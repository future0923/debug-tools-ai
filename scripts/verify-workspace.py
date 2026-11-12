#!/usr/bin/env python3
"""Build, test and cross-check the three local DebugTools repositories."""
import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
import zipfile

VERSIONS = (8, 11, 17, 21, 25)
STEPS = ('preflight', 'build-agent', 'agent-tests', 'agent-test-evidence', 'sync-agent',
         'idea-check', 'idea-test-evidence', 'target-jdk-matrix', 'contracts',
         'ai-validate', 'package-evidence', 'verifier', 'verifier-evidence')


def idea_properties(idea):
    """插件补丁可独立发版，旧项目未指定 agentVersion 时沿用插件版本。"""
    properties = dict(re.findall(r'^([\w.]+)\s*=\s*(.+)$', (idea / 'gradle.properties').read_text(), re.M))
    properties = {key: value.strip() for key, value in properties.items()}
    properties.setdefault('agentVersion', properties['pluginVersion'])
    return properties


def java_major(home):
    release = (Path(home) / 'release').read_text()
    match = re.search(r'^JAVA_VERSION="(?:1\.)?(\d+)', release, re.M)
    if not match:
        raise ValueError(f'Cannot identify JDK: {home}')
    return int(match.group(1))


def discover_jdks():
    """Prefer explicit per-version settings; never download or install runtimes."""
    candidates = []
    for version in VERSIONS:
        value = os.environ.get(f'JAVA{version}_HOME')
        if value:
            candidates.append(Path(value))
    for directory in (Path('/Library/Java/JavaVirtualMachines'), Path('/usr/lib/jvm')):
        if directory.is_dir():
            candidates.extend(sorted(directory.glob('*/Contents/Home')))
            candidates.extend(p for p in sorted(directory.iterdir()) if (p / 'release').is_file())
    found = {}
    for home in candidates:
        if (home / 'bin/javac').is_file():
            found.setdefault(java_major(home), home.resolve())
    return found


def test_totals(directory):
    """A successful process with zero tests is not a successful regression run."""
    totals = dict(tests=0, failures=0, errors=0, skipped=0)
    for path in directory.glob('TEST-*.xml'):
        suite = ET.parse(path).getroot()
        for key in totals:
            totals[key] += int(suite.get(key, 0))
    if totals['tests'] <= totals['skipped'] or totals['failures'] or totals['errors']:
        raise ValueError(f'No passing regression evidence in {directory}: {totals}')
    return totals


def validate_package(archive, agent):
    expected = agent.read_bytes()
    found = []
    with zipfile.ZipFile(archive) as plugin:
        roots = {name.split('/')[0] for name in plugin.namelist()}
        if roots != {'DebugTools'}:
            raise ValueError(f'Unexpected plugin roots: {roots}')
        for name in plugin.namelist():
            if '/lib/modules/' in name or name.endswith('.mcp.jar'):
                raise ValueError('MCP must remain in the single plugin')
            if not name.endswith('.jar'):
                continue
            with zipfile.ZipFile(io.BytesIO(plugin.read(name))) as jar:
                for entry in jar.namelist():
                    if entry == 'META-INF/plugin.xml':
                        descriptor = ET.fromstring(jar.read(entry))
                        if any('com.intellij.mcpServer' in ''.join(node.itertext()) for node in descriptor.findall('depends')):
                            raise ValueError('MCP Server dependency is forbidden')
                    if entry.endswith('/' + agent.name):
                        if jar.read(entry) != expected:
                            raise ValueError('Packaged agent differs from the rebuilt agent')
                        found.append(name + ':' + entry)
    if len(found) != 1:
        raise ValueError(f'Expected exactly one embedded agent: {found}')
    return dict(zipSha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                agentSha256=hashlib.sha256(expected).hexdigest(), embeddedAgent=found[0])


class Verification:
    def __init__(self, output):
        output.mkdir(parents=True, exist_ok=True)
        self.output = output
        self.report = dict(startedAt=datetime.now(timezone.utc).isoformat(), status='RUNNING', steps=[dict(name=name, status='NOT_RUN') for name in STEPS],
                           environmentChecks=[dict(name=name, status='NOT_RUN', reason=reason) for name, reason in (
                               ('IDEA MCP / Run / HotSwap', 'Requires an exposed live IDEA MCP and an explicit test application'),
                               ('Kubernetes', 'Requires an explicitly selected test context, namespace and workload'),
                               ('Business framework refresh', 'Requires a selected Spring/MyBatis/Solon test application'))])
        self.save()

    def save(self):
        destination = self.output / 'report.json'
        temporary = self.output / 'report.json.tmp'
        temporary.write_text(json.dumps(self.report, ensure_ascii=False, indent=2) + '\n')
        temporary.replace(destination)

    def step(self, name, action):
        record = next((item for item in self.report['steps'] if item['name'] == name), None)
        if record is None:
            record = dict(name=name)
            self.report['steps'].append(record)
        record['status'] = 'RUNNING'
        self.save()
        print(f'RUN {name}', flush=True)
        started = time.monotonic()
        try:
            record['evidence'] = action()
            record['status'] = 'PASS'
        except BaseException as error:
            record.update(status='FAIL', error=str(error))
            self.report['status'] = 'FAIL'
            raise
        finally:
            record['durationSeconds'] = round(time.monotonic() - started, 2)
            self.save()
        print(f'PASS {name}', flush=True)

    def command(self, name, command, cwd, env):
        log = self.output / (name + '.log')
        with log.open('w') as stream:
            process = subprocess.run(command, cwd=cwd, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=1800)
        if process.returncode:
            raise RuntimeError(f'{name} exited {process.returncode}; see {log}')
        return dict(log=str(log), command=command)


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--agent-repo', type=Path, default=root.parent / 'debug-tools')
    parser.add_argument('--idea-repo', type=Path, default=root.parent / 'debug-tools-idea')
    parser.add_argument('--java-home', type=Path, help='JDK 21 for Maven/Gradle; defaults to JAVA_HOME or local JDK 21')
    parser.add_argument('--target-java-home', type=Path, action='append', help='Repeat for target JDKs; requires 8,11,17,21,25')
    parser.add_argument('--maven', default=shutil.which('mvn') or 'mvn')
    parser.add_argument('--offline', action='store_true')
    parser.add_argument('--skip-verifier', action='store_true', help='Report verifier NOT_RUN; remaining checks still run')
    parser.add_argument('--output', type=Path, help='New output directory (must not exist)')
    args = parser.parse_args()
    output = (args.output or root / 'build/workspace-verification' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')).resolve()
    if output.exists():
        parser.error('--output must be a new directory, so previous evidence is never reused')
    verification = Verification(output)
    print(f'Report: {output / "report.json"}', flush=True)
    try:
        jdks = discover_jdks()
        build_java = args.java_home or (Path(os.environ['JAVA_HOME']) if os.environ.get('JAVA_HOME') else jdks.get(21))
        targets = [p.resolve() for p in args.target_java_home] if args.target_java_home else [jdks[v] for v in VERSIONS if v in jdks]
        agent = args.agent_repo.resolve()
        idea = args.idea_repo.resolve()
        env = dict(os.environ)

        def preflight():
            if not build_java or java_major(build_java) != 21:
                raise ValueError('Select JDK 21 with --java-home')
            if {java_major(p) for p in targets} != set(VERSIONS) or len(targets) != len(VERSIONS):
                raise ValueError('Provide exactly one JDK for each of 8,11,17,21,25 using --target-java-home or JAVA<N>_HOME')
            for home in targets + [build_java]:
                for executable in ('java', 'javac'):
                    if not (home / 'bin' / executable).is_file():
                        raise ValueError(f'Missing {executable}: {home}')
            for path in (agent / 'pom.xml', idea / 'gradlew', idea / 'MCP_INTEGRATION.md'):
                if not path.is_file():
                    raise ValueError(f'Missing workspace source: {path}')
            namespace = {'m': 'http://maven.apache.org/POM/4.0.0'}
            agent_version = ET.parse(agent / 'pom.xml').findtext('m:properties/m:revision', namespaces=namespace)
            required_agent_version = idea_properties(idea)['agentVersion']
            if agent_version != required_agent_version:
                raise ValueError(f'Agent version {agent_version} does not match required agent {required_agent_version}')
            env.update(JAVA_HOME=str(build_java), PATH=str(build_java / 'bin') + os.pathsep + env['PATH'])
            return dict(buildJava=str(build_java), targets={str(java_major(p)): str(p) for p in targets})
        verification.step('preflight', preflight)
        maven = [args.maven, '-q', '-Dlicense.skip=true', '-Dspotless.skip=true'] + (['-o'] if args.offline else [])
        verification.step('build-agent', lambda: verification.command('build-agent', maven + ['-pl', 'debug-tools-attach', '-am', 'install', '-DskipTests'], agent, env))
        modules = ['debug-tools-sql', 'debug-tools-server', 'debug-tools-extension/debug-tools-extension-spring']
        for module in modules:
            for old in (agent / module / 'target/surefire-reports').glob('TEST-*.xml'):
                old.unlink()
        verification.step('agent-tests', lambda: verification.command('agent-tests', maven + ['-pl', 'debug-tools-server,debug-tools-extension/debug-tools-extension-spring', '-am', 'test'], agent, env))
        verification.step('agent-test-evidence', lambda: {module: test_totals(agent / module / 'target/surefire-reports') for module in modules})
        properties = idea_properties(idea)
        version = properties['pluginVersion']
        source = agent / 'debug-tools-attach/target/debug-tools-agent.jar'
        resource = idea / f'src/main/resources/lib/debug-tools-agent-{properties["agentVersion"]}.jar'

        def sync_agent():
            with zipfile.ZipFile(source) as jar:
                manifest = jar.read('META-INF/MANIFEST.MF').decode()
                if not re.search(r'^Premain-Class:', manifest, re.M):
                    raise ValueError('Built jar is not a Java agent')
            resource.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, resource)
            return dict(source=str(source), resource=str(resource), sha256=hashlib.sha256(resource.read_bytes()).hexdigest())
        verification.step('sync-agent', sync_agent)
        gradle = ['bash', './gradlew', '-Pkotlin.daemon.jvmargs=-Xmx2g', '-PdebugTools.test.javaHomes=' + os.pathsep.join(map(str, targets))] + (['--offline'] if args.offline else [])
        for old in (idea / 'build/test-results/test').glob('TEST-*.xml'):
            old.unlink()
        (idea / 'build/generated/debug-tools-mcp-contracts.json').unlink(missing_ok=True)
        verification.step('idea-check', lambda: verification.command('idea-check', gradle + ['test', '--rerun', 'check', 'buildPlugin', 'movePluginZip'], idea, env))
        verification.step('idea-test-evidence', lambda: test_totals(idea / 'build/test-results/test'))

        def matrix_evidence():
            suite = ET.parse(idea / 'build/test-results/test/TEST-io.github.future0923.debug.tools.idea.mcp.PackagedAgentRegressionTest.xml').getroot()
            output_text = ''.join(suite.findtext(tag, '') for tag in ('system-out', 'system-err'))
            missing = [str(p) for p in targets if f'PACKAGED_AGENT_PASS {p}' not in output_text]
            if missing:
                raise ValueError(f'Target matrix did not complete: {missing}')
            return dict(passed={str(java_major(p)): str(p) for p in targets})
        verification.step('target-jdk-matrix', matrix_evidence)
        verification.step('contracts', lambda: verification.command('contracts', [sys.executable, str(root / 'scripts/check-tool-contracts.py'), '--plugin-export', str(idea / 'build/generated/debug-tools-mcp-contracts.json')], root, env))
        verification.step('ai-validate', lambda: verification.command('ai-validate', ['bash', str(root / 'scripts/validate.sh')], root, env))
        verification.step('package-evidence', lambda: validate_package(idea / f'dist/DebugTools-{version}.zip', resource))
        if args.skip_verifier:
            for record in verification.report['steps']:
                if record['name'].startswith('verifier'):
                    record.update(status='NOT_RUN', reason='Explicit --skip-verifier')
        else:
            verification.step('verifier', lambda: verification.command('verifier', gradle + ['verifyPlugin', '--rerun'], idea, env))
            def verdicts():
                reports = list((idea / 'build/reports/pluginVerifier').rglob('verification-verdict.txt'))
                expected = len(properties['ideVersionVerifier'].split(','))
                if len(reports) != expected or not all(p.read_text().startswith('Compatible.') for p in reports):
                    raise ValueError(f'Expected {expected} compatible IDE verdicts, found {len(reports)}')
                return {str(p.relative_to(idea)): p.read_text().strip() for p in reports}
            verification.step('verifier-evidence', verdicts)
        verification.report['status'] = 'PARTIAL' if args.skip_verifier else 'PASS'
        verification.report['scope'] = 'Local automated verification; environmentChecks are separate and were not executed'
        print(f'{verification.report["status"]}: local verification; live environment checks remain NOT_RUN', flush=True)
        return 0
    except (Exception, KeyboardInterrupt) as error:
        verification.report.update(status='FAIL', error=str(error))
        print(f'FAIL: {error}', file=sys.stderr)
        return 1
    finally:
        verification.report['finishedAt'] = datetime.now(timezone.utc).isoformat()
        verification.save()


if __name__ == '__main__':
    sys.exit(main())

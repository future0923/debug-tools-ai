import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('workspace_verifier', ROOT / 'scripts/verify-workspace.py')
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)


class WorkspaceEvidenceTest(unittest.TestCase):
    def test_plugin_patch_can_keep_agent_version_and_legacy_projects_still_work(self):
        with tempfile.TemporaryDirectory() as temporary:
            idea = Path(temporary)
            properties = idea / 'gradle.properties'
            properties.write_text('pluginVersion=5.4.1\nagentVersion=5.4.0\n')
            self.assertEqual('5.4.1', verifier.idea_properties(idea)['pluginVersion'])
            self.assertEqual('5.4.0', verifier.idea_properties(idea)['agentVersion'])
            properties.write_text('pluginVersion=5.4.0\n')
            self.assertEqual('5.4.0', verifier.idea_properties(idea)['agentVersion'])

    def test_zero_skipped_only_and_failed_reports_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for attributes in ('tests="0"', 'tests="2" skipped="2"', 'tests="2" failures="1"', 'tests="1" errors="1"'):
                (directory / 'TEST-example.xml').write_text('<testsuite ' + attributes + '/>')
                with self.assertRaises(ValueError):
                    verifier.test_totals(directory)
            (directory / 'TEST-example.xml').write_text('<testsuite tests="2" failures="0" errors="0"/>')
            self.assertEqual(2, verifier.test_totals(directory)['tests'])

    def test_stale_embedded_agent_and_mcp_dependency_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            agent = directory / 'debug-tools-agent-5.3.0.jar'
            agent.write_bytes(b'new-agent')
            archive = directory / 'plugin.zip'

            def package(content, descriptor='<idea-plugin/>'):
                data = io.BytesIO()
                with zipfile.ZipFile(data, 'w') as jar:
                    jar.writestr('lib/' + agent.name, content)
                    jar.writestr('META-INF/plugin.xml', descriptor)
                with zipfile.ZipFile(archive, 'w') as plugin:
                    plugin.writestr('DebugTools/lib/main.jar', data.getvalue())
            package(b'old-agent')
            with self.assertRaisesRegex(ValueError, 'differs'):
                verifier.validate_package(archive, agent)
            package(agent.read_bytes(), '<idea-plugin><depends>com.intellij.mcpServer</depends></idea-plugin>')
            with self.assertRaisesRegex(ValueError, 'dependency'):
                verifier.validate_package(archive, agent)
            package(agent.read_bytes())
            self.assertIn('zipSha256', verifier.validate_package(archive, agent))

    def test_failing_step_is_persisted_before_exception_leaves(self):
        with tempfile.TemporaryDirectory() as temporary:
            run = verifier.Verification(Path(temporary))
            def failed():
                raise RuntimeError('fixture failed')
            with self.assertRaises(RuntimeError):
                run.step('fixture', failed)
            import json
            report = json.loads((Path(temporary) / 'report.json').read_text())
            self.assertEqual('FAIL', report['status'])
            self.assertEqual('FAIL', next(item for item in report['steps'] if item['name'] == 'fixture')['status'])
            self.assertEqual('NOT_RUN', next(item for item in report['steps'] if item['name'] == 'contracts')['status'])
            self.assertTrue(all(check['status'] == 'NOT_RUN' for check in report['environmentChecks']))


if __name__ == '__main__':
    unittest.main()

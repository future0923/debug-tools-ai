#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "README.md"
  "README-zh.md"
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  "install.sh"
  "package.json"
  "bin/debug-tools-ai"
  "docs/examples.md"
  "docs/examples-zh.md"
  "docs/transcripts.md"
  "docs/transcripts-zh.md"
  "docs/workflow.md"
  "docs/tool-contracts.md"
  "docs/installation.md"
  "docs/installation-zh.md"
  "docs/release.md"
  "examples/spring-boot-demo.md"
  "scripts/check-pressure-scenarios.sh"
  "scripts/check-release-readiness.sh"
  "scripts/check-manifest-paths.sh"
  "scripts/doctor.sh"
  "scripts/uninstall.sh"
  "scripts/list-pressure-scenarios.sh"
  "scripts/new-pressure-report.sh"
  "scripts/package-release.sh"
  "scripts/prepublish-check.sh"
  "scripts/check-versions.sh"
  "scripts/smoke-install.sh"
  "scripts/sync-adapters.sh"
  ".github/workflows/validate.yml"
  ".github/workflows/release.yml"
  ".github/pull_request_template.md"
  ".github/ISSUE_TEMPLATE/bug_report.md"
  ".github/ISSUE_TEMPLATE/skill_behavior_gap.md"
  "tests/pressure/README.md"
  "tests/pressure/runs/2026-06-19-debug-tools-mcp.md"
  "tests/pressure/01-existing-connection-args-template.md"
  "tests/pressure/02-multiple-connections-select-target.md"
  "tests/pressure/03-classnotfound-http-classloader.md"
  "tests/pressure/04-multiple-classloaders-require-choice.md"
  "tests/pressure/05-complex-args-template-first.md"
  "tests/pressure/06-hotswap-run-configuration.md"
  "tests/pressure/07-hotswap-ambiguous-configuration.md"
  "tests/pressure/08-no-attachable-jvms-offer-hotswap.md"
  "skills/debug-tools-method-invocation/SKILL.md"
  "skills/debug-tools-method-invocation/agents/openai.yaml"
  "skills/debug-tools-method-invocation/references/args-json.md"
  "skills/debug-tools-method-invocation/references/http-classloader.md"
  "skills/debug-tools-method-invocation/references/workflow.md"
  "skills/debug-tools-method-invocation/references/troubleshooting.md"
  "skills/debug-tools-hotswap/SKILL.md"
  "skills/debug-tools-hotswap/agents/openai.yaml"
  ".codex-plugin/plugin.json"
  ".claude-plugin/plugin.json"
  ".cursor-plugin/plugin.json"
  ".kimi-plugin/plugin.json"
  ".opencode/plugins/debug-tools-ai.js"
  ".pi/extensions/debug-tools-ai/README.md"
  "gemini-extension.json"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$ROOT/$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

tools=(
  "list_debug_tools_connections"
  "list_attachable_jvms"
  "attach_local_jvm"
  "generate_method_args_template"
  "invoke_java_method"
  "list_debug_tools_run_configurations"
  "execute_debug_tools_run_configuration"
)

for tool in "${tools[@]}"; do
  if ! grep -R "$tool" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/GEMINI.md" "$ROOT/docs" "$ROOT/skills" >/dev/null; then
    echo "Missing tool reference: $tool" >&2
    exit 1
  fi
done

python3 -m json.tool "$ROOT/.codex-plugin/plugin.json" >/dev/null
python3 -m json.tool "$ROOT/.claude-plugin/plugin.json" >/dev/null
python3 -m json.tool "$ROOT/.claude-plugin/marketplace.json" >/dev/null
python3 -m json.tool "$ROOT/.cursor-plugin/plugin.json" >/dev/null
python3 -m json.tool "$ROOT/.kimi-plugin/plugin.json" >/dev/null
python3 -m json.tool "$ROOT/gemini-extension.json" >/dev/null
python3 -m json.tool "$ROOT/package.json" >/dev/null

bash -n "$ROOT/install.sh"
bash -n "$ROOT/bin/debug-tools-ai"
bash -n "$ROOT/scripts/check-pressure-scenarios.sh"
bash -n "$ROOT/scripts/check-release-readiness.sh"
bash -n "$ROOT/scripts/check-manifest-paths.sh"
bash -n "$ROOT/scripts/doctor.sh"
bash -n "$ROOT/scripts/uninstall.sh"
bash -n "$ROOT/scripts/list-pressure-scenarios.sh"
bash -n "$ROOT/scripts/new-pressure-report.sh"
bash -n "$ROOT/scripts/package-release.sh"
bash -n "$ROOT/scripts/prepublish-check.sh"
bash -n "$ROOT/scripts/check-versions.sh"
bash -n "$ROOT/scripts/smoke-install.sh"
bash -n "$ROOT/scripts/sync-adapters.sh"
bash -n "$ROOT/tests/validate-layout.sh"
"$ROOT/scripts/sync-adapters.sh"
bash "$ROOT/scripts/check-versions.sh"
bash "$ROOT/scripts/check-manifest-paths.sh"
bash "$ROOT/scripts/check-pressure-scenarios.sh"
bash "$ROOT/scripts/check-release-readiness.sh"
bash "$ROOT/scripts/smoke-install.sh"
bash "$ROOT/scripts/doctor.sh"

for skill_file in "$ROOT/skills/debug-tools-method-invocation/SKILL.md" "$ROOT/skills/debug-tools-hotswap/SKILL.md"; do
  if ! grep -q "^---" "$skill_file"; then
    echo "Skill is missing YAML frontmatter: ${skill_file#$ROOT/}" >&2
    exit 1
  fi
done

old_skill_name="debug-tools""-mcp"
if grep -R "$old_skill_name" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/GEMINI.md" "$ROOT/docs" "$ROOT/skills" "$ROOT/tests/pressure" "$ROOT/package.json" "$ROOT/gemini-extension.json" >/dev/null; then
  echo "Old skill name remains in public package files" >&2
  exit 1
fi

if grep -R "../../docs" "$ROOT/skills/debug-tools-method-invocation/SKILL.md" "$ROOT/skills/debug-tools-hotswap/SKILL.md" >/dev/null; then
  echo "Skills must not depend on repository-level docs after installation" >&2
  exit 1
fi

http_terms=(
  "/allClassLoader"
  "/classLoader/hasClass"
  "httpPort"
  "classLoaderIdentity"
)

for term in "${http_terms[@]}"; do
  if ! grep -R "$term" "$ROOT/docs/tool-contracts.md" "$ROOT/skills/debug-tools-method-invocation" >/dev/null; then
    echo "Missing HTTP ClassLoader reference: $term" >&2
    exit 1
  fi
done

pressure_terms=(
  "generate_method_args_template"
  "connectionId"
  "ClassNotFoundException"
  "/allClassLoader"
  "/classLoader/hasClass"
  "list_debug_tools_classloaders"
  "targetMethodContent"
  "list_debug_tools_run_configurations"
  "execute_debug_tools_run_configuration"
  "autoAttachEnabled"
  "requiresManualAttach"
  "nextAction"
  "waitForConnectionMillis"
  "count=0"
  "empty jvms"
)

for term in "${pressure_terms[@]}"; do
  if ! grep -R "$term" "$ROOT/tests/pressure" >/dev/null; then
    echo "Missing pressure scenario coverage: $term" >&2
    exit 1
  fi
done

pressure_count="$(find "$ROOT/tests/pressure" -name '*.md' ! -name 'README.md' | wc -l | tr -d '[:space:]')"
if [[ "$pressure_count" -lt 5 ]]; then
  echo "Expected at least 5 pressure scenarios, found $pressure_count" >&2
  exit 1
fi

if grep -R "list_debug_tools_classloaders" "$ROOT/docs/tool-contracts.md" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/GEMINI.md" >/dev/null; then
  echo "Do not document list_debug_tools_classloaders as a tool; use direct DebugTools HTTP instead" >&2
  exit 1
fi

echo "debug-tools-ai validation passed"

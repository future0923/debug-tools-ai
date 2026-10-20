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
  "docs/workflow-groups.md"
  "tests/pressure/27-unified-workflow.md"
  "tests/pressure/runs/2026-10-19-unified-workflow.md"
  "docs/tool-contracts.md"
  "docs/installation.md"
  "docs/installation-zh.md"
  "docs/release.md"
  "examples/spring-boot-demo.md"
  "scripts/check-pressure-scenarios.sh"
  "scripts/check-release-readiness.sh"
  "scripts/check-manifest-paths.sh"
  "scripts/verify-workspace.py"
  "scripts/check-skill-routing.py"
  "tests/workspace_verification_test.py"
  "tests/skill_routing_test.py"
  "docs/workspace-verification.md"
  "docs/live-acceptance.md"
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
  "tests/pressure/09-no-attachable-jvms-offer-native-when-available.md"
  "tests/pressure/10-missing-mcp-tools-fails-fast.md"
  "tests/pressure/11-json-result-view-http.md"
  "tests/pressure/12-debug-result-view-http.md"
  "tests/pressure/13-spring-config-http.md"
  "tests/pressure/14-method-invocation-waits-for-spring-ready.md"
  "skills/debug-tools/references/code-search.md"
  "skills/debug-tools/references/database-query.md"
  "tests/pressure/22-code-search-route-lookup.md"
  "tests/pressure/23-database-query-readonly.md"
  "skills/debug-tools/SKILL.md"
  "skills/debug-tools/agents/openai.yaml"
  "skills/debug-tools/references/invocation.md"
  "skills/debug-tools/references/run-and-hotswap.md"
  "skills/debug-tools/references/spring.md"
  "skills/debug-tools/references/runtime-diagnostics.md"
  "skills/debug-tools/references/extended-workflows.md"
  "skills/debug-tools/references/args-json.md"
  "skills/debug-tools/references/http-classloader.md"
  "skills/debug-tools/references/http-result-view.md"
  "skills/debug-tools/references/workflow.md"
  "skills/debug-tools/references/troubleshooting.md"
  "skills/debug-tools/assets/pluginIcon.png"
  "skills/debug-tools/references/results-and-evidence.md"
  "skills/debug-tools/references/live-observation.md"
  "docs/runtime-diagnostics.md"
  "docs/runtime-regression-2026-10-14.md"
  "skills/debug-tools/references/http-spring-config.md"
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
  "compile_and_reload_modified_files"
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
node --test "$ROOT/tests/adapters.test.mjs"
python3 "$ROOT/tests/doctor_runtime_test.py"
python3 "$ROOT/scripts/check-tool-contracts.py"
python3 "$ROOT/tests/tool_contracts_test.py"
python3 "$ROOT/tests/workspace_verification_test.py"
python3 "$ROOT/tests/skill_routing_test.py"

for skill_file in "$ROOT/skills/debug-tools/SKILL.md"; do
  if ! grep -q "^---" "$skill_file"; then
    echo "Skill is missing YAML frontmatter: ${skill_file#$ROOT/}" >&2
    exit 1
  fi
done

old_skill_name="debug-tools""-mcp"
if grep -R -E "(^|[^[:alnum:]_-])${old_skill_name}([^[:alnum:]_-]|$)" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/GEMINI.md" "$ROOT/docs" "$ROOT/skills" "$ROOT/tests/pressure" "$ROOT/package.json" "$ROOT/gemini-extension.json" >/dev/null; then
  echo "Old skill name remains in public package files" >&2
  exit 1
fi

if grep -R "../../docs" "$ROOT/skills/debug-tools/SKILL.md" >/dev/null; then
  echo "Skills must not depend on repository-level docs after installation" >&2
  exit 1
fi

http_terms=(
  "/allClassLoader"
  "/classLoader/hasClass"
  "/result/type"
  "/result/detail"
  "httpPort"
  "classLoaderIdentity"
  "printResultType"
  "offsetPath"
)

for term in "${http_terms[@]}"; do
  if ! grep -R "$term" "$ROOT/docs/tool-contracts.md" "$ROOT/skills/debug-tools" >/dev/null; then
    echo "Missing DebugTools HTTP reference: $term" >&2
    exit 1
  fi
done

spring_config_terms=(
  "/spring/config"
  "Spring runtime Environment"
  "JSON string array"
)

for term in "${spring_config_terms[@]}"; do
  if ! grep -R "$term" "$ROOT/docs/tool-contracts.md" "$ROOT/docs/workflow.md" "$ROOT/skills/debug-tools" "$ROOT/tests/pressure" >/dev/null; then
    echo "Missing Spring config HTTP reference: $term" >&2
    exit 1
  fi
done

spring_ready_terms=(
  "/spring/ready"
  "retryable=true"
  "retryable=false"
)

for term in "${spring_ready_terms[@]}"; do
  if ! grep -R "$term" "$ROOT/docs/tool-contracts.md" "$ROOT/docs/workflow.md" "$ROOT/skills/debug-tools" "$ROOT/tests/pressure" >/dev/null; then
    echo "Missing Spring readiness reference: $term" >&2
    exit 1
  fi
done

for path in \
  "$ROOT/docs/tool-contracts.md" \
  "$ROOT/docs/workflow.md" \
  "$ROOT/skills/debug-tools" \
  "$ROOT/tests/pressure"; do
  if ! grep -R "/spring/ready" "$path" >/dev/null; then
    echo "Missing /spring/ready in ${path#$ROOT/}" >&2
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
  "/result/type"
  "/result/detail"
  "printResultType=Json"
  "printResultType=Debug"
  "/spring/config"
  "/spring/ready"
  "retryable=true"
  "retryable=false"
  "get_spring_config"
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

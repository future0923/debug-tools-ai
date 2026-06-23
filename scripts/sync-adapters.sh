#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

method_tools=(
  "list_debug_tools_connections"
  "list_attachable_jvms"
  "attach_local_jvm"
  "generate_method_args_template"
  "invoke_java_method"
)

hotswap_tools=(
  "list_debug_tools_run_configurations"
  "execute_debug_tools_run_configuration"
  "compile_and_reload_modified_files"
)

adapters=(
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  ".opencode/INSTALL.md"
)

for adapter in "${adapters[@]}"; do
  for tool in "${method_tools[@]}" "${hotswap_tools[@]}"; do
    if ! grep -q "$tool" "$ROOT/$adapter"; then
      echo "$adapter is missing tool reference: $tool" >&2
      exit 1
    fi
  done
done

for tool in "${method_tools[@]}"; do
  if ! grep -q "$tool" "$ROOT/skills/debug-tools-method-invocation/SKILL.md"; then
    echo "skills/debug-tools-method-invocation/SKILL.md is missing tool reference: $tool" >&2
    exit 1
  fi
done

for tool in "${hotswap_tools[@]}"; do
  if ! grep -q "$tool" "$ROOT/skills/debug-tools-hotswap/SKILL.md"; then
    echo "skills/debug-tools-hotswap/SKILL.md is missing tool reference: $tool" >&2
    exit 1
  fi
done

if ! grep -q "docs/workflow.md" "$ROOT/AGENTS.md"; then
  echo "AGENTS.md must point agents to docs/workflow.md" >&2
  exit 1
fi

for skill in "debug-tools-method-invocation" "debug-tools-hotswap"; do
  if ! grep -R "$skill" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/GEMINI.md" "$ROOT/docs" "$ROOT/skills" >/dev/null; then
    echo "Missing skill reference: $skill" >&2
    exit 1
  fi
done

echo "debug-tools-ai adapters are in sync"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tools=(
  "list_debug_tools_connections"
  "list_attachable_jvms"
  "attach_local_jvm"
  "generate_method_args_template"
  "invoke_java_method"
)

adapters=(
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  ".opencode/INSTALL.md"
  "skills/debug-tools-mcp/SKILL.md"
)

for adapter in "${adapters[@]}"; do
  for tool in "${tools[@]}"; do
    if ! grep -q "$tool" "$ROOT/$adapter"; then
      echo "$adapter is missing tool reference: $tool" >&2
      exit 1
    fi
  done
done

if ! grep -q "docs/workflow.md" "$ROOT/AGENTS.md"; then
  echo "AGENTS.md must point agents to docs/workflow.md" >&2
  exit 1
fi

echo "debug-tools-ai adapters are in sync"

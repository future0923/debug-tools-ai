#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME is required}"
strict_installed=false
failures=0
warnings=0
mcp_url=""

usage() {
  cat <<'EOF'
Usage: debug-tools-ai doctor [options]

Options:
  --strict-installed   Fail if supported local agent files are not installed.
  --mcp-url URL        Check an explicit Streamable HTTP MCP endpoint (discovery only).
  --help               Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict-installed) strict_installed=true ;;
    --mcp-url)
      [[ $# -ge 2 ]] || { echo "--mcp-url requires a URL" >&2; exit 1; }
      mcp_url="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown doctor option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

ok() {
  printf 'OK   %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1"
}

check_repo_file() {
  local label="$1"
  local path="$2"
  if [[ -e "$ROOT/$path" ]]; then
    ok "$label: $path"
  else
    fail "$label missing: $path"
  fi
}

check_installed_file() {
  local label="$1"
  local path="$2"
  if [[ -e "$HOME_DIR/$path" ]]; then
    ok "$label: ~/$path"
    if [[ "$path" == */skills/*/SKILL.md ]]; then
      local relative="skills/${path##*/skills/}"
      if [[ -f "$ROOT/$relative" ]] && ! cmp -s "$ROOT/$relative" "$HOME_DIR/$path"; then
        if [[ "$strict_installed" == true ]]; then
          fail "$label differs from this checkout; update the installed skill"
        else
          warn "$label differs from this checkout; installed instructions may be older"
        fi
      fi
    fi
  elif [[ "$strict_installed" == true ]]; then
    fail "$label missing: ~/$path"
  else
    warn "$label not installed: ~/$path"
  fi
}

echo "DebugTools AI Doctor"
if [[ -n "$mcp_url" ]]; then
  python3 "$ROOT/scripts/doctor-runtime.py" --mcp-url "$mcp_url" || failures=$((failures + 1))
else
  python3 "$ROOT/scripts/doctor-runtime.py" || failures=$((failures + 1))
fi
echo
echo "Package checkout:"
check_repo_file "Workflow skill" "skills/debug-tools/SKILL.md"
check_repo_file "Workflow metadata" "skills/debug-tools/agents/openai.yaml"
check_repo_file "Workflow instructions" "docs/workflow.md"
check_repo_file "Tool contracts" "docs/tool-contracts.md"
check_repo_file "Codex plugin manifest" ".codex-plugin/plugin.json"
check_repo_file "Claude plugin manifest" ".claude-plugin/plugin.json"
check_repo_file "Gemini extension manifest" "gemini-extension.json"
check_repo_file "OpenCode plugin" ".opencode/plugins/debug-tools-ai.js"
check_installed_file "Codex workflow skill" ".codex/skills/debug-tools/SKILL.md"
check_installed_file "Codex plugin workflow skill" ".codex/plugins/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "Claude plugin workflow skill" ".claude/plugins/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "Gemini extension workflow skill" ".gemini/extensions/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "OpenCode workflow skill" ".config/opencode/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "Cursor plugin workflow skill" ".cursor/plugins/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "Kimi plugin workflow skill" ".kimi/plugins/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "Pi workflow skill" ".pi/packages/debug-tools-ai/skills/debug-tools/SKILL.md"
check_installed_file "OpenCode plugin" ".config/opencode/plugins/debug-tools-ai.js"
check_installed_file "Pi package CLI" ".pi/packages/debug-tools-ai/bin/debug-tools-ai"

echo
if [[ "$failures" -gt 0 ]]; then
  echo "Doctor failed: $failures failure(s), $warnings warning(s)"
  exit 1
fi

echo "Doctor passed: $warnings warning(s)"

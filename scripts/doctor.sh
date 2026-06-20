#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME is required}"
strict_installed=false
failures=0
warnings=0

usage() {
  cat <<'EOF'
Usage: debug-tools-ai doctor [options]

Options:
  --strict-installed   Fail if supported local agent files are not installed.
  --help               Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict-installed) strict_installed=true ;;
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
  elif [[ "$strict_installed" == true ]]; then
    fail "$label missing: ~/$path"
  else
    warn "$label not installed: ~/$path"
  fi
}

echo "DebugTools AI Doctor"
echo
echo "Package checkout:"
check_repo_file "Skill" "skills/debug-tools-mcp/SKILL.md"
check_repo_file "CLI" "bin/debug-tools-ai"
check_repo_file "Installer" "install.sh"
check_repo_file "OpenCode plugin" ".opencode/plugins/debug-tools-ai.js"
check_repo_file "Codex manifest" ".codex-plugin/plugin.json"
check_repo_file "Gemini manifest" "gemini-extension.json"
check_repo_file "Pressure scenarios" "tests/pressure/README.md"

echo
echo "Installed adapters:"
check_installed_file "Codex skill" ".codex/skills/debug-tools-mcp/SKILL.md"
check_installed_file "Codex plugin skill" ".codex/plugins/debug-tools-ai/skills/debug-tools-mcp/SKILL.md"
check_installed_file "Claude plugin skill" ".claude/plugins/debug-tools-ai/skills/debug-tools-mcp/SKILL.md"
check_installed_file "Gemini extension skill" ".gemini/extensions/debug-tools-ai/skills/debug-tools-mcp/SKILL.md"
check_installed_file "OpenCode skill" ".config/opencode/debug-tools-ai/skills/debug-tools-mcp/SKILL.md"
check_installed_file "OpenCode plugin" ".config/opencode/plugins/debug-tools-ai.js"
check_installed_file "Cursor plugin skill" ".cursor/plugins/debug-tools-ai/skills/debug-tools-mcp/SKILL.md"
check_installed_file "Kimi plugin skill" ".kimi/plugins/debug-tools-ai/skills/debug-tools-mcp/SKILL.md"
check_installed_file "Pi package CLI" ".pi/packages/debug-tools-ai/bin/debug-tools-ai"

echo
if [[ "$failures" -gt 0 ]]; then
  echo "Doctor failed: $failures failure(s), $warnings warning(s)"
  exit 1
fi

echo "Doctor passed: $warnings warning(s)"

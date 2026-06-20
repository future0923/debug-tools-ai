#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${HOME:?HOME is required}"

uninstall_codex=false
uninstall_claude=false
uninstall_gemini=false
uninstall_opencode=false
uninstall_cursor=false
uninstall_kimi=false
uninstall_pi=false

usage() {
  cat <<'EOF'
Usage: debug-tools-ai uninstall [options]

Options:
  --all        Remove files for every supported local agent
  --codex      Remove Codex skill and plugin metadata
  --claude     Remove Claude Code project instructions
  --gemini     Remove Gemini extension metadata and instructions
  --opencode   Remove OpenCode plugin and instructions
  --cursor     Remove Cursor plugin metadata
  --kimi       Remove Kimi plugin metadata
  --pi         Remove Pi package metadata
  --help       Show this help

The uninstaller removes only debug-tools-ai owned files and directories. It
does not remove DebugTools, IntelliJ, MCP servers, or parent agent config
directories.
EOF
}

remove_path() {
  local path="$1"
  local label="$2"

  if [[ -e "$path" || -L "$path" ]]; then
    rm -rf "$path"
    echo "Removed $label"
  else
    echo "Already absent $label"
  fi
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      uninstall_codex=true
      uninstall_claude=true
      uninstall_gemini=true
      uninstall_opencode=true
      uninstall_cursor=true
      uninstall_kimi=true
      uninstall_pi=true
      ;;
    --codex) uninstall_codex=true ;;
    --claude) uninstall_claude=true ;;
    --gemini) uninstall_gemini=true ;;
    --opencode) uninstall_opencode=true ;;
    --cursor) uninstall_cursor=true ;;
    --kimi) uninstall_kimi=true ;;
    --pi) uninstall_pi=true ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown uninstall option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "$uninstall_codex" == true ]]; then
  remove_path "$HOME_DIR/.codex/skills/debug-tools-method-invocation" "Codex method invocation skill"
  remove_path "$HOME_DIR/.codex/skills/debug-tools-hotswap" "Codex hotswap skill"
  remove_path "$HOME_DIR/.codex/plugins/debug-tools-ai" "Codex plugin files"
fi

if [[ "$uninstall_claude" == true ]]; then
  remove_path "$HOME_DIR/.claude/debug-tools-ai" "Claude Code instructions"
  remove_path "$HOME_DIR/.claude/plugins/debug-tools-ai" "Claude Code plugin files"
fi

if [[ "$uninstall_gemini" == true ]]; then
  remove_path "$HOME_DIR/.gemini/extensions/debug-tools-ai" "Gemini extension files"
fi

if [[ "$uninstall_opencode" == true ]]; then
  remove_path "$HOME_DIR/.config/opencode/debug-tools-ai" "OpenCode instructions"
  remove_path "$HOME_DIR/.config/opencode/plugins/debug-tools-ai.js" "OpenCode plugin file"
fi

if [[ "$uninstall_cursor" == true ]]; then
  remove_path "$HOME_DIR/.cursor/debug-tools-ai" "Cursor instructions"
  remove_path "$HOME_DIR/.cursor/plugins/debug-tools-ai" "Cursor plugin files"
fi

if [[ "$uninstall_kimi" == true ]]; then
  remove_path "$HOME_DIR/.kimi/debug-tools-ai" "Kimi instructions"
  remove_path "$HOME_DIR/.kimi/plugins/debug-tools-ai" "Kimi plugin files"
fi

if [[ "$uninstall_pi" == true ]]; then
  remove_path "$HOME_DIR/.pi/packages/debug-tools-ai" "Pi package files"
fi

echo "debug-tools-ai uninstall finished"

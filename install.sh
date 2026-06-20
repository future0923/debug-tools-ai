#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is required}"

bootstrap_from_remote() {
  local temp_dir
  local ref
  local repo
  local tarball_url
  local status

  ref="${DEBUG_TOOLS_AI_REF:-main}"
  repo="${DEBUG_TOOLS_AI_REPO:-future0923/debug-tools-ai}"
  tarball_url="${DEBUG_TOOLS_AI_TARBALL_URL:-https://github.com/${repo}/archive/refs/heads/${ref}.tar.gz}"

  if ! command -v curl >/dev/null 2>&1; then
    echo "Remote install requires curl when install.sh is not run from a checkout." >&2
    exit 1
  fi

  if ! command -v tar >/dev/null 2>&1; then
    echo "Remote install requires tar when install.sh is not run from a checkout." >&2
    exit 1
  fi

  temp_dir="$(mktemp -d)"
  echo "Downloading debug-tools-ai from $tarball_url"
  curl -fsSL "$tarball_url" -o "$temp_dir/debug-tools-ai.tar.gz"
  tar -xzf "$temp_dir/debug-tools-ai.tar.gz" -C "$temp_dir" --strip-components=1
  bash "$temp_dir/install.sh" "$@"
  status=$?
  rm -rf "$temp_dir"
  exit "$status"
}

if [[ ! -d "$ROOT/skills/debug-tools-method-invocation" ]]; then
  bootstrap_from_remote "$@"
fi

install_codex=false
install_claude=false
install_gemini=false
install_opencode=false
install_cursor=false
install_kimi=false
install_pi=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --all        Install files for every supported local agent
  --codex      Install Codex skill and plugin metadata
  --claude     Install Claude Code project instructions
  --gemini     Install Gemini extension metadata and instructions
  --opencode   Install OpenCode plugin and instructions
  --cursor     Install Cursor plugin metadata
  --kimi       Install Kimi plugin metadata
  --pi         Install Pi package metadata
  --help       Show this help

The installer copies this checkout into per-agent local directories. It does
not install DebugTools, IntelliJ, or MCP servers.

Remote one-line install:
  curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
EOF
}

copy_dir() {
  local source="$1"
  local target="$2"
  mkdir -p "$target"
  cp -R "$source"/. "$target"/
}

copy_file() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

copy_package() {
  local target="$1"
  mkdir -p "$target"
  copy_file "$ROOT/README.md" "$target/README.md"
  copy_file "$ROOT/LICENSE" "$target/LICENSE"
  copy_file "$ROOT/AGENTS.md" "$target/AGENTS.md"
  copy_file "$ROOT/CLAUDE.md" "$target/CLAUDE.md"
  copy_file "$ROOT/GEMINI.md" "$target/GEMINI.md"
  copy_file "$ROOT/gemini-extension.json" "$target/gemini-extension.json"
  copy_file "$ROOT/package.json" "$target/package.json"
  copy_file "$ROOT/install.sh" "$target/install.sh"
  copy_dir "$ROOT/bin" "$target/bin"
  copy_dir "$ROOT/docs" "$target/docs"
  copy_dir "$ROOT/scripts" "$target/scripts"
  copy_dir "$ROOT/tests" "$target/tests"
  copy_dir "$ROOT/skills" "$target/skills"
  copy_dir "$ROOT/.codex-plugin" "$target/.codex-plugin"
  copy_dir "$ROOT/.claude-plugin" "$target/.claude-plugin"
  copy_dir "$ROOT/.cursor-plugin" "$target/.cursor-plugin"
  copy_dir "$ROOT/.kimi-plugin" "$target/.kimi-plugin"
  copy_dir "$ROOT/.opencode" "$target/.opencode"
  copy_dir "$ROOT/.pi" "$target/.pi"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      install_codex=true
      install_claude=true
      install_gemini=true
      install_opencode=true
      install_cursor=true
      install_kimi=true
      install_pi=true
      ;;
    --codex) install_codex=true ;;
    --claude) install_claude=true ;;
    --gemini) install_gemini=true ;;
    --opencode) install_opencode=true ;;
    --cursor) install_cursor=true ;;
    --kimi) install_kimi=true ;;
    --pi) install_pi=true ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "$install_codex" == true ]]; then
  copy_dir "$ROOT/skills" "$HOME_DIR/.codex/skills"
  copy_dir "$ROOT/.codex-plugin" "$HOME_DIR/.codex/plugins/debug-tools-ai/.codex-plugin"
  copy_dir "$ROOT/skills" "$HOME_DIR/.codex/plugins/debug-tools-ai/skills"
  echo "Installed Codex files"
fi

if [[ "$install_claude" == true ]]; then
  copy_file "$ROOT/CLAUDE.md" "$HOME_DIR/.claude/debug-tools-ai/CLAUDE.md"
  copy_dir "$ROOT/.claude-plugin" "$HOME_DIR/.claude/plugins/debug-tools-ai/.claude-plugin"
  copy_dir "$ROOT/skills" "$HOME_DIR/.claude/plugins/debug-tools-ai/skills"
  echo "Installed Claude Code files"
fi

if [[ "$install_gemini" == true ]]; then
  copy_file "$ROOT/GEMINI.md" "$HOME_DIR/.gemini/extensions/debug-tools-ai/GEMINI.md"
  copy_file "$ROOT/gemini-extension.json" "$HOME_DIR/.gemini/extensions/debug-tools-ai/gemini-extension.json"
  copy_dir "$ROOT/skills" "$HOME_DIR/.gemini/extensions/debug-tools-ai/skills"
  echo "Installed Gemini files"
fi

if [[ "$install_opencode" == true ]]; then
  copy_file "$ROOT/AGENTS.md" "$HOME_DIR/.config/opencode/debug-tools-ai/AGENTS.md"
  copy_dir "$ROOT/.opencode/plugins" "$HOME_DIR/.config/opencode/plugins"
  copy_dir "$ROOT/skills" "$HOME_DIR/.config/opencode/debug-tools-ai/skills"
  echo "Installed OpenCode files"
fi

if [[ "$install_cursor" == true ]]; then
  copy_file "$ROOT/AGENTS.md" "$HOME_DIR/.cursor/debug-tools-ai/AGENTS.md"
  copy_dir "$ROOT/.cursor-plugin" "$HOME_DIR/.cursor/plugins/debug-tools-ai/.cursor-plugin"
  copy_dir "$ROOT/skills" "$HOME_DIR/.cursor/plugins/debug-tools-ai/skills"
  echo "Installed Cursor files"
fi

if [[ "$install_kimi" == true ]]; then
  copy_file "$ROOT/AGENTS.md" "$HOME_DIR/.kimi/debug-tools-ai/AGENTS.md"
  copy_dir "$ROOT/.kimi-plugin" "$HOME_DIR/.kimi/plugins/debug-tools-ai/.kimi-plugin"
  copy_dir "$ROOT/skills" "$HOME_DIR/.kimi/plugins/debug-tools-ai/skills"
  echo "Installed Kimi files"
fi

if [[ "$install_pi" == true ]]; then
  copy_package "$HOME_DIR/.pi/packages/debug-tools-ai"
  echo "Installed Pi package files"
fi

echo "debug-tools-ai installation finished"

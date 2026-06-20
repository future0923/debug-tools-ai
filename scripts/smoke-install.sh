#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_CODEX_HOME="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_HOME"
  rm -rf "$TMP_CODEX_HOME"
}
trap cleanup EXIT

HOME="$TMP_CODEX_HOME" "$ROOT/install.sh" --codex >/dev/null

codex_only_files=(
  ".codex/skills/debug-tools-method-invocation/SKILL.md"
  ".codex/skills/debug-tools-hotswap/SKILL.md"
  ".codex/plugins/debug-tools-ai/.codex-plugin/plugin.json"
  ".codex/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".codex/plugins/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
)

for file in "${codex_only_files[@]}"; do
  if [[ ! -f "$TMP_CODEX_HOME/$file" ]]; then
    echo "Codex install smoke test missing: $file" >&2
    exit 1
  fi
done

HOME="$TMP_CODEX_HOME" bash "$ROOT/bin/debug-tools-ai" uninstall --codex >/dev/null

codex_removed_paths=(
  ".codex/skills/debug-tools-method-invocation"
  ".codex/skills/debug-tools-hotswap"
  ".codex/plugins/debug-tools-ai"
)

for path in "${codex_removed_paths[@]}"; do
  if [[ -e "$TMP_CODEX_HOME/$path" ]]; then
    echo "Codex uninstall smoke test left path behind: $path" >&2
    exit 1
  fi
done

HOME="$TMP_HOME" "$ROOT/install.sh" --all >/dev/null

required_installed=(
  ".codex/skills/debug-tools-method-invocation/SKILL.md"
  ".codex/skills/debug-tools-hotswap/SKILL.md"
  ".codex/plugins/debug-tools-ai/.codex-plugin/plugin.json"
  ".codex/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".codex/plugins/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
  ".claude/debug-tools-ai/CLAUDE.md"
  ".claude/plugins/debug-tools-ai/.claude-plugin/plugin.json"
  ".claude/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".claude/plugins/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
  ".gemini/extensions/debug-tools-ai/GEMINI.md"
  ".gemini/extensions/debug-tools-ai/gemini-extension.json"
  ".gemini/extensions/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".gemini/extensions/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
  ".config/opencode/debug-tools-ai/AGENTS.md"
  ".config/opencode/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".config/opencode/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
  ".config/opencode/plugins/debug-tools-ai.js"
  ".cursor/debug-tools-ai/AGENTS.md"
  ".cursor/plugins/debug-tools-ai/.cursor-plugin/plugin.json"
  ".cursor/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".cursor/plugins/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
  ".kimi/debug-tools-ai/AGENTS.md"
  ".kimi/plugins/debug-tools-ai/.kimi-plugin/plugin.json"
  ".kimi/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".kimi/plugins/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
  ".pi/packages/debug-tools-ai/package.json"
  ".pi/packages/debug-tools-ai/bin/debug-tools-ai"
  ".pi/packages/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
  ".pi/packages/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
)

for file in "${required_installed[@]}"; do
  if [[ ! -f "$TMP_HOME/$file" ]]; then
    echo "Install smoke test missing: $file" >&2
    exit 1
  fi
done

python3 -m json.tool "$TMP_HOME/.codex/plugins/debug-tools-ai/.codex-plugin/plugin.json" >/dev/null
python3 -m json.tool "$TMP_HOME/.claude/plugins/debug-tools-ai/.claude-plugin/plugin.json" >/dev/null
python3 -m json.tool "$TMP_HOME/.cursor/plugins/debug-tools-ai/.cursor-plugin/plugin.json" >/dev/null
python3 -m json.tool "$TMP_HOME/.kimi/plugins/debug-tools-ai/.kimi-plugin/plugin.json" >/dev/null
python3 -m json.tool "$TMP_HOME/.gemini/extensions/debug-tools-ai/gemini-extension.json" >/dev/null
python3 -m json.tool "$TMP_HOME/.pi/packages/debug-tools-ai/package.json" >/dev/null

grep -q "debug-tools-method-invocation" "$TMP_HOME/.codex/skills/debug-tools-method-invocation/SKILL.md"
grep -q "debug-tools-hotswap" "$TMP_HOME/.codex/skills/debug-tools-hotswap/SKILL.md"
grep -q "generate_method_args_template" "$TMP_HOME/.config/opencode/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
grep -q "execute_debug_tools_run_configuration" "$TMP_HOME/.config/opencode/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
pressure_output="$(bash "$TMP_HOME/.pi/packages/debug-tools-ai/bin/debug-tools-ai" pressure)"
grep -q "ClassNotFound Uses DebugTools HTTP ClassLoader Recovery" <<<"$pressure_output"
HOME="$TMP_HOME" bash "$ROOT/bin/debug-tools-ai" doctor --strict-installed >/dev/null

HOME="$TMP_HOME" bash "$ROOT/bin/debug-tools-ai" uninstall --all >/dev/null

removed_after_all=(
  ".codex/skills/debug-tools-method-invocation"
  ".codex/skills/debug-tools-hotswap"
  ".codex/plugins/debug-tools-ai"
  ".claude/debug-tools-ai"
  ".claude/plugins/debug-tools-ai"
  ".gemini/extensions/debug-tools-ai"
  ".config/opencode/debug-tools-ai"
  ".config/opencode/plugins/debug-tools-ai.js"
  ".cursor/debug-tools-ai"
  ".cursor/plugins/debug-tools-ai"
  ".kimi/debug-tools-ai"
  ".kimi/plugins/debug-tools-ai"
  ".pi/packages/debug-tools-ai"
)

for path in "${removed_after_all[@]}"; do
  if [[ -e "$TMP_HOME/$path" ]]; then
    echo "Uninstall smoke test left path behind: $path" >&2
    exit 1
  fi
done

HOME="$TMP_HOME" "$ROOT/install.sh" --all >/dev/null

python3 - "$TMP_HOME" <<'PY'
from pathlib import Path
import sys

home = Path(sys.argv[1])
plugin_path = home / ".config/opencode/plugins/debug-tools-ai.js"
source = plugin_path.read_text(encoding="utf-8")

required_snippets = [
    "../opencode/debug-tools-ai",
    "config.skills.paths.push(skillsDir)",
]

for snippet in required_snippets:
    if snippet not in source:
        raise SystemExit(f"OpenCode plugin is missing install-path support snippet: {snippet}")

expected_skill = home / ".config/opencode/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md"
if not expected_skill.exists():
    raise SystemExit(f"OpenCode installed skill missing: {expected_skill}")

expected_hotswap_skill = home / ".config/opencode/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md"
if not expected_hotswap_skill.exists():
    raise SystemExit(f"OpenCode installed skill missing: {expected_hotswap_skill}")
PY

echo "install smoke test passed"

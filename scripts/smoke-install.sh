#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

# Simulate an existing package install with local edits and an unrelated user skill.
for legacy in debug-tools-method-invocation debug-tools-hotswap debug-tools-spring-config debug-tools-runtime-diagnostics; do
  mkdir -p "$TMP_HOME/.codex/skills/$legacy"
  printf '%s\n' '---' "name: $legacy" '---' 'local customization survives migration' > "$TMP_HOME/.codex/skills/$legacy/SKILL.md"
done
mkdir -p "$TMP_HOME/.codex/skills/unrelated-user-skill"
printf '%s\n' 'user owned' > "$TMP_HOME/.codex/skills/unrelated-user-skill/keep.txt"
HOME="$TMP_HOME" bash "$ROOT/install.sh" --codex >/dev/null
[[ ! -e "$TMP_HOME/.claude" ]]
[[ -f "$TMP_HOME/.codex/skills/debug-tools/SKILL.md" ]]
for legacy in debug-tools-method-invocation debug-tools-hotswap debug-tools-spring-config debug-tools-runtime-diagnostics; do
  [[ ! -e "$TMP_HOME/.codex/skills/$legacy" ]]
done
python3 - "$TMP_HOME" <<'PY'
from pathlib import Path
import sys
home = Path(sys.argv[1])
backups = list((home / '.local/share/debug-tools-ai/skill-backups').rglob('SKILL.md'))
assert len(backups) == 4
assert all('local customization survives migration' in p.read_text() for p in backups)
PY
HOME="$TMP_HOME" bash "$ROOT/install.sh" --all >/dev/null
HOME="$TMP_HOME" bash "$ROOT/install.sh" --all >/dev/null
python3 - "$TMP_HOME" <<'PY'
from pathlib import Path
import json
import sys
home = Path(sys.argv[1])
folders = ['.codex/skills', '.codex/plugins/debug-tools-ai/skills', '.claude/plugins/debug-tools-ai/skills',
           '.gemini/extensions/debug-tools-ai/skills', '.config/opencode/debug-tools-ai/skills',
           '.cursor/plugins/debug-tools-ai/skills', '.kimi/plugins/debug-tools-ai/skills', '.pi/packages/debug-tools-ai/skills']
for folder in folders:
    root = home / folder
    ours = {p.parent.name for p in root.glob('debug-tools*/SKILL.md')}
    assert ours == {'debug-tools'}, (folder, ours)
    for relative in ['SKILL.md', 'agents/openai.yaml', 'references/invocation.md', 'references/run-and-hotswap.md',
                     'references/spring.md', 'references/results-and-evidence.md', 'references/live-observation.md',
                     'references/extended-workflows.md']:
        assert (root / 'debug-tools' / relative).is_file(), (folder, relative)
for relative in ['.codex/plugins/debug-tools-ai/.codex-plugin/plugin.json', '.claude/plugins/debug-tools-ai/.claude-plugin/plugin.json',
                 '.cursor/plugins/debug-tools-ai/.cursor-plugin/plugin.json', '.kimi/plugins/debug-tools-ai/.kimi-plugin/plugin.json',
                 '.gemini/extensions/debug-tools-ai/gemini-extension.json', '.pi/packages/debug-tools-ai/package.json']:
    json.loads((home / relative).read_text())
for relative in ['.config/opencode/debug-tools-ai/AGENTS.md', '.cursor/debug-tools-ai/AGENTS.md', '.kimi/debug-tools-ai/AGENTS.md']:
    text = (home / relative).read_text()
    assert 'skills/debug-tools/SKILL.md' in text
    assert 'debug-tools-method-invocation' not in text
PY
HOME="$TMP_HOME" bash "$ROOT/bin/debug-tools-ai" doctor --strict-installed >/dev/null
node --test "$TMP_HOME/.pi/packages/debug-tools-ai/tests/adapters.test.mjs" >/dev/null
bash "$TMP_HOME/.pi/packages/debug-tools-ai/bin/debug-tools-ai" pressure >/dev/null
HOME="$TMP_HOME" bash "$ROOT/bin/debug-tools-ai" uninstall --all >/dev/null
[[ ! -e "$TMP_HOME/.codex/skills/debug-tools" ]]
[[ ! -e "$TMP_HOME/.pi/packages/debug-tools-ai" ]]
[[ -f "$TMP_HOME/.codex/skills/unrelated-user-skill/keep.txt" ]]
[[ -d "$TMP_HOME/.local/share/debug-tools-ai/skill-backups" ]]

# A same-named foreign folder must stop migration without destroying its content.
mkdir -p "$TMP_HOME/.codex/skills/debug-tools-hotswap"
printf '%s\n' '---' 'name: foreign-skill' '---' > "$TMP_HOME/.codex/skills/debug-tools-hotswap/SKILL.md"
if HOME="$TMP_HOME" bash "$ROOT/install.sh" --codex >/dev/null 2>&1; then
  echo 'Installer accepted a foreign legacy folder' >&2
  exit 1
fi
grep -q 'name: foreign-skill' "$TMP_HOME/.codex/skills/debug-tools-hotswap/SKILL.md"
echo 'install, migration, backup, repeat-install and uninstall smoke passed'

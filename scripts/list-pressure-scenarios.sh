#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRESSURE_DIR="$ROOT/tests/pressure"

cat <<'EOF'
DebugTools AI pressure scenarios

Run each scenario with a fresh AI agent and the relevant skill:
  skills/debug-tools-method-invocation/SKILL.md
  skills/debug-tools-hotswap/SKILL.md

Ask the agent:
  Read the relevant skill, run this scenario mentally, and return PASS or FAIL against the pass criteria with evidence.

Record results with:
  Scenario: <file>
  Verdict: PASS|FAIL
  Evidence:
  Notes:

Scenarios:
EOF

find "$PRESSURE_DIR" -name '*.md' ! -name 'README.md' | sort | while read -r file; do
  title="$(sed -n '1s/^# //p' "$file")"
  printf '  - %s: %s\n' "$(basename "$file")" "$title"
done

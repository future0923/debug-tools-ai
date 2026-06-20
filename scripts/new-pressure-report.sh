#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRESSURE_DIR="$ROOT/tests/pressure"
date_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat <<EOF
# DebugTools MCP Pressure Run

- Date: $date_utc
- Skill: skills/debug-tools-mcp/SKILL.md
- Runner:
- Agent/runtime:

## Instructions

For each scenario, start from a fresh agent context with the skill attached. Ask:

\`\`\`text
Read the debug-tools-mcp skill, run this scenario mentally, and return PASS or FAIL against the pass criteria with evidence.
\`\`\`

## Results

EOF

find "$PRESSURE_DIR" -name '*.md' ! -name 'README.md' | sort | while read -r file; do
  name="$(basename "$file")"
  title="$(sed -n '1s/^# //p' "$file")"
  cat <<EOF
### $name

- Title: $title
- Verdict: TODO
- Evidence:
- Notes:

EOF
done

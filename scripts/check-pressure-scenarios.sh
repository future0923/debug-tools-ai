#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRESSURE_DIR="$ROOT/tests/pressure"

required_sections=(
  "## Scenario"
  "## Expected Behavior"
  "## Pass Criteria"
  "## Fail Signals"
)

for file in "$PRESSURE_DIR"/*.md; do
  [[ "$(basename "$file")" == "README.md" ]] && continue

  for section in "${required_sections[@]}"; do
    if ! grep -q "^$section$" "$file"; then
      echo "Pressure scenario $(basename "$file") is missing section: $section" >&2
      exit 1
    fi
  done
done

scenario_count="$(find "$PRESSURE_DIR" -name '*.md' ! -name 'README.md' | wc -l | tr -d '[:space:]')"
if [[ "$scenario_count" -lt 5 ]]; then
  echo "Expected at least 5 pressure scenarios, found $scenario_count" >&2
  exit 1
fi

echo "pressure scenario check passed: $scenario_count scenarios"

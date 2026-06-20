#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

version_of() {
  local file="$1"
  python3 - "$ROOT/$file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(data.get("version", ""))
PY
}

package_version="$(version_of package.json)"

version_files=(
  ".codex-plugin/plugin.json"
  ".claude-plugin/plugin.json"
  ".cursor-plugin/plugin.json"
  ".kimi-plugin/plugin.json"
  "gemini-extension.json"
)

if [[ -z "$package_version" ]]; then
  echo "package.json is missing version" >&2
  exit 1
fi

for file in "${version_files[@]}"; do
  version="$(version_of "$file")"
  if [[ "$version" != "$package_version" ]]; then
    echo "Version mismatch: $file has '$version', expected '$package_version'" >&2
    exit 1
  fi
done

if ! grep -Eq "^## (\\[$package_version\\]|$package_version)$" "$ROOT/CHANGELOG.md"; then
  echo "CHANGELOG.md is missing an entry for version $package_version" >&2
  exit 1
fi

echo "version check passed: $package_version"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/scripts/validate.sh"

archive="$(bash "$ROOT/scripts/package-release.sh")"

version="$(python3 - "$ROOT/package.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["version"])
PY
)"

tag="v$version"

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$ROOT" rev-parse "$tag" >/dev/null 2>&1; then
    echo "Tag already exists locally: $tag" >&2
    exit 1
  fi
fi

echo "prepublish check passed"
echo "version: $version"
echo "expected tag: $tag"
echo "archive: $archive"

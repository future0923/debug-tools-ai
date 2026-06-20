#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-${TMPDIR:-/tmp}/debug-tools-ai-dist}"

version="$(python3 - "$ROOT/package.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    print(json.load(fh)["version"])
PY
)"

archive="$DIST_DIR/debug-tools-ai-$version.tar.gz"
mkdir -p "$DIST_DIR"
rm -f "$archive"

tar \
  --exclude='.git' \
  --exclude='dist' \
  -czf "$archive" \
  -C "$ROOT" \
  .

echo "$archive"

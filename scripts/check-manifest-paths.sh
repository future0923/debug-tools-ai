#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])

def load(path):
    return json.loads((root / path).read_text(encoding="utf-8"))

def require_exists(path, source):
    target = root / path
    if not target.exists():
        raise SystemExit(f"{source} points to missing path: {path}")

package = load("package.json")
require_exists(package["main"], "package.json main")
for name, path in package.get("bin", {}).items():
    require_exists(path, f"package.json bin.{name}")
for path in package.get("files", []):
    require_exists(path, "package.json files")
for path in package.get("pi", {}).get("extensions", []):
    require_exists(path, "package.json pi.extensions")
for path in package.get("pi", {}).get("skills", []):
    require_exists(path, "package.json pi.skills")

for manifest_path in [".codex-plugin/plugin.json", ".cursor-plugin/plugin.json"]:
    manifest = load(manifest_path)
    skills = manifest.get("skills")
    if skills:
        require_exists(skills, f"{manifest_path} skills")

gemini = load("gemini-extension.json")
require_exists(gemini["contextFileName"], "gemini-extension.json contextFileName")

claude_marketplace = load(".claude-plugin/marketplace.json")
for plugin in claude_marketplace.get("plugins", []):
    source = plugin.get("source", {})
    if source.get("source") == "local":
        require_exists(source.get("path", "."), ".claude-plugin/marketplace.json local path")

required_plugin_files = [
    ".claude-plugin/plugin.json",
    ".kimi-plugin/plugin.json",
    ".opencode/plugins/debug-tools-ai.js",
]
for path in required_plugin_files:
    require_exists(path, "plugin file")

print("manifest path check passed")
PY

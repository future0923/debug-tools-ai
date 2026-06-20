#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
pkg = json.loads((root / "package.json").read_text(encoding="utf-8"))

required_exact = {
    "name": "debug-tools-ai",
    "type": "module",
    "main": ".opencode/plugins/debug-tools-ai.js",
    "license": "MIT",
    "homepage": "https://github.com/future0923/debug-tools-ai",
}

for key, expected in required_exact.items():
    actual = pkg.get(key)
    if actual != expected:
        raise SystemExit(f"package.json {key} is {actual!r}, expected {expected!r}")

repository = pkg.get("repository")
if not isinstance(repository, dict) or repository.get("type") != "git":
    raise SystemExit("package.json repository must be an object with type=git")
if repository.get("url") != "git+https://github.com/future0923/debug-tools-ai.git":
    raise SystemExit("package.json repository.url must point to the GitHub repository")

bin_map = pkg.get("bin")
if not isinstance(bin_map, dict) or bin_map.get("debug-tools-ai") != "bin/debug-tools-ai":
    raise SystemExit("package.json bin.debug-tools-ai must point to bin/debug-tools-ai")

files = pkg.get("files")
required_files = {
    "bin",
    "docs",
    "examples",
    "scripts",
    "skills",
    "tests/pressure",
    ".codex-plugin",
    ".claude-plugin",
    ".cursor-plugin",
    ".kimi-plugin",
    ".opencode",
    ".pi",
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "install.sh",
    "gemini-extension.json",
}
if not isinstance(files, list):
    raise SystemExit("package.json files must be a list")
missing = sorted(required_files.difference(files))
if missing:
    raise SystemExit("package.json files is missing: " + ", ".join(missing))

publish_config = pkg.get("publishConfig")
if not isinstance(publish_config, dict) or publish_config.get("access") != "public":
    raise SystemExit("package.json publishConfig.access must be public")
PY

required_release_terms=(
  "npm publish"
  "git tag"
  "GitHub release"
  "softprops/action-gh-release"
  "tags:"
  "bash scripts/validate.sh"
  "bash scripts/check-versions.sh"
  "bash scripts/check-manifest-paths.sh"
  "bash scripts/smoke-install.sh"
  "bash scripts/package-release.sh"
  "prepublish-check"
  "debug-tools-ai doctor"
  "curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh"
  "examples/spring-boot-demo.md"
  "pressure"
  "debug-tools-invoking-methods"
  "debug-tools-args-json"
  "debug-tools-classloader-recovery"
)

for term in "${required_release_terms[@]}"; do
  if ! grep -R "$term" "$ROOT/docs/release.md" "$ROOT/README.md" "$ROOT/CONTRIBUTING.md" "$ROOT/.github/workflows/release.yml" >/dev/null; then
    echo "Release readiness docs missing: $term" >&2
    exit 1
  fi
done

echo "release readiness check passed"

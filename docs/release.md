# Release Process

Use this checklist before publishing a DebugTools AI release.

## Version

Update the same version in:

- `package.json`
- `.codex-plugin/plugin.json`
- `.claude-plugin/plugin.json`
- `.cursor-plugin/plugin.json`
- `.kimi-plugin/plugin.json`
- `gemini-extension.json`

Add a matching entry to `CHANGELOG.md`.

Verify:

```bash
bash scripts/check-versions.sh
```

## Validation

Run:

```bash
bash scripts/validate.sh
bash scripts/check-manifest-paths.sh
bash scripts/package-release.sh
```

This includes install smoke testing with a temporary `HOME`.
By default, the release archive is written under `${TMPDIR:-/tmp}/debug-tools-ai-dist`. Set `DIST_DIR=dist` to write into the repository checkout.

Also verify the package CLI:

```bash
bash bin/debug-tools-ai validate
bash bin/debug-tools-ai pressure
bash bin/debug-tools-ai pressure-report
```

## Skill Pressure Test

Run at least the pressure scenarios that match the release changes:

```text
tests/pressure/
```

For a release that changes MCP workflow behavior, run all scenarios with a fresh AI agent and record PASS/FAIL notes.

Generate a report template:

```bash
bash bin/debug-tools-ai pressure-report > pressure-run.md
```

Fill the report with the fresh-agent results and attach it to the release PR.

## npm Package

Before publishing:

```bash
bash scripts/check-release-readiness.sh
bash bin/debug-tools-ai prepublish-check
npm pack --dry-run
npm publish
```

The npm package exposes:

```bash
debug-tools-ai install --codex
debug-tools-ai upgrade --all
debug-tools-ai validate
debug-tools-ai pressure
debug-tools-ai pressure-report
```

## GitHub Release

1. Commit the release changes.
2. Tag the release:

```bash
git tag v0.1.0
git push origin main --tags
```

3. The `Release` GitHub Actions workflow validates the package, creates an archive, and creates the GitHub release.
4. Review the generated release notes and paste in the matching `CHANGELOG.md` section if needed.

## Marketplace and Host Submission

After the GitHub release:

- Codex: submit or install through the repository plugin flow when available.
- Claude Code: submit `.claude-plugin/` metadata when marketplace submission is available.
- Gemini: verify `gemini-extension.json`, then use the host extension submission or Git URL install.
- OpenCode: verify `.opencode/plugins/debug-tools-ai.js` with `bash scripts/smoke-install.sh`.
- Cursor, Kimi, and Pi: submit host-specific metadata when their review flow is available.

If a host rejects the package, fix the adapter and add a validation check before retrying.

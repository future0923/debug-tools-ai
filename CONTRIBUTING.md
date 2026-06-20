# Contributing

DebugTools AI is a skill and installer package. Treat changes as behavior changes for future agents, not only documentation edits.

## Before Opening a PR

Run:

```bash
bash scripts/validate.sh
```

The package CLI equivalent is:

```bash
bash bin/debug-tools-ai validate
```

This checks:

- required package files and plugin manifests
- version consistency across manifests
- manifest path references such as `skills`, `bin`, and Gemini context files
- installer smoke test with a temporary `HOME`
- pressure scenario coverage
- shell syntax and JSON validity

## Skill Changes

When changing `skills/debug-tools-mcp/SKILL.md` or its references:

1. Add or update a pressure scenario in `tests/pressure/` for the behavior.
2. Keep `SKILL.md` short; move heavy protocol detail to `skills/debug-tools-mcp/references/`.
3. Use direct DebugTools HTTP for ClassLoader discovery; do not add `list_debug_tools_classloaders`.
4. Run `bash scripts/validate.sh`.
5. If the change affects judgment, run at least one scenario with a fresh AI agent and record the result in the PR.

Generate a report template with:

```bash
bash bin/debug-tools-ai pressure-report
```

## Skill Classification

Keep `debug-tools-mcp` as the primary skill while the workflow is one connected method-invocation loop.

Do not split only because a reference file is long. Split only when a future agent should discover and load a topic independently. Likely future split candidates are:

- `debug-tools-invoking-methods`
- `debug-tools-args-json`
- `debug-tools-classloader-recovery`

Before splitting, add pressure scenarios proving the separated skill is discovered at the right time and does not hide required method-invocation context.

Each pressure scenario must include:

- `## Scenario`
- `## Expected Behavior`
- `## Pass Criteria`
- `## Fail Signals`

## Installer Changes

When changing `install.sh` or platform plugin files:

1. Update `scripts/smoke-install.sh`.
2. Verify installed files under a temporary `HOME`.
3. Check that plugin metadata points to files that are actually installed.

## Release Changes

When changing the package version:

1. Update every manifest version checked by `scripts/check-versions.sh`.
2. Add a matching `CHANGELOG.md` entry.
3. Run `bash scripts/check-release-readiness.sh`.
4. Run `bash bin/debug-tools-ai prepublish-check` before publishing.
5. Follow `docs/release.md`.

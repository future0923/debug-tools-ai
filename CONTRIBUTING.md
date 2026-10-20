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

When changing `skills/debug-tools/SKILL.md` or its references:

1. Add or update a pressure scenario in `tests/pressure/` for the behavior.
2. Keep `SKILL.md` short; move heavy method-invocation protocol detail to `skills/debug-tools/references/`.
3. Prefer exposed `find_class_loaders`; retain documented HTTP fallback after MCP target discovery.
4. Run `bash scripts/validate.sh`.
5. If the change affects judgment, run at least one scenario with a fresh AI agent and record the result in the PR.

Generate a report template with:

```bash
bash bin/debug-tools-ai pressure-report
```

## Skill Classification

Keep one discoverable `debug-tools` skill for the full requested workflow. Organize
startup/reload, invocation/results/streams, Spring and diagnosis in references
rather than introducing topic skills that hand off to each other. MCP categories
organize tool ownership separately; they do not require independent skill entries.
Update [workflow groups](docs/workflow-groups.md) and pressure scenarios when
changing these boundaries.

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

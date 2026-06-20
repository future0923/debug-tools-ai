# DebugTools AI Agent Instructions

Use these instructions for the whole `debug-tools-ai` repository. This package teaches
AI agents how to operate DebugTools IntelliJ MCP tools, so documentation, skill,
installer, and test changes can all change future agent behavior.

## Project Shape

- Core workflow docs live in `docs/workflow.md` and `docs/tool-contracts.md`.
- Method invocation guidance lives in `skills/debug-tools-method-invocation/SKILL.md`.
- Method invocation references live in `skills/debug-tools-method-invocation/references/`.
- Hotswap run configuration guidance lives in `skills/debug-tools-hotswap/SKILL.md`.
- Pressure scenarios live in `tests/pressure/`.
- Installers, validation, release, and adapter sync scripts live in `scripts/`.
- Agent entry files include `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and packaged
  plugin manifests.
- `package.json` is the package manifest and defines the supported validation
  commands.

## Method Invocation Workflow

Apply this workflow when the user asks to attach a JVM, inspect DebugTools
connections, generate method parameters, select ClassLoaders, or invoke Java
methods through DebugTools.

1. Call `list_debug_tools_connections` before attaching unless the user supplied
   a fresh PID.
2. Reuse a suitable active connection when possible.
3. If no suitable connection exists, call `list_attachable_jvms`, select the
   target PID, then call `attach_local_jvm`.
4. If `list_attachable_jvms` returns `count=0` or an empty `jvms` list, call
   `list_debug_tools_run_configurations` and offer only startup paths supported
   by actual context. If only DebugTools Hotswap is known to be available, ask
   whether to start one with Hotswap unless the user already authorized
   launch-if-needed behavior. If IDEA native Run/Debug is also known to be
   available from user context, tool output, or a future MCP capability, ask the
   user to choose between Hotswap and native Run/Debug.
5. After any Hotswap startup request, call `list_debug_tools_connections` again
   before invoking. Do not treat `execute_debug_tools_run_configuration.success=true`
   as proof that DebugTools is connected.
6. If the user chooses IDEA native Run/Debug, ask them to start the app in IDEA,
   then repeat connection discovery after they report startup is complete.
7. For parameterized methods, overloaded methods, unclear parameter names, or
   complex argument types, call `generate_method_args_template`.
8. Fill the returned `argsJson` by editing `content` values while preserving
   generated keys, order, and RunContentDTO shape.
9. Call `invoke_java_method`.
10. If invocation fails, recover from the specific error instead of retrying the
   same call unchanged.

Use `debug-tools-method-invocation` for this workflow.

## Hotswap Workflow

Apply this workflow when the user asks to list IntelliJ run configurations or
start a run configuration with DebugTools Hotswap.

1. If the exact configuration name is unknown or ambiguous, call
   `list_debug_tools_run_configurations`; pass `moduleName`,
   `mainClassNameContains`, or `typeDisplayName` filters when known.
2. Match the target by exact configuration `name`; use type, main class, and
   module fields only to disambiguate.
3. Ask the user to choose when multiple configurations remain plausible.
4. Call `execute_debug_tools_run_configuration` with the exact
   `configurationName`.
5. Treat `success=true` as "startup was requested", not as proof that DebugTools
   is connected.
6. Follow `nextAction`; if `requiresManualAttach=true` or
   `autoAttachEnabled=false`, do not assume DebugTools will attach automatically.

Use `debug-tools-hotswap` for this workflow. Switch back to
`debug-tools-method-invocation` only when the user asks to inspect connections,
attach, generate args, or invoke a method.

## MCP Tool Rules

- Prefer DebugTools MCP tools over shell process inspection for invocation work.
  Do not use `jps`, `ps`, run configuration files, or local port probing as the
  primary connection-selection path unless the user explicitly asks for those
  diagnostics.
- Use `connectionId` when more than one active DebugTools connection exists.
- Use `parameterTypes` for overloaded methods or when template generation reports
  ambiguity.
- Preserve generated parameter names and method declaration order.
- Use ordered fallback keys such as `arg0`, `arg1`, and `arg2` only when reliable
  parameter names are unavailable.
- Do not wrap `argsJson` in `targetMethodContent`.
- For no-argument methods, omit `argsJson` or pass `{}`.
- If MCP reports that the target project is ambiguous, retry the same MCP
  operation with the inferred `projectPath` when it can be determined from the
  source path or current repository.
- If this skill source repository is open beside a Java application repository,
  do not select the skill source repository for runtime method invocation unless
  the target explicitly belongs to it.
- Use Hotswap startup only as a recovery path when there is no active connection
  and no attachable JVM. Ask before starting a run configuration unless the user
  explicitly asked to launch if needed.
- Do not always offer IDEA native Run/Debug startup. Include it only when actual
  user context, tool output, or a future MCP capability shows it is available.

## ClassLoader Rules

- Do not query ClassLoaders during the normal path.
- Use `classLoaderIdentity` only when the user selected one, the connection has a
  relevant default ClassLoader, or the failure indicates class-not-found,
  bean-not-found, framework-context mismatch, or wrong class version.
- ClassLoader discovery is direct DebugTools HTTP, not an MCP tool. Do not invent
  or look for a dedicated MCP ClassLoader-listing tool.
- Use `host` and `httpPort` from `list_debug_tools_connections` for:
  - `GET /allClassLoader`
  - `POST /classLoader/hasClass`
- If exactly one ClassLoader can load the target class, pass its identity to
  `invoke_java_method.classLoaderIdentity`.
- If multiple ClassLoaders can load the target class, ask the user to choose
  instead of guessing from loader names.

## Editing Guidelines

- Treat skill and documentation edits as behavior changes for future agents.
- Keep `skills/debug-tools-method-invocation/SKILL.md` concise; move heavy
  method-invocation protocol details to
  `skills/debug-tools-method-invocation/references/`.
- Keep `debug-tools-method-invocation` and `debug-tools-hotswap` separate unless
  a future workflow genuinely requires one combined trigger.
- Split skills only when a future agent should discover and load a topic
  independently, and add pressure scenarios proving discovery still works.
- When changing installer behavior or plugin files, update smoke tests and verify
  installed paths under a temporary `HOME`.
- When changing package version data, update every manifest covered by
  `scripts/check-versions.sh`, add a matching `CHANGELOG.md` entry, and follow
  `docs/release.md`.
- Do not add a dedicated MCP ClassLoader-listing step; ClassLoader recovery uses
  direct DebugTools HTTP.

## Validation

Before opening a PR or handing off a meaningful change, run:

```bash
bash scripts/validate.sh
```

Equivalent package command:

```bash
bash bin/debug-tools-ai validate
```

Focused checks:

```bash
bash scripts/check-versions.sh
bash scripts/check-manifest-paths.sh
bash scripts/smoke-install.sh
bash scripts/check-pressure-scenarios.sh
bash scripts/check-release-readiness.sh
bash bin/debug-tools-ai prepublish-check
```

For skill behavior changes:

1. Add or update a pressure scenario in `tests/pressure/`.
2. Ensure every scenario contains `## Scenario`, `## Expected Behavior`,
   `## Pass Criteria`, and `## Fail Signals`.
3. Run `bash scripts/validate.sh`.
4. If the change affects agent judgment, run at least one scenario with a fresh
   AI agent and record the result in the PR.

Generate a pressure report template with:

```bash
bash bin/debug-tools-ai pressure-report
```

## Reference Order

When DebugTools workflow details are needed, read these in order:

1. `docs/workflow.md`
2. `docs/tool-contracts.md`
3. `skills/debug-tools-method-invocation/SKILL.md` or
   `skills/debug-tools-hotswap/SKILL.md`
4. Relevant files in `skills/debug-tools-method-invocation/references/`

For release work, read `docs/release.md`. For installation behavior, read
`docs/installation.md` and `scripts/smoke-install.sh`.

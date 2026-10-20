
# DebugTools Hotswap

Use DebugTools Hotswap tools to start IntelliJ run configurations through the DebugTools Hotswap executor, trigger IDEA Java Debugger Compile and Reload Modified Files, query pending operations, and orchestrate a reload → invoke loop. If the user later asks for standalone connection discovery, attach, or argument preparation, continue with [method invocation](invocation.md).

## Toolset

Run and reload tools include the following; `run_and_invoke` belongs to the invocation workflow and composes reload when requested:

- `list_debug_tools_run_configurations`
- `execute_debug_tools_run_configuration`
- `compile_and_reload_modified_files`
- `get_hotswap_operation`
- `run_and_invoke`

## Missing Tool Failure

If a requested startup or reload step requires a tool missing from the current MCP catalog, stop that dependent step and report the missing capability. Do not require unrelated tools for a standalone request. Do not inspect IDE files, run shell process discovery, launch applications directly, or use ordinary Java/Maven/Gradle commands as fallbacks.

Tell the user to check that the IDEA MCP server is available and that the DebugTools IDEA plugin registers the tools listed above.

## Decision Rules

- If the user gives an exact run configuration name, call `execute_debug_tools_run_configuration` with that `configurationName`.
- If the configuration name is missing, partial, or ambiguous, call `list_debug_tools_run_configurations` first. When module, main class, or type is known, pass `moduleName`, `mainClassNameContains`, or `typeDisplayName` filters.
- Match `configurationName` exactly from the list result before executing. Ask the user to choose when more than one configuration remains plausible.
- A standalone startup request ends after reporting its actual startup state. A combined user-requested workflow continues through shared connection discovery and invocation steps; do not invoke a method merely to verify startup.
- Treat `execute_debug_tools_run_configuration.success=true` as "startup was requested", not as proof that the JVM is running or DebugTools is connected.
- Use the returned `nextAction` and `requiresManualAttach` fields to decide the next workflow step. If `requiresManualAttach=true` or `autoAttachEnabled=false`, do not assume DebugTools will attach automatically after launch. Tell the user auto attach is disabled when it matters.
- If execution fails because the configuration is missing, use `availableConfigurationNames` to help the user choose a valid configuration.
- If execution fails because the run configuration does not support the DebugTools Hotswap executor, report that limitation instead of retrying unchanged.
- When the current task needs recent Java code changes loaded into an already-debugged JVM, call `compile_and_reload_modified_files` directly. Do not inspect `git status` to decide its scope, and do not refuse because the worktree has unrelated VCS changes.
- For `compile_and_reload_modified_files`, "modified files" means IDEA Java Debugger HotSwap changed files/classes tracked since debugger session start or the previous reload; it is not based on VCS/git modified files.
- If `compile_and_reload_modified_files` returns multiple `availableSessionNames`, ask the user to choose a session or pass the intended `sessionName` when it is already clear.
- Pass `waitMillis` when the caller needs bounded feedback. If an operation id is returned after timeout, call `get_hotswap_operation` rather than submitting the same reload again.
- A successful request means IDEA accepted the action. Use `status`, `errorCode`, and `classResults` when present; do not claim every class was reloaded when IDEA only returned a request-level status.
- When multiple debugger sessions exist, use the explicit `sessionName`; do not infer a session from a fuzzy process name.
- Use `run_and_invoke` for a complete loop. `allowStart=true` requires an exact `runConfigurationName`, and `allowAttach=true` requires an explicit `pid`; both are opt-in.

## Hotswap Pattern

1. Identify the requested run configuration name, module, main class, or application hint.
2. If the exact `configurationName` is unknown, call `list_debug_tools_run_configurations`.
3. Select one exact configuration name when it is clear from `name`, `typeName`, `typeDisplayName`, `mainClassName`, or `moduleName`.
4. If multiple configurations match, ask the user to choose by exact `name`.
5. Call `execute_debug_tools_run_configuration` with:

```json
{
  "configurationName": "DemoApplication"
}
```

6. Read the result:
   - `success=true`: report that the DebugTools Hotswap start was requested.
   - `success=false`: report `message` and any `availableConfigurationNames`.
   - `nextAction=LIST_DEBUG_TOOLS_CONNECTIONS`: connection discovery should be retried before invoking.
   - `nextAction=LIST_ATTACHABLE_JVMS`: enumerate attachable JVMs and attach if the broader workflow already authorized startup/invocation.
   - `requiresManualAttach=true` or `autoAttachEnabled=false`: do not claim that DebugTools will auto attach.
7. For follow-up connection or method calls already included in the request, continue with [invocation](invocation.md) in this same skill.

## Compile And Reload Pattern

Call `compile_and_reload_modified_files` whenever the task needs IDEA to compile and HotSwap recent changes into an attached Java debugger session, such as after editing Java code and needing live verification. This mirrors IDEA Java Debugger's Compile and Reload Modified Files action. The changed-file set is IDEA's HotSwap increment since session start or the previous reload, not the git/VCS dirty set. Do not infer completion from `success=true` alone: inspect `status`, and query a returned `operationId` with `get_hotswap_operation` until its documented terminal state. IDEA also reports compile and HotSwap progress or failures through native UI/notifications.

## Closed-Loop Pattern

When the user asks to reload code and immediately exercise it, use `run_and_invoke` when available. It can return status, HotSwap, invocation, and optional log/SQL steps in one response. It must not start or attach implicitly: require an exact `runConfigurationName` with `allowStart=true`, or an explicit `pid` with `allowAttach=true`.

## Result Shape

`list_debug_tools_run_configurations` returns:

- `count`
- `configurations[].name`
- `configurations[].typeName`
- `configurations[].typeDisplayName`
- `configurations[].mainClassName`
- `configurations[].moduleName`

`compile_and_reload_modified_files` returns:

- `success`
- `sessionName`
- `compileBeforeReload`
- `message`
- `availableSessionNames`
- `operationId`
- `status`
- `changedFiles`
- `compiledClasses`
- `reloadedClasses`
- `skippedClasses`
- `classResults`
- `error`
- `errorCode`

`execute_debug_tools_run_configuration` returns:

- `success`
- `configurationName`
- `executorId`
- `autoAttachEnabled`
- `requiresManualAttach`
- `nextAction`
- `expectedMainClassName`
- `expectedModuleName`
- `message`
- `availableConfigurationNames`

`get_hotswap_operation` accepts `operationId` and returns the latest reload status. `run_and_invoke` accepts `className`, `methodName`, `resultView`, `waitMillis`, `allowStart`, `runConfigurationName`, `allowAttach`, `pid`, `verifyLogs`, and `verifySql` in addition to method invocation fields.

## Completion contract

For reload-dependent invocation, wait for `status=SUCCESS` from the same project and `operationId`. `REQUESTED`, `COMPILING`, `RELOADING`, and `TIMEOUT` do not permit invocation. Use `get_hotswap_operation` to continue observing; do not submit a duplicate reload. An older plugin exposing only request submission cannot prove completion. Empty per-class details mean unavailable detail, not that zero classes changed. `run_and_invoke` keeps one target connection and requires a successful reload before invoking. Log/SQL evidence failures are distinct from invocation failure.

## Additional runtime tools

When actually exposed, use `inspect_spring_beans` and `explain_spring_config` for context/bean metadata and property precedence. For related deployment, run lifecycle, Kubernetes, or result comparisons requested by the user, continue with [extended workflows](extended-workflows.md) in this same skill. Do not infer these capabilities from the plugin version alone.

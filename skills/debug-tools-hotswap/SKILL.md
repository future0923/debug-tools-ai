---
name: debug-tools-hotswap
description: Use when operating DebugTools IntelliJ MCP Hotswap tools to list or start IntelliJ run configurations with DebugTools Hotswap, or to trigger IDEA Java Debugger Compile and Reload Modified Files when a task needs recent code changes loaded into the debugged JVM; includes list_debug_tools_run_configurations, execute_debug_tools_run_configuration, and compile_and_reload_modified_files.
---

# DebugTools Hotswap

Use DebugTools Hotswap tools to start IntelliJ run configurations through the DebugTools Hotswap executor, and to trigger IDEA Java Debugger Compile and Reload Modified Files when recent code changes need to reach the debugged JVM. This skill is for Hotswap launch and reload workflows, not Java method invocation. If the user later asks to inspect DebugTools connections, attach a JVM, generate method args, or invoke a Java method, use the `debug-tools-method-invocation` skill.

## Toolset

These tools are exposed under `DebugToolsHotswapToolset`:

- `list_debug_tools_run_configurations`
- `execute_debug_tools_run_configuration`
- `compile_and_reload_modified_files`

## Missing Tool Failure

If this skill is selected but the current Codex tool context does not expose the DebugTools Hotswap MCP tools, stop immediately and report a configuration error. Do not inspect IDE files, run shell process discovery, launch applications directly, or use ordinary Java/Maven/Gradle commands as fallbacks.

Tell the user to check that the IDEA MCP server is available and that the DebugTools IDEA plugin registers `list_debug_tools_run_configurations`, `execute_debug_tools_run_configuration`, and `compile_and_reload_modified_files`.

## Decision Rules

- If the user gives an exact run configuration name, call `execute_debug_tools_run_configuration` with that `configurationName`.
- If the configuration name is missing, partial, or ambiguous, call `list_debug_tools_run_configurations` first. When module, main class, or type is known, pass `moduleName`, `mainClassNameContains`, or `typeDisplayName` filters.
- Match `configurationName` exactly from the list result before executing. Ask the user to choose when more than one configuration remains plausible.
- Do not call Java method invocation tools before Hotswap launch unless the user explicitly asks for connection inspection, attach, args template generation, or method invocation.
- Treat `execute_debug_tools_run_configuration.success=true` as "startup was requested", not as proof that the JVM is running or DebugTools is connected.
- Use the returned `nextAction` and `requiresManualAttach` fields to decide the next workflow step. If `requiresManualAttach=true` or `autoAttachEnabled=false`, do not assume DebugTools will attach automatically after launch. Tell the user auto attach is disabled when it matters.
- If execution fails because the configuration is missing, use `availableConfigurationNames` to help the user choose a valid configuration.
- If execution fails because the run configuration does not support the DebugTools Hotswap executor, report that limitation instead of retrying unchanged.
- When the current task needs recent Java code changes loaded into an already-debugged JVM, call `compile_and_reload_modified_files` directly. Do not inspect `git status` to decide its scope, and do not refuse because the worktree has unrelated VCS changes.
- For `compile_and_reload_modified_files`, "modified files" means IDEA Java Debugger HotSwap changed files/classes tracked since debugger session start or the previous reload; it is not based on VCS/git modified files.
- If `compile_and_reload_modified_files` returns multiple `availableSessionNames`, ask the user to choose a session or pass the intended `sessionName` when it is already clear.

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
7. For follow-up connection or method calls, switch to `debug-tools-method-invocation`.

## Compile And Reload Pattern

Call `compile_and_reload_modified_files` whenever the task needs IDEA to compile and HotSwap recent changes into an attached Java debugger session, such as after editing Java code and needing live verification. This mirrors IDEA Java Debugger's Compile and Reload Modified Files action. The changed-file set is IDEA's HotSwap increment since session start or the previous reload, not the git/VCS dirty set. Treat `success=true` as a submitted request; compile and HotSwap progress or failures remain in IDEA's native UI/notifications.

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

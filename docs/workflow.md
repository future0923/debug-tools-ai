# DebugTools AI Workflow

This document is the shared workflow source for AI agents using DebugTools through IntelliJ MCP tools.

## Supported MCP Tools

`DebugToolsMethodInvocationToolset`:

- `list_debug_tools_connections` - list current DebugTools connections already known to the IDE.
- `list_attachable_jvms` - list local JVM processes that can be attached.
- `attach_local_jvm` - attach the DebugTools agent to a local JVM process.
- `generate_method_args_template` - generate DebugTools `argsJson` for a Java method from project PSI.
- `invoke_java_method` - invoke a Java method through an active DebugTools connection.

`DebugToolsHotswapToolset`:

- `list_debug_tools_run_configurations` - list IntelliJ run configurations in the current project.
- `execute_debug_tools_run_configuration` - start a run configuration with the DebugTools Hotswap executor.
- `compile_and_reload_modified_files` - trigger IDEA Java Debugger Compile and Reload Modified Files for the HotSwap changed-file/class set.

Use `debug-tools-method-invocation` for connection, attach, argument template, ClassLoader recovery, and Java method invocation tasks. Use `debug-tools-hotswap` for run configuration listing, Hotswap startup, and compile/reload tasks.

## Standard Method Invocation Flow

1. If the user asks what is already connected, or before attaching by default, call `list_debug_tools_connections`.
2. If a suitable active connection exists, reuse it.
3. If no suitable connection exists, call `list_attachable_jvms`.
4. If attachable JVMs are returned, ask only when multiple plausible JVMs match the user's target. Otherwise attach the obvious target with `attach_local_jvm`.
5. If `list_attachable_jvms` returns `count=0` or an empty `jvms` list, call `list_debug_tools_run_configurations` and pass filters such as `moduleName`, `mainClassNameContains`, or `typeDisplayName` when known. Offer only startup paths supported by actual context.
6. If only DebugTools Hotswap is known to be available, ask whether to start one with DebugTools Hotswap unless the user already authorized launch-if-needed behavior. If IDEA native Run/Debug is also known to be available from user context, tool output, or a future MCP capability, ask the user to choose between Hotswap and native Run/Debug.
7. After any Hotswap startup request, follow `execute_debug_tools_run_configuration.nextAction`. Use `LIST_DEBUG_TOOLS_CONNECTIONS` to re-check connections, or `LIST_ATTACHABLE_JVMS` to locate the started JVM and attach. Do not treat `execute_debug_tools_run_configuration.success=true` as proof that DebugTools is connected.
8. If the user chooses IDEA native Run/Debug, ask them to start the app in IDEA, then repeat connection discovery after they report startup is complete.
9. For methods with parameters, call `generate_method_args_template` before manually writing `argsJson`, unless the exact `argsJson` is already known.
10. Fill only the `content` values in the template unless the user explicitly wants to change parameter protocol types.
11. Call `invoke_java_method` with `connectionId` when there are multiple active connections.
12. If startup was authorized and manual attach is required, call `attach_local_jvm` with `waitForConnectionMillis` so the result can provide `connectionId` directly.

## Compile And Reload Modified Files

Call `compile_and_reload_modified_files` when the task needs recent Java code changes loaded into an attached Java debugger session. Do not require an explicit user request when reload is the natural next step, and do not use `git status` to decide or restrict the scope.

The "modified files" are IDEA Java Debugger HotSwap changed files/classes tracked since debugger session start or the previous reload. They are not VCS/git modified files. `success=true` means the request was submitted to IDEA; compile and HotSwap progress or failures are reported by IDEA's native UI/notifications. If the tool returns multiple `availableSessionNames`, choose the clear target or ask the user for the session name.

## Connection Selection Rules

- Prefer an existing active connection over re-attaching.
- Use `connectionId` when more than one DebugTools connection exists.
- Use `classLoaderIdentity` only when the user selected one, the current connection has a known default classloader, or the method requires a specific classloader.
- ClassLoader discovery is not an MCP tool. When needed, use direct DebugTools HTTP from connection `host` and `httpPort`.
- Treat `list_attachable_jvms` as a discovery tool only; it does not prove a DebugTools connection exists.
- Treat Hotswap startup as a recovery path for no active connection plus no attachable JVMs, not as the normal method invocation path.
- Do not always offer IDEA native Run/Debug startup. Include it only when actual user context, tool output, or a future MCP capability shows it is available.

## Parameter Rules

- Prefer `generate_method_args_template` for parameterized methods.
- Preserve method declaration order.
- Use generated parameter names such as `name` and `age`; do not invent names.
- If parameter names are unavailable, use ordered fallback keys such as `arg0` and `arg1`.
- Do not wrap `argsJson` in `targetMethodContent`.
- If user values are missing for simple scalar parameters, safe sample values are acceptable when stated before invoking. Ask for values for complex arguments or methods likely to mutate external state.

Minimal `argsJson` example:

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

## Overloads

When a method is overloaded, pass `parameterTypes` in declaration order:

```json
["java.lang.String", "java.lang.Integer"]
```

If `generate_method_args_template` reports that `parameterTypes` are required, resolve the overload before invoking.

## Standard Hotswap Flow

1. If the user gives an exact IntelliJ run configuration name, call `execute_debug_tools_run_configuration` with that `configurationName`.
2. If the name is missing, partial, or ambiguous, call `list_debug_tools_run_configurations`; use `moduleName`, `mainClassNameContains`, or `typeDisplayName` filters when available.
3. Match the target by exact `name` when possible. Use `typeName`, `typeDisplayName`, `mainClassName`, and `moduleName` only to disambiguate.
4. Ask the user to choose when multiple run configurations remain plausible.
5. Treat `execute_debug_tools_run_configuration.success=true` as "startup was requested", not as proof that the JVM is running or DebugTools is connected.
6. If `requiresManualAttach=true` or `autoAttachEnabled=false`, do not assume DebugTools will attach automatically after launch. Use `nextAction` to continue the broader invocation workflow when startup was already authorized.
7. If the user then asks to inspect connections, attach, or invoke a Java method, switch to the method invocation flow.

## Common Failures

- `No active DebugTools connection found`: call `list_debug_tools_connections`; attach if needed.
- No attachable JVMs: call `list_debug_tools_run_configurations`, offer only actually available startup paths, ask before Hotswap startup unless launch was explicitly authorized, then re-check connections before invoking.
- Multiple active connections: choose the correct `connectionId`.
- Method not found: verify `className`, `methodName`, and `parameterTypes`.
- Parameters arrive as `null`: verify `argsJson` is the top-level RunContentDTO map and is not wrapped in `targetMethodContent`.
- Wrong class version or missing bean: inspect connection `defaultClassLoader`; if needed, use `GET /allClassLoader` and `POST /classLoader/hasClass` through DebugTools HTTP, then pass the selected identity as `classLoaderIdentity`.
- Run configuration not found: call `list_debug_tools_run_configurations` or use returned `availableConfigurationNames` to ask the user for the exact name.
- Unsupported Hotswap runner: report that the run configuration does not support the DebugTools Hotswap executor instead of retrying unchanged.

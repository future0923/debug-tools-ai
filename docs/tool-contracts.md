# DebugTools MCP Tool Contracts

## Toolset

Method invocation tools are exposed under `DebugToolsMethodInvocationToolset` because they all support the Java method invocation workflow: inspect connections, discover JVMs, attach when needed, generate method argument templates, and invoke the target method.

Hotswap tools are exposed under `DebugToolsHotswapToolset` because they support the separate workflow of listing IntelliJ run configurations and starting one with the DebugTools Hotswap executor.

## `list_debug_tools_connections`

No required input.

Returns current IDE-side DebugTools connections with fields such as:

- `connectionId`
- `applicationName`
- `pid`
- `source`
- `host`
- `port`
- `httpPort`
- `remark`
- `state`
- `active`
- `defaultClassLoader`
- `headers`
- `printSqlType`

Use this before attaching when the user may already have a connection.

`host` and `httpPort` can be used for direct DebugTools agent HTTP when advanced ClassLoader selection is needed. These endpoints are not MCP tools:

```http
GET http://<host>:<httpPort>/allClassLoader
```

```http
POST http://<host>:<httpPort>/classLoader/hasClass
Content-Type: application/json

{
  "className": "com.example.UserController",
  "classLoaderIdentity": "abc123"
}
```

`classLoaderIdentity` may be omitted or blank; the server then checks its default ClassLoader. Use the selected `identity` as `invoke_java_method.classLoaderIdentity`.

## `list_attachable_jvms`

No required input.

Returns local JVM processes that can be attached. Use this only when no suitable DebugTools connection already exists or the user asks what can be attached.

## `attach_local_jvm`

Required:

- `pid`

Optional:

- `attachName`

Use the PID returned by `list_attachable_jvms`.

## `generate_method_args_template`

Required:

- `className`
- `methodName`

Optional:

- `parameterTypes`
- `genParamType` (`SIMPLE`, `CURRENT`, `ALL`)

Returns `argsJson`, `parameterNames`, `parameterTypes`, and `genParamType`.

## `invoke_java_method`

Required:

- `className`
- `methodName`

Common optional fields:

- `connectionId`
- `parameterTypes`
- `argsJson`
- `classLoaderIdentity`
- `headers`
- `xxlJobParam`
- `traceMethodDTO`
- `methodAroundContent`
- `timeoutMillis`

When parameter names, default values, or RunContentDTO types are unclear, call `generate_method_args_template` first and use its `argsJson` result.

Returns `result` as the ToString view plus `offsetPath` for object result re-rendering. JSON and Debug result views are not MCP fields; when the user asks for them, use direct DebugTools HTTP `POST /result/type` with `printResultType=Json` or `Debug`, using connection `host`/`httpPort` and the returned `offsetPath`.

## `list_debug_tools_run_configurations`

No required input.

Returns IntelliJ run configurations in the current project:

- `count`
- `configurations`
- `configurations[].name`
- `configurations[].typeName`
- `configurations[].typeDisplayName`
- `configurations[].mainClassName`
- `configurations[].moduleName`

Use this before `execute_debug_tools_run_configuration` when the target run configuration name is missing, partial, or ambiguous. The list is not filtered by DebugTools Hotswap support.
Optional filters are `moduleName`, `mainClassNameContains`, and `typeDisplayName`.

## `execute_debug_tools_run_configuration`

Required:

- `configurationName`

Starts the named run configuration with the DebugTools Hotswap executor. The name must match an IntelliJ run configuration name exactly.

Returns:

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

`success=true` means the startup request was submitted to IntelliJ. It does not prove that the target JVM has started or that DebugTools is connected. Follow `nextAction`: `LIST_DEBUG_TOOLS_CONNECTIONS` means re-check existing connections, and `LIST_ATTACHABLE_JVMS` means locate and attach the started JVM. If `requiresManualAttach=true` or `autoAttachEnabled=false`, do not assume DebugTools will attach automatically after launch.

## `compile_and_reload_modified_files`

No required input.

Optional:

- `projectPath`
- `sessionName`
- `compileBeforeReload`

Triggers IDEA Java Debugger Compile and Reload Modified Files for an attached Java debugger session. Call it whenever the task needs recent Java code changes loaded into the debugged JVM; an explicit user request is not required when reload is the natural next step.

The "modified files" are IDEA Java Debugger HotSwap changed files/classes tracked since debugger session start or the previous reload. They are not VCS/git modified files, and clients should not use `git status` to decide whether this tool is safe to call.

Returns:

- `success`
- `sessionName`
- `compileBeforeReload`
- `message`
- `availableSessionNames`

`success=true` means the compile/reload request was submitted to IDEA. Compile and HotSwap progress or failures are reported by IDEA's native UI/notifications. If multiple sessions are available, the tool returns `availableSessionNames`; choose the clear target or ask for `sessionName`.

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

`host` and `httpPort` can be used for documented direct DebugTools agent HTTP companion endpoints. These endpoints are not MCP tools.

ClassLoader endpoints:

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

Spring config endpoint:

```http
POST http://<host>:<httpPort>/spring/config
Content-Type: application/json

["server.port", "spring.profiles.active"]
```

The body is a JSON string array of Spring config keys. The response is a JSON object keyed by the requested keys. Values are resolved from Spring runtime Environment; a `null` value means the key was not resolved.

Spring readiness endpoint:

```http
GET http://<host>:<httpPort>/spring/ready
```

Use this companion HTTP endpoint before invoking Spring-like methods after fresh attach or DebugTools Hotswap startup. Use only `host` and `httpPort` from the selected MCP connection. Do not guess `127.0.0.1:22222`, scan ports, or use process inspection as a replacement for MCP connection selection.

Ready response:

```json
{"ready":true,"state":"UP","retryable":false}
```

HTTP `200` or `ready=true` means the agent can continue to `invoke_java_method`.

Starting response:

```json
{"ready":false,"state":"STARTING","retryable":true}
```

The agent should poll again until the workflow timeout.

No Spring context response:

```json
{"ready":false,"state":"NO_SPRING_CONTEXT","retryable":false}
```

The agent should stop polling and report that Spring is unavailable or the target is not a Spring application.

Check error response:

```json
{"ready":false,"state":"CHECK_ERROR","retryable":false}
```

The agent should stop polling and report that readiness checking is unavailable. It should continue only if the user explicitly asks to force invocation.

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
- `methodAroundName` - exact name of a saved Method Around script, without the `.java` suffix. Discover names with `list_method_around_scripts`; when both name and content are sent, explicit content wins for backward compatibility.
- `timeoutMillis`

When parameter names, default values, or RunContentDTO types are unclear, call `generate_method_args_template` first and use its `argsJson` result.

Optional:

- `resultView`: `TO_STRING` (default), `JSON`, `DEBUG`, or `NONE`.

Returns `result` as the ToString view plus `offsetPath` for object result re-rendering. When `resultView=JSON`, the response may include `resultJson`; when `resultView=DEBUG`, it may include the Debug result structure. `resultFetchStatus` reports `SUCCESS`, `FAILED`, or `NOT_REQUESTED`, and `resultFetchError` describes a fetch failure. A failed result fetch does not imply that method invocation failed. Older plugins can still use the direct `/result/type` and `/result/detail` HTTP fallback documented in the workflow.

## Saved Method Around scripts

`list_method_around_scripts` lists Java scripts saved by the IDEA Method Around editor under `.idea/DebugTools/MethodAround/`. It returns bounded metadata (`name`, `sizeBytes`, and `modifiedAt`) and never exposes file paths.

`get_method_around_script` accepts the exact saved `name` without `.java` and returns the source, content `identity`, size, and modification time. Names are single file names; path separators, `.`/`..`, and an extra `.java` suffix are rejected. Pass the returned name as `invoke_java_method.methodAroundName` or `run_and_invoke.methodAroundName`.

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
- `waitMillis` (bounded wait, maximum 120 seconds)
- `operationId` (query an existing operation)

Triggers IDEA Java Debugger Compile and Reload Modified Files for an attached Java debugger session. Call it whenever the task needs recent Java code changes loaded into the debugged JVM; an explicit user request is not required when reload is the natural next step.

The "modified files" are IDEA Java Debugger HotSwap changed files/classes tracked since debugger session start or the previous reload. They are not VCS/git modified files, and clients should not use `git status` to decide whether this tool is safe to call.

Returns:

- `success`
- `sessionName`
- `compileBeforeReload`
- `message`
- `availableSessionNames`
- `operationId`
- `status`: `REQUESTED`, `COMPILING`, `RELOADING`, `SUCCESS`, `PARTIAL_SUCCESS`, `FAILED`, `TIMEOUT`, or `UNSUPPORTED`
- `changedFiles`
- `compiledClasses`
- `reloadedClasses`
- `skippedClasses`
- `classResults[]`: `{className, status, message}`
- `error`
- `errorCode`

`success=true` means the compile/reload request was submitted to IDEA. Compile and HotSwap progress or failures are reported by IDEA's native UI/notifications. If multiple sessions are available, the tool returns `availableSessionNames`; choose the clear target or ask for `sessionName`. When the request times out, retain `operationId` and call `get_hotswap_operation`.

## `get_hotswap_operation`

Required:

- `operationId`

Returns the latest status for a compile/reload request. The operation may still be `REQUESTED`, `COMPILING`, or `RELOADING`; clients must not infer final success from the initial request alone. If the IDEA version does not expose per-class progress, `classResults` can remain empty or contain an `UNKNOWN` status.

## `get_debug_tools_status`

Optional:

- `projectPath`

Returns a diagnostic snapshot containing `project`, `connections`, `attachableJvms`, `debuggerSessions`, and `nextAction`. `nextAction` is one of `INVOKE`, `SELECT_CONNECTION`, `ATTACH_JVM`, `START_RUN_CONFIGURATION`, `SELECT_DEBUGGER_SESSION`, `WAIT_FOR_SPRING`, `RECONNECT`, or `NONE`. Connection headers are omitted from this snapshot.

## `search_http_url`

Optional:

- `path` (substring match)
- `method`
- `moduleName`
- `limit` (default 50, capped at 200)
- `projectPath`

Returns `{count, items, indexState}`. Each item contains stable metadata such as `method`, `path`, `moduleName`, `className`, `methodName`, `targetMethodIdentity`, and `comment`; it does not return PSI or Swing navigation objects.

## `read_target_application_logs`

Optional:

- `connectionId`
- `limit`
- `since`
- `level`
- `keyword`

Reads bounded recent target logs. Records can contain `timestamp`, `level`, `logger`, `thread`, `message`, `throwable`, and `source`. Treat `LOGS_UNAVAILABLE` as a capability error rather than an empty result.

## `get_last_sql_statements`

Optional:

- `connectionId`
- `limit`
- `since`
- `keyword`
- `projectPath`

Reads recent SQL from the target JVM ring buffer. IDEA `~/.debugTools/sql` history remains available through the SQL History UI. Records contain `timestamp`, `sql`, `consumeTimeMillis`, `dbType`, and `applicationName`. Treat `SQL_HISTORY_UNAVAILABLE` as an unavailable source.

## `run_and_invoke`

Required:

- `className`
- `methodName`

Optional fields include `connectionId`, `sessionName`, `compileBeforeReload`, `waitMillis`, `parameterTypes`, `argsJson`, `methodAroundName`, `methodAroundContent`, `resultView`, `verifyLogs`, and `verifySql`. Startup and attach are opt-in: `allowStart=true` requires an exact `runConfigurationName`; `allowAttach=true` requires an explicit `pid`. The result contains `success`, `steps`, `invokeResult`, `hotswap`, `logs`, `sql`, and `error`.

The tool is intended for the closed loop: inspect status, select a target, optionally start/attach, reload, invoke, and inspect logs or SQL. It never guesses a run configuration or JVM from a fuzzy name.

## Structured errors

New and enhanced tools may return `{success:false, error:{code, message, hint, availableOptions, retryable, nextAction, details}, requestId, timestamp}`. Use `availableOptions` objects (`id`, `name`, `type`, `state`, `hint`) for target selection. Common codes include `NO_PROJECT`, `INVALID_ARGUMENT`, `CONNECTION_NOT_FOUND`, `CONNECTION_INACTIVE`, `CONNECTION_AMBIGUOUS`, `NO_CONNECTION`, `NO_DEBUGGER_SESSION`, `SESSION_NOT_FOUND`, `SESSION_AMBIGUOUS`, `SPRING_NOT_READY`, `HTTP_UNAVAILABLE`, `HOTSWAP_UNSUPPORTED`, `HOTSWAP_COMPILE_FAILED`, `HOTSWAP_CLASS_STRUCTURE_CHANGED`, `HOTSWAP_FAILED`, `INVOCATION_FAILED`, `RESULT_FETCH_FAILED`, `LOGS_UNAVAILABLE`, `SQL_HISTORY_UNAVAILABLE`, `TIMEOUT`, and `INTERNAL_ERROR`.

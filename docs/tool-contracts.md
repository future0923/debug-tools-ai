# DebugTools MCP Tool Contracts

The machine-readable input snapshot is [mcp-input-contracts.json](mcp-input-contracts.json).
It is generated from the IDEA plugin's registered schema objects, not hand-edited.
After changing tools, run `McpContractExportTest` in the IDEA repository, copy
`build/generated/debug-tools-mcp-contracts.json` to this snapshot, and run:

```bash
python3 scripts/check-tool-contracts.py --plugin-export ../debug-tools-idea/build/generated/debug-tools-mcp-contracts.json
```

This checks exact input-contract drift. It does not validate output schemas or
prove runtime availability; the current MCP catalog remains authoritative.

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

HTTP `2xx` together with `ready=true` and `state=UP` means the agent can continue to `invoke_java_method`.

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

## Optional runtime and recovery tools

Use the runtime MCP catalog as the authority. These extensions return
`{success:true,data,requestId,timestamp}` or the structured error envelope above.
All accept `projectPath` and optional `connectionId`; an ambiguous target requires
an explicit choice. They may be absent from older installed plugins or agents.

| Tool | Inputs beyond target selection | Data and interpretation |
|---|---|---|
| `get_agent_capabilities` | None | agentVersion, protocolVersion, agentInstanceId, capabilities, limits, logSources; support is not runtime readiness |
| `manage_business_log_capture` | action STATUS/START/STOP; START/STOP require framework LOGBACK/LOG4J2 and classLoaderIdentity | root-appender capture state, startedAt, captured count, errors and scope limitations; records are read separately |
| `get_spring_config` | Required keys array, 1–100 keys | connectionId, source=SPRING_ENVIRONMENT, values; null means unresolved |
| `wait_for_application_ready` | waitMillis 0–120000, default 30000 | ready, state, retryable, message; successful query envelope alone does not mean ready |
| `find_class_loaders` | className, offset, limit 1–200 | items with identity/name/canLoadClass, total, nextOffset; read all pages before deciding uniqueness |
| `get_method_trace` | Required traceOffsetPath; maxDepth, maxNodes, minDurationMillis, topN | nodes with parentId, hotspots, truncation; durations are inclusive |
| `inspect_run_result` | Required offsetPath; view, offset, limit 1–200, maxDepth 1–20, maxNodes 1–2000 | inspection with bounded value/items; RESULT_EXPIRED differs from null |
| `get_invocation_result` | Required invocationId; waitMillis 0–30000 | COMPLETED result, UNKNOWN_OR_PENDING, or an available stream snapshot; no re-execution |
| `read_invocation_stream` | Required invocationId; afterCursor, limit 1–256 | events, state, nextCursor, gap, droppedEvents; not a durable replay log |
| `cancel_invocation_stream` | Required invocationId | cancelRequested and snapshot; verify terminal event separately |
| `get_jvm_snapshot` | None | uptime, heap/nonHeap, GC counters, threads, class counts, load; -1 means unsupported |
| `get_thread_snapshot` | offset, limit 1–256, maxDepth 0–128 | live paged stacks, locks, deadlock IDs and detection scope |
| `inspect_runtime_class` | Exact className or nameContains length ≥3; optional classLoaderIdentity, offset, limit 1–100, methodLimit 0–200 | already-loaded class metadata, methods, source jar; no class initialization |

Corresponding agent additions are `POST /result/inspect`, `POST /capabilities`,
`POST /runtime/jvm`, `POST /runtime/threads`, `POST /runtime/classes`, and `POST /logs/capture`.
The other queries reuse existing documented HTTP or socket protocols. A missing
new endpoint returns CAPABILITY_UNAVAILABLE; do not interpret it as empty data.
Stream handles are project-local, retain 256 events and request cancellation after
five minutes. Invocation handles expire after 30 minutes.

## Completion contract

For reload-dependent invocation, wait for `status=SUCCESS` from the same project and `operationId`. `REQUESTED`, `COMPILING`, `RELOADING`, and `TIMEOUT` do not permit invocation. Use `get_hotswap_operation` to continue observing; do not submit a duplicate reload. An older plugin exposing only request submission cannot prove completion. Empty per-class details mean unavailable detail, not that zero classes changed. `run_and_invoke` keeps one target connection and requires a successful reload before invoking. Log/SQL evidence failures are distinct from invocation failure.

## Complete extension catalog and machine contracts

The generated [MCP contract snapshot](mcp-input-contracts.json) contains all registered
input schemas and output envelopes. Compare it with the IDEA test export using
`scripts/check-tool-contracts.py --plugin-export <path>`. Validate a captured JSON
response using `--tool execute_http_request --response <path>`. The validator fails
on unsupported schema vocabulary rather than silently skipping checks. Legacy
outputs retain tool-specific shapes and error text; their schema is deliberately
weaker. Selected modern tools additionally constrain essential payload fields.
This is a wire-shape check, not proof of semantic success or endpoint availability.

See [extended workflows](../skills/debug-tools/references/extended-workflows.md)
for all execution/diagnostic boundaries and [extension inventory](extension-inventory.md)
for the complete registered tool list. All modern tools use a success/data or
error envelope. Inspect inner operation state; success=true is not a deployment,
readiness, cancellation, or business-success guarantee.

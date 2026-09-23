# DebugTools AI Workflow

This document is the shared workflow source for AI agents using DebugTools through IntelliJ MCP tools.

## Supported MCP Tools

`DebugToolsMethodInvocationToolset`:

- `list_debug_tools_connections` - list current DebugTools connections already known to the IDE.
- `list_attachable_jvms` - list local JVM processes that can be attached.
- `attach_local_jvm` - attach the DebugTools agent to a local JVM process.
- `generate_method_args_template` - generate DebugTools `argsJson` for a Java method from project PSI.
- `invoke_java_method` - invoke a Java method through an active DebugTools connection.
- `get_debug_tools_status` - aggregate project, connection, attachable JVM, debugger session, and capability status.
- `read_target_application_logs` - read recent logs from the selected target JVM ring buffer.
- `get_last_sql_statements` - read recent SQL from the target JVM or the IDEA SQL history fallback.
- `search_http_url` - query indexed HTTP endpoints as stable JSON metadata.

`DebugToolsHotswapToolset`:

- `list_debug_tools_run_configurations` - list IntelliJ run configurations in the current project.
- `execute_debug_tools_run_configuration` - start a run configuration with the DebugTools Hotswap executor.
- `compile_and_reload_modified_files` - trigger IDEA Java Debugger Compile and Reload Modified Files for the HotSwap changed-file/class set.
- `get_hotswap_operation` - query a HotSwap operation after the initial request timed out or returned an operation id.
- `run_and_invoke` - orchestrate status, optional explicit start/attach, reload, invocation, and optional logs/SQL verification.

Use `debug-tools-method-invocation` for connection, attach, argument template, ClassLoader recovery, and Java method invocation tasks. Use `debug-tools-hotswap` for run configuration listing, Hotswap startup, and compile/reload tasks. Use `debug-tools-spring-config` when the user asks to read Spring runtime Environment configuration keys from an attached application.

## Standard Method Invocation Flow

1. Prefer `get_debug_tools_status` when the user asks for a complete diagnostic snapshot or when the target is not yet known. It exposes `nextAction` and candidate options without exposing connection headers.
2. If the user asks what is already connected, or before attaching by default, call `list_debug_tools_connections`.
3. If a suitable active connection exists, reuse it. When exactly one active connection exists it may be selected automatically; when several exist, pass an explicit `connectionId` or ask the user to choose.
4. If no suitable connection exists, call `list_attachable_jvms`.
5. If attachable JVMs are returned, ask only when multiple plausible JVMs match the user's target. Otherwise attach the obvious target with `attach_local_jvm`.
6. If `list_attachable_jvms` returns `count=0` or an empty `jvms` list, call `list_debug_tools_run_configurations` and pass filters such as `moduleName`, `mainClassNameContains`, or `typeDisplayName` when known. Offer only startup paths supported by actual context.
7. If only DebugTools Hotswap is known to be available, ask whether to start one with DebugTools Hotswap unless the user already authorized launch-if-needed behavior. If IDEA native Run/Debug is also known to be available from user context, tool output, or a future MCP capability, ask the user to choose between Hotswap and native Run/Debug.
8. After any Hotswap startup request, follow `execute_debug_tools_run_configuration.nextAction`. Use `LIST_DEBUG_TOOLS_CONNECTIONS` to re-check connections, or `LIST_ATTACHABLE_JVMS` to locate the started JVM and attach. Do not treat `execute_debug_tools_run_configuration.success=true` as proof that DebugTools is connected.
9. If the user chooses IDEA native Run/Debug, ask them to start the app in IDEA, then repeat connection discovery after they report startup is complete.
10. For methods with parameters, call `generate_method_args_template` before manually writing `argsJson`, unless the exact `argsJson` is already known.
11. Fill only the `content` values in the template unless the user explicitly wants to change parameter protocol types.
12. After a fresh attach or Hotswap startup, run the Spring readiness gate before invoking Spring-like `Controller`, `Service`, repository, component, or bean methods.
13. Call `invoke_java_method` with `connectionId` when there are multiple active connections.
14. If startup was authorized and manual attach is required, call `attach_local_jvm` with `waitForConnectionMillis` so the result can provide `connectionId` directly.

## Spring Readiness Gate

For method invocation, attach success only proves the DebugTools agent is present. It does not prove Spring has finished starting. When the selected target looks like a Spring method and the current turn just attached or just recovered from Hotswap startup, call:

```http
GET http://<host>:<httpPort>/spring/ready
```

Use only `host` and `httpPort` from the selected MCP connection. Do not guess localhost/default ports, scan ports, use `/spring/config`, or use Java method calls as readiness probes.

Polling rules:

- Fresh attach timeout: `30s`.
- Hotswap startup timeout: `60s`.
- Interval: `1s`.
- `ready=true` or HTTP `200`: proceed to `invoke_java_method`.
- `state=STARTING` and `retryable=true`: keep polling until ready or timeout.
- `retryable=false`: stop polling, report the state, and continue only if the user explicitly asks to force invocation.

Do not force this gate for obvious non-Spring static utility methods.

## Result View Rules

- `invoke_java_method.result` is the ToString view.
- `resultView` is optional and defaults to `TO_STRING`. Pass `JSON`, `DEBUG`, or `NONE` when the MCP result mode is requested explicitly.
- `JSON` and `DEBUG` are fetched by the plugin from the selected connection's existing result endpoints. The response includes `resultJson`, `resultFetchStatus`, and `resultFetchError` when applicable.
- If result fetching fails, keep the method invocation outcome separate: the invocation can succeed while `resultFetchStatus=FAILED`. Report the fetch error and retry only when useful.
- Direct `POST /result/type` and `POST /result/detail` remain a compatibility fallback when an older plugin does not expose `resultView`, or when bounded Debug child expansion is needed. Use `host`, `httpPort`, and `offsetPath` from MCP output.

## Spring Config Rules

- If the user asks to read Spring configuration, use `debug-tools-spring-config`.
- Spring configuration reads are key-based direct DebugTools HTTP: `POST /spring/config` with a JSON string array of requested keys, using `host` and `httpPort` from `list_debug_tools_connections`.
- If the user does not provide keys, ask which Spring config keys to read. Do not try to dump all Spring configuration.
- Report values as Spring runtime Environment resolved values, not as direct `application.yml` or `application.properties` reads.
- If `httpPort` is missing, report that Spring config HTTP is unavailable.

## Compile And Reload Modified Files

Call `compile_and_reload_modified_files` when the task needs recent Java code changes loaded into an attached Java debugger session. Do not require an explicit user request when reload is the natural next step, and do not use `git status` to decide or restrict the scope. Pass `waitMillis` when bounded feedback is needed and retain the returned `operationId` if the request times out.

The "modified files" are IDEA Java Debugger HotSwap changed files/classes tracked since debugger session start or the previous reload. They are not VCS/git modified files. `success=true` means the request was submitted to IDEA; compile and HotSwap progress or failures are reported by IDEA's native UI/notifications. If the tool returns multiple `availableSessionNames`, choose the clear target or ask the user for the session name. Use `get_hotswap_operation` with `operationId` to query a pending request.

## Closed-Loop Tools

- Use `read_target_application_logs` after an invocation when the user asks what the target logged. Pass `connectionId` when needed and use `limit`, `since`, `level`, and `keyword` to keep the response bounded. `LOGS_UNAVAILABLE` means the target could not provide log capability; it does not mean the log stream is empty.
- Use `get_last_sql_statements` to inspect recent SQL from the target JVM ring buffer. The IDEA SQL history file remains available in the SQL History UI; the MCP tool reports `SQL_HISTORY_UNAVAILABLE` when the target endpoint cannot provide data.
- Use `search_http_url` for path-to-controller discovery. It returns stable JSON and supports method, module, and limit filters; do not expect PSI or Swing navigation objects.
- Use `run_and_invoke` when the user requests the full status → reload → invoke → logs/SQL loop. It may start or attach only when `allowStart=true` with an exact `runConfigurationName`, or `allowAttach=true` with an explicit `pid`. Never guess a run configuration or JVM from a fuzzy name.

## Structured Errors

New and enhanced tools use an error object with `code`, `message`, `hint`, `availableOptions`, `retryable`, `nextAction`, and `details`. Common codes include `NO_PROJECT`, `CONNECTION_NOT_FOUND`, `CONNECTION_AMBIGUOUS`, `NO_CONNECTION`, `SESSION_AMBIGUOUS`, `SPRING_NOT_READY`, `HOTSWAP_FAILED`, `RESULT_FETCH_FAILED`, `LOGS_UNAVAILABLE`, `SQL_HISTORY_UNAVAILABLE`, and `TIMEOUT`. Use `availableOptions` as the source for the next selection instead of parsing prose.

## Connection Selection Rules

- Prefer an existing active connection over re-attaching.
- Use `connectionId` when more than one DebugTools connection exists.
- Use `classLoaderIdentity` only when the user selected one, the current connection has a known default classloader, or the method requires a specific classloader.
- ClassLoader discovery, Spring config reads, and Spring readiness checks are not MCP tools. When needed, use direct DebugTools HTTP from connection `host` and `httpPort`.
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
- Spring method fails immediately after attach or Hotswap startup: check `GET /spring/ready` first. If it returns `STARTING` with `retryable=true`, wait instead of switching ClassLoaders or retrying unchanged.
- Spring config key returns `null`: report that Spring runtime Environment did not resolve that key instead of treating the HTTP call as failed.
- Run configuration not found: call `list_debug_tools_run_configurations` or use returned `availableConfigurationNames` to ask the user for the exact name.
- Unsupported Hotswap runner: report that the run configuration does not support the DebugTools Hotswap executor instead of retrying unchanged.

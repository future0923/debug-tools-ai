---
name: debug-tools-method-invocation
description: Use when operating DebugTools IntelliJ MCP tools for status discovery, Java method invocation, JVM attachment, connection selection, argsJson template generation, result views, logs, SQL, classloader selection, overloaded methods, or failures involving get_debug_tools_status, list_debug_tools_connections, list_attachable_jvms, attach_local_jvm, generate_method_args_template, invoke_java_method, read_target_application_logs, get_last_sql_statements, run_and_invoke, no attachable JVMs, or Hotswap startup fallback.
---

# DebugTools Method Invocation

Use DebugTools as a live Java method invocation bridge. The workflow is MCP-first: choose the IntelliJ project, inspect status, find or attach a DebugTools connection, prepare arguments, invoke, and optionally inspect logs or SQL. Use local process commands only when the user explicitly asks for diagnostics.

## Toolset

Method invocation tools:

- `list_debug_tools_connections`
- `list_attachable_jvms`
- `attach_local_jvm`
- `generate_method_args_template`
- `invoke_java_method`
- `list_method_around_scripts`
- `get_method_around_script`
- `get_debug_tools_status`
- `read_target_application_logs`
- `get_last_sql_statements`
- `search_http_url`

Startup recovery tools, used only when no active connection and no attachable JVMs are available:

- `list_debug_tools_run_configurations`
- `execute_debug_tools_run_configuration`

## Hard Boundaries

- If the DebugTools MCP tools are not exposed in the current Codex tool context, stop and report a configuration error. Do not fall back to shell process inspection, local startup, direct HTTP probing, reflection runners, or Java/Maven commands for discovery or invocation.
- Direct DebugTools HTTP is allowed only after MCP has returned a selected connection with `host` and `httpPort`, and only for documented companion endpoints such as Spring readiness, ClassLoader checks, and compatibility result views. Prefer MCP `resultView` when it is available.
- `GET /spring/ready` is a DebugTools companion HTTP endpoint, not an MCP tool. Use only the selected MCP connection `host` and `httpPort`; do not guess `127.0.0.1:22222`, scan ports, or use `ps`/`jps` as a substitute for MCP connection selection.
- Do not invent MCP tools or parameters. The supported result mode is `resultView=TO_STRING|JSON|DEBUG|NONE`; do not send obsolete names such as `resultFormats` or `debugDepth`.

## Invocation Flow

1. Infer `projectPath` from the target source path or workspace when possible. If MCP reports ambiguous open projects, retry the same MCP call with the inferred project.
2. Prefer `get_debug_tools_status` for a complete snapshot and follow its `nextAction`. Call `list_debug_tools_connections` when you only need connection details or before attaching unless the user gave a fresh PID.
3. Reuse a matching active connection. Exactly one active connection may be selected automatically; if multiple connections are plausible, pass `connectionId` or use the structured `availableOptions` to ask the user.
4. If no suitable connection exists, call `list_attachable_jvms`, select a PID, then `attach_local_jvm`. Use bounded `waitForConnectionMillis` when attach is part of an authorized invocation workflow.
5. If no JVMs are attachable, read `references/workflow.md` for Hotswap startup recovery. Starting a run configuration requires explicit user authorization or `run_and_invoke.allowStart=true` with an exact name.
6. Prepare parameters: omit `argsJson` for no-arg methods, build simple known values directly, and use `generate_method_args_template` for complex args, uncertain names, generated defaults, or overloads.
7. Before invoking a Spring-like target after a fresh `attach_local_jvm` or Hotswap startup recovery, run the Readiness Gate below.
8. Call `invoke_java_method` with `className`, `methodName`, plus `projectPath`, `connectionId`, `parameterTypes`, `argsJson`, `classLoaderIdentity`, and `resultView` only when needed. When a saved Method Around script should run, list scripts first, choose an exact returned name, and pass it as `methodAroundName`. Use `get_method_around_script` when you need to inspect the source; do not construct a script path or guess a filename.
9. If invocation fails, recover from the specific structured error instead of retrying unchanged; see `references/troubleshooting.md`.
10. When the user requests the complete loop, prefer `run_and_invoke`; request logs or SQL with `verifyLogs` and `verifySql`, or use `read_target_application_logs` and `get_last_sql_statements` separately.

## Readiness Gate

Use this gate only when the selected method appears to depend on Spring runtime state, such as a `Controller`, `Service`, repository, component, or bean method. Do not force it for obvious non-Spring static utility methods.

Run the gate when either condition is true:

- This turn just attached with `attach_local_jvm` and MCP returned a connection with `host` and `httpPort`.
- This turn just started through DebugTools Hotswap, then rediscovered or attached a connection before invocation.

Call:

```http
GET http://<host>:<httpPort>/spring/ready
```

Polling rules:

- Use the selected MCP connection `host` and `httpPort` only.
- Poll every `1s`.
- Use timeout `30s` after fresh attach.
- Use timeout `60s` after Hotswap startup.
- Continue to `invoke_java_method` when `ready=true` or HTTP status is `200`.
- If `state=STARTING` and `retryable=true`, keep polling until ready or timeout.
- If `retryable=false`, stop polling and report the `state` and reason. Continue only if the user explicitly asks to force invocation.

## ClassLoader Selection

Usually omit `classLoaderIdentity`. Use it only when the user selected a loader, the connection reports a suitable default loader, or errors indicate class-not-found, bean resolution, framework-context, or wrong-class-version problems.

ClassLoader discovery is direct DebugTools HTTP after MCP connection discovery, not an MCP tool. Use `GET /allClassLoader` and `POST /classLoader/hasClass`; if multiple loaders match, ask the user to choose. See `references/http-classloader.md`.

## Result Views

- `invoke_java_method.result` is the ToString view.
- Pass `resultView=JSON` or `resultView=DEBUG` to let the plugin fetch the existing result representation; use `NONE` when only invocation metadata is needed.
- Read `resultJson`, `resultFetchStatus`, and `resultFetchError` from the response. A method can succeed while result fetching fails.
- For older plugins, use direct `POST /result/type` and bounded `POST /result/detail` with the selected connection metadata and `offsetPath` as described in `references/http-result-view.md`.

## Observability And Errors

- `read_target_application_logs` returns bounded target JVM log records. Use `limit`, `since`, `level`, and `keyword`; `LOGS_UNAVAILABLE` is a capability error.
- `get_last_sql_statements` returns target SQL ring-buffer records. IDEA SQL history remains available in its UI; `SQL_HISTORY_UNAVAILABLE` means the target endpoint is unavailable.
- New tools expose structured error objects. Prefer `error.code`, `error.retryable`, `error.nextAction`, and `error.availableOptions` over matching error prose.
- Saved Method Around scripts are project-local files. `list_method_around_scripts` returns names and metadata, while `get_method_around_script` returns source and identity. A missing or unsafe name is an explicit script error; do not retry with a path variant.
- See `references/http-result-view.md` for request shapes and expansion limits.

## argsJson Contract

`argsJson` is a JSON object whose values are RunContentDTO objects, not a wrapper around `targetMethodContent`.

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

Preserve generated parameter keys and declaration order. Use `arg0`, `arg1`, `arg2` only when reliable names are unavailable. For complex values or type choices, read `references/args-json.md`.

## References

- `references/workflow.md` - connection selection, startup recovery, parameters, ClassLoader flow.
- `references/args-json.md` - RunContentDTO shapes and template editing.
- `references/http-classloader.md` - direct HTTP ClassLoader checks.
- `references/http-result-view.md` - direct HTTP JSON and Debug result views.
- `references/troubleshooting.md` - recovery by failure symptom.

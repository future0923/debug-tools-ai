---
name: debug-tools
description: "Operate DebugTools IntelliJ MCP across one Java debugging workflow: select or attach a JVM, start or reload an application when authorized, prepare and invoke methods, recover existing results and streams, inspect Spring, HTTP, logs, SQL and runtime evidence, or deploy selected code/resources and connect Kubernetes targets. Also use for code/route search and read-only data checks through available companion IDE tools. Use for DebugTools tasks and their failures; keep target identity, authorization and cleanup consistent across steps."
---

# DebugTools Workflows

Follow the user's requested outcome across tools. MCP categories organize operations;
they are not separate skills or mandatory stages. Load only references needed for the
current request, and stop when that outcome is achieved.

## Shared workflow

1. **Discover capability and target.** Use the current MCP catalog, then
   `get_debug_tools_status` or `list_debug_tools_connections`. Infer `projectPath`
   from the application workspace. Reuse a unique matching active connection; ask
   when several targets remain plausible. Query `get_agent_capabilities` when exposed.
   Version numbers and a successful tunnel/start request do not prove readiness or support.
2. **Obtain a connection only if needed.** With no suitable connection, use
   `list_attachable_jvms`, then `attach_local_jvm` with the selected PID. Empty JVM
   results lead to `list_debug_tools_run_configurations` and only startup paths
   actually available. Use `execute_debug_tools_run_configuration` for supported Hotswap startup,
   or exposed `manage_run_instance` for a selected native run instance. Launch only when requested/previously authorized; an authorized
   “start if needed” workflow may continue without asking again. Rediscover the
   connection after startup. Do not use shell processes or port scans to replace MCP.
3. **Wait or reload only when relevant.** For a Spring-dependent call after fresh
   attach/start, use `wait_for_application_ready`; require ready=true/state=UP. Poll
   STARTING only while retryable=true. If recent code must take effect, request
   `compile_and_reload_modified_files` on the selected debugger session and confirm
   success before invoking. Keep operationId and query `get_hotswap_operation` after
   a timeout. Starting, connecting and reloading are distinct states.
4. **Perform the requested operation.** For invocation, use
   `generate_method_args_template` for overloads, complex types or uncertain names;
   preserve generated RunContentDTO keys/order and edit content values. Then
   `invoke_java_method` once. For no-arg methods omit argsJson or use `{}`. Select a
   loader only when needed or required; read all matching-loader pages and ask on
   ambiguity. Select the exact runtime signature for watches/deployment.
5. **Recover and inspect the same execution.** Keep invocationId, operationId,
   offsetPath and traceOffsetPath. A timeout ends the wait, not the business action.
   Recover via `get_invocation_result` or `get_agent_operation`; never repeat a
   write/job merely to obtain output. UNKNOWN_OR_PENDING/UNKNOWN_OR_EXPIRED remain
   unknown. Keep project, connection and agentInstanceId fixed; stop old-handle
   recovery on TARGET_CHANGED/TARGET_INSTANCE_CHANGED/TARGET_MISMATCH.
6. **Gather requested evidence and finish.** Read existing results, traces, streams,
   logs or SQL without reinvocation. Preserve truncation, gaps and unsupported values.
   InvocationId gives exact correlation; time overlap alone gives window evidence.
   Clean up sessions created for this request, leave pre-existing sessions untouched,
   and report cleanup as unconfirmed when no returned state proves it completed.

For a combined reload → invoke → evidence request, prefer exposed `run_and_invoke`.
`allowStart=true` needs an exact runConfigurationName; `allowAttach=true` needs an
explicit PID. Do not expand a standalone config-read/diagnosis request into startup,
deployment, execution, or connection-default changes.

## Choose the relevant part of the workflow

| User outcome | Read when needed |
| --- | --- |
| Attach, prepare args, invoke, inspect existing results | [Invocation](references/invocation.md), [argument shapes](references/args-json.md) |
| Start/restart, debugger reload or reload → invoke | [Run and HotSwap](references/run-and-hotswap.md) |
| Timeout, object/stream result, snapshot or slow-call investigation | [Results and evidence](references/results-and-evidence.md), [extended workflows](references/extended-workflows.md) |
| HTTP request, Groovy, compilation, resource deployment, saved inputs or Kubernetes | [Extended workflows](references/extended-workflows.md) |
| Spring keys, readiness, beans or property-source explanation | [Spring](references/spring.md), [extended workflows](references/extended-workflows.md) |
| Independent JVM/thread/class inspection | [Runtime diagnosis](references/runtime-diagnostics.md) |
| Observe incoming calls or selected-executor async propagation | [Live observation](references/live-observation.md) |
| Older plugins need supported HTTP companions | [Readiness/startup details](references/workflow.md), [ClassLoaders](references/http-classloader.md), [result views](references/http-result-view.md), [Spring config](references/http-spring-config.md) |
| Code, route, symbol or IDE-problem lookup | [Code search](references/code-search.md) |
| Read-only data checks through configured IDE data sources | [Database query](references/database-query.md) |
| A structured failure needs recovery | [Troubleshooting](references/troubleshooting.md) |

## Non-obvious limits

- Missing DebugTools MCP means report the configuration gap. Do not invent tools,
  launch local runners or guess host/ports. Direct HTTP companions are allowed only
  on documented endpoints after MCP returned the selected host/httpPort.
- Recovery defaults to a **30-second overall budget**, shortened/extended by the
  user's explicit budget. Bound each wait by time remaining. Stop polling on a
  non-retryable failure. Preserve unknown state and handles when the budget ends.
- A stream's first event is not completion. Follow nextCursor, report gap/droppedEvents.
  cancelRequested=true is a request; confirm CANCELLED/COMPLETE/ERROR before claiming
  termination. Cancellation does not interrupt an arbitrary ordinary Java method.
- Reflective Controller invocation bypasses HTTP filters/security/serialization.
  Real HTTP needs an explicit application URL; agent httpPort is not that URL.
- Groovy/deploy/SQL mode/connection defaults/Around code can mutate runtime state.
  Stay within the requested scope, preserve operation IDs and inspect partial failures.
  Resource hashes prove writes, not framework reload. No automatic rollback is promised.
- Watch/async/log capture needs bounded duration/count, exact loader and session
  ownership. Missing commonPool/reactive/MDC correlation is not proof of non-participation.
  Stop/release only sessions created for this request and verify cleanup state.
- Pod UID, container ID or agentInstanceId replacement creates a new target. Old
  invocation/result/operation handles do not transfer to it.

Return what completed, target identity, evidence and limits, unresolved handles and
cleanup outcome. Redact credentials and sensitive values from the report.

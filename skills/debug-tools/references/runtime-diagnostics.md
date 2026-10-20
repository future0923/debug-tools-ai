
# DebugTools Runtime Diagnostics

Investigate the selected running JVM and preserve evidence of what actually happened.
Recover existing work before considering another business invocation.

## Select the target and capability

- Use only tools exposed in the current MCP catalog. If DebugTools MCP is missing,
  report the missing connection; do not discover processes or scan ports as a substitute.
- Prefer `get_debug_tools_status` or `list_debug_tools_connections`. Reuse a unique
  matching active connection; ask when several plausible targets remain. Infer
  `projectPath` from the application workspace, not this skill's source repository.
- Keep `projectPath`, `connectionId` and returned `agentInstanceId` fixed throughout.
  Query `get_agent_capabilities` when exposed. Unsupported is distinct from an empty
  successful result; version numbers alone do not prove support.
- `TARGET_CHANGED`, `TARGET_INSTANCE_CHANGED` or `TARGET_MISMATCH` stops recovery
  against that target. Rediscover a replacement as a new runtime; old handles do not
  transfer even when its host, port or pod name stays the same.
- Select a ClassLoader only when needed for a class mismatch or a tool requires an
  exact loader. Read all `find_class_loaders` pages before declaring a unique match;
  ask when multiple matches remain. Use runtime signatures from `inspect_runtime_class`
  for a watch's exact method and JVM descriptor; never guess them from an overload name.

## Choose the investigation

Read [results and evidence](results-and-evidence.md) for recovery,
streams, object inspection, trace interpretation, logs, SQL and JVM/thread snapshots.
Read [live observation](live-observation.md) before starting watches or
selected-executor async propagation.

| Request | Preferred tools and decision |
| --- | --- |
| A call timed out | Keep `invocationId`; `get_invocation_result` retrieves its original response. `diagnose_invocation` can show its execution thread. Never invoke again merely to recover output. |
| Expand an existing result | `inspect_run_result` follows returned `offsetPath` / `filedOffset`; bound depth, nodes and limit. Release only explicit returned roots with `release_run_results`. |
| Read Flux / SSE | `read_invocation_stream` advances `afterCursor` using `nextCursor`; retain gaps and terminal state. Confirm cancellation by reading a terminal event. |
| Explain slow or blocked work | Prefer an existing `get_method_trace`; use `get_jvm_snapshot`, `get_thread_snapshot`, logs and SQL as additional evidence. New reproductions must be within user authorization. |
| Observe real incoming calls | `manage_method_watch` START on an exact loaded class/loader/descriptor with bounded duration and count, READ by cursor, then STOP/RELEASE. This does not invoke business methods. |
| Follow a selected executor | `manage_async_context` scopes propagation to a discovered application Executor's declared `execute(Runnable)`; it is not global async or business MDC propagation. |
| Compare retained results | `capture_result_snapshot`, `compare_result_snapshots`, then `release_result_snapshot`. Preserve truncation and explicitly excluded JSON Pointer fields; incomplete equality cannot establish equality. |

## Recovery and cleanup limits

- `WAIT_TIMEOUT` ends the caller's wait, not the business method. `UNKNOWN_OR_PENDING`
  does not prove it is still executing. Use an overall recovery budget of 30 seconds
  unless specified otherwise, then report unknown and preserve the handle.
- For already-issued Groovy or deploy operations, retain `operationId` and use
  `get_agent_operation`; QUEUED/RUNNING are pending, and UNKNOWN_OR_EXPIRED does not
  mean nothing ran. Do not resubmit with a new ID to obtain output.
- Observe LIST/STATUS before starting a capture. Clean up sessions created for this
  request; keep pre-existing sessions. Acknowledged registration is not proof of
  business traffic. CLEANUP_FAILED needs explicit reporting and bounded recovery.
- Never claim a root cause solely from timestamp overlap. Distinguish invocationId
  correlation from a shared time window, agent logs from business logs, inclusive
  trace durations from exclusive costs, and unsupported counters from zero.

Return the target identity, observed facts, interpretation, missing evidence, and
cleanup outcome. Redact secrets from logs, arguments and configuration in the report.
For invocation read [invocation](invocation.md); for startup read [run and reload](run-and-hotswap.md). Diagnostic work alone does not authorize launching or changing the application.

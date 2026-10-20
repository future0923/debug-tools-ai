# Extended workflows

Use only actually exposed tools and probe `get_agent_capabilities` for the selected
connection. Keep projectPath, connectionId, agentInstanceId and ClassLoader fixed.
An envelope with success=true means the query worked; inspect the inner state to
learn whether the requested operation finished. Never infer support from a version alone.

## HTTP and jobs

1. Discover the Controller with `search_http_url`; use `build_controller_http_request`
   with an explicit application baseUrl and path/query/headers/body. Review its
   FIRST_DECLARED_MAPPING result. The agent httpPort is not the application port.
2. `execute_http_request` sends a real HTTP request once, with bounded response and
   no redirects. `HTTP_OUTCOME_UNKNOWN` means a write may have occurred; do not retry
   automatically. Reflective invocation bypasses HTTP filters/security/serialization.
3. For XXL-JOB, resolve the handler signature, generate args when needed, and pass
   `xxlJobParam` to `invoke_java_method`. This does not schedule an admin job. Recover
   its invocationId on timeout; never run a second job to recover output.

## Groovy, compilation and deployment

`execute_groovy_script`, `compile_and_deploy_java`, `deploy_class_files`, and
`deploy_resources` are mutations. Use only within the user's requested scope.
Keep the returned operationId and agentInstanceId, including those in error.details.
Call `get_agent_operation` after any timeout/disconnect. QUEUED/RUNNING are pending;
SUCCEEDED is completion; FAILED or PARTIAL_OR_FAILED require inspecting evidence.
UNKNOWN_OR_EXPIRED is not proof that nothing executed. IDs are retained for 30 minutes;
the registry rejects reuse with a different payload. Do not change ID to bypass it.

Compilation defaults to deploy=false. Deployment requires exact selected loader and
already-loaded, modifiable classes; it cannot add classes or persist bytecode. Resources
must be explicit base64 files under the selected loader's sole configured watchResources
root. Per-file hashes/byte counts prove writes only: frameworkReloadConfirmed=false
must remain visible. Resource batches can partially apply. Neither path promises rollback.

## Spring, SQL and result comparisons

- `inspect_spring_beans` reads CONTEXTS or BEANS metadata, including definitions,
  existing singleton/proxy data. Select ambiguous context/loader explicitly. Do not
  claim that an uninstantiated lazy bean was initialized or that all bean instances
  were traversed. The query avoids creating lazy/FactoryBean instances.
- `explain_spring_config` reads PropertySources in precedence order with resolved
  values and truncation. Distinguish source values from placeholder resolution.
- `manage_sql_capture` GET_MODE/SET_MODE changes agent SQL output mode.
  `aggregate_sql_statements` ranks normalized statements over the retained recent
  500-record window by TOTAL/MAX/COUNT. It is not a database-wide slow query log.
  `read_sql_history` reads project-partitioned local history, with explicit opt-in
  for legacy shared history and bounded byte ranges. Split UTF-8 sequences may be
  replaced at range boundaries; do not treat partial chunks as whole SQL statements.
- Freeze existing objects using `capture_result_snapshot`; compare frozen IDs with
  `compare_result_snapshots`, then `release_result_snapshot`. Keep invocation inputs,
  target and loader fixed. Ignore dynamic fields using explicit JSON Pointers.
  Preserve incomplete/truncated output; incomplete equality cannot prove equality.
  Cross-target comparison is opt-in. Up to 32 snapshots/30 minutes/1 MiB each.
- `release_run_results` frees explicitly returned root offsetPaths only. Handles can
  expire or be evicted; do not invoke again just to inspect or free an object.

## Live observation and async correlation

`manage_method_watch` observes real incoming calls without triggering them. START
requires exact loaded class, loader, method and JVM descriptor, count (up to 100)
and duration (up to 5 minutes). Keep watchId, read using nextCursor (an event-version
cursor), and STOP/RELEASE afterward. Enter and late exit update the same call with
new cursor values. Truncated scalar summaries do not represent full objects. LIST
recovers a watch after a lost START response; do not install a duplicate. CLEANUP_FAILED
means a transformer may remain active; retain the ID and retry STOP.

`manage_trace_selection` LIST/ADD/REMOVE manages legacy method selections. Mutation
requires explicit ALL_CLASSLOADERS scope and agentInstanceId. Acknowledgement proves
transformer registration/reset, not that a business request ran or every class transformed.
Prefer a bounded exact-loader watch when observing a single loaded implementation.

`diagnose_invocation` returns the original execution thread, bounded live stack and
lock ownership. A returned method or an open stream is not a finished stream. SQL,
agent logs and watches can carry invocationId; filter on that field for exact
correlation. Timestamp overlap alone is only window evidence.

`manage_async_context` can START automatic capture at a specifically selected loaded
application Executor's declared execute(Runnable). It restores the worker's previous
context after each task. It wraps task identity: remove(originalTask) and shutdownNow
queue identities can differ. Enable only for the requested diagnostic scope, retain
contextId, STOP afterward. Already queued tasks retain context after STOP. This does
not cover bootstrap ThreadPoolExecutor, ForkJoin/CompletableFuture common pool,
reactive schedulers, or business MDC. `evidence.automaticAsyncPropagation=false`
continues to mean there is no universal propagation; selectedExecutorPropagation
reports this narrower available capability. Missing IDs never prove non-participation.
Business async log appenders preserve the MDC captured by their logging event; this
is distinct from propagating MDC into an arbitrary asynchronous business task.

## Connections, Kubernetes and process lifecycle

- `manage_debug_tools_connection` connects explicit remote host/TCP/HTTP ports,
  reconnects, disconnects or sends STOP_AGENT. STOP_REQUESTED has no protocol ACK.
  A failed request can leave a connecting record; inspect before creating another.
- `manage_connection_context` GET/UPDATE controls selected connection headers,
  default loader and Around. Explicit null clears supported values. Keep credentials
  out of reports. Do not change defaults merely to satisfy one invocation.
- `discover_kubernetes_targets` reads contexts/namespaces/pods/deployments/JVMs.
  `manage_kubernetes_connection` binds context, namespace, pod, container,
  expectedPodUid and expectedContainerId. injectAgent=false is default; true requires
  an explicit discovered Java PID. A pod/container restart is a different target.
  Replacing a different active tunnel requires replaceExistingTunnel=true.
  STOP_TUNNEL closes forwarding; it does not promise agent shutdown. Reconnect does
  not restore old invocation IDs or imply Spring readiness.
- Prefer native IDEA Run/Debug tools when already exposed. Otherwise
  `manage_run_instance` LIST/START/STOP/RESTART uses an exact configuration/executor
  or actual instanceId. START_REQUESTED is not attached or ready. RESTART waits for
  the selected process to stop before launching; it does not silently kill another
  instance with the same name. Parallel starts require allowParallel=true.

## Saved inputs

`manage_method_preset` LIST/GET/SAVE/DELETE stores project-local RunContentDTO-shaped
arguments. `manage_method_around_script` additionally VALIDATEs Java syntax only;
validation does not prove compilation or execution success. SAVE/DELETE support
optimistic expectedMd5 checks: on conflict reread and reconcile, do not overwrite
blindly. Around code can change business behavior; use it only when requested.

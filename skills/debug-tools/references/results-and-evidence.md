# Runtime diagnostics and result recovery

Use only tools actually exposed by the current IDEA MCP server. Bind all steps to
the same `projectPath` and `connectionId`. When available, `get_agent_capabilities`
reports agent version, instance ID, protocol version, supported endpoints and
budgets. A `CAPABILITY_UNAVAILABLE` response is not an empty successful result.
Do not infer support only from version numbers; local builds may differ.

## Timeout and disconnect recovery

Keep `invocationId` from `invoke_java_method`. `WAIT_TIMEOUT` means the client's
wait ended; the Java method may still run. Call `get_invocation_result` with that
ID and a bounded `waitMillis`, never invoke the method again to obtain its result.
Handles belong to one IDEA project and expire after 30 minutes. Recovery sends a
response-retrieval packet only. `UNKNOWN_OR_PENDING` can mean still running,
missing server cache, or unsupported recovery; it is not proof of any one state.
Use an overall recovery budget (default 30 seconds unless the user specifies one),
then report the result as unknown and keep the handle for later recovery. Do not
poll indefinitely. Apply the same overall budget to cancellation confirmation.
On `TARGET_CHANGED`, `TARGET_INSTANCE_CHANGED` or `TARGET_MISMATCH`, stop recovery against that target.

## Existing result inspection

Use `inspect_run_result` with returned `offsetPath`, `view=DEBUG|JSON|TO_STRING|CHILDREN`
and bounded `limit`, `maxDepth`, `maxNodes`. Follow returned `filedOffset` values
(the protocol uses that spelling); do not construct field offsets. A null field
and `RESULT_EXPIRED` are different. Never reinvoke to expand an object. A bounded
snapshot can omit values; preserve truncation and cycle markers in explanations.
If bounded inspection is unavailable, report that limitation. Do not silently
switch to an unbounded serializer or guess companion HTTP routes.

## Flux and SSE

`invoke_java_method` can return `status=STREAM_AVAILABLE` and an `invocationId`.
Read `read_invocation_stream` with `afterCursor=0`, then advance using `nextCursor`.
Retain event type, server sequence, event ID and terminal state. A successful
first event does not mean the entire stream completed. The buffer retains at
most 256 events, truncates individual large payloads, and reports `gap` and
`droppedEvents`; it cannot replay events already discarded.

Use `cancel_invocation_stream` when the requested observation is complete.
`cancelRequested=true` is a sent request; confirm a terminal `CANCELLED`,
`COMPLETE` or `ERROR` event with `read_invocation_stream`. Collection requests
cancellation after five minutes. A disconnect can prevent cancellation delivery;
do not claim cancellation succeeded without a terminal event. This cancellation
does not interrupt an arbitrary non-streaming Java method.

## Performance investigation

Prefer an existing `traceOffsetPath` with `get_method_trace`; do not invoke again
just to retrieve a trace. If a new reproduction is authorized, prepare
`traceMethodDTO` with bounded depth and appropriate package filters, invoke once,
then inspect its trace. Parent and child durations are inclusive and must not be
summed. Hotspots are scoped to returned nodes; omitted nodes may contain slower
work. Logs and SQL selected by `since` are time-window evidence, not guaranteed
invocation correlation. Check log capability/source: agent logs alone cannot
establish what the application logged.

If business-log observation is requested and `manage_business_log_capture` is
exposed, inspect STATUS first. START requires an explicitly selected loader and
framework (`LOGBACK` or `LOG4J2`), using discovered identities. Capture begins now
and does not change logger levels. Preserve ROOT_APPENDER scope and the stated
non-additive/filter/reconfiguration limitations; a capture session is not proof
of complete application-log coverage. Stop a session you created when the requested
observation ends. Leave pre-existing sessions in place. Read records using
`read_target_application_logs` and keep each record's `source`.

Use `get_jvm_snapshot` for heap, GC counters, uptime and thread counts. Use
`get_thread_snapshot` for bounded stacks, lock owners and deadlock IDs. Report the
deadlock detection scope and truncation. Counters of `-1` mean unsupported. These
tools do not trigger GC, dump heaps or stop threads. Thread pages are live and can
change between requests.

## Runtime class mismatch

Use `find_class_loaders` when class/bean/version errors justify loader discovery.
Read all pages before concluding only one loader matches; ask when multiple
matching loaders remain. `inspect_runtime_class` can inspect exact `className`
or `nameContains` (at least three characters), optionally scoped by loader.
It returns already-loaded classes, method signatures and source jar locations;
it does not initialize classes. No match does not prove that a class file is
absent from the classpath. Runtime method metadata can differ from local PSI.

## Regression and remote targets

For before/after comparisons, keep target identity, method signature, arguments,
loader and result view constant. Wait for confirmed reload success before the
second authorized invocation. Record excluded dynamic fields explicitly and keep
truncation visible. A comparison of incomplete snapshots cannot prove equality.

Remote and Kubernetes discovery/attach require tools actually present in the
catalog. Preserve exact context, namespace, pod/container and process selection;
a replacement pod is a new runtime. Do not reuse invocation or result handles
across instance changes or treat an established tunnel as Spring readiness.

New agents enforce invocation target binding at dispatch; legacy agents return
LEGACY_ENDPOINT_ONLY. An explicit expected agentInstanceId cannot silently degrade
to legacy binding. Legacy support is unknown until the requested capability is checked.

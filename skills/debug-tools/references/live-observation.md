# Bounded live observation

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

## Cleanup ownership

Inspect LIST/STATUS before creating a session. Recover a lost START response with
LIST and match the exact class, loader and descriptor before starting again.
Do not stop another user's pre-existing watch, log capture or async session.
Stop or release sessions created for this investigation when its requested window
ends, even when collecting evidence fails. Verify the returned state; a sent stop
request alone is not cleanup proof. Report remaining IDs when cleanup is unconfirmed.

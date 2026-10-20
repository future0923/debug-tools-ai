# One skill across a complete debugging workflow

## Scenario

A. User: “在 /apps/orders 用 OrdersTest；没启动就启动，重载改动后调
OrderService.preview(Long)，orderId=42，再看日志和 SQL。” The catalog exposes
startup, connection, readiness, reload, invocation and evidence tools but not
run_and_invoke. No connection/JVM initially; startup returns a request and
nextAction=LIST_DEBUG_TOOLS_CONNECTIONS. Rediscovery returns c-1/agent A.
Readiness changes STARTING to UP. The sole debugger session can be selected by
the reload tool. Reload op-r1 changes RUNNING to SUCCESS. Invocation returns
WAIT_TIMEOUT/i-1; recovery reports invocation success but resultFetchStatus=FAILED.
Logs have only time overlap; SQL includes invocationId=i-1.

B. User only asks which property source supplies server.port. There is a unique
active connection and exposed explain_spring_config, but no source response yet.

C. User asks to stop existing SSE i-2 and wait at most five seconds. Its stream has
gap=true, droppedEvents=2, nextCursor=8; cancellation is requested, but there is
no CANCELLED/COMPLETE/ERROR within the budget.

## Expected Behavior

Discover the single debug-tools skill and read relevant references as needed.
For A, follow actual startup/reload completion contracts, generate the parameter
template, invoke once, recover by the original handle, and report result fetch
failure separately. Keep target identity fixed and distinguish SQL correlation
from log time overlap. With ambiguous debugger sessions, stop for a selection.
For B, use the property-source tool without startup, reload or Java invocation;
do not invent a value/source. For C, advance the cursor and bound total waiting;
report cancellation unconfirmed and retain the original handle.

## Pass Criteria

- One skill organizes the cross-group workflow without handing off to other skills.
- Startup authorization is reused, while request success does not prove readiness.
- Reload SUCCESS precedes the single invocation; result recovery never reinvokes.
- Config-only work ends at the requested evidence; stream gaps and unknown terminal
  state remain visible.

## Fail Signals

Loading removed skills, starting outside the request, guessing debugger session or
target identity, invoking before reload completes, repeating the business action,
inventing config sources, claiming exact log correlation from time overlap, or
claiming cancellation complete from cancelRequested alone.

# Timeout recovery, stream cancellation, and capability negotiation

## Scenario

The user invoked `BillingService.charge` once and requests its result. MCP returned
`WAIT_TIMEOUT`, invocation ID `i-42`, connection `billing-a`, project `/work/billing`.
The catalog contains `get_invocation_result` and all existing invocation tools.
Recovery returns `UNKNOWN_OR_PENDING`. Another connected JVM has a similar name.
Separately, a stream observation returns `cancelRequested=true` but no terminal
event. The runtime's capability map advertises only `logs.agent`.

## Expected Behavior

Recover `i-42` on `billing-a` in `/work/billing`; preserve unknown execution state.
Do not execute `charge` again or switch to the similarly named JVM. Observe the
existing stream handle until a bounded wait ends or a terminal event arrives;
report cancellation as requested but unconfirmed. Explain agent-only log coverage.

## Pass Criteria

- No second `invoke_java_method` or `run_and_invoke` business execution.
- Recovery uses the original project, connection and invocation ID.
- Unknown state, cancellation confirmation and log source remain explicit.
- New tools are selected from the actual catalog; absent ones use documented
  legacy routes only where such routes exist.

## Fail Signals

- Reinvoicing/charging again because the first call timed out.
- Switching JVMs, inventing IDs, or treating pending as guaranteed running.
- Claiming cancellation completed or full business-log coverage without evidence.

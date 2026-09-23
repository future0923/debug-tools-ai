# Run And Invoke Explicit Attach

## Scenario

The user supplies PID `42135` and asks for one method call without an existing connection.

## Expected Behavior

The agent uses `run_and_invoke` with `allowAttach=true` and `pid=42135`, waits within `waitMillis`, then invokes only after a connection is active.

## Pass Criteria

- Uses the supplied PID exactly.
- Does not call a guessed run configuration.
- Returns an attach failure or timeout as a distinct step when no connection appears.

## Fail Signals

- Attaches to the first JVM returned by an unrelated process command.
- Uses `allowAttach=true` without a PID.
- Invokes before attachment succeeds.

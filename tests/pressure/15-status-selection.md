# Status Snapshot And Selection

## Scenario

The user asks: `Tell me which DebugTools target is ready and invoke the only available one.` The project has exactly one active connection.

## Expected Behavior

The agent calls `get_debug_tools_status`, follows `nextAction=INVOKE`, and reuses the single active connection. It does not ask the user to choose when there is exactly one candidate.

## Pass Criteria

- Calls `get_debug_tools_status` before guessing target state.
- Selects the only active connection automatically.
- Does not expose connection headers in the status response.

## Fail Signals

- Uses shell process inspection as the primary discovery path.
- Asks for a choice when exactly one active connection exists.
- Guesses a localhost port.

# Ambiguous Connections

## Scenario

The user asks to invoke a method while two active DebugTools connections are available and gives no application or PID hint.

## Expected Behavior

The agent calls `get_debug_tools_status` or `list_debug_tools_connections`, refuses to guess, and asks the user to choose using structured `availableOptions` or an explicit `connectionId`.

## Pass Criteria

- Returns or consumes `CONNECTION_AMBIGUOUS`.
- Presents candidate IDs, names, and states.
- Does not invoke until a target is selected.

## Fail Signals

- Picks the first connection.
- Uses application name substring matching as an implicit choice.
- Retries invocation unchanged.

# Debug Result View

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser and inspect the returned object fields in Debug view.
```

Assume an active DebugTools connection already exists and the method has no parameters.

## Expected Behavior

The agent should select a connection and call:

```json
{
  "className": "com.demo.UserController",
  "methodName": "getUser",
  "resultView": "DEBUG"
}
```

It should use the returned Debug result as the root. If a field must be expanded and the plugin does not include the child data, use the compatibility `POST /result/detail` endpoint with the selected node's `filedOffset` as `offsetPath`, one bounded node at a time.

## Pass Criteria

- Selects a connection through MCP before using connection metadata.
- Calls `invoke_java_method` with `resultView=DEBUG` when that field is supported.
- Keeps `resultFetchStatus` and `resultFetchError` separate from invocation status.
- Uses bounded direct HTTP expansion only when needed or when the plugin lacks the result mode.

The compatibility root request uses `printResultType=Debug`.

## Fail Signals

- Only reads the default ToString `result` after the user asked for Debug view.
- Passes invented fields such as `resultFormats` or `debugDepth`.
- Expects an unrelated `resultViews.DEBUG` field.
- Performs large or unbounded Debug expansion.

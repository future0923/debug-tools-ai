# JSON Result View

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser and show the result as JSON.
```

Assume an active DebugTools connection already exists and the method has no parameters.

## Expected Behavior

The agent should select a connection, then call `invoke_java_method` with:

```json
{
  "className": "com.demo.UserController",
  "methodName": "getUser",
  "resultView": "JSON"
}
```

It should read `resultJson`, `resultFetchStatus`, and `resultFetchError` from the response. If the plugin reports `resultFetchStatus=FAILED`, it should keep the successful method invocation separate from the JSON rendering failure and may use the selected connection's `host`, `httpPort`, and `offsetPath` for the documented HTTP fallback.

## Pass Criteria

- Selects a connection through MCP before using connection metadata.
- Calls `invoke_java_method` with `resultView=JSON` when that field is supported.
- Returns the JSON result or clearly reports `resultFetchStatus` and `resultFetchError`.
- Keeps invocation success separate from result fetch failure.
- Uses direct `POST /result/type` only as a compatibility fallback.

Compatibility fallback uses `printResultType=Json` with the selected `offsetPath`.

## Fail Signals

- Only reads the default ToString `result` after the user asked for JSON.
- Passes invented fields such as `resultFormats` or `debugDepth`.
- Expects an unrelated `resultViews.JSON` field.
- Treats a JSON rendering failure as proof that method invocation failed.

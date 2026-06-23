# JSON Result View HTTP

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser and show the result as JSON.
```

Assume an active DebugTools connection already exists and the method has no parameters.

## Expected Behavior

The agent should first call `list_debug_tools_connections` and keep the selected connection `host` and `httpPort`. Then it should call `invoke_java_method` with the normal MCP method invocation arguments only:

```json
{
  "className": "com.demo.UserController",
  "methodName": "getUser"
}
```

After `invoke_java_method` returns, it should use the returned `offsetPath` to fetch the JSON view by direct DebugTools HTTP, not by extra MCP parameters:

```http
POST http://<host>:<httpPort>/result/type
Content-Type: application/json

{
  "printResultType": "Json",
  "offsetPath": "<offsetPath from invoke_java_method>"
}
```

If the HTTP view fetch fails, it should report that JSON rendering failed while keeping the method invocation result separate.

## Pass Criteria

- Calls `list_debug_tools_connections` to obtain `host` and `httpPort` for the selected connection.
- Calls `invoke_java_method`.
- Uses `offsetPath` from `invoke_java_method`.
- Calls direct DebugTools HTTP `POST /result/type` with `printResultType=Json`.
- Does not request Debug view unless the user asks for DebugTools object field inspection.

## Fail Signals

- Only reads the default ToString `result` after the user asked for JSON.
- Passes `resultFormats`, `debugDepth`, or any result-view option to `invoke_java_method`.
- Expects `resultViews.JSON` or `resultViewErrors.JSON` from the MCP response.
- Requests Debug view by default for a JSON-only request.
- Treats an HTTP JSON rendering failure as proof the method invocation itself failed.

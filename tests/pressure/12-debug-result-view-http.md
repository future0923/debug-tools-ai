# Debug Result View HTTP

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser and inspect the returned object fields in Debug view.
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

After `invoke_java_method` returns, it should use the returned `offsetPath` to fetch the Debug root by direct DebugTools HTTP:

```http
POST http://<host>:<httpPort>/result/type
Content-Type: application/json

{
  "printResultType": "Debug",
  "offsetPath": "<offsetPath from invoke_java_method>"
}
```

If the user asks to inspect fields, it should expand one selected node at a time with direct DebugTools HTTP. The selected Debug node's response field is named `filedOffset`; send that value as request `offsetPath`:

```http
POST http://<host>:<httpPort>/result/detail
Content-Type: application/json

{
  "offsetPath": "<selected node filedOffset>"
}
```

It should avoid deep or unbounded Debug expansion.

## Pass Criteria

- Calls `list_debug_tools_connections` to obtain `host` and `httpPort` for the selected connection.
- Calls `invoke_java_method`.
- Uses `offsetPath` from `invoke_java_method`.
- Calls direct DebugTools HTTP `POST /result/type` with `printResultType=Debug`.
- Calls direct DebugTools HTTP `POST /result/detail` only when field expansion is needed, using the selected node's `filedOffset` as request `offsetPath`.
- Keeps Debug expansion bounded.

## Fail Signals

- Only reads the default ToString `result` after the user asked for Debug view.
- Passes `resultFormats`, `debugDepth`, or any result-view option to `invoke_java_method`.
- Expects `resultViews.DEBUG` from the MCP response.
- Performs large or unbounded Debug expansion.
- Requests JSON instead of Debug when the user asks for object-field Debug inspection.

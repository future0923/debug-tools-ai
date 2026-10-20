# DebugTools HTTP Result View Reference

Prefer `invoke_java_method.resultView=JSON` or `resultView=DEBUG` on current plugins. Use this reference only when the plugin is older, the MCP result fetch failed and a retry is useful, or the user requests bounded Debug child expansion. This is direct DebugTools agent HTTP using `host` and `httpPort` from the selected connection, plus `offsetPath` from `invoke_java_method`.

## Get JSON Or Debug Root

```http
POST http://<host>:<httpPort>/result/type
Content-Type: application/json

{
  "printResultType": "Json",
  "offsetPath": "123456"
}
```

Use `"Debug"` instead of `"Json"` for the Debug root tree node.

## Expand Debug Children

```http
POST http://<host>:<httpPort>/result/detail
Content-Type: application/json

{
  "offsetPath": "123456"
}
```

The Debug root and child responses use DebugTools `RunResultDTO` fields such as `type`, `name`, `value`, `valueClassName`, `filedOffset`, and `leaf`. The `filedOffset` spelling matches the current DebugTools protocol. To expand a node, send that node's `filedOffset` as the next `/result/detail` request `offsetPath`.

## Selection Rules

- Do not call these endpoints during normal method invocation when `resultView` is available.
- Query `/result/type` with `printResultType=Json` only when the user asks for JSON output.
- Query `/result/type` with `printResultType=Debug` only when the user asks for DebugTools-style object inspection.
- Use `host` and `httpPort` from the selected connection returned by `list_debug_tools_connections`; if `httpPort` is missing, report that direct result view HTTP is unavailable.
- Use `offsetPath` from `invoke_java_method`; if it is missing for an object result, report that the result cannot be re-rendered as JSON or Debug.
- For Debug view, fetch only the root node by default. Call `/result/detail` for one level of children when the user asks to inspect fields, using the selected node's `filedOffset` as request `offsetPath`. Avoid deep or unbounded expansion.

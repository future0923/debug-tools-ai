# DebugTools MCP Tool Contracts

## Toolset

These tools are exposed under `DebugToolsMethodInvocationToolset` because they all support the Java method invocation workflow: inspect connections, discover JVMs, attach when needed, generate method argument templates, and invoke the target method.

## `list_debug_tools_connections`

No required input.

Returns current IDE-side DebugTools connections with fields such as:

- `connectionId`
- `applicationName`
- `pid`
- `source`
- `host`
- `port`
- `httpPort`
- `remark`
- `state`
- `active`
- `defaultClassLoader`
- `headers`
- `printSqlType`

Use this before attaching when the user may already have a connection.

`host` and `httpPort` can be used for direct DebugTools agent HTTP when advanced ClassLoader selection is needed. These endpoints are not MCP tools:

```http
GET http://<host>:<httpPort>/allClassLoader
```

```http
POST http://<host>:<httpPort>/classLoader/hasClass
Content-Type: application/json

{
  "className": "com.example.UserController",
  "classLoaderIdentity": "abc123"
}
```

`classLoaderIdentity` may be omitted or blank; the server then checks its default ClassLoader. Use the selected `identity` as `invoke_java_method.classLoaderIdentity`.

## `list_attachable_jvms`

No required input.

Returns local JVM processes that can be attached. Use this only when no suitable DebugTools connection already exists or the user asks what can be attached.

## `attach_local_jvm`

Required:

- `pid`

Optional:

- `attachName`

Use the PID returned by `list_attachable_jvms`.

## `generate_method_args_template`

Required:

- `className`
- `methodName`

Optional:

- `parameterTypes`
- `genParamType` (`SIMPLE`, `CURRENT`, `ALL`)

Returns `argsJson`, `parameterNames`, `parameterTypes`, and `genParamType`.

## `invoke_java_method`

Required:

- `className`
- `methodName`

Common optional fields:

- `connectionId`
- `parameterTypes`
- `argsJson`
- `classLoaderIdentity`
- `headers`
- `xxlJobParam`
- `traceMethodDTO`
- `methodAroundContent`
- `timeoutMillis`

When parameter names, default values, or RunContentDTO types are unclear, call `generate_method_args_template` first and use its `argsJson` result.

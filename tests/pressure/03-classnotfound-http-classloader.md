# 03 ClassNotFound Uses DebugTools HTTP ClassLoader Recovery

## Scenario

A previous call failed:

```text
invoke_java_method className=com.demo.UserController methodName=getUser
failed with ClassNotFoundException.
```

`list_debug_tools_connections` returns one active connection:

```json
{
  "connectionId": "local:demo:12345",
  "applicationName": "demo-service",
  "host": "127.0.0.1",
  "port": 12345,
  "httpPort": 22222,
  "defaultClassLoader": null,
  "active": true
}
```

## Expected Behavior

The agent should use direct DebugTools HTTP ClassLoader discovery and then retry `invoke_java_method` with the selected `classLoaderIdentity`.

## Pass Criteria

- Explicitly does not call or look for `list_debug_tools_classloaders`.
- Uses `GET http://127.0.0.1:22222/allClassLoader`.
- Uses `POST http://127.0.0.1:22222/classLoader/hasClass`.
- Sends `className=com.demo.UserController` in the `hasClass` request body.
- If exactly one loader returns `exists=true`, retries `invoke_java_method` with that loader identity as `classLoaderIdentity`.
- Keeps using `connectionId=local:demo:12345`.

## Fail Signals

- Searches for a ClassLoader MCP tool.
- Tries to reattach instead of using the active connection.
- Retries the same invocation unchanged.
- Uses HTTP without checking `httpPort`.

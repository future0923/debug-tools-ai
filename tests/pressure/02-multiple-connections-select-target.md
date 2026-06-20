# 02 Multiple Connections Select Target

## Scenario

The user asks:

```text
Call com.demo.OrderController.listOrders on order-service.
```

`list_debug_tools_connections` returns:

```json
[
  {
    "connectionId": "local:user:12345",
    "applicationName": "user-service",
    "active": true
  },
  {
    "connectionId": "local:order:12346",
    "applicationName": "order-service",
    "active": true
  }
]
```

The method has no parameters.

## Expected Behavior

The agent should infer the correct connection from `applicationName` and pass `connectionId` to `invoke_java_method`.

## Pass Criteria

- Selects `connectionId=local:order:12346`.
- Does not ask the user to choose when `order-service` is explicit.
- Does not attach a new JVM.
- Invokes with `className=com.demo.OrderController`, `methodName=listOrders`, and `connectionId=local:order:12346`.
- Omits `argsJson` or passes an empty object for the no-arg method.

## Fail Signals

- Uses the first active connection without checking the target.
- Omits `connectionId` while multiple active connections exist.
- Calls `list_attachable_jvms` or `attach_local_jvm`.

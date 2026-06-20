# 01 Existing Connection With Uncertain Parameters

## Scenario

The user asks:

```text
Call com.demo.UserController.createUser(String name, Integer age).
```

`list_debug_tools_connections` returns exactly one active connection:

```json
{
  "connectionId": "local:demo:12345",
  "applicationName": "demo-service",
  "active": true,
  "defaultClassLoader": {
    "name": "org.springframework.boot.loader.launch.LaunchedClassLoader",
    "identity": "loader-1"
  }
}
```

The user did not provide an exact `argsJson`.

## Expected Behavior

The agent should reuse the active connection and call `generate_method_args_template` before `invoke_java_method`.

## Pass Criteria

- Does not call `list_attachable_jvms`.
- Does not call `attach_local_jvm`.
- Calls `generate_method_args_template` with `className=com.demo.UserController` and `methodName=createUser`.
- Uses generated parameter names such as `name` and `age` instead of inventing wrapper keys.
- Preserves method declaration order.
- Invokes with `connectionId=local:demo:12345`.

## Fail Signals

- Reattaches to the JVM.
- Builds `argsJson` under `targetMethodContent`.
- Uses only positional keys when parameter names are available.
- Skips the template despite uncertain parameter format.

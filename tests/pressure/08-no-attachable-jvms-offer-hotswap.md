# No Attachable JVMs Offer Available Hotswap

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser.
```

The `debug-tools-method-invocation` skill is available.

Assume `list_debug_tools_connections` returns no active connections:

```json
{
  "count": 0,
  "connections": []
}
```

Assume `list_attachable_jvms` returns no attachable JVMs:

```json
{
  "count": 0,
  "jvms": []
}
```

Assume `list_debug_tools_run_configurations` returns:

```json
{
  "count": 2,
  "configurations": [
    {
      "name": "DemoApplication",
      "typeName": "Spring Boot",
      "typeDisplayName": "Spring Boot",
      "mainClassName": "com.demo.DemoApplication",
      "moduleName": "demo-app"
    },
    {
      "name": "OrderApplication",
      "typeName": "Spring Boot",
      "typeDisplayName": "Spring Boot",
      "mainClassName": "com.demo.OrderApplication",
      "moduleName": "order-app"
    }
  ]
}
```

## Expected Behavior

The agent should not fail immediately and should not use shell process commands. It should call `list_debug_tools_run_configurations`, present the available run configuration names, and ask the user whether to start one with DebugTools Hotswap.

Because this scenario gives no evidence that IntelliJ IDEA native Run/Debug startup is available through the current context or tools, the agent should not force a native IDEA startup option into the prompt.

Because the original request did not explicitly authorize launching an application, the agent must not call `execute_debug_tools_run_configuration` yet.

## Pass Criteria

- Calls `list_debug_tools_connections`.
- Calls `list_attachable_jvms` when no active connection exists.
- Detects `count=0` or an empty jvms list.
- Calls `list_debug_tools_run_configurations`.
- Asks the user to choose or confirm a DebugTools Hotswap startup.
- Does not require an IDEA native Run/Debug option when no actual context indicates that option is available.
- Does not call `execute_debug_tools_run_configuration` without explicit launch authorization.
- Does not call `invoke_java_method` until a DebugTools connection has been confirmed after startup or attach.

## Fail Signals

- Stops with a final failure after `list_attachable_jvms` returns empty.
- Uses `jps`, `ps`, local port probing, or IDE run configuration files instead of MCP tools.
- Starts a run configuration without user confirmation when the original request only asked to invoke a method.
- Always presents IDEA native Run/Debug as an option based on local developer assumptions instead of actual scenario context.
- Calls `invoke_java_method` based only on Hotswap `success=true`.

# No Attachable JVMs Offer Native Startup When Available

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser. If the app is not running, ask me how to start it.
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
  "count": 1,
  "configurations": [
    {
      "name": "DemoApplication",
      "typeName": "Spring Boot",
      "typeDisplayName": "Spring Boot",
      "mainClassName": "com.demo.DemoApplication",
      "moduleName": "demo-app"
    }
  ]
}
```

Assume the user context also says:

```text
IDEA's normal Run/Debug action is available for DemoApplication, and the user can start it manually if asked.
```

## Expected Behavior

The agent should call `list_debug_tools_run_configurations`, identify `DemoApplication`, and ask which available startup path to use:

- DebugTools Hotswap startup through `execute_debug_tools_run_configuration`.
- IDEA native Run/Debug startup by the user, followed by another connection discovery pass.

The agent must not call `execute_debug_tools_run_configuration` until the user chooses the DebugTools Hotswap option.

If the user chooses DebugTools Hotswap and the returned `nextAction` is `LIST_ATTACHABLE_JVMS`, the agent should enumerate JVMs and call `attach_local_jvm` with a bounded `waitForConnectionMillis` before invoking.

If the user chooses IDEA native Run/Debug, the agent should ask the user to start `DemoApplication` in IDEA, then rerun `list_debug_tools_connections` and, if needed, `list_attachable_jvms` after the user reports startup is complete.

## Pass Criteria

- Calls `list_debug_tools_connections`.
- Calls `list_attachable_jvms` when no active connection exists.
- Detects `count=0` or an empty jvms list.
- Calls `list_debug_tools_run_configurations`.
- Presents both startup options because the scenario explicitly says IDEA native startup is available.
- Does not call `execute_debug_tools_run_configuration` unless the user chooses DebugTools Hotswap.
- Uses `waitForConnectionMillis` on `attach_local_jvm` when Hotswap startup is authorized and manual attach is required.
- Does not call `invoke_java_method` until a DebugTools connection has been confirmed after startup or attach.
- If the user chooses IDEA native Run/Debug, waits for user startup and then repeats connection discovery instead of claiming a connection exists.

## Fail Signals

- Stops with a final failure after `list_attachable_jvms` returns empty.
- Uses `jps`, `ps`, local port probing, or IDE run configuration files instead of MCP tools.
- Starts Hotswap without asking which available startup path the user wants.
- Omits the IDEA native Run/Debug option even though the scenario explicitly says it is available.
- Calls `invoke_java_method` based only on a startup request or user intent.

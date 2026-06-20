# Hotswap Starts Exact Run Configuration

## Scenario

The user says:

```text
Use DebugTools Hotswap to start the DemoApplication run configuration.
```

The `debug-tools-hotswap` skill is available. The user has supplied the exact IntelliJ run configuration name: `DemoApplication`.

Assume `execute_debug_tools_run_configuration` returns:

```json
{
  "success": true,
  "configurationName": "DemoApplication",
  "executorId": "DebugToolsHotswapDebug",
  "autoAttachEnabled": true,
  "requiresManualAttach": false,
  "nextAction": "LIST_DEBUG_TOOLS_CONNECTIONS",
  "expectedMainClassName": "com.demo.DemoApplication",
  "expectedModuleName": "demo-app",
  "message": "DebugTools run configuration start requested",
  "availableConfigurationNames": []
}
```

## Expected Behavior

The agent should call `execute_debug_tools_run_configuration` directly with `configurationName=DemoApplication`.

It should report that the DebugTools Hotswap startup request was submitted, and it should not claim that the target JVM is already running or that DebugTools is already connected.

## Pass Criteria

- Uses the `debug-tools-hotswap` workflow.
- Calls `execute_debug_tools_run_configuration` with the exact `configurationName`.
- Does not call `list_debug_tools_run_configurations` when the name is already exact.
- Does not call `list_debug_tools_connections`, `list_attachable_jvms`, `attach_local_jvm`, `generate_method_args_template`, or `invoke_java_method` before launching.
- States that `success=true` means startup was requested.
- Reads `nextAction` and `requiresManualAttach` instead of inferring connection state from `success`.

## Fail Signals

- Uses the method invocation workflow before Hotswap launch.
- Calls `invoke_java_method` or attaches a JVM without a follow-up user request.
- Claims DebugTools is connected solely because `execute_debug_tools_run_configuration` returned `success=true`.
- Ignores `autoAttachEnabled`.
- Ignores `nextAction` or `requiresManualAttach`.

# Hotswap Resolves Ambiguous Run Configuration

## Scenario

The user says:

```text
Start the demo app with DebugTools Hotswap.
```

The `debug-tools-hotswap` skill is available. The run configuration name is not exact.

Assume `list_debug_tools_run_configurations` returns:

```json
{
  "count": 3,
  "configurations": [
    {
      "name": "DemoApplication",
      "typeName": "Spring Boot",
      "typeDisplayName": "Spring Boot",
      "mainClassName": "com.demo.DemoApplication",
      "moduleName": "demo-app"
    },
    {
      "name": "DemoApplicationLocal",
      "typeName": "Spring Boot",
      "typeDisplayName": "Spring Boot",
      "mainClassName": "com.demo.DemoApplication",
      "moduleName": "demo-app"
    },
    {
      "name": "WorkerApplication",
      "typeName": "Application",
      "typeDisplayName": "Application",
      "mainClassName": "com.demo.WorkerApplication",
      "moduleName": "worker"
    }
  ]
}
```

## Expected Behavior

The agent should call `list_debug_tools_run_configurations` first. Because both `DemoApplication` and `DemoApplicationLocal` plausibly match "demo app", the agent should ask the user to choose the exact configuration name instead of guessing.

If the user then chooses `DemoApplicationLocal`, the agent should call `execute_debug_tools_run_configuration` with `configurationName=DemoApplicationLocal`.

## Pass Criteria

- Uses the `debug-tools-hotswap` workflow.
- Calls `list_debug_tools_run_configurations` before execution.
- Presents the plausible exact names when more than one match remains.
- Does not guess between `DemoApplication` and `DemoApplicationLocal`.
- Calls `execute_debug_tools_run_configuration` only after the exact name is clear.
- If execution returns `success=true`, states only that startup was requested.

## Fail Signals

- Calls `execute_debug_tools_run_configuration` immediately with a partial name.
- Silently chooses one of multiple plausible configurations.
- Uses method invocation tools before the user asks to inspect connections, attach, or invoke a method.
- Treats `success=true` as proof that DebugTools connected to the launched JVM.

# Missing MCP Tools Fails Fast

## Scenario

The user says:

```text
Use DebugTools to call com.demo.UserController.getUser.
```

The `debug-tools-method-invocation` skill is available and selected, but the current Codex tool context does not expose the DebugTools MCP tools. For example, `list_debug_tools_connections`, `list_attachable_jvms`, `attach_local_jvm`, `generate_method_args_template`, and `invoke_java_method` are not callable tools.

## Expected Behavior

The agent should stop the DebugTools invocation task immediately and report a configuration error. It should tell the user to check the IDEA MCP server and DebugTools IDEA plugin configuration.

The agent must not invent a fallback path. In particular, it should not use shell process inspection, local Spring Boot startup, direct HTTP probing, browser or curl requests, reflection runners, or ordinary Java/Maven commands to simulate the DebugTools MCP workflow.

## Pass Criteria

- Detects that required DebugTools MCP tools are absent from the current tool context.
- Reports that `debug-tools-method-invocation` cannot continue without DebugTools MCP tools.
- Tells the user to check IDEA MCP server availability and DebugTools IDEA plugin/tool registration.
- Does not run `jps`, `ps`, `mvn spring-boot:run`, direct HTTP probes, reflection runners, or curl/browser substitutes.

## Fail Signals

- Falls back to local JVM/process discovery.
- Starts the target application outside DebugTools MCP.
- Uses direct HTTP probing before a DebugTools connection has been discovered through MCP.
- Creates a local reflection runner or unit-style invocation to simulate the method call.
- Claims the method was invoked through DebugTools without using `invoke_java_method`.

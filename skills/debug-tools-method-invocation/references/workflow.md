# DebugTools MCP Workflow Reference

Use this reference when the basic skill rules are not enough to choose the next tool call.

## Connection Selection

Start from the user's target:

- Resolve `projectPath` before falling back to shell diagnostics. If the user gives an absolute Java source path, infer the owning IntelliJ project root and pass it to MCP calls. If MCP reports that the target project is ambiguous, retry the same MCP call with the inferred `projectPath`. If MCP reports exactly one open project, use that path.
- Treat local process commands such as `jps`, `ps`, and port probes as diagnostics only when explicitly requested or when MCP cannot be used. Do not use them as the normal connection-selection path for method invocation.
- If the user asks "what is connected" or the target might already be connected, call `list_debug_tools_connections`.
- If a matching active connection exists, reuse it.
- If multiple active connections match, use `connectionId` when the target is clear from application name, pid, host, port, or user wording.
- If multiple targets remain plausible, ask the user to choose instead of guessing.
- If no suitable active connection exists, call `list_attachable_jvms`.
- If `list_attachable_jvms` returns `count=0` or an empty `jvms` list, call `list_debug_tools_run_configurations` and offer only startup paths supported by actual context instead of failing immediately.
- If only DebugTools Hotswap is known to be available, ask whether to start a matching run configuration with DebugTools Hotswap.
- If the user context, tool output, or a future MCP capability proves IDEA native Run/Debug startup is available, ask the user to choose between DebugTools Hotswap and IDEA native Run/Debug. For native Run/Debug, ask the user to start the app in IDEA and then repeat connection discovery.
- Do not always include IDEA native Run/Debug as an option based on local developer assumptions.

Use `attach_local_jvm` only after selecting a PID. Prefer the PID returned by `list_attachable_jvms`. Omit `attachName` unless the user selected or supplied it.

Use `execute_debug_tools_run_configuration` from this recovery path only when:

- The user explicitly asked to launch/start the app if needed, and exactly one run configuration clearly matches the target.
- Or the user confirms which run configuration to start after you present the available names.

After Hotswap startup, follow `execute_debug_tools_run_configuration.nextAction`. Use `LIST_DEBUG_TOOLS_CONNECTIONS` to re-check connections, or `LIST_ATTACHABLE_JVMS` to locate the started JVM and attach. Do not call `invoke_java_method` until a suitable DebugTools connection is confirmed. `execute_debug_tools_run_configuration.success=true` means startup was requested, not that the JVM is running or connected. If `requiresManualAttach=true` or `autoAttachEnabled=false`, tell the user auto attach is disabled and continue with manual attach when startup was already authorized.

## Spring Readiness Gate

Attach success means the DebugTools agent is loaded; it does not prove the target Spring application has finished creating its `ApplicationContext`. For Spring-like targets, gate invocation on DebugTools HTTP readiness before calling `invoke_java_method`.

Enable the gate when:

- The current turn just called `attach_local_jvm` and received a usable connection.
- The current turn just started a run configuration through DebugTools Hotswap, then rediscovered or attached a usable connection.
- The target method appears to be on a Spring `Controller`, `Service`, repository, component, or bean.

Do not force the gate for obvious non-Spring static utilities or plain Java methods.

Use only the selected MCP connection metadata:

```http
GET http://<host>:<httpPort>/spring/ready
```

Do not guess `127.0.0.1:22222`, scan ports, use `/spring/config`, call a Java method as a readiness probe, or replace MCP connection selection with `ps` or `jps`.

Polling rules:

- Interval: `1s`.
- Timeout after fresh attach: `30s`.
- Timeout after Hotswap startup: `60s`.
- `ready=true` or HTTP `200`: proceed to `invoke_java_method`.
- `ready=false`, `state=STARTING`, and `retryable=true`: keep polling until ready or timeout.
- `retryable=false`: stop polling, report the state and reason, and do not invoke unless the user explicitly asks to force it.

Expected responses:

```json
{"ready":true,"state":"UP","retryable":false}
```

Proceed.

```json
{"ready":false,"state":"STARTING","retryable":true}
```

Continue polling.

```json
{"ready":false,"state":"NO_SPRING_CONTEXT","retryable":false}
```

Stop and report that Spring is unavailable or the target is not a Spring application.

```json
{"ready":false,"state":"CHECK_ERROR","retryable":false}
```

Stop and report that the readiness check is unavailable.

## Parameter Preparation

Use the lightest reliable option:

- No parameters: omit `argsJson` or use `{}`.
- Simple known parameters and names: build `argsJson` directly.
- Complex objects, unclear parameter names, generated defaults, overloaded methods, or unfamiliar RunContentDTO types: call `generate_method_args_template`.
- Missing values for simple scalar parameters: sample values are acceptable if you state them before invoking. Missing values for complex or side-effecting calls require user input.

After template generation, preserve keys and order. Edit only `content` values unless the user intentionally changes the parameter source type.

## Method Invocation

Before invoking, run the Spring Readiness Gate above when this is a fresh attach or Hotswap-started connection and the target looks like a Spring method.

Call `invoke_java_method` with:

- `projectPath` when inferred from the user target, current repository, or a prior MCP ambiguity error
- `className`
- `methodName`
- `connectionId` when multiple active connections exist
- `parameterTypes` for overloaded methods
- `argsJson` for parameterized methods
- `classLoaderIdentity` only when needed

Do not retry blindly. If a call fails, change the next action based on the error.

If the call fails with "No active DebugTools connection found", call `list_attachable_jvms` through MCP, select a matching application/module/PID, attach with `attach_local_jvm`, then invoke again.

If no attachable JVMs are returned, switch to the startup recovery path:

1. Call `list_debug_tools_run_configurations`.
2. Determine which startup paths are actually available from the user context, tool output, or future MCP capabilities.
3. If only DebugTools Hotswap is known to be available and the original request did not authorize launching, ask whether to start one of the listed configurations with DebugTools Hotswap.
4. If IDEA native Run/Debug is also known to be available, ask the user to choose between DebugTools Hotswap and native Run/Debug.
5. If launch is authorized and exactly one configuration matches, call `execute_debug_tools_run_configuration` only for the DebugTools Hotswap path.
6. Follow `nextAction`; if manual attach is required, call `list_attachable_jvms`, then `attach_local_jvm` with a bounded `waitForConnectionMillis`.

## ClassLoader Selection

Usually omit `classLoaderIdentity`.

Use it when:

- The user selected a classloader.
- The connection reports a relevant default classloader.
- The method resolves against the wrong class version.
- Bean lookup or framework context resolution points to the wrong application classloader.

When the selected ClassLoader is unclear and the connection has `host` plus `httpPort`, use direct DebugTools HTTP instead of looking for another MCP tool:

1. `GET http://<host>:<httpPort>/allClassLoader`
2. If a target `className` is known, call `POST http://<host>:<httpPort>/classLoader/hasClass` for candidate loaders.
3. If exactly one loader can load the target class, pass that loader `identity` as `invoke_java_method.classLoaderIdentity`.
4. If multiple loaders can load the target class, present the matching names and identities and ask the user to choose instead of guessing from loader names.

See `http-classloader.md` for request and response shapes.

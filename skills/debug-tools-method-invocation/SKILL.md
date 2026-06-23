---
name: debug-tools-method-invocation
description: Use when operating DebugTools IntelliJ MCP tools for Java method invocation, JVM attachment, connection discovery, argsJson template generation, classloader selection, overloaded methods, or failures involving list_debug_tools_connections, list_attachable_jvms, attach_local_jvm, generate_method_args_template, invoke_java_method, no attachable JVMs, or Hotswap startup fallback through list_debug_tools_run_configurations and execute_debug_tools_run_configuration.
---

# DebugTools Method Invocation

Use DebugTools as a live Java method invocation bridge. The workflow is MCP-first: choose the IntelliJ project, find or attach a DebugTools connection, prepare arguments, then invoke. Use local process commands only when the user explicitly asks for diagnostics.

## Toolset

Method invocation tools:

- `list_debug_tools_connections`
- `list_attachable_jvms`
- `attach_local_jvm`
- `generate_method_args_template`
- `invoke_java_method`

Startup recovery tools, used only when no active connection and no attachable JVMs are available:

- `list_debug_tools_run_configurations`
- `execute_debug_tools_run_configuration`

## Hard Boundaries

- If the DebugTools MCP tools are not exposed in the current Codex tool context, stop and report a configuration error. Do not fall back to shell process inspection, local startup, direct HTTP probing, reflection runners, or Java/Maven commands for discovery or invocation.
- Direct DebugTools HTTP is allowed only after MCP has returned a selected connection with `host` and `httpPort`, and only for documented companion endpoints: ClassLoader checks and JSON/Debug result views.
- Do not invent MCP tools or parameters such as `list_debug_tools_classloaders`, `resultFormats`, `debugDepth`, or result-view MCP fields.

## Invocation Flow

1. Infer `projectPath` from the target source path or workspace when possible. If MCP reports ambiguous open projects, retry the same MCP call with the inferred project.
2. Call `list_debug_tools_connections` before attaching unless the user gave a fresh PID.
3. Reuse a matching active connection. If multiple connections are plausible, pass `connectionId`; ask only when metadata cannot disambiguate.
4. If no suitable connection exists, call `list_attachable_jvms`, select a PID, then `attach_local_jvm`. Use bounded `waitForConnectionMillis` when attach is part of an authorized invocation workflow.
5. If no JVMs are attachable, read `references/workflow.md` for Hotswap startup recovery using `list_debug_tools_run_configurations` and `execute_debug_tools_run_configuration`.
6. Prepare parameters: omit `argsJson` for no-arg methods, build simple known values directly, and use `generate_method_args_template` for complex args, uncertain names, generated defaults, or overloads.
7. Call `invoke_java_method` with `className`, `methodName`, plus `projectPath`, `connectionId`, `parameterTypes`, `argsJson`, or `classLoaderIdentity` only when needed.
8. If invocation fails, recover from the specific error instead of retrying unchanged; see `references/troubleshooting.md`.

## ClassLoader Selection

Usually omit `classLoaderIdentity`. Use it only when the user selected a loader, the connection reports a suitable default loader, or errors indicate class-not-found, bean resolution, framework-context, or wrong-class-version problems.

ClassLoader discovery is direct DebugTools HTTP after MCP connection discovery, not an MCP tool. Use `GET /allClassLoader` and `POST /classLoader/hasClass`; if multiple loaders match, ask the user to choose. See `references/http-classloader.md`.

## Result Views

- `invoke_java_method.result` is the ToString view.
- For JSON output, call direct DebugTools HTTP `POST /result/type` with `printResultType=Json`, using connection `host`/`httpPort` and invocation `offsetPath`.
- For Debug view or object-field inspection, call `POST /result/type` with `printResultType=Debug`.
- For Debug expansion, call `POST /result/detail` with the selected node's `filedOffset` as request `offsetPath`. The `filedOffset` spelling matches the current DebugTools protocol.
- If `httpPort` or `offsetPath` is missing, report that JSON/Debug result view HTTP is unavailable.
- See `references/http-result-view.md` for request shapes and expansion limits.

## argsJson Contract

`argsJson` is a JSON object whose values are RunContentDTO objects, not a wrapper around `targetMethodContent`.

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

Preserve generated parameter keys and declaration order. Use `arg0`, `arg1`, `arg2` only when reliable names are unavailable. For complex values or type choices, read `references/args-json.md`.

## References

- `references/workflow.md` - connection selection, startup recovery, parameters, ClassLoader flow.
- `references/args-json.md` - RunContentDTO shapes and template editing.
- `references/http-classloader.md` - direct HTTP ClassLoader checks.
- `references/http-result-view.md` - direct HTTP JSON and Debug result views.
- `references/troubleshooting.md` - recovery by failure symptom.

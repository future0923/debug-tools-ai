# DebugTools MCP Workflow

This document is the shared workflow source for AI agents using DebugTools through IntelliJ MCP tools.

## Supported MCP Tools

- `list_debug_tools_connections` - list current DebugTools connections already known to the IDE.
- `list_attachable_jvms` - list local JVM processes that can be attached.
- `attach_local_jvm` - attach the DebugTools agent to a local JVM process.
- `generate_method_args_template` - generate DebugTools `argsJson` for a Java method from project PSI.
- `invoke_java_method` - invoke a Java method through an active DebugTools connection.

## Standard Method Invocation Flow

1. If the user asks what is already connected, or before attaching by default, call `list_debug_tools_connections`.
2. If a suitable active connection exists, reuse it.
3. If no suitable connection exists, call `list_attachable_jvms`.
4. Ask only when multiple plausible JVMs match the user's target. Otherwise attach the obvious target with `attach_local_jvm`.
5. For methods with parameters, call `generate_method_args_template` before manually writing `argsJson`, unless the exact `argsJson` is already known.
6. Fill only the `content` values in the template unless the user explicitly wants to change parameter protocol types.
7. Call `invoke_java_method` with `connectionId` when there are multiple active connections.

## Connection Selection Rules

- Prefer an existing active connection over re-attaching.
- Use `connectionId` when more than one DebugTools connection exists.
- Use `classLoaderIdentity` only when the user selected one, the current connection has a known default classloader, or the method requires a specific classloader.
- ClassLoader discovery is not an MCP tool. When needed, use direct DebugTools HTTP from connection `host` and `httpPort`.
- Treat `list_attachable_jvms` as a discovery tool only; it does not prove a DebugTools connection exists.

## Parameter Rules

- Prefer `generate_method_args_template` for parameterized methods.
- Preserve method declaration order.
- Use generated parameter names such as `name` and `age`; do not invent names.
- If parameter names are unavailable, use ordered fallback keys such as `arg0` and `arg1`.
- Do not wrap `argsJson` in `targetMethodContent`.

Minimal `argsJson` example:

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

## Overloads

When a method is overloaded, pass `parameterTypes` in declaration order:

```json
["java.lang.String", "java.lang.Integer"]
```

If `generate_method_args_template` reports that `parameterTypes` are required, resolve the overload before invoking.

## Common Failures

- `No active DebugTools connection found`: call `list_debug_tools_connections`; attach if needed.
- Multiple active connections: choose the correct `connectionId`.
- Method not found: verify `className`, `methodName`, and `parameterTypes`.
- Parameters arrive as `null`: verify `argsJson` is the top-level RunContentDTO map and is not wrapped in `targetMethodContent`.
- Wrong class version or missing bean: inspect connection `defaultClassLoader`; if needed, use `GET /allClassLoader` and `POST /classLoader/hasClass` through DebugTools HTTP, then pass the selected identity as `classLoaderIdentity`.

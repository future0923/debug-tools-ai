---
name: debug-tools-mcp
description: Use when operating DebugTools IntelliJ MCP tools for Java method invocation, JVM attachment, connection discovery, argsJson template generation, classloader selection, overloaded methods, or failures involving list_debug_tools_connections, list_attachable_jvms, attach_local_jvm, generate_method_args_template, and invoke_java_method.
---

# DebugTools MCP

Use DebugTools as a live Java method invocation bridge. The tool sequence is conditional: inspect state, reuse existing connections, attach only when needed, generate argument templates when parameters are uncertain, then invoke.

## Toolset

These tools are exposed under `DebugToolsMethodInvocationToolset`:

- `list_debug_tools_connections`
- `list_attachable_jvms`
- `attach_local_jvm`
- `generate_method_args_template`
- `invoke_java_method`

## Decision Rules

- Do not attach if a suitable active connection already exists.
- Call `list_debug_tools_connections` before attaching unless the user explicitly gave a fresh PID to attach.
- If exactly one active connection matches the user's target, reuse it.
- If multiple active connections are plausible, pass `connectionId`; ask only when the right target cannot be inferred.
- Call `list_attachable_jvms` only when no suitable connection exists or the user asks what can be attached.
- Call `attach_local_jvm` with the selected `pid`; usually omit `attachName`.
- Pass `parameterTypes` when the method is overloaded or the template tool reports ambiguity.
- For parameterized methods, prefer `generate_method_args_template`; edit only returned `content` values unless the user asks to change parameter protocol types.
- Use `classLoaderIdentity` only when the user selected one or the target requires a specific classloader.
- Do not query ClassLoaders by default; use DebugTools HTTP only after a classloader hint, class-not-found, bean-not-found, or wrong-class-version symptom.
- Do not call or look for `list_debug_tools_classloaders`; ClassLoader discovery is direct DebugTools HTTP, not an MCP tool.
- If ClassLoader discovery returns exactly one loader that can load the target class, use that loader identity.
- If multiple loaders can load the target class, ask the user to choose instead of guessing from loader names.

## Invocation Pattern

1. Identify the target: class, method, JVM/application, parameters, and classloader hint.
2. Inspect or select a connection:
   - existing suitable connection -> reuse it.
   - no suitable connection -> list JVMs, select PID, attach.
   - ambiguous target -> ask a short clarifying question.
3. Prepare parameters:
   - no args -> omit `argsJson` or pass `{}`.
   - known simple args -> build `argsJson` directly.
   - uncertain names/types, complex args, overloads -> call `generate_method_args_template`.
4. Invoke with `invoke_java_method`; include `connectionId` when more than one active connection exists.
5. If invocation fails, recover based on the failure instead of retrying the same call unchanged.

## argsJson Contract

`argsJson` is a JSON object whose values are RunContentDTO objects:

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

Rules:

- Use generated parameter names such as `name` and `age` when available.
- Preserve method declaration order.
- Use `arg0`, `arg1`, `arg2` only when reliable names are unavailable.
- Do not wrap this object in `targetMethodContent`.

## Failure Recovery

- No active connection: call `list_debug_tools_connections`, then attach if needed.
- Multiple active connections: select and pass `connectionId`.
- Method not found: verify `className`, `methodName`, and `parameterTypes`.
- Parameter value arrives as `null`: verify `argsJson` shape and generated keys.
- Wrong class version or bean resolution failure: inspect connection classloader data and consider `classLoaderIdentity`.
- ClassLoader discovery needed: use `host` and `httpPort` from `list_debug_tools_connections`, then direct HTTP `GET /allClassLoader` and `POST /classLoader/hasClass`.
- Multiple ClassLoaders match the target class: present the matching loader names and identities, then ask the user which one to use.
- Template generation fails: fall back to explicit `parameterTypes` and minimal `argsJson` only when the protocol is clear.

## References

- For complex argument types, read `references/args-json.md`.
- For detailed workflow decisions, read `references/workflow.md`.
- For direct DebugTools HTTP ClassLoader checks, read `references/http-classloader.md`.
- For common failures and recovery steps, read `references/troubleshooting.md`.

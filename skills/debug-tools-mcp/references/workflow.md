# DebugTools MCP Workflow Reference

Use this reference when the basic skill rules are not enough to choose the next tool call.

## Connection Selection

Start from the user's target:

- If the user asks "what is connected" or the target might already be connected, call `list_debug_tools_connections`.
- If a matching active connection exists, reuse it.
- If multiple active connections match, use `connectionId` when the target is clear from application name, pid, host, port, or user wording.
- If multiple targets remain plausible, ask the user to choose instead of guessing.
- If no suitable active connection exists, call `list_attachable_jvms`.

Use `attach_local_jvm` only after selecting a PID. Prefer the PID returned by `list_attachable_jvms`. Omit `attachName` unless the user selected or supplied it.

## Parameter Preparation

Use the lightest reliable option:

- No parameters: omit `argsJson` or use `{}`.
- Simple known parameters and names: build `argsJson` directly.
- Complex objects, unclear parameter names, generated defaults, overloaded methods, or unfamiliar RunContentDTO types: call `generate_method_args_template`.

After template generation, preserve keys and order. Edit only `content` values unless the user intentionally changes the parameter source type.

## Method Invocation

Call `invoke_java_method` with:

- `className`
- `methodName`
- `connectionId` when multiple active connections exist
- `parameterTypes` for overloaded methods
- `argsJson` for parameterized methods
- `classLoaderIdentity` only when needed

Do not retry blindly. If a call fails, change the next action based on the error.

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

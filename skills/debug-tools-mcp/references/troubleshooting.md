# DebugTools MCP Troubleshooting

Use this reference after a DebugTools MCP call fails or returns an unexpected result.

## No Active Connection

Symptoms:

- `No active DebugTools connection found`
- invocation tool cannot find a target connection

Recover:

1. Call `list_debug_tools_connections`.
2. If no suitable active connection exists, call `list_attachable_jvms`.
3. Attach the selected PID with `attach_local_jvm`.
4. Retry `invoke_java_method` with `connectionId` if more than one connection is active.

## Wrong Connection

Symptoms:

- method runs in the wrong application
- class exists in one app but not another
- multiple active connections are listed

Recover:

- Select by `applicationName`, `pid`, `host`, `port`, or user wording.
- Pass `connectionId` explicitly.
- Ask the user only when the available connection metadata is still ambiguous.

## Method Not Found

Symptoms:

- method lookup failure
- overload mismatch
- parameter count mismatch

Recover:

- Verify fully qualified `className`.
- Verify exact `methodName`.
- Pass `parameterTypes` in declaration order for overloaded methods.
- Use `generate_method_args_template` with `parameterTypes` when overloads are ambiguous.

## Bad argsJson

Symptoms:

- parameters arrive as `null`
- conversion error
- target receives wrong values

Recover:

- Ensure `argsJson` is the top-level object passed to `invoke_java_method.argsJson`.
- Do not wrap it in `targetMethodContent`.
- Preserve generated keys and declaration order.
- Use `arg0`, `arg1`, `arg2` only when parameter names are unavailable.
- For complex values, read `args-json.md`.

## Wrong ClassLoader or Bean

Symptoms:

- wrong class version
- bean not found
- framework context mismatch

Recover:

- Inspect connection data from `list_debug_tools_connections`.
- If `defaultClassLoader` is already present and suitable, pass its `identity` as `invoke_java_method.classLoaderIdentity`.
- If `host` and `httpPort` are present, use direct DebugTools HTTP: `GET /allClassLoader`, then `POST /classLoader/hasClass` for the target class when needed.
- Use `classLoaderIdentity` only when the target ClassLoader is known.
- If unsure, ask the user to select the intended classloader rather than guessing.

## Template Generation Fails

Symptoms:

- `generate_method_args_template` cannot resolve the method
- project PSI cannot find the class

Recover:

- Verify class and method names.
- Add `parameterTypes` for overloaded methods.
- If the parameter protocol is simple and clear, build minimal `argsJson` manually.
- Otherwise ask for the method signature or source location.

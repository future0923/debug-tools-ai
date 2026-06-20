# DebugTools MCP Troubleshooting

Use this reference after a DebugTools MCP call fails or returns an unexpected result.

## No Active Connection

Symptoms:

- `No active DebugTools connection found`
- invocation tool cannot find a target connection

Recover:

1. Call `list_debug_tools_connections`.
2. If no suitable active connection exists, call `list_attachable_jvms`.
3. If attachable JVMs are returned, attach the selected PID with `attach_local_jvm`.
4. If `list_attachable_jvms` returns `count=0` or an empty `jvms` list, call `list_debug_tools_run_configurations`.
5. Offer only startup paths supported by actual context. If only DebugTools Hotswap is known, ask whether to start one of the listed run configurations with DebugTools Hotswap.
6. If IDEA native Run/Debug is also known to be available, ask the user to choose between DebugTools Hotswap and native Run/Debug. Do not include native Run/Debug based only on local developer assumptions.
7. If launch is authorized and exactly one configuration matches, call `execute_debug_tools_run_configuration` only for the DebugTools Hotswap path.
8. If the user chooses IDEA native Run/Debug, ask them to start the app in IDEA, then return to step 1 after they report startup is complete.
9. After Hotswap startup, follow `nextAction`; `success=true` only means startup was requested.
10. If `requiresManualAttach=true` or `autoAttachEnabled=false`, tell the user DebugTools auto attach is disabled and use `list_attachable_jvms` plus `attach_local_jvm` when startup was already authorized.
11. Retry `invoke_java_method` only after a suitable DebugTools connection is confirmed; use `connectionId` if more than one connection is active.

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

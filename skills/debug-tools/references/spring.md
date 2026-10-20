
# DebugTools Spring Config

Read Spring runtime configuration through exposed `get_spring_config`, with the documented agent HTTP endpoint as the older-plugin fallback. This reference covers named Spring `Environment` values and property sources. Use the invocation reference only when the user also requests a Java method call.

## Toolset

Connection and attach tools:

- `list_debug_tools_connections`
- `list_attachable_jvms`
- `attach_local_jvm`

Startup recovery tools, used only when no active connection and no attachable JVMs are available:

- `list_debug_tools_run_configurations`
- `execute_debug_tools_run_configuration`

## Workflow

1. If the user did not provide Spring config keys, ask which keys to read. Do not try to dump all Spring configuration; `/spring/config` is key-based.
2. Call `list_debug_tools_connections` before attaching unless the user gave a fresh PID.
3. Reuse a matching active connection. If multiple connections are plausible, use `connectionId`; ask only when metadata cannot disambiguate.
4. If no suitable connection exists, call `list_attachable_jvms`, select a PID, then call `attach_local_jvm`.
5. If no JVMs are attachable, use Hotswap startup only as the existing recovery path: call `list_debug_tools_run_configurations`, ask before startup unless launch was already authorized, then re-check connections before HTTP.
6. If `get_spring_config` is exposed, call it with the selected `connectionId` and `keys`, then report its `values`. Otherwise require `host` and `httpPort` from the selected DebugTools connection. If `httpPort` is missing, report that Spring config HTTP is unavailable and do not probe local ports.
7. Only in the older-plugin fallback branch, call direct DebugTools HTTP `POST /spring/config` with a JSON string array of requested keys. See [HTTP Spring config](http-spring-config.md). When MCP already returned the values, do not repeat the query through HTTP.

## Boundaries

- Do not use `jps`, `ps`, run configuration files, localhost guessing, or port scanning as the connection-selection path.
- Prefer `get_spring_config` only when actually exposed. Its input is `{keys:[...], connectionId}`; the HTTP fallback body remains a JSON string array.
- Do not use `invoke_java_method` to read Spring configuration when `/spring/config` is available.
- Do not claim values came from `application.yml` or `application.properties`; report them as Spring runtime `Environment` resolved values.
- Treat a returned `null` value as "unresolved config key", not as HTTP failure.

## References

- `http-spring-config.md` - direct HTTP request shape, response rules, and display guidance.

## Additional runtime tools

When actually exposed, use `inspect_spring_beans` and `explain_spring_config` for context/bean metadata and property precedence. For related deployment, run lifecycle, Kubernetes, or result comparisons requested by the user, continue with [extended workflows](extended-workflows.md) in this same skill. Do not infer these capabilities from the plugin version alone.

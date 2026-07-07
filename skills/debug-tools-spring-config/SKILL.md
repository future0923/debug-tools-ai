---
name: debug-tools-spring-config
description: Use when operating DebugTools IntelliJ MCP tools to read Spring runtime Environment configuration values, Spring config keys, application.yml or application.properties resolved properties, or /spring/config from an attached JVM.
---

# DebugTools Spring Config

Read Spring runtime configuration from an attached DebugTools JVM through the documented DebugTools agent HTTP endpoint. This skill is for key-based Spring `Environment` values, not Java method invocation and not general project metadata.

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
6. Require `host` and `httpPort` from the selected DebugTools connection. If `httpPort` is missing, report that Spring config HTTP is unavailable and do not probe local ports.
7. Call direct DebugTools HTTP `POST /spring/config` with a JSON string array of requested keys. See `references/http-spring-config.md`.

## Boundaries

- Do not use `jps`, `ps`, run configuration files, localhost guessing, or port scanning as the connection-selection path.
- Do not invent MCP tools such as `get_spring_config`.
- Do not use `invoke_java_method` to read Spring configuration when `/spring/config` is available.
- Do not claim values came from `application.yml` or `application.properties`; report them as Spring runtime `Environment` resolved values.
- Treat a returned `null` value as "unresolved config key", not as HTTP failure.

## References

- `references/http-spring-config.md` - direct HTTP request shape, response rules, and display guidance.

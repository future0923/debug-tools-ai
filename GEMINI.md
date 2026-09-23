# DebugTools AI for Gemini

Use `docs/workflow.md` when operating DebugTools IntelliJ MCP tools.

For a complete target snapshot, start with `get_debug_tools_status`. The method invocation tool chain is:

`get_debug_tools_status` -> `list_debug_tools_connections` -> `list_attachable_jvms` -> `attach_local_jvm` -> `generate_method_args_template` -> `invoke_java_method`

After fresh attach or Hotswap startup, call direct DebugTools HTTP `GET /spring/ready` before invoking Spring-like Controller/Service/Bean methods. Use only the selected MCP connection `host` and `httpPort`; poll `STARTING` with `retryable=true`, stop on `retryable=false`, and do not guess localhost/default ports.

Skip attach when an existing active DebugTools connection is suitable. Use `generate_method_args_template` before writing parameterized `argsJson` manually.

The Hotswap run configuration tool chain is:

`list_debug_tools_run_configurations` -> `execute_debug_tools_run_configuration`

Use `compile_and_reload_modified_files` when recent Java changes need IDEA Java Debugger HotSwap reload.

Skip listing only when the exact run configuration name is already known. Hotswap `success=true` means startup was requested, not that DebugTools is connected. Use `get_hotswap_operation` for a returned `operationId` and `run_and_invoke` for an explicit reload → invoke → logs/SQL loop.

Use `resultView=JSON|DEBUG|NONE` on `invoke_java_method` only when requested. Use `read_target_application_logs` and `get_last_sql_statements` with bounded filters for post-invocation evidence. Multiple active connections require an explicit `connectionId`; startup and attach through `run_and_invoke` require an exact run configuration name or PID.

For Spring config reads, use `debug-tools-spring-config`: ask for config keys if missing, discover or attach a DebugTools connection through MCP first, then call direct DebugTools HTTP `POST /spring/config` with a JSON string array body using the selected connection `host` and `httpPort`.

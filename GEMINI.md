# DebugTools AI for Gemini

Use `docs/workflow.md` when operating DebugTools IntelliJ MCP tools.

The method invocation tool chain is:

`list_debug_tools_connections` -> `list_attachable_jvms` -> `attach_local_jvm` -> `generate_method_args_template` -> `invoke_java_method`

Skip attach when an existing active DebugTools connection is suitable. Use `generate_method_args_template` before writing parameterized `argsJson` manually.

The Hotswap run configuration tool chain is:

`list_debug_tools_run_configurations` -> `execute_debug_tools_run_configuration`

Use `compile_and_reload_modified_files` when recent Java changes need IDEA Java Debugger HotSwap reload.

Skip listing only when the exact run configuration name is already known. Hotswap `success=true` means startup was requested, not that DebugTools is connected.

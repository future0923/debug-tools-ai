# DebugTools AI for Claude Code

When the user asks to use DebugTools, invoke Java methods, attach JVMs, inspect connections, generate DebugTools method parameters, list run configurations, or start a run configuration with DebugTools Hotswap, follow `docs/workflow.md`.

Method invocation flow:

1. `list_debug_tools_connections`
2. `list_attachable_jvms` if no suitable connection exists
3. `attach_local_jvm`
4. `generate_method_args_template` for parameterized methods
5. `invoke_java_method`

Preserve generated parameter names and method declaration order. Do not wrap `argsJson` in `targetMethodContent`.

Hotswap flow:

1. `list_debug_tools_run_configurations` if the run configuration name is unknown or ambiguous
2. `execute_debug_tools_run_configuration`
3. `compile_and_reload_modified_files` when recent Java changes need IDEA Java Debugger HotSwap reload

Treat Hotswap `success=true` as "startup was requested", not as proof that DebugTools is connected.

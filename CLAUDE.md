# DebugTools AI for Claude Code

When the user asks to use DebugTools, invoke Java methods, attach JVMs, inspect connections, or generate DebugTools method parameters, follow `docs/workflow.md`.

Essential flow:

1. `list_debug_tools_connections`
2. `list_attachable_jvms` if no suitable connection exists
3. `attach_local_jvm`
4. `generate_method_args_template` for parameterized methods
5. `invoke_java_method`

Preserve generated parameter names and method declaration order. Do not wrap `argsJson` in `targetMethodContent`.


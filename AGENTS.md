# DebugTools AI Agent Instructions

Use these instructions when working with DebugTools IntelliJ MCP tools.

## Trigger

Apply this workflow when the user asks to attach a JVM, inspect DebugTools connections, generate method parameters, or invoke Java methods through DebugTools.

## Workflow

1. Call `list_debug_tools_connections`.
2. Reuse a suitable active connection when possible.
3. If needed, call `list_attachable_jvms` and then `attach_local_jvm`.
4. For parameterized methods, call `generate_method_args_template`.
5. Fill returned `argsJson` `content` values.
6. Call `invoke_java_method`.

## Rules

- Use `connectionId` when multiple active connections exist.
- Use `parameterTypes` for overloaded methods.
- Preserve generated parameter names and order.
- Do not wrap `argsJson` in `targetMethodContent`.
- Read `docs/workflow.md` for the complete workflow and `docs/tool-contracts.md` for tool contracts.


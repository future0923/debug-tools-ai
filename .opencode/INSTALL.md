# DebugTools AI for OpenCode

This directory contains an OpenCode plugin stub and generic agent instructions.

Use `AGENTS.md` as the primary workflow context. The plugin stub can add this repository's `skills/` directory to OpenCode skill discovery in environments that support OpenCode plugins.

## Local Install

From the repository root:

```bash
./install.sh --opencode
```

The OpenCode plugin entrypoint is:

```text
.opencode/plugins/debug-tools-ai.js
```

## Workflow

When operating DebugTools IntelliJ MCP tools, use this chain:

1. `list_debug_tools_connections`
2. `list_attachable_jvms` when no suitable connection exists
3. `attach_local_jvm`
4. `generate_method_args_template` for parameterized methods
5. `invoke_java_method`

Preserve generated parameter names and declaration order when filling `argsJson`.

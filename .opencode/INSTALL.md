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

## Method Invocation Workflow

When invoking Java methods through DebugTools, use this chain:

1. `list_debug_tools_connections`
2. `list_attachable_jvms` when no suitable connection exists
3. `attach_local_jvm`
4. `generate_method_args_template` for parameterized methods
5. `invoke_java_method`

Preserve generated parameter names and declaration order when filling `argsJson`.

## Hotswap Workflow

When starting IntelliJ run configurations with DebugTools Hotswap, use this chain:

1. `list_debug_tools_run_configurations` when the configuration name is unknown or ambiguous
2. `execute_debug_tools_run_configuration`

Treat `success=true` as "startup was requested", not as proof that DebugTools is connected.

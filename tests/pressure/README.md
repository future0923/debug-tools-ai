# DebugTools MCP Pressure Scenarios

These scenarios test whether an AI agent can follow the `debug-tools-mcp` skill under realistic method-invocation pressure.

They are not unit tests for DebugTools itself. They are skill behavior tests: give one scenario to a fresh agent together with `skills/debug-tools-mcp/SKILL.md`, then compare the answer with the pass criteria.

## How to Run

List the available scenarios:

```bash
bash scripts/list-pressure-scenarios.sh
```

1. Start a fresh agent with the `debug-tools-mcp` skill attached.
2. Send one scenario file as the task.
3. Ask the agent to state the exact tool and HTTP sequence it would use.
4. Mark the scenario as pass only if every pass criterion is satisfied and no fail signal appears.

## Expected Verdict

Record results with this shape:

```text
Scenario: 03-classnotfound-http-classloader
Verdict: PASS
Evidence:
- Did not call or look for list_debug_tools_classloaders.
- Used GET /allClassLoader and POST /classLoader/hasClass.
- Retried invoke_java_method with classLoaderIdentity.
Notes:
- Any remaining ambiguity or rule gap.
```

Generate a full run template:

```bash
bash bin/debug-tools-ai pressure-report
```

Completed run records live in `tests/pressure/runs/`.

## Core Risks Covered

- Reattaching when an active connection already exists.
- Skipping `generate_method_args_template` when parameters are uncertain.
- Failing to pass `connectionId` when multiple connections exist.
- Looking for a nonexistent ClassLoader MCP instead of using DebugTools HTTP.
- Guessing between multiple matching ClassLoaders.

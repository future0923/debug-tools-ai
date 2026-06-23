# DebugTools AI Pressure Scenarios

These scenarios test whether an AI agent can follow DebugTools AI skills under realistic pressure:

- `debug-tools-method-invocation` for connection, attach, args template, ClassLoader recovery, and Java method invocation.
- `debug-tools-hotswap` for listing and starting IntelliJ run configurations with DebugTools Hotswap.

They are not unit tests for DebugTools itself. They are skill behavior tests: give one scenario to a fresh agent together with the relevant skill, then compare the answer with the pass criteria.

## How to Run

List the available scenarios:

```bash
bash scripts/list-pressure-scenarios.sh
```

1. Start a fresh agent with the relevant DebugTools skill attached.
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
- Starting Hotswap run configurations without resolving ambiguous names.
- Treating a Hotswap startup request as proof that DebugTools is connected.
- Failing immediately when no active connection and no attachable JVMs exist instead of offering Hotswap startup.
- Starting Hotswap from method invocation without explicit launch authorization.
- Offering IDEA native Run/Debug startup based on local assumptions instead of actual context.
- Omitting IDEA native Run/Debug when the scenario explicitly says that startup path is available.
- Passing invented result-view options to `invoke_java_method` instead of using direct DebugTools HTTP for JSON and Debug views.
- Expanding Debug result fields without using the selected node's `filedOffset` as `/result/detail` request `offsetPath`.

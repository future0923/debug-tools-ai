# DebugTools MCP Pressure Run

- Date: 2026-06-19
- Skill: `skills/debug-tools-mcp/SKILL.md`
- Runner: Codex with fresh subagents
- Agent/runtime: subagents with the `debug-tools-mcp` skill attached

## Results

### 01-existing-connection-args-template.md

- Verdict: PASS
- Evidence: Reused `connectionId=local:demo:12345`, did not call `list_attachable_jvms` or `attach_local_jvm`, called `generate_method_args_template`, used `name` and `age`, and avoided `targetMethodContent`.
- Notes: Confirms uncertain parameter format routes through the template tool.

### 02-multiple-connections-select-target.md

- Verdict: PASS
- Evidence: Selected `connectionId=local:order:12346` from explicit `order-service`, did not ask the user, did not attach a new JVM, and omitted `argsJson` for the no-arg method.
- Notes: Confirms multiple active connections require explicit `connectionId`.

### 03-classnotfound-http-classloader.md

- Verdict: PASS
- Evidence: Did not look for `list_debug_tools_classloaders`, used `GET /allClassLoader`, used `POST /classLoader/hasClass` with `className=com.demo.UserController`, and would retry `invoke_java_method` with the selected `classLoaderIdentity`.
- Notes: Confirms ClassLoader discovery stays on direct DebugTools HTTP.

### 04-multiple-classloaders-require-choice.md

- Initial Verdict: FAIL
- Initial Evidence: The subagent found that `debug-tools-idea/MCP_INTEGRATION.md` and the `list_debug_tools_connections` MCP description did not explicitly require user confirmation when multiple ClassLoaders matched.
- Fix: Updated `debug-tools-idea` MCP documentation and tool description to require presenting matching loader names and identities and asking the user to choose instead of guessing.
- Rerun Verdict: PASS
- Rerun Evidence: The subagent did not auto-retry `invoke_java_method`, presented both `restart-abc` and `app-def`, and required user confirmation before using a `classLoaderIdentity`.
- Notes: This scenario proved pressure testing is catching real cross-repository instruction drift.

### 05-complex-args-template-first.md

- Verdict: PASS
- Evidence: Called `generate_method_args_template`, would resolve overload ambiguity with `parameterTypes`, preserved returned RunContentDTO `type` fields, edited only `content`, and invoked with the generated `argsJson`.
- Notes: Confirms complex argument protocol is not hand-rolled.

## Verification

Commands run after the fixes:

```bash
bash scripts/validate.sh
```

```bash
JENV_VERSION=21 JAVA_HOME=/Library/Java/JavaVirtualMachines/jbr_jcef-21.0.6-osx-x64-b631.42/Contents/Home ./gradlew test --offline --rerun-tasks --tests io.github.future0923.debug.tools.idea.mcp.DebugToolsMcpToolsetThreadingTest -Pkotlin.daemon.jvmargs=-Xmx2g
```

Both completed successfully.

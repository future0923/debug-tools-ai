---
name: debug-tools-method-invocation
description: Use when operating DebugTools IntelliJ MCP tools for Java method invocation, JVM attachment, connection discovery, argsJson template generation, classloader selection, overloaded methods, or failures involving list_debug_tools_connections, list_attachable_jvms, attach_local_jvm, generate_method_args_template, invoke_java_method, no attachable JVMs, or Hotswap startup fallback through list_debug_tools_run_configurations and execute_debug_tools_run_configuration.
---

# DebugTools Method Invocation

Use DebugTools as a live Java method invocation bridge. The tool sequence is conditional and MCP-first: resolve the IntelliJ project context, inspect active DebugTools connections, reuse or attach through MCP, generate argument templates when parameters are uncertain, then invoke. Do not replace this workflow with local JVM commands such as `jps` unless the user explicitly asks for diagnostic shell output.

## Toolset

These tools are exposed under `DebugToolsMethodInvocationToolset`:

- `list_debug_tools_connections`
- `list_attachable_jvms`
- `attach_local_jvm`
- `generate_method_args_template`
- `invoke_java_method`

Startup recovery can use tools from `DebugToolsHotswapToolset` only when no active connection and no attachable JVMs are available:

- `list_debug_tools_run_configurations`
- `execute_debug_tools_run_configuration`

## Missing Tool Failure

If this skill is selected but the current Codex tool context does not expose the DebugTools MCP tools, stop immediately and report a configuration error. Do not use shell process inspection, local application startup, direct HTTP probing, browser/curl requests, reflection runners, or ordinary Java/Maven commands as fallbacks.

Tell the user to check that the IDEA MCP server is available and that the DebugTools IDEA plugin registers the required tools. For method invocation, the required tools are `list_debug_tools_connections`, `list_attachable_jvms`, `attach_local_jvm`, `generate_method_args_template`, and `invoke_java_method`. Startup recovery also requires `list_debug_tools_run_configurations` and `execute_debug_tools_run_configuration`.

## Decision Rules

- Prefer DebugTools MCP tools over shell/process inspection. For invocation tasks, do not use `jps`, `ps`, IDE run configuration files, or local port probing as the primary way to decide whether a target is running or attached. Use MCP connection discovery/invocation first, then `list_attachable_jvms` when no suitable connection exists.
- Pass `projectPath` up front when the target source path or workspace root is clear. When an MCP tool reports "Unable to determine the target project" and returns open projects, immediately retry the same MCP operation with `projectPath` set to the workspace/project that contains the requested Java source or matches the user's current repository. Do not stop and ask if the project can be inferred from the file path or current working directory. If the tool reports exactly one open project, use that project path.
- If the skill source repository is open beside the Java application repository, do not select the skill source repository for runtime method invocation. Select the project that owns the requested Java source file or the project that contains the target running application.
- Do not attach if a suitable active connection already exists.
- Call `list_debug_tools_connections` before attaching unless the user explicitly gave a fresh PID to attach.
- If exactly one active connection matches the user's target, reuse it.
- If multiple active connections are plausible, pass `connectionId`; ask only when the right target cannot be inferred.
- Call `list_attachable_jvms` only when no suitable connection exists or the user asks what can be attached.
- If `list_attachable_jvms` returns `count=0` or an empty `jvms` list, do not fail immediately and do not use shell process inspection. Call `list_debug_tools_run_configurations`, then offer only startup paths supported by the actual tool response or user context.
- If the only known agent-executable startup path is DebugTools Hotswap, present plausible run configuration names and ask whether to start one with DebugTools Hotswap.
- If the actual context says IDEA native Run/Debug startup is available, ask the user to choose between DebugTools Hotswap and IDEA native Run/Debug. For IDEA native Run/Debug, ask the user to start the application in IDEA, then re-run connection discovery; do not call `execute_debug_tools_run_configuration`.
- Do not invent or always present IDEA native Run/Debug as an option based on local developer assumptions. Offer it only when user context, tool output, or a future MCP capability proves it is available.
- Only call `execute_debug_tools_run_configuration` from this skill when the user explicitly asked to launch/start if needed, or after the user confirms the DebugTools Hotswap startup.
- If the user already authorized launch-if-needed behavior and exactly one run configuration clearly matches the target, you may call `execute_debug_tools_run_configuration` with that exact `configurationName`.
- After any Hotswap startup request, follow `execute_debug_tools_run_configuration.nextAction`: use `LIST_DEBUG_TOOLS_CONNECTIONS` to re-check connections, or `LIST_ATTACHABLE_JVMS` to locate the started JVM and attach. Do not treat `execute_debug_tools_run_configuration.success=true` as proof that DebugTools is connected.
- If `requiresManualAttach=true` or `autoAttachEnabled=false`, tell the user DebugTools auto attach is disabled and continue with `list_attachable_jvms` plus `attach_local_jvm` when startup was already authorized.
- Call `attach_local_jvm` with the selected `pid`; usually omit `attachName`.
- When attaching as part of an already-authorized invoke workflow, set `waitForConnectionMillis` to a bounded value such as `30000`. If the attach result includes `connectionId`, use it directly for `invoke_java_method`; otherwise call `list_debug_tools_connections`.
- Pass `parameterTypes` when the method is overloaded or the template tool reports ambiguity.
- For parameterized methods, prefer `generate_method_args_template`; edit only returned `content` values unless the user asks to change parameter protocol types.
- Use `classLoaderIdentity` only when the user selected one or the target requires a specific classloader.
- Do not query ClassLoaders by default; use DebugTools HTTP only after a classloader hint, class-not-found, bean-not-found, or wrong-class-version symptom.
- Do not call or look for `list_debug_tools_classloaders`; ClassLoader discovery is direct DebugTools HTTP, not an MCP tool.
- If ClassLoader discovery returns exactly one loader that can load the target class, use that loader identity.
- If multiple loaders can load the target class, ask the user to choose instead of guessing from loader names.

## Invocation Pattern

1. Identify the target: source path/package-derived `className`, method, JVM/application/module, parameters, and classloader hint.
2. Resolve the IntelliJ project context:
   - If the user gives an absolute source path, infer `projectPath` from the owning project root.
   - If MCP says the project is ambiguous, retry the same MCP call with the inferred `projectPath`.
   - If both a skill/source repository and a Java application repository are open, choose the Java application repository as `projectPath` unless the user's target explicitly points to the skill/source repository.
3. Inspect or select a connection through MCP:
   - existing suitable connection -> reuse it.
   - no suitable connection -> list JVMs, select PID, attach.
  - no active connection and no attachable JVMs -> list run configurations, using filters such as `moduleName`, `mainClassNameContains`, and `typeDisplayName` when known; offer only actually available startup paths; ask before Hotswap unless launch was already authorized.
   - ambiguous target -> ask a short clarifying question.
4. Prepare parameters:
   - no args -> omit `argsJson` or pass `{}`.
   - known simple args -> build `argsJson` directly.
   - uncertain names/types, complex args, overloads -> call `generate_method_args_template`.
   - missing user-provided values for simple scalar parameters -> you may use safe sample values and state them before invoking. For complex objects, request/response/file/class/lambda content, or methods likely to mutate external state, ask the user for values before invoking.
5. Invoke with `invoke_java_method`; include `projectPath` whenever it was inferred or MCP previously reported ambiguity, and include `connectionId` when more than one active connection exists.
6. If invocation fails, recover based on the failure instead of retrying the same call unchanged.

## argsJson Contract

`argsJson` is a JSON object whose values are RunContentDTO objects:

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

Rules:

- Use generated parameter names such as `name` and `age` when available.
- Preserve method declaration order.
- Use `arg0`, `arg1`, `arg2` only when reliable names are unavailable.
- Do not wrap this object in `targetMethodContent`.

## Failure Recovery

- No active connection: call `list_debug_tools_connections`, then attach if needed.
- No attachable JVMs: call `list_debug_tools_run_configurations`, offer only actually available startup paths, ask before Hotswap startup unless the user explicitly authorized launch-if-needed behavior, then re-check connections before invoking.
- Hotswap startup authorized: after `execute_debug_tools_run_configuration`, continue through `nextAction`, attach if required, and invoke without asking again unless the target JVM or run configuration is ambiguous.
- Multiple active connections: select and pass `connectionId`.
- Method not found: verify `className`, `methodName`, and `parameterTypes`.
- Parameter value arrives as `null`: verify `argsJson` shape and generated keys.
- Wrong class version or bean resolution failure: inspect connection classloader data and consider `classLoaderIdentity`.
- ClassLoader discovery needed: use `host` and `httpPort` from `list_debug_tools_connections`, then direct HTTP `GET /allClassLoader` and `POST /classLoader/hasClass`.
- Multiple ClassLoaders match the target class: present the matching loader names and identities, then ask the user which one to use.
- Template generation fails: fall back to explicit `parameterTypes` and minimal `argsJson` only when the protocol is clear.

## References

- For complex argument types, read `references/args-json.md`.
- For detailed workflow decisions, read `references/workflow.md`.
- For direct DebugTools HTTP ClassLoader checks, read `references/http-classloader.md`.
- For common failures and recovery steps, read `references/troubleshooting.md`.

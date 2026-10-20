# DebugTools AI workflow

Load `skills/debug-tools/SKILL.md` (`$debug-tools`) for any DebugTools task. This is
one skill across connection, run/reload, method invocation/results, HTTP, deployment,
Spring, runtime diagnosis, logs/SQL and Kubernetes. Read only needed skill references.
Repository workflow reference: `docs/workflow.md`.

Use `get_debug_tools_status` / `list_debug_tools_connections` to choose the application
project and target. Reuse its connection; with no suitable JVM use
`list_attachable_jvms` then `attach_local_jvm`. Startup is within the user's requested
scope only; discover exact configurations with `list_debug_tools_run_configurations`
and use `execute_debug_tools_run_configuration` when appropriate. Rediscover a
connection after startup and wait for Spring readiness before a Spring-dependent call.

For changed code use `compile_and_reload_modified_files`, retain operationId and
confirm completion with `get_hotswap_operation`. Then prepare args with
`generate_method_args_template` when needed and call `invoke_java_method` once.
`run_and_invoke` can compose reload → invoke → evidence. Keep projectPath,
connectionId, agentInstanceId and returned handles fixed. Timeout recovery retrieves
the original result; never repeat a business action merely to obtain output.

Only use tools in the current catalog. No shell process/port discovery as an MCP
substitute. Direct HTTP companions require MCP-selected host/httpPort. Older Spring
config uses `POST /spring/config` with a JSON string array; readiness uses
`GET /spring/ready`, retryable=true means bounded polling, retryable=false stops.
Current MCP provides the preferred Spring config/readiness tools. Preserve generated
RunContentDTO keys/order, choose ambiguous loaders explicitly, and report truncation,
unknown states and incomplete cleanup. Stop/release only sessions created for the
request; keep pre-existing sessions in place. Agent/pod/container replacement ends
old-handle recovery even when endpoint names match.

For code/route lookup or read-only data checks, use the unified debug-tools skill
and load references/code-search.md or references/database-query.md. These optional
companion IDE tools must be present in the current catalog; confirm their exact
parameter and response shapes before use. They do not require JVM attachment.

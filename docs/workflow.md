# DebugTools workflow

Use the single `skills/debug-tools/SKILL.md` entrypoint for any DebugTools request.
MCP categories describe primary workflows; they are not separate skills or forced
steps. The skill composes the requested outcome across groups and loads references
only when relevant. See [workflow groups](workflow-groups.md).

1. Discover actual catalog support, target project and an existing connection.
2. Attach if needed; launch only when the user requested/authorized it, using a
   selected PID or exact configuration. Rediscover connection after startup.
3. For Spring-dependent invocation after fresh attach/start, wait for readiness.
   Prefer wait_for_application_ready. Older plugins may use GET /spring/ready only
   on selected MCP host/httpPort; retryable=true permits bounded polling,
   retryable=false stops. Require ready=true/state=UP.
4. Confirm requested reload, generate uncertain/complex arguments, then invoke once.
   Preserve generated RunContentDTO keys and order, not a targetMethodContent wrapper.
5. Retrieve existing results and streams with returned handles/cursors. A timeout
   does not prove failure; do not repeat writes/jobs to recover their output.
6. Collect requested trace, logs/SQL or other evidence; compare snapshots if needed.
   Clean up sessions created for this request and confirm the returned state.

Keep projectPath, connectionId, agentInstanceId and ClassLoader consistent. Ambiguous
connections/loaders require explicit selection; read all loader pages first. Target
replacement invalidates old handles. UNKNOWN_OR_PENDING remains unknown; use a total
recovery budget of 30 seconds unless the user specifies one.

For named Spring runtime Environment properties prefer get_spring_config. Older
plugins use POST /spring/config with a JSON string array only after MCP supplies
host/httpPort. Config values are resolved runtime properties, not raw file contents.
No guessed ports, invented endpoints or shell discovery as an MCP substitute.

Detailed contracts are in [tool-contracts.md](tool-contracts.md). The installed skill
is self-contained; it does not require repository docs after installation.

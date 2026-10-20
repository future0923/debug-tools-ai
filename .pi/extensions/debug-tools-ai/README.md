# DebugTools AI for Pi

The package exposes one `debug-tools` skill and a `/debug-tools <request>` command.
The command loads the shared workflow entry; it does not force a topic or concatenate
all reference documents. The same skill can connect, start/reload when authorized,
invoke once, recover the original result, collect evidence and clean up sessions.

Example: `/debug-tools 热重载 OrdersTest 后调用健康检查，超时先恢复原结果`.

Install with `./install.sh --pi`. Existing topic words such as `runtime` are ordinary
request text rather than separate skill routes.

[Workflow groups and migration](../../../docs/workflow-groups.md)

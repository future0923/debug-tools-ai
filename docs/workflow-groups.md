# DebugTools 工作流分组与统一 skill

56 个工具按用户工作流分成九组。每个工具恰好属于一组；结果、流、快照和单次调用诊断都在方法调用流程中。

| 分组 | 数量 | 工具 |
| --- | --- | --- |
| 连接与 JVM | 7 | `attach_local_jvm`、`get_agent_capabilities`、`get_debug_tools_status`、`list_attachable_jvms`、`list_debug_tools_connections`、`manage_connection_context`、`manage_debug_tools_connection` |
| 运行与热重载 | 5 | `compile_and_reload_modified_files`、`execute_debug_tools_run_configuration`、`get_hotswap_operation`、`list_debug_tools_run_configurations`、`manage_run_instance` |
| 方法调用 | 17 | `cancel_invocation_stream`、`capture_result_snapshot`、`compare_result_snapshots`、`diagnose_invocation`、`generate_method_args_template`、`get_invocation_result`、`get_method_around_script`、`get_method_trace`、`inspect_run_result`、`invoke_java_method`、`list_method_around_scripts`、`manage_method_around_script`、`manage_method_preset`、`read_invocation_stream`、`release_result_snapshot`、`release_run_results`、`run_and_invoke` |
| HTTP 调试 | 3 | `build_controller_http_request`、`execute_http_request`、`search_http_url` |
| 脚本与部署 | 5 | `compile_and_deploy_java`、`deploy_class_files`、`deploy_resources`、`execute_groovy_script`、`get_agent_operation` |
| Spring | 4 | `explain_spring_config`、`get_spring_config`、`inspect_spring_beans`、`wait_for_application_ready` |
| 运行时诊断 | 7 | `find_class_loaders`、`get_jvm_snapshot`、`get_thread_snapshot`、`inspect_runtime_class`、`manage_async_context`、`manage_method_watch`、`manage_trace_selection` |
| 日志与 SQL | 6 | `aggregate_sql_statements`、`get_last_sql_statements`、`manage_business_log_capture`、`manage_sql_capture`、`read_sql_history`、`read_target_application_logs` |
| Kubernetes | 2 | `discover_kubernetes_targets`、`manage_kubernetes_connection` |

## AI 如何串联

AI 只加载一个 `debug-tools` skill。工具分组帮助查找入口；任务允许时，skill 会跨组组织完整流程：

1. 从 status/connections 确认项目、连接、agentInstanceId 和能力。
2. 缺连接时附着已选 JVM；用户要求启动时才选择精确配置启动，随后重新发现连接。
3. Spring 调用等待 readiness；修改代码后确认重载完成。
4. 准备签名/参数并调用一次，保存 invocationId、offsetPath、traceOffsetPath。
5. 超时恢复原结果，继续读流、对象、trace、日志或 SQL；不靠再次执行业务拿回结果。
6. 对需要的结果做比较、保存证据，清理本次创建的观察、日志/异步会话。

普通的只读配置请求在拿到配置后结束。独立 JVM/线程诊断不要求先调用方法。
没有 MCP 能力、目标模糊、agent/Pod 身份变化或恢复预算到期时，保留真实未知状态。

## 分类与身份分开

`DebugToolsMcpWorkflows` 集中显式维护所有工具分类，未分类工具不能默认塞入方法组。
descriptor 的 category 反映新分类；tool name、input/output schema 和原有工具 FQN 保持稳定。
因此 `run_and_invoke` 虽移到方法组，其历史 Hotswap FQN 仍保留为身份键；
SQL 等工具虽移出方法组，历史方法组 FQN 同样保留。分类变化不能用重建工具身份实现。
新分类的组级开关由 IDEA 管理；升级后应在 Exposed Tools 检查预期启用状态。
旧版 MCP API 没有分类字段时保持原平面工具入口。

## skill 安装迁移

包中只保留 `skills/debug-tools/SKILL.md`，详细内容在同目录 references 下按需读取。
各宿主入口、Pi `/debug-tools <请求>`、OpenCode discovery 都加载这一入口。
旧 topic 前缀不再是必填路由；例如 `/debug-tools 启动测试配置并调用健康检查`。

升级安装时，原四个包拥有的 skill 会移至
`~/.local/share/debug-tools-ai/skill-backups/<timestamp>/`，自定义内容保留；
其他 skill 不受影响，同名但 frontmatter 不匹配的目录会拒绝迁移。备份不会自动删除。
这里只更新项目源码和临时安装 smoke；未替用户执行真实本机安装。

## 验证

分类全覆盖/唯一性、调用结果同组、2026.1/2026.2 descriptor 身份不变及旧 API 回退均有聚焦 Kotlin 测试。
AI validate 校验单入口、自包含参考、工具分类契约与升级/卸载行为；独立 agent 场景验证跨组工作流判断。

本轮测试数量、兼容性与包哈希见 [回归记录](workflow-regression-2026-10-19.md)。

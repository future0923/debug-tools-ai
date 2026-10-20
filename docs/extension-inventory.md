# DebugTools MCP / AI 完整扩展核对清单

截至 2026-10-14，本地源码实际注册 **56 个 MCP 工具**。下表来自 IDEA 的契约导出，
不是当前正在运行的 IDE 已加载工具清单；安装新插件及新 agent 后以运行时 catalog/capabilities 为准。

## 实际工具入口

### 连接与实例

| 工具 | 必填输入（另有动作级校验） |
|---|---|
| `get_debug_tools_status` | 无；多目标时须显式选择 |
| `list_debug_tools_connections` | 无；多目标时须显式选择 |
| `list_attachable_jvms` | 无；多目标时须显式选择 |
| `attach_local_jvm` | `pid` |
| `manage_debug_tools_connection` | `action` |
| `manage_connection_context` | 无；多目标时须显式选择 |
| `get_agent_capabilities` | 无；多目标时须显式选择 |
| `discover_kubernetes_targets` | 无；多目标时须显式选择 |
| `manage_kubernetes_connection` | 无；多目标时须显式选择 |
| `list_debug_tools_run_configurations` | 无；多目标时须显式选择 |
| `execute_debug_tools_run_configuration` | `configurationName` |
| `manage_run_instance` | 无；多目标时须显式选择 |

### 调用、输入与 HTTP

| 工具 | 必填输入（另有动作级校验） |
|---|---|
| `generate_method_args_template` | `className`、`methodName` |
| `invoke_java_method` | `className`、`methodName` |
| `run_and_invoke` | `className`、`methodName` |
| `list_method_around_scripts` | 无；多目标时须显式选择 |
| `get_method_around_script` | `name` |
| `manage_method_around_script` | `action` |
| `manage_method_preset` | `action` |
| `search_http_url` | 无；多目标时须显式选择 |
| `build_controller_http_request` | `baseUrl`、`className`、`methodName` |
| `execute_http_request` | `method`、`url` |
| `execute_groovy_script` | `classLoaderIdentity`、`script` |

### 热重载与部署

| 工具 | 必填输入（另有动作级校验） |
|---|---|
| `compile_and_reload_modified_files` | 无；多目标时须显式选择 |
| `get_hotswap_operation` | `operationId` |
| `compile_and_deploy_java` | `classLoaderIdentity`、`files` |
| `deploy_class_files` | `classLoaderIdentity`、`files` |
| `deploy_resources` | `classLoaderIdentity`、`files` |
| `get_agent_operation` | `agentInstanceId`、`operationId` |

### 结果、流与比较

| 工具 | 必填输入（另有动作级校验） |
|---|---|
| `get_invocation_result` | `invocationId` |
| `inspect_run_result` | `offsetPath` |
| `release_run_results` | `offsetPaths` |
| `read_invocation_stream` | `invocationId` |
| `cancel_invocation_stream` | `invocationId` |
| `capture_result_snapshot` | `offsetPath` |
| `compare_result_snapshots` | `afterSnapshotId`、`beforeSnapshotId` |
| `release_result_snapshot` | `snapshotId` |

### 运行时诊断

| 工具 | 必填输入（另有动作级校验） |
|---|---|
| `get_spring_config` | `keys` |
| `wait_for_application_ready` | 无；多目标时须显式选择 |
| `inspect_spring_beans` | `classLoaderIdentity` |
| `explain_spring_config` | `classLoaderIdentity`、`keys` |
| `find_class_loaders` | 无；多目标时须显式选择 |
| `inspect_runtime_class` | 无；多目标时须显式选择 |
| `get_method_trace` | `traceOffsetPath` |
| `manage_trace_selection` | 无；多目标时须显式选择 |
| `manage_method_watch` | `agentInstanceId` |
| `manage_async_context` | `agentInstanceId` |
| `diagnose_invocation` | `invocationId` |
| `get_jvm_snapshot` | 无；多目标时须显式选择 |
| `get_thread_snapshot` | 无；多目标时须显式选择 |

### 日志与 SQL

| 工具 | 必填输入（另有动作级校验） |
|---|---|
| `manage_business_log_capture` | 无；多目标时须显式选择 |
| `read_target_application_logs` | 无；多目标时须显式选择 |
| `get_last_sql_statements` | 无；多目标时须显式选择 |
| `manage_sql_capture` | 无；多目标时须显式选择 |
| `aggregate_sql_statements` | 无；多目标时须显式选择 |
| `read_sql_history` | 无；多目标时须显式选择 |

## 已落地的 AI 能力

- 性能定位、真实 HTTP、Spring Bean/配置来源、Flux/SSE、远程/Kubernetes、结果回归与 XXL-JOB 工作流。
- 运行时能力协商；旧 agent 的 HTTP 回退和较弱实例绑定明确标记，不能伪造支持。
- 全工具输入契约导出/漂移校验，现代输出 envelope 和关键 payload 字段校验；历史返回保留较弱 schema。
- 可执行 doctor、临时目录安装 smoke、Pi 扩展、OpenCode 按需技能路由、诊断报告模板与 fresh-agent 压力场景。

## 验收与使用边界

| 范围 | 实现/证据 | 仍需真实环境确认的部分 |
|---|---|---|
| HotSwap、调用编排、流、目标绑定 | Kotlin 测试、真实回调/状态模型、服务端实例拒绝测试 | 每个实际业务应用的 reload/ready |
| HTTP | 本地真实 HTTP 服务测试单次发送、正文、响应限额、302 | 业务服务鉴权及过滤器行为 |
| Groovy/资源/远端编译/类部署 | 操作去重/资源原子写/Groovy 测试，编译/部署真实 Instrumentation 路径 | 各业务 ClassLoader 与框架刷新；无回滚保证 |
| Spring | 真实 Spring context，lazy 不初始化、覆盖链和多 context 测试 | 特定框架版本的容器差异 |
| 方法观察/异步上下文 | 专用测试 JVM 真实 ByteBuddy 重转换、返回/异常/撤销、线程不泄漏 | 选定应用 executor；不覆盖所有 JDK/ForkJoin/响应式调度器 |
| SQL/日志/调用诊断 | 聚合、精确 invocationId、日志 appender/MDC、活线程和缓存测试 | 数据源/日志框架实际配置的覆盖范围 |
| Kubernetes/Run 生命周期 | 参数/目标身份边界测试、公开 IDEA 执行 API | 尚无真实 K8s 集群端到端验证；Run/Debug 需实际 IDE 操作确认 |
| 快照、预设、Around | 冻结/比较/限额/路径约束/冲突测试 | Around 语法校验不等于编译执行成功 |

## 设计上明确保留的限制

1. 不提供“全局任意异步自动关联”的承诺：显式选定 execute(Runnable) 才传播调用 ID；
   业务 MDC、bootstrap pools、ForkJoin 和 reactive 均未自动传播。包装会改变任务 identity。
2. 注册 trace transformer、请求启动/停止、写入资源都不是业务执行成功证据。
3. 超时不能推导未执行；优先按原 operationId/invocationId 恢复，不能盲目重试写操作。
4. 查询/结果有容量、TTL、分页和截断；缺失结果不能证明没有执行或没有问题。
5. K8s Pod/Container 或 agent 实例变化后，旧 handles 不可用于新实例。
6. 没有发布、安装到用户 IDE、连接或部署到真实业务环境；本任务产物为本地源码和构建包。

详细动作、状态及限制见 [extended workflows](../skills/debug-tools/references/extended-workflows.md)。
最终本地验收：IDEA 564 项测试、agent SQL/server/Spring 77 项测试、AI validate/安装 smoke/契约校验全部通过；完整六版本 verifier（2023.3 至 2026.1）通过。构建/兼容性细节记录在 IDEA 仓库的 progress.md；环境未验证项仍按上表保留。

## Runtime diagnostics

The unified `debug-tools` skill handles timeout recovery, retained objects and
streams, slow calls, method watches and async correlation within the same workflow.
Pi users can describe the task directly: `/debug-tools <request>`.

- [Usage guide (Chinese)](runtime-diagnostics.md)
- [Regression results and remaining checks (Chinese)](runtime-regression-2026-10-14.md)

## 2026-10-19 验收完善

统一构建/同步/五 JDK 测试/跨仓库契约/最终包校验入口已加入，详见
[统一验收](workspace-verification.md)、[本轮回归记录](workspace-regression-2026-10-19.md)
和 [实机验收步骤](live-acceptance.md)。上方 564 项为 10 月 14 日验收记录；本轮实际数量
由新报告生成，避免沿用旧计数。

Current workflow entry / 当前统一入口：`skills/debug-tools/SKILL.md`。详见 [工作流分组与迁移](workflow-groups.md)。

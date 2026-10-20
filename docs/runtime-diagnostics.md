# 运行时诊断 AI skill 使用指南

`debug-tools` 面向已经运行的 Java 应用：恢复超时结果、检查对象与流、分析慢调用、观察实际业务请求。它属于统一 skill 的按需诊断流程，和连接、调用、结果恢复共享同一目标与会话状态。

## 安装与入口

按 [安装指南](installation-zh.md) 安装或更新本仓库，安装器会复制统一 skill。无需新增 MCP 服务；实际能力由 IDEA 插件与目标 JVM 的 agent 提供。

- Codex：`$debug-tools 帮我分析这次调用为什么超时，先取回已有结果。`
- Pi：`/debug-tools 观察指定方法的真实调用，结束后清理观察器。`
- 其他支持 skills 的客户端：自然语言请求运行时诊断，或明确指定 skill 名称。

没有 DebugTools MCP 时，skill 会说明缺失配置，不通过扫描端口或启动本地 Java 程序替代连接发现。运行时连接来自 `get_debug_tools_status` / `list_debug_tools_connections`；多个候选目标或多个匹配 ClassLoader 时需要明确选择。

## 可以直接使用的请求

| 需求 | 示例 | 关键结果 |
| --- | --- | --- |
| 超时恢复 | “订单调用超时了，invocationId 是 i-42，只找原来的结果。” | 查询原句柄；等待有上限，不重复下单 |
| 对象检查 | “展开这个 offsetPath，最多三层，告诉我哪些内容被截断。” | 有界对象视图，保留循环/截断信息 |
| 流读取 | “继续读取这次 SSE，到观察时间后结束并确认取消。” | 游标连续性、丢失事件与终态 |
| 性能分析 | “分析已有 trace，结合线程和 SQL 判断慢在哪里。” | inclusive 耗时不直接相加；时间窗口与精确关联分开 |
| 真实请求观察 | “在选定 loader 中观察此方法 30 秒、最多 10 次，不主动调用。” | 精确 JVM descriptor 的 watch，读取后释放 |
| 异步关联 | “跟踪这个应用 Executor 的 execute(Runnable)，调查完恢复。” | 只覆盖该执行器；保留队列任务和 MDC 限制 |
| 结果对比 | “对比这两次已保留的结果，忽略 /updatedAt。” | 冻结快照、显式 JSON Pointer 排除、释放快照 |

参数以当前 MCP catalog 的 schema 为准。完整工具输入契约见 [tool-contracts.md](tool-contracts.md)，全部扩展和边界见 [extension-inventory.md](extension-inventory.md)。普通调用、启动与部署继续用相应既有工作流。

## 一次诊断如何完成

1. 确认应用项目、connectionId、agentInstanceId 与支持的能力。先利用已有 invocationId、operationId、offsetPath、traceOffsetPath。
2. 根据问题读取原结果、trace、线程、SQL 或日志。需要观察真实请求时先检查已有会话，再创建有时间和次数上限的观察器。
3. 超时只表示客户端停止等待。恢复默认总预算 30 秒；仍未知时保留句柄和未知状态。实例改变后停止沿用旧句柄。
4. 清理本次创建的 watch、日志采集或 async 会话，确认状态；不关闭原来就存在的会话。不能确认清理时给出剩余 ID。
5. 报告事实、推断、缺失证据与清理结果，可使用 [诊断报告模板](diagnostic-report-template.md)。

## 能力边界

- 反射调用 Controller 不经过真实 HTTP 网络、过滤器和序列化链，不能当作 HTTP 端到端测试。
- agent 日志不是完整业务日志；ROOT_APPENDER 采集受非 additivity、过滤和日志重配置影响。
- selected-executor 关联不是全局异步传播，不覆盖所有 ForkJoin、Reactive 或业务 MDC。
- 观察器注册成功不等于收到业务请求；停止请求发出不等于已清理。
- SQL 聚合只覆盖保留窗口；不完整对象快照相等不代表完整结果相等。
- Kubernetes 替换 Pod/容器、同端口新 JVM 都是新实例，旧操作和结果句柄不能继承。

实测范围与尚缺环境的项见 [回归报告](runtime-regression-2026-10-14.md)。

Current workflow entry / 当前统一入口：`skills/debug-tools/SKILL.md`。详见 [工作流分组与迁移](workflow-groups.md)。

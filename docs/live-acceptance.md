# 实机验收步骤

这里列出本地自动化无法替代的验收。每次先记录选定测试环境及允许的副作用，使用专门的
无真实订单/支付/通知副作用样例。保留原始返回、版本和时间，不以请求已发送替代完成。
当前未提供可调用 DebugTools MCP 或选定 Kubernetes/业务测试应用时记为 BLOCKED。

## IDEA MCP 与 Run / Debug / HotSwap

准备：安装本次构建的插件，重启或按 IDEA 支持流程重载，启用 IDEA MCP Server，
让客户端实际暴露工具。选定测试项目与唯一运行配置，使用可重复调用的计数/返回值样例。

1. 导出当前 catalog，与 `docs/mcp-input-contracts.json` 的 DebugTools 工具集合核对，
   当前源码期望 56 项。若宿主显示不同名称空间，按工具名匹配并保留原始导出。
2. 用 status/connections 确认项目。授权启动测试配置后，经 run instance 或 Hotswap
   启动；重新发现连接，读取 agentInstanceId/capabilities。START_REQUESTED 不等于连接就绪。
3. Spring 目标先等待 readiness UP。按签名生成参数，调用一次，保存 invocationId 和结果。
4. 修改一个方法体，编译重载并查询 operationId，必须确认 SUCCEEDED，再调用一次验证新值。
5. 让样例方法延迟超过 waitMillis，按 invocationId 恢复原结果；检查计数只增加一次。
6. 停止并重新启动该测试进程，确认新 agentInstanceId，旧句柄被拒绝或报告目标变化。
7. 多项目同时打开时分别请求 projectPath，结果、会话与缓存不得串项目。

通过标准：工具实际可见、身份/就绪/重载结果明确、原调用不重复执行、新旧实例句柄隔离。

## Kubernetes

准备：明确测试 context、namespace、deployment/pod、container、PID，并授权注入或
仅连接已安装 agent。不要自动选当前 context 或生产 workload。

1. discovery 列出目标，记录 pod UID 与 container ID。建立 TCP/HTTP 两端口转发后读 capabilities；
   转发建立不代表应用 ready。注入须用实际发现的 Java PID。
2. 调用无副作用样例后中断本次专用隧道，验证状态报告与重连行为。
3. 在获准测试 workload 中更换 Pod 或重启容器，发现新的 UID/container/agent ID，
   拒绝沿用旧 handles；不得悄悄连接同名的新实例。
4. 关闭本次隧道，确认转发进程退出、连接状态更新；不要把 STOP_TUNNEL 当作 agent 停止。
5. 若测试 STOP_AGENT，单独验证其结果；协议无 ACK 的路径只能报告 STOP_REQUESTED。

通过标准：双端口实际可用、目标替换被识别、旧句柄不跨实例、重连和清理可验证。

## 框架资源刷新

准备：选定测试应用的框架版本、ClassLoader、watchResources 唯一目录，保存原文件用于
测试结束后的恢复。仅在授权的样例中写入资源，保留每文件的 hash 与操作状态。

| 框架 | 样例变更 | 需要观察的业务行为 |
| --- | --- | --- |
| Spring | 样例消息/模板资源或受支持的配置刷新路径 | 新请求返回更新后的样例值；普通文件写入不代表 Environment 已刷新 |
| MyBatis | 测试 mapper 的只读 SELECT 表达式 | 返回可区分的新值，证明 mapper 缓存/配置实际更新 |
| Solon | 该应用明确支持热刷新的样例资源 | 受影响组件的新请求反映更新；记录所用刷新插件 |

若返回 frameworkReloadConfirmed=false，继续保留此状态直到独立业务证据确认。
批量写入可能部分成功；失败后按每文件证据恢复并重新验证，不承诺自动回滚。

## 记录格式

每项记录 PASS / FAIL / BLOCKED / NOT_RUN、插件/agent/JDK/框架版本、明确目标身份、
输入（脱敏）、返回原文、实际行为、清理结果和剩余句柄。可使用
[诊断报告模板](diagnostic-report-template.md)。环境能力缺失和真实失败分别记录。

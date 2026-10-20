# 运行时扩展回归记录（2026-10-14）

本报告区分打包 agent 协议回归与真实 IDEA/Kubernetes 集成。PASS 表示已执行且通过；BLOCKED 表示当前缺环境；NOT_RUN 表示本次未执行；FAIL 表示已执行失败。

## 本次真实 agent 回归

测试为 IDEA 仓库 `PackagedAgentRegressionTest.kt`：在临时 HOME 中启动独立 JVM，用最终内置 agent 的 `-javaagent` 加载，经 loopback TCP/HTTP 请求验证，不连接用户应用。所有子进程与临时目录在结束时清理。

| 状态 | 验证项 | 实际断言 |
| --- | --- | --- |
| PASS | TCP 方法调用与异常 | 返回值正确，业务异常按失败返回 |
| PASS | 客户端超时恢复 | 50ms 等待超时后查询原 invocationId，业务计数只增加一次 |
| PASS | Groovy 操作去重 | 同 operationId 重复提交不重复执行业务 |
| PASS | Java 21 方法观察与清理 | 插桩收到带 invocationId 的事件；释放后列表为空且原方法仍正常 |
| PASS | 编译检查与真实部署 | deploy=false 时仍返回 10；显式部署后返回 20 |
| PASS | 错误 ClassLoader | 操作失败，原业务返回值保持 20 |
| PASS | 结果根缓存释放 | 第一次 removed=true，重复释放 removed=false |
| PASS | 目标实例绑定 | 独立新 JVM 拒绝旧 agentInstanceId，业务计数不增加；旧操作查询 HTTP 409 |

回归首次发现：原 Byte Buddy 只能解析到 Java 19，Java 21 类观察返回
WATCH_UNAVAILABLE。修复主项目依赖管理，将 Byte Buddy/agent 固定为 1.17.8；
Maven Shade 升为 3.6.2，以处理新依赖中的多版本 class 文件。未用 experimental
VM 参数绕过。重新构建 agent、同步 IDEA 内置 jar 后，上述回归通过。

## 自动化验收

- PASS：IDEA `./gradlew check buildPlugin -Pkotlin.daemon.jvmargs=-Xmx2g --offline`，564 tests、0 failures/errors/skipped。
- PASS：JBR 21 / Maven 3.8.7，SQL 15 + server 52 + Spring extension 10 = 77 tests，0 failures/errors/skipped。显式运行 Surefire 3.2.5，避免 JDK 21 profile 跳过测试。
- PASS：`bash scripts/validate.sh`，四 skill 临时目录安装/卸载 smoke、OpenCode/Pi 路由、doctor、工具契约和压力场景检查。当前宿主未安装的客户端会显示 doctor warning，不代表临时安装 smoke 失败。
- PASS：`quick_validate.py skills/debug-tools-runtime-diagnostics`。
- PASS：[独立 AI 行为场景](../tests/pressure/runs/2026-10-14-runtime-diagnostics.md)，覆盖实例替换、禁止重复下单、观察清理归属和 commonPool 关联边界。
- PASS：最终包 `./gradlew verifyPlugin -Pkotlin.daemon.jvmargs=-Xmx2g --offline`，六版本 Compatible：2023.3、2024.1、2024.3、2025.1、2025.3、2026.1；无配置的失败级别问题，保留实验/废弃 API 提示。
- PASS：打包的 56 工具输入/输出契约与 IDEA 本轮生成的 `build/generated/debug-tools-mcp-contracts.json` 一致。
- PASS：ZIP 只有一个 DebugTools 插件根目录，内置 agent 与本轮回归的资源 jar 字节一致。

最终产物 `debug-tools-idea/dist/DebugTools-5.3.0.zip`：

- ZIP SHA256：`e6d961c284d22b986c416c5b29482f17fdb9083f2e4fbb03fcd04a3ed0fdf7b4`
- Agent SHA256：`09c226ce0b201996bd1924cfe79b5247654a22307318ac159a49ad478a7c8517`

源码和文档已加入暂存区，未提交或发布。jar/ZIP 由现有 `.gitignore` 忽略，未强制加入暂存区。

重跑打包 agent 回归：在 IDEA 仓库使用匹配项目配置的 JDK，执行
`./gradlew test --tests '*PackagedAgentRegressionTest' -Pkotlin.daemon.jvmargs=-Xmx2g`。
该测试加载本地 `src/main/resources/lib/debug-tools-agent-5.3.0.jar`；改动主项目
agent 后须先重建并同步该资源，不能只测试旧 jar。

## 尚未验证的实机链路

| 状态 | 项目 | 需要的环境与验收 |
| --- | --- | --- |
| BLOCKED | 真实 IDEA MCP catalog、工具调度、Run/Debug 启停与 HotSwap | 当前会话无 DebugTools MCP；需安装最终插件的 IDEA 暴露工具，确认完整清单与调用链 |
| BLOCKED | Kubernetes 发现、双端口转发、注入与替换 Pod | kubectl 可用但没有 context；需可用测试集群，验证 UID/容器身份切换、旧句柄拒绝与隧道清理 |
| NOT_RUN | 实际业务框架资源刷新 | 需目标 Spring/MyBatis/Solon 应用；资源写入证据不能替代框架已刷新证据 |

本轮六版本 verifier 通过不能代替以上实机验证。

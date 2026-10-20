# 完善与统一验收记录（2026-10-19）

本轮落实统一验收、JVM 矩阵、skill 路由与行为场景。真实 IDEA MCP、Kubernetes 和
业务框架刷新需要明确的测试环境，未通过本地自动化代替验证。

## 变更

- `debug-tools-ai verify-workspace` 重建 agent、运行普通 Maven test、同步内置 jar、
  强制 IDEA 测试和目标矩阵、比对契约、验证 AI 安装、核对插件内容及完整 verifier。
- 默认 Surefire 固定为 3.2.5，使 JDK 21+ 的普通 `mvn test` 实际执行现有测试。
- 打包 agent 测试以 Java 8/11/17/21/25 各自 javac 生成原生字节码；HTTP 由操作系统
  分配端口，启动日志就绪后探活，减少端口竞争导致的假失败。
- 每个 adapter 单独检查四个 skill 的路由；所有 skill 的 Markdown 相对链接必须留在
  自己安装目录且实际存在。新增回归证明一个 adapter 缺失不会被其他入口掩盖。
- 新增流取消未确认、多 ClassLoader/旧 agent 缺观察能力压力场景；独立 AI 模拟三场景
  保持预算、实例与证据边界，见 [行为报告](../tests/pressure/runs/2026-10-19-runtime-failure-boundaries.md)。

## 发现与修正

Java 25 首次在 Groovy 执行业务样例时失败：`Unsupported class file major version 69`。
独立最小样例证实：Groovy 4.0.22 失败，4.0.28 返回 42。主仓库升级为 4.0.28，
随后通过统一命令重建打包 agent 并验证。没有使用旧字节码或实验开关绕过此项。

首次 offline 统一运行因为 Maven 本地来源标记与当前仓库不一致，无法使用 Groovy4.0.28，
build-agent 记录 FAIL，后续步骤全部 NOT_RUN。报告保留后改用正常依赖解析重跑。

## 本轮结果

统一命令本轮完整执行成功，report.json 状态 PASS；13 个本地验收步骤全部 PASS。

| 状态 | 检查 | 证据 |
| --- | --- | --- |
| PASS | 普通 Maven test | SQL15 + server52 + Spring10 = 77，0 failures/errors/skipped |
| PASS | IDEA check/buildPlugin | 564 tests，0 failures/errors/skipped |
| PASS | 契约比对 | 56 工具 input/output 与本轮导出一致 |
| PASS | AI validate | 安装/卸载、路由、doctor、契约与压力场景检查 |
| PASS | 包内容 | 单插件、无 MCP Server 依赖、内置 agent 与本轮构建字节一致；verifier 完成后再次确认哈希未变 |
| PASS | 完整 verifier | 2023.3、2024.1、2024.3、2025.1、2025.3、2026.1 全部 Compatible；保留实验/废弃 API 提示 |
| PASS | Java 8 (1.8.0_441) | 原生字节码、TCP/HTTP、Groovy、watch 清理、编译/部署与实例绑定 |
| PASS | Java 11 (11.0.15) | 原生字节码、TCP/HTTP、Groovy、watch 清理、编译/部署与实例绑定 |
| PASS | Java 17 (17.0.14) | 原生字节码、TCP/HTTP、Groovy、watch 清理、编译/部署与实例绑定 |
| PASS | Java 21 (21.0.6) | 原生字节码、TCP/HTTP、Groovy、watch 清理、编译/部署与实例绑定 |
| PASS | Java 25 (25) | 原生字节码、TCP/HTTP、Groovy、watch 清理、编译/部署与实例绑定 |

统一命令实际运行：

```bash
bash bin/debug-tools-ai verify-workspace \
  --java-home /Library/Java/JavaVirtualMachines/jbr_jcef-21.0.6-osx-x64-b631.42/Contents/Home \
  --maven /Users/weilai/software/maven-3.8.7/bin/mvn
```

本地机器报告位于 `build/workspace-verification/20261019-105028-766865/report.json`，
逐步日志在同目录。报告被现有 build/ 忽略规则排除，未强制加入暂存区。

产物 `debug-tools-idea/dist/DebugTools-5.3.0.zip`：

- ZIP SHA256：`f512899de92207f0a271bce8f5b77cec6e741ddf0dd5d2bd669acf0112ec79de`
- Agent SHA256：`cc610181ed3889cf5d14c6c13762d5632f60c5e8581217d6a812b5cbf6ea8fa3`


已完成：AI validate、3 项验收证据负向回归、2 项路由负向回归、独立 AI 模拟场景通过。
这些检查验证报告与 agent 判断，不能代替真实业务端到端执行。

## 实机边界

- BLOCKED：会话无 DebugTools MCP 工具，无法安装后的实际 catalog、Run/Debug、HotSwap 全链路验收。
- BLOCKED：kubectl context 为空，未选定任何测试 workload。
- NOT_RUN：没有指定 Spring/MyBatis/Solon 业务样例，资源刷新未实机确认。

具体准备与通过标准见 [实机验收步骤](live-acceptance.md)。统一命令生成的 report.json
始终将这些环境检查单列为 NOT_RUN，不会把本地 PASS 扩大成整体实机验收通过。

源码、脚本、测试和 docs 已加入暂存区，未提交/发布，未安装到用户 IDE。保留原有
无关修改；AGENTS.md 按仓库偏好未加入暂存区。完整 verifier 的两个新版 IDE 阶段曾
等待 Marketplace 依赖解析，最终成功；未跳过该检查或沿用上轮报告。

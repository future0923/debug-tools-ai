# 工作流分组与统一 skill 回归记录

本次将 56 个 MCP 工具按职责归入九个工作流组；调用结果、流、快照、trace 和单次调用诊断保持在方法调用组。AI 仅发现一个 `debug-tools` skill，按请求跨组完成任务。

## 本地验证

| 检查 | 结果 | 证据与范围 |
| --- | --- | --- |
| IDEA test/check/buildPlugin | PASS | 571 tests，0 failures/errors/skipped |
| 全覆盖分类、结果同组与稳定身份 | PASS | 3 项新增 Kotlin 测试；分类枚举与全部注册工具集合相等 |
| Descriptor 兼容 | PASS | 2026.1/2026.2 分类 API 保留原工具 FQN；旧 API 平面回退测试 |
| 完整 verifier | PASS | 2023.3、2024.1、2024.3、2025.1、2025.3、2026.1 全部 Compatible；仍有既有弃用/实验 API 提示 |
| 56 工具契约 | PASS | input/output schema 与修改前暂存契约完全相同；新增分类/稳定身份与 IDEA 导出一致 |
| AI validate、skill quick_validate | PASS | 单入口发现、自包含引用、各宿主路由、适配器与压力场景结构校验 |
| 安装与升级 | PASS | 临时 HOME；旧四 skill 保留自定义内容后迁出发现路径；重复安装、卸载、无关目录保留及同名外来目录拒绝 |
| 独立 AI 行为模拟 | PASS | [场景 27 记录](../tests/pressure/runs/2026-10-19-unified-workflow.md)，包括复合调用、配置来源查询和未确认流取消；原 fixture 的错误枚举经源码核对后更正并重放 |
| 插件包 | PASS | 单插件结构，包含新分类实现，内置 agent 与源码资源一致，dist 与 build/distributions 内容相同 |

命令：

```bash
# IDEA，JBR 21 环境
./gradlew test check buildPlugin movePluginZip -Pkotlin.daemon.jvmargs=-Xmx2g --offline
./gradlew verifyPlugin movePluginZip -Pkotlin.daemon.jvmargs=-Xmx2g --offline

# AI
bash scripts/validate.sh
python3 scripts/check-tool-contracts.py --plugin-export ../debug-tools-idea/build/generated/debug-tools-mcp-contracts.json
```

本次未修改 agent 实现，没有重新执行上一轮 Maven 77 tests 或五 JDK 矩阵，不能把历史结果算成本轮重跑。

## 构建产物

- ZIP：`debug-tools-idea/dist/DebugTools-5.3.0.zip`
- ZIP SHA256：`369127ca114a47a5d0e912ee278dbee58ae1c406fde673d8cc32e87416bfbde3`
- Agent SHA256：`cc610181ed3889cf5d14c6c13762d5632f60c5e8581217d6a812b5cbf6ea8fa3`

本地插件证据：IDEA `build/reports/workflow-groups.json`、`build/test-results/test/`、`build/reports/pluginVerifier/`。

## 未实测项目

真实 IDEA Exposed Tools 新分类显示和组级启用状态为 NOT_RUN；没有覆盖用户安装的插件或 skills。本地反射构造测试不等同于真实页面确认。当前会话无 DebugTools MCP，Kubernetes 无 context；业务框架刷新等实机范围仍按 [实机验收](live-acceptance.md) 执行。源码已准备，未提交或发布。

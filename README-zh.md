# DebugTools AI

中文 | [English](README.md)

[![Validate](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml/badge.svg)](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml)
[![Release](https://img.shields.io/github/v/release/future0923/debug-tools-ai?include_prereleases)](https://github.com/future0923/debug-tools-ai/releases)
[![npm](https://img.shields.io/npm/v/debug-tools-ai)](https://www.npmjs.com/package/debug-tools-ai)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

DebugTools AI 用来教 Codex、Claude Code、OpenCode、Gemini、Cursor、Kimi、Pi 和其他 Agent 使用 DebugTools IntelliJ MCP 工具：附着 JVM、生成方法参数模板、调用 Java 方法。

## 30 秒开始

为 Codex 安装：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

验证安装：

```bash
debug-tools-ai doctor
```

然后对你的 Agent 说：

```text
Use DebugTools to call com.demo.UserController.getUser.
```

期望的 Agent 调用路径：

```text
list_debug_tools_connections
generate_method_args_template   # 只有方法需要参数或参数不确定时才需要
invoke_java_method
```

如果当前没有可用的 DebugTools 连接，Agent 应该走：

```text
list_attachable_jvms
attach_local_jvm
invoke_java_method
```

## 它能做什么

安装这个包后，Agent 可以：

- 查看当前 DebugTools 连接
- 列出可附着的 JVM 进程
- 将 DebugTools agent 附着到本地 JVM
- 根据 Java 方法签名生成 DebugTools `argsJson` 参数模板
- 通过 DebugTools 调用 Java 方法
- 必要时通过 DebugTools HTTP 恢复 ClassLoader 问题

## 前置条件

- IntelliJ IDEA 已安装 DebugTools 插件。
- IntelliJ 插件提供的 DebugTools MCP tools 可用。
- 目标 JVM 已连接或可以被本地附着。
- 你的 AI 客户端可以使用 DebugTools MCP tools。

这个包不会安装 IntelliJ IDEA、DebugTools 插件、DebugTools agent 或 MCP Server。

## 安装

一行安装：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

克隆后安装：

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --codex
```

安装所有本地集成：

```bash
bash install.sh --all
```

npm 发布后：

```bash
npm install -g debug-tools-ai
debug-tools-ai upgrade --all
```

卸载一个集成：

```bash
debug-tools-ai uninstall --codex
```

详细安装说明见：[docs/installation-zh.md](docs/installation-zh.md)。

## 支持的 Agent

| Agent | 本地安装 |
| --- | --- |
| Codex | `bash install.sh --codex` |
| Claude Code | `bash install.sh --claude` |
| Gemini | `bash install.sh --gemini` |
| OpenCode | `bash install.sh --opencode` |
| Cursor | `bash install.sh --cursor` |
| Kimi | `bash install.sh --kimi` |
| Pi | `bash install.sh --pi` |
| 通用 Agent | 使用 `AGENTS.md` |

不同平台的 marketplace 安装可能需要发布后经过对应平台审核。

## CLI

| 命令 | 作用 |
| --- | --- |
| `debug-tools-ai install --codex` | 安装一个本地集成。 |
| `debug-tools-ai install --all` | 安装所有支持的本地集成。 |
| `debug-tools-ai upgrade --all` | 用当前包版本重新安装本地集成。 |
| `debug-tools-ai uninstall --codex` | 卸载一个本地集成。 |
| `debug-tools-ai uninstall --all` | 卸载所有支持的本地集成。 |
| `debug-tools-ai doctor` | 检查包文件和本地 adapter 安装路径。 |
| `debug-tools-ai validate` | 运行完整校验。 |
| `debug-tools-ai pressure` | 列出 skill 行为压力测试场景。 |
| `debug-tools-ai pressure-report` | 生成压力测试记录模板。 |
| `debug-tools-ai prepublish-check` | 发布前运行 release 检查。 |

如果你在源码 checkout 里运行，使用 `bash bin/debug-tools-ai <command>`。

## Doctor

运行：

```bash
debug-tools-ai doctor
```

`OK` 表示预期文件存在。`WARN` 表示当前 `HOME` 下没有安装某个可选本地 adapter。`FAIL` 表示必要包文件缺失，或使用了 `--strict-installed` 且安装路径缺失。

严格检查安装路径：

```bash
debug-tools-ai doctor --strict-installed
```

## 使用示例

无参方法：

```text
User: Use DebugTools to call com.demo.HealthController.ping.
AI: list_debug_tools_connections -> invoke_java_method
```

有参方法：

```text
User: Call com.demo.UserController.createUser with name Codex and age 18.
AI: list_debug_tools_connections -> generate_method_args_template -> invoke_java_method
```

ClassLoader 恢复：

```text
ClassNotFoundException: com.demo.UserController
AI: GET /allClassLoader -> POST /classLoader/hasClass -> invoke_java_method with classLoaderIdentity
```

如果多个 ClassLoader 都能加载目标类，Agent 必须询问用户使用哪个 loader identity，不能自行猜测。

更多示例：[docs/examples-zh.md](docs/examples-zh.md)。安装和使用 transcript：[docs/transcripts-zh.md](docs/transcripts-zh.md)。Spring Boot demo：[examples/spring-boot-demo.md](examples/spring-boot-demo.md)。

## 工作流参考

核心工具顺序：

```text
list_debug_tools_connections
list_attachable_jvms
attach_local_jvm
generate_method_args_template
invoke_java_method
```

详细文档：

- 工作流：[docs/workflow.md](docs/workflow.md)
- 工具契约：[docs/tool-contracts.md](docs/tool-contracts.md)
- Skill：[skills/debug-tools-mcp/SKILL.md](skills/debug-tools-mcp/SKILL.md)

## 校验

运行：

```bash
bash scripts/validate.sh
```

专项检查：

```bash
bash bin/debug-tools-ai validate
bash scripts/check-versions.sh
bash scripts/check-manifest-paths.sh
bash scripts/smoke-install.sh
bash scripts/check-pressure-scenarios.sh
bash scripts/check-release-readiness.sh
```

压力测试场景在 [tests/pressure](tests/pressure)。修改 skill 行为时，用 fresh AI agent 跑相关场景。

## 贡献和发布

- 贡献说明：[CONTRIBUTING.md](CONTRIBUTING.md)
- 发布流程：[docs/release.md](docs/release.md)

发布前：

```bash
bash bin/debug-tools-ai prepublish-check
```

发布需要同步版本号、更新 `CHANGELOG.md`、创建 `git tag`、发布 GitHub Release，并按目标平台完成 marketplace 提交流程。Release workflow 使用 `softprops/action-gh-release`。

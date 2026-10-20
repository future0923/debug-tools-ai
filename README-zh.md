# DebugTools AI

中文 | [English](README.md)

[![Validate](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml/badge.svg)](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml)
[![Release](https://img.shields.io/github/v/release/future0923/debug-tools-ai?include_prereleases)](https://github.com/future0923/debug-tools-ai/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

DebugTools AI 为 Codex、Claude Code、Gemini、OpenCode、Cursor、Kimi、Pi 等 AI Agent 提供 DebugTools 使用说明和 Skills。安装后，Agent 可以根据你的自然语言需求查看状态、选择或附着 JVM、热重载并调用 Java 方法、查看 JSON 结果、日志和 SQL，无需记住 MCP 工具名，也不必每次特意说“DebugTools”。

项目开源地址：[future0923/debug-tools-ai](https://github.com/future0923/debug-tools-ai)。

## 30 秒开始

先确认 IntelliJ IDEA 已安装 DebugTools 插件，并且插件提供的 MCP 已在当前 AI 客户端中启用。然后选择你正在使用的 Agent，例如 Codex：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

把末尾参数替换成对应 Agent 即可：

| Agent | 参数 |
| --- | --- |
| Codex | `--codex` |
| Claude Code | `--claude` |
| Gemini | `--gemini` |
| OpenCode | `--opencode` |
| Cursor | `--cursor` |
| Kimi | `--kimi` |
| Pi | `--pi` |
| 全部安装 | `--all` |

看到下面两类输出，表示文件已经写入对应 Agent 的本地目录：

```text
Installed Codex files
debug-tools-ai installation finished
```

安装后新建一个 Agent 会话；如果客户端没有立即发现 Skills，重启一次客户端。

现在可以直接描述任务：

```text
调用 com.demo.UserController.getUser 方法。
```

```text
用 Hotswap 启动 DemoApplication，然后调用刚修改的方法。
```

```text
读取当前 Spring 应用的 server.port 和 spring.profiles.active。
```

当上下文中存在多套类似工具、需要明确限定时，再补充“使用 DebugTools”即可。

## 前置条件

- IntelliJ IDEA 已安装 DebugTools 插件。
- DebugTools 插件提供的 MCP tools 已添加到当前 AI 客户端并处于可用状态。
- 目标 JVM 已连接，或允许 DebugTools 在本机附着。
- AI 客户端支持 MCP 和本项目对应的 Skill/插件安装方式。

DebugTools AI 只安装 Agent 指令、Skills 和插件元数据，不会安装 IntelliJ IDEA、DebugTools 插件、DebugTools agent 或 MCP Server。

## 一个统一 Skill

`debug-tools` 根据任务串联连接、启动/就绪、热重载、方法调用、原结果恢复、证据收集和清理。
结果、流、快照与调用诊断属于方法调用，不单独拆成 skill。详细步骤按需加载 references。

- [DebugTools unified workflow skill](skills/debug-tools/SKILL.md)
- [九个工作流分组及迁移](docs/workflow-groups.md)


## 安装、更新与卸载

从源码安装：

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --codex
```

需要更新时，重新执行原来的安装命令即可，新版本文件会覆盖已有安装文件。

从源码目录卸载一个 Agent 集成：

```bash
bash scripts/uninstall.sh --codex
```

卸载全部集成：

```bash
bash scripts/uninstall.sh --all
```

卸载脚本只删除 DebugTools AI 自己安装的文件，不会删除 IntelliJ IDEA、DebugTools 插件、MCP Server 或 Agent 的父级配置目录。

各 Agent 的安装位置和完整说明见 [docs/installation-zh.md](docs/installation-zh.md)，实际命令输出见 [docs/transcripts-zh.md](docs/transcripts-zh.md)。

## 使用示例

无参方法：

```text
用户：调用 com.demo.HealthController.ping。
Agent：查找可用连接并调用该方法。
```

有参方法：

```text
用户：调用 com.demo.UserController.createUser，name 是 test-user，age 是 18。
Agent：查找连接，生成参数模板，填入参数并调用方法。
```

Hotswap 运行配置：

```text
用户：用 Hotswap 启动 DemoApplication。
Agent：确认运行配置；名称不明确时先列出候选项，再提交启动请求。
```

Spring 配置读取：

```text
用户：读取当前 Spring 应用的 server.port。
Agent：查找目标连接，并读取 Spring Environment 中实际生效的值。
```

完整闭环：

```text
用户：热重载刚修改的代码，调用 UserService.health，并把最近日志和 SQL 一起返回。
Agent：run_and_invoke（必要时显式传 allowStart/runConfigurationName 或 allowAttach/pid）
```

更多示例见 [docs/examples-zh.md](docs/examples-zh.md)，Spring Boot 示例见 [examples/spring-boot-demo.md](examples/spring-boot-demo.md)。

## 工作流参考

项目维护者可以继续查看以下底层说明：

- [工作流](docs/workflow.md)
- [工具契约](docs/tool-contracts.md)
- [压力测试场景](tests/pressure)

## 校验

修改 Skills、安装器或适配文件后运行：

```bash
bash scripts/validate.sh
```

## 贡献和发布

- [贡献说明](CONTRIBUTING.md)
- [发布流程](docs/release.md)

## Runtime diagnostics / 运行时诊断

统一 `debug-tools` skill 按需处理超时恢复、对象与流读取、慢调用分析、方法观察及异步关联，
并与连接、调用和清理保持同一条工作流。Pi 直接使用 `/debug-tools <请求>`。

- [使用指南](docs/runtime-diagnostics.md)
- [回归结果与待验证项](docs/runtime-regression-2026-10-14.md)

## Workspace verification / 三仓库验收

Run `bash bin/debug-tools-ai verify-workspace` to rebuild the agent, sync the
embedded jar, run the five-JDK matrix and IDEA checks, compare exported contracts,
and verify the final plugin. See [统一验收命令](docs/workspace-verification.md) and
[实机验收步骤](docs/live-acceptance.md) for requirements and remaining environment checks.

Current workflow entry / 当前统一入口：`skills/debug-tools/SKILL.md`。详见 [工作流分组与迁移](docs/workflow-groups.md)。

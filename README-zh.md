# DebugTools AI

中文 | [English](README.md)

[![Validate](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml/badge.svg)](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml)
[![Release](https://img.shields.io/github/v/release/future0923/debug-tools-ai?include_prereleases)](https://github.com/future0923/debug-tools-ai/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

DebugTools AI 为 Codex、Claude Code、Gemini、OpenCode、Cursor、Kimi、Pi 等 AI Agent 提供 DebugTools 使用说明和 Skills。安装后，Agent 可以根据你的自然语言需求操作 DebugTools IntelliJ MCP，无需记住 MCP 工具名，也不必每次特意说“DebugTools”。

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

## 三个 Skill

### 方法调用

`debug-tools-method-invocation` 用于查找 DebugTools 连接、附着本地 JVM、生成方法参数并调用 Java 方法。

适合这类需求：

- “调用 `UserService.findById`，参数是 1001。”
- “附着到正在运行的 demo 服务，再执行这个 Controller 方法。”
- “这个方法有重载，帮我调用接收 `Long` 的版本。”

特殊注意：存在多个 JVM、连接、重载方法或 ClassLoader 时，Agent 会结合上下文选择；无法可靠判断时会先让你确认。复杂参数会先按方法签名生成模板，避免直接猜测参数结构。

### Hotswap

`debug-tools-hotswap` 用于查找 IntelliJ Run Configuration、通过 DebugTools Hotswap 启动应用，以及编译并重新加载调试会话中的已修改类。

适合这类需求：

- “用 Hotswap 启动 `DemoApplication`。”
- “把刚修改的 Java 类编译并热更新到当前调试进程。”

特殊注意：启动请求成功不等于 DebugTools 已经连接完成。后续还要调用方法时，Agent 会重新确认连接；运行配置不明确时会先列出候选项。

### Spring 配置

`debug-tools-spring-config` 用于读取目标 JVM 中 Spring `Environment` 的运行时配置值。

适合这类需求：

- “读取 `server.port`。”
- “看看当前环境实际生效的 Redis 地址和 active profile。”

特殊注意：这里读取的是 Spring 运行时解析后的值，不是直接读取 `application.yml` 或 `application.properties`。因此结果会包含 profile、环境变量、启动参数等配置源覆盖后的最终值。

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

更多示例见 [docs/examples-zh.md](docs/examples-zh.md)，Spring Boot 示例见 [examples/spring-boot-demo.md](examples/spring-boot-demo.md)。

## 工作流参考

项目维护者可以继续查看以下底层说明：

- [工作流](docs/workflow.md)
- [工具契约](docs/tool-contracts.md)
- [方法调用 Skill](skills/debug-tools-method-invocation/SKILL.md)
- [Hotswap Skill](skills/debug-tools-hotswap/SKILL.md)
- [Spring 配置 Skill](skills/debug-tools-spring-config/SKILL.md)
- [压力测试场景](tests/pressure)

## 校验

修改 Skills、安装器或适配文件后运行：

```bash
bash scripts/validate.sh
```

## 贡献和发布

- [贡献说明](CONTRIBUTING.md)
- [发布流程](docs/release.md)

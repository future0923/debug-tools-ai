# 安装

DebugTools AI 的安装器会把 Agent 指令、一个统一 Skill 和对应的插件元数据复制到本地配置目录。它不会安装 IntelliJ IDEA、DebugTools 插件、DebugTools agent 或 MCP Server。

## 安装前准备

安装 DebugTools AI 前，请先确认：

1. IntelliJ IDEA 已安装 DebugTools 插件。
2. DebugTools 插件提供的 MCP 已添加到当前 AI 客户端。
3. AI 客户端能够看到 DebugTools MCP tools。

DebugTools AI 负责告诉 Agent 什么时候、按什么顺序使用这些工具；它不能替代 MCP 本身。

## 一行安装

选择当前使用的 Agent，把对应参数放在命令末尾。例如安装到 Codex：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

支持的参数：

| Agent | 参数 | 主要安装位置 |
| --- | --- | --- |
| Codex | `--codex` | `~/.codex/skills/`、`~/.codex/plugins/debug-tools-ai/` |
| Claude Code | `--claude` | `~/.claude/debug-tools-ai/`、`~/.claude/plugins/debug-tools-ai/` |
| Gemini | `--gemini` | `~/.gemini/extensions/debug-tools-ai/` |
| OpenCode | `--opencode` | `~/.config/opencode/debug-tools-ai/`、`~/.config/opencode/plugins/` |
| Cursor | `--cursor` | `~/.cursor/debug-tools-ai/`、`~/.cursor/plugins/debug-tools-ai/` |
| Kimi | `--kimi` | `~/.kimi/debug-tools-ai/`、`~/.kimi/plugins/debug-tools-ai/` |
| Pi | `--pi` | `~/.pi/packages/debug-tools-ai/` |
| 全部安装 | `--all` | 上述全部位置 |

只安装实际使用的 Agent 即可；同时使用多个 Agent 时，可以重复执行命令并更换参数，也可以使用 `--all`。

安装器会先下载 GitHub 仓库内容，再输出每个已安装的 Agent。以 Codex 为例：

```text
Downloading debug-tools-ai from https://github.com/future0923/debug-tools-ai/archive/refs/heads/main.tar.gz
Installed Codex files
debug-tools-ai installation finished
```

出现 `Installed ... files` 和最后一行 `debug-tools-ai installation finished`，表示复制完成。安装后请新建 Agent 会话；客户端没有立即发现 Skills 时，重启一次客户端。

## 从源码安装

已经克隆仓库时，可以直接运行本地脚本：

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --codex
```

安装全部本地集成：

```bash
bash install.sh --all
```

查看安装器支持的参数：

```bash
bash install.sh --help
```

## 各 Agent 安装内容

### Codex

`--codex` 安装一个统一 Skill，并复制 Codex 插件元数据：

```text
~/.codex/skills/debug-tools/
~/.codex/plugins/debug-tools-ai/
```

### Claude Code

`--claude` 安装 `CLAUDE.md`、一个统一 Skill 和 Claude Code 插件元数据：

```text
~/.claude/debug-tools-ai/
~/.claude/plugins/debug-tools-ai/
```

### Gemini

`--gemini` 安装 `GEMINI.md`、扩展元数据和一个统一 Skill：

```text
~/.gemini/extensions/debug-tools-ai/
```

### OpenCode

`--opencode` 安装 `AGENTS.md`、一个统一 Skill 和用于注册 Skill 路径的 OpenCode 插件：

```text
~/.config/opencode/debug-tools-ai/
~/.config/opencode/plugins/debug-tools-ai.js
```

### Cursor

`--cursor` 安装 `AGENTS.md`、一个统一 Skill 和 Cursor 插件元数据：

```text
~/.cursor/debug-tools-ai/
~/.cursor/plugins/debug-tools-ai/
```

### Kimi

`--kimi` 安装 `AGENTS.md`、一个统一 Skill 和 Kimi 插件元数据：

```text
~/.kimi/debug-tools-ai/
~/.kimi/plugins/debug-tools-ai/
```

### Pi

`--pi` 把完整的 DebugTools AI 包安装到：

```text
~/.pi/packages/debug-tools-ai/
```

### 其他 Agent

没有专用参数的 Agent，按宿主支持的方式加载 `skills/debug-tools/SKILL.md`。`CLAUDE.md` 提供通用运行时说明；安装器在需要时将它复制为宿主的 `AGENTS.md`。仓库根目录 `AGENTS.md` 用于维护本项目。是否能自动发现 Skill，取决于宿主扩展机制。

## 更新

重新执行安装时，安装器会用当前仓库版本覆盖 DebugTools AI 已安装的文件。因此更新仍然使用原来的命令，例如：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

如果从本地源码安装，先更新仓库，再重跑安装脚本：

```bash
git pull
bash install.sh --codex
```

## 卸载

在源码目录中卸载一个 Agent 集成：

```bash
bash scripts/uninstall.sh --codex
```

卸载全部集成：

```bash
bash scripts/uninstall.sh --all
```

没有保留源码仓库时，也可以直接运行远程卸载脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/scripts/uninstall.sh | bash -s -- --codex
```

卸载脚本只删除 DebugTools AI 自己安装的目录，不会删除 IntelliJ IDEA、DebugTools 插件、MCP Server 或 Agent 的父级配置目录。

## 常见问题

### 安装成功，但 Agent 没有使用 Skill

先新建会话或重启 AI 客户端，再确认 DebugTools MCP tools 已经对该客户端开放。Skills 只提供使用规则；如果 MCP 没有启用，Agent 仍然无法操作 DebugTools。

### 必须在提问中写“DebugTools”吗

不需要。安装后可以直接说“调用这个 Java 方法”“用 Hotswap 启动这个配置”或“读取 Spring 运行时配置”。当上下文中有多套相似工具，或者你希望明确限定实现方式时，再说明“使用 DebugTools”。

## 运行环境与 MCP 诊断

`bash bin/debug-tools-ai doctor` 检查包版本、Node/Python 版本及已安装 Skill
是否与当前源码一致。校验需要 Node.js 18+ 和 Python 3。未安装的可选适配器
默认提示警告；`--strict-installed` 将缺失或内容过期视为失败。默认不联网探测。

`doctor --mcp-url <明确的 Streamable HTTP MCP 地址>` 执行 MCP 初始化和
分页 tools/list，不调用 Java 方法、不附着 JVM。需要 Bearer token 时通过
`DEBUG_TOOLS_MCP_TOKEN` 环境变量提供；不会打印 token 或跟随重定向。
本诊断暂不支持旧式仅 SSE 传输，可使用 AI 客户端自带的连接检查。

Current workflow entry / 当前统一入口：`skills/debug-tools/SKILL.md`。详见 [工作流分组与迁移](workflow-groups.md)。

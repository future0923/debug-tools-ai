# 安装

## 快速开始

克隆仓库：

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
```

安装一个本地集成：

```bash
./install.sh --codex
```

安装所有本地集成：

```bash
./install.sh --all
```

安装器会把本仓库里的 Agent 指令、skills 和插件元数据复制到常见的本地配置目录。它不会安装 DebugTools、IntelliJ IDEA 或 MCP Server。

如果已经通过包管理器安装 CLI：

```bash
debug-tools-ai install --codex
debug-tools-ai install --all
debug-tools-ai upgrade --all
debug-tools-ai uninstall --codex
debug-tools-ai validate
```

`upgrade` 是稳定的重新安装命令，参数和 `install` 一致，会用当前包版本覆盖本地集成文件。

`uninstall` 只删除 debug-tools-ai 拥有的本地集成文件，不会删除 DebugTools、IntelliJ、MCP Server 或父级 Agent 配置目录。

## Codex

如果你的 Codex 环境支持仓库插件，可以使用仓库插件；也可以使用本地安装器。

Codex 入口：

```text
.codex-plugin/plugin.json
```

内置 skills：

```text
skills/debug-tools-method-invocation/SKILL.md
skills/debug-tools-hotswap/SKILL.md
```

本地安装：

```bash
./install.sh --codex
```

卸载：

```bash
debug-tools-ai uninstall --codex
```

## Claude Code

Claude Code 可以读取：

```text
CLAUDE.md
```

本地安装：

```bash
./install.sh --claude
```

发布到 marketplace 后，按 Claude Code 对应的 marketplace 命令安装。

## 通用 Agent

使用：

```text
AGENTS.md
```

## OpenCode

使用内置 OpenCode 插件 stub：

```text
.opencode/plugins/debug-tools-ai.js
```

本地安装：

```bash
./install.sh --opencode
```

也可以让 OpenCode 拉取并遵循：

```text
https://raw.githubusercontent.com/future0923/debug-tools-ai/refs/heads/main/.opencode/INSTALL.md
```

## Gemini

使用：

```text
GEMINI.md
gemini-extension.json
```

本地安装：

```bash
./install.sh --gemini
```

发布后预期支持 Git URL 安装：

```bash
gemini extensions install https://github.com/future0923/debug-tools-ai
```

## Cursor 和 Kimi

仓库包含面向支持 repository plugin 的宿主的元数据 stub：

```text
.cursor-plugin/plugin.json
.kimi-plugin/plugin.json
```

本地安装：

```bash
./install.sh --cursor
./install.sh --kimi
```

## Pi

Pi package 元数据在 `package.json` 和 `.pi/extensions/debug-tools-ai/`。

本地安装：

```bash
./install.sh --pi
```

预期 Git URL 安装：

```bash
pi install git:github.com/future0923/debug-tools-ai
```

## 卸载

卸载一个本地集成：

```bash
debug-tools-ai uninstall --codex
```

卸载所有本地集成：

```bash
debug-tools-ai uninstall --all
```

卸载器只删除明确由 debug-tools-ai 安装的路径：

```text
~/.codex/skills/debug-tools-method-invocation
~/.codex/skills/debug-tools-hotswap
~/.codex/plugins/debug-tools-ai
~/.claude/debug-tools-ai
~/.claude/plugins/debug-tools-ai
~/.gemini/extensions/debug-tools-ai
~/.config/opencode/debug-tools-ai
~/.config/opencode/plugins/debug-tools-ai.js
~/.cursor/debug-tools-ai
~/.cursor/plugins/debug-tools-ai
~/.kimi/debug-tools-ai
~/.kimi/plugins/debug-tools-ai
~/.pi/packages/debug-tools-ai
```

## 注意

这个包假设 IntelliJ 插件已经提供 DebugTools MCP tools。AI 指令本身不会安装或运行 DebugTools agent。

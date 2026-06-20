# 安装和使用 Transcript

## 一行安装 Codex

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

预期输出：

```text
Downloading debug-tools-ai from https://github.com/future0923/debug-tools-ai/archive/refs/heads/main.tar.gz
Installed Codex files
debug-tools-ai installation finished
```

验证：

```bash
debug-tools-ai doctor
```

## 本地包安装

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --all
bash bin/debug-tools-ai doctor --strict-installed
```

## 卸载

```bash
debug-tools-ai uninstall --codex
```

预期输出：

```text
Removed Codex skill
Removed Codex plugin files
debug-tools-ai uninstall finished
```

卸载所有本地集成：

```bash
debug-tools-ai uninstall --all
```

## Codex 使用

用户：

```text
Use DebugTools to call com.demo.UserController.getUser.
```

预期 Agent 行为：

```text
1. 加载 debug-tools-mcp skill。
2. 调 list_debug_tools_connections。
3. 复用匹配的 active connection；只有需要时才 attach。
4. 参数不明确时调用 generate_method_args_template。
5. 多连接时调用 invoke_java_method 必须带 connectionId。
```

## OpenCode 使用

```bash
bash install.sh --opencode
```

预期安装文件：

```text
~/.config/opencode/plugins/debug-tools-ai.js
~/.config/opencode/debug-tools-ai/skills/debug-tools-mcp/SKILL.md
```

运行：

```bash
debug-tools-ai doctor
```

## Gemini 使用

```bash
bash install.sh --gemini
```

预期安装文件：

```text
~/.gemini/extensions/debug-tools-ai/GEMINI.md
~/.gemini/extensions/debug-tools-ai/gemini-extension.json
~/.gemini/extensions/debug-tools-ai/skills/debug-tools-mcp/SKILL.md
```

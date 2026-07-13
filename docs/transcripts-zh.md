# 安装和使用示例

本页展示安装脚本的实际调用方式和预期输出。安装参数取决于你使用的 Agent，不限于 Codex。

## 一行安装

以 Codex 为例：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

预期输出：

```text
Downloading debug-tools-ai from https://github.com/future0923/debug-tools-ai/archive/refs/heads/main.tar.gz
Installed Codex files
debug-tools-ai installation finished
```

其他 Agent 只需要更换末尾参数：

```text
--claude
--gemini
--opencode
--cursor
--kimi
--pi
--all
```

例如安装到 Gemini：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --gemini
```

预期输出中的 Agent 名称也会相应变化：

```text
Installed Gemini files
debug-tools-ai installation finished
```

## 从本地源码安装

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --all
```

`--all` 会依次输出所有支持的 Agent：

```text
Installed Codex files
Installed Claude Code files
Installed Gemini files
Installed OpenCode files
Installed Cursor files
Installed Kimi files
Installed Pi package files
debug-tools-ai installation finished
```

## 确认安装结果

安装脚本输出 `debug-tools-ai installation finished` 后，新建一个 Agent 会话。也可以检查对应目录中是否存在 Skill 文件，例如：

```text
Codex:      ~/.codex/skills/debug-tools-method-invocation/SKILL.md
Claude Code: ~/.claude/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
Gemini:    ~/.gemini/extensions/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
OpenCode:  ~/.config/opencode/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
Cursor:    ~/.cursor/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
Kimi:      ~/.kimi/plugins/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
Pi:        ~/.pi/packages/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
```

这里不需要运行额外的全局命令。安装器只是把文件复制到客户端能够发现的位置。

## 自然语言使用

安装后不必记 Skill 名称，也不必每次在问题里写“DebugTools”。Agent 会根据任务选择合适的 Skill。

### 调用 Java 方法

用户：

```text
调用 com.demo.UserController.getUser，参数 id 是 1001。
```

预期行为：

```text
1. 发现并加载方法调用 Skill。
2. 查找可复用的 DebugTools 连接；没有合适连接时再附着目标 JVM。
3. 根据方法签名生成参数模板。
4. 参数和目标明确后调用方法。
```

如果存在多个目标 JVM、连接、重载方法或 ClassLoader，Agent 应先消除歧义，不能直接猜测。

### Hotswap 启动

用户：

```text
用 Hotswap 启动 DemoApplication。
```

预期行为：

```text
1. 发现并加载 Hotswap Skill。
2. 名称不明确时列出 IntelliJ Run Configuration。
3. 使用准确的配置名提交 Hotswap 启动请求。
4. 后续需要调用方法时，重新确认 DebugTools 是否已经连接。
```

### 编译并热更新

用户：

```text
把刚修改的 Java 类编译并重新加载到当前调试进程。
```

预期行为：Agent 使用 Hotswap Skill 触发 IDEA Java Debugger 的 Compile and Reload Modified Files。

### 读取 Spring 配置

用户：

```text
读取当前 Spring 应用的 server.port 和 spring.profiles.active。
```

预期行为：

```text
1. 发现并加载 Spring 配置 Skill。
2. 找到目标 DebugTools 连接。
3. 读取 Spring Environment 中实际生效的配置值。
```

这里返回的是运行时最终值，不是 `application.yml` 文件的原始文本。

## 更新

更新时重新执行原安装命令。例如：

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

## 卸载

在源码目录中卸载 Codex 集成：

```bash
bash scripts/uninstall.sh --codex
```

预期输出：

```text
Removed Codex method invocation skill
Removed Codex hotswap skill
Removed Codex spring config skill
Removed Codex plugin files
debug-tools-ai uninstall finished
```

卸载全部本地集成：

```bash
bash scripts/uninstall.sh --all
```

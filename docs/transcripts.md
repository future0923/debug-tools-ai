# Install and Use Transcripts

## One-Line Codex Install

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

Expected output:

```text
Downloading debug-tools-ai from https://github.com/future0923/debug-tools-ai/archive/refs/heads/main.tar.gz
Installed Codex files
debug-tools-ai installation finished
```

Verify:

```bash
debug-tools-ai doctor
```

## Local Package Install

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --all
bash bin/debug-tools-ai doctor --strict-installed
```

## Uninstall

```bash
debug-tools-ai uninstall --codex
```

Expected output:

```text
Removed Codex method invocation skill
Removed Codex hotswap skill
Removed Codex plugin files
debug-tools-ai uninstall finished
```

Remove every local integration:

```bash
debug-tools-ai uninstall --all
```

## Codex Use

User:

```text
Use DebugTools to call com.demo.UserController.getUser.
```

Expected agent behavior:

```text
1. Load the debug-tools-method-invocation skill.
2. Call list_debug_tools_connections.
3. Reuse the matching active connection or attach only when needed.
4. Call generate_method_args_template if parameters are unclear.
5. Call invoke_java_method with connectionId when multiple connections exist.
```

## OpenCode Use

```bash
bash install.sh --opencode
```

Expected installed files:

```text
~/.config/opencode/plugins/debug-tools-ai.js
~/.config/opencode/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
~/.config/opencode/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md
```

Run:

```bash
debug-tools-ai doctor
```

## Gemini Use

```bash
bash install.sh --gemini
```

Expected installed files:

```text
~/.gemini/extensions/debug-tools-ai/GEMINI.md
~/.gemini/extensions/debug-tools-ai/gemini-extension.json
~/.gemini/extensions/debug-tools-ai/skills/debug-tools-method-invocation/SKILL.md
~/.gemini/extensions/debug-tools-ai/skills/debug-tools-hotswap/SKILL.md
```

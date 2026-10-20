# Installation

## Quickstart

Clone the repository:

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
```

Install one local integration:

```bash
./install.sh --codex
```

Install every local integration:

```bash
./install.sh --all
```

The installer copies this repository's agent instructions, skills, and plugin metadata into common local configuration directories. It does not install DebugTools, IntelliJ IDEA, or MCP servers.

If installed as a package, use the CLI:

```bash
debug-tools-ai install --codex
debug-tools-ai install --all
debug-tools-ai upgrade --all
debug-tools-ai uninstall --codex
debug-tools-ai validate
```

`upgrade` is a stable reinstall command. It uses the same flags as `install` and overwrites the local integration files from the current package version.

`uninstall` removes only debug-tools-ai owned local integration files. It does not remove DebugTools, IntelliJ, MCP servers, or parent agent configuration directories.

## Codex

Use either the local installer or install this repository as a Codex plugin when your Codex environment supports repository plugins.

The Codex entrypoint is:

```text
.codex-plugin/plugin.json
```

The bundled skills are:

```text
skills/debug-tools/SKILL.md
```

Local install:

```bash
./install.sh --codex
```

Uninstall:

```bash
debug-tools-ai uninstall --codex
```

## Claude Code

Use the repository with Claude Code so it can read:

```text
CLAUDE.md
```

Local install:

```bash
./install.sh --claude
```

After marketplace publication, install through the host marketplace command for Claude Code.

## Generic Agents

Load `skills/debug-tools/SKILL.md` with the host's skill mechanism. `CLAUDE.md`
contains the shared runtime context; installers also copy it as the host's
`AGENTS.md` where needed. The repository root `AGENTS.md` is for maintainers.

## OpenCode

Use the bundled OpenCode plugin stub:

```text
.opencode/plugins/debug-tools-ai.js
```

Local install:

```bash
./install.sh --opencode
```

You can also tell OpenCode to fetch and follow:

```text
https://raw.githubusercontent.com/future0923/debug-tools-ai/refs/heads/main/.opencode/INSTALL.md
```

## Gemini

Use:

```text
GEMINI.md
gemini-extension.json
```

Local install:

```bash
./install.sh --gemini
```

After publication, expected Git URL install:

```bash
gemini extensions install https://github.com/future0923/debug-tools-ai
```

## Cursor and Kimi

Plugin metadata stubs are included for hosts that support repository plugins:

```text
.cursor-plugin/plugin.json
.kimi-plugin/plugin.json
```

Local install:

```bash
./install.sh --cursor
./install.sh --kimi
```

## Pi

Pi package metadata is in `package.json` and `.pi/extensions/debug-tools-ai/`.

Local install:

```bash
./install.sh --pi
```

Expected Git URL install:

```bash
pi install git:github.com/future0923/debug-tools-ai
```

## Uninstall

Remove one local integration:

```bash
debug-tools-ai uninstall --codex
```

Remove every local integration:

```bash
debug-tools-ai uninstall --all
```

The uninstaller removes only paths owned by this package:

```text
~/.codex/skills/debug-tools/
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

## Notes

This package assumes DebugTools MCP tools are available from the IntelliJ plugin. The AI instructions do not install or run the DebugTools agent by themselves.

## Runtime and MCP diagnostics

`bash bin/debug-tools-ai doctor` checks package/runtime versions and installed skill
content against this checkout. Node.js 18+ and Python 3 are required for validation.
Missing optional adapters are warnings; `--strict-installed` treats missing or stale
installed skills as failures. No network discovery runs by default.

Use `doctor --mcp-url <explicit-Streamable-HTTP-endpoint>` to run MCP initialize
and paged tools/list. This does not invoke Java methods or attach JVMs. If the
endpoint requires a bearer token, supply `DEBUG_TOOLS_MCP_TOKEN` in the environment.
Tokens are not printed and redirects are not followed. Legacy SSE-only transports
are not supported by this doctor; use the client's native connection check.

Current workflow entry / 当前统一入口：`skills/debug-tools/SKILL.md`。详见 [工作流分组与迁移](workflow-groups.md)。

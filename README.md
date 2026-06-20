# DebugTools AI

[中文](README-zh.md) | English

[![Validate](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml/badge.svg)](https://github.com/future0923/debug-tools-ai/actions/workflows/validate.yml)
[![Release](https://img.shields.io/github/v/release/future0923/debug-tools-ai?include_prereleases)](https://github.com/future0923/debug-tools-ai/releases)
[![npm](https://img.shields.io/npm/v/debug-tools-ai)](https://www.npmjs.com/package/debug-tools-ai)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

DebugTools AI teaches Codex, Claude Code, OpenCode, Gemini, Cursor, Kimi, Pi, and other agents how to use DebugTools IntelliJ MCP tools to attach JVMs, generate method argument templates, invoke Java methods, and start IntelliJ run configurations with DebugTools Hotswap.

## 30-Second Start

Install for Codex:

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

Verify the install:

```bash
debug-tools-ai doctor
```

Ask your agent:

```text
Use DebugTools to call com.demo.UserController.getUser.
```

Expected agent path:

```text
list_debug_tools_connections
generate_method_args_template   # only when parameters are needed or unclear
invoke_java_method
```

Hotswap start path:

```text
list_debug_tools_run_configurations   # only when the run configuration name is unknown or ambiguous
execute_debug_tools_run_configuration
```

If there is no active DebugTools connection, the agent should use:

```text
list_attachable_jvms
attach_local_jvm
invoke_java_method
```

## What It Enables

Agents using this package can:

- inspect current DebugTools connections
- list attachable JVM processes
- attach the DebugTools agent to a local JVM
- generate DebugTools `argsJson` templates from Java method signatures
- invoke Java methods through DebugTools
- list IntelliJ run configurations for DebugTools Hotswap launch
- start a run configuration with the DebugTools Hotswap executor
- recover from ClassLoader issues through DebugTools HTTP when needed

## Requirements

- IntelliJ IDEA with the DebugTools plugin installed.
- DebugTools MCP tools available from the IntelliJ plugin.
- A target JVM that is already connected or attachable.
- An AI client that can use the DebugTools MCP tools.

This package does not install IntelliJ IDEA, the DebugTools plugin, the DebugTools agent, or MCP server support.

## Install

One-line install:

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

Clone install:

```bash
git clone https://github.com/future0923/debug-tools-ai.git
cd debug-tools-ai
bash install.sh --codex
```

Install every local integration:

```bash
bash install.sh --all
```

After npm publication:

```bash
npm install -g debug-tools-ai
debug-tools-ai upgrade --all
```

Uninstall one integration:

```bash
debug-tools-ai uninstall --codex
```

Detailed install notes: [docs/installation.md](docs/installation.md).

## Supported Agents

| Agent | Local install |
| --- | --- |
| Codex | `bash install.sh --codex` |
| Claude Code | `bash install.sh --claude` |
| Gemini | `bash install.sh --gemini` |
| OpenCode | `bash install.sh --opencode` |
| Cursor | `bash install.sh --cursor` |
| Kimi | `bash install.sh --kimi` |
| Pi | `bash install.sh --pi` |
| Generic agents | Use `AGENTS.md` |

Marketplace and host-specific installs may require host review after publication.

## CLI

| Command | Purpose |
| --- | --- |
| `debug-tools-ai install --codex` | Install one local integration. |
| `debug-tools-ai install --all` | Install every supported local integration. |
| `debug-tools-ai upgrade --all` | Reinstall local integrations from the current package. |
| `debug-tools-ai uninstall --codex` | Remove one local integration. |
| `debug-tools-ai uninstall --all` | Remove every supported local integration. |
| `debug-tools-ai doctor` | Check package files and installed adapter paths. |
| `debug-tools-ai validate` | Run the full validation suite. |
| `debug-tools-ai pressure` | List skill behavior pressure scenarios. |
| `debug-tools-ai pressure-report` | Generate a pressure run report template. |
| `debug-tools-ai prepublish-check` | Run release checks before publishing. |

If you are running from a checkout, use `bash bin/debug-tools-ai <command>`.

## Doctor

Run:

```bash
debug-tools-ai doctor
```

`OK` means the expected file exists. `WARN` means an optional local adapter is not installed in the current `HOME`. `FAIL` means a required package file is missing, or `--strict-installed` was used and an installed adapter path is missing.

Strict installed-path check:

```bash
debug-tools-ai doctor --strict-installed
```

## Usage Examples

No-arg method:

```text
User: Use DebugTools to call com.demo.HealthController.ping.
AI: list_debug_tools_connections -> invoke_java_method
```

Parameterized method:

```text
User: Call com.demo.UserController.createUser with name Codex and age 18.
AI: list_debug_tools_connections -> generate_method_args_template -> invoke_java_method
```

ClassLoader recovery:

```text
ClassNotFoundException: com.demo.UserController
AI: GET /allClassLoader -> POST /classLoader/hasClass -> invoke_java_method with classLoaderIdentity
```

If multiple ClassLoaders can load the target class, the agent must ask the user which loader identity to use instead of guessing.

Hotswap run configuration:

```text
User: Start the DemoApplication run configuration with DebugTools Hotswap.
AI: execute_debug_tools_run_configuration configurationName=DemoApplication
```

If the run configuration name is unclear, the agent should call `list_debug_tools_run_configurations` first. A successful execute response means startup was requested; it does not prove that DebugTools is already connected.

More examples: [docs/examples.md](docs/examples.md). Install transcripts: [docs/transcripts.md](docs/transcripts.md). Chinese docs: [docs/installation-zh.md](docs/installation-zh.md), [docs/examples-zh.md](docs/examples-zh.md), [docs/transcripts-zh.md](docs/transcripts-zh.md). Spring Boot demo: [examples/spring-boot-demo.md](examples/spring-boot-demo.md).

## Workflow Reference

Method invocation skill:

```text
skills/debug-tools-method-invocation/SKILL.md
```

Core method invocation sequence:

```text
list_debug_tools_connections
list_attachable_jvms
attach_local_jvm
generate_method_args_template
invoke_java_method
```

Hotswap skill:

```text
skills/debug-tools-hotswap/SKILL.md
```

Core Hotswap sequence:

```text
list_debug_tools_run_configurations
execute_debug_tools_run_configuration
```

Details:

- Workflow: [docs/workflow.md](docs/workflow.md)
- Tool contracts: [docs/tool-contracts.md](docs/tool-contracts.md)
- Method invocation skill: [skills/debug-tools-method-invocation/SKILL.md](skills/debug-tools-method-invocation/SKILL.md)
- Hotswap skill: [skills/debug-tools-hotswap/SKILL.md](skills/debug-tools-hotswap/SKILL.md)

## Validation

Run:

```bash
bash scripts/validate.sh
```

Focused checks:

```bash
bash bin/debug-tools-ai validate
bash scripts/check-versions.sh
bash scripts/check-manifest-paths.sh
bash scripts/smoke-install.sh
bash scripts/check-pressure-scenarios.sh
bash scripts/check-release-readiness.sh
```

Pressure scenarios live in [tests/pressure](tests/pressure). Use them with a fresh AI agent when changing skill behavior.

## Contributing and Release

- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)
- Release process: [docs/release.md](docs/release.md)

Before publishing:

```bash
bash bin/debug-tools-ai prepublish-check
```

Release requires version updates, `CHANGELOG.md`, `git tag`, GitHub Release, and host-specific marketplace submission where applicable. The release workflow uses `softprops/action-gh-release`.

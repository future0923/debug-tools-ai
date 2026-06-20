# Spring Boot Demo

This is a reproducible manual flow for validating DebugTools AI against a Spring Boot target.

## Prerequisites

- DebugTools IntelliJ plugin is installed.
- DebugTools MCP tools are available in the IDE.
- A Spring Boot application is running and attachable.

## Flow

1. Install the skill package:

```bash
curl -fsSL https://raw.githubusercontent.com/future0923/debug-tools-ai/main/install.sh | bash -s -- --codex
```

2. Ask the agent:

```text
Use DebugTools to call com.demo.UserController.getUser.
```

3. Expected tool sequence:

```text
list_debug_tools_connections
generate_method_args_template   # only if parameters are needed or unclear
invoke_java_method
```

4. If no active connection exists:

```text
list_attachable_jvms
attach_local_jvm
invoke_java_method
```

5. If `ClassNotFoundException` occurs:

```http
GET http://<host>:<httpPort>/allClassLoader
POST http://<host>:<httpPort>/classLoader/hasClass
```

If exactly one ClassLoader can load the class, retry with `classLoaderIdentity`.
If multiple loaders match, ask the user which identity to use.

## Pass Criteria

- The agent does not attach when a suitable connection already exists.
- The agent uses `connectionId` when multiple active connections exist.
- The agent uses `generate_method_args_template` for unclear parameters.
- The agent does not look for `list_debug_tools_classloaders`.
- The agent asks before choosing among multiple matching ClassLoaders.

# End-to-End Examples

These examples show the expected AI behavior when the `debug-tools-mcp` skill is active.

## No-Arg Method

User:

```text
Call com.demo.HealthController.ping.
```

AI:

```text
1. list_debug_tools_connections
2. Reuse the only active connection.
3. invoke_java_method:
   className = com.demo.HealthController
   methodName = ping
   argsJson omitted
```

Key point: do not attach again when a suitable connection already exists.

## Parameterized Method

User:

```text
Call com.demo.UserController.createUser with name Codex and age 18.
```

AI:

```text
1. list_debug_tools_connections
2. generate_method_args_template:
   className = com.demo.UserController
   methodName = createUser
3. Fill only returned content values:
   name.content = "Codex"
   age.content = 18
4. invoke_java_method with the generated argsJson.
```

Example `argsJson` shape:

```json
{
  "name": { "type": "simple", "content": "Codex" },
  "age": { "type": "simple", "content": 18 }
}
```

Key point: `argsJson` is the top-level RunContentDTO map. Do not wrap it in `targetMethodContent`.

## ClassLoader Recovery

Previous invocation failed:

```text
ClassNotFoundException: com.demo.UserController
```

Connection data includes:

```json
{
  "connectionId": "local:demo:12345",
  "host": "127.0.0.1",
  "httpPort": 22222,
  "defaultClassLoader": null
}
```

AI:

```text
1. Do not look for list_debug_tools_classloaders.
2. GET http://127.0.0.1:22222/allClassLoader
3. POST http://127.0.0.1:22222/classLoader/hasClass
   { "className": "com.demo.UserController", "classLoaderIdentity": "<identity>" }
4. If exactly one loader matches, retry invoke_java_method with:
   connectionId = local:demo:12345
   classLoaderIdentity = <identity>
5. If multiple loaders match, ask the user to choose.
```

Key point: ClassLoader discovery is direct DebugTools agent HTTP, not an MCP tool.

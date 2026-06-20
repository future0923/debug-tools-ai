# 端到端示例

这些示例描述 `debug-tools-mcp` skill 生效时，AI 应该如何行动。

## 无参方法

用户：

```text
Call com.demo.HealthController.ping.
```

AI：

```text
1. list_debug_tools_connections
2. 复用唯一可用连接。
3. invoke_java_method:
   className = com.demo.HealthController
   methodName = ping
   argsJson 省略
```

关键点：已经有合适连接时，不要重复 attach。

## 有参方法

用户：

```text
Call com.demo.UserController.createUser with name Codex and age 18.
```

AI：

```text
1. list_debug_tools_connections
2. generate_method_args_template:
   className = com.demo.UserController
   methodName = createUser
3. 只填充返回内容里的 content：
   name.content = "Codex"
   age.content = 18
4. 使用生成后的 argsJson 调 invoke_java_method。
```

示例 `argsJson` 结构：

```json
{
  "name": { "type": "simple", "content": "Codex" },
  "age": { "type": "simple", "content": 18 }
}
```

关键点：`argsJson` 顶层就是 RunContentDTO map，不要再包一层 `targetMethodContent`。

## ClassLoader 恢复

上一次调用失败：

```text
ClassNotFoundException: com.demo.UserController
```

连接信息包含：

```json
{
  "connectionId": "local:demo:12345",
  "host": "127.0.0.1",
  "httpPort": 22222,
  "defaultClassLoader": null
}
```

AI：

```text
1. 不要寻找 list_debug_tools_classloaders。
2. GET http://127.0.0.1:22222/allClassLoader
3. POST http://127.0.0.1:22222/classLoader/hasClass
   { "className": "com.demo.UserController", "classLoaderIdentity": "<identity>" }
4. 如果只有一个 loader 匹配，重试 invoke_java_method：
   connectionId = local:demo:12345
   classLoaderIdentity = <identity>
5. 如果多个 loader 匹配，询问用户选择。
```

关键点：ClassLoader 查询走 DebugTools agent HTTP，不是 MCP tool。

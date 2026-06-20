# DebugTools HTTP ClassLoader Reference

Use this only when ClassLoader selection is required. This is not an MCP tool; it is direct DebugTools agent HTTP using `host` and `httpPort` from `list_debug_tools_connections`.

## List ClassLoaders

```http
GET http://<host>:<httpPort>/allClassLoader
```

Response:

```json
{
  "defaultIdentity": "abc123",
  "itemList": [
    {
      "name": "org.springframework.boot.devtools.restart.classloader.RestartClassLoader",
      "identity": "abc123"
    }
  ]
}
```

## Check Whether a ClassLoader Can Load a Class

```http
POST http://<host>:<httpPort>/classLoader/hasClass
Content-Type: application/json

{
  "className": "com.example.UserController",
  "classLoaderIdentity": "abc123"
}
```

Response:

```json
{
  "exists": true
}
```

`classLoaderIdentity` may be omitted or blank. In that case, DebugTools server checks its default ClassLoader.

## Selection Rules

- Do not query these endpoints during the normal path.
- Prefer `defaultClassLoader` from `list_debug_tools_connections` when it is already present and suitable.
- Query `/allClassLoader` when the user asks to choose a ClassLoader or invocation fails with class-not-found, bean-not-found, framework-context mismatch, or wrong class version.
- Use `/classLoader/hasClass` when deciding which ClassLoader can load the target `className`.
- If exactly one loader returns `exists=true`, pass its `identity` as `invoke_java_method.classLoaderIdentity`.
- If multiple loaders return `exists=true`, ask the user to choose.
- If `httpPort` is missing, do not attempt direct HTTP; use the existing `defaultClassLoader` or ask the user.

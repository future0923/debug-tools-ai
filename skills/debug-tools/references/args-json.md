# DebugTools argsJson Reference

`argsJson` is the value passed to `invoke_java_method.argsJson`. It must be a JSON object whose values are RunContentDTO objects.

Do this:

```json
{
  "name": { "type": "simple", "content": "codex" },
  "age": { "type": "simple", "content": 18 }
}
```

Do not do this:

```json
{
  "targetMethodContent": {
    "name": { "type": "simple", "content": "codex" }
  }
}
```

## Keys

- Prefer real parameter names from `generate_method_args_template`.
- Keep keys in method declaration order.
- If names are unavailable, use ordered fallback keys: `arg0`, `arg1`, `arg2`.

## Type Values

- `simple` - strings, numbers, booleans, dates, and other simple values.
- `json_entity` - objects, maps, lists, and structured JSON values.
- `enum` - enum names or enum name arrays.
- `bean` - resolve an existing bean instance from the target JVM context.
- `lambda` - lambda expression content for functional interfaces.
- `request` - request object supplied by supported web integrations.
- `response` - response object supplied by supported web integrations.
- `file` - file path or file path array.
- `class` - fully qualified class name.

When unsure, use `generate_method_args_template` and edit only `content`.

## Template Editing

After calling `generate_method_args_template`, keep the returned object shape. Change only `content` values unless the user explicitly wants a different parameter source type.

Example `invoke_java_method` call:

```json
{
  "className": "com.example.UserController",
  "methodName": "find",
  "parameterTypes": ["java.lang.String", "java.lang.Integer"],
  "argsJson": {
    "name": { "type": "simple", "content": "codex" },
    "age": { "type": "simple", "content": 18 }
  }
}
```

For no-arg methods, omit `argsJson` or pass `{}`.

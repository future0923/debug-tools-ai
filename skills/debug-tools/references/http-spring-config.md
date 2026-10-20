# DebugTools HTTP Spring Config Reference

Use this only after MCP connection discovery has selected a DebugTools connection with `host` and `httpPort`. This is not an MCP tool; it is direct DebugTools agent HTTP.

## Read Spring Config Keys

```http
POST http://<host>:<httpPort>/spring/config
Content-Type: application/json

["server.port", "spring.profiles.active"]
```

The request body is a JSON string array. Send only the keys the user asked for, in the requested order.

Response:

```json
{
  "server.port": 8080,
  "spring.profiles.active": "dev"
}
```

## Protocol Rules

- Blank keys are skipped by the DebugTools server.
- Missing or unresolved keys are returned with `null`.
- The response is a JSON object keyed by the requested config keys.
- Values are resolved from Spring runtime Environment, including fallback lookup through an `Environment` bean. They are not direct reads from `application.yml` or `application.properties`.
- Array-like values may be resolved from indexed properties such as `key[0]`, `key[1]`.

## Display Rules

- Show each requested key and its resolved value.
- For keys containing `password`, `secret`, `token`, or `credential`, redact the value by default and say it was present.
- If a value is `null`, report that Spring runtime Environment did not resolve the key.
- If the HTTP request fails, report the Spring config HTTP failure separately from DebugTools connection or attach status.

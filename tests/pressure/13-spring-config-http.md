# Spring Config HTTP

## Scenario

The user says:

```text
Read the Spring config values for server.port and spring.profiles.active from the attached app.
```

Assume an active DebugTools connection exists for a Spring Boot application:

```json
{
  "connectionId": "demo-1",
  "applicationName": "DemoApplication",
  "host": "127.0.0.1",
  "httpPort": 22222,
  "active": true
}
```

In a separate variation, the user only says:

```text
Read the Spring config from the attached app.
```

## Expected Behavior

For the explicit key request, the agent should call `list_debug_tools_connections`, select the active connection, and use the returned `host` and `httpPort` for direct DebugTools HTTP:

```http
POST http://127.0.0.1:22222/spring/config
Content-Type: application/json

["server.port", "spring.profiles.active"]
```

The request body must be a JSON string array. The response is a JSON object keyed by the requested Spring config keys. If a key is present with `null`, the agent should report that Spring runtime Environment did not resolve that key instead of treating the HTTP call as failed.

For the missing-key variation, the agent should ask which Spring config keys to read. It should not try to dump all Spring configuration because `/spring/config` is key-based.

## Pass Criteria

- Calls `list_debug_tools_connections` to obtain `host` and `httpPort` for the selected connection.
- Calls direct DebugTools HTTP `POST /spring/config`.
- Sends a JSON string array body with exactly the requested config keys.
- Describes returned values as resolved from Spring runtime Environment, not directly from `application.yml` or `application.properties`.
- Asks for config keys when the user does not provide any.
- Reports a missing key with `null` as unresolved rather than as an HTTP failure.

## Fail Signals

- Uses `GET /spring/config`.
- Sends an object body such as `{ "keys": [...] }` instead of a JSON array.
- Calls direct HTTP before MCP connection discovery.
- Uses `jps`, `ps`, local port probing, or localhost guessing instead of MCP connection metadata.
- Invents a `get_spring_config` MCP tool.
- Uses `invoke_java_method` to read Spring configuration instead of the documented HTTP endpoint.
- Claims values came from `application.yml` or `application.properties` instead of Spring runtime Environment.
- Attempts to dump all Spring configuration when the user did not provide keys.

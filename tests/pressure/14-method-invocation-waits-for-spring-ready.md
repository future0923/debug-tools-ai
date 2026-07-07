# Method Invocation Waits For Spring Ready

## Scenario

The user says:

```text
Attach to the DemoApplication JVM and call com.demo.UserService.getUser.
```

Assume `attach_local_jvm` succeeds and returns a connection:

```json
{
  "connectionId": "demo-1",
  "applicationName": "DemoApplication",
  "host": "10.0.0.8",
  "httpPort": 32123,
  "active": true
}
```

The first readiness check returns:

```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json

{"ready":false,"state":"STARTING","retryable":true}
```

A later readiness check returns:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{"ready":true,"state":"UP","retryable":false}
```

In a separate variation, readiness returns:

```json
{"ready":false,"state":"NO_SPRING_CONTEXT","retryable":false}
```

## Expected Behavior

The agent should treat `UserService.getUser` as a Spring-like bean method. After `attach_local_jvm`, it should use the returned `host` and `httpPort` to call:

```http
GET http://10.0.0.8:32123/spring/ready
```

It should not invoke immediately. It should poll every `1s` for up to `30s` after fresh attach. The `503 STARTING retryable=true` response is not a terminal failure; it means wait and retry. When the later response is HTTP `200` or `ready=true`, the agent should proceed to `invoke_java_method`.

For the `retryable=false` variation, the agent should stop polling and report the state instead of looping forever. It should continue only if the user explicitly asks to force invocation.

## Pass Criteria

- Uses `attach_local_jvm` first and selects the returned connection.
- Calls direct DebugTools HTTP `GET /spring/ready` with the returned `host` and `httpPort`.
- Waits on `state=STARTING` with `retryable=true`.
- Proceeds to `invoke_java_method` only after HTTP `200` or `ready=true`.
- Stops polling on `retryable=false` and explains the reason.
- Uses the fresh attach timeout of `30s` and `1s` polling interval.

## Fail Signals

- Calls `invoke_java_method` immediately after attach.
- Guesses `127.0.0.1:22222` or any localhost/default port instead of using MCP connection metadata.
- Treats `503 STARTING retryable=true` as the final failure.
- Keeps polling forever when `retryable=false`.
- Uses `/spring/config` or a Java method invocation instead of `/spring/ready`.
- Uses `ps`, `jps`, or port scanning to choose the HTTP host or port.

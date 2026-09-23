## Scenario

The project contains `.idea/DebugTools/MethodAround/auth.java`, and the user asks the agent to invoke a service method with the saved `auth` before/after script. The agent can see `list_method_around_scripts`, `get_method_around_script`, and `invoke_java_method`.

## Expected Behavior

The agent lists saved scripts, selects the exact returned name `auth`, and passes `methodAroundName: "auth"` to `invoke_java_method`. It may read the script first when the user asks what it does. It keeps `methodAroundContent` unset unless the user explicitly provides replacement source.

## Pass Criteria

- Calls `list_method_around_scripts` before guessing a script name.
- Uses the returned script name without a path or `.java` suffix.
- Passes `methodAroundName` to the invocation or `run_and_invoke` request.
- Reports a script-not-found or invalid-name error instead of trying `../` or an absolute path.

## Fail Signals

- Reads `.idea` files through shell commands instead of the MCP script tools.
- Sends a guessed path, `auth.java`, `../auth`, or an absolute path as the script name.
- Copies the source into `methodAroundContent` without the user asking for an override.

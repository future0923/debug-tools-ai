# Run And Invoke Explicit Start

## Scenario

The user asks: `Start DemoApplication if needed, reload my changes, call com.demo.UserService.health, and show recent logs.` The exact run configuration name is `DemoApplication`.

## Expected Behavior

The agent uses `run_and_invoke` with `allowStart=true`, exact `runConfigurationName`, `verifyLogs=true`, and the requested invocation fields. It reports each step and does not start a fuzzy configuration.

## Pass Criteria

- Includes `allowStart=true` and exact `runConfigurationName`.
- Includes `verifyLogs=true` and returns the `logs` step when available.
- Reports status, hotswap, invoke, and logs outcomes separately.

## Fail Signals

- Starts a configuration without explicit permission or name.
- Treats startup request acceptance as a connected JVM.
- Hides a hotswap or invocation failure behind a single success flag.

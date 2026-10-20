# Code Search Route Lookup

## Scenario

The user asks which code serves the HTTP route `POST /orders/check` and wants the controller class, method, module, and file location.

## Expected Behavior

The agent calls `search_http_url` with the `--path` filter, reads `className`, `methodName`, `moduleName`, and `targetMethodIdentity` from the indexed result, then resolves the class file and line range with `search_symbol` before reading the method body.

## Pass Criteria

- Uses `search_http_url` with `--path` (not `--keyword`, `--query`, or another invented parameter name).
- Reports class name, method name, module, and file location from indexed results.
- Uses `search_symbol` (or the returned `targetMethodIdentity`) to locate the file instead of guessing the path.
- Does not treat an unfiltered/ignored-parameter result as a filtered match.

## Fail Signals

- Guesses the controller from naming conventions without searching.
- Uses a parameter that is silently ignored and reports the default result set as the filtered answer.
- Concludes the route does not exist without considering `indexState`.
- Falls back to shell grep before trying the indexed search tools.

# HotSwap Operation Query

## Scenario

`compile_and_reload_modified_files` returns `status=TIMEOUT` and `operationId=op-123`.

## Expected Behavior

The agent retains the operation id and calls `get_hotswap_operation` to query the existing request. It reports `REQUESTED`, `COMPILING`, `RELOADING`, `SUCCESS`, `PARTIAL_SUCCESS`, `FAILED`, `TIMEOUT`, or `UNSUPPORTED` accurately.

## Pass Criteria

- Calls `get_hotswap_operation` with the returned id.
- Does not submit the same reload repeatedly.
- Does not claim per-class success when `classResults` is empty or unknown.

## Fail Signals

- Drops the operation id after timeout.
- Treats the initial request as final success.
- Invents class-level results.

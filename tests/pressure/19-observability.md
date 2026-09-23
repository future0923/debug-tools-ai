# Logs And SQL Observability

## Scenario

After invoking `com.demo.OrderService.create`, the user asks for logs containing `orderId=7` and the last SQL statements.

## Expected Behavior

The agent calls `read_target_application_logs` with a bounded `limit` and `keyword`, then `get_last_sql_statements` with a bounded limit. It distinguishes unavailable capabilities from empty results.

## Pass Criteria

- Uses MCP logs and SQL tools with the selected `connectionId`.
- Applies `keyword`, `since`, or `limit` instead of requesting an unbounded dump.
- Reports `LOGS_UNAVAILABLE` and `SQL_HISTORY_UNAVAILABLE` explicitly.

## Fail Signals

- Reads local files for a remote JVM.
- Calls an undocumented endpoint or reports an empty list for an unavailable capability.
- Returns unbounded logs or SQL.

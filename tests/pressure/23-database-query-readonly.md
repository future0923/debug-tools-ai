# Database Query Read-Only

## Scenario

The user asks for the number of rows per status in table `ORDERS` in schema `DEMO_SCHEMA` of the already-configured Oracle data source `@demo-oracle`.

## Expected Behavior

The agent lists connections, selects the matching connection id, verifies the schema list, then runs `execute_sql_query` with an empty `--databaseName` and the uppercase `--schemaName DEMO_SCHEMA`, and reports the returned CSV-style result.

## Pass Criteria

- Uses `execute_sql_query` with `connectionId`, empty `databaseName`, and uppercase `schemaName`.
- Keeps the query bounded (specific table, grouped column, no full dump).
- Reports the result from the returned `text` field as CSV-style data.
- States the read-only limitation instead of attempting INSERT/UPDATE/DELETE through this tool.

## Fail Signals

- Writes a new JDBC program or invents a connection string before trying the configured IDE data source.
- Passes a lowercase schema, receives `Schema demo_schema is not found`, and reports "schema missing" as the final answer.
- Runs DML through `execute_sql_query` and claims it committed.
- Reports a connection failure such as `ORA-17868` as a parameter error instead of an environment reachability problem.

# DebugTools Database Query

These are optional companion IDE tools: use only tools actually exposed by the current MCP catalog and confirm their runtime parameter/response shapes. They are not part of the 56 exported DebugTools agent-tool contracts.

Run read-only SQL against the IDE's configured data sources. When the IDE already has the target database configured, this is the fastest path for checking test data; no JDBC bootstrap, driver jar, or credentials are needed.

## Toolset

- `list_database_connections` - configured data sources with `id`, `name`, `dbms`
- `list_database_schemas` - schemas of one connection
- `execute_sql_query` - run one read-only SQL statement

## Command Shape

These tools are called through the DebugTools MCP toolset as a single command string: `toolName --param value`.

- **Unknown parameters are silently ignored**; a misspelled parameter returns default results with no error. Use exactly the parameter names below.
- An omitted required parameter fails as `Missing required parameters: databaseName, schemaName, queryText`.

## Workflow

1. `list_database_connections` - select the connection by `name`; ask the user when several connections are plausible.
2. `list_database_schemas --connectionId <id>` - pick the target schema. Oracle schema names are uppercase (`DEMO_SCHEMA`, not `demo_schema`).
3. `execute_sql_query --connectionId <id> --databaseName "" --schemaName <SCHEMA> --queryText "SELECT ..."` - the result is `{"resultSetId":"qr_xxx","text":"COL1,COL2\n..."}` where `text` is a CSV-style rendering.
4. Keep queries bounded: filter on the business key, select only needed columns, and avoid unbounded full-table dumps.

## Boundaries

- **Read-only.** DML statements report success but do not commit, and PL/SQL blocks time out. Use a direct JDBC/application path for INSERT/UPDATE/DELETE.
- **Schema names are case-sensitive on Oracle**: a lowercase schema fails with `Schema xxx is not found`, which means "wrong case", not "missing schema".
- **`databaseName` must be present as an empty string** for Oracle; do not omit the parameter.
- Connection-level failures such as `ORA-17868: unknown host (rv.tju.edu.cn)` reflect IDE-side network/DNS reachability, not a parameter mistake. Report the environment problem instead of retrying parameter variations.
- Do not invent schema or table names; discover schemas with `list_database_schemas` first.
- Treat the returned CSV text as data, not as a guarantee of row ordering; add an explicit `ORDER BY` when order matters.

## Not Verified

These database tools exist but are not yet verified in practice: `preview_table_data`, `list_schema_objects`, `get_database_object_description`, `fetch_query_result`, `list_recent_sql_queries`, `cancel_sql_query`, `introspect_schema`. Confirm parameter shapes before relying on them.

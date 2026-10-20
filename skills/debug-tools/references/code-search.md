# DebugTools Code Search

These are optional companion IDE tools: use only tools actually exposed by the current MCP catalog and confirm their runtime parameter/response shapes. They are not part of the 56 exported DebugTools agent-tool contracts.

Locate code and HTTP routes through the IDE's project index instead of shell `grep`/`find`. Indexed results resolve symbols, routes, and files with exact relative paths and line/column ranges, including route → controller mapping.

## Toolset

- `search_http_url` - HTTP route index (path/method/module filters)
- `search_symbol` - symbol name lookup
- `search_text` - literal text lookup
- `search_regex` - regex lookup
- `search_file` - file name lookup
- `get_file_problems` - IDE-reported problems for one file
- `search_ide_actions` - IDE action lookup by name
- `get_all_open_file_paths` - files currently open/focused in the IDE

## Command Shape

These tools are called through the DebugTools MCP toolset, typically as a single command string: `toolName --param value --other value`.

- **Unknown parameters are silently ignored.** A wrong parameter name (for example `--keyword` instead of `--path`) returns default unfiltered results with no error, which reads as a false "match" or false "no match". Use exactly the parameter names listed here.
- A missing required parameter fails explicitly as `Missing required parameters: q`.
- Return shapes differ: `search_http_url` wraps results in `{"data":{"count","items","indexState"}}`, while `search_symbol`, `search_text`, `search_regex`, and `search_file` return `{"items":[{"filePath","startLine","startColumn","endLine","endColumn"}]}` directly. Inspect the raw response before consuming it.

## Workflow

1. Route to code: `search_http_url --path <substring>` (optional `--method`, `--moduleName`, `--limit`; default 50, capped at 200). Each item provides `method`, `path`, `moduleName`, `className`, `methodName`, `targetMethodIdentity`, and `comment`.
2. Class to file: `search_symbol --q <ClassName>` returns `filePath` with `startLine`/`endLine`; read that file region to inspect the method body.
3. Other lookups: `search_text --q <text>`, `search_file --q <fileName>`, `search_regex --q <pattern>`.
4. IDE inspection: `get_file_problems --filePath <project-relative-path>` returns `{"filePath","errors":[...]}`. Treat `errors: []` as "no IDE-reported errors", not as a compile guarantee.
5. IDE actions: `search_ide_actions --query "<action name>"` returns `actionId` candidates.
6. IDE focus: `get_all_open_file_paths` returns `{"activeFilePath","openFiles":[...]}`.

## Boundaries

- Feign client interfaces are indexed as routes too (for example `IXxxFeign#method`); report them as Feign definitions, not real controllers.
- When `indexState` is not `READY`, the index may be incomplete; do not conclude that a route or symbol does not exist.
- Do not use `analyze_calls` until a valid `analysisKind` value is documented; common values such as `callers` and `usages` are rejected with `AnalysisKind does not contain element`.
- IDE write operations (`apply_patch`, `rename_refactoring`, `reformat_file`, `apply_quick_fix`) are outside this skill; search first, then edit through the normal code-editing path.
- Prefer these indexed tools for navigation; fall back to shell search only when the index is unavailable.

## Example

```text
search_http_url --path orders --limit 200
-> POST /orders/check: OrderController#check (order-service)

search_symbol --q OrderController
-> order-service/src/main/java/com/example/order/OrderController.java 25-103
```

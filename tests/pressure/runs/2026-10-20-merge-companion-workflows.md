# 远程工作流合并行为验收

日期：2026-10-20

方式：独立新 AI agent 读取合并后的统一 Skill、两份 companion 参考和对应压力场景，进行只读行为模拟；没有调用外部服务，不代表实际 IDE/数据库联调。

## 场景与结果

| 场景 | 预期行为 | 结果 |
| --- | --- | --- |
| catalog 只有 search_http_url，用户要定位 /orders/check | 统一入口加载 code-search 参考；按实际 schema 用 path 过滤；不虚构 search_symbol，不猜 Controller 或文件路径，说明索引及定位范围。 | PASS |
| 查询测试库订单状态，数据源有多个且 schema 未选 | 统一入口加载 database-query 参考；列出连接并确认歧义，再发现 schema；明确表与字段后才执行有界只读查询。 | PASS |

两种任务都不要求附着 JVM，不执行 Java 业务方法或数据库写入。数据库和搜索 companion 能力以当前 catalog 为准，不把它们冒充为 56 个 Agent 工具契约的一部分。

## 本地验证

- 合并后 `bash scripts/validate.sh` 通过，包含统一技能路由、适配器、临时安装 smoke、doctor 和工具契约检查。
- 远程新增场景与内容保留，接入单一 `debug-tools` 入口的按需参考。

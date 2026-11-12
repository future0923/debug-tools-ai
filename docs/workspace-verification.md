# 三仓库统一验收

在 `debug-tools-ai` 中执行：

```bash
bash bin/debug-tools-ai verify-workspace --java-home "$JAVA21_HOME" --maven /path/to/mvn
```

默认读取相邻 `debug-tools`、`debug-tools-idea`。不同路径可传 `--agent-repo` 和
`--idea-repo`。构建使用 JDK 21；目标矩阵要求完整的 Java 8、11、17、21、25 JDK，
不是仅有 JRE。设置 `JAVA8_HOME`、`JAVA11_HOME`、`JAVA17_HOME`、`JAVA21_HOME`、
`JAVA25_HOME`，或重复传 `--target-java-home /path/to/jdk`。macOS/Linux 标准 JDK
目录可自动发现。命令不会下载安装 JDK。

首次使用需能解析 Maven/Gradle 依赖，已有缓存可加 `--offline`。
默认包含完整 `verifyPlugin`。诊断构建问题时可显式 `--skip-verifier`，报告会标记
PARTIAL 与 verifier=NOT_RUN，不能当作发布兼容性通过。

## 执行范围

1. 检查源码路径和五个目标 JDK，缺一个就失败。
2. Maven 重建并 install agent 及其依赖，然后运行普通 `mvn test`。
3. 检查 SQL、server、Spring extension 的 Surefire 报告；零测试、只有 skipped、失败或错误均拒绝。
4. 将本轮 agent jar 同步至 IDEA 对应版本的内置资源。
5. 强制重新执行 IDEA 测试，完成 check、buildPlugin、movePluginZip。
6. 打包 agent 测试使用每个目标 JDK 的 javac 生成该版本字节码，并启动隔离进程验证调用、恢复、watch、部署和清理。
7. 校验 AI 契约与本轮 IDEA 导出一致，运行 AI validate 和安装/卸载 smoke。
8. 核对单插件结构、无 MCP Server 依赖、ZIP 内置 agent 字节与本轮构建一致。
9. 运行配置中的全部 IDE verifier，检查每个版本都有 Compatible 判定。

构建会更新各仓库的构建目录、Maven 本地仓库、IDEA 内置 agent 资源和 dist 包。
不会修改 Git 暂存区、提交、发布或安装到用户运行中的 IDE。源码已有用户改动会参与
本地构建，报告证明当前工作目录的产物；不会自动还原这些改动。

## 报告与失败

每次创建新的 `build/workspace-verification/<timestamp>/`，包含每步日志与
`report.json`。也可用 `--output` 指定不存在的目录。步骤开始、成功、失败会及时写入
报告；首个失败返回非零状态。测试前清理旧 XML，并强制运行 IDEA test，避免把旧报告
或 UP-TO-DATE 当成新证据。矩阵必须有五个目标的完成标识。

报告内 `status=PASS` 仅代表本地自动化范围通过。`environmentChecks` 单独列出未执行
的真实 IDEA/Kubernetes/框架项；该命令不会访问用户的业务系统。
对应环境按 [实机验收步骤](live-acceptance.md) 选择目标后执行并另存证据。

## 单独重跑矩阵

在 IDEA 仓库中使用项目所需 JDK，执行：

```bash
./gradlew test --tests '*PackagedAgentRegressionTest' \
  "-PdebugTools.test.javaHomes=$JAVA8_HOME:$JAVA11_HOME:$JAVA17_HOME:$JAVA21_HOME:$JAVA25_HOME" \
  -Pkotlin.daemon.jvmargs=-Xmx2g
```

上述分隔符适用于 macOS/Linux。测试源码保持 Kotlin，Java 业务样例只在临时目录
生成并由目标 javac 编译。测试失败信息保留目标 JDK 和 agent 输出；正常结束清理子进程
与临时 HOME。改动 agent 后优先使用统一命令，以免测到旧内置 jar。

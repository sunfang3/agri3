# 日常开发与变异测试

每次修改业务规则，先补充允许、拒绝和边界场景的断言，再修改实现。
普通测试通过以后，使用 `bin/mutant` 检查测试是否能够发现被故意改坏的业务规则。
提交合并或部署前必须运行完整 `bin/ci`；变异测试失败会阻止 CI 签发 signoff。

```sh
bin/rails test
bin/mutant
bin/ci
```

首批强制范围在 `config/mutant.yml`：管理员角色与课程管理权限、报名状态流转、
推荐状态与推荐等级、等级中文标签。每个范围要求 100% 变异覆盖；没有存活变异
才算通过。范围以外的逻辑仍依赖普通测试，当前结果不代表整个应用达到 100%。

新增关键业务方法时，将方法加入 `matcher.subjects`，并在测试类中添加对应的
`cover "Class#method"`。看到存活变异时，补充能区分业务结果的断言，或者删除
确实冗余的生产代码。不得通过排除变异、降低阈值或跳过 CI 步骤使检查通过。

本地可以用 `bin/mutant 'Admin#can_manage_course?'` 缩小反馈范围；完整 CI
始终不带方法参数，运行所有已登记方法，避免只检查 Git 差异遗漏间接影响。

`bin/mutant` 在 `tmp/` 下建立独立 Litestack 数据目录，加载当前 schema，
固定单 worker，并禁用 Rails 内层测试并行。退出时删除数据库目录，不加载八倍
演示种子，也不使用 `storage/development` 或 `storage/test` 中的数据库。

接入方式参考 [Mutant Minitest 文档](https://github.com/mbj/mutant/blob/v0.17.1/docs/mutant-minitest.md)
和 [Rails 文档](https://github.com/mbj/mutant/blob/v0.17.1/docs/rails.md)。
Mutant 自身使用其上游许可证；本仓库的开源许可证不替代依赖的许可证。

# Oaken 种子数据维护

当前使用 [Oaken 1.0](https://github.com/kaspth/oaken)，将数据按依赖顺序、区县及业务场景组织，开发演示与相关测试复用同一份定义。`db/seeds.rb` 负责加载顺序和整体数据库事务。

## 目录与依赖

| 路径 | 用途 |
| --- | --- |
| `db/seeds/setup.rb` | 类型默认值、命名辅助方法及 `keep`；不创建记录 |
| `db/seeds/setup/catalog.rb` | 产业画像、课程/政策/师资等基础规格 |
| `db/seeds/setup/attachments.rb` | 本地生成演示插图及静音音频，无外部下载 |
| `db/seeds/data/` | 官方区划、标签、阶段规则及匹配权重 |
| `db/seeds/districts/jinan.rb` | 以区县为根组织管理员、学员和标签 |
| `db/seeds/resources/catalog.rb` | 师资 → 政策 → 课程 → 知识库及问卷 |
| `db/seeds/cases/enrollments.rb` | 市直/区办、跨区报名、录取与备案 |
| `db/seeds/cases/profiles.rb` | 需求、荣誉、六个月评估及作品案例 |
| `db/seeds/cases/learning.rb` | 考勤、照片、音频/文本笔记、答疑、问卷与归因 |
| `db/seeds/cases/conversions.rb` | 查看/收藏/申报/获批、消息与需求预警 |
| `db/seeds/cases/matching.rb` | 仅对演示学员运行阶段判定与匹配，重建知识库索引 |
| `db/seeds/exports/import_samples.rb` | 导出与数据集一致的 Excel 导入样例 |

`setup` 由 Oaken 自动加载一次。入口显式声明其余阶段的顺序，场景文件不依赖文件名字典序。

## 导入与按需加载

默认加载八倍演示集：

```sh
bin/rails db:seed
```

原始规模及只维护基础字典：

```sh
SEED_MULTIPLIER=1 bin/rails db:seed
bin/rails runner 'Oaken.seed :data'
```

只加载报名场景，先显式提供它的依赖：

```sh
SEED_MULTIPLIER=1 bin/rails runner 'Oaken.seed :data, :districts, :resources, "cases/enrollments"'
bin/rails runner 'puts Oaken.glob("cases/enrollments")'
```

`db:seed` 的数据库写入由入口事务包裹；直接调用 `Oaken.seed` 加载片段时，可按需要自行包裹 `ActiveRecord::Base.transaction`。

若需独立演示库，可以指定数据目录，并先迁移：

```sh
LITESTACK_DATA_PATH=/tmp/agri3-demo bin/rails db:migrate
LITESTACK_DATA_PATH=/tmp/agri3-demo bin/rails db:seed
```

附件仍遵循 `config/storage.yml` 的存储路径。已有部署环境仍应按项目运维手册使用 seed；本次不执行远程 seed 或部署。

## 默认数据规模

以下为新库中的种子记录数量；现有库中的其他业务数据不会被清理。

| 对象 | 原始规模 | 默认规模 |
| --- | ---: | ---: |
| 学员 | 24 | 192 |
| 政策 | 9 | 72 |
| 课程 | 11 | 88 |
| 师资 | 9 | 72 |
| 案例/作品 | 12 | 96 |
| 知识条目 | 5 | 40 |
| 问卷 | 3 | 24 |

正式区划保持 **12**，管理员保持 **13**，基础标签保持 **20**。新增关联数据包括 **576** 条报名、**192** 条需求、**192** 项荣誉、**1,152** 条能力评估、**576** 条政策进度，以及照片、学习笔记、答疑、消息等。

手机号 `13800000001`–`13800000024` 保留原区县顺序；其后每 24 人为一组，直至 `13800000192`。张三 `13800000009`、李四 `13800000003` 和管理员账号保持不变。新建演示账号密码为 `password`。

日期以首次加载时写入首个学员 `profile.demo_reference_date` 的基准为准，避免第二天重跑又生成一批评估或改变历史。默认演示集包含历史课程、当期/未来课程、四种报名状态，以及多种审核和申报状态。

## 维护规则

基础字典使用 Oaken 的 `create(unique_by:)`：同一业务键重跑时维护声明值。可变业务数据使用在 `setup.rb` 定义的 `keep`：存在则重用并登记 Oaken 标签，不执行覆盖更新。这样会保留改过的密码、经营画像、清空的标签、荣誉审核、报名录取、备案和政策办理进度。

数据自然键使用手机号、邮箱、标题或关联组合。修改标题等自然键将生成新条目；调整说明、元数据或演示业务状态时，应区分首次创建默认值与需要显式执行的数据维护操作。对已存在的课程和政策，仅补齐尚为空的容量、文号和发布单位等新增字段。

在 `setup/catalog.rb` 维护共享的政策/课程规格；在对应的 `cases/*.rb` 增加或调整业务情景。通用字典、演示场景和 Excel 业务导入保持各自入口：真实 Excel 上传继续由 `Students::ExcelImporter` 校验处理，Oaken 用于维护可重复的开发和测试数据集。

## 测试复用

记录可通过业务名称访问：

```ruby
include Oaken::Seeds

seed :data, :districts, :resources, "cases/enrollments"
students.zhang_san
admins.licheng
courses.city_demonstration
enrollments.zhang_city
enrollments.li_cross_district
```

新增测试通过 `SEED_MULTIPLIER=1` 按需加载小场景；现有测试保持原有隔离方式，不会为每个 worker 预装八倍完整数据。可参考 `test/db/oaken_seeds_test.rb` 和 `test/integration/oaken_enrollment_test.rb`。

验证包括实际八倍加载、重复加载后数量稳定、附件字节可读取，以及已经人工修改的业务状态不被重置。

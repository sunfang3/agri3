# 齐鲁农创客全过程管理系统 · 使用与运维手册

**版本：** 与 roadmap Phase 1–3 产品设计对齐；**运行时底座为 agri3 / Litestack**（自 `react_demo_2` PG+pgbus 版迁入）  
**适用对象：** 系统架构读者、区县/市级管理员、学员、系统维护员  
**项目定位：** 济南市农广校内部管理平台（与省级齐鲁农云无关联）  
**仓库：** 本手册以 **agri3** 为准；历史 PG 版见 `../react_demo_2`（只读参考）

---

## 1. 系统架构视角

### 1.1 使命与价值主张

系统存在的目的，是让市农广校与区县管理员用数字化工具收口农创客培育全过程数据，使每位学员获得适配的**政策、课程与服务**（见 `docs/product/mission.md`）。

核心假设（MVP）：

| 假设 | 验证点 |
|------|--------|
| A1 管理员愿意迁移 Excel 工作流 | 区县后台周活、CSV 导出、批量审核 |
| A2 学员愿意看专属适配清单 | 首页推荐打开、App 内消息 |

### 1.2 技术栈

| 层级 | 技术 |
|------|------|
| 应用 | Ruby on Rails 8.1 |
| 视图 | **Phlex** + Tailwind / DaisyUI（`phlex-reactive` / `phlex-forms`） |
| 管理后台 | 自研 `/admin` + Avo `/avo` |
| 数据库 | **Litedb**（SQLite via [Litestack](https://github.com/sunfang3/litestack)），路径见 `config/database.yml` |
| 缓存 | **Litecache** |
| 后台任务 | Active Job + **Litejob**（**进程内** worker，无独立 job 进程） |
| 实时 | **Litecable**（Action Cable，`/cable`） |
| 全文检索 | **Litesearch**（中文/拼音可选 **libsimple**） |
| 定时任务 | 系统 timer / cron 或自重排 Job → `DailyMatchingJob`（T+1 匹配） |
| 认证 | Session + `bcrypt`（`Admin` / `Student`） |
| 外部能力 | 适配器接口 + 可替换 Fake（ASR / LLM / SMS / WebPush / 微信） |
| 部署 | **Tomo**；`storage/` 为共享链接目录 |

**刻意不包含：** PostgreSQL、`pg`、pgbus/PGMQ、Solid Cache/Queue/Cable、Redis、独立 job systemd 单元。

详见 `docs/product/tech-stack.md` 与仓库根 `README.md`。

### 1.3 逻辑架构

```
                    ┌─────────────────────────────────────┐
                    │           入口与角色路由              │
                    │  /  平台首页                         │
                    │  /student/*  学员 PWA（2 Tab）        │
                    │  /admin/*    区县/市级运营后台         │
                    │  /avo        Avo 资源管理             │
                    └───────────────┬─────────────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          ▼                         ▼                         ▼
   ┌─────────────┐          ┌──────────────┐          ┌──────────────┐
   │ 学员域       │          │ 运营域        │          │ 匹配与智能域   │
   │ Student      │          │ Admin/District│          │ Matching/*    │
   │ Enrollment   │          │ Policy/Course │          │ Tips/Push/PDF │
   │ AppMessage   │          │ Survey/Mentor │          │ Cosine/Gaps   │
   └─────────────┘          └──────────────┘          └──────────────┘
                                    │
                                    ▼
                          ┌──────────────────┐
                          │ Litestack AIO    │
                          │ data.sqlite3     │
                          │ analytics_events │
                          │ Litejob (in-proc)│
                          │ Litecache/Cable  │
                          └──────────────────┘
```

> **不移植：** 原 `react_demo_2` 的 `/chat` 演示（依赖 pgbus SSE），与 roadmap 产品无关。
### 1.4 核心数据域

| 域 | 主要模型 | 说明 |
|----|----------|------|
| 组织 | `District`, `Admin` | 济南市正式区划 **10 区 + 2 县**（不含功能区）；管理员按区县/市级隔离 |
| 学员 | `Student`, `StudentTag`, `TipsStageRule` | 画像 + T-I-P-S 阶段 |
| 资源 | `Policy`, `Course`, `Tag`, `Mentor` | 政策/课程/标签/师资 |
| 闭环 | `Enrollment`, `ResourceMatch`, `AppMessage` | 报名四态、匹配分、站内消息 |
| 过程 | `CheckIn`, `TrainingPhoto`, `Survey*`, `VoiceNote` | 签到、留痕、学情、语音笔记 |
| 智能 | `MatchWeight`, `FeedbackSignal`, `Attribution` | 权重回流、成效归因 |
| 决策 | `ResourceGap`, `Alert`, `ShowcaseCase`, `KnowledgeArticle` | 缺口、预警、案例、知识库 |
| 观测 | `AnalyticsEvent` | login / key_action / page_view |

### 1.5 匹配引擎

**规则版（Phase 1，T+1 默认）**

\[
\text{score} = \mathrm{round}\left(\frac{|\text{学员标签} \cap \text{资源标签}|}{|\text{资源标签}|} \times 100\right) \in [0,100]
\]

- 实现：`Matching::RuleEngine` + `Matching::Runner`
- 调度：`DailyMatchingJob`，由 **cron / systemd timer**（或 job 自重排）每日 02:00 触发，参数 `["rules"]`（位置参数）

**余弦版（Phase 3，实时）**

- `Matching::CosineEngine`：标签维 + 规模/收入归一化
- 非正相似度或资源无标签 → **score = 0**（避免旧公式把正交映射成 50）
- 调用：`Matching::Runner.new(student, engine: :cosine).match_one(resource)` 或 `run!`

**推荐展示（学员首页 D3 三档）**

| 档位 | 分数 | 文案 |
|------|------|------|
| 1 | 80–100 | 强烈推荐 |
| 2 | 50–79 | 建议关注 |
| 3 | 其他 >0 | 可了解 |

### 1.6 报名状态机

```
pending ──confirm──► enrolled ──complete──► completed
   │                    │
   └──drop──► dropped ◄─┘ drop
```

批量确认：`Enrollment.bulk_confirm!(ids)`（管理后台）。

### 1.7 关键路径速查

| 路径 | 角色 | 功能 |
|------|------|------|
| `/` | 公开 | 平台落地页与入口 |
| `/up` | 运维 | 健康检查 |
| `/student/login` · `/register` | 学员 | 登录 / 注册画像 |
| `/student/home` | 学员 | 推荐清单 + 选课 + 消息红点 |
| `/student/me` | 学员 | T-I-P-S、标签修正、答疑入口 |
| `/student/surveys` | 学员 | 学情调查作答 |
| `/student/knowledge` | 学员 | 农技知识库检索 |
| `/admin/login` | 管理员 | 后台登录 |
| `/admin` | 管理员 | 汇总、筛选、批量审核、驾驶舱 |
| `/admin/imports` | 管理员 | Excel dry-run / 正式导入 |
| `/admin/policies` · `/courses` · `/surveys` | 管理员 | 政策/课程/问卷 |
| `/avo` | 管理员 | Avo CRUD |
| `/cable` | 实时 | Action Cable（WebSocket；非产品页） |

### 1.8 分阶段交付对照

| Phase | 主题 | 已交付要点 |
|-------|------|------------|
| **1 MVP** | 证明可用 | 注册画像、Excel 导入、政策库、课程报名、规则匹配、PWA 2 Tab、区县后台、埋点 |
| **2 V1.1** | 可复制 | PDF 解析+校对、语音笔记、动态 T-I-P-S、多通道推送、签到 GPS、水印、师资、学情调查、驾驶舱、反馈回流 |
| **3 V1.2** | 规模化 | 余弦匹配、物化视图驾驶舱、缺口+预警、归因、案例墙、知识库、导师语音答疑、全市区县种子 |

非目标（不在本系统交付范围）：红头文件现场运营指标、区块链证书、VR/AR、跨市协同等（见 roadmap Deferred）。

---

## 2. 使用者视角

### 2.1 角色总览

| 角色 | 典型人物 | 主要目标 |
|------|----------|----------|
| 学员 | 家庭农场主张三 | 看到「我能用什么政策、该学什么课」 |
| 区县管理员 | 历城农广校李科长 | 收口报名、审核、导出、本区汇总 |
| 市级管理员 | 市农广校 | 驾驶舱、多区县对照、预警与案例 |
| 导师 | 培训师资 | 课程关联、语音答疑（能力路径已备） |
| 系统维护员 | 见第 3 章 | 部署、备份、任务、账号 |

### 2.2 学员：日常用法

#### 2.2.1 注册与登录

1. 打开平台首页 `/` → **学员注册** 或 **学员入口**。
2. 注册必填：手机号（11 位）、姓名、区县；建议填写主业、规模、年收入、荣誉。
3. 设置密码后登录；**未设置密码的账号无法登录**（安全策略）。
4. Excel 批量导入的账号：初始密码为**手机号本身**，首次登录后建议在「我的」中修改画像并联系管理员重置习惯。

#### 2.2.2 首页（专属适配清单）

- **三档推荐**：强烈推荐 / 建议关注 / 可了解（由匹配分数分层）。
- **选课**：点「报名」→ 状态 `pending`，等待管理员审核。
- **消息红点**：未读 App 内消息数量；进入消息页后标记已读。

#### 2.2.3 我的（画像）

- 查看 **T-I-P-S 阶段**（可由规则引擎根据规模/收入等动态更新）。
- **修正标签**：勾选正确标签并保存（标记为用户修正）。
- **学情调查**：训前需求 / 训中日评 / 训后考试。
- **导师答疑**：文字提问；可选填语音 key 触发 ASR 转写路径。
- **知识库**：关键词全文检索。

#### 2.2.4 现场培训相关（Phase 2）

- **扫码签到**：管理员下发课程 token + 学员提交经纬度；系统用 Haversine 校验是否在课程点约 500m 内。
- 签到失败常见原因：未报名或状态非 enrolled、token 过期、GPS 偏差过大。

### 2.3 区县管理员：日常用法

#### 2.3.1 登录

- 路径：`/admin/login`
- 种子示例（开发环境 `bin/rails db:seed` 后）：
  - 区县：`admin@licheng.local` / `password`
  - 市级：`city@jinan.local` / `password`

区县账号**仅能操作本区**学员与报名；市级账号可看全市驾驶舱。

#### 2.3.2 本区工作台（`/admin`）

1. **区县汇总视图**：学员总数、T-I-P-S 分布、报名状态分布。
2. **多维筛选**：阶段、**标签**、报名状态。
3. **报名批量 confirm**：勾选 pending 报名 → 批量确认 → `enrolled`。
4. **CSV 导出**：本区（或全市）学员列表，用于上级检查。
5. **Excel 导入**：先 **Dry-run 预览**（不写库）→ 确认无误再 **正式导入**。
   - 表头：`phone, name, district_code, primary_industry, scale, annual_income, honors`
6. **政策 / 课程 / 学情调查**：录入与维护；政策支持 PDF 解析后**人工校对通过**。

#### 2.3.3 推荐操作节奏（对齐 mvp-plan GTM）

| 周次 | 动作 |
|------|------|
| 第 1 周 | 导入历史 Excel；熟悉后台与筛选 |
| 第 2 周 | 录入首批政策与课程；维护标签 |
| 第 3 周 | 组织学员注册与首次选课；批量审核 |
| 第 4 周 | 现场培训；签到/问卷/反馈（V1.1 能力） |

### 2.4 市级管理员

- 使用 `role=city`（或 `system`）账号登录 `/admin`。
- 可见 **市级基础驾驶舱**（学员总量、分县、阶段、报名、匹配均分等）。
- 可结合 **预警中心 / 资源缺口** 与 **案例展示墙** 做资源调配与典型经验推广。
- Avo `/avo` 适合做全资源 CRUD 与快速检索。

### 2.5 学员「专属清单」从哪里来？

1. 学员与政策/课程打上**同一标签体系**（产业、适用对象、规模/收入门槛等）。
2. 夜间 T+1 任务或管理员触发匹配后，写入 `resource_matches`。
3. 首页按分数分三档展示；学员报名与反馈可回流权重（Phase 2）。

---

## 3. 系统维护员视角

### 3.1 环境与数据库

**全部环境使用 Litedb（SQLite）**，路径由 `config.litestack.data_path`（默认 `storage/`）解析（**以仓库最新 `config/database.yml` 为准**）：

| 环境 | 数据文件（典型） |
|------|------------------|
| development | `storage/development/data.sqlite3` |
| test | `storage/test/data.sqlite3` |
| production | `storage/production/data.sqlite3`（发布时 `storage/` 为 **linked** 共享目录） |

可选：`ENV["LITESTACK_DATA_PATH"]` 覆盖数据根目录。

常用命令：

```bash
# 安装依赖
bundle install

# 创建/迁移（开发）
bin/rails db:prepare
bin/rails db:seed

# 测试库
RAILS_ENV=test bin/rails db:prepare
bin/rails test

# 启动（开发）— 仅 web + css；Litejob 跑在 web 进程内
bin/dev
```

**不要**配置 Postgres `DATABASE_URL`。生产密钥写在 Tomo 管理的远程 env / credentials，勿入库。

### 3.2 进程与组件

| 组件 | 职责 | 备注 |
|------|------|------|
| Puma / Rails | Web + **Litejob** | 健康检查 `/up`；**无**独立 job 进程 |
| Litestack 文件 | 主库 / cache / cable / job 队列 | 均在 `storage/`（或 `LITESTACK_DATA_PATH`）下 |
| Action Cable | 实时 | `ws://…/cable`（需 WebSocket 升级） |
| Tailwind 构建 | 样式 | `bin/dev` 含 CSS watch |

T+1 匹配：**不使用** pgbus `recurring.yml`。推荐生产用 **systemd user timer** 或主机 cron：

```cron
0 2 * * * cd /path/to/current && bin/rails runner 'DailyMatchingJob.perform_later("rules")'
```

（移植实现阶段可改为 job 自重排方案，见 `docs/plans/litestack-port-plan.md`。）

手动跑一次匹配：

```bash
bin/rails runner 'DailyMatchingJob.perform_now("rules")'
# 或余弦
bin/rails runner 'DailyMatchingJob.perform_now("cosine")'
```

### 3.3 账号与安全

| 项 | 措施 |
|----|------|
| 学员登录 | 必须有 `password_digest` 且 `authenticate` 成功；空 digest **拒绝登录** |
| 导入账号 | 提交导入时若无密码，设置初始密码为手机号 |
| 管理员 | `has_secure_password`；会话 `session[:admin_id]` |
| 浏览器 | 非 test 环境启用 `allow_browser versions: :modern` |
| 数据隔离 | 区县管理员 `scoped_students` / `scoped_enrollments` |
| 密钥 | `config/master.key`、生产 secrets / Tomo env 勿入库 |

重置学员密码（控制台示例）：

```bash
bin/rails runner 's=Student.find_by!(phone:"13800000001"); s.password="newpass"; s.save!'
```

### 3.4 备份与恢复

SQLite / Litestack 文件备份要点：

1. **每日**在应用停写窗口或使用 SQLite 在线备份 API / 一致性拷贝 `storage/`（至少 `**/data.sqlite3` 与相关 litestack 文件）。
2. 迁移或发布前备份整个 linked `storage/`；保留至少 7 日滚动。
3. 恢复后确认应用能 `db:migrate:status` 且 `/up` 正常。
4. Active Storage 附件与 `storage/` **同周期**备份。
5. 生产 **禁止**把 `storage/` 放在无可靠锁的网络文件系统上（见 Litestack 文档）。

示例（开发机粗备份）：

```bash
# 应用短暂停写更安全；生产建议用维护窗口或 SQLite backup API
tar -czf backup_$(date +%F).tgz storage/
```

### 3.5 日常巡检清单

| 频率 | 检查项 |
|------|--------|
| 每次发布 | `bin/rails test`；`/up` 200；登录学员/管理路径；`storage/` 仍为 linked |
| 每日 | `DailyMatchingJob` 是否执行（timer/cron 日志）；磁盘空间；SQLite 文件大小 |
| 每周 | `analytics_events` 量级与登录/关键操作是否异常；失败 Job（Litejob） |
| 每月 | 标签质量抽检；过期政策 `valid_until`；未审核报名积压；备份可恢复演练 |

资源缺口与预警（可脚本化）：

```bash
bin/rails runner 'Analytics::GapAnalyzer.new.analyze!; Analytics::GapAnalyzer.new.raise_alerts!'
```

驾驶舱快照刷新（**非** Postgres 物化视图；应用层汇总表 / 任务）：

```bash
bin/rails runner 'Dashboard::CityCockpit.new.materialize!'
```

### 3.6 外部适配器切换

生产若接入真实厂商，替换对应 adapter 注入点即可，业务代码保持不变：

| 能力 | 默认 | 接入点 |
|------|------|--------|
| PDF 抽取 | `Extractors::FakePdfExtractor` | `Policies::PdfParser.new(extractor: ...)` |
| ASR | `Adapters::FakeAsr` | `VoiceNotes::Pipeline` |
| LLM 结构化 | `Adapters::FakeLlm` | 同上 |
| SMS / WebPush / 微信 | `Adapters::Fake*` | `Push::MultiChannel.new(...)` |

**不要**在未配置密钥时启用真实通道。

### 3.7 故障排查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| 测试/启动找不到库文件 | `litestack.data_path` / 权限 | 确认 `storage/<env>/` 可写，`db:prepare` |
| database is locked | 多进程写同一 SQLite | 保持单 Puma + 进程内 Litejob；避免并行 `rails runner` 长事务 |
| 学员无法登录 | 无 password_digest | 导入会写手机号密码；或控制台重置 |
| 推荐清单为空 | 未跑匹配 / 无标签 | 打标签后 `DailyMatchingJob.perform_now` |
| 报名不能确认 | 状态非 pending | 检查状态机；仅 pending→enrolled |
| 签到 GPS 失败 | 课程无坐标或距离过大 | 维护 course lat/lng；放宽半径需改 `QrService` |
| T+1 Job 报错 | perform 参数 | 使用位置参数 `"rules"` 或关键字 `engine:` |
| 知识库搜不到中文 | 未装 libsimple / 未用 Litesearch | 见 `config/initializers/litestack_extensions.rb` 与 README |
| 403 非浏览器 | `allow_browser` | 运维探活用现代 UA 或探 `/up` |
| Avo 空白/跳转 | 未登录策略 | 开发环境可先 `/admin`；Avo 授权见 `config/initializers/avo.rb` |

### 3.8 发布与回滚建议

1. 合并前：`bin/rails test` 全绿。  
2. 生产：备份 `storage/` → `tomo deploy`（migrate 后重启 **Puma** 即可；Litejob 随 web 起来）。  
3. 回滚：代码回退 + 仅在**有反向迁移**时 `db:rollback`；**先恢复 `storage/` 备份**再启服务。  
4. 部署细节见根 `README.md` 与 `.tomo/`；历史 kamal-proxy 笔记在 `docs/plans/react_demo_2_legacy/`。
### 3.9 种子数据（开发）

```bash
bin/rails db:seed
```

会写入济南区县、示例管理员/学员、政策、课程、标签，并跑一轮规则匹配。生产环境慎用 seed。

### 3.10 测试与质量门禁

```bash
bin/rails test
```

覆盖重点：报名状态机、规则/余弦匹配、Excel dry-run vs commit、埋点、学情调查全路径、登录安全、T+1 Job 位置参数、缺口分析断言等。

---

## 4. 附录

### 4.1 相关文档

| 文档 | 内容 |
|------|------|
| `docs/product/mission.md` | 使命与用户故事 |
| `docs/product/mvp-plan.md` | MVP 范围与风险 |
| `docs/product/roadmap.md` | 三阶段交付与退出标准 |
| `docs/product/tech-stack.md` | 技术选型（Litestack 版） |
| `docs/er-diagram.md` | 实体关系 |
| `docs/plans/litestack-port-plan.md` | 自 react_demo_2 移植计划 |
| 本文 `docs/handbook.md` | 架构 / 使用者 / 运维 |

### 4.2 标签类别（政策/课程/学员）

`applicable_object` · `industry` · `scale_threshold` · `income_threshold` · `deadline` · `course` · `other`

### 4.3 成长阶段（T-I-P-S）中文对照

库内编码仍为 `T|I|P|S`；**界面一律用中文**，面向农业基层用户：

| 编码 | 界面名称 | 一句话说明 |
|------|----------|------------|
| T | **起步期** | 刚起步，正在打基础、学技术 |
| I | **成长期** | 加大投入，经营在往上走 |
| P | **壮大期** | 规模扩大，发展比较稳 |
| S | **示范期** | 示范带动，经验能帮到乡亲 |

实现：`Student.tips_stage_label` / `tips_stage_hint`。  
规则表 `tips_stage_rules` 可配置；无匹配规则时由规模/收入启发式回落。

### 4.4 修订记录

| 日期 | 说明 |
|------|------|
| 2026-07-14 | 初版：对齐 Phase 1–3 实现与 PostgreSQL/pgbus database.yml（react_demo_2） |
| 2026-07-19 | 迁入 agri3：技术栈改为 Litestack AIO；运维/备份/进程模型重写；去掉 chat/pgbus |

---

*如文档与代码冲突，以仓库实现与最新 `config/database.yml` 为准。产品范围以 `docs/product/*` 为准。*

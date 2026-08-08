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

| 角色 | 典型人物 | 主要目标 | 登录入口 |
|------|----------|----------|----------|
| 学员 | 家庭农场主张三 | 看到「我能用什么政策、该学什么课」 | `/student/login` |
| 区县管理员 | 历城农广校李科长 | 收口报名、审核、导出、本区汇总 | `/admin/login` |
| 市级管理员 | 市农广校 | 全市汇总、多区对照、资源 CRUD | `/admin/login` |
| 导师 | 培训师资 | 课程关联、语音答疑（能力路径已备） | 经课程/答疑链路 |
| 系统维护员 | 见第 3 章 | 部署、备份、任务、账号 | 主机 / 控制台 |

平台首页 `/` 为统一入口页，提供「学员入口 / 注册」与「管理后台登录」卡片，不承载业务操作本身。

---

### 2.2 开发演示账号（`bin/rails db:seed`）

> **适用范围：** 开发与演示环境。生产**慎用** seed。  
> 下列账号在执行 `bin/rails db:seed` 后可用；**默认密码均为 `password`**（除非另行说明）。

Seed 会写入：济南 **10 区 + 2 县**、标签库、政策/课程/师资、学情问卷、案例、规则匹配结果等。学员共 **24** 人（每区县 2 名）；管理员 **1 市级 + 12 区县**。

#### 2.2.1 市级管理员（1 个）

| 项 | 值 |
|----|-----|
| 邮箱 | `city@jinan.local` |
| 密码 | `password` |
| 角色 | `city`（不绑定单一区县，可看全市） |
| 显示名 | 济南市农广校·市级管理员 |
| 入口 | `/admin/login` → 工作台 `/admin` |

#### 2.2.2 区县管理员（12 个）

邮箱模式：`admin@<区县 code>.local`，密码均为 `password`。

| 邮箱 | 显示名 | 区县 |
|------|--------|------|
| `admin@lixia.local` | 历下王科长 | 历下区 |
| `admin@shizhong.local` | 市中赵科长 | 市中区 |
| `admin@huaiyin.local` | 槐荫孙科长 | 槐荫区 |
| `admin@tianqiao.local` | 天桥周科长 | 天桥区 |
| **`admin@licheng.local`** | **历城李科长**（手册推荐演示） | **历城区** |
| `admin@changqing.local` | 长清吴科长 | 长清区 |
| `admin@zhangqiu.local` | 章丘郑科长 | 章丘区 |
| `admin@jiyang.local` | 济阳冯科长 | 济阳区 |
| `admin@laiwu.local` | 莱芜陈科长 | 莱芜区 |
| `admin@gangcheng.local` | 钢城褚科长 | 钢城区 |
| `admin@pingyin.local` | 平阴卫科长 | 平阴县 |
| `admin@shanghe.local` | 商河蒋科长 | 商河县 |

#### 2.2.3 学员（24 个）

- 手机号：`13800000001` … `13800000024`（按区县顺序各 2 人）
- 密码：均为 `password`
- 每区县：第 1 人偏「示范户」（规模/收入较大，可能有荣誉），第 2 人偏普通学员
- 入口：`/student/login`

**具名演示账号（手册优先使用）：**

| 手机号 | 姓名 | 区县 | 说明 |
|--------|------|------|------|
| **`13800000009`** | **张三** | 历城区 | 标杆学员：标签与匹配结果较完整；有待审核报名、欢迎站内消息 |
| `13800000003` | 李四 | 市中区 | 第二具名演示学员 |

其他示例：`13800000001` 历下示范户1、`13800000002` 历下学员2，规则同上。

#### 2.2.4 推荐演示路径（最短）

1. **学员：** `/student/login` → `13800000009` / `password`  
   → 首页看推荐清单 →「我的」看阶段与标签 → 消息页  
2. **区县：** `/admin/login` → `admin@licheng.local` / `password`  
   → 筛选 pending 报名 → 批量确认张三 → CSV 导出  
3. **市级：** `/admin/login` → `city@jinan.local` / `password`  
   → 看全市汇总；可选 `/avo` 做资源 CRUD  

---

### 2.3 学员：登录后能做什么

#### 2.3.1 注册与登录

1. 打开平台首页 `/` → **学员注册** 或 **学员入口**。  
2. 注册必填：手机号（11 位）、姓名、区县；建议填写主业、规模、年收入、荣誉。  
3. 设置密码后登录；**未设置密码的账号无法登录**（安全策略）。  
4. Excel 批量导入的账号：初始密码为**手机号本身**（与 seed 演示密码 `password` 不同）；首次登录后建议在「我的」中完善画像。

#### 2.3.2 功能一览（学员 PWA）

| 能力 | 路径 / 入口 | 说明 |
|------|-------------|------|
| **专属适配清单** | `/student/home` | 政策/课程推荐；三档：强烈推荐 / 建议关注 / 可了解 |
| **报名选课** | 首页「报名」 | 提交后 `pending`，等管理员审核为 `enrolled` |
| **App 内消息** | `/student/messages` | 站内消息；未读可在首页以红点提示 |
| **我的画像** | `/student/me` | T-I-P-S 阶段、标签修正、答疑入口 |
| **学情调查** | `/student/surveys` | 训前需求 / 训中日评 / 训后考试 |
| **知识库检索** | `/student/knowledge` | 关键词检索农技文章（支持中文；Litesearch + 回退） |
| **签到 / 导师答疑** | 对应接口与页面链路 | 签到需已报名且 GPS 合理；答疑可走文字/语音管道 |

#### 2.3.3 首页与画像细节

- **三档推荐**：由匹配分数分层（见 §1.5）。  
- **选课**：`pending` → 管理员 confirm → `enrolled`。  
- **T-I-P-S**：可由规则引擎按规模/收入等更新；界面显示中文阶段名（见附录）。  
- **修正标签**：勾选正确标签并保存（标记为用户修正）。  

#### 2.3.4 现场培训相关（Phase 2）

- **扫码签到**：课程 token + 学员经纬度；约 500m 内判定 GPS 有效。  
- 常见失败：未报名 / 非 enrolled、token 过期、课程无坐标、距离过大。

---

### 2.4 区县管理员：登录后能做什么

#### 2.4.1 登录与数据范围

- 路径：`/admin/login`  
- 演示：`admin@licheng.local` / `password`  
- **仅能操作本区**学员与报名（`scoped_students` / `scoped_enrollments`）

#### 2.4.2 功能一览（`/admin` 工作台）

| 能力 | 路径 / 操作 | 说明 |
|------|-------------|------|
| **区县汇总** | `/admin` | 本区学员数、T-I-P-S 分布、报名状态分布 |
| **多维筛选** | 工作台筛选条 | 阶段、标签、报名状态 |
| **批量确认报名** | 勾选 pending → 批量 confirm | 仅**本区开办的班**（`course.district_id`）；`pending` → `enrolled`。市直班不在此列 |
| **CSV 导出** | `/admin/export/students` | 导出本区（市级则可为更广范围）学员列表 |
| **Excel 导入** | `/admin/imports` | 先 Dry-run 预览，再正式导入 |
| **政策维护** | `/admin/policies` | 列表/新建；可走 PDF 解析 + 人工校对 |
| **课程维护** | `/admin/courses` | 列表/新建 |
| **学情调查** | `/admin/surveys` | 创建训前/训中/训后问卷 |
| **Avo 资源** | `/avo` | 学员/政策/课程/标签等 CRUD（与自研后台互补） |

导入表头：`phone, name, district_code, primary_industry, scale, annual_income, honors`。

#### 2.4.3 推荐操作节奏（对齐 mvp-plan GTM）

| 周次 | 动作 |
|------|------|
| 第 1 周 | 导入历史 Excel；熟悉后台与筛选 |
| 第 2 周 | 录入首批政策与课程；维护标签 |
| 第 3 周 | 组织学员注册与首次选课；批量审核 |
| 第 4 周 | 现场培训；签到/问卷/反馈（V1.1 能力） |

---

### 2.5 市级管理员：登录后能做什么

| 项 | 说明 |
|----|------|
| 账号 | `city@jinan.local` / `password`（`role=city`） |
| 入口 | 同 `/admin/login`，工作台 `/admin` |
| **与区县差异** | **全市**学员可见；**报名审核**只处理 **市直班**（`course.district_id` 为空） |
| 汇总 / 驾驶舱 | 学员总量、分县、阶段、匹配均分等全市视角 |
| 运营能力 | 导入/导出/政策/课程/问卷；批量确认市直班录取 |
| 扩展视图 | 预警 / 资源缺口 / 案例墙等（Phase 2–3 能力） |
| Avo | `/avo` 适合全资源快速 CRUD |

---

### 2.6 学员「专属清单」从哪里来？

1. 学员与政策/课程打上**同一标签体系**（产业、适用对象、规模/收入门槛等）。  
2. 夜间 T+1 任务（`DailyMatchingJob`，Litejob + cron/timer）或手动跑匹配后，写入 `resource_matches`。  
3. 首页按分数分三档展示；学员报名与反馈可回流权重（Phase 2）。  

开发环境 seed 结束时会跑一轮规则匹配，因此张三等账号登录后通常**已有推荐**，无需再等定时任务。

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
| 数据隔离 | 区县看本区学员；报名审核按**开班主体**（市直→市，区办→开班区） |
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

会写入：济南 10 区 + 2 县、标签库、**1 市级 + 12 区县管理员**、**24 学员**、政策/课程/师资、问卷与案例，并跑一轮规则匹配与知识库索引重建。

**常用演示账号（密码均为 `password`）详见 §2.2：**

| 角色 | 账号 |
|------|------|
| 市级 | `city@jinan.local` |
| 历城管理员 | `admin@licheng.local` |
| 学员张三 | `13800000009` |

生产环境慎用 seed。

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
| 2026-07-19 | 扩充 §2：seed 账号清单、各角色登录后能力表、最短演示路径 |
| 2026-07-19 | 导出 HTML 手册（`docs/exports/agri3-handbook.html`，系统 CJK 字体；弃用 PDF） |

---

*如文档与代码冲突，以仓库实现与最新 `config/database.yml` 为准。产品范围以 `docs/product/*` 为准。*

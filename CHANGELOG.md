# Changelog

All notable changes to **agri3**（齐鲁农创客全过程管理系统）are documented in this file.

Format inspired by [Keep a Changelog](https://keepachangelog.com/).  
Dates are **author dates** from `git log` unless noted as **production deploy** (`revisions.log`, +0800).

---

## [Unreleased]

### Added

- 齐鲁界面原型接入 Rails：门户、学员四大页面、管理概览/学员档案/资源库/匹配驾驶舱，响应式深靛紫主题。
- 真实需求跟进、荣誉与作品审核、政策收藏及申报登记、六维能力评估与成长图表。
- 课程筛选与月历、容量限制、签名签到码、照片与语音/文本笔记归档；补齐 Active Storage 表。
- 页面、数据模型与权限迁移说明见 `docs/plans/qilu-ui-migration.md`。

- **公共聊天大厅 `/chat`**（Litecable + Turbo Streams + phlex-reactive）
  - 游客 session 昵称；已登录学员/管理员用系统姓名
  - 单房间 `lobby`，最近 50 条历史，实时广播
  - 表 `chat_messages`；首页入口链接

### Planned / backlog

- Real ASR / LLM / SMS / WebPush / 微信 adapters (Fake 适配器已在库)
- Production cron/timer for `DailyMatchingJob` (documented; host-specific)
- 按课程分房聊天（第二迭代）

---

## [2026-08-08] — 两级班审核、课程学员管理、生产业务全量

Production deploys this day: `061cada` (17:49), `0cdec52` (18:04), `f571f35` (18:09).

### Added

- **市直班 / 区办班审核分流**：录取权跟随开班主体（`course.district_id` 空 = 市直 → 市级；有区县 = 区办 → 开班区）
- **区县知会 / 备案**：本区学员报市直班后，区只备案不录取（`district_ack_*`）
- **市级只读区办班**：市级工作台可查看区办报名，不可 bulk 录取
- **Seed 两级课程矩阵**：3 门市直 + 多门区办；张三 / 李四报名演示矩阵
- **Excel 导入可选 `course_title`**：导入时创建 pending 报名并带正确备案状态
- **录取站内消息**：管理员 `confirm!` / 批量确认后学员收到「报名已通过」
- **学员首页报名状态徽章**：审核中 / 已录取 / 已结业 / 已取消
- **课程详情学员 CRUD**（`/admin/courses/:id`）：添加学员、录取、结业、取消、移除；按开班主体鉴权
- 手册功能上线时间表（`docs/handbook.md` §1.8–1.9）与 HTML 导出刷新

### Fixed

- 学员录取后无站内通知的问题
- `/admin/courses` 500：生产 Litedb 将 `starts_at` 读为 String 导致 `strftime` 崩溃（datetime cast + 安全格式化）

### Changed

- 课程列表：归属徽章、报名人数、学员/编辑入口
- 后台工作台文案与列表区分「待我审核录取」与「知会/备案」

---

## [2026-08-07] — 生产槽位与部署就绪

Production deploy: `53afa78` (16:32 +0800).

### Added / Changed

- Tomo / Tailwind 生产路径（`TAILWINDCSS_INSTALL_DIR` 等）
- agri3 应用在 `web2` 槽位首次可部署

---

## [2026-07-19] — Litestack 全量移植（代码合入）

从 `react_demo_2`（PostgreSQL + pgbus）迁入 agri3；当日 master 完成 U0–U9 与知识库补强。  
**生产域名业务全量以 2026-08-08 部署为准**（见上节）。

### Added

- **产品文档**：mission / MVP / roadmap / tech-stack、handbook、ER、移植计划（U0）
- **Litedb 业务 schema**：Phase 1–3 核心表（无 pgbus / solid / chat）
- **领域模型与服务**：学员/政策/课程/报名/匹配（规则 + 余弦）、Excel 导入、Fake 适配器、学情、签到、推送接口等
- **Litejob**：`DailyMatchingJob`、`ProcessVoiceNoteJob`；T+1 调度说明（cron/timer）
- **学员 PWA**：登录注册、首页推荐清单、选课报名、消息、画像、学情、知识库
- **区县 / 市级管理后台**：汇总、筛选、批量审核、导入导出、政策/课程/问卷；Avo 资源
- **Litesearch 知识库** + 快照式驾驶舱（非 PG 物化视图）
- **测试套件**在 SQLite/Litedb 上绿；无 Pgbus 依赖
- 运维：Tomo 单进程、`storage/` linked、演示账号说明

### Fixed

- 知识库：Litesearch 与 seed 时序不一致时 FTS 空结果 → **FTS ∪ LIKE** 并支持 rebuild

### Removed / Rejected (by design)

- PostgreSQL、`pg`、pgbus/PGMQ、Solid Cache/Queue/Cable
- 遗留 `/chat` 演示（pgbus SSE）
- 双栈兼容

---

## [2026-07-19] — 项目初始化

### Added

- Rails 8.1 + Phlex / DaisyUI / Hotwire 脚手架（Plexy Litestack 版）
- 初始 README 与 Litestack 数据面配置

---

## Notes

| 符号 | 含义 |
|------|------|
| 市直班 | `courses.district_id` IS NULL；市级录取；户籍区备案 |
| 区办班 | `courses.district_id` 指向开班区；开班区录取 |
| 生产 | https://agri3.fanglab.site |

更细的路径与角色操作见 [`docs/handbook.md`](docs/handbook.md)。  
完整提交历史：`git log --oneline`。

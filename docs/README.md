# Documentation index (agri3)

齐鲁农创客全过程管理系统 — **产品设计权威**与 **Litestack 运行说明**。

## Product (authoritative)

| Doc | Purpose |
|-----|---------|
| [product/mission.md](product/mission.md) | 使命、用户、成功标准 |
| [product/mvp-plan.md](product/mvp-plan.md) | MVP 范围与风险 |
| [product/roadmap.md](product/roadmap.md) | Phase 1–3 路线图 |
| [product/tech-stack.md](product/tech-stack.md) | **当前**技术选型（Litestack AIO） |

## Architecture & ops

| Doc | Purpose |
|-----|---------|
| [handbook.md](handbook.md) | 架构 / 使用者 / 运维手册（含 seed 账号与登录后能力） |
| [exports/agri3-handbook.html](exports/agri3-handbook.html) | 手册 HTML 导出（系统中文字体；浏览器可打印） |
| [er-diagram.md](er-diagram.md) | 业务 ER（语义）；物理类型见 tech-stack |
| [seeds.md](seeds.md) | Oaken 数据集、八倍演示规模与按场景维护 |

## Plans

| Doc | Purpose |
|-----|---------|
| [plans/litestack-port-plan.md](plans/litestack-port-plan.md) | 自 `react_demo_2` 全量业务移植单元 |
| [plans/qilu-ui-migration.md](plans/qilu-ui-migration.md) | 齐鲁界面原型迁移、页面映射与模型调整 |
| [plans/react_demo_2_legacy/](plans/react_demo_2_legacy/) | 历史 kamal-proxy 笔记（网关仍可参考） |

## Archive / reference only

| Path | Note |
|------|------|
| [reference_superpowers_from_react_demo_2/](reference_superpowers_from_react_demo_2/) | 原 chat / tomo+pgbus 设计稿，**非**当前实现权威 |
| [archive/database-issues/](archive/database-issues/) | PG schema dump 与 PGMQ 历史坑；SQLite 栈不适用 |

代码与 `config/database.yml` 冲突时 **以代码为准**；产品范围冲突时 **以 `product/*` 为准**。

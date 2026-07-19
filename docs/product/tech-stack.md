# Tech Stack（agri3 / Litestack 版）

**版本：** 1.0  
**日期：** 2026-07-19  
**状态：** 权威（取代 react_demo_2 的 PG + pgbus 运行时选型）

产品范围（谁用、做什么）仍以 `mission.md` / `mvp-plan.md` / `roadmap.md` 为准。  
本文只定 **怎么跑**：实现仓库 **agri3**，数据面 **完全依托 Litestack**。

## Decision Principles

1. **AIO 优先** — 主库、缓存、队列、Cable 同一套 SQLite 文件面，运维面最小。  
2. **无聊默认** — Rails 8.1 + Hotwire + Phlex；不为「以后可能多机写扩展」预埋 Postgres。  
3. **单实例写路径** — 与 Tomo 单 Puma 槽位一致；Litejob 进程内，避免多进程抢 SQLite。  
4. **设计文档权威、基础设施可替换** — 业务语义从 react_demo_2 移植；pg/pgbus/solid 边缘全部丢掉。  
5. **中文检索一等公民** — 知识库用 Litesearch；需要时启用 libsimple（已 vendor）。

## Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Runtime | Ruby 4.0+ / Rails ~> 8.1 | 与脚手架及 litestack fork 对齐 |
| Web | Puma | Tomo 已有 unit；单进程模型友好 SQLite |
| Database | **Litedb**（SQLite via Litestack） | 替换 PostgreSQL；零独立 DB 主机 |
| Cache | **Litecache** | 替换 solid_cache |
| Active Job | **Litejob**（in-process） | 替换 pgbus/PGMQ；无独立 worker 进程 |
| Action Cable | **Litecable** | 替换 solid_cable；挂载 `/cable` |
| Full-text | **Litesearch**（+ optional libsimple） | 替换 `tsvector` / `ILIKE` 知识库路径 |
| Vector (optional) | **Litevector** / vectorlite | 预留；MVP 非必须 |
| Front-end | Hotwire + importmap + Propshaft | 与 react_demo_2 一致 |
| CSS | Tailwind + DaisyUI | 同左 |
| Views | Phlex + phlex-reactive + phlex-forms | 主 UI；不用 ERB 扩业务页 |
| Icons | glyphs + rails_icons | 同左 |
| Admin CRUD | Avo + 自研 `/admin` | 从 react_demo_2 移植 |
| Auth | Session + bcrypt | Admin / Student |
| Spreadsheet | roo / caxlsx | Excel 导入导出 |
| Deploy | Tomo（storage linked） | 无 pgbus systemd；可选 kamal-proxy 网关 |
| Hosting shape | 单机 `web2` 槽位 | `APP_HOST` + loopback Puma |

## Data layout

```text
storage/                         # config.litestack.data_path（生产 linked）
  <env>/data.sqlite3             # 主业务库（Litedb）
  …                              # Litecache / Litejob / Litecable 文件由 litestack 管理
```

可选：`LITESTACK_DATA_PATH` 覆盖根路径。

## Scheduling (T+1 matching)

| 旧（react_demo_2） | 新（agri3） |
|--------------------|-------------|
| `config/recurring.yml` + pgbus dispatcher | **cron / systemd timer** 调 `DailyMatchingJob.perform_later`，或 job 自重排 |
| 独立 `bin/pgbus start` | **无**；Litejob 随 Puma |

## Type / SQL mapping (port notes)

| PostgreSQL (source) | SQLite / Litedb (target) |
|---------------------|---------------------------|
| `jsonb` | `json`（AR 序列化保持） |
| `tsvector` + `@@` | Litesearch 索引 API；去掉 `search_vector` 列 |
| `ILIKE` | `LIKE` + 大小写不敏感策略，或走 Litesearch |
| 物化视图驾驶舱 | 应用层快照表 / 普通 VIEW + 定时 `materialize!` |
| PGMQ / `pgbus_*` 表 | **不建**；Litejob 内部存储 |
| solid_cache / solid_cable 表 | **不建** |

## Alternatives Rejected

| Alternative | Why Rejected |
|-------------|--------------|
| 继续 PostgreSQL + pgbus | 与 agri3 脚手架目标冲突；双进程与远程 PG 运维成本高 |
| 双栈（PG + SQLite）兼容层 | migration/测试永久分叉，违背 AIO |
| Solid Queue/Cache/Cable on SQLite | 已选 Litestack 统一面，避免第二套 solid |
| 保留 `/chat` + pgbus SSE | 非产品；绑死 pgbus，移植噪音大 |
| Redis 作为 cache/cable/job | 再引入外部依赖，无当前规模收益 |
| 多 Puma worker 抢同一 SQLite | 写锁风险；保持单 worker 直到有证据需要扩展 |

## Ops constraints (non-negotiable)

1. 生产 **一个** 写入口（单 Puma + in-process Litejob）。  
2. `storage/` 必须在发布间 **持久**（Tomo linked）。  
3. 每日备份 `storage/`；迁移前必备可回滚副本。  
4. 数据文件放在具备可靠锁与 fsync 的本地盘，不放不可靠网络盘。  

## Source of truth

| Concern | Document |
|---------|----------|
| Why / who | `docs/product/mission.md` |
| MVP scope | `docs/product/mvp-plan.md` |
| Phases | `docs/product/roadmap.md` |
| How to run (ops) | `docs/handbook.md` |
| Domain ER | `docs/er-diagram.md` |
| Code port units | `docs/plans/litestack-port-plan.md` |
| Scaffold quickstart | 仓库根 `README.md` |

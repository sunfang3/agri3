# Implementation Plan: Port react_demo_2 → agri3 (Litestack)

**Version:** 1.0  
**Date:** 2026-07-19  
**Status:** Complete (U0–U9 landed on agri3/Litestack)  
**Source app:** `../react_demo_2` (PostgreSQL + pgbus + solid_*)  
**Target app:** this repo `agri3` (Litestack AIO — already scaffolded)  
**Product authority:** `docs/product/*`, `docs/handbook.md`, `docs/er-diagram.md`  
**Scope decision:** Full Phase 1–3 **business** code; **not** chat/pgbus demo; **not** dual-stack.

---

## Architecture (port shape)

```text
docs (done) ──► gems/config ──► SQLite schema ──► models/services
                    │                                    │
                    ▼                                    ▼
              jobs/schedule/FTS ◄── controllers/views/forms/avo
                    │
                    ▼
              tests + tomo/README cleanup
```

**Rule:** Copy domain code surgically. **Rewrite** migrations, search, schedule, deploy plugins, and anything that mentions `pg`, `pgbus`, `jsonb`, `tsvector`, `solid_*`.

---

## Out of scope (explicit)

- `/chat`, `ChatMessage`, pgbus stream mount, `pgbus-stream-source` tests  
- PostgreSQL extensions / PGMQ schema dump workarounds  
- Solid Cache/Queue/Cable  
- Dual adapter support  
- Re-running historical PG migrations as-is  

---

### Unit 0: Docs & tech alignment — **DONE**

**Goal:** Product design lives in agri3 with Litestack-accurate ops docs.  

**Requirements trace:** Port decision; handbook/tech-stack rewrite.  

**Delivered:**
- `docs/product/{mission,mvp-plan,roadmap,tech-stack}.md`
- `docs/handbook.md`, `docs/er-diagram.md` (infra rewritten)
- This plan file  
- Historical notes under `docs/plans/react_demo_2_legacy/`, `docs/reference_superpowers_from_react_demo_2/`, `docs/archive/`

**Verification:** Docs reference Litestack paths; no operational “run pgbus / DATABASE_URL postgres” as current truth.

---

### Unit 1: Application gems & config wiring

**Goal:** agri3 can load the same **product dependencies** as react_demo_2 without PG/pgbus.  

**Requirements trace:** MVP admin/student auth, Excel, Avo.  

**Dependencies:** Unit 0  

**Files (expected):**
- `Gemfile` / `Gemfile.lock` — add `avo`, `bcrypt`, `roo`, `caxlsx`; keep `litestack`; **no** `pg`, `pgbus`, `solid_cache`, `solid_cable`
- `config/application.rb` — module name remains `Agri3`; queue adapter already litejob in production
- `config/initializers/avo.rb` — port from source, drop solid_cache comments that imply PG solid
- `config/routes.rb` — mount cable only (no pgbus)
- `config/puma.rb` — no `plugin :pgbus_streams`
- `Procfile.dev` — web + css only (no `jobs:`)

**Approach:**
1. Add gems; `bundle install`.  
2. Run Avo install generator if needed; align with existing Phlex layout.  
3. Grep for `pgbus|solid_|postgresql` in config and delete/adapt.

**Patterns:** Follow existing agri3 README litestack conventions.  

**Test scenarios:**
- [ ] `bundle check` succeeds  
- [ ] `bin/rails runner 'puts Rails.application.class.name'` → Agri3  
- [ ] Boot does not require `DATABASE_URL` postgres  

**Verification:** App boots with `bin/rails runner 'puts :ok'`.  

**Planning-time unknowns:** Avo + Phlex layout quirks — **Deferred to implementation**.

---

### Unit 2: Business schema (SQLite rewrite)

**Goal:** One (or few) migrations that create the **full Phase 1–3 business schema** on Litedb.  

**Requirements trace:** ER domains in `docs/er-diagram.md`; MVP + V1.1 + V1.2 tables.  

**Dependencies:** Unit 1  

**Files:**
- `db/migrate/YYYYMMDDHHMMSS_create_platform_core.rb` — rewritten from `react_demo_2/db/migrate/20260714000001_create_platform_core.rb`
- **Do not** port: pgbus migration, solid_cache/cable migrations, chat_messages  
- `db/schema.rb` — regenerated  
- `db/seeds.rb` — port Jinan 10+2 districts, sample admins/students, tags, one matching pass  

**Approach:**
1. Map `t.jsonb` → `t.json`.  
2. Drop `t.tsvector :search_vector`; knowledge search later via Litesearch (Unit 6).  
3. Keep indexes/FKs that SQLite supports; avoid PG-only index ops.  
4. Prefer schema dump verification over replaying source migrations.

**Patterns:** agri3 `database.yml` litedb; idle_timeout 0.  

**Test scenarios:**
- [ ] `bin/rails db:drop db:prepare` (dev) succeeds  
- [ ] `RAILS_ENV=test bin/rails db:prepare` succeeds  
- [ ] Seed creates districts count = 12 and sample admin can be found  
- [ ] No `pgmq` / `pgbus_` / `solid_` tables in `schema.rb`  

**Verification:** `schema.rb` lists core business tables from ER (students, policies, courses, enrollments, resource_matches, analytics_events, …).  

**Planning-time unknowns:** Exact SQLite index name length / JSON default quirks — **Deferred**.

---

### Unit 3: Models & pure domain services

**Goal:** Port ActiveRecord models and service objects that do not depend on PG SQL dialects.  

**Requirements trace:** Matching, enrollment state machine, Excel import, fake adapters, tips, push interfaces.  

**Dependencies:** Unit 2  

**Files:**
- `app/models/**` from source (exclude `chat_message.rb`)  
- `app/services/**`  
- `app/jobs/application_job.rb` (base); job classes in Unit 5  
- Model concerns  

**Approach:**
1. Copy models; fix any `jsonb` column assumptions in code to `json`.  
2. Port services; isolate PG SQL in knowledge/dashboard for Unit 6.  
3. Temporarily stub or skip FTS methods until Unit 6 if needed to keep boot green.

**Patterns:** Plain PORO services under `app/services`; Fake adapters.  

**Test scenarios:**
- [ ] Port unit tests for `Matching::RuleEngine`, `CosineEngine`, `Enrollment`, `ExcelImporter`  
- [ ] Enrollment state transitions pending→enrolled→completed / dropped  
- [ ] Rule score 0–100 formula matches handbook  

**Verification:** Focused model/service tests green under SQLite.  

**Planning-time unknowns:** None blocking.

---

### Unit 4: Auth, student PWA, admin app, forms, views

**Goal:** End-user and admin HTTP surfaces work on agri3.  

**Requirements trace:** MVP modules 1–7; Phase 2/3 UI already in source.  

**Dependencies:** Unit 3  

**Files:**
- `app/controllers/student_app/**`, `admin_app/**`, concerns  
- `app/forms/**`  
- `app/views/student_app/**`, `admin_app/**`, layouts  
- `app/components/**` (exclude chat/*)  
- `config/routes.rb` product routes  
- `app/controllers/application_controller.rb` browser/session bits  

**Approach:**
1. Copy routes for student/admin/avo; keep agri3 `/cable` mount.  
2. Port Phlex views; ensure `Views::Base` / `Components::Base` match agri3 includes.  
3. Session keys `student_id` / `admin_id` as source.  
4. Home landing page becomes platform entry (replace counter demo when ready).

**Patterns:** Existing Phlex + DaisyUI in both apps.  

**Test scenarios:**
- [ ] Integration: student register/login, home shows matches after seed  
- [ ] Integration: admin login, bulk confirm, import dry-run  
- [ ] Security: student without password_digest cannot login  
- [ ] Survey flow / platform routes tests ported  

**Verification:** Manual `bin/dev` smoke: `/student/login`, `/admin/login`, `/avo`.  

**Planning-time unknowns:** Avo auth hook with session admin — **Deferred** (copy source initializer).

---

### Unit 5: Jobs & T+1 schedule

**Goal:** `DailyMatchingJob` and `ProcessVoiceNoteJob` run on Litejob; daily schedule without pgbus.  

**Requirements trace:** MVP matching T+1; Phase 2 voice pipeline.  

**Dependencies:** Unit 3  

**Files:**
- `app/jobs/daily_matching_job.rb`, `process_voice_note_job.rb`  
- Schedule mechanism: prefer `config` + documented cron/timer **or** self-reschedule in job  
- Remove any `config/recurring.yml` expectation from docs already done  
- Tomo notes / optional systemd timer template under `.tomo/` or `ops/`  

**Approach:**
1. Jobs are plain ActiveJob — should run on `:litejob` unchanged.  
2. Choose **one** schedule strategy and document in handbook:  
   - **A (recommended):** host cron / systemd timer → `perform_later("rules")`  
   - **B:** first boot enqueues; job end reschedules next 02:00  
3. Test with `ActiveJob::TestHelper` / perform_now.

**Patterns:** Source job argument compatibility (`"rules"` positional).  

**Test scenarios:**
- [ ] `DailyMatchingJob.perform_now("rules")` creates/updates resource_matches  
- [ ] `perform_now("cosine")` path works  
- [ ] Voice job with Fake ASR/LLM pipeline  

**Verification:** Seed + job leaves non-empty matches for tagged student.  

**Planning-time unknowns:** Final schedule strategy A vs B — **Deferred** (default A).

---

### Unit 6: Knowledge FTS + dashboard snapshots

**Goal:** Replace PG full-text and materialized-view assumptions.  

**Requirements trace:** Phase 3 knowledge base; city cockpit.  

**Dependencies:** Unit 2–3  

**Files:**
- `app/models/knowledge_article.rb` — Litesearch API  
- Possibly migration for search config / drop dead columns  
- `app/services/dashboard/city_cockpit.rb` — snapshot table refresh without PG matview  

**Approach:**
1. Follow litestack Litesearch docs; enable `:simple` tokenizer if Chinese.  
2. `full_text_search` uses Litesearch; fallback simple `LIKE` only if needed.  
3. `materialize!` writes a normal table or recomputes aggregates.

**Patterns:** `config/initializers/litestack_extensions.rb` already probes libsimple.  

**Test scenarios:**
- [ ] Chinese keyword finds seeded article when libsimple present  
- [ ] Empty query returns none  
- [ ] Cockpit numbers match direct counts for seed data  

**Verification:** `/student/knowledge` search returns hit in integration test.  

**Planning-time unknowns:** Exact Litesearch model DSL for this litestack fork — **Resolve in implementation** by reading gem docs/examples.

---

### Unit 7: Avo resources

**Goal:** Admin CRUD parity for core resources.  

**Requirements trace:** MVP policy/course/tag management.  

**Dependencies:** Unit 4  

**Files:**
- `app/avo/resources/**`  
- Avo controllers if customized  

**Approach:** Copy resources; fix any PG-specific field types.  

**Test scenarios:**
- [ ] Boot `/avo` with admin session (or source’s auth strategy)  
- [ ] Create policy with tags  

**Verification:** Smoke visit `/avo` after login path.  

**Planning-time unknowns:** Avo version drift — pin compatible with source `~> 3.0`.

---

### Unit 8: Test suite port & green bar

**Goal:** Port relevant minitest files; remove pgbus/chat/PG deployment assertions.  

**Requirements trace:** Quality gate before claiming port complete.  

**Dependencies:** Units 3–7  

**Files:**
- `test/**` from source, excluding chat system tests and pgbus-specific deployment tests  
- `test/test_helper.rb` — drop `Pgbus::Testing`  
- Adapt production_database / tomo tests to litestack + agri3 tomo config  

**Approach:**
1. Port domain/integration tests first.  
2. Rewrite or delete: `stream_route_test`, chat tests, pgbus tomo plugin tests.  
3. Add lite assertions: schema has no pgbus; database adapter is litedb.

**Test scenarios:**
- [ ] `bin/rails test` full green  
- [ ] No references to `Pgbus` in test tree  

**Verification:** CI-equivalent `bin/ci` or `bin/rails test` exit 0.  

**Planning-time unknowns:** System tests needing browser — keep if env allows.

---

### Unit 9: Deploy & README finalization

**Goal:** Tomo/ops match single-process Litestack; operators not told to run pgbus.  

**Requirements trace:** Production readiness.  

**Dependencies:** Unit 5, 8  

**Files:**
- `.tomo/config.rb` and plugins — ensure no pgbus plugin required  
- Root `README.md` — product one-liner + link to docs  
- Optional `ops/` timer example for DailyMatchingJob  

**Approach:**
1. Diff agri3 vs react_demo_2 tomo; keep agri3 litestack path.  
2. Document `APP_HOST`, storage link, no `DATABASE_URL` postgres.  
3. If sharing host with old react_demo, separate app name / storage / port.

**Test scenarios:**
- [ ] `bundle exec tomo run --dry-run` tasks that matter exist  
- [ ] README matches handbook §3  

**Verification:** Dry-run deploy config consistent; handbook + README agree.  

**Planning-time unknowns:** Whether production data migrates from PG dump — **out of band**; default is fresh seed/import Excel, not automatic PG→SQLite dump.

---

## Dependency DAG

```text
U0(docs done)
  └─► U1 gems/config
        └─► U2 schema/seeds
              ├─► U3 models/services ─┬─► U4 HTTP/UI ─► U7 Avo
              │                       └─► U5 jobs
              └─► U6 FTS/dashboard
        U3–U7 ─► U8 tests ─► U9 deploy/README
```

---

## Quality bar

- [x] Units have requirements traces  
- [x] Dependencies form a DAG  
- [x] Each unit has ≥3 test scenarios (or explicit doc verification for U0)  
- [x] No unit requires inventing product behavior (docs are authority)  
- [x] Chat/pgbus explicitly excluded  
- [x] PG type mappings listed  

---

## Suggested PR slicing

| PR | Units | Title idea |
|----|-------|------------|
| 1 | U0 | docs: product design + litestack port plan |
| 2 | U1–U2 | feat: platform schema on litedb + product gems |
| 3 | U3–U5 | feat: domain models, services, matching jobs |
| 4 | U4+U7 | feat: student/admin UI and Avo |
| 5 | U6+U8 | feat: litesearch knowledge + port tests green |
| 6 | U9 | chore: tomo/readme ops for litestack-only |

---

## Success criteria for “port complete”

1. Product docs + handbook describe Litestack-only ops.  
2. Phase 1–3 business features from handbook reachable without PG/pgbus.  
3. `bin/rails test` green on SQLite.  
4. T+1 matching can be triggered and scheduled without pgbus.  
5. Knowledge search works via Litesearch (Chinese path documented).  
6. Deploy path does not start a second job supervisor.

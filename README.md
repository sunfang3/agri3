# Agri3

Rails application scaffolded from the **Plexy** template (Litestack edition): Phlex UI, DaisyUI, Hotwire, and an all-SQLite data plane via [sunfang3/litestack](https://github.com/sunfang3/litestack).

## Stack

| Layer | Choice |
| --- | --- |
| Runtime | **Ruby 4.0+** (`.ruby-version`), **Rails ~> 8.1** |
| Web server | **Puma** |
| Database | **Litedb** (SQLite via Litestack), not PostgreSQL |
| Cache | **Litecache** |
| Background jobs | **Litejob** (in-process workers; no separate job process) |
| Action Cable | **Litecable**, mounted at `/cable` |
| Full-text search | **Litesearch** (built-in tokenizers; optional Chinese/Pinyin via libsimple) |
| Vector search | **Litevector** (optional, vectorlite extension) |
| Front-end | **Hotwire** (Turbo + Stimulus), **importmap-rails**, **Propshaft** |
| CSS | **Tailwind CSS** + **DaisyUI** (`bin/tailwindcss` → `/usr/local/bin/tailwindcss`) |
| Views | **Phlex** (`phlex-rails`), with **phlex-reactive** and **phlex-forms** |
| Icons | **glyphs** + **rails_icons** (Lucide / Heroicons) |
| Deploy | **Tomo** (local git → remote release); optional Kamal leftover from Rails default |

There is **no Redis, Postgres, Solid Cache/Queue/Cable, or pgbus**. Durable files live under `storage/` (`config.litestack.data_path`).

## Requirements

- Ruby matching `.ruby-version` (or compatible 4.0.x)
- Bundler
- `/usr/local/bin/tailwindcss` (the system-wide Tailwind CSS CLI)
- Optional: `python3` + network if re-fetching Litestack native extensions

## Quick start

```bash
bin/setup --skip-server
bin/rails db:prepare
bin/dev
```

- App: [http://localhost:3000](http://localhost:3000)
- Health: `GET /up`
- Action Cable: `ws://localhost:3000/cable` (WebSocket upgrade only)

`bin/dev` runs `Procfile.dev`:

```
web: bin/rails server
css: bin/rails tailwindcss:watch
```

No `jobs:` process — Litejob runs inside the web process.

## Configuration

### Environment

`.env` (gitignored) is used by Tomo and local tooling:

```bash
APP_HOST=agri3.fanglab.site
```

Optional:

```bash
# Override Litestack data root (default: Rails.root/storage via application.rb)
LITESTACK_DATA_PATH=/var/lib/agri3
```

### Database paths

`config/database.yml` uses Litedb. Paths resolve as:

```text
storage/<env>/data.sqlite3
```

because `config.litestack.data_path = Rails.root.join("storage")` in `config/application.rb`.

### Litestack adapters

| Concern | Setting |
| --- | --- |
| Active Record | `adapter: litedb` |
| Cache (production) | `config.cache_store = :litecache` |
| Active Job (production) | `config.active_job.queue_adapter = :litejob` |
| Active Job (test) | `:test` |
| Action Cable | `adapter: litecable` in `config/cable.yml` |

### Optional native extensions

Installed under `vendor/` (platform-specific `.so` / `.dylib`), wired in `config/initializers/litestack_extensions.rb`:

| Extension | Path pattern | Purpose |
| --- | --- | --- |
| libsimple | `vendor/simple/<platform>/` | Chinese / Pinyin FTS (`tokenizer :simple`) |
| vectorlite | `vendor/vectorlite/<platform>/` | Vector kNN (Litevector) |

Re-fetch from the app root if missing:

```bash
export LITESTACK_EXTENSION_ROOT="$PWD"
bundle exec ruby "$(bundle show litestack)/scripts/fetch_simple.rb"
bundle exec ruby "$(bundle show litestack)/scripts/fetch_vectorlite.rb"
```

Core stack works without these binaries.

## Project layout (UI)

| Path | Role |
| --- | --- |
| `app/components/base.rb` | Shared Phlex components (`DaisyUI`, `Glyphs`, `Forms`) |
| `app/views/base.rb` | Page views |
| `app/forms/application_form.rb` | phlex-forms base (`ApplicationForm`) |
| `app/components/counter.rb` | Example **phlex-reactive** component |
| `app/components/broadcasting.rb` | Peer Turbo stream helpers |
| `app/views/pages/home.rb` | Home page (`turbo_stream_from` + counter) |

Conventions:

- Components → `Components::*`
- Views → `Views::*`
- Prefer Phlex over ERB for new UI

Tailwind `@source` scans DaisyUI / phlex-forms gem sources via symlinks created by `bin/setup` (`vendor/daisyui-src`, `vendor/phlex-forms-src`).

## Development notes

```bash
# Migrations / schema
bin/rails db:prepare
bin/rails db:migrate

# Tests
bin/rails test

# Security / style (optional)
bin/brakeman
bin/rubocop

# phlex-reactive health
bin/rails phlex_reactive:doctor
```

### Action Cable mount

Routes explicitly mount cable (Rails 8.1 `LazyRouteSet` can drop the automatic mount on reload):

```ruby
mount ActionCable.server => "/cable"
```

Plain HTTP `GET /cable` without a WebSocket upgrade is expected to fail; clients must use WebSocket.

## Deployment (Tomo)

Config lives under `.tomo/`. Production env is set from `.env` (`APP_HOST`) plus generated secrets.

Slot for this app: **web2**, Puma port **3001**, host **agri3.fanglab.site**.

```bash
bundle exec tomo setup   # first time
bundle exec tomo deploy
```

Production git remote (template default):

```text
ssh://web2@43.133.189.82:22020/home/web2/repos/agri3.git
```

Important production details:

- `storage/` is a **linked** shared directory so SQLite / Litestack files survive releases
- Litejob runs **in-process** with Puma — no separate systemd job unit
- Ruby on the host: rbenv `4.0-jemalloc` (see `.tomo/config.rb`)

## What this app deliberately avoids

- PostgreSQL / `pg` / `DATABASE_URL` Postgres setup
- pgbus / PGMQ job workers
- Solid Cache, Solid Queue, Solid Cable
- Separate Redis for cache, jobs, or cable (unless you add it later)

## License

Application code follows the project’s own license; third-party gems keep their respective licenses.

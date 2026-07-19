# Tomo Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure tomo to deploy the Rails chat application to `fang@192.168.10.99` with rbenv Ruby `4.0-jemalloc`, one PostgreSQL database, and supervised Puma and pgbus processes.

**Architecture:** Rails will use one production Active Record connection and one migration history for application, pgbus, Solid Cache, and Solid Cable tables. Tomo's built-in plugins will manage releases and Puma; a focused local plugin will manage pgbus as a second systemd user service.

**Tech Stack:** Rails 8.1, PostgreSQL/PGMQ, pgbus, Puma, systemd user services, tomo 1.22, rbenv

---

## File Map

- `config/database.yml`: expose one production connection backed by `DATABASE_URL`.
- `config/cache.yml`: make Solid Cache use the primary connection.
- `config/cable.yml`: make Solid Cable use the primary connection.
- `db/migrate/20260712000000_create_solid_cache_entries.rb`: add cache storage to the primary migration history.
- `db/migrate/20260712000001_create_solid_cable_messages.rb`: add cable storage to the primary migration history.
- `db/schema.rb`: record the consolidated single-database schema.
- `Gemfile` and `Gemfile.lock`: pin tomo 1.22 for reproducible operator commands and tests.
- `.tomo/config.rb`: define the host, plugins, settings, setup tasks, and deploy tasks.
- `.tomo/plugins/pgbus.rb`: install, operate, and check the pgbus systemd user service.
- `.tomo/templates/pgbus.service.erb`: keep the systemd unit separate from task orchestration.
- `test/config/production_database_test.rb`: protect the single-connection production contract.
- `test/deployment/tomo_config_test.rb`: prove tomo loads the expected settings, tasks, and dry-run order.
- `README.md`: document prerequisites and operator commands without secrets.

### Task 1: Consolidate Production Database Configuration

**Files:**
- Create: `test/config/production_database_test.rb`
- Modify: `config/database.yml`
- Modify: `config/cache.yml`
- Modify: `config/cable.yml`

- [ ] **Step 1: Write the failing production configuration test**

Parse the YAML files with `ERB` and assert that production has one database
configuration with an explicit `DATABASE_URL`, while cache and cable have no
named database selector.

```ruby
class ProductionDatabaseTest < ActiveSupport::TestCase
  test "production services share the primary database" do
    database = parsed_yaml("config/database.yml").fetch("production")
    cache = parsed_yaml("config/cache.yml").fetch("production")
    cable = parsed_yaml("config/cable.yml").fetch("production")

    assert_equal %w[adapter encoding max_connections url], database.keys.sort
    assert_equal ENV.fetch("DATABASE_URL"), database.fetch("url")
    refute cache.key?("database")
    refute cable.key?("connects_to")
  end
end
```

- [ ] **Step 2: Run the test and verify RED**

Run: `DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails test test/config/production_database_test.rb`

Expected: FAIL because production still contains four named configurations and cache/cable select named roles.

- [ ] **Step 3: Implement the single connection**

Make production inherit the common PostgreSQL defaults and set:

```yaml
production:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL") %>
```

Remove `database: cache` from production cache config and remove `connects_to`
from production cable config.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run the command from Step 2.

Expected: 1 test, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add config/database.yml config/cache.yml config/cable.yml test/config/production_database_test.rb
git commit -m "refactor(db): Use one production connection"
```

### Task 2: Consolidate Cache and Cable Schemas

**Files:**
- Create: `db/migrate/20260712000000_create_solid_cache_entries.rb`
- Create: `db/migrate/20260712000001_create_solid_cable_messages.rb`
- Modify: `db/schema.rb`
- Modify: `test/config/production_database_test.rb`

- [ ] **Step 1: Extend the test to require all shared tables**

Assert that `db/schema.rb` contains `solid_cache_entries` and
`solid_cable_messages` alongside `chat_messages` and pgbus tables.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because the cache and cable tables only exist in separate schema files.

- [ ] **Step 3: Add primary migrations**

Create Rails 8.1 migrations matching the existing definitions in
`db/cache_schema.rb` and `db/cable_schema.rb`, including their unique and lookup
indexes. Do not drop the separate schema files; Rails generators may still use
them as reference, but production no longer loads them.

- [ ] **Step 4: Migrate and dump schema**

Run: `DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails db:migrate`

Expected: both migrations apply and `db/schema.rb` contains both tables.

- [ ] **Step 5: Verify a fresh database schema load**

Run:

```bash
DATABASE_URL=postgresql:///react_demo_tomo_test RAILS_ENV=test bin/rails db:drop db:create db:migrate
DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails test test/config/production_database_test.rb
DATABASE_URL=postgresql:///react_demo_tomo_test RAILS_ENV=test bin/rails db:drop db:create db:schema:load
DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails test test/config/production_database_test.rb
```

Expected: both the migration path and schema load path succeed, and the focused
test passes after each fresh database build. Every destructive command carries
the disposable database URL inline, so it cannot inherit a production URL.

- [ ] **Step 6: Commit**

```bash
git add db/migrate db/schema.rb test/config/production_database_test.rb
git commit -m "feat(db): Add cache and cable to primary schema"
```

### Task 3: Add the Tomo Configuration

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Create: `test/deployment/tomo_config_test.rb`
- Create: `.tomo/config.rb`

- [ ] **Step 1: Pin tomo and install the bundle**

Add `gem "tomo", "~> 1.22", require: false` to the development/test tooling
group and run `bundle install`. All repository commands and tests use
`bundle exec tomo` so clean operator machines receive the tested version.

- [ ] **Step 2: Write the failing tomo configuration test**

Use `Open3.capture3` to invoke `bundle exec tomo tasks --no-color`. Assert success and task
names for `rbenv:install`, `puma:setup_systemd`, and `pgbus:setup_systemd`.
Invoke `bundle exec tomo deploy --dry-run --debug --no-color` to assert settings
such as `rbenv_ruby_version: 4.0-jemalloc` and the GitHub URL. Keep command
ordering assertions limited to normal dry-run output: database migration,
asset precompile, current symlink, and both service restarts.

- [ ] **Step 3: Run the test and verify RED**

Run: `DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails test test/deployment/tomo_config_test.rb`

Expected: FAIL because `.tomo/config.rb` does not exist.

- [ ] **Step 4: Add the minimal tomo configuration**

Load `git`, `env`, `bundler`, `rails`, `puma`, `rbenv`, and the local pgbus
plugin. Configure:

```ruby
host "fang@192.168.10.99"
set application: "react_demo"
set deploy_to: "/home/fang/apps/%{application}"
set git_url: "https://github.com/sunfang3/react_demo.git"
set git_branch: "master"
set rbenv_ruby_version: "4.0-jemalloc"
```

Set prompted `DATABASE_URL`, generated `SECRET_KEY_BASE`, `RBENV_VERSION`,
Rails production variables, shared directories, and explicit setup/deploy task
lists from the approved design. Exclude `.tomo/` and tests from remote release
archives.

- [ ] **Step 5: Run the test to reach the plugin-specific failure**

Expected: tomo loads the core configuration but fails because the pgbus plugin is absent.

### Task 4: Add the Pgbus Systemd Plugin

**Files:**
- Create: `.tomo/plugins/pgbus.rb`
- Create: `.tomo/templates/pgbus.service.erb`
- Modify: `test/deployment/tomo_config_test.rb`

- [ ] **Step 1: Add dry-run assertions for service behavior**

Assert that `bundle exec tomo run --dry-run pgbus:setup_systemd` writes and enables
`pgbus_react_demo.service`, and that restart/check tasks call systemd for the
same unit.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because the pgbus tasks and service template are absent.

- [ ] **Step 3: Implement the focused plugin**

Define defaults for the service name/path/template and tasks:

- `setup_systemd`: check linger, create the user systemd directory, render the
  template, reload systemd, and enable the unit.
- `start`, `stop`, `restart`, `status`: delegate to `systemctl --user`.
- `check_active`: fail with status and recent journal output unless active.
- `log` and `tail_log`: expose the service journal.

The ERB unit must use `Type=simple`, `WorkingDirectory=<%= paths.current %>`, a
login shell executing `bin/pgbus start`, `Wants=network-online.target`,
`After=network-online.target`, `Restart=on-failure`, and a bounded graceful stop
timeout.

- [ ] **Step 4: Run tomo tests and verify GREEN**

Run: `DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails test test/deployment/tomo_config_test.rb`

Expected: all tomo task-load and dry-run assertions pass.

- [ ] **Step 5: Commit configuration and plugin**

```bash
git add .tomo test/deployment/tomo_config_test.rb
git commit -m "feat(deploy): Configure tomo and pgbus service"
```

### Task 5: Document and Verify Deployment Operations

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add concise operator documentation**

Document:

- `sudo loginctl enable-linger fang` on the app host.
- PostgreSQL/PGMQ and `4.0-jemalloc` ruby-build definition prerequisites.
- Bundler followed by `bundle exec tomo`, with tomo 1.22 pinned in the bundle.
- `tomo setup`, prompted `DATABASE_URL`, `tomo deploy`, and service log tasks.
- The database URL shape without including the real password.

- [ ] **Step 2: Run local verification**

```bash
ruby -c .tomo/config.rb
ruby -c .tomo/plugins/pgbus.rb
bundle exec tomo tasks --no-color
bundle exec tomo deploy --dry-run --debug --no-color
DATABASE_URL=postgresql:///react_demo_tomo_test bin/rails test
bin/rubocop db/migrate test/config test/deployment .tomo/plugins/pgbus.rb
bin/brakeman --no-pager
```

Expected: syntax checks and all test/static analysis commands pass; dry-run
shows migrations before symlink activation and both services restarted after.

- [ ] **Step 3: Commit documentation**

```bash
git add README.md
git commit -m "docs(deploy): Add tomo operator guide"
```

### Task 6: Push and Run Deployment Preflight

**Files:** None.

- [ ] **Step 1: Push all implementation commits**

Run: `git push origin master`

- [ ] **Step 2: Verify application host prerequisites**

Use SSH to check connectivity, OS/systemd user support, linger status, write
access to `/home/fang/apps/react_demo`, the Ruby/native-gem build toolchain (including
PostgreSQL and jemalloc headers), `4.0-jemalloc` availability, and network
reachability from `192.168.10.99` to PostgreSQL at `192.168.10.66:5432`.
Perform an authenticated database preflight for database/schema/extension
creation privileges without printing or persisting the password.

- [ ] **Step 3: Run tomo setup**

Run: `bundle exec tomo setup` and provide the production database URL only at
tomo's secure prompt. If privileged host prerequisites are missing, stop with
the exact administrator command required rather than weakening service
supervision.

- [ ] **Step 4: Run tomo deploy and smoke test**

Run `bundle exec tomo deploy`, verify `puma:check_active` and
`pgbus:check_active`, then run `systemd-analyze --user verify` for the generated
pgbus unit and request `http://192.168.10.99:3000/up` and the chat root page.

- [ ] **Step 5: Report exact deployment state**

Record whether setup/deploy completed, which commit is live, the reachable URL,
and any external prerequisite that remains blocked.

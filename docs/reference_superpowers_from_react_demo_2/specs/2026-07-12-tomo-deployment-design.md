# Tomo Deployment Design

## Goal

Deploy the Rails chat application from the public GitHub repository to
`fang@192.168.10.99` with tomo. Run the application with the tomo rbenv
plugin using Ruby `4.0-jemalloc`, and connect every production Rails database
role to one PostgreSQL database on `192.168.10.66`.

## Deployment Architecture

Tomo will deploy releases from
`https://github.com/sunfang3/react_demo.git` into
`/home/fang/apps/react_demo`. The user-writable deployment tree avoids a
one-time privileged directory setup.
The standard `git`, `env`, `bundler`, `rails`, `puma`, and `rbenv` plugins will
manage releases, remote environment variables, dependencies, migrations,
assets, the web process, and Ruby installation.

The application also requires a continuously running pgbus dispatcher and
worker. A project-local tomo plugin will install a separate systemd user
service that runs `bin/pgbus start` from the current release. Keeping pgbus
separate from Puma gives each process an independent restart policy, status,
and journal.

## Ruby Selection

The tomo setting `rbenv_ruby_version` will be `4.0-jemalloc`. The remote
environment will also set `RBENV_VERSION=4.0-jemalloc`, because the repository
currently contains a different `.ruby-version` value and rbenv gives the
project file precedence over its global version.

The target host must have `4.0-jemalloc` installed in rbenv. Tomo loads the
rbenv plugin and uses its `rbenv_ruby_version` setting; a target-specific setup
task verifies that version rather than reinstalling an existing system rbenv.

## Database Configuration

The production database is `react_demo_production` on `192.168.10.66`, using
the PostgreSQL role supplied by the operator. The password and full connection
URL will not be committed. During `tomo setup`, the env plugin will prompt for
`DATABASE_URL` and store it in tomo's remote environment file with mode 0600.

Rails production configuration will expose one unnamed/default connection with
an explicit `url: <%= ENV.fetch("DATABASE_URL") %>`. Solid Cache and Solid
Cable will stop selecting named `cache` and `cable` connections and will use
the primary connection. The unused `queue` connection is removed because
Active Job uses pgbus.

The Solid Cache and Solid Cable table definitions will be converted into
normal migrations under `db/migrate`. This gives the single physical database
one `schema_migrations` history and one migration path. It avoids the ambiguous
and unsafe behavior of pointing multiple Rails database roles, each with its
own schema file and migration path, at the same physical database.

The PostgreSQL server must allow the configured role to connect to or create
`react_demo_production`. Loading the application schema also requires the PGMQ
extension used by pgbus to be available to that role/database.

Before tomo setup, an administrator on the application host must run
`sudo loginctl enable-linger fang`. Tomo manages Puma and pgbus as systemd user
services, and lingering is required for those services to survive logout and
start after reboot.

## Setup Flow

`tomo setup` will:

1. Store production environment variables and create release/shared paths.
2. Clone the public Git repository and create the first release.
3. Verify that rbenv provides `4.0-jemalloc`.
4. Install the locked Bundler version and application gems.
5. Create the database with Rails' idempotent `db:create` task and load the
   single production schema, including the application,
   pgbus, Solid Cache, and Solid Cable tables, then seed it.
6. Install and enable the Puma and pgbus systemd user services.

The environment will include `RAILS_ENV=production`,
`RAILS_LOG_TO_STDOUT=1`, `RAILS_SERVE_STATIC_FILES=1`,
`RBENV_VERSION=4.0-jemalloc`, a prompted `DATABASE_URL`, and a generated
`SECRET_KEY_BASE`.

## Deploy Flow

`tomo deploy` will:

1. Refresh non-secret environment settings and create a release.
2. Link shared directories and install gems.
3. Run database migrations and precompile assets.
4. Atomically update the `current` symlink.
5. Restart pgbus and Puma against the new current release.
6. Require pgbus to remain active through a stabilization window and require
   Puma's `/up` endpoint to return success.
7. Clean old releases and unused gems, then record the deployed revision.

The pgbus unit will be a foreground `Type=simple` service that starts only
after the network is online, stops gracefully through systemd's normal
termination signal, and restarts on failure. Both services load tomo's remote
environment through the deploy user's login shell.

## Failure Handling

Tomo stops before switching `current` when dependency installation,
migrations, or asset compilation fails. If a service fails after activation,
the active checks fail the deployment and leave its systemd journal available
for diagnosis. The plugin exposes pgbus status and log tasks alongside tomo's
existing Puma tasks.

Database credentials never appear in tracked files or command-line defaults.
Operators can rotate the database URL with tomo's `env:set` task and restart
both services.

## Verification

Before a real deployment, verification will include:

- Ruby syntax checks for tomo configuration and the custom plugin.
- `tomo tasks` to prove every configured task loads.
- `tomo deploy --dry-run` to inspect task ordering and remote commands.
- Rails tests and a production database configuration assertion that Rails,
  Solid Cache, Solid Cable, and Active Job all use the primary database.
- SSH connectivity to `fang@192.168.10.99` and PostgreSQL connectivity from
  the application host before running setup.
- A linger check for the `fang` systemd user before installing services.

The deployment is complete when Puma answers its active check, the pgbus
systemd service is active, migrations have succeeded against the single
production database, and the chat page is reachable on the configured Puma
port.

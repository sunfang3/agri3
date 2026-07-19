# Shared Kamal Proxy Tomo Integration Plan

## Architecture

The server has one native gateway process and any number of independently
deployed Rails applications. The gateway is host infrastructure, not a child
of the first Rails repository.

A dedicated `kamal-proxy` system user runs the installed Fork binary from a
system-level systemd unit. systemd grants only `CAP_NET_BIND_SERVICE`, creates
a stable group-restricted RPC directory at `/run/kamal-proxy`, and creates a
private state root at `/var/lib/kamal-proxy`. The service sets
`XDG_RUNTIME_DIR=/run/kamal-proxy` so all application CLIs can deliberately
address the same Unix socket. ACME settings live in root-managed
`/etc/kamal-proxy.env`.

Each Rails application keeps its own ignored `.env`, Tomo application name,
Linux deploy user, and loopback Puma port. Its deploy user belongs to the
shared `kamal-proxy` group. A reusable project-local Tomo plugin checks the
system service and socket contract, then calls the installed binary with the
same runtime directory to register exactly one route. The plugin never mutates
the gateway lifecycle.

```text
                       ┌─ APP_HOST=a.example.com ──> 127.0.0.1:3001 (app-a)
internet :80/:443 ──> shared native kamal-proxy
                       └─ APP_HOST=b.example.com ──> 127.0.0.1:3002 (app-b)
                                      │
                         /run/kamal-proxy/kamal-proxy.sock
                                      ▲
                     app-a user ──────┴────── app-b user
                         shared Unix group; shared route authority
```

### Unit 1: Server Gateway Bootstrap Contract

**Goal:** Define a reproducible, least-privilege systemd deployment for the
already-installed native Fork binary and its server-owned configuration.

**Requirements trace:** R3, R4, R7, R8, R9

**Dependencies:** None.

**Files:**
- `ops/kamal-proxy/kamal-proxy.service` — system service with dedicated identity, runtime/state directories, capabilities, hardening, and restart behavior.
- `ops/kamal-proxy/kamal-proxy.env.example` — non-secret ACME and optional future feature keys with advanced features disabled by default.
- `ops/kamal-proxy/release.example` — build commit, source branch/repository, SHA-256, build date, and Go version manifest format.
- `ops/kamal-proxy/README.md` — administrator bootstrap, verification, upgrade, rollback, backup, and deploy-user onboarding guide.

**Approach:** Provision a persistent system user and shared group named
`kamal-proxy`; application deploy users join only the group. Configure the
system unit with `User=kamal-proxy`, `Group=kamal-proxy`,
`RuntimeDirectory=kamal-proxy` mode `0770`, `StateDirectory=kamal-proxy` mode
`0700`, `HOME=/var/lib/kamal-proxy`, and
`XDG_RUNTIME_DIR=/run/kamal-proxy`. Use a restrictive umask so the RPC socket
is group-accessible while the state root remains private. Grant and bound only
`CAP_NET_BIND_SERVICE`; use service hardening that still permits AF_UNIX,
IPv4/IPv6, DNS, and writes to the declared runtime/state directories.

The root-owned `/etc/kamal-proxy.env` supplies `KAMAL_PROXY_ACME_EMAIL` and the
production ACME directory, intentionally enabling the Fork's shared SAN
certificate manager. DNS-provider secrets and all other extended Fork flags
remain absent. The admin copies the reviewed binary to `/usr/local/bin`, writes its
release manifest, validates the unit, and starts it. Upgrades use a staged
binary, recorded SHA, service restart, listener/socket checks, and an explicit
rollback to the prior binary; application deploys never perform this flow.
The administrator guide also owns application decommissioning: verify route
ownership, remove the named service through the shared CLI, then retire the
application user and port. This destructive action is intentionally absent
from application plugins.

**Patterns:** Follow systemd directory and capability directives instead of
filesystem `chown` commands embedded in application deploys. Keep secrets in a
root-managed environment file and logs in journald.

**Test scenarios:**
- [ ] Happy path: the unit starts the binary as the dedicated user and listens on 80/443.
- [ ] Happy path: an authorized deploy user can connect to the shared Unix socket but cannot traverse the state/certificate directory.
- [ ] Nil/empty input: a missing ACME email prevents the operator from declaring automatic TLS ready.
- [ ] Error path: an invalid binary path or failed bind produces a failed unit with journald diagnostics.
- [ ] Error path: a deploy user outside the group cannot connect to the RPC socket.
- [ ] Edge case: replacing the binary does not lose low-port permission because the capability belongs to the unit, not the file.
- [ ] Edge case: restart restores all routes and certificate state without an application deploy.
- [ ] Edge case: two explicit application hosts are registered with the shared SAN manager and remain visible as intentionally coupled certificate identities.

**Verification:** `systemd-analyze verify` passes; service identity,
capabilities, listeners, runtime ownership, state permissions, RPC access, and
restart restoration are verified with the documented read-only commands.

**Planning-time unknowns:** Resolved. The local and server binaries share SHA
`55b6ea7e71e1feebe84de1066dd8db7230fba96280866d9d6dbd6a28fd4184e6`.
Go build metadata records commit
`00f31277f47b0b7e5a5a8719886efd30f734bedd`, build time
`2026-07-11T20:33:31Z`, and `vcs.modified=true`; the only worktree patch is
`go.mod` changing Go 1.26.4 to 1.26.5.

### Unit 2: Reusable Application Registration Plugin

**Goal:** Add a tested Tomo plugin that checks the shared native gateway and
registers only the current application's route.

**Requirements trace:** R5, R6, R7, R8

**Dependencies:** Unit 1.

**Files:**
- `.tomo/plugins/kamal_proxy.rb` — define gateway compatibility, deploy, and read-only listing tasks.
- `test/deployment/kamal_proxy_tasks_test.rb` — verify command construction and named failures using Tomo's mock plugin tester.

**Approach:** Default the binary to `/usr/local/bin/kamal-proxy`, runtime
directory to `/run/kamal-proxy`, system service to `kamal-proxy.service`,
target host to `127.0.0.1`, shared TLS cache path to
`/var/lib/kamal-proxy/.config/kamal-proxy/certs`, and health path to `/up`.
`check` verifies the
binary, active system unit, group-writable Unix socket, and required Fork CLI
flags. It fails without trying to repair host infrastructure.

`deploy` runs the native CLI with the shared `XDG_RUNTIME_DIR`, unique Tomo
application name, exact `APP_HOST`, configured Puma port, `--tls`,
`--forward-headers`, `--health-check-host=APP_HOST`, and `/up`. `list` is
read-only and intentionally displays the shared routing table to trusted group
members. There are no plugin methods for run, start, stop, restart, upgrade, or
remove. Before either check or deploy, validate a proxy-safe application name
and require the target host setting to be exactly `127.0.0.1`.
Always pass `--tls-acme-cache-path` explicitly so the service owns every
certificate path; never accept the CLI default derived from an application
user's home directory.

**Patterns:** Use `defaults`, plain task methods, private escaped command
builders, `remote.run?`, `remote.run`, and `die` consistently with the existing
`pgbus.rb` and `health.rb` project plugins.

**Test scenarios:**
- [ ] Happy path: check verifies the active service, socket, and required CLI flags.
- [ ] Happy path: deploy registers the configured application, hostname, loopback port, TLS, forwarded headers, Host-aware `/up` health check.
- [ ] Happy path: deploy explicitly points ACME cache state at the private gateway-owned certificate directory.
- [ ] Nil/empty input: missing application, host, port, or runtime directory aborts before invoking the CLI.
- [ ] Error path: an unsafe application identity or non-loopback target is rejected before registration.
- [ ] Error path: missing/incompatible binary names the failed capability contract.
- [ ] Error path: inactive service or inaccessible/non-socket RPC path names the server bootstrap fix.
- [ ] Error path: proxy target health, duplicate host, RPC, or TLS failure propagates as a failed Tomo task.
- [ ] Error path: an application-user ACME cache path is rejected before registration.
- [ ] Edge case: application/host/port arguments containing unsafe shell syntax are escaped or rejected.
- [ ] Edge case: no task can remove another application's route or mutate gateway lifecycle.

**Verification:** Focused tests pass without the real proxy; Ruby syntax checks
pass; `tomo tasks` lists check/deploy/list and no destructive gateway task.

**Planning-time unknowns:** The Fork provides no per-service RPC authorization;
shared group trust is **Deferred to Planning** and explicitly accepted by the
operator.

### Unit 3: Rails Application Integration

**Goal:** Connect this Rails application's `.env`, Host Authorization, Puma
port, direct health check, and Tomo deployment order to the shared plugin.

**Requirements trace:** R1, R2, R5, R6, R7, R8

**Dependencies:** Unit 2.

**Files:**
- `.tomo/config.rb` — load and validate `.env`, configure the plugin from application/host/Puma settings, and order gateway checks/deploy.
- `.tomo/plugins/health.rb` — send the configured public Host header during direct loopback health checks.
- `config/environments/production.rb` — validate exact `APP_HOST`, configure Host Authorization, and enable proxy-aware SSL.
- `test/deployment/tomo_config_test.rb` — assert task loading, secret-safe config, gateway settings, and deploy order.
- `test/deployment/health_tasks_test.rb` — assert Host-aware loopback health commands and failure behavior.
- `test/config/production_host_test.rb` — assert valid/missing/malformed `APP_HOST` and production host/SSL behavior.
- `README.md` — document per-app `.env`, unique naming/ports, deploy-user group membership, onboarding, deploy, and diagnostics.

**Approach:** Load Dotenv before Tomo settings and require non-empty
`DATABASE_URL` plus one valid ASCII DNS hostname in `APP_HOST`. Keep both
values untracked; write them into Tomo's mode-0600 remote env without printing
the database URL. Derive the proxy service name from the unique, validated Tomo
`application` setting, require `puma_host` to remain exactly `127.0.0.1`, and
derive the target port only from `puma_port`.

Run `kamal_proxy:check` early in setup and deploy so missing shared
infrastructure fails before a release switch. Direct health uses
`curl --header Host:APP_HOST` against the loopback URL. After Puma restart and
direct health success, run `kamal_proxy:deploy`; cleanup occurs only after
successful registration. Production Rails uses exactly `[APP_HOST]` for
`config.hosts`, enables `assume_ssl` and `force_ssl`, and does not exempt `/up`
from Host Authorization.

**Patterns:** Extend existing `.tomo/config.rb` task declarations,
`health.rb` command arrays, Open3 dry-run tests, and isolated production config
tests. Do not introduce a shared application registry; uniqueness is an
operator/server contract enforced by proxy and port bind failures.

**Test scenarios:**
- [ ] Happy path: valid per-app `.env` values produce the right service/host/port without revealing `DATABASE_URL`.
- [ ] Happy path: direct and proxy health checks both use `APP_HOST`, and production Rails authorizes exactly that host.
- [ ] Nil/empty input: missing `DATABASE_URL` or `APP_HOST` stops local Tomo configuration with the key name.
- [ ] Error path: scheme, port, path, wildcard, whitespace, Unicode, or shell metacharacters in `APP_HOST` are rejected.
- [ ] Error path: unrelated Host headers remain rejected, including `/up`.
- [ ] Error path: a non-loopback `puma_host` or unsafe application name fails local configuration.
- [ ] Edge case: gateway check precedes release work, while route registration occurs only after Puma health succeeds.
- [ ] Edge case: the app uses a loopback port different from another documented app and never exposes Puma publicly.
- [ ] Edge case: `.env` remains ignored and secrets are absent from dry-run/debug output and tracked fixtures.

**Verification:** All focused tests and the full Rails suite pass; Tomo task and
dry-run output match the documented setup/deploy sequence; a second-app dry-run
with another name/host/port produces an independent route command.

**Planning-time unknowns:** DNS propagation, inbound 80/443, and the unique
port allocation for each future app are **Deferred to Planning** operational
checks recorded during onboarding.

## Named Failures

| Name | Detection | Operator feedback |
|------|-----------|-------------------|
| `AppEnvironmentMissing` | `DATABASE_URL` or `APP_HOST` is absent/empty. | Stop before SSH and name the missing `.env` key. |
| `AppHostInvalid` | `APP_HOST` is not one ASCII DNS hostname. | State the hostname-only format. |
| `AppIdentityInvalid` | Tomo `application` is empty or contains proxy-unsafe characters. | Require a unique lowercase ASCII service identifier. |
| `AppTargetNotLoopback` | `puma_host` differs from `127.0.0.1`. | Stop before deploy and explain that public binding bypasses the gateway. |
| `GatewayBinaryMissing` | Native binary is absent or not executable. | Direct the gateway maintainer to server bootstrap/upgrade docs. |
| `GatewayBinaryIncompatible` | Required deploy flags are absent. | Report the missing Fork capability and installed release manifest. |
| `GatewayServiceInactive` | `systemctl is-active` fails. | Stop without restart and direct the admin to service status/journal. |
| `GatewaySocketUnavailable` | RPC path is missing, not a socket, or inaccessible to the deploy user. | Report expected runtime path and shared-group membership. |
| `GatewayRouteConflict` | The proxy rejects a duplicate host/service. | Preserve CLI output and require an intentional route-owner decision. |
| `GatewayTargetUnhealthy` | Host-aware `/up` fails during registration. | Fail deploy and preserve Puma/proxy diagnostics. |
| `GatewayTLSFailed` | ACME/DNS/firewall validation fails. | Fail deploy and direct the admin to gateway journal and prerequisites. |
| `GatewayTLSPathInvalid` | TLS cache path is absent or outside the gateway-owned state root. | Refuse registration to prevent certificate state from entering an application home. |

## Test Coverage Map

```text
server bootstrap (documented integration checks)
├── service identity + low-port capability
├── 80/443 listeners + restart restoration
├── RPC directory/group access
├── private state/certificate access denial
└── release manifest + upgrade/rollback

Tomo plugin (mock unit tests)
├── binary compatible / missing / incompatible
├── service active / inactive
├── socket valid / missing / wrong type / permission denied
├── deploy argument contract / unsafe input
├── gateway-owned TLS cache path / application-home path rejection
├── upstream health / host conflict / RPC / TLS failure propagation
└── read-only list with no destructive lifecycle tasks

Rails app integration
├── `.env` valid / missing / empty / malformed
├── exact Rails host + SSL settings
├── direct loopback health with public Host header
├── Tomo preflight and post-health registration order
├── DATABASE_URL output redaction
└── two-app name/host/port independence dry-run
```

Live DNS propagation, firewall reachability, actual ACME issuance, and proxy
restart restoration are server acceptance checks rather than unit tests.

## Quality Bar Checklist

- [x] Every unit has a requirements trace.
- [x] Dependencies form a DAG (Unit 1 → Unit 2 → Unit 3).
- [x] Every unit has at least three test scenarios.
- [x] No unit touches more than eight files.
- [x] No unit introduces more than two new abstractions.
- [x] Every planning-time unknown is classified.
- [x] Server-wide and per-application responsibilities are explicit; an engineer need not invent product behavior.

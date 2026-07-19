# Shared Kamal Proxy Tomo Integration Requirements

**Version:** 2.0
**Status:** Draft
**Date:** 2026-07-16

## Problem Frame

One Linux server will host multiple Rails applications deployed directly with
Tomo. Each application has its own Linux deploy user, loopback Puma port,
database URL, and public `APP_HOST`. The server already contains a locally
built native binary from the extended
`mhenrixon/kamal-proxy` fork, but that binary is not yet running as a service
and cannot currently bind ports 80/443.

The server needs one durable public gateway that owns TLS certificates and
routes multiple hostnames, while each application deployment independently
registers only its own route. Server-wide proxy lifecycle, certificate state,
and ACME credentials must remain separate from application-specific Tomo
configuration.

## Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| R1 | Each application loads `DATABASE_URL` and one ASCII DNS hostname in `APP_HOST` from its ignored repository `.env`, failing locally when either value is missing or malformed. | Must Have | Use the standard `DATABASE_URL` spelling and never print its value. |
| R2 | Production Rails authorizes only its exact `APP_HOST`, assumes SSL behind the gateway, and forces SSL; internal health checks must send `APP_HOST` as the Host header rather than bypass Host Authorization. | Must Have | No wildcard or `/up` Host Authorization exemption. |
| R3 | Run one native kamal-proxy instance as a system-level systemd service under a dedicated unprivileged `kamal-proxy` user, granting only the capability needed to bind low ports. | Must Have | Use the installed `/usr/local/bin/kamal-proxy`; do not introduce Docker. |
| R4 | Persist proxy state and certificate material in a private server-owned directory, and expose only a group-restricted Unix RPC socket to authorized application deploy users. | Must Have | Certificate private keys must not be readable by deploy users. |
| R5 | Provide a project-local Tomo plugin that verifies the shared gateway contract, enforces a loopback-only Puma target, and registers the current application name, `APP_HOST`, and `127.0.0.1:<puma_port>` target with TLS, forwarded headers, and `/up` health checks. | Must Have | Both proxy and direct Tomo health checks send `APP_HOST` as their Host header. |
| R6 | Register or update the application route only after Puma passes its direct health check; any gateway compatibility, socket permission, target health, host conflict, or TLS error must fail the deployment visibly. | Must Have | The plugin must not start, restart, upgrade, remove, or reconfigure the shared service. |
| R7 | Expose read-only application-facing proxy diagnostics and protect the server/application configuration contract with focused tests and operator documentation. | Should Have | Tests must not require root, a running proxy, DNS, or real ACME issuance. |
| R8 | Require a unique, proxy-safe Tomo `application` name and loopback Puma port per Rails application, with one Linux deploy user per application joined to the shared `kamal-proxy` Unix group. | Must Have | Names use lowercase ASCII letters, digits, hyphens, and underscores. Group members are trusted to administer all routes because the Fork's RPC interface has no per-service authorization. |
| R9 | Enable the Fork's ACME-email-backed shared SAN certificate manager for explicit application hosts, while keeping dynamic domains, DNS-01 wildcard certificates, HTTP/3, rollouts, and read/write target routing disabled. | Must Have | Operators accept certificate-transparency correlation and cross-application renewal coupling. |

## Success Criteria

- `kamal-proxy.service` runs as the dedicated proxy user, listens on 80/443,
  survives reboot, and writes state outside every Rails application tree.
- `/run/kamal-proxy/kamal-proxy.sock` is accessible to the shared proxy group,
  while certificate/state directories remain inaccessible to application
  deploy users.
- A Tomo dry run registers a unique application service against
  `127.0.0.1:<puma_port>` and `APP_HOST` with `--tls`, `--forward-headers`,
  `--health-check-host`, and `/up`, only after direct Puma health succeeds.
- Configuration rejects a non-loopback Puma host before it can expose an
  application port outside the gateway.
- Production Rails accepts its configured public host and rejects an unrelated
  Host header, including on non-authorized health requests.
- A second Rails application can use another deploy user, application name,
  port, and hostname without changing or restarting the shared gateway.
- Multiple explicit application hosts are managed by the Fork's shared SAN
  certificate manager using the server-level ACME email.
- The operator guide separates one-time server bootstrap, binary upgrades,
  per-application onboarding, normal deploys, diagnostics, and rollback.

## Scope Boundaries

**In scope:**
- One Linux server, one native shared proxy, and multiple Rails/Tomo apps.
- A dedicated service account, systemd capability bounding, private state,
  shared RPC group, and stable runtime directory.
- HTTP-01 automatic TLS with shared SAN batching for explicit `APP_HOST` routes.
- Per-app `.env`, exact Rails Host Authorization, unique loopback ports, Tomo
  route registration, tests, and operations documentation.
- Recording the installed Fork build commit/hash because the binary exposes no
  version command.

**Out of scope:**
- Building or downloading the Fork binary from an application deploy.
- Letting an application deploy start, stop, restart, upgrade, or remove the
  shared gateway.
- Docker or full Kamal application deployment.
- Per-application authorization inside the proxy RPC protocol.
- Enabling DNS provider credentials, wildcard certificates, dynamic customer
  domains, HTTP/3, read targets, or progressive rollouts.
- Zero-downtime Puma switching; each Tomo application still restarts one fixed
  Puma endpoint.

## Key Decisions

| Decision | Chosen | Rationale | Alternatives Considered |
|----------|--------|-----------|-------------------------|
| Gateway topology | One native proxy per server | A single listener can route many unique hosts and centralize certificates. | One proxy per app; Docker proxy. |
| Service identity | Dedicated `kamal-proxy` system user | Keeps gateway state independent of the first Rails application. | Run as root; run as an app deploy user. |
| Low-port access | systemd `AmbientCapabilities=CAP_NET_BIND_SERVICE` with a matching capability bound | Survives binary replacement and avoids broad root privileges. | Permanent `setcap`; authbind; redirect high ports. |
| RPC access | Stable `/run/kamal-proxy` runtime directory plus shared Unix group | Allows separate Tomo users to reach one RPC socket. | User-specific `XDG_RUNTIME_DIR`; world-writable socket. |
| State access | `/var/lib/kamal-proxy` private to the service user | Prevents deploy users from reading ACME state or certificate keys. | Store state under an application home; group-readable state. |
| ACME configuration | Root-managed `/etc/kamal-proxy.env` with ACME email | Enables the chosen shared SAN manager; future DNS secrets remain server concerns, not app `.env` values. | Per-host autocert without email; duplicate values in every application. |
| Certificate isolation tradeoff | Shared SAN accepted | Reduces certificate count and uses the Fork's expanded manager, at the cost of CT correlation and renewal coupling between apps. | One certificate per `APP_HOST`. |
| Health authorization | Send `APP_HOST` explicitly | Preserves exact Rails Host Authorization without a health endpoint bypass. | Exempt `/up` from Host Authorization. |
| Fork upgrades | Server-owned binary plus build commit/SHA/dirty-patch record | The installed Fork binary has no version output and was built from a modified worktree. | Pin a Docker tag; trust an unrecorded local build. |

## Outstanding Questions

| # | Question | Impact if Wrong | Owner |
|---|----------|-----------------|-------|
| Q1 | Has the administrator created the proxy service user/group, joined every deploy user to the group, installed the systemd unit, and configured `ACME_EMAIL`? | The shared service or RPC access will fail. | Server administrator |
| Q2 | Does each application have a unique Tomo application name, loopback Puma port, and DNS hostname pointing to this server with inbound 80/443 open? | Routes may collide or certificate issuance will fail. | Application operator |
| Q3 | Has the resolved build record (commit `00f3127`, Go 1.26.5 patch, SHA-256 `55b6ea7e…184e6`) been installed next to the binary? | Future upgrades and incident diagnosis will not be reproducible. | Gateway maintainer |

# 0015 — Hostnames by audience, Workers by path

- **Status:** accepted
- **Date:** 2026-09-13
- **Deciders:** cm

## Context

Darkmatter deploys Cloudflare Workers with Alchemy, and every Worker needs a
public address. Cloudflare offers two ways to give it one: a **custom
domain**, which binds a hostname to exactly one Worker, and a **zone route**,
which binds a hostname-plus-path pattern (`host/prefix/*`) to a Worker and
takes precedence over whatever Worker holds the hostname.

Without a rule the path of least resistance is a new subdomain per Worker
(`bounty.dm.sh`, `next-thing.dm.sh`, …). That produces a hostname per feature,
a TLS certificate, Access application, WAF and cache configuration per
hostname, and no shared origin for the things that should share one. The
opposite shortcut, mounting service Workers under the marketing site's
hostname (`dm.sh/api/...`), couples unrelated services to the site's cookies,
its path-scoped Access policies and its asset routing, and makes every
service share the site's XSS surface.

The first case that forced the decision was the bounty payout intake Worker
in `darkmatter/web`, a payments-adjacent surface with a public claim page, an
operator queue behind Cloudflare Access, and webhooks.

## Decision

1. **Hostnames are assigned by audience, not by feature.**
   - `dm.sh` and `darkmatter.io` serve what people open in a browser: the
     marketing site Worker.
   - `api.dm.sh` is the single hostname for service Workers. Cache bypass,
     WAF and Access rules for services target this hostname.
2. **Service Workers are addressed by path.** Each Worker owns one plural
   path prefix, `api.dm.sh/<features>/*` (for example
   `api.dm.sh/bounties/*`), attached with a zone route. The hostname is one
   proxied placeholder DNS record (`AAAA 100::`); Workers attach routes,
   never custom domains, so adding a Worker adds a route and nothing else.
3. **`dm.sh/api/*` is reserved for same-origin proxies.** Use it only when
   the browser frontend must call a service without CORS or with the site's
   cookies, and then only as a route or service binding that forwards to the
   service Worker on `api.dm.sh`. It is never a Worker's primary address.
4. **No new hostname per Worker.** A new hostname needs an ADR-level reason:
   a different audience, tenant isolation, or a regulatory boundary.
5. **Path segments and route patterns are plural nouns.**
6. **Stages.** Only the production stage attaches DNS records and routes;
   other stages stay on their `workers.dev` URL with the same path prefix,
   so a Worker's paths are identical in every environment.

In an Alchemy stack this is a `Cloudflare.DNS.Record` for the hostname and a
`Cloudflare.WorkerRoute` per Worker, both created only when
`Alchemy.Stage` is `production`; the Worker's routes carry the prefix in
every stage.

## Consequences

**Upside**

- One hostname to secure, cache and monitor for every service.
- Each service has a predictable address that follows from its name.
- Workers stay isolated in bindings and secrets while sharing a hostname.
- The marketing site's origin stays free of service cookies and policies.

**Costs**

- Every service Worker carries its path prefix in code, in all stages.
- Browser calls from `dm.sh` to `api.dm.sh` are cross-origin: they need
  CORS headers or a `dm.sh/api/*` proxy, and cookies need `Domain=dm.sh`.
- The bare `api.dm.sh/` root serves nothing until a Worker claims `/*`.
- Zone routes need the placeholder DNS record to exist and be proxied.

## Alternatives considered

- **A subdomain per Worker.** Rejected: hostname sprawl, per-hostname
  security and cache configuration, no shared origin.
- **All services under `dm.sh/api/*` as their primary address.** Rejected:
  couples every service to the site's origin, cookies and path-scoped Access
  policies, and to the site Worker's asset handling. Kept only as the
  same-origin proxy pattern.
- **A single gateway Worker fanning out over service bindings.** Rejected as
  the default: an extra hop and a component that must know every backend.
  It can be introduced later behind `api.dm.sh` without changing any
  service's address.

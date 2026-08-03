# 0009 — Curate the default agent skill bundle

- **Status:** accepted
- **Date:** 2026-08-03
- **Deciders:** Darkmatter maintainers

## Context

The team source catalog accumulated broad process guidance and client-runtime
hooks alongside Darkmatter-specific operating knowledge. `enableAll` shipped
each of them to every agent, duplicating capabilities that current agents
provide natively and increasing discovery noise.

## Decision

The Home Manager module enables a small explicit allowlist of high-signal,
team-wide skills. The source catalog may retain retired material, but new
default skills require an intentional addition to `skills.enable`.

Client-runtime hooks and their assets belong under `presets/<client>/runtime/`.
They remain opt-in and must not be enabled just by installing the shared skill
bundle.

## Consequences

- Default agents receive 14 skills rather than every source directory.
- Native agent facilities replace generic skill-discovery, authoring, browser,
  and dispatch-policy skills.
- Runtime integrations remain available without pretending to be task skills.
- Reactivating an archived skill is deliberate and reviewable.

## Alternatives considered

- Delete all retired sources. Rejected: retaining source preserves useful
  history and makes a later explicit reactivation cheap.
- Keep `enableAll` and hide rows in the catalog. Rejected: it does not reduce
  the effective prompt surface.

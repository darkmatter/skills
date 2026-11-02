# 0018 — Centaur consumes the root skills catalog

- **Status:** accepted
- **Date:** 2026-11-02
- **Deciders:** darkmatter maintainers

## Context

Centaur sandboxes previously received a curated copy of the catalog under
`.agents/skills/`, generated from `.agents/skills.manifest` by
`scripts/sync-sandbox-skills.sh`, with a CI check that failed on drift. The
copy existed because the overlay contract accepted one directory per source
and the full catalog includes workstation-only skills.

Centaur now reads `skills/` at the repository root directly. Keeping the
manifest, generated tree, sync script, and drift check alongside the real
catalog added a second source to maintain and a class of failures where the
copies diverged from `skills/`.

## Decision

`skills/` at the repository root is the canonical skill source. Centaur
consumes that directory directly. Existing installers, packaging, and catalog
validation keep their current steps; this decision does not replace them.

There is no sandbox manifest, generated or copied subtree, secondary catalog,
or compatibility path. Do not reintroduce `.agents/skills/`, a sync script, or
a sandbox drift check. `.agents/` remains ignored local state and is never a
distribution artifact.

## Consequences

- Adding or editing a skill under `skills/` requires no additional sandbox
  manifest, copied subset, or sync step. Existing Nix, Claude plugin, and
  catalog-validation steps are unchanged.
- The catalog has one authoritative copy, so drift between a source and a
  generated subset is no longer possible.
- Sandboxes see the full catalog rather than a repo-maintained subset. This
  repository no longer curates sandbox-specific skill availability.
- Validation stays focused on skill structure, catalog parity, links, and
  generated instructions; there is no sandbox sync step to test.

## Alternatives considered

- **Keep the manifest and generated subset.** Rejected: it duplicates every
  skill, needs a sync command after each edit, and adds a drift check for
  content that already exists.
- **Point the overlay at a filtered directory elsewhere in the repo.**
  Rejected: it is the same second catalog with a different path.
- **Retain a compatibility path for old sandboxes.** Rejected: Centaur is
  already cut over to `skills/`, and a compatibility path would preserve the
  obsolete distribution model.

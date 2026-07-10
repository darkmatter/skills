# 0008 — Per-language reference codebases under `references/`

- **Status:** accepted
- **Date:** 2026-07-09
- **Deciders:** cm

## Context

Preferred conventions currently live as prose in skills (`rust-best-practices`,
`effect-typescript`, `coding-standards`) and implicitly in project repos. Prose
under-specifies: two agents reading the same guidance produce different code,
and agents weight concrete code they can see over abstract rules. There was no
canonical place for "this is what good darkmatter Rust/Go/TypeScript looks
like" — examples get written ad hoc inside projects and drift apart.

## Decision

Add a top-level `references/` section to this repo: one directory per major
language or framework — `rust/`, `go/`, `typescript/` to start — each holding a
`README.md` index plus exemplar code demonstrating preferred conventions
(project layout, error handling, testing, tooling config, preferred
libraries).

Division of labor:

- `skills/` carry prose guidance and decision frameworks, loaded on demand.
- `references/` carry code. Exemplars show; skills tell. The two cross-link
  rather than duplicate.
- `docs/reference/` is unchanged: documentation examples about agent-project
  setup, not language conventions.

Precedence for agents when conventions conflict: project `.agent/` rules →
`references/` exemplars → general language idiom.

## Consequences

- Convention changes become reviewable PRs against one canonical location, and
  agents and skills can point at stable paths (`references/<language>/`).
- `references/` is **not** distributed by the Home Manager module, which syncs
  only `skills/`. Consumers need the repo checkout; if a skill must surface an
  exemplar on consumer machines, it copies it into its own
  `skills/<name>/reference/` or we wire distribution later. Revisit when the
  first remote consumer appears.
- Staleness risk: an exemplar that no longer matches practice actively
  misleads. A change to a convention must update the exemplar in the same
  change.
- `scripts/validate-skill.sh` does not cover `references/`; keeping the
  per-language indexes accurate is manual review for now.

## Alternatives considered

- **`skills/<name>/reference/` inside per-language skills.** Rejected:
  language conventions cross-cut many skills (Effect, React, and coding
  standards all touch TypeScript); nesting code under one skill fragments the
  per-language view and bloats skill payloads that the Home Manager module
  installs on every machine.
- **`docs/reference/`.** Rejected: that directory documents agent-project
  setup patterns for humans reading this repo's docs; a growing codebase with
  per-language subtrees doesn't belong under `docs/`.
- **A separate `darkmatter/references` repo.** Rejected: another checkout to
  discover and keep cloned; this repo is already the shared-guidance home
  teammates and agents know.

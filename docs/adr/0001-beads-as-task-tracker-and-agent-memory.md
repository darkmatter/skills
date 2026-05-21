# 0001 — Beads is the standard task tracker and agent memory store

- **Status:** accepted
- **Date:** 2026-05-21
- **Deciders:** cm

## Context

Darkmatter projects and agents have, over time, accumulated several incompatible
ways to track work-in-progress and remember context across sessions:

- `TodoWrite` / `TaskCreate` lists that vanish at session end.
- Scattered `MEMORY.md`, `NOTES.md`, `TODO.md`, and `.agent/notes/` files that
  fragment across accounts, worktrees, and machines.
- Ad-hoc GitHub Issues, Linear tickets, and Slack threads that are not
  reachable from inside the agent runtime.

The result is that agents:

- Lose state on compaction, clear, or new sessions.
- Cannot reliably hand work between models, agents, or teammates.
- Duplicate or contradict each other when working the same repo concurrently.
- Cannot answer "what's next?" or "what's blocked?" without re-reading the
  whole repo.

[beads][beads] (`bd`) gives us a single, version-controlled, dependency-aware
issue tracker with first-class agent ergonomics: `bd ready`, `bd create`,
`bd close`, `bd remember`, plus session-priming via `bd prime` and bidirectional
sync to Linear via `bd linear sync`. It stores data in Dolt inside `.beads/`,
so the source of truth travels with the repo.

## Decision

For every darkmatter project repo, beads is the standard mechanism for:

1. **Task tracking** — `bd create`, `bd ready`, `bd update`, `bd close`,
   `bd dep add`. No `TodoWrite`, `TaskCreate`, `TODO.md`, or `NOTES.md` for
   tracking work that needs to survive a session.
2. **Persistent agent memory** — `bd remember "insight"` and
   `bd memories <keyword>`. No `MEMORY.md` files in repo, agent dotdirs, or
   personal scratch directories.
3. **Upstream collaboration sync** — when a project has a Linear team, beads
   syncs bidirectionally via `bd linear sync`. Linear stays the surface for
   humans and managers; beads stays the surface for agents and code.

Per-repo onboarding (install `bd`, run `bd init`, wire agent recipes, and
configure Linear if applicable) is handled by the `beads-setup` skill in this
catalog. Agents working in any darkmatter project must apply that skill when
the repo lacks a `.beads/` directory or when Linear integration is requested.

Ephemeral, intra-turn checklists (the per-response todo list a single agent
holds while it's actively working) are out of scope. This ADR governs what
must survive across turns, sessions, and machines.

## Consequences

**Upside**

- Agents can recover full task and memory context after compaction, clear, or
  fresh checkout via `bd prime` and `bd memories`.
- Work is dependency-aware: `bd ready` returns issues whose blockers are all
  closed, so an agent can pick up the next unit of work without reading the
  whole repo.
- Multiple agents and teammates working the same worktree no longer step on
  each other's todo lists.
- Linear-backed teams keep one issue graph instead of two, with humans on
  Linear and agents on beads.

**Costs**

- Every project needs a one-time `bd init` and a `.beads/` directory that
  travels in git.
- Agents must learn the `bd` surface (small, documented in `bd prime`) instead
  of reaching for `TodoWrite` reflexively.
- Linear sync requires credentials (`linear.api_key` + `linear.team_id`, or
  `LINEAR_OAUTH_*` for CI workers). Storing those is the project's
  responsibility; the `sops-secret-access` skill covers the encrypted-config
  pattern.
- `bd` (and Dolt's embedded engine) must be installable on every contributor
  and CI machine. The `beads-setup` skill handles the install fallback chain.

## Alternatives considered

- **Status quo (mixed `TodoWrite` + `MEMORY.md` + GitHub Issues).** Already
  failing in practice: context loss, fragmentation, no dependency model.
- **GitHub Issues / Linear as the single source of truth, no local tracker.**
  Networked, slow, requires auth and a live connection; not usable from inside
  a sandboxed agent or an offline dev loop. Better as a sync target (which is
  what we get via `bd linear sync`).
- **A purpose-built markdown convention** (e.g. `.agent/state/issues/*.md`).
  No dependency model, no `ready` query, no concurrency story, nothing to sync
  to Linear. Reinvents beads, worse.

[beads]: https://github.com/steveyegge/beads

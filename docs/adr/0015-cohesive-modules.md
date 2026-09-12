# 0015 — Cohesive modules and small public interfaces

- **Status:** accepted
- **Date:** 2026-09-12
- **Deciders:** cm

## Context

Directory conventions and size limits make code easier to navigate, but rigid
extraction rules can scatter one operation across helpers, forwarding services,
duplicated contracts, and adapter layers. Readers then need to reconstruct its
behavior across files even though each individual file is short.

Existing instructions require splitting by function length, banning tiny
functions, or extracting every component into its own file. ADR-0007 also
requires replacing application SQL with a query builder or ORM. Those rules can
force unrelated abstraction and toolchain changes during a readability refactor.

## Decision

**Keep each capability together, make it simple to use, and split it only when
the split improves understanding.**

The ten rules and good/bad examples in
[codebase-design](../../skills/codebase-design/SKILL.md) are the canonical module
convention. Specialized skills link to it and describe only their relevant
application. Always-on instructions carry a concise, standalone summary of the
rules and point to the skill for examples.

Group source by domain, then by useful role. A focused package can itself own
the domain. Keep an operation's helpers, queries, bindings, and decoding nearby;
extract a module when it hides complexity or enables useful reuse. Short or
single-use helpers and private components can be useful. Public interfaces
expose complete operations, including their ordering, failure, and cleanup.
Retain thin public package entries and real external-interface adapters; remove
internal forwarding chains that add no useful contract.

Retain configured file limits; use 300 nonblank, noncomment lines when introducing
a limit. Split at a coherent responsibility or document a narrow increase or
exception. Keep other checks active. Do not satisfy size limits by manufacturing forwarding files or
disable existing diagnostics without an authorized configuration change.

This decision supersedes ADR-0007's blanket ban on SQL in TypeScript:

- Existing typed query builders and ORMs remain useful and may stay in place.
- Parameterized SQL may live inside its owning adapter alongside bindings and
  row conversion. Validate returned rows and verify observable query behavior
  against the database through the project's adapter or integration tests.
- Type arguments such as `query<Row>` assert a row shape; they do not validate
  returned data or prove the SQL correct.
- A readability refactor does not require a query-builder migration or a new
  toolchain. Preserve the current tool's guarantees when changing its queries.

ADR-0013's shared UI package boundary remains in force. A reusable
presentational unit belongs in that package; its app-specific state and routing
remain in the app. Repeated use is evidence of reuse, but visual similarity or
call count alone does not establish a coherent component responsibility.

## Consequences

Readers can follow a complete operation with fewer jumps. Schemas and derived
types have one definition, adapters own external conversions, and tests verify
observable behavior through useful interfaces.

Some cohesive files will be longer. Reviews must explain why an extraction or
size exception improves understanding; lint alone cannot decide module quality.
Parameterized SQL gives up the query builder's compile-time query checks, so row
validation and meaningful database verification carry more responsibility.

## Alternatives considered

- **Fixed file and function sizes as architecture.** Rejected. Limits remain
  useful checks, but automatic extraction can fragment one responsibility.
- **Ban short helpers, single-use components, or all re-exports.** Rejected.
  These shapes can hide a decision or establish a useful public interface.
- **Remove size limits.** Rejected. Retain them with documented narrow
  adjustments when a cohesive implementation needs room.
- **Require an ORM for every SQL operation.** Rejected. Existing typed query
  tools remain supported, but changing dependencies is not a prerequisite for
  keeping a database operation understandable in one place.

# 0017 — Skill and instruction ownership

- **Status:** accepted
- **Date:** 2026-10-31
- **Deciders:** darkmatter maintainers

## Context

Skills, presets, workflow examples, and catalog rows had each accumulated a
version of the module, testing, and repository rules. Some still pointed at
`codebase-design` and `domain-organization` after those skills were removed.
The result was not just duplicated prose: two artifacts could claim to be
canonical, an edit in one place left a contradiction in another, and readers
could not tell which rule would actually load.

## Decision

Each policy domain has exactly one owner. Every other artifact references the
owner by name; it does not restate or fork the policy. A change updates the
owner and all active references in the same change.

- The **Readability and module design** section in
  `docs/agents/60-readability.md` is the canonical source for module,
  readability, and domain/role source-layout rules. It ships in every generated
  `AGENTS.md`. Skills, presets, and review checklists cite that section by name.
- `repository-organization` owns artifact placement, README and ADR process,
  instruction ownership, and the format for explicit exceptions. It does not
  define source architecture or language rules.
- `darkmatter-ts-toolchain` owns TypeScript stack, dependency, persistence, and
  test-placement choices plus the check contract. `effect-typescript` owns
  implementation patterns, not a second stack policy.
- `choose-dev-entrypoints` owns entrypoint layering and ops-script language.
  `alchemy` owns infrastructure and deploy implementation, not a second database
  selection policy. `sops-secret-access` owns secret access procedure.
- `when-to-write-tests` owns test necessity and coverage decisions. TDD is
  explicit opt-in: the requested or project-required TDD procedure owns the
  red/green steps. A decision to add a test does not create a test-first
  requirement.
- `nix-flake-organization` owns flake and module layout.
  `definition-of-done` orchestrates the applicable owners instead of defining
  their policies.
- `darkmatter-design-system` owns fallback visual tokens,
  `ui-component-architecture` owns component and package responsibility, and
  `shadcn-registry-first` owns component sourcing and comparison.
  `run-ui-registry-variations` remains explicitly user-invoked.
- Do not recreate a deleted skill to hold a rule. Move the rule to its owner
  and update active references; do not add compatibility shims or a
  retired-name registry.

### ADR-0015 supersession

This ADR partially supersedes
[ADR-0015](0015-cohesive-modules.md): only its ownership and pointer decision,
which named `codebase-design` as the canonical convention and directed
always-on rules to that skill for examples. That skill no longer exists, and
the canonical location is now this decision plus the **Readability and module
design** section.

ADR-0015's technical decisions remain in force unchanged: cohesive
capabilities, small complete public interfaces, meaningful extraction,
configured line limits with narrow documented exceptions, the
parameterized-SQL/ORM position that superseded ADR-0007's blanket ban, and
ADR-0013's shared UI package boundary. The historical ADR text stays intact;
this ADR records the current ownership.

## Consequences

- One edit changes a policy. A stale copy is a review failure rather than a
  competing convention.
- References stay stable because they name the owner rather than a fragile
  path; repo-local links still work for readers browsing the repository.
- Skills and presets become shorter, but they depend on the shared instructions
  being loaded. The owner file remains the authority when a skill is used
  without the shared context.
- Reviewers must reject a second copy of policy even when duplicating it looks
  convenient.

## Alternatives considered

- **Keep a canonical skill with duplicated summaries in presets.** Rejected:
  the removed skill left dangling references, and copies drift.
- **Add a retired-name registry or compatibility shim.** Rejected: it preserves
  the obsolete path and hides stale references instead of repairing them.
- **Rewrite ADR-0015 in place.** Rejected: accepted ADRs are history, and its
  technical decisions still apply.

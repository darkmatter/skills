# 0001 — Skill naming convention: namespace, manual-invocation, and auto-trigger

- **Status:** accepted
- **Date:** 2026-05-09
- **Deciders:** cooper

## Context

Skills in `skills/` are loaded by an agent (Claude, Codex, etc.) in two distinct ways:

1. **Auto-trigger** — the agent reads each skill's frontmatter `description`, and pulls a skill into context when its trigger phrases match the user's intent. This is the default and the desired behavior for most skills (`dm-hl-funding-analysis`, `dm-codebase-cleanup`, `dm-end-of-turn-review`).
2. **Manual invocation** — the user explicitly invokes the skill by name, typically via a slash command or by saying "run X". The skill should *not* auto-trigger on adjacent topics. This fits skills that are expensive, irreversible, or that drive a multi-step user-facing workflow with check-ins (`dm-kickoff-dm-design` posts to Linear and Slack on first run).

Both flavors live in the same `skills/` directory and ship through the same Nix Home Manager module. All team-wide skills use the `dm-` namespace so installed skill lists make ownership obvious. After that namespace, names still need to signal which mode the skill expects; otherwise two failure modes show up:

- A manual skill ends up auto-triggering because its description shares vocabulary with adjacent topics. The user gets surprised when the skill posts to Slack uninvited.
- An auto skill is named like an action (`run-foo`) and the agent treats it as something it should only fire when explicitly asked, leaving capability on the table.

We need a convention that's recognizable on sight, doesn't require new tooling, and reinforces the right triggering behavior at description-write time.

## Decision

**Every team-wide skill starts with `dm-`, and the rest of the skill name signals its triggering mode.**

- **Auto-triggered skills** are named as **noun phrases** after `dm-`, describing a domain or capability — `<domain>-<aspect>` or a compound noun. Examples: `dm-hl-funding-analysis`, `dm-codebase-cleanup`, `dm-end-of-turn-review`, `dm-systematic-debugging`. The skill reads as a thing you consult, not an action you invoke.
- **Manual-invocation skills** put an **imperative verb** after `dm-`, drawn from a small fixed set — `run-`, `kickoff-`, `setup-`, `init-`, or `do-` as a generic fallback. The verb makes the name only sensible at invocation time. Examples: `dm-kickoff-dm-design`, `dm-run-funding-screen`, `dm-setup-vault`, `dm-init-project`.

**A skill is manual when at least one of these is true.** Otherwise default to auto.

- The action is expensive in tokens, time, or money (a long benchmark sweep, paid API hits, a multi-minute screen).
- The action is irreversible or has side effects on shared resources (Linear tickets, Slack posts, vault mutations, git operations on shared branches).
- The skill drives a guided workflow with user check-ins partway through, not a one-shot.
- Auto-triggering on a near-miss would surprise or annoy the user.

**The frontmatter description must reinforce the triggering mode.** The name is a label; the `description` is what actually governs Claude's decision to load a skill. So:

- **Auto skills** open with what the skill does, then list concrete `Triggers when…` clauses and explicit `Do NOT trigger for…` carve-outs. (Already the convention in this repo.)
- **Manual skills** open with the line `Manual-invocation skill — run only when the user explicitly asks for "<name>" or invokes it as a slash command. Do not auto-trigger on adjacent topics.` Then describe what it does. The verb-prefixed name and this opening line together make under-triggering the safe default.

**Renames apply to existing skills that violate the convention.** At the time of this ADR, every team-wide skill without a `dm-` prefix is renamed by adding one. For manual skills, the imperative verb stays immediately after `dm-`, for example `kickoff-dm-design` → `dm-kickoff-dm-design`.

## Consequences

**Upside.**

- A teammate skimming `skills/` or `docs/catalog.md` can tell at a glance that a skill belongs to Dark Matter and whether it expects to be invoked or picked up by the agent. That changes how they write the description and how they reason about side effects.
- The `dm-` namespace, duplicate `dm-dm-` rejection, and directory/frontmatter name match are enforced by `scripts/validate-skill.sh` and CI, so ownership drift is caught before merge.
- The auto-vs-manual grammar and manual description opening line remain review-enforced conventions, which leaves room for genuine edge cases without complicating the validator.
- The "Manual-invocation skill — …" opening line is a hard signal in the description, robust to whatever heuristic the model uses for triggering. Even if the model's behavior shifts across versions, a manual skill stays manual.

**Costs.**

- A one-time namespace migration, which means rewriting slash-invocation examples, path examples, and catalog rows.
- Future manual skills need to pick a verb at naming time. The fixed set (`run-`, `kickoff-`, `setup-`, `init-`, `do-`) reduces bikeshedding but still requires a moment of thought.
- The validator only enforces the namespace and basic structural invariants. Drift is still possible in the trigger-mode convention itself; if we see that in practice, we can extend the validator to grep manual skill descriptions for the manual-invocation opening line and warn if absent.

**Out of scope.**

- We are not splitting `skills/` into separate `skills/auto/` and `skills/manual/` directories. That would require flake/module changes and obscures the fact that both flavors are loaded by the same mechanism. The naming convention is the only structural change.
- We are not introducing a `mode: manual | auto` frontmatter field. The opening-line discipline in `description` is sufficient and avoids inventing a new schema the validator would need to learn.

## Alternatives considered

**Frontmatter `mode:` field.** Add `mode: manual` or `mode: auto` to YAML frontmatter, surfaced in tooling. Rejected because it duplicates the signal already present in the description, requires `validate-skill.sh` changes, and doesn't help a teammate skimming filenames.

**Separate directories (`skills/auto/`, `skills/manual/`).** Rejected because both flavors flow through the same home-manager module and the same agent loading mechanism — there's no real distinction at the system level, only at the social/UX one. A directory split would require flake changes and create a false sense of mechanical separation.

**Suffix instead of prefix (`*-cmd`, `*-command`).** Rejected because the suffix reads as a noun ("the funding-analysis command") rather than as an action, weakening the social signal. Verb-first reads as an instruction.

**No convention; rely entirely on description discipline.** Rejected because the name is what a teammate sees when scanning `ls skills/` or `docs/catalog.md`, and a name that misleads about triggering mode is worse than no name at all. The two signals (name grammar + description opening line) are cheap to maintain together and reinforce each other.

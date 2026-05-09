# Architecture Decision Records

Standing decisions about how this repo is structured and how skills are written. Use ADRs for choices that cross-cut multiple skills, multiple teammates, or future work — not for one-off implementation notes.

## Format

One file per decision: `NNNN-kebab-case-title.md`. Numbers are zero-padded to four digits and assigned in commit order.

Each ADR has the same shape (loosely [Nygard][nygard], [MADR][madr]):

```markdown
# NNNN — Title

- **Status:** proposed | accepted | superseded by ADR-XXXX | deprecated
- **Date:** YYYY-MM-DD
- **Deciders:** github handles or names

## Context

What's the situation that forced a decision? What constraints are in play?

## Decision

What did we decide. State it plainly.

## Consequences

What follows from this — both the upside and the costs we're accepting.

## Alternatives considered

Briefly: what else we looked at and why we didn't pick it.
```

[nygard]: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
[madr]: https://adr.github.io/madr/

## When to write an ADR

- A naming, layout, or directory convention that contributors should follow
- A choice between two reasonable approaches where the rationale will fade from memory
- A constraint that's load-bearing for safety, secrets, or distribution (e.g. "skills must not require external deps beyond the flake")
- A reversal — supersede the prior ADR rather than rewriting it

## When NOT to write an ADR

- Implementation details inside a single skill — those belong in that skill's `reference/`
- Project-local decisions inside a darkmatter project — those go in that project's `.agent/context/decisions.md`
- Things still under debate — leave a `proposed` ADR draft, but don't accept it until the decision is real

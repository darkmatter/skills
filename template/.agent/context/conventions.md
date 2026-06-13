---
last_updated: { { date } }
review_by: { { review_date } }
---

# Operating principles and conventions

## How agents should approach this project

1. **Read before answering.** Always read `.agent/context/*` before producing analysis. Skim `.agent/memory/*` for active issues.
2. **Don't invent data.** If an API call fails, say so. State files in `.agent/context/` are point-in-time snapshots, not live state.
3. **Reference standing decisions explicitly.** When an answer is in `decisions.md`, cite it: "per decisions.md #N, …". Makes reasoning auditable.
4. **Surface uncertainty explicitly.** "I'm not sure" beats confident wrongness. Qualify estimates with the assumption they depend on.
5. **Be terse.** No "everything is fine" filler. Notify only on changes, flags, or trigger conditions.

## Code and infrastructure conventions

> Project-specific stack defaults, secrets handling, where logs/caches go, rate-limiting rules, doc-locality preferences, etc.

## Communication conventions

> Project-specific output formatting, when to use tables vs prose, default verbosity, etc.

# AGENTS.md rule — shared UI components

Paste this block into the `AGENTS.md` (or equivalent always-on context file) of
any repo that has a shared UI package. Fill in the package path and import alias
from that repo. It's the highest-leverage lever: it's always in context, so it
catches the common "just write a screen" path that an on-demand skill can miss.

---

## UI components

Reusable UI lives in its own package. Apply the "Readability and module design"
section in the shared agent instructions to it; the rules below are the
UI-specific additions. Look up this repo's package path and import alias
(workspaces, `packages/*`, vendor trees). Do not assume a name.

- **Reuse first.** Before authoring a screen, check what the UI package already
  exports and use it. Do not reimplement `Button`, `Card`, `Badge`, `Input`,
  `Dialog`, `EmptyState`, `Skeleton`, etc.
- **Extract useful units.** Move reusable presentational units into the UI
  package when they have an independent interface. Repeated use is evidence to
  inspect. Keep local layout and app-specific behavior local.
- **Keep shared components dumb.** No app routes, stores, API clients, or
  app-specific types inside the UI package. Data comes in as props.
- **Style with tokens and variants.** Use theme tokens and a `cn`/`cva` variant
  map, not raw hex literals or copy-pasted class clusters. An existing project
  design system wins over the fallback language.

---

## Why this works where a skill alone doesn't

Keep this UI-specific excerpt aligned with the "Readability and module design"
section in the shared agent instructions. That section owns the generic module
rules; this block adds the UI package boundary and reuse rules. Do not duplicate
the generic rules here.

A skill in the shared catalog is loaded on demand by description match. "Writing
any UI" is so common that relying on the skill to fire every time is fragile —
the agent often writes the wall of divs before it ever consults a skill. The
`AGENTS.md` rule is always in context, so it's the reliable backstop. Use both:
the rule for the always-on directive, the skill for the deeper extraction
workflow and heuristics.

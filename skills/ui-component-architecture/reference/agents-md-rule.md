# AGENTS.md rule — shared UI components

Paste this block into the `AGENTS.md` (or equivalent always-on context file) of
any monorepo that has a shared UI package at `packages/ui`. It's the highest-
leverage lever: it's always in context, so it catches the common "just write a
screen" path that an on-demand skill can miss.

Adjust the import alias (`@repo/ui`) and path (`packages/ui`) if the repo differs.

---

## UI components

This repo has a shared UI package at `packages/ui`, imported as `@repo/ui`.

- **Reuse first.** Before authoring a screen, check what `@repo/ui` already
  exports and use it. Do not reimplement `Button`, `Card`, `Badge`, `Input`,
  `Dialog`, `EmptyState`, `Skeleton`, etc.
- **Keep screens thin.** Page/route files should read as composition — a handful
  of named components plus data wiring, not walls of `<div className="...">`.
- **Extract on the second use.** When a visual unit is reused twice, or is a
  self-contained presentational primitive, move it into `packages/ui` and import
  it back via `@repo/ui`. Don't extract one-off layout glue speculatively.
- **Keep shared components dumb.** No app routes, stores, API clients, or
  app-specific types inside `@repo/ui`. Data comes in as props.
- **Style with tokens and variants.** Use theme tokens and a `cn`/`cva` variant
  map, not raw hex literals or copy-pasted class clusters.

---

## Why this works where a skill alone doesn't

A skill in the shared catalog is loaded on demand by description match. "Writing
any UI" is so common that relying on the skill to fire every time is fragile —
the agent often writes the wall of divs before it ever consults a skill. The
`AGENTS.md` rule is always in context, so it's the reliable backstop. Use both:
the rule for the always-on directive, the skill for the deeper extraction
workflow and heuristics.

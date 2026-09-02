# 0013 — Shared UI lives in its own package; the name is per-repo

- **Status:** accepted
- **Date:** 2026-09-01
- **Deciders:** cm

## Context

Reusable React UI must live in its own package, not in the screen, route,
or page that uses it. That package boundary is the architecture.

Darkmatter apps already do this under different names and layouts. Some
use `packages/ui` imported as `@repo/ui`. Some vendor a starter imported
as `@native/ui`. Some keep other workspace aliases. Some still drop shadcn
output next to the route.

Skills and docs that pin one of those strings make the import path look
like the rule. The name is per-repo. Mandating one alias is false
precision.

## Decision

Reusable UI MUST live in its own package, separate from app screens,
routes, and business logic.

The package path and import alias are per-repo. Discover them from the
workspace (`package.json` workspaces, `packages/*`, vendor trees). Do not
require `@repo/ui`, `@native/ui`, or any other name.

Screens import primitives from that package. Graduate a visual unit into
it on the second use, or when it is a presentational primitive (`Button`,
`Card`, `Badge`, …). Keep those components dumb: no app routes, stores, or
API clients inside the UI package.

## Consequences

**Upside**

- Skills stay true across repos that already picked different aliases.
- The load-bearing rule is the package boundary, not a string in an import.

**Costs**

- Agents must look up the local package name instead of copying `@repo/ui`
  from a skill. That lookup is one grep.

## Alternatives considered

- **Mandate `@repo/ui` / `packages/ui`.** Rejected. Several Darkmatter
  apps already use a different alias. The name is not the architecture.
- **Leave reusable UI in the app.** Rejected. Screens become unreadable
  Tailwind walls and primitives drift per route.
- **Require a specific vendor path (`@native/ui`).** Rejected for the same
  reason as `@repo/ui`. A design system's tokens may live in that package
  when the repo uses it; the name is still the repo's choice.

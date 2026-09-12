# TypeScript reference

Exemplar TypeScript code showing darkmatter's preferred conventions. See
[`references/README.md`](../README.md) for how this section works and how to
contribute.

**Status:** scaffolding — topics indexed below; exemplars land incrementally.

## Related skills

- `effect-typescript` — Effect for anything with meaningful I/O: services,
  Layers, Config, Schema, typed errors, retries, resources, tests.
- `codebase-design` — cohesive capabilities, complete operations, useful
  extraction, line limits with narrow exceptions, and behavioral tests.
- `domain-organization` — domain ownership, role directories, and filenames.
- `ui-component-architecture` — thin screens; reusable UI in its own package
  (name is per-repo).
- `vercel-react-best-practices` — React/Next.js performance patterns.
- `choose-dev-entrypoints` — where dev/build/test commands live across Nix,
  Just, Bun, Turborepo, and package scripts.

## Index

| Topic              | What it should demonstrate                                            | Exemplar |
| ------------------ | ---------------------------------------------------------------------- | -------- |
| Project layout     | Domain then role, cohesive packages, small public interfaces | _todo_   |
| Contracts          | Schema and inferred type together; decode at external boundaries | _todo_   |
| Effect services    | Complete operations, one Promise-to-Effect conversion at the adapter, owned completion | _todo_   |
| Error handling     | Typed errors with Schema, expected failure vs defect                   | _todo_   |
| Testing            | Observable behavior through package interfaces; Effect test layers where useful | _todo_   |
| Tooling            | `tsconfig` baseline, lint/format choice, CI wiring                     | _todo_   |
| Preferred packages | Blessed picks for common needs (validation, HTTP, dates, CLI)          | _todo_   |

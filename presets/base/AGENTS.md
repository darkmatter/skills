# Darkmatter Global Agent Preset

This is the shared global instruction entrypoint installed from
`darkmatter/skills/presets/base`.

Project-specific instructions override this file. When working in a project,
read that project's `AGENTS.md` first and treat this file as general background.

## Defaults

- Prefer evidence over assertion: verify builds, tests, and claims before reporting success.
- Keep repo-specific context in the project repo, not in this shared preset catalog.
- Do not read or commit secrets, private keys, credentials, or local environment files.
- Preserve user changes in dirty worktrees unless explicitly asked to revert them.
- Use reusable skills from the shared catalog when their trigger conditions apply.
- After significant code changes, check the completed diff against the repo's standing ADRs before finalizing. Call out conflicts, fix them, or state which ADRs materially applied and why the work complies.
- Keep repository READMEs compliant with the Standard Readme spec: use `README.md` for Markdown READMEs, required sections/order, a valid chosen format, no broken links, and lintable code examples; use `standard-readme-preset` to lint and `generator-standard-readme` when scaffolding.

## Standing ADRs

Decisions in `darkmatter/skills/docs/adr/` that bind every darkmatter project repo. Read the linked ADR before re-litigating any of these:

- **ADR-0001** — Beads (`bd`) is the standard task tracker and persistent agent memory store. Use `bd create` / `bd ready` / `bd close` / `bd remember`, not `TodoWrite` or `MEMORY.md` files.
- **ADR-0002** — Every project exposes a uniform command surface at `./scripts/<name>` or via `just <name>`: `install`, `setup`, `server`/`run`, `test`, `build`, `ci`, `console`. A fresh clone bootstraps via `./scripts/install && ./scripts/setup && ./scripts/build && ./scripts/server`. Turbo is the one carve-out.
- **ADR-0003** — Services and cross-language type contracts MUST use Protocol Buffers as the source of truth, with `buf` for codegen and [Connect](https://connectrpc.com) as the default transport. Exceptions: libraries, services with <5 endpoints and a single first-party consumer, and single-language schema-as-code setups (e.g. Drizzle/Effect Schema/Zod with no typed cross-language consumers).
- **ADR-0007** — TypeScript MUST NOT embed inline SQL strings or tagged SQL templates for application queries. Use a type-checked query builder/ORM, preferably Kysely; Drizzle is allowed but not preferred for complex query-heavy code because of weaker inference.

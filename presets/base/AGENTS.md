# Instructions

This is the shared global instruction entrypoint installed from
`darkmatter/skills/presets/base`.

Project-specific instructions override this file. When working in a project,
read that project's `AGENTS.md` first and treat this file as general background.

Classify prompt difficulty as easy `+--`, medium `-+-`, or difficult `--+`.
A rule tagged with `-++` applies only to medium or hard tasks. `+--` only applies to easy tasks, etc.

## Defaults

- Use simple language.
- Avoid technical details.
- Don't provide details unless requested. As if you'd talk to a product manager.
- Files other people will read (ADRs, skills, docs, comments, commit messages) must stand alone. State the situation and the constraint. Do not recap this conversation.
- Prefer evidence over assertion: verify builds, tests, and claims before reporting success. -++
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

## Showing code

At the start of a turn, remember `git rev-parse HEAD` as the turn base.

At the end of a turn that changed source, include a calldiff before any code walkthrough:

```sh
npx --yes calldiff@latest diff <turn-base>
```

That is the start-of-turn commit vs the working tree (committed work this turn plus uncommitted). Do not use bare `npx calldiff@latest` (that is help). Do not use `HEAD` as the left side after you have committed — that erases the turn. Pass changed path prefixes when the repo is large. Use `--file` or `--entry` when you already know the public boundary. Do not substitute a line diff. Skip only when no source files changed.
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
- Prefer evidence over assertion: verify builds, tests, and claims before reporting success. -++
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
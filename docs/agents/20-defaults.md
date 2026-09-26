## Defaults

- Use simple language.
- Avoid technical details.
- Don't provide details unless requested. As if you'd talk to a product manager.
- Files other people will read (ADRs, skills, docs, comments, commit messages) must stand alone. State the situation and the constraint. Do not recap this conversation.
- Prefer evidence over assertion: verify builds, tests, and claims before reporting success. -++
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep each capability cohesive and expose a small, complete interface.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
- For framework adoption, migration, or architecture/library recommendations that depend materially on upstream-supported usage, consult the relevant official guides or examples before settling the design. Version-matched bundled docs count; a link alone or source inspection alone does not establish the documented approach. Reconcile docs with the project's pinned version and source, cite the sources behind key choices, and distinguish documented support from inference. When a safe local probe can resolve a material compatibility question, run it before recommending a workaround or asking the user to choose an architecture. Keep this proportional: routine edits with no API, compatibility, or design uncertainty need no extra docs pass, and relevant docs already reviewed for the unchanged version need not be reread. If docs are unavailable, use version-matched official source/tests, disclose the limit, and defer only decisions that depend on missing evidence. Documentation informs choices; it does not authorize upgrades, scope expansion, or overriding user/project constraints.

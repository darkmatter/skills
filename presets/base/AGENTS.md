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
- Keep repo-specific context in the project repo, not in this shared preset catalog.
- Do not read or commit secrets, private keys, credentials, or local environment files.
- Preserve user changes in dirty worktrees unless explicitly asked to revert them.
- Use reusable skills from the shared catalog when their trigger conditions apply.
- After significant code changes, check the completed diff against the repo's standing ADRs before finalizing. Call out conflicts, fix them, or state which ADRs materially applied and why the work complies.
- Keep repository READMEs compliant with the Standard Readme spec: use `README.md` for Markdown READMEs, required sections/order, a valid chosen format, no broken links, and lintable code examples; use `standard-readme-preset` to lint and `generator-standard-readme` when scaffolding.


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

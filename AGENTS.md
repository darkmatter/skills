# darkmatter/skills — agent entry point

This repo is **infrastructure for other agent projects**, not an agent project itself. There is no `.agent/` directory here, no `agent.yaml`, no project-state to read.

What lives here:

- `skills/` — team-wide shared skills, distributed via the Nix Home Manager module exported by `flake.nix`
- `template/` — the bootstrap template for new darkmatter projects (`.agent/`, config, hooks, compliance, shims)
- `scripts/new-project.sh` — stamps `template/` into a new project repo
- `scripts/validate-skill.sh` — sanity-check the skills catalog
- `docs/` — catalog overview and bootstrap walkthrough

If you're an agent reading this because you were pointed at the darkmatter skills repo:

- For "add a skill to the team catalog" → see `skills/README.md` and validate with `scripts/validate-skill.sh`
- For "bootstrap a new project" → see `docs/new-project-guide.md` and use `scripts/new-project.sh`
- For "what's already shared" → see `docs/catalog.md`

If you're working inside a darkmatter **project repo** (not this one), look for that project's `AGENTS.md` and `.agent/` — they have the project-state and decisions you need.

## What this repo is not

- Not where vault state, trading positions, or any other live project data lives
- Not where any single project's agent context belongs (that goes in the project's own `.agent/`)
- Not a place to commit secrets, addresses-with-balance, or personal skills (use `personal/`, gitignored)

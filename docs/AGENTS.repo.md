# darkmatter/skills — agent entry point

This repo is **infrastructure for other agent projects**, not an agent project itself. There is no `.agent/` directory here, no `agent.yaml`, no project-state to read.

What lives here:

- `skills/` — team-wide shared skills, distributed via the Nix Home Manager module exported by `flake.nix`
- `.agents/skills/` — GENERATED subset of `skills/` shipped to Centaur sandboxes, managed by flake-skills (the `mkSkillsFlake` export in `flake.nix`); never edited by hand
- `references/` — per-language reference codebases (`rust/`, `go/`, `typescript/`) showing preferred conventions as exemplar code
- `docs/agents/` — shared instruction topics, one file per topic named `<order>-<topic>.md` (the number sets bundle order), discovered from the directory at build time and exported as the flake output `agentsMd`; downstream repos concatenate a chosen subset with their own text to generate their `AGENTS.md`, and this repo does the same
- `docs/AGENTS.md` — GENERATED bundle of every topic (`packages.agents-md-shared`); the Home Manager module installs it as every LLM client's global `AGENTS.md`. The root `AGENTS.md` is generated too: every topic plus `docs/AGENTS.repo.md`, via `packages.agents-md`
- `scripts/install-base.sh` — manually install `docs/AGENTS.md` as `AGENTS.md` into a client config dir
- `scripts/validate-skill.sh` — sanity-check the skills catalog
- `docs/` — catalog overview and OpenCode layout notes

If you're an agent reading this because you were pointed at the darkmatter skills repo:

- For "add a skill to the team catalog" → see `docs/catalog.md` and validate with `scripts/validate-skill.sh`
- For "bootstrap a new project" → use the `darkmatter-repo-setup` skill (`skills/darkmatter-repo-setup/SKILL.md`), which reads the separate `darkmatter/template` repo as the canonical template
- For "what's already shared" → see `docs/catalog.md`
- For "what are our preferred conventions in <language>" → see `references/<language>/`

If you're working inside a darkmatter **project repo** (not this one), look for that project's `AGENTS.md` and `.agent/` — they have the project-state and decisions you need.

## What this repo is not

- Not where vault state, trading positions, or any other live project data lives
- Not where any single project's agent context belongs (that goes in the project's own `.agent/`)
- Not a place to commit secrets, addresses-with-balance, or personal skills (use `personal/`, gitignored)

## Responding to the User

- Answer the question first. If it's a yes/no question, the
  first word is yes or no.
- Never justify, hedge, or mention process (beads, skills,
  agents) unless asked.
- If there's a way to reproduce or verify, give numbered
  steps. Each step is one simple action: "go to <url>", "click
  <thing>", "run <command>".
- Simple language. Short sentences. No preamble, no summary
  of work unless asked.
- If the answer is "no", say no, then give the closest thing
  that works.

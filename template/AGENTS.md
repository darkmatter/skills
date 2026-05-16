# {{project}} — agent entry point

This file is a shim. Canonical agent context lives in `.agent/`. Read these files in order before starting any session in this repo:

1. `.agent/README.md` — structure of agent-readable files
2. `.agent/context/overview.md` — what this project is, current state
3. `.agent/context/decisions.md` — standing decisions (do not re-litigate without flagging)
4. `.agent/context/conventions.md` — operating principles
5. `.agent/context/glossary.md` — domain terminology
6. `.agent/memory/known-issues.md` — active rough edges
7. `.agent/memory/lessons.md` — accumulated wisdom

Then read the project-level config:

- `agent.yaml` — project identity + advisory compliance defaults (detailed controls live in `compliance/`)
- `RULES.md` — hard constraints (must / must-not)
- `DUTIES.md` — responsibilities (owned, triggered, out-of-scope, escalation)
- `SOUL.md` — voice and disposition

For specific tasks see `.agent/workflows/`, `.agent/skills/`, `.agent/prompts/`.

If content here drifts from `.agent/`, the `.agent/` files are authoritative. Regenerate with `scripts/regen-agent-shims.sh`.

## Project bootstrap

This `.agent/` and these root files were stamped from the `darkmatter/skills` template via `scripts/new-project.sh`. Team-wide skills come in via the Nix Home Manager module from that repo. Project-local skills live in `.agent/skills/`.

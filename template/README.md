# {{project}} — agent configuration

This is the agent-facing configuration for **{{project}}**, stamped from the `darkmatter/agents` template via `scripts/new-project.sh`.

## What's here

```
.agent/                  ← canonical, provider-agnostic project context
agent.yaml               ← runtime + compliance configuration
RULES.md                 ← hard constraints (must / must-not)
DUTIES.md                ← owned and triggered responsibilities, escalation
SOUL.md                  ← voice and disposition
compliance/              ← risk assessment, regulatory map, validation schedule
hooks/                   ← session lifecycle hook scripts
knowledge/               ← knowledge index (project-specific reference material)
config/                  ← runtime config defaults
memory/                  ← session-spanning memory (separate from .agent/memory/)
scripts/regen-agent-shims.sh  ← regenerate provider shims from .agent/

AGENTS.md, CLAUDE.md, .cursorrules  ← provider shims, generated from .agent/
```

## Provider shim regeneration

After editing `.agent/`, run:

```sh
./scripts/regen-agent-shims.sh
```

The script reads `agent.yaml` for the project name and rewrites `AGENTS.md`, `CLAUDE.md`, and `.cursorrules` to point into `.agent/`.

## Team-wide skills

Skills shared across darkmatter projects are pulled in via the Nix Home Manager module exported by `darkmatter/agents`. Project-local skills live in `.agent/skills/`.

## Where to start (for humans)

1. Fill in `.agent/context/overview.md` with what this project actually is
2. Add the first standing decisions to `.agent/context/decisions.md`
3. Edit `agent.yaml` — at minimum, set `description`
4. Customize `RULES.md`, `DUTIES.md`, `SOUL.md` to match this project's particulars
5. Run `./scripts/regen-agent-shims.sh`

## Where to start (for agents)

Read `AGENTS.md` (or `CLAUDE.md`). It points you at the canonical files in order.

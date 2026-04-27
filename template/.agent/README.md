# .agent/ — provider-agnostic agent context

This directory is the canonical source of truth for AI agent context, capabilities, and workflows for **{{project}}**.

It is provider-agnostic. Any AI tool — Claude Code, Codex, OpenCode, Cursor, Aider, Cline, etc. — should read from here. Provider-specific shim files at the repo root (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`) point into `.agent/` rather than duplicating content.

## Layout

```
.agent/
├── README.md           ← this file
├── context/            ← "what is" — durable project state, always loaded
├── workflows/          ← "how to do recurring tasks" — step-by-step procedures
├── skills/             ← "capabilities" — project-local skills (team-wide shared
│                          skills come from the darkmatter agents Nix module)
├── memory/             ← "what we've learned" — accumulated lessons, history
└── prompts/            ← "task templates" — entry points for cron, slash commands, etc.
```

## Lifecycle

| Folder | Update pattern | When to edit |
|---|---|---|
| `context/` | Updated as reality changes | Project state changes (positions, decisions, scope) |
| `workflows/` | Stable | Procedure for a recurring task changes |
| `skills/` | Versioned like libraries | Capability evolves, or a new project-local capability is added |
| `memory/` | Append-mostly | After incidents, mistakes, or significant learnings |
| `prompts/` | Stable | New task template or change to entry point |

## How agents should use this directory

Any session targeting this project should:

1. Read all of `.agent/context/*.md` for grounding
2. Skim `.agent/memory/lessons.md` and `.agent/memory/known-issues.md`
3. Pull in specific skills only when their trigger conditions match the current task
4. Follow `.agent/workflows/` when executing a recurring task
5. Use `.agent/prompts/` when invoked with a specific task template

## Team-wide skills

Skills shared across darkmatter projects come in via the Nix Home Manager module from the `darkmatter/agents` repo. Project-local skills live here in `.agent/skills/`. Personal skills live outside the project (typically in your private `personal/skills/` directory).

## Provider shims

Files at the repo root that shim into `.agent/`:

- `AGENTS.md` — Codex, OpenCode, and the emerging cross-vendor convention
- `CLAUDE.md` — Claude Code
- `.cursorrules` — Cursor

Regenerate them after editing `.agent/` content with `scripts/regen-agent-shims.sh`.

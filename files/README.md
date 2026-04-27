# .agent/ — provider-agnostic agent context

This directory is the canonical source of truth for AI agent context, capabilities, and workflows for the darkmatter project. It is provider-agnostic: any AI tool (Claude Code, Cursor, Codex, Aider, Cline, etc.) should read from here.

## Layout

```
.agent/
├── README.md           ← this file
├── context/            ← "what is" — durable project state, always loaded
├── workflows/          ← "how to do specific tasks" — recurring procedures
├── skills/             ← "capabilities" — reusable tools with code + instructions
├── memory/             ← "what we've learned" — accumulated lessons, history
└── prompts/            ← "task templates" — one-shot or recurring task entry points
```

## Lifecycle

| Folder | Update pattern | When to edit |
|---|---|---|
| `context/` | Updated as reality changes | When facts about the project change (new positions, new decisions, etc.) |
| `workflows/` | Stable | When the procedure for a recurring task changes |
| `skills/` | Versioned like libraries | When the capability itself evolves; new skills added as new use cases emerge |
| `memory/` | Append-mostly | After incidents, mistakes, or significant learnings |
| `prompts/` | Stable | When you add a new task template or change the entry point |

## Provider shims

Files at the repo root that shim to this directory:

- `CLAUDE.md` — for Claude Code
- `AGENTS.md` — for Codex, OpenCode, and any agent following the emerging convention
- `.cursorrules` — for Cursor (if used)

These shims either symlink, include-by-reference, or are concatenated copies of the canonical files in `.agent/`. Regenerate them with `scripts/regen-agent-shims.sh` after editing canonical files.

## How agents should use this directory

Any session targeting this project should:

1. Read all of `.agent/context/*.md` for grounding
2. Skim `.agent/memory/lessons.md` and `.agent/memory/known-issues.md`
3. Pull in specific skills from `.agent/skills/` only when their trigger conditions match the current task
4. Use workflows in `.agent/workflows/` when executing a recurring task
5. Use prompts in `.agent/prompts/` when invoked with a specific task template

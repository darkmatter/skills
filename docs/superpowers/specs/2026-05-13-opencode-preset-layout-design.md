# OpenCode Preset Layout Design

## Context

This repository is the shared source catalog for Darkmatter agent infrastructure. It currently ships team-wide skills, a project bootstrap template, Nix/Home Manager distribution, and supporting scripts. OpenCode is the preferred client, but the repo should remain provider-aware rather than becoming a direct clone of `~/.config/opencode`.

OpenCode has native conventions for global and project config directories:

- `opencode.json` or `opencode.jsonc` for runtime configuration
- `tui.json` for TUI-only settings
- `AGENTS.md` for cross-client instructions
- `agents/`, `commands/`, `plugins/`, `skills/`, `tools/`, `themes/`, and optionally `modes/`

The source repo should map cleanly to these conventions while preserving the existing reusable catalog structure.

## Goals

- Keep this repo as the canonical source catalog for shared LLM presets.
- Prefer OpenCode as the first-class install target.
- Preserve compatibility with Claude Code, Codex, Cursor, and other clients through generated shims and shared `AGENTS.md` conventions.
- Separate reusable source assets from installed OpenCode config output.
- Make the public install story easy to understand and safe to rerun.

## Non-Goals

- Do not make the repo root itself a direct `~/.config/opencode` directory.
- Do not remove existing project bootstrap behavior in `template/`.
- Do not collapse all skills into an OpenCode-only location.
- Do not introduce machine-specific secrets, provider keys, or private skills.

## Recommended Layout

```text
darkmatter/skills/
├── README.md
├── flake.nix
├── home-manager.nix
├── presets/
│   ├── README.md
│   ├── base/
│   │   ├── AGENTS.md
│   │   ├── instructions/
│   │   └── README.md
│   └── opencode/
│       ├── opencode.jsonc
│       ├── tui.json
│       ├── package.json
│       ├── agents/
│       ├── commands/
│       ├── plugins/
│       ├── tools/
│       ├── themes/
│       └── README.md
├── skills/
│   └── <shared-skill>/SKILL.md
├── template/
├── scripts/
│   ├── install-opencode.sh
│   ├── sync-opencode.sh
│   ├── new-project.sh
│   └── validate-skill.sh
└── docs/
    ├── catalog.md
    ├── opencode-layout.md
    └── new-project-guide.md
```

## Directory Mapping

| OpenCode target | Source path | Purpose |
|---|---|---|
| `~/.config/opencode/opencode.jsonc` | `presets/opencode/opencode.jsonc` | Runtime config: models, permissions, agents, MCP servers, instructions, plugins, formatters. |
| `~/.config/opencode/tui.json` | `presets/opencode/tui.json` | TUI-only config: theme, keybinds, diff style, mouse behavior. |
| `~/.config/opencode/AGENTS.md` | `presets/base/AGENTS.md` | Global shared instructions for OpenCode and compatible clients. |
| `~/.config/opencode/agents/` | `presets/opencode/agents/` | Markdown agent definitions for primary agents and subagents. |
| `~/.config/opencode/commands/` | `presets/opencode/commands/` | Slash-command prompt templates. |
| `~/.config/opencode/plugins/` | `presets/opencode/plugins/` | JS/TS OpenCode lifecycle hooks and event extensions. |
| `~/.config/opencode/tools/` | `presets/opencode/tools/` | JS/TS custom tools callable by the model. |
| `~/.config/opencode/themes/` | `presets/opencode/themes/` | Optional OpenCode TUI themes. |
| `~/.config/opencode/skills/` | `skills/` | Shared on-demand skills with `SKILL.md`. |
| project root `AGENTS.md` | `template/AGENTS.md` | Project-local generated instruction shim. |
| project root `CLAUDE.md` | `template/CLAUDE.md` | Claude Code compatibility shim. |
| project `.agent/` | `template/.agent/` | Project-local canonical context and memory. |

## Conceptual Boundaries

### Commands

Commands are slash-invoked prompts. Use them for repeatable workflows that start an agent action, such as `/plan`, `/verify`, `/review`, or `/commit`. They should not contain executable helper scripts.

### Tools

Tools are deterministic functions the model can call. Use them for structured operations such as running project checks, reading generated metadata, computing summaries, or wrapping safe shell utilities.

### Plugins

Plugins are event-driven OpenCode extensions. Use them for lifecycle behavior such as safety hooks, notifications, automatic context injection, session observation, or tool-call interception.

### Skills

Skills are reusable instruction bundles loaded on demand. Keep them in the repo-level `skills/` catalog so they can be installed into OpenCode, Claude-compatible, and generic agent-compatible locations.

### Scripts

Scripts are repository maintenance and installation helpers. OpenCode does not auto-discover a `scripts/` directory, so repo-level scripts should remain in `scripts/`. Scripts needed only by a plugin or tool can live near that plugin/tool under a private subdirectory.

## Installation Strategy

Two installation modes should be supported:

1. Declarative install through Nix/Home Manager.
   - Sync `skills/` to OpenCode and generic skill targets.
   - Sync or link `presets/opencode/*` into `~/.config/opencode`.
   - Keep personal skills outside the repo through the existing `personalAgentSkillsPath` pattern.

2. Scripted public install.
   - Clone the repo anywhere.
   - Run `scripts/install-opencode.sh`.
   - Back up any existing `~/.config/opencode` entries before linking or copying.
   - Install plugin/tool dependencies if `presets/opencode/package.json` exists.
   - Print smoke-test instructions and uninstall guidance.

The install script should be idempotent and should avoid deleting user data. A separate `scripts/sync-opencode.sh` can refresh links/copies after updates.

## Documentation Updates

- Update `README.md` to describe the repo as an LLM preset source catalog with OpenCode as the preferred client.
- Add `docs/opencode-layout.md` explaining the directory mapping and install targets.
- Update `docs/catalog.md` only for skills, not for every OpenCode command or agent.
- Add `presets/opencode/README.md` for OpenCode-specific usage.
- Add `presets/README.md` to explain preset pack conventions.

## Validation

- Continue validating skills with `scripts/validate-skill.sh`.
- Add a lightweight preset validation script later if needed. It should check for known OpenCode directories, required files, and broken references from `opencode.jsonc`.
- Avoid adding validation that requires provider credentials or network access.

## Migration Steps

1. Add the `presets/` skeleton and OpenCode README files.
2. Move or create OpenCode-native config in `presets/opencode/`.
3. Keep existing `skills/`, `template/`, `scripts/`, and `docs/` paths stable.
4. Update README and docs to explain the new source-to-target mapping.
5. Extend `home-manager.nix` to support OpenCode config syncing after the source layout is stable.
6. Add public install/sync scripts after the first OpenCode preset is present.

## Open Questions

- Whether `presets/opencode` should install by symlink or by copy by default.
- Whether non-skill OpenCode assets should be installed by Nix first or by shell script first.
- Which initial agents and commands should be included in the first preset pack.

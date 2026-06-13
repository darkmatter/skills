# OpenCode layout

This repository is a source catalog for LLM presets. OpenCode is the preferred
client, but the repo root is not itself an OpenCode config directory.

## Source to install mapping

| OpenCode target                     | Source path                                                                                                 | Purpose                                                                                                                                                         |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `~/.config/opencode/opencode.jsonc` | `presets/opencode/opencode.nix` via Home Manager overlays; `presets/opencode/opencode.jsonc` for shell sync | Runtime config: models, permissions, agents, MCP servers, instructions, plugins, formatters. Installed as a mutable file so OpenCode can write runtime changes. |
| `~/.config/opencode/tui.json`       | `presets/opencode/tui.json`                                                                                 | TUI-only config: theme, keybinds, diff style, mouse behavior.                                                                                                   |
| `~/.config/opencode/AGENTS.md`      | `presets/base/AGENTS.md`                                                                                    | Global shared instructions.                                                                                                                                     |
| `~/.config/opencode/agents/`        | `presets/opencode/agents/`                                                                                  | Markdown agent definitions.                                                                                                                                     |
| `~/.config/opencode/commands/`      | `presets/opencode/commands/`                                                                                | Slash-command prompt templates.                                                                                                                                 |
| `~/.config/opencode/plugins/`       | `presets/opencode/plugins/`                                                                                 | JS/TS OpenCode lifecycle hooks and event extensions.                                                                                                            |
| `~/.config/opencode/tools/`         | `presets/opencode/tools/`                                                                                   | JS/TS custom tools callable by the model.                                                                                                                       |
| `~/.config/opencode/themes/`        | `presets/opencode/themes/`                                                                                  | Optional TUI themes.                                                                                                                                            |
| `~/.config/opencode/modes/`         | `presets/opencode/modes/`                                                                                   | Optional mode definitions.                                                                                                                                      |
| `~/.config/opencode/package.json`   | `presets/opencode/package.json`                                                                             | Plugin/tool dependency manifest.                                                                                                                                |
| `~/.config/opencode/skills/`        | `skills/`                                                                                                   | Shared on-demand skills.                                                                                                                                        |

## What goes where

- `presets/opencode/opencode.nix` is the canonical OpenCode base config for
  Home Manager installs. Consumers can pass `opencodeConfigOverlays` as
  functions from the previous config to a recursive override attrset.
- `presets/opencode/opencode.jsonc` mirrors the base config for non-Nix shell
  syncs and should be kept in sync with `opencode.nix`.
- `commands/` are slash-invoked prompts. They start workflows.
- `tools/` are deterministic functions the model can call during workflows.
- `plugins/` are event-driven extensions that react to OpenCode lifecycle events.
- `skills/` are reusable instruction bundles loaded on demand.
- `scripts/` are repo maintenance and install helpers. OpenCode does not auto-discover them.

## Project bootstrap files

The `template/` directory remains separate. It creates project-local files such
as `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, and `.agent/` context. Those files
belong in individual project repositories, not in global OpenCode config.

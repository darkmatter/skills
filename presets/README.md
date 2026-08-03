# presets/

Installable source packs for LLM clients.

This repository remains the source catalog. Presets in this directory are shaped
like their target clients so they can be synced or linked into local config
directories without making the repo root itself a client config directory.

## Packs

- `base/` - cross-client instructions and shared policy for all clients.
- `claude/` - Claude Code-native themes and opt-in runtime integrations.
- `opencode/` - OpenCode-native config, commands, agents, plugins, tools, and TUI settings.

Shared skills stay in the repository-level `skills/` catalog so they can be
installed into OpenCode, Claude-compatible, and generic agent-compatible targets.
Runtime integrations live with their target preset and are opt-in: installing a
preset must not silently enable a hook that sends context to a model or mutates
local client state.

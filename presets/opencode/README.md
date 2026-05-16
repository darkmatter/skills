# OpenCode preset

OpenCode-native source pack for Darkmatter agent behavior.

When installed globally, this directory maps to `~/.config/opencode/`:

- `opencode.jsonc` -> runtime config
- `tui.json` -> TUI settings
- `agents/` -> Markdown agent definitions
- `commands/` -> slash-command prompt templates
- `plugins/` -> OpenCode JS/TS event hooks
- `tools/` -> custom model-callable tools
- `themes/` -> TUI themes
- `modes/` -> optional mode definitions

Shared skills are installed from the repository-level `skills/` directory rather
than duplicated here.

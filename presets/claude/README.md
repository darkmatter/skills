# Claude preset

Claude Code-specific source pack for Darkmatter agent behavior.

`runtime/session-context-pipeline/` is an opt-in hook bundle. Run its installer
from a project or user configuration only after reviewing its model, network,
and transcript-handling behavior; it is deliberately not installed as a shared
agent skill.

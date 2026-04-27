---
update_pattern: append-only
---

# Changelog

What has changed in this `.agent/` directory and the surrounding project. Append entries as things change. Newest at top.

## 2026-04-26
- Initial `.agent/` structure created. Migrated context from previous monolithic `CLAUDE.md` into `context/`, `memory/`, `workflows/`, `skills/`, `prompts/` layout.
- Funding screener (`funding_history.py`) extracted into a skill at `.agent/skills/hl-funding-analysis/`.
- Daily report prompt extracted into `.agent/prompts/daily-report.md`, referenced by cron.
- Provider shims set up for Claude Code (`CLAUDE.md`) and the `AGENTS.md` convention.
- zkXMR spec drafted (lives at `docs/zkxmr_spec.md`, separate from agent context).

## (older entries go here as the project ages)

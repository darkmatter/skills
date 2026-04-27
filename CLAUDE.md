# darkmatter — agent entry point

This file is a shim. The canonical agent context lives in `.agent/`. Read these files in order before starting any session in this repo:

1. **`.agent/README.md`** — explains the structure of agent-readable files
2. **`.agent/context/overview.md`** — what darkmatter is, current state, who's involved
3. **`.agent/context/decisions.md`** — standing decisions and constraints (do not re-litigate without flagging)
4. **`.agent/context/conventions.md`** — operating principles
5. **`.agent/context/glossary.md`** — domain terminology
6. **`.agent/memory/known-issues.md`** — active rough edges
7. **`.agent/memory/lessons.md`** — accumulated wisdom

For specific tasks:

- **Daily reports / cron-driven status** → `.agent/workflows/daily-report.md`
- **Funding rate analysis** → `.agent/skills/hl-funding-analysis/`
- **HL API queries** → `.agent/skills/hl-api/`

For deliverables and project artifacts (not agent context):

- **zkXMR cryptographic spec** → `docs/zkxmr_spec.md`
- **Reports** (daily/weekly) → `reports/`
- **Source code** → `src/`

## Why this is structured this way

`.agent/` is provider-agnostic. Claude Code, Codex, Cursor, and any other AI tooling read from the same canonical files. Provider shims at the repo root (this file, `AGENTS.md`, `.cursorrules`) point to the canonical content rather than duplicating it.

If you find duplication, regenerate shims with `scripts/regen-agent-shims.sh`.

## For users (humans) reading this file directly

This is a quant trading project — vault management on Hyperliquid, with adjacent infrastructure work. The README at the project root has user-facing setup instructions. This file is for AI agents working in the codebase.

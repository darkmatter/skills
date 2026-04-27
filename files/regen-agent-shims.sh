#!/usr/bin/env bash
# Regenerate provider-specific shim files at repo root from canonical .agent/ content.
#
# Run this after editing files in .agent/ to keep root-level shims in sync.
# Idempotent: safe to run multiple times.
#
# Usage: ./scripts/regen-agent-shims.sh
#
# Suggested cadence:
#   - Manually after meaningful .agent/ edits
#   - As a git pre-commit hook (see end of file)

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ ! -d ".agent" ]]; then
    echo "error: .agent/ directory not found at $ROOT" >&2
    exit 1
fi

# AGENTS.md and CLAUDE.md are identical shims pointing into .agent/.
# We could symlink, but a real file is more portable across systems and
# more compatible with agents that read content rather than follow links.

cat > CLAUDE.md <<'EOF'
# darkmatter — agent entry point

This file is a shim. Canonical agent context lives in `.agent/`. Read these files in order before starting any session in this repo:

1. `.agent/README.md` — structure of agent-readable files
2. `.agent/context/overview.md` — what this project is, current state
3. `.agent/context/decisions.md` — standing decisions (do not re-litigate without flagging)
4. `.agent/context/conventions.md` — operating principles
5. `.agent/context/glossary.md` — domain terminology
6. `.agent/memory/known-issues.md` — active rough edges
7. `.agent/memory/lessons.md` — accumulated wisdom

For specific tasks see `.agent/workflows/`, `.agent/skills/`, `.agent/prompts/`.

If you find content duplication between this file and `.agent/`, the `.agent/` files are authoritative. Regenerate with `scripts/regen-agent-shims.sh`.
EOF

cp CLAUDE.md AGENTS.md

# .cursorrules (if Cursor is used) — Cursor wants short, punchy rules at the top.
# We embed a brief version of conventions here.
if command -v sed > /dev/null && [[ -f .agent/context/conventions.md ]]; then
    cat > .cursorrules <<'EOF'
# Cursor rules — auto-generated from .agent/

When working in this repo, read `.agent/context/overview.md` and `.agent/context/decisions.md` before producing analysis. Standing decisions and operating principles live in `.agent/context/`.

Do not re-litigate decisions without flagging. Do not invent data. Read-only operations only when running cron-driven workflows.

For full context, see CLAUDE.md and the `.agent/` directory.
EOF
fi

echo "shims regenerated:"
echo "  - CLAUDE.md  ($(wc -l < CLAUDE.md) lines)"
echo "  - AGENTS.md  ($(wc -l < AGENTS.md) lines)"
[[ -f .cursorrules ]] && echo "  - .cursorrules  ($(wc -l < .cursorrules) lines)"

# To install as a pre-commit hook:
#   ln -s ../../scripts/regen-agent-shims.sh .git/hooks/pre-commit
# Then it auto-runs before every commit.

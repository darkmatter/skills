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

# Prefer git toplevel; fall back to script's parent dir for pre-init use.
if ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
	:
else
	ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$ROOT"

if [[ ! -d ".agent" ]]; then
	echo "error: .agent/ directory not found at $ROOT" >&2
	exit 1
fi

# Pull project name from agent.yaml if present, else fall back to directory name.
PROJECT="$(basename "$ROOT")"
if [[ -f agent.yaml ]]; then
	name_line="$(grep -E '^name:' agent.yaml | head -1 || true)"
	if [[ -n "$name_line" ]]; then
		# Strip "name:", quotes, whitespace
		candidate="$(echo "$name_line" | sed -E 's/^name:[[:space:]]*//; s/^"//; s/"$//; s/^'\''//; s/'\''$//')"
		[[ -n "$candidate" ]] && PROJECT="$candidate"
	fi
fi

# AGENTS.md and CLAUDE.md are identical shims pointing into .agent/.
# We could symlink, but a real file is more portable across systems and
# more compatible with agents that read content rather than follow links.

shim_body() {
	cat <<EOF
# ${PROJECT} — agent entry point

This file is a shim. Canonical agent context lives in \`.agent/\`. Read these files in order before starting any session in this repo:

1. \`.agent/README.md\` — structure of agent-readable files
2. \`.agent/context/overview.md\` — what this project is, current state
3. \`.agent/context/decisions.md\` — standing decisions (do not re-litigate without flagging)
4. \`.agent/context/conventions.md\` — operating principles
5. \`.agent/context/glossary.md\` — domain terminology
6. \`.agent/memory/known-issues.md\` — active rough edges
7. \`.agent/memory/lessons.md\` — accumulated wisdom

Then read the project-level config:

- \`agent.yaml\` — project identity + advisory compliance defaults (detailed controls live in \`compliance/\`)
- \`RULES.md\` — hard constraints (must / must-not)
- \`DUTIES.md\` — responsibilities (owned, triggered, out-of-scope, escalation)
- \`SOUL.md\` — voice and disposition

For specific tasks see \`.agent/workflows/\`, \`.agent/skills/\`, \`.agent/prompts/\`.

If content here drifts from \`.agent/\`, the \`.agent/\` files are authoritative. Regenerate with \`scripts/regen-agent-shims.sh\`.
EOF
}

shim_body >CLAUDE.md
shim_body >AGENTS.md

cat >.cursorrules <<EOF
# Cursor rules — ${PROJECT}

When working in this repo, read \`.agent/context/overview.md\` and \`.agent/context/decisions.md\` before producing analysis. Standing decisions and operating principles live in \`.agent/context/\`.

Do not re-litigate decisions without flagging. Do not invent data. Read-only operations only when running cron-driven workflows.

For full context, see \`AGENTS.md\` and the \`.agent/\` directory.
EOF

echo "shims regenerated for project: ${PROJECT}"
echo "  - CLAUDE.md     ($(wc -l <CLAUDE.md | tr -d ' ') lines)"
echo "  - AGENTS.md     ($(wc -l <AGENTS.md | tr -d ' ') lines)"
echo "  - .cursorrules  ($(wc -l <.cursorrules | tr -d ' ') lines)"

# To install as a pre-commit hook:
#   ln -s ../../scripts/regen-agent-shims.sh .git/hooks/pre-commit
# Then it auto-runs before every commit.

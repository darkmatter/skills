#!/usr/bin/env bash
# Scaffold a new skill directory in darkmatter/agents/skills/.
#
# Usage:
#   scripts/scaffold-skill.sh <skill-name> "Short description"
#
# Creates:
#   skills/<name>/SKILL.md          (with frontmatter pre-filled)
#   skills/<name>/scripts/.gitkeep
#   skills/<name>/reference/.gitkeep
#
# Refuses to overwrite an existing directory. Run from anywhere — the script
# locates the repo root via its own path.

set -euo pipefail

if [[ $# -lt 2 ]]; then
	echo "usage: $0 <skill-name> \"Short description\"" >&2
	exit 2
fi

NAME="$1"
DESC="$2"

# Validate name format (lowercase, hyphenated, no underscores or caps)
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
	echo "error: skill name must be lowercase, hyphenated, alphanumeric (got: $NAME)" >&2
	echo "examples of good names: funding-screener, dm-skill-creator, end-of-turn-review" >&2
	exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/$NAME"

if [[ -e "$SKILL_DIR" ]]; then
	echo "error: $SKILL_DIR already exists" >&2
	exit 1
fi

mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/reference"
touch "$SKILL_DIR/scripts/.gitkeep" "$SKILL_DIR/reference/.gitkeep"

cat > "$SKILL_DIR/SKILL.md" <<EOF
---
name: $NAME
description: $DESC Triggers when the user asks <fill in concrete phrases>. Do NOT trigger for <fill in adjacent-but-different cases>.
---

# ${NAME//-/ }

> One-paragraph overview: what this skill does and why it exists.

## When to use

- <concrete trigger phrase or situation>
- <another>

## When NOT to use

- <adjacent thing that uses a different tool>
- <case where general knowledge suffices>

## Tools

### \`scripts/<name>.sh\`

> What it does, when to run it.

**Usage:**

\`\`\`bash
scripts/<name>.sh --help
\`\`\`

**Env vars / deps:** <list any, or "none">

## Reference

- \`reference/<topic>.md\` — <when to load this>
EOF

echo "created $SKILL_DIR"
echo
echo "next steps:"
echo "  1. edit $SKILL_DIR/SKILL.md"
echo "  2. add code under $SKILL_DIR/scripts/ and reference docs under $SKILL_DIR/reference/"
echo "  3. $REPO_ROOT/scripts/validate-skill.sh $SKILL_DIR"
echo "  4. add a row to $REPO_ROOT/docs/catalog.md"
echo "  5. rebuild ~/darwin to test:"
echo "     cd ~/darwin && darwin-rebuild switch --flake .#\$(hostname -s) \\"
echo "       --override-input darkmatter/darkmatter-agents path:$REPO_ROOT"

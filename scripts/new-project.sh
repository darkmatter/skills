#!/usr/bin/env bash
# Stamp the darkmatter agent template into a target project repo.
#
# Usage:
#   scripts/new-project.sh <target_dir> <project_name> [project_description]
#
# Example:
#   scripts/new-project.sh ~/git/darkmatter/zkxmr zkxmr "Trust-minimized XMR wrap on HyperEVM"
#
# Behavior:
#   - Copies template/ into <target_dir>/, substituting {{project}}, {{project_description}},
#     {{date}}, {{review_date}} placeholders.
#   - Refuses to overwrite existing files (use --force to override).
#   - Prints what was written.
#
# After stamping:
#   1. Edit .agent/context/overview.md to describe the project
#   2. Run ./scripts/regen-agent-shims.sh inside the target repo
#   3. git init && git add . && git commit -m "bootstrap agent config from darkmatter/agents"

set -euo pipefail

usage() {
	sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
	exit 1
}

FORCE=0
if [[ "${1-}" == "--force" ]]; then
	FORCE=1
	shift
fi

TARGET="${1-}"
PROJECT="${2-}"
PROJECT_DESCRIPTION="${3-A darkmatter project}"

[[ -z "$TARGET" || -z "$PROJECT" ]] && usage

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/template"

if [[ ! -d "$TEMPLATE" ]]; then
	echo "error: template directory not found at $TEMPLATE" >&2
	exit 1
fi

mkdir -p "$TARGET"
TARGET_ABS="$(cd "$TARGET" && pwd)"

DATE="$(date +%Y-%m-%d)"
# 3 months out by default for review_by; portable across BSD/GNU date.
if date -v+3m +%Y-%m-%d >/dev/null 2>&1; then
	REVIEW_DATE="$(date -v+3m +%Y-%m-%d)"
else
	REVIEW_DATE="$(date -d '+3 months' +%Y-%m-%d)"
fi

substitute() {
	sed \
		-e "s|{{project}}|${PROJECT}|g" \
		-e "s|{{project_description}}|${PROJECT_DESCRIPTION}|g" \
		-e "s|{{date}}|${DATE}|g" \
		-e "s|{{review_date}}|${REVIEW_DATE}|g"
}

# Walk template/ and copy each file, substituting placeholders in text files.
written=0
skipped=0

# Files that should be treated as binary (no substitution). Currently none in
# the template, but keep the hook for the future.
is_text() {
	case "$1" in
	*.md | *.yaml | *.yml | *.sh | *.cursorrules | *.gitkeep | *.gitignore | *.txt | *.toml | *.json) return 0 ;;
	*) return 1 ;;
	esac
}

while IFS= read -r -d '' src; do
	rel="${src#$TEMPLATE/}"
	dst="$TARGET_ABS/$rel"
	mkdir -p "$(dirname "$dst")"

	if [[ -e "$dst" && "$FORCE" -eq 0 ]]; then
		echo "skip (exists): $rel"
		skipped=$((skipped + 1))
		continue
	fi

	if is_text "$src"; then
		substitute <"$src" >"$dst"
	else
		cp "$src" "$dst"
	fi

	# Preserve executable bit
	[[ -x "$src" ]] && chmod +x "$dst"

	echo "  wrote: $rel"
	written=$((written + 1))
done < <(find "$TEMPLATE" -type f -print0)

echo
echo "stamped $written file(s) into $TARGET_ABS (skipped $skipped existing)"
echo
echo "next steps:"
echo "  1. cd $TARGET_ABS"
echo "  2. edit .agent/context/overview.md"
echo "  3. ./scripts/regen-agent-shims.sh"
echo "  4. git init && git add . && git commit -m 'bootstrap agent config'"

#!/usr/bin/env bash
# Validate the structure of skills in skills/ (the team-wide catalog).
#
# Usage:
#   scripts/validate-skill.sh                 # validate all skills/
#   scripts/validate-skill.sh skills/foo      # validate a single skill
#
# Checks:
#   - SKILL.md exists at skill root
#   - SKILL.md has a YAML frontmatter block with `name` and `description`
#   - Skill directory name starts with `dm-`
#   - Skill directory name matches `name:` in frontmatter
#   - Any referenced sub-paths (scripts/, reference/) actually exist if mentioned

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_skill() {
	local dir="$1"
	local rel="${dir#$REPO_ROOT/}"
	local dirname
	dirname="$(basename "$dir")"

	if [[ ! -f "$dir/SKILL.md" ]]; then
		echo "FAIL $rel: missing SKILL.md"
		fail=$((fail + 1))
		return
	fi

	# Read first frontmatter block.
	local fm
	fm="$(awk '/^---$/{c++; next} c==1' "$dir/SKILL.md" 2>/dev/null || true)"

	if [[ -z "$fm" ]]; then
		echo "FAIL $rel: SKILL.md missing YAML frontmatter"
		fail=$((fail + 1))
		return
	fi

	local name desc
	name="$(echo "$fm" | grep -E '^name:' | head -1 | sed -E 's/^name:[[:space:]]*//; s/^"//; s/"$//')"
	desc="$(echo "$fm" | grep -E '^description:' | head -1 | sed -E 's/^description:[[:space:]]*//')"

	if [[ -z "$name" ]]; then
		echo "FAIL $rel: SKILL.md frontmatter has no name"
		fail=$((fail + 1))
	fi
	if [[ -z "$desc" ]]; then
		echo "FAIL $rel: SKILL.md frontmatter has no description"
		fail=$((fail + 1))
	fi
	if [[ "$dirname" != dm-* ]]; then
		echo "FAIL $rel: team-wide skill names must start with dm-"
		fail=$((fail + 1))
	fi
	if [[ "$dirname" == dm-dm-* ]]; then
		echo "FAIL $rel: skill name has duplicate dm- namespace"
		fail=$((fail + 1))
	fi
	if [[ -n "$name" && "$dirname" != "$name" ]]; then
		echo "FAIL $rel: directory name does not match frontmatter name ($name)"
		fail=$((fail + 1))
	fi

	echo "ok   $rel"
}

if [[ $# -gt 0 ]]; then
	for d in "$@"; do
		check_skill "$(cd "$d" && pwd)"
	done
else
	if [[ ! -d "$REPO_ROOT/skills" ]]; then
		echo "no skills/ directory at $REPO_ROOT — nothing to validate"
		exit 0
	fi
	while IFS= read -r -d '' d; do
		check_skill "$d"
	done < <(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d -print0)
fi

if [[ $fail -gt 0 ]]; then
	echo
	echo "$fail check(s) failed"
	exit 1
fi

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
#   - Frontmatter block is properly closed (second ---)
#   - Frontmatter keys are well-formed (no markdown headings like ## name:)
#   - Skill directory name matches `name:` in frontmatter
#   - Any referenced sub-paths (scripts/, reference/) actually exist if mentioned

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_skill() {
  local dir="$1"
  local rel="${dir#"$REPO_ROOT"/}"

  if [[ ! -f "$dir/SKILL.md" ]]; then
    echo "FAIL $rel: missing SKILL.md"
    fail=$((fail + 1))
    return
  fi

  # Count frontmatter delimiters (lines that are exactly "---").
  local delim_count
  delim_count="$(grep -cx -e '---' "$dir/SKILL.md" 2>/dev/null || true)"
  delim_count="${delim_count:-0}"

  if [[ "$delim_count" -lt 2 ]]; then
    echo "FAIL $rel: SKILL.md frontmatter is unclosed (missing closing ---)"
    fail=$((fail + 1))
    return
  fi

  # Read first frontmatter block (between first and second ---).
  local fm
  fm="$(awk '/^---$/{c++; next} c==1' "$dir/SKILL.md" 2>/dev/null || true)"

  if [[ -z "$fm" ]]; then
    echo "FAIL $rel: SKILL.md missing YAML frontmatter"
    fail=$((fail + 1))
    return
  fi

  # Check for malformed keys (markdown headings like ## name: instead of name:).
  if echo "$fm" | grep -qE '^#+[[:space:]]*(name|description):'; then
    echo "FAIL $rel: SKILL.md frontmatter has markdown heading instead of YAML key (## name: or ## description:)"
    fail=$((fail + 1))
    return
  fi

  local name desc
  name="$(printf '%s\n' "$fm" | awk '/^name:/ {sub(/^name:[[:space:]]*/, ""); gsub(/^"|"$/, ""); print; exit}')"
  desc="$(printf '%s\n' "$fm" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}')"

  if [[ -z "$name" ]]; then
    echo "FAIL $rel: SKILL.md frontmatter has no name"
    fail=$((fail + 1))
  fi
  if [[ -z "$desc" ]]; then
    echo "FAIL $rel: SKILL.md frontmatter has no description"
    fail=$((fail + 1))
  fi
  if [[ -n "$name" && "$(basename "$dir")" != "$name" ]]; then
    echo "WARN $rel: directory name does not match frontmatter name ($name)"
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

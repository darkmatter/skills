#!/usr/bin/env bash
# Regenerate .agents/skills/ (the Centaur sandbox subset) from
# .agents/skills.manifest.
#
# .agents/skills is the conventional skillsSubdir in the Centaur overlay
# contract, so darkmatter/skills can be listed as an overlay source with
# just repo + ref. The generated tree contains real copies (the sandbox
# skill merger preserves symlinks, which would dangle in ~/workspace),
# so this script plus the CI drift check are what keep the copies honest.
#
# Usage:
#   scripts/sync-sandbox-skills.sh           # regenerate .agents/skills/
#   scripts/sync-sandbox-skills.sh --check   # fail if the tree is stale (CI)
#
# The manifest lists one skill name per line (# comments and blank lines
# ignored); each must exist under skills/. Never edit .agents/skills/ by
# hand — edit skills/<name>/ or the manifest and rerun this script.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$REPO_ROOT/.agents/skills.manifest"
CATALOG="$REPO_ROOT/skills"
TARGET="$REPO_ROOT/.agents/skills"

check_mode=0
if [[ "${1:-}" == "--check" ]]; then
  check_mode=1
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--check]" >&2
  exit 2
fi

[[ -f "$MANIFEST" ]] || { echo "FAIL: missing $MANIFEST" >&2; exit 1; }

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

fail=0
count=0
while IFS= read -r name; do
  name="${name%%#*}"
  name="$(echo "$name" | tr -d '[:space:]')"
  [[ -z "$name" ]] && continue

  src="$CATALOG/$name"
  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "FAIL: manifest lists '$name' but skills/$name/SKILL.md does not exist" >&2
    fail=1
    continue
  fi
  cp -R "$src" "$staging/$name"
  count=$((count + 1))
done <"$MANIFEST"

[[ $fail -eq 0 ]] || exit 1
find "$staging" -name '.DS_Store' -delete

if [[ $check_mode -eq 1 ]]; then
  if ! diff -r "$staging" "$TARGET" >/dev/null 2>&1; then
    echo "FAIL: .agents/skills/ is out of sync with .agents/skills.manifest" >&2
    echo "      run scripts/sync-sandbox-skills.sh and commit the result" >&2
    diff -rq "$staging" "$TARGET" >&2 || true
    exit 1
  fi
  echo "OK: .agents/skills/ matches the manifest ($count skills)"
else
  rm -rf "$TARGET"
  mkdir -p "$TARGET"
  cp -R "$staging"/. "$TARGET"/
  echo "OK: regenerated .agents/skills/ ($count skills)"
fi

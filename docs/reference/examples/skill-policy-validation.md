# Reference example — skill policy validation

This extends the current `scripts/validate-skill.sh` idea with policy checks for ADR-0001 and catalog coverage.

```sh
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fail=0
warn=0

error() {
  echo "FAIL: $*" >&2
  fail=$((fail + 1))
}

warning() {
  echo "WARN: $*" >&2
  warn=$((warn + 1))
}

manual_prefix_re='^(run|kickoff|setup|init|do)-'

check_skill() {
  local dir="$1"
  local rel="${dir#$REPO_ROOT/}"
  local base
  base="$(basename "$dir")"

  if [ ! -f "$dir/SKILL.md" ]; then
    error "$rel missing SKILL.md"
    return
  fi

  local fm name desc
  fm="$(awk '/^---$/{c++; next} c==1' "$dir/SKILL.md" || true)"
  name="$(printf '%s\n' "$fm" | grep -E '^name:' | head -1 | sed -E 's/^name:[[:space:]]*//; s/^"//; s/"$//')"
  desc="$(printf '%s\n' "$fm" | grep -E '^description:' | head -1 | sed -E 's/^description:[[:space:]]*//; s/^"//; s/"$//')"

  [ -n "$name" ] || error "$rel frontmatter missing name"
  [ -n "$desc" ] || error "$rel frontmatter missing description"

  if [ -n "$name" ] && [ "$name" != "$base" ]; then
    error "$rel directory name does not match frontmatter name: $name"
  fi

  # ADR-0001: manual skills use imperative prefix and description opening line.
  if printf '%s\n' "$base" | grep -Eq "$manual_prefix_re"; then
    if ! printf '%s\n' "$desc" | grep -q '^Manual-invocation skill'; then
      error "$rel manual-prefixed skill must start description with 'Manual-invocation skill'"
    fi
  fi

  # Catalog coverage.
  if [ -f docs/catalog.md ] && ! grep -q "\`$base\`" docs/catalog.md; then
    error "docs/catalog.md missing skill row for $base"
  fi

  # Standardize supporting docs dir spelling.
  if [ -d "$dir/reference" ] && [ -d "$dir/references" ]; then
    error "$rel has both reference/ and references/; choose one"
  fi
  if [ -d "$dir/references" ]; then
    warning "$rel uses references/; repo convention should choose one spelling"
  fi

  # Shell scripts should be executable.
  if [ -d "$dir/scripts" ]; then
    while IFS= read -r -d '' script; do
      if [ ! -x "$script" ]; then
        error "$rel script is not executable: ${script#$dir/}"
      fi
    done < <(find "$dir/scripts" -type f -name '*.sh' -print0)
  fi

  echo "ok $rel"
}

if [ "$#" -gt 0 ]; then
  for d in "$@"; do
    check_skill "$(cd "$d" && pwd)"
  done
else
  while IFS= read -r -d '' d; do
    check_skill "$d"
  done < <(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d -print0)
fi

if [ "$warn" -gt 0 ]; then
  echo "$warn warning(s)"
fi

if [ "$fail" -gt 0 ]; then
  echo "$fail failure(s)"
  exit 1
fi
```

#!/usr/bin/env bash
# render-agents.sh — Install or refresh darkmatter's shared instructions in a repo.
#
# Usage: render-agents.sh [--check] [<repo-dir>]
#
# <repo-dir> defaults to the current directory. The repo's AGENTS.md keeps its
# own text and a marked block:
#
#   <!-- BEGIN docs/AGENTS.md -->
#   ...generated, do not edit...
#   <!-- END docs/AGENTS.md -->
#
# The block is replaced with docs/AGENTS.md from this checkout of
# darkmatter/skills. Codex, OpenCode, and omp read AGENTS.md verbatim, so this
# is how the shared rules reach every client without @-import support.
#
# If the repo has no AGENTS.md, one is created with the block at the top and a
# placeholder section for repo-specific text. If CLAUDE.md is missing, it is
# created as `@AGENTS.md`. Existing CLAUDE.md files are never touched.
#
#   --check   Exit 1 if AGENTS.md is missing or out of date; write nothing.
set -euo pipefail

CHECK=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    --help | -h) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$arg" >&2; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done
TARGET="${TARGET:-$PWD}"

SRC="${DARKMATTER_AGENTS_MD:-$(cd "$(dirname "$0")/.." && pwd)/docs/AGENTS.md}"
DST="$TARGET/AGENTS.md"
CLAUDE="$TARGET/CLAUDE.md"
BEGIN='<!-- BEGIN docs/AGENTS.md -->'
END='<!-- END docs/AGENTS.md -->'

[[ -f "$SRC" ]] || { printf 'error: %s missing\n' "$SRC" >&2; exit 1; }
[[ -d "$TARGET" ]] || { printf 'error: %s is not a directory\n' "$TARGET" >&2; exit 1; }

if [[ ! -f "$DST" ]]; then
  if [[ "$CHECK" == 1 ]]; then
    printf 'AGENTS.md missing in %s; run render-agents.sh\n' "$TARGET" >&2
    exit 1
  fi
  name="$(basename "$(cd "$TARGET" && pwd)")"
  printf '%s\n%s\n\n# %s\n\nRepo-specific instructions go here, below the shared block.\n' \
    "$BEGIN" "$END" "$name" > "$DST"
fi

if ! grep -qF "$BEGIN" "$DST" || ! grep -qF "$END" "$DST"; then
  printf 'error: %s lacks the BEGIN/END docs/AGENTS.md markers\n' "$DST" >&2
  exit 1
fi

rendered="$(awk -v begin="$BEGIN" -v end="$END" -v src="$SRC" '
  $0 == begin { print; while ((getline line < src) > 0) print line; close(src); skip = 1; next }
  $0 == end   { skip = 0 }
  !skip       { print }
' "$DST")"

if [[ "$CHECK" == 1 ]]; then
  if [[ "$rendered" == "$(cat "$DST")" ]]; then
    printf 'AGENTS.md is up to date\n'
  else
    printf 'AGENTS.md is stale; run render-agents.sh\n' >&2
    exit 1
  fi
  exit 0
fi

printf '%s\n' "$rendered" > "$DST"
printf 'rendered docs/AGENTS.md into %s\n' "$DST"

if [[ ! -e "$CLAUDE" ]]; then
  printf '@AGENTS.md\n' > "$CLAUDE"
  printf 'created %s\n' "$CLAUDE"
fi

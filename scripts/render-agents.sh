#!/usr/bin/env bash
# render-agents.sh — Inline docs/AGENTS.md into the repo-root AGENTS.md.
#
# Usage: render-agents.sh [--check]
#
# AGENTS.md keeps its repo-specific text and a marked block:
#
#   <!-- BEGIN docs/AGENTS.md -->
#   ...generated, do not edit...
#   <!-- END docs/AGENTS.md -->
#
# This script replaces the block's contents with the current docs/AGENTS.md so
# every client that reads AGENTS.md verbatim (Codex, OpenCode, omp) sees the
# shared instructions without needing @-import support.
#
#   --check   Exit 1 if AGENTS.md is out of date instead of rewriting it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/docs/AGENTS.md"
DST="$REPO_ROOT/AGENTS.md"
BEGIN='<!-- BEGIN docs/AGENTS.md -->'
END='<!-- END docs/AGENTS.md -->'

[[ -f "$SRC" ]] || { printf 'error: %s missing\n' "$SRC" >&2; exit 1; }
grep -qF "$BEGIN" "$DST" && grep -qF "$END" "$DST" \
  || { printf 'error: %s lacks the BEGIN/END docs/AGENTS.md markers\n' "$DST" >&2; exit 1; }

rendered="$(awk -v begin="$BEGIN" -v end="$END" -v src="$SRC" '
  $0 == begin { print; while ((getline line < src) > 0) print line; close(src); skip = 1; next }
  $0 == end   { skip = 0 }
  !skip       { print }
' "$DST")"

if [[ "${1-}" == "--check" ]]; then
  if [[ "$rendered" == "$(cat "$DST")" ]]; then
    printf 'AGENTS.md is up to date\n'
  else
    printf 'AGENTS.md is stale; run scripts/render-agents.sh\n' >&2
    exit 1
  fi
else
  printf '%s\n' "$rendered" > "$DST"
  printf 'rendered %s into %s\n' "docs/AGENTS.md" "AGENTS.md"
fi

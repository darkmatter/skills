#!/usr/bin/env bash
# install-base.sh — Install the shared base instructions (AGENTS.md)
# into a target directory.
#
# Usage: install-base.sh [OPTIONS]
#
# Options:
#   --target <dir>  Target directory (required).
#   --link          Symlink source files into target (default).
#   --copy          Copy source files into target instead of symlinking.
#   --dry-run       Print actions without writing anything.
#   --help, -h      Show this help text.
#
# Installs docs/AGENTS.md as AGENTS.md.
# Backs up conflicting non-symlink files as <name>.bak.<timestamp>.
# Never deletes user data.
set -euo pipefail

MODE="link"
DRY_RUN=0
TARGET=""

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      MODE="copy"
      shift
      ;;
    --link)
      MODE="link"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --target)
      TARGET="${2-}"
      [[ -z "$TARGET" ]] && usage
      shift 2
      ;;
    --help | -h) usage ;;
    *) usage ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  printf 'error: --target <dir> is required\n' >&2
  usage
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$REPO_ROOT/docs"
STAMP="$(date +%Y%m%d%H%M%S)"

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ensure_parent() {
  run mkdir -p "$(dirname "$1")"
}

backup_conflict() {
  local dst="$1"
  if [[ ! -e "$dst" && ! -L "$dst" ]]; then
    return 0
  fi
  if [[ -L "$dst" ]]; then
    run rm "$dst"
    return 0
  fi
  run mv "$dst" "$dst.bak.$STAMP"
}

install_one() {
  local src="$1"
  local dst="$2"
  ensure_parent "$dst"
  backup_conflict "$dst"
  if [[ "$MODE" == "copy" ]]; then
    run cp -R "$src" "$dst"
  else
    run ln -s "$src" "$dst"
  fi
}

install_one "$BASE/AGENTS.md" "$TARGET/AGENTS.md"

printf 'base instructions installed to %s using %s mode\n' "$TARGET" "$MODE"

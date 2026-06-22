#!/usr/bin/env bash
# sync-omp.sh — Sync the Darkmatter omp (oh-my-pi) preset into an agent dir.
#
# Usage: sync-omp.sh [OPTIONS]
#
# Options:
#   --link          Symlink source files into target (default).
#   --copy          Copy source files into target instead of symlinking.
#   --target <dir>  Set target directory (default: $PI_CODING_AGENT_DIR
#                   or ~/.omp/agent).
#   --dry-run       Print actions without writing anything.
#   --help, -h      Show this help text.
#
# Backs up conflicting non-symlink files as <name>.bak.<timestamp>.
# config.yml and models.yml are always copied so omp can mutate them at runtime.
# Never deletes user data.
set -euo pipefail

MODE="link"
DRY_RUN=0
TARGET="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
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

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$REPO_ROOT/presets/base"
OMP="$REPO_ROOT/presets/omp"
SKILLS="$REPO_ROOT/skills"
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

install_mutable() {
  local src="$1"
  local dst="$2"
  ensure_parent "$dst"
  backup_conflict "$dst"
  run cp -f "$src" "$dst"
}

install_one "$BASE/AGENTS.md" "$TARGET/AGENTS.md"
install_one "$OMP/RULES.md" "$TARGET/RULES.md"
install_mutable "$OMP/config.yml" "$TARGET/config.yml"
install_mutable "$OMP/models.yml" "$TARGET/models.yml"
install_one "$SKILLS" "$TARGET/skills"

printf 'omp preset synced to %s using %s mode\n' "$TARGET" "$MODE"

#!/usr/bin/env bash
# sync-opencode.sh — Sync OpenCode preset files into a target directory.
#
# Usage: sync-opencode.sh [OPTIONS]
#
# Options:
#   --link          Symlink source files into target (default).
#   --copy          Copy source files into target instead of symlinking.
#   --target <dir>  Set target directory (default: $XDG_CONFIG_HOME/opencode
#                   or ~/.config/opencode).
#   --dry-run       Print actions without writing anything.
#   --help, -h      Show this help text.
#
# Backs up conflicting non-symlink files as <name>.bak.<timestamp>.
# opencode.jsonc is always copied so OpenCode can mutate it at runtime.
# Never deletes user data.
set -euo pipefail

MODE="link"
DRY_RUN=0
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

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
OC="$REPO_ROOT/presets/opencode"
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
install_mutable "$OC/opencode.jsonc" "$TARGET/opencode.jsonc"
install_one "$OC/tui.json" "$TARGET/tui.json"
install_one "$OC/package.json" "$TARGET/package.json"
install_one "$OC/agents" "$TARGET/agents"
install_one "$OC/commands" "$TARGET/commands"
install_one "$OC/plugins" "$TARGET/plugins"
install_one "$OC/tools" "$TARGET/tools"
install_one "$OC/themes" "$TARGET/themes"
install_one "$OC/modes" "$TARGET/modes"
install_one "$SKILLS" "$TARGET/skills"

printf 'OpenCode preset synced to %s using %s mode\n' "$TARGET" "$MODE"

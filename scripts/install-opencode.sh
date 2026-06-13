#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
DRY_RUN=0

args=("$@")
idx=0
while [[ "$idx" -lt "${#args[@]}" ]]; do
  case "${args[$idx]}" in
    --dry-run) DRY_RUN=1 ;;
    --target)
      idx=$((idx + 1))
      CONFIG_DIR="${args[$idx]-}"
      [[ -z "$CONFIG_DIR" ]] && { printf 'error: --target requires a value\n' >&2; exit 1; }
      ;;
    --help|-h)
      "$REPO_ROOT/scripts/sync-opencode.sh" --help
      printf '\nWrapper behavior:\n'
      printf '  - Installs npm/bun dependencies if package.json exists.\n'
      printf '  - Prints next steps and uninstall guidance.\n'
      exit 0
      ;;
  esac
  idx=$((idx + 1))
done

"$REPO_ROOT/scripts/sync-opencode.sh" "$@"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'dry-run: skipping dependency install\n'
elif [[ -f "$CONFIG_DIR/package.json" ]]; then
  if command -v bun >/dev/null 2>&1; then
    (cd "$CONFIG_DIR" && bun install)
  elif command -v npm >/dev/null 2>&1; then
    (cd "$CONFIG_DIR" && npm install)
  else
    printf 'warning: neither bun nor npm found; skipping OpenCode plugin/tool dependency install\n' >&2
  fi
fi

cat <<'MSG'

Next steps:
  1. Run: opencode
  2. Confirm the shared AGENTS.md and skills are visible.
  3. Edit provider/model settings in ~/.config/opencode/opencode.jsonc if needed.

Uninstall guidance:
  Remove symlinks created in ~/.config/opencode, or restore any *.bak.<timestamp>
  backups created by the sync script. The installer never deletes the cloned repo.

MSG

#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

args=("$@")
idx=0
while [[ "$idx" -lt "${#args[@]}" ]]; do
  case "${args[$idx]}" in
    --target)
      idx=$((idx + 1))
      TARGET="${args[$idx]-}"
      [[ -z "$TARGET" ]] && { printf 'error: --target requires a value\n' >&2; exit 1; }
      ;;
    --help | -h)
      "$REPO_ROOT/scripts/sync-omp.sh" --help
      exit 0
      ;;
  esac
  idx=$((idx + 1))
done

"$REPO_ROOT/scripts/sync-omp.sh" "$@"

cat <<MSG

Next steps:
  1. Ensure OPENROUTER_API_KEY is set in the environment.
  2. Run: omp config list   # verify the preset's settings loaded
  3. Adjust model roles in $TARGET/config.yml if needed.

Uninstall guidance:
  Remove the symlinks/files created in $TARGET, or restore any *.bak.<timestamp>
  backups created by the sync script. The installer never deletes the cloned repo.
MSG

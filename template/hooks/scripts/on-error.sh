#!/usr/bin/env bash
set -euo pipefail
_input=$(cat)
# shellcheck disable=SC2034
INPUT="$_input"
echo '{"action": "allow", "modifications": null}'

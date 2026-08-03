#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${OPENCODE_CONTINUOUS_LEARNING_DIR:-$HOME/.config/opencode/runtime/continuous-learning}"
"$RUNTIME_DIR/stop.sh"

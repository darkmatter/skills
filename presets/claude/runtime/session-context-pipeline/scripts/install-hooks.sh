#!/usr/bin/env bash
# session-context-pipeline — wire the pipeline into Claude Code settings.
#
# A skill directory on disk executes nothing by itself; hooks only run once
# they're registered in Claude Code's settings. This installer does that
# registration idempotently (re-running replaces this skill's entries, never
# duplicates them) and leaves everything else in the settings file untouched.
#
# Usage:
#   install-hooks.sh                  # project install: <git root>/.claude/settings.json
#   install-hooks.sh --project DIR    # project install into DIR/.claude/settings.json
#   install-hooks.sh --user           # user install: ~/.claude/settings.json
#   install-hooks.sh --uninstall [--user | --project DIR]
#
# What gets registered (absolute paths into this skill checkout):
#   PostToolUse      (matcher "*") → summarize-session.sh   timeout 10
#   UserPromptSubmit               → enrich-context.sh      timeout 10
#   Stop                           → review-turn.sh         timeout 180
#
# Project installs also seed .claude/session-context-pipeline.json from
# config.example.json when absent.
#
# Hooks load at session start — restart Claude Code after installing.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE="project"
TARGET_DIR=""
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) MODE="user" ;;
    --project)
      MODE="project"
      if [[ $# -gt 1 && "${2#--}" == "$2" ]]; then
        TARGET_DIR="$2"
        shift
      fi
      ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: $1 (see --help)" >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "$MODE" == "user" ]]; then
  SETTINGS="$HOME/.claude/settings.json"
else
  if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fi
  SETTINGS="$TARGET_DIR/.claude/settings.json"
fi

mkdir -p "$(dirname "$SETTINGS")"
[[ -f "$SETTINGS" ]] || echo '{}' >"$SETTINGS"

if ! jq -e . >/dev/null 2>&1 <"$SETTINGS"; then
  echo "refusing to touch $SETTINGS — not valid JSON" >&2
  exit 1
fi

BACKUP="$SETTINGS.bak.$(date +%s)"
cp "$SETTINGS" "$BACKUP"

# Entries owned by this skill are recognized by their command path containing
# "session-context-pipeline" — that's what makes install/uninstall idempotent.
# Strip at the inner .hooks[] level so a matcher entry that also carries
# someone else's hooks keeps them; only entries left empty are dropped.
STRIP='
  .hooks = ((.hooks // {}) | with_entries(
    .value |= (map(
      .hooks = ((.hooks // []) | map(select(
        ((.command? // "") | contains("session-context-pipeline")) | not
      )))
    ) | map(select((.hooks | length) > 0)))
  ) | with_entries(select((.value | length) > 0)))
'

if [[ "$UNINSTALL" == "1" ]]; then
  jq "$STRIP | if (.hooks | length) == 0 then del(.hooks) else . end" "$SETTINGS" >"$SETTINGS.tmp"
  mv "$SETTINGS.tmp" "$SETTINGS"
  echo "removed session-context-pipeline hooks from $SETTINGS (backup: $BACKUP)"
  echo "restart Claude Code to apply."
  exit 0
fi

ADD="$(jq -n \
  --arg sum "$SKILL_DIR/scripts/summarize-session.sh" \
  --arg enr "$SKILL_DIR/scripts/enrich-context.sh" \
  --arg rev "$SKILL_DIR/scripts/review-turn.sh" \
  '{
    PostToolUse: [{matcher: "*", hooks: [{type: "command", command: $sum, timeout: 10}]}],
    UserPromptSubmit: [{matcher: "", hooks: [{type: "command", command: $enr, timeout: 10}]}],
    Stop: [{matcher: "", hooks: [{type: "command", command: $rev, timeout: 180}]}]
  }')"

jq --argjson add "$ADD" "$STRIP"' |
  .hooks = (reduce ($add | to_entries[]) as $e (.hooks; .[$e.key] = ((.[$e.key] // []) + $e.value)))
' "$SETTINGS" >"$SETTINGS.tmp"
mv "$SETTINGS.tmp" "$SETTINGS"

echo "installed session-context-pipeline hooks into $SETTINGS (backup: $BACKUP)"

if [[ "$MODE" == "project" ]]; then
  CONF="$TARGET_DIR/.claude/session-context-pipeline.json"
  if [[ ! -f "$CONF" ]]; then
    cp "$SKILL_DIR/config.example.json" "$CONF"
    echo "seeded config at $CONF — tune thresholds, triggers, and review checklist there."
  fi
fi

echo
echo "hooks load at session start — restart Claude Code."
echo "session state lands under: ${SCP_STATE_ROOT:-${TMPDIR:-/tmp}/session-context-pipeline}/<session_id>/"

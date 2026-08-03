#!/usr/bin/env bash
# session-context-pipeline — throttled session summarizer.
#
# Wire as a Claude Code PostToolUse hook (matcher "*"). The foreground path is
# a handful of file stats and exits 0 in milliseconds — it never blocks the
# turn and never prints to stdout, so it adds zero context noise. When a
# summary is due, it detaches a --worker copy of itself that:
#
#   1. renders the most recent transcript slice to readable text
#   2. asks a cheap summarizer model for strict JSON:
#      { tags[], libraries[{name, ecosystem, repo, evidence}], bullets[], focus }
#   3. atomically writes it to <state>/<session_id>/summary.json
#
# Throttling (config, see config.example.json):
#   .summarize.interval_seconds   min seconds between runs        (default 180)
#   .summarize.min_new_bytes      min transcript growth to re-run (default 16384)
#
# Model: SCP_SUMMARY_MODEL env > .summarize.model config > gpt-5-mini.
# Fails open: no key / gateway down / bad JSON → keep the previous summary.

set -euo pipefail

# Recursion guard: headless agent runs spawned by this pipeline inherit
# SCP_DISABLE=1 and must not re-enter the pipeline via their own hooks.
if [[ -n "${SCP_DISABLE:-}" ]]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scp-lib.sh
. "$SCRIPT_DIR/scp-lib.sh"

# ---------------------------------------------------------------- worker ----
if [[ "${1:-}" == "--worker" ]]; then
  STATE_DIR="$2"
  TRANSCRIPT="$3"

  # One worker per session at a time; steal locks older than 10 minutes.
  LOCK="$STATE_DIR/summarize.lock"
  if ! mkdir "$LOCK" 2>/dev/null; then
    if [[ -n "$(find "$LOCK" -maxdepth 0 -mmin +10 2>/dev/null)" ]]; then
      rmdir "$LOCK" 2>/dev/null || true
      mkdir "$LOCK" 2>/dev/null || exit 0
    else
      exit 0
    fi
  fi
  trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

  TAIL_LINES="$(scp_config '.summarize.transcript_tail_lines' 350)"
  EXCERPT="$(scp_transcript_tail "$TRANSCRIPT" "$TAIL_LINES" 24000)"
  [[ -n "$EXCERPT" ]] || exit 0

  PREV="{}"
  [[ -r "$STATE_DIR/summary.json" ]] && PREV="$(cat "$STATE_DIR/summary.json")"

  SYS="$(cat "$SCP_SKILL_DIR/reference/summarizer-prompt.md")"
  USER_MSG="## Previous summary (merge and update; drop stale items)

${PREV}

## Transcript excerpt (most recent slice)

${EXCERPT}"

  MODEL="${SCP_SUMMARY_MODEL:-$(scp_config '.summarize.model' 'gpt-5-mini')}"
  RAW="$(scp_llm_chat "$MODEL" "$SYS" "$USER_MSG")" || {
    echo "$(date -u '+%FT%TZ') summarizer model call failed (model=$MODEL)" >&2
    exit 0
  }

  JSON="$(scp_extract_json <<<"$RAW")" || {
    echo "$(date -u '+%FT%TZ') summarizer returned non-JSON output" >&2
    exit 0
  }

  # Schema gate: tags and bullets must be arrays. Anything else → discard.
  jq -e '(.tags | type == "array") and (.bullets | type == "array")' >/dev/null 2>&1 <<<"$JSON" || {
    echo "$(date -u '+%FT%TZ') summarizer JSON failed schema check" >&2
    exit 0
  }

  TMP="$STATE_DIR/summary.json.tmp.$$"
  jq --arg t "$(date -u '+%FT%TZ')" '. + {updated_at: $t}' <<<"$JSON" >"$TMP"
  mv "$TMP" "$STATE_DIR/summary.json"
  exit 0
fi

# ------------------------------------------------------------- hook path ----
INPUT="$(cat)"
SESSION_ID="$(jq -r '.session_id // empty' <<<"$INPUT")"
TRANSCRIPT="$(jq -r '.transcript_path // empty' <<<"$INPUT")"
[[ -n "$SESSION_ID" && -n "$TRANSCRIPT" && -r "$TRANSCRIPT" ]] || exit 0

STATE_DIR="$(scp_state_dir "$SESSION_ID")"

INTERVAL="$(scp_config '.summarize.interval_seconds' 180)"
MIN_GROWTH="$(scp_config '.summarize.min_new_bytes' 16384)"

NOW="$(date +%s)"
LAST_RUN=0
[[ -r "$STATE_DIR/summarize.last_run" ]] && LAST_RUN="$(cat "$STATE_DIR/summarize.last_run")"
(( NOW - LAST_RUN >= INTERVAL )) || exit 0

SIZE="$(wc -c <"$TRANSCRIPT" | tr -d '[:space:]')"
LAST_SIZE=0
[[ -r "$STATE_DIR/summarize.last_size" ]] && LAST_SIZE="$(cat "$STATE_DIR/summarize.last_size")"
(( SIZE - LAST_SIZE >= MIN_GROWTH )) || exit 0

# Claim the slot before spawning so parallel PostToolUse firings don't
# double-spawn workers.
echo "$NOW" >"$STATE_DIR/summarize.last_run"
echo "$SIZE" >"$STATE_DIR/summarize.last_size"

scp_spawn "$STATE_DIR/summarize.log" \
  "$SCRIPT_DIR/summarize-session.sh" --worker "$STATE_DIR" "$TRANSCRIPT"

exit 0

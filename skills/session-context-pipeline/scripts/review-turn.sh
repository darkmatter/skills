#!/usr/bin/env bash
# session-context-pipeline — end-of-turn checklist review.
#
# Wire as a Claude Code Stop hook. Sends the turn's uncommitted diff plus the
# running session summary through a reviewer model with a configurable
# checklist ("did the agent invent unconventional solutions?", "is it
# tested?", ...).
#
# Modes (.review.mode, or SCP_REVIEW_MODE env — env wins):
#   off     never runs
#   report  (default) critique printed to stdout — lands in the transcript
#           for the human; the agent is not interrupted
#   block   on a FAIL verdict the critique goes to stderr with exit 2, which
#           feeds it back to Claude and forces it to keep working
#
# Loop safety: exits immediately when stop_hook_active is set (i.e. we're
# already continuing because a previous Stop hook blocked). Also skips when
# the diff hash is unchanged since the last review, so consecutive stops on
# identical work cost nothing.
#
# Fails open on every dependency: not a git repo, empty/trivial diff, gateway
# unreachable → exit 0 silently.

set -euo pipefail

# Recursion guard: headless agent runs spawned by this pipeline inherit
# SCP_DISABLE=1 and must not re-enter the pipeline via their own hooks.
if [[ -n "${SCP_DISABLE:-}" ]]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scp-lib.sh
. "$SCRIPT_DIR/scp-lib.sh"

INPUT="$(cat)"

# Never re-review while a previous block is being addressed — infinite-loop guard.
[[ "$(jq -r '.stop_hook_active // false' <<<"$INPUT")" == "true" ]] && exit 0

MODE="${SCP_REVIEW_MODE:-$(scp_config '.review.mode' report)}"
[[ "$MODE" == "off" ]] && exit 0

SESSION_ID="$(jq -r '.session_id // empty' <<<"$INPUT")"
[[ -n "$SESSION_ID" ]] || exit 0
STATE_DIR="$(scp_state_dir "$SESSION_ID")"

# ------------------------------------------------------------ gather work ----
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

DIFF="$(git diff HEAD 2>/dev/null || true)"
UNTRACKED="$(git ls-files --others --exclude-standard 2>/dev/null | head -n 40 || true)"
[[ -n "$DIFF$UNTRACKED" ]] || exit 0

MIN_CHANGED="$(scp_config '.review.min_changed_lines' 4)"
CHANGED="$(grep -cE '^[+-][^+-]' <<<"$DIFF" || true)"
if (( CHANGED < MIN_CHANGED )) && [[ -z "$UNTRACKED" ]]; then
  exit 0
fi

# Skip when nothing changed since the last review (consecutive stops).
DIFF_SHA="$(printf '%s\n%s' "$DIFF" "$UNTRACKED" | shasum | cut -d' ' -f1)"
LAST_SHA=""
[[ -r "$STATE_DIR/review.last_sha" ]] && LAST_SHA="$(cat "$STATE_DIR/review.last_sha")"
[[ "$DIFF_SHA" == "$LAST_SHA" ]] && exit 0

# ------------------------------------------------------------ build prompt ----
DEFAULT_CHECKLIST='[
  "Did the agent invent unconventional solutions where the repo already has an established pattern? Point at the existing pattern.",
  "Is the change tested — were tests added or updated, and is there evidence they were actually run?",
  "Any scope creep beyond what the session summary says was asked?",
  "Leftover debug scaffolding, dead code, commented-out blocks, or TODO/stub placeholders presented as done?",
  "Are errors swallowed silently, or do fallbacks hide failure instead of surfacing it?",
  "Do the claims in the final answer match what the diff actually does?"
]'
CHECKLIST_JSON="$(scp_config_json '.review.checklist' "$DEFAULT_CHECKLIST")"
CHECKLIST="$(jq -r 'to_entries | map("\(.key + 1). \(.value)") | join("\n")' <<<"$CHECKLIST_JSON" 2>/dev/null || true)"
[[ -n "$CHECKLIST" ]] || CHECKLIST="$(jq -r 'to_entries | map("\(.key + 1). \(.value)") | join("\n")' <<<"$DEFAULT_CHECKLIST")"

SESSION_CONTEXT="(no session summary available)"
if [[ -r "$STATE_DIR/summary.json" ]]; then
  SESSION_CONTEXT="$(jq -r '
    "Focus: " + (.focus // "unknown") + "\n" +
    "Tags: " + ((.tags // []) | join(", ")) + "\n" +
    ((.bullets // []) | map("- " + .) | join("\n"))
  ' "$STATE_DIR/summary.json" 2>/dev/null || echo '(no session summary available)')"
fi

SYS="$(cat "$SCP_SKILL_DIR/reference/review-prompt.md")"
USER_MSG="## Checklist to evaluate

${CHECKLIST}

## What this session has been doing (running summary)

${SESSION_CONTEXT}

## Untracked new files (names only)

${UNTRACKED:-(none)}

## Uncommitted diff

\`\`\`diff
$(head -c 60000 <<<"$DIFF")
\`\`\`"

MODEL="${SCP_REVIEW_MODEL:-$(scp_config '.review.model' 'gpt-5.5')}"
CRITIQUE="$(scp_llm_chat "$MODEL" "$SYS" "$USER_MSG")" || exit 0
[[ -n "$CRITIQUE" ]] || exit 0

VERDICT="$(head -n 1 <<<"$CRITIQUE")"

if [[ "$MODE" == "block" ]] && grep -qi '^VERDICT:[[:space:]]*FAIL' <<<"$VERDICT"; then
  # Deliberately do NOT persist review.last_sha here: if the agent stops again
  # with the same unfixed diff on a later turn, it must be re-reviewed, not
  # waved through by the dedupe check.
  # Exit 2 + stderr: fed back to Claude, which must address the findings.
  {
    echo "session-context-pipeline review ($MODEL) blocked this stop:"
    echo
    echo "$CRITIQUE"
  } >&2
  exit 2
fi

echo "$DIFF_SHA" >"$STATE_DIR/review.last_sha"

echo "---"
echo "## session-context-pipeline review ($MODEL)"
echo
echo "$CRITIQUE"
exit 0

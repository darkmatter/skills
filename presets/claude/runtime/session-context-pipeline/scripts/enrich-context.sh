#!/usr/bin/env bash
# session-context-pipeline — context enricher (the "watcher subagent").
#
# Wire as a Claude Code UserPromptSubmit hook. Two jobs, both cheap in the
# foreground:
#
#   1. INJECT: any finished enrichment briefs waiting in
#      <state>/enrich/pending/*.md are printed to stdout (UserPromptSubmit
#      stdout is added to the model's context) and moved to enrich/injected/.
#
#   2. TRIGGER: read <state>/summary.json (written by summarize-session.sh)
#      and fire background enrich-worker.sh jobs:
#        - built-in library trigger: every library the summarizer detected is
#          resolved → shallow-cloned → documented, once per session
#        - declarative custom triggers from config (.triggers[]): match on
#          tags / library name patterns, ship a note + docs link + repo
#          excerpts. Purely data-driven — no shell execution.
#        - command triggers (.triggers[].run) exist but are OFF unless config
#          sets .enrich.allow_command_triggers = true. See SKILL.md.
#
# Slow work always happens in detached workers; this hook only reads files,
# writes markers, and spawns.

set -euo pipefail

# Recursion guard: headless agent runs spawned by this pipeline inherit
# SCP_DISABLE=1 and must not re-enter the pipeline via their own hooks.
if [[ -n "${SCP_DISABLE:-}" ]]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scp-lib.sh
. "$SCRIPT_DIR/scp-lib.sh"

INPUT="$(cat)"
SESSION_ID="$(jq -r '.session_id // empty' <<<"$INPUT")"
[[ -n "$SESSION_ID" ]] || exit 0

[[ "$(scp_config '.enrich.enabled' true)" == "true" ]] || exit 0

STATE_DIR="$(scp_state_dir "$SESSION_ID")"
PENDING="$STATE_DIR/enrich/pending"
INJECTED="$STATE_DIR/enrich/injected"
DONE="$STATE_DIR/enrich/done"
mkdir -p "$PENDING" "$INJECTED" "$DONE"
LOG="$STATE_DIR/enrich.log"

# ------------------------------------------------- 1. inject finished briefs
MAX_INJECT="$(scp_config '.enrich.max_pending_inject' 3)"
emitted=0
count=0
for f in "$PENDING"/*.md; do
  [[ -e "$f" ]] || break
  (( count < MAX_INJECT )) || break
  if (( emitted == 0 )); then
    echo "<session-context-pipeline>"
    echo "Background enrichment based on the running session summary. Prefer these"
    echo "sources (and the local clones they point at) over guessing about APIs."
    echo
    emitted=1
  fi
  cat "$f"
  echo
  mv "$f" "$INJECTED/$(basename "$f")"
  count=$((count + 1))
done
(( emitted == 1 )) && echo "</session-context-pipeline>"

# ------------------------------------------------- 2. fire triggers
SUMMARY="$STATE_DIR/summary.json"
[[ -r "$SUMMARY" ]] || exit 0

# Built-in: one enrichment per detected library, once per session.
if [[ "$(scp_config '.enrich.libraries' true)" == "true" ]]; then
  while IFS= read -r lib; do
    [[ -n "$lib" ]] || continue
    name="$(jq -r '.name // empty' <<<"$lib")"
    [[ -n "$name" ]] || continue
    slug="$(scp_slug "$name")"
    scp_enrich_claim "$STATE_DIR" "lib-$slug" || continue
    scp_spawn "$LOG" "$SCRIPT_DIR/enrich-worker.sh" "$STATE_DIR" \
      "$(jq -c '{kind: "library"} + .' <<<"$lib")"
  done < <(jq -c '.libraries[]?' "$SUMMARY" 2>/dev/null || true)
fi

# Declarative custom triggers.
ALLOW_CMD="$(scp_config '.enrich.allow_command_triggers' false)"
HAVE_TAGS="$(jq -c '.tags // []' "$SUMMARY" 2>/dev/null || echo '[]')"
HAVE_LIBS="$(jq -c '[.libraries[]?.name] // []' "$SUMMARY" 2>/dev/null || echo '[]')"

while IFS= read -r trig; do
  [[ -n "$trig" ]] || continue
  tname="$(jq -r '.name // empty' <<<"$trig")"
  [[ -n "$tname" ]] || continue
  key="trig-$(scp_slug "$tname")"
  [[ -e "$DONE/$key" ]] && continue

  # Match: any summary tag in .match_tags (case-insensitive), or any detected
  # library name matching a glob in .library_patterns.
  hit="$(jq -nr \
    --argjson trig "$trig" \
    --argjson tags "$HAVE_TAGS" \
    --argjson libs "$HAVE_LIBS" '
    def lc: ascii_downcase;
    def glob_to_re: lc | gsub("[.^$+()\\[\\]{}|\\\\]"; "\\\(.)") | gsub("\\*"; ".*") | gsub("\\?"; ".");
    (($trig.match_tags // []) | map(lc)) as $want
    | (($tags // []) | map(lc)) as $have
    | (($trig.library_patterns // []) | map(glob_to_re)) as $pats
    | (($libs // []) | map(lc)) as $names
    | (any($want[]; . as $w | any($have[]; . == $w))
       or any($pats[]; . as $p | any($names[]; test("^" + $p + "$"))))
    | tostring')"
  [[ "$hit" == "true" ]] || continue

  scp_enrich_claim "$STATE_DIR" "$key" || continue

  run_cmd="$(jq -r '.run // empty' <<<"$trig")"
  if [[ -n "$run_cmd" ]]; then
    # Command triggers are double-gated: the config flag AND a per-user env
    # opt-in. A checked-in project config alone must never be able to make a
    # hook execute arbitrary shell.
    if [[ "$ALLOW_CMD" == "true" && "${SCP_ALLOW_COMMAND_TRIGGERS:-}" == "1" ]]; then
      SUMMARY_FILE="$SUMMARY" PENDING_DIR="$PENDING" STATE_DIR="$STATE_DIR" \
        scp_spawn "$LOG" bash -c "$run_cmd"
      # Fire-and-forget: no worker to report success, mark done at spawn.
      scp_enrich_finish "$STATE_DIR" "$key" 0
    else
      echo "$(date -u '+%FT%TZ') trigger '$tname' has .run but command triggers are not double-enabled (.enrich.allow_command_triggers + SCP_ALLOW_COMMAND_TRIGGERS=1) — skipped" >>"$LOG"
      # Release the claim without marking done so enabling the gates later
      # (new shell env) lets the trigger fire.
      scp_enrich_finish "$STATE_DIR" "$key" 1
    fi
    continue
  fi

  scp_spawn "$LOG" "$SCRIPT_DIR/enrich-worker.sh" "$STATE_DIR" \
    "$(jq -c '{kind: "trigger"} + .' <<<"$trig")"
done < <(scp_config_json '.triggers' '[]' | jq -c '.[]?' 2>/dev/null || true)

exit 0

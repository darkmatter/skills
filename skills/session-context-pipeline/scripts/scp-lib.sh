# shellcheck shell=bash
# session-context-pipeline — shared helpers, sourced by every script in this
# skill. Not executable on its own.
#
# Env overrides (all optional):
#   SCP_STATE_ROOT     state root      (default: ${TMPDIR:-/tmp}/session-context-pipeline)
#   SCP_CACHE_ROOT     clone cache     (default: ~/.cache/session-context-pipeline)
#   SCP_CONFIG         explicit config path — wins over project and user config
#   LITELLM_BASE_URL   model gateway   (default: https://litellm.drkmttr.dev/v1)
#   LITELLM_API_KEY    gateway key     (fallback: ~/.config/litellm/key)
#
# Config resolution order (first readable wins):
#   $SCP_CONFIG
#   $CLAUDE_PROJECT_DIR/.claude/session-context-pipeline.json
#   $PWD/.claude/session-context-pipeline.json
#   ~/.config/session-context-pipeline/config.json
#   built-in defaults (the literal defaults passed at each call site)

# Used by the scripts that source this lib (summarize-session, enrich-worker).
# shellcheck disable=SC2034
SCP_SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scp_state_root() { printf '%s' "${SCP_STATE_ROOT:-${TMPDIR:-/tmp}/session-context-pipeline}"; }

# scp_state_dir <session_id> — per-session scratch dir, created on demand.
scp_state_dir() {
  local dir
  dir="$(scp_state_root)/$1"
  mkdir -p "$dir"
  printf '%s' "$dir"
}

scp_config_path() {
  local c
  for c in \
    "${SCP_CONFIG:-}" \
    "${CLAUDE_PROJECT_DIR:-}/.claude/session-context-pipeline.json" \
    "$PWD/.claude/session-context-pipeline.json" \
    "$HOME/.config/session-context-pipeline/config.json"; do
    if [[ -n "$c" && -r "$c" ]]; then
      printf '%s' "$c"
      return 0
    fi
  done
  printf ''
}

# scp_config <jq filter> <default> — scalar config lookup with default.
# NB: deliberately not `// empty` — jq's alternative operator treats false as
# absent, which would make any `"flag": false` read back as the default. Only
# null/missing falls through to the default here.
scp_config() {
  local path val
  path="$(scp_config_path)"
  val="__SCP_ABSENT__"
  if [[ -n "$path" ]]; then
    val="$(jq -r "($1) | if . == null then \"__SCP_ABSENT__\" else tostring end" "$path" 2>/dev/null || printf '__SCP_ABSENT__')"
  fi
  if [[ "$val" != "__SCP_ABSENT__" && -n "$val" ]]; then printf '%s' "$val"; else printf '%s' "$2"; fi
}

# scp_config_json <jq filter> <default-json> — compact JSON config lookup.
scp_config_json() {
  local path val
  path="$(scp_config_path)"
  val=""
  if [[ -n "$path" ]]; then
    val="$(jq -c "($1) // empty" "$path" 2>/dev/null || true)"
  fi
  if [[ -n "$val" ]]; then printf '%s' "$val"; else printf '%s' "$2"; fi
}

# scp_slug <string> — filesystem-safe lowercase slug.
scp_slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

scp_litellm_key() {
  if [[ -n "${LITELLM_API_KEY:-}" ]]; then
    printf '%s' "$LITELLM_API_KEY"
    return 0
  fi
  if [[ -r "$HOME/.config/litellm/key" ]]; then
    cat "$HOME/.config/litellm/key"
    return 0
  fi
  return 1
}

# scp_llm_chat <model> <system-prompt> <user-msg> — prints assistant content.
# Returns nonzero (and prints nothing) when the gateway is unreachable, the
# key is missing, or the response has no content. Callers fail open.
scp_llm_chat() {
  local model="$1" sys="$2" user="$3"
  local base="${LITELLM_BASE_URL:-https://litellm.drkmttr.dev/v1}"
  local key body resp
  key="$(scp_litellm_key)" || return 1
  body="$(jq -n --arg model "$model" --arg sys "$sys" --arg user "$user" \
    '{model:$model, temperature:0.1, messages:[{role:"system",content:$sys},{role:"user",content:$user}]}')"
  resp="$(curl -sS --max-time 120 -X POST "$base/chat/completions" \
    -H "Authorization: Bearer $key" \
    -H 'Content-Type: application/json' \
    --data-binary "$body")" || return 1
  jq -er '.choices[0].message.content // empty' <<<"$resp" 2>/dev/null
}

# scp_extract_json — stdin: model output. stdout: the JSON payload, tolerant
# of ```json fences. Fails when nothing parseable is found.
scp_extract_json() {
  local raw fenced
  raw="$(cat)"
  if jq -e . >/dev/null 2>&1 <<<"$raw"; then
    printf '%s' "$raw"
    return 0
  fi
  fenced="$(printf '%s\n' "$raw" | awk '/^```/{f=!f; next} f')"
  if [[ -n "$fenced" ]] && jq -e . >/dev/null 2>&1 <<<"$fenced"; then
    printf '%s' "$fenced"
    return 0
  fi
  return 1
}

# scp_transcript_tail <transcript.jsonl> <max-lines> <max-chars>
# Renders the most recent slice of a Claude Code transcript as readable text:
# role-prefixed message text plus compact tool-call markers. Tolerates lines
# that aren't JSON and content shapes it doesn't know (fromjson? + fallbacks).
scp_transcript_tail() {
  local transcript="$1" max_lines="$2" max_chars="$3"
  tail -n "$max_lines" "$transcript" 2>/dev/null | jq -Rr '
    fromjson? |
    select(.type == "user" or .type == "assistant") |
    .message as $m |
    (if ($m.content | type) == "string" then [$m.content]
     elif ($m.content | type) == "array" then
       [$m.content[]? |
         if .type == "text" then .text
         elif .type == "tool_use" then "[tool:" + (.name // "?") + "] " + ((.input // {} | tojson)[0:200])
         elif .type == "tool_result" then "[tool_result] " + ((.content | tostring)[0:200])
         else empty
         end]
     else []
     end) as $parts |
    select(($parts | length) > 0) |
    (($m.role // .type) + ": " + ($parts | join("\n")))
  ' 2>/dev/null | tail -c "$max_chars"
}

# scp_timeout <seconds> <cmd...> — run cmd with a kill-after watchdog.
# Portable (macOS has no `timeout` binary by default).
scp_timeout() {
  local secs="$1"
  shift
  "$@" &
  local pid=$!
  # The watchdog must not inherit the caller's stdout/stderr: inside a
  # command substitution it would hold the pipe open until the sleep ends,
  # stalling the caller long after the command finished.
  (
    sleep "$secs"
    kill -TERM "$pid" 2>/dev/null
  ) >/dev/null 2>&1 &
  local watcher=$!
  local rc=0
  wait "$pid" 2>/dev/null || rc=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null || true
  return "$rc"
}

# scp_spawn <logfile> <cmd...> — detach a background worker from the hook
# process so the hook can exit immediately. stdin closed, output appended to
# the log. The hook's own stdout stays clean.
scp_spawn() {
  local log="$1"
  shift
  nohup "$@" </dev/null >>"$log" 2>&1 &
}

# scp_enrich_claim <state_dir> <key> — try to claim a unit of background
# enrichment work. Succeeds (creating an inflight lock) unless the key is
# already marked done or a fresh inflight lock exists. Stale locks (>15 min,
# i.e. a worker that died without cleaning up) are stolen so the work can
# retry instead of being suppressed for the rest of the session.
scp_enrich_claim() {
  local state="$1" key="$2"
  local lock="$state/enrich/inflight/$key"
  [[ -e "$state/enrich/done/$key" ]] && return 1
  mkdir -p "$state/enrich/inflight" "$state/enrich/done"
  # mkdir is the atomic claim primitive — two concurrent hooks can't both win.
  if ! mkdir "$lock" 2>/dev/null; then
    # Steal only stale locks (>15 min: a worker that died without cleanup).
    if [[ -n "$(find "$lock" -maxdepth 0 -mmin +15 2>/dev/null)" ]]; then
      rm -rf "$lock"
      mkdir "$lock" 2>/dev/null || return 1
    else
      return 1
    fi
  fi
  return 0
}

# scp_enrich_finish <state_dir> <key> <rc> — worker epilogue: drop the
# inflight lock; mark done only on success (rc 0) so failures retry later.
scp_enrich_finish() {
  local state="$1" key="$2" rc="$3"
  rm -rf "$state/enrich/inflight/$key"
  if [[ "$rc" == "0" ]]; then
    mkdir -p "$state/enrich/done"
    : >"$state/enrich/done/$key"
  fi
}

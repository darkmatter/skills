#!/usr/bin/env bash
# session-context-pipeline — background enrichment worker.
#
# Invoked (detached) by enrich-context.sh. Never runs in a hook's foreground.
#
#   enrich-worker.sh <state_dir> '<payload-json>'
#
# Payloads:
#   {"kind":"library","name":"react-query","ecosystem":"npm","repo":null,...}
#     → resolve the source repo (npm/pypi/crates/go/github), shallow-clone it
#       into the shared cache, and write a docs brief.
#   {"kind":"trigger","name":"...","note":"...","docs_url":"...",
#    "repo_url":"...","excerpt_paths":["README.md"]}
#     → declarative brief: note + links + optional repo clone + file excerpts.
#
# Output: <state>/enrich/pending/<slug>.md (atomic write). enrich-context.sh
# injects it on the next user prompt.
#
# Brief content, in both modes, always includes the local clone path when a
# clone exists — the point is that the main agent reads real sources instead
# of guessing APIs.

set -euo pipefail

# Recursion guard: headless agent runs spawned by this pipeline inherit
# SCP_DISABLE=1 and must not re-enter the pipeline via their own hooks.
if [[ -n "${SCP_DISABLE:-}" ]]; then exit 0; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scp-lib.sh
. "$SCRIPT_DIR/scp-lib.sh"

STATE_DIR="$1"
PAYLOAD="$2"

PENDING="$STATE_DIR/enrich/pending"
mkdir -p "$PENDING"

KIND="$(jq -r '.kind // "library"' <<<"$PAYLOAD")"
NAME="$(jq -r '.name // empty' <<<"$PAYLOAD")"
[[ -n "$NAME" ]] || exit 0
SLUG="$(scp_slug "$NAME")"

CACHE_ROOT="${SCP_CACHE_ROOT:-$HOME/.cache/session-context-pipeline}"
REPOS="$CACHE_ROOT/repos"
mkdir -p "$REPOS"

# --------------------------------------------------------------- helpers ----

# normalize_repo_url <url> — git+https/ssh/shorthand → clonable https URL.
normalize_repo_url() {
  local url="$1"
  url="${url#git+}"
  case "$url" in
    git@*:*) url="https://${url#git@}"; url="${url/://}" ;;
    ssh://git@*) url="https://${url#ssh://git@}" ;;
  esac
  printf '%s' "$url"
}

# resolve_repo_url <name> <ecosystem> — best-effort canonical source repo.
resolve_repo_url() {
  local name="$1" eco="$2" url=""
  case "$eco" in
    npm)
      url="$(curl -sS --max-time 20 "https://registry.npmjs.org/$name" 2>/dev/null |
        jq -r '.repository.url // empty' 2>/dev/null || true)"
      ;;
    pypi)
      url="$(curl -sS --max-time 20 "https://pypi.org/pypi/$name/json" 2>/dev/null |
        jq -r '(.info.project_urls // {} | to_entries | map(select(.key | test("source|repo|github"; "i"))) | .[0].value) // .info.home_page // empty' 2>/dev/null || true)"
      ;;
    crates)
      url="$(curl -sS --max-time 20 "https://crates.io/api/v1/crates/$name" 2>/dev/null |
        jq -r '.crate.repository // empty' 2>/dev/null || true)"
      ;;
    go)
      # Go module paths are host/path; most are directly clonable.
      case "$name" in
        github.com/*|gitlab.com/*|bitbucket.org/*) url="https://$name" ;;
      esac
      ;;
    github)
      url="https://github.com/$name"
      ;;
  esac
  [[ -n "$url" ]] && normalize_repo_url "$url"
}

# clone_repo <url> <slug> — shallow clone into cache, reuse when present.
# Prints the clone dir on success.
clone_repo() {
  local url="$1" slug="$2"
  local dir="$REPOS/$slug"
  if [[ -d "$dir/.git" ]]; then
    printf '%s' "$dir"
    return 0
  fi
  rm -rf "$dir"
  if scp_timeout 120 git clone --quiet --depth 1 --single-branch "$url" "$dir" 2>/dev/null; then
    printf '%s' "$dir"
    return 0
  fi
  rm -rf "$dir"
  return 1
}

# emit_excerpts <clone_dir> <paths-json-array> <max-lines-each>
emit_excerpts() {
  local dir="$1" paths="$2" maxl="$3" p
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    # Refuse traversal outside the clone.
    case "$p" in
      /*|*..*) continue ;;
    esac
    [[ -r "$dir/$p" ]] || continue
    echo
    echo "### Excerpt: \`$p\`"
    echo '```'
    head -n "$maxl" "$dir/$p"
    echo '```'
  done < <(jq -r '.[]?' <<<"$paths" 2>/dev/null || true)
}

# agent_brief <clone_dir> <name> — optional headless-agent pass over the clone.
# Requires a `claude` binary and .enrich.use_agent (default true). Fails open.
agent_brief() {
  local dir="$1" name="$2"
  [[ "$(scp_config '.enrich.use_agent' true)" == "true" ]] || return 1
  command -v claude >/dev/null 2>&1 || return 1
  local tags model prompt template
  tags="$(jq -r '(.tags // []) | join(", ")' "$STATE_DIR/summary.json" 2>/dev/null || echo '')"
  model="$(scp_config '.enrich.agent_model' 'haiku')"
  template="$(cat "$SCP_SKILL_DIR/reference/enricher-prompt.md")"
  prompt="${template//\{\{LIBRARY\}\}/$name}"
  prompt="${prompt//\{\{TAGS\}\}/$tags}"
  # SCP_DISABLE=1 keeps the headless run's own hooks from re-entering this
  # pipeline (hooks inherit the environment).
  (cd "$dir" && scp_timeout 180 env SCP_DISABLE=1 claude -p "$prompt" --model "$model" 2>/dev/null) | head -c 12000
}

# fallback_brief <clone_dir> — no-agent docs digest: README head + docs map.
fallback_brief() {
  local dir="$1" readme=""
  local f
  for f in README.md README.rst README.markdown readme.md README; do
    if [[ -r "$dir/$f" ]]; then
      readme="$f"
      break
    fi
  done
  if [[ -n "$readme" ]]; then
    echo "### \`$readme\` (first 80 lines)"
    echo '```markdown'
    head -n 80 "$dir/$readme"
    echo '```'
  fi
  local docs
  docs="$(cd "$dir" && find docs doc website/docs -type f \( -name '*.md' -o -name '*.mdx' \) 2>/dev/null | head -n 25 || true)"
  if [[ -n "$docs" ]]; then
    echo
    echo "### Docs files in the clone"
    echo '```'
    echo "$docs"
    echo '```'
  fi
}

# ------------------------------------------------------------------ main ----

# Claim key created by enrich-context.sh; success is only recorded once the
# brief lands in pending/, so a worker that dies here gets retried after the
# inflight lock goes stale.
KEY="trig-$SLUG"
[[ "$KIND" == "library" ]] && KEY="lib-$SLUG"
FINISH_RC=1

OUT="$(mktemp "${TMPDIR:-/tmp}/scp-brief.XXXXXX")"
# shellcheck disable=SC2329  # invoked via trap
cleanup() {
  rm -f "$OUT" 2>/dev/null || true
  scp_enrich_finish "$STATE_DIR" "$KEY" "$FINISH_RC"
}
trap cleanup EXIT

CLONE_DIR=""
REPO_URL="$(jq -r '.repo // .repo_url // empty' <<<"$PAYLOAD")"
[[ -n "$REPO_URL" ]] && REPO_URL="$(normalize_repo_url "$REPO_URL")"

if [[ "$KIND" == "library" ]]; then
  ECO="$(jq -r '.ecosystem // "unknown"' <<<"$PAYLOAD")"
  if [[ -z "$REPO_URL" ]]; then
    REPO_URL="$(resolve_repo_url "$NAME" "$ECO" || true)"
  fi

  {
    echo "## Library context: $NAME"
    echo
    if [[ -n "$REPO_URL" ]]; then
      echo "- Source repo: $REPO_URL"
    else
      echo "- Source repo: unresolved (ecosystem: $ECO)"
    fi
  } >"$OUT"

  if [[ -n "$REPO_URL" && "$(scp_config '.enrich.clone' true)" == "true" ]]; then
    if CLONE_DIR="$(clone_repo "$REPO_URL" "$SLUG")"; then
      echo "- Local clone: \`$CLONE_DIR\` — read the real sources there; do not guess APIs." >>"$OUT"
    else
      echo "- Local clone: failed (network or auth) — rely on the repo link above." >>"$OUT"
      CLONE_DIR=""
    fi
  fi

  if [[ -n "$CLONE_DIR" ]]; then
    echo >>"$OUT"
    if BRIEF="$(agent_brief "$CLONE_DIR" "$NAME")" && [[ -n "$BRIEF" ]]; then
      printf '%s\n' "$BRIEF" >>"$OUT"
    else
      fallback_brief "$CLONE_DIR" >>"$OUT"
    fi
  fi
else
  # Declarative trigger brief.
  NOTE="$(jq -r '.note // empty' <<<"$PAYLOAD")"
  DOCS_URL="$(jq -r '.docs_url // empty' <<<"$PAYLOAD")"

  {
    echo "## Context: $NAME"
    echo
    [[ -n "$NOTE" ]] && { echo "$NOTE"; echo; }
    [[ -n "$DOCS_URL" ]] && echo "- Docs: $DOCS_URL"
    [[ -n "$REPO_URL" ]] && echo "- Repo: $REPO_URL"
  } >"$OUT"

  if [[ -n "$REPO_URL" && "$(scp_config '.enrich.clone' true)" == "true" ]]; then
    if CLONE_DIR="$(clone_repo "$REPO_URL" "$SLUG")"; then
      echo "- Local clone: \`$CLONE_DIR\`" >>"$OUT"
      emit_excerpts "$CLONE_DIR" "$(jq -c '.excerpt_paths // []' <<<"$PAYLOAD")" \
        "$(scp_config '.enrich.excerpt_max_lines' 60)" >>"$OUT"
    fi
  fi
fi

# Atomic hand-off to the injection path.
mv "$OUT" "$PENDING/$SLUG.md"
FINISH_RC=0
exit 0

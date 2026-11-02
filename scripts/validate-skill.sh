#!/usr/bin/env bash
# Validate skills/ (the team-wide catalog) and its authored index.
#
# Usage:
#   scripts/validate-skill.sh                 # all skills/, links, and catalog parity
#   scripts/validate-skill.sh skills/foo ...  # only the named skill directories
#
# Every invocation checks, for each validated skill:
#   - SKILL.md exists at the skill root
#   - SKILL.md has a YAML frontmatter block with `name` and `description`
#   - the frontmatter block is properly closed (second ---)
#   - frontmatter keys are well-formed (no markdown headings like ## name:)
#   - the directory name matches `name:` in frontmatter (mismatch is a failure)
#   - every relative link in the skill's Markdown resolves on disk
#
# The default invocation additionally checks:
#   - docs/catalog.md has a `## Local skills` section with exactly one
#     backticked row per top-level directory in skills/, and no stale rows
#     (see scripts/validate_catalog.py)
#   - relative links in docs/catalog.md resolve
#
# Link contract (lychee --offline):
#   - links are resolved relative to the containing Markdown file
#   - inline and reference-style links are both checked
#   - fenced code blocks, external URL schemes, and pure fragments are ignored
#   - URL fragments are stripped before checking the target
#   - vendored trees declared in .gitmodules are excluded from the scan
#   - no network requests are made
#
# Explicit skill-directory arguments validate only those directories; they do
# not require catalog membership, so fixtures and vendored/out-of-tree skills
# can be checked. A missing sibling or reference target is always a failure.
#
# Dependencies: lychee (link checks), python3 (catalog parity), POSIX tools.
# Dependency-complete run:
#   nix build .#checks.x86_64-linux.skills
# Focused runs (lychee must be on PATH; bare mode also needs python3):
#   nix shell --inputs-from . nixpkgs#lychee -c \
#     scripts/validate-skill.sh skills/<name>
#   nix shell --inputs-from . nixpkgs#lychee nixpkgs#python3 -c \
#     scripts/validate-skill.sh
# A missing lychee is a failure, never a silent skip.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_skill() {
  local dir="$1"
  local rel="${dir#"$REPO_ROOT"/}"

  if [[ ! -f "$dir/SKILL.md" ]]; then
    echo "FAIL $rel: missing SKILL.md"
    fail=$((fail + 1))
    return
  fi

  # Count frontmatter delimiters (lines that are exactly "---").
  local delim_count
  delim_count="$(grep -cx -e '---' "$dir/SKILL.md" 2>/dev/null || true)"
  delim_count="${delim_count:-0}"

  if [[ "$delim_count" -lt 2 ]]; then
    echo "FAIL $rel: SKILL.md frontmatter is unclosed (missing closing ---)"
    fail=$((fail + 1))
    return
  fi

  # Read first frontmatter block (between first and second ---).
  local fm
  fm="$(awk '/^---$/{c++; next} c==1' "$dir/SKILL.md" 2>/dev/null || true)"

  if [[ -z "$fm" ]]; then
    echo "FAIL $rel: SKILL.md missing YAML frontmatter"
    fail=$((fail + 1))
    return
  fi

  # Check for malformed keys (markdown headings like ## name: instead of name:).
  if echo "$fm" | grep -qE '^#+[[:space:]]*(name|description):'; then
    echo "FAIL $rel: SKILL.md frontmatter has markdown heading instead of YAML key (## name: or ## description:)"
    fail=$((fail + 1))
    return
  fi

  local name desc
  name="$(printf '%s\n' "$fm" | awk '/^name:/ {sub(/^name:[[:space:]]*/, ""); gsub(/^"|"$/, ""); print; exit}')"
  desc="$(printf '%s\n' "$fm" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}')"

  if [[ -z "$name" ]]; then
    echo "FAIL $rel: SKILL.md frontmatter has no name"
    fail=$((fail + 1))
  fi
  if [[ -z "$desc" ]]; then
    echo "FAIL $rel: SKILL.md frontmatter has no description"
    fail=$((fail + 1))
  fi
  if [[ -n "$name" && "$(basename "$dir")" != "$name" ]]; then
    echo "FAIL $rel: directory name does not match frontmatter name ($name)"
    fail=$((fail + 1))
  fi

  echo "ok   $rel"
}

# Absolute paths of vendored trees declared in .gitmodules. Their Markdown is
# upstream content, not owned by this catalog, so it is never link-checked.
submodule_paths=()
if [[ -f "$REPO_ROOT/.gitmodules" ]]; then
  while IFS= read -r submodule_path; do
    if [[ -n "$submodule_path" ]]; then
      submodule_paths+=("$REPO_ROOT/$submodule_path")
    fi
  done < <(
    awk -F '=' '
      /^[[:space:]]*path[[:space:]]*=/ {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
      }
    ' "$REPO_ROOT/.gitmodules"
  )
fi

is_vendored() {
  local file="$1"
  local submodule_path
  if [[ ${#submodule_paths[@]} -eq 0 ]]; then
    return 1
  fi
  for submodule_path in "${submodule_paths[@]}"; do
    if [[ "$file" == "$submodule_path"/* ]]; then
      return 0
    fi
  done
  return 1
}

markdown_files=()
collect_markdown() {
  local root="$1"
  local file
  [[ -d "$root" ]] || return 0
  while IFS= read -r -d '' file; do
    if is_vendored "$file"; then
      continue
    fi
    markdown_files+=("$file")
  done < <(find "$root" -type f -name '*.md' -print0)
}

check_links() {
  if ! command -v lychee >/dev/null 2>&1; then
    echo "FAIL links: lychee not found on PATH (use nix build .#checks.x86_64-linux.skills, or nix shell --inputs-from . nixpkgs#lychee -c $0 ...)"
    fail=$((fail + 1))
    return
  fi
  if [[ ${#markdown_files[@]} -eq 0 ]]; then
    echo "FAIL links: no Markdown files found to check"
    fail=$((fail + 1))
    return
  fi

  if lychee --offline --include-fragments=none --no-progress -- "${markdown_files[@]}"; then
    echo "ok   links (${#markdown_files[@]} files)"
  else
    echo "FAIL links: broken relative links (see lychee output above)"
    fail=$((fail + 1))
  fi
}

if [[ $# -gt 0 ]]; then
  for d in "$@"; do
    dir="$(cd "$d" && pwd)"
    check_skill "$dir"
    collect_markdown "$dir"
  done
else
  if [[ ! -d "$REPO_ROOT/skills" ]]; then
    echo "no skills/ directory at $REPO_ROOT — nothing to validate"
    exit 0
  fi
  while IFS= read -r -d '' d; do
    check_skill "$d"
  done < <(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d -print0)

  collect_markdown "$REPO_ROOT/skills"
  if [[ -f "$REPO_ROOT/docs/catalog.md" ]]; then
    markdown_files+=("$REPO_ROOT/docs/catalog.md")
  fi

  # The catalog is the authored index; skills/ is the source of truth.
  if ! python3 "$REPO_ROOT/scripts/validate_catalog.py" "$REPO_ROOT"; then
    fail=$((fail + 1))
  fi
fi

check_links

if [[ $fail -gt 0 ]]; then
  echo
  echo "$fail check(s) failed"
  exit 1
fi

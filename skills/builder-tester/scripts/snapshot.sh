#!/bin/sh
# Record the state of a git working tree, so a Builder can show that a Tester
# agent changed nothing in the repository during a test round.
#
# Usage: sh snapshot.sh   (from anywhere inside the repository)
#
# Prints a new directory that holds one file, `state`. Take a snapshot before
# and after a round, then compare: diff <before>/state <after>/state
#
# Each line of `state` is one of:
#   tree <hash> <repo>     Every tracked file and every untracked file that is
#                          not ignored, in the top repository (".") or in one
#                          checked-out submodule (its path), recursively.
#   ignored <hash> <path>  One ignored file, such as .env, that is not inside
#                          an ignored directory.
#
# The real index of each repository is never touched. Tree objects are
# written to each repository's object store so changed files can be restored
# with `git -C <repo> restore --source=<hash> -- <path>`. Ignored files are
# only hashed (git hash-object without -w), so ignored secrets never enter
# Git. Files inside ignored directories (dependencies, build output, caches)
# are not covered.
set -eu

out="$(mktemp -d)"
: > "$out/state"

# Record the repository in the current directory under the label $1.
snap_repo() {
  label="$1"
  index="$out/index"
  rm -f "$index"
  # Start from the tracked file list without saved timestamps, so `git add -A`
  # re-reads every file. A copied index would let git trust its timestamps and
  # miss a same-size edit made within the same second.
  git ls-files -s -z | GIT_INDEX_FILE="$index" git update-index -z --index-info
  GIT_INDEX_FILE="$index" git add -A
  tree="$(GIT_INDEX_FILE="$index" git write-tree)"
  rm -f "$index"
  printf 'tree %s %s\n' "$tree" "$label" >> "$out/state"
  # shellcheck disable=SC2016 # the inner sh expands $f and $0, not this one
  git ls-files -z --others --ignored --exclude-standard --directory |
    xargs -0 sh -c 'for f; do [ -d "$f" ] ||
      printf "ignored %s %s/%s\n" "$(git hash-object --no-filters -- "$f")" "$0" "$f"; done' "$label" \
    >> "$out/state"
}

cd "$(git rev-parse --show-toplevel)"
snap_repo .
# The top tree records only each submodule's checked-out commit, not edits
# inside it, so each submodule gets its own entry.
# shellcheck disable=SC2016 # git submodule foreach sets and expands $displaypath
git submodule foreach --quiet --recursive 'printf "%s\n" "$displaypath"' |
  while IFS= read -r sub; do
    (cd "$sub" && snap_repo "$sub")
  done
echo "$out"

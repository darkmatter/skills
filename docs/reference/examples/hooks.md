# Reference example — hooks

This shows hook entrypoints that can be called by different agent runtimes, git hooks, or CI. Keep the scripts provider-agnostic.

Recommended template structure:

```text
hooks/
  hooks.yaml
  scripts/
    session-start.sh
    validate-policy.sh
    diff-review.sh
    pre-commit.sh
```

Example `hooks/hooks.yaml`:

```yaml
hooks:
  on_session_start:
    - script: hooks/scripts/session-start.sh
      description: Print required context and stale-review warnings
      timeout: 10
      fail_open: true

  on_stop:
    - script: hooks/scripts/diff-review.sh
      description: Review non-trivial uncommitted diffs
      timeout: 120
      fail_open: true

  pre_commit:
    - script: hooks/scripts/pre-commit.sh
      description: Run policy, secret, and configured checks
      timeout: 300
      fail_open: false
```

Example `hooks/scripts/session-start.sh`:

```sh
#!/usr/bin/env sh
set -eu

printf '%s\n' 'Agent session context:'
printf '%s\n' '1. Read AGENTS.md'
printf '%s\n' '2. Read .agent/context/overview.md'
printf '%s\n' '3. Read .agent/context/decisions.md'
printf '%s\n' '4. Read RULES.md'
printf '%s\n' '5. Read .agent/policy/engineering-practices.md'

if [ -f .agent/context/decisions.md ]; then
  grep -n 'review_by:' .agent/context/decisions.md || true
fi
```

Example `hooks/scripts/validate-policy.sh`:

```sh
#!/usr/bin/env sh
set -eu

required='AGENTS.md RULES.md DUTIES.md SOUL.md agent.yaml .agent/README.md .agent/context/overview.md .agent/context/decisions.md .agent/policy/engineering-practices.md .agent/policy/project-exceptions.md .agent/workflows/feature-development.md .agent/checklists/completion.md'

fail=0
for path in $required; do
  if [ ! -e "$path" ]; then
    echo "missing required agent policy file: $path" >&2
    fail=1
  fi
done

if grep -R '{{project}}\|> Add project-specific\|TODO(agent-policy)' .agent RULES.md DUTIES.md agent.yaml 2>/dev/null; then
  echo 'found unfilled template placeholders' >&2
  fail=1
fi

exit "$fail"
```

Example `hooks/scripts/diff-review.sh`:

```sh
#!/usr/bin/env sh
set -eu

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed_lines="$(git diff --numstat | awk '{ add += $1; del += $2 } END { print add + del + 0 }')"

# Skip tiny diffs.
if [ "$changed_lines" -lt 10 ]; then
  exit 0
fi

if [ -x .agent/skills/end-of-turn-review/scripts/review.sh ]; then
  git diff | .agent/skills/end-of-turn-review/scripts/review.sh --kind=diff
elif command -v review-agent >/dev/null 2>&1; then
  git diff | review-agent --kind=diff
else
  echo "diff review skipped: no review script configured" >&2
fi
```

Example `hooks/scripts/pre-commit.sh`:

```sh
#!/usr/bin/env sh
set -eu

hooks/scripts/validate-policy.sh

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --redact
else
  echo 'warning: gitleaks not installed; secret scan skipped' >&2
fi

# Project-specific checks should come from agent.yaml. Keep this example simple.
if [ -f package.json ] && command -v pnpm >/dev/null 2>&1; then
  pnpm lint
  pnpm typecheck
  pnpm test
fi
```

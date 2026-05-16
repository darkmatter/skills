# Reference example — `validate-agent-project.sh`

This is a reference shape for a validator that can live at `scripts/validate-agent-project.sh` in `darkmatter/skills`, and be stamped into downstream projects as `scripts/validate-agent-project.sh`.

```sh
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

fail=0
warn=0

error() {
  echo "FAIL: $*" >&2
  fail=$((fail + 1))
}

warning() {
  echo "WARN: $*" >&2
  warn=$((warn + 1))
}

require_file() {
  [ -f "$1" ] || error "missing required file: $1"
}

require_dir() {
  [ -d "$1" ] || error "missing required directory: $1"
}

require_file AGENTS.md
require_file RULES.md
require_file DUTIES.md
require_file SOUL.md
require_file agent.yaml
require_dir .agent
require_file .agent/README.md
require_file .agent/context/overview.md
require_file .agent/context/decisions.md
require_file .agent/context/conventions.md
require_file .agent/policy/engineering-practices.md
require_file .agent/policy/agent-practices.md
require_file .agent/policy/review-gates.md
require_file .agent/policy/project-exceptions.md
require_file .agent/workflows/feature-development.md
require_file .agent/workflows/bugfix.md
require_file .agent/workflows/refactor.md
require_file .agent/workflows/release.md
require_file .agent/checklists/pr.md
require_file .agent/checklists/completion.md

# Ensure shims point to canonical context.
for shim in AGENTS.md CLAUDE.md .cursorrules; do
  if [ -f "$shim" ] && ! grep -q '.agent/' "$shim"; then
    error "$shim does not point to .agent/"
  fi
done

# Reject obvious unfilled placeholders.
if grep -R '{{project}}\|{{project_description}}\|> Add project-specific' \
  AGENTS.md RULES.md DUTIES.md SOUL.md agent.yaml .agent 2>/dev/null; then
  error "unfilled template placeholders found"
fi

# Parse agent.yaml and require operational sections.
python3 - <<'PY' || error "agent.yaml failed validation"
from pathlib import Path
import sys
try:
    import yaml
except ImportError:
    print('PyYAML not installed; skipping deep yaml validation', file=sys.stderr)
    raise SystemExit(0)

data = yaml.safe_load(Path('agent.yaml').read_text()) or {}
required = ['name', 'description', 'practices', 'checks', 'gates']
missing = [k for k in required if k not in data]
if missing:
    raise SystemExit('missing keys: ' + ', '.join(missing))
checks = data.get('checks') or {}
for check in ['lint', 'typecheck', 'test']:
    if check not in checks:
        raise SystemExit(f'missing checks.{check}')
PY

# Warn on stale review_by dates.
today="$(date +%Y-%m-%d)"
while IFS= read -r line; do
  file="${line%%:*}"
  value="${line##*review_by:}"
  value="$(echo "$value" | tr -d ' "')"
  if [ -n "$value" ] && [ "$value" \< "$today" ]; then
    warning "$file has stale review_by: $value"
  fi
done < <(grep -R 'review_by:' .agent/context .agent/policy 2>/dev/null || true)

# Optional secret scan.
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --redact || error "gitleaks found possible secrets"
else
  warning "gitleaks not installed; secret scan skipped"
fi

if [ "$warn" -gt 0 ]; then
  echo "$warn warning(s)"
fi

if [ "$fail" -gt 0 ]; then
  echo "$fail failure(s)"
  exit 1
fi

echo "agent project validation passed"
```

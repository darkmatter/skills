# Reference example — CI workflows

This shows two CI examples:

1. Validation for the `darkmatter/agents` infrastructure repo.
2. Validation stamped into downstream project repos.

## `darkmatter/agents` repo workflow

Path: `.github/workflows/validate.yml`

```yaml
name: validate

on:
  pull_request:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate skills
        run: scripts/validate-skill.sh

      - name: Validate template has required files
        run: |
          set -eu
          required='template/AGENTS.md template/RULES.md template/DUTIES.md template/SOUL.md template/agent.yaml template/.agent/README.md template/.agent/context/overview.md template/.agent/context/decisions.md'
          for path in $required; do
            test -e "$path" || { echo "missing $path"; exit 1; }
          done

      - name: Check skill catalog coverage
        run: |
          set -eu
          for skill in skills/*/SKILL.md; do
            name="$(basename "$(dirname "$skill")")"
            grep -q "\`$name\`" docs/catalog.md || {
              echo "docs/catalog.md missing skill: $name"
              exit 1
            }
          done

      - name: Enforce manual skill convention
        run: |
          set -eu
          for skill in skills/{run,kickoff,setup,init,do}-*/SKILL.md; do
            [ -e "$skill" ] || continue
            grep -q '^description:.*Manual-invocation skill' "$skill" || {
              echo "manual skill missing Manual-invocation description: $skill"
              exit 1
            }
          done

      - name: Shellcheck scripts
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './scripts ./template/scripts ./template/hooks/scripts'
```

## Downstream project workflow

Path: `template/.github/workflows/agent-policy.yml`

```yaml
name: agent policy

on:
  pull_request:
  push:
    branches: [main]

jobs:
  agent-policy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate agent project files
        run: |
          set -eu
          required='AGENTS.md RULES.md DUTIES.md SOUL.md agent.yaml .agent/README.md .agent/context/overview.md .agent/context/decisions.md .agent/policy/engineering-practices.md .agent/policy/project-exceptions.md .agent/workflows/feature-development.md .agent/checklists/completion.md'
          for path in $required; do
            test -e "$path" || { echo "missing $path"; exit 1; }
          done

      - name: Check for unfilled template placeholders
        run: |
          set -eu
          ! grep -R '{{project}}\|{{project_description}}\|> Add project-specific' AGENTS.md RULES.md DUTIES.md SOUL.md agent.yaml .agent || {
            echo 'unfilled template placeholder found'
            exit 1
          }

      - name: Parse agent.yaml
        run: |
          python3 - <<'PY'
          import pathlib, yaml
          data = yaml.safe_load(pathlib.Path('agent.yaml').read_text())
          for key in ['name', 'description', 'practices', 'checks', 'gates']:
              if key not in data:
                  raise SystemExit(f'missing agent.yaml key: {key}')
          PY

      - name: Secret scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Project checks
        run: |
          set -eu
          if [ -f package.json ] && command -v corepack >/dev/null 2>&1; then
            corepack enable
            pnpm install --frozen-lockfile
            pnpm lint
            pnpm typecheck
            pnpm test
          else
            echo 'No default project check runner configured; customize this workflow.'
          fi
```

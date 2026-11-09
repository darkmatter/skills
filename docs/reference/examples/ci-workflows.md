# Reference example — CI workflows

This shows two CI examples:

1. Validation for the `darkmatter/skills` infrastructure repo.
2. Validation in the `darkmatter/template` repo, stamped into downstream project repos.

## `darkmatter/skills` repo workflow

Path: `.github/workflows/validate-skills.yml`

```yaml
name: Validate skills

on:
  pull_request:
  push:
    branches: [main]

jobs:
  validate-skills:
    runs-on: arc
    steps:
      - uses: actions/checkout@v4
      # No cachix/install-nix-action step: the arc runner image already ships
      # Nix with flakes enabled.
      - name: Validate skills (structure, links, catalog, regressions)
        run: nix build .#checks.x86_64-linux.skills
      - name: Check generated instructions
        run: nix build .#checks.x86_64-linux.agents-md
      - name: Evaluate Home Manager module on the native platform
        run: nix eval --impure --raw --file scripts/check-home-manager.nix
```

Validation covers the skill structure and catalog plus generated instructions.
There is no sandbox copy to drift-check: Centaur consumes `skills/` directly.

## Downstream project workflow

Path: `.github/workflows/agent-policy.yml` in the `darkmatter/template` repo (stamped into downstream project repos).

```yaml
name: agent policy

on:
  pull_request:
  push:
    branches: [main]

jobs:
  agent-policy:
    runs-on: arc
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

      # The arc runner image does not guarantee Python.
      - uses: actions/setup-python@v5
        with:
          python-version: "3.x"

      - run: pip install pyyaml

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

      # arc keeps Node off PATH until setup-node runs; corepack/pnpm below need it.
      - uses: actions/setup-node@v4
        with:
          node-version: 22

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

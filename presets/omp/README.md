# Darkmatter omp preset

Shared [oh-my-pi](https://github.com/can1357/oh-my-pi) (`omp`) configuration for
Darkmatter agents, installed into an omp agent directory (`~/.omp/agent`, or
`$PI_CODING_AGENT_DIR` when set).

## Install

```bash
./scripts/install-omp.sh            # symlink into ~/.omp/agent
./scripts/install-omp.sh --copy     # copy instead (use this in containers)
./scripts/install-omp.sh --target /custom/agent/dir
```

Requires `OPENROUTER_API_KEY` in the environment.

## Contents

| Source | Installed to | Purpose |
|---|---|---|
| `../base/AGENTS.md` | `AGENTS.md` | Shared global agent instructions (user-level context) |
| `RULES.md` | `RULES.md` | Always-apply safety rules (destructive-command policy) |
| `config.yml` | `config.yml` | Settings: model roles, approval mode, behavior — copied, since omp mutates it |
| `models.yml` | `models.yml` | Model/provider config (OpenRouter by default) — copied |
| `../../skills` | `skills/` | Shared skill catalog |

Primarily consumed by the **github-executor** container (darkmatter/platform,
epic `platform-uyt`), which runs omp headlessly to service `/oc` commands.
Model roles default to the latest Claude models via OpenRouter; edit
`config.yml` to change them.

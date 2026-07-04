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

Requires `LITELLM_API_KEY` (darkmatter LiteLLM gateway — the default provider)
and `OPENROUTER_API_KEY` (frontier models for the `slow` role) in the
environment.

## Contents

| Source | Installed to | Purpose |
|---|---|---|
| `../base/AGENTS.md` | `AGENTS.md` | Shared global agent instructions (user-level context) |
| `RULES.md` | `RULES.md` | Always-apply safety rules (destructive-command policy) |
| `config.yml` | `config.yml` | Settings: model roles, approval mode, behavior — copied, since omp mutates it |
| `models.yml` | `models.yml` | Model/provider config (darkmatter LiteLLM gateway + OpenRouter) — copied |
| `../../skills` | `skills/` | Shared skill catalog |

Primarily consumed by the **github-executor** container (darkmatter/platform,
epic `platform-uyt`), which runs omp headlessly to service `/bot` commands.
Model roles default to `glm-5.2-fp8` on the darkmatter LiteLLM gateway (our
dedicated instance); only the `slow` deep-reasoning role uses a frontier model
(Claude via OpenRouter). Edit `config.yml` to change them.

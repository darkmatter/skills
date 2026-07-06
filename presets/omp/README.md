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
Model roles default to the gateway's `glm-local` alias (hosted_vllm
`glm-5.2-fp8` on our dedicated LiteLLM instance); only the `slow` deep-reasoning
role uses a frontier model (Claude via OpenRouter). Edit `config.yml` to change
them. Do not point roles at `glm-5.2-fp8` directly: omp's discovery fuzzy-merges
gateway ids against the live models.dev catalog, and that id collides with the
fireworks-ai `glm-5p2-fp8` entry, which swaps in an upstream wire id the gateway
rejects (see config.yml comment, diagnosed 2026-07-06).

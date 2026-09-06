# base/

Shared cross-client instructions for Darkmatter agents: the layer every LLM
client installs, independent of any client-specific pack in `presets/`.

- `AGENTS.md` — global agent instructions: defaults, hard rules
  (evidence before claims, tests before behavior changes, review, secrets
  handling), authority order, and completion evidence. This is the main
  entrypoint because OpenCode, Codex, omp, and several other tools understand
  it natively.
- `runtime/end-of-turn-review/` — opt-in end-of-turn review hook utility.

## Install

There are three routes; every client pack also installs these files on its own:

1. **home-manager module** — when this repo's `home-manager.nix` is imported,
   the file is installed for OpenCode (`programs.opencode.context`), Codex
   (`~/.codex/AGENTS.md`), omp (`~/.omp/agent/AGENTS.md`), and Claude Code
   (a copy in `~/.claude/darkmatter/`).
2. **`scripts/install-base.sh`** — install just this layer into any directory:
   `./scripts/install-base.sh --target <dir>` (symlinks by default;
   `--copy` for real files).
3. **Per-client sync scripts** — `scripts/sync-omp.sh` and
   `scripts/sync-opencode.sh` install the base files alongside each client's
   own pack.

## Claude Code import

The module never writes `~/.claude/CLAUDE.md` (personal user config). To load
the shared instructions in Claude Code, add this line to your
~/.claude/CLAUDE.md:

```
@~/.claude/darkmatter/AGENTS.md
```

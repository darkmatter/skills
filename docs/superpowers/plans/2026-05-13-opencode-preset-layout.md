# OpenCode Preset Layout Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize this repository into a source catalog for LLM presets with OpenCode as the preferred install target.

**Architecture:** Keep canonical shared assets at the repo level and add `presets/opencode/` as an OpenCode-native source pack. Installation scripts and Home Manager wiring should sync source assets into `~/.config/opencode` without making the repo root itself an OpenCode config directory.

**Tech Stack:** Markdown documentation, POSIX-ish Bash, Nix Home Manager, OpenCode JSONC config conventions, existing `SKILL.md` skill format.

---

## File Structure

Create and update these files. Keep each file focused on one responsibility.

- Create `presets/README.md` to explain preset-pack conventions.
- Create `presets/base/README.md` to describe shared cross-client instructions.
- Create `presets/base/AGENTS.md` as the global cross-client instruction entrypoint for installed presets.
- Create `presets/base/instructions/.gitkeep` so the shared instruction directory exists before content is added.
- Create `presets/opencode/README.md` to explain how the OpenCode preset maps to `~/.config/opencode`.
- Create `presets/opencode/opencode.jsonc` as the minimal OpenCode preset config.
- Create `presets/opencode/tui.json` as the minimal TUI config.
- Create `presets/opencode/package.json` for future local plugin/tool dependencies.
- Create `.gitkeep` files under `presets/opencode/agents/`, `commands/`, `plugins/`, `tools/`, `themes/`, and `modes/`.
- Create `docs/opencode-layout.md` for the directory mapping and conceptual boundaries.
- Modify `README.md` to reposition the repo as an LLM preset catalog with OpenCode preferred.
- Modify `home-manager.nix` to install OpenCode preset files declaratively, if the current Home Manager module has access to `xdg.configFile`.
- Create `scripts/sync-opencode.sh` to safely sync/link the OpenCode preset into a target config directory.
- Create `scripts/install-opencode.sh` as the public install wrapper around the sync script.

Do not modify user-private config, credentials, `.obsidian/`, or existing unrelated worktree changes.

## Task 1: Add Preset Skeleton

**Files:**
- Create: `presets/README.md`
- Create: `presets/base/README.md`
- Create: `presets/base/AGENTS.md`
- Create: `presets/base/instructions/.gitkeep`
- Create: `presets/opencode/README.md`
- Create: `presets/opencode/opencode.jsonc`
- Create: `presets/opencode/tui.json`
- Create: `presets/opencode/package.json`
- Create: `presets/opencode/agents/.gitkeep`
- Create: `presets/opencode/commands/.gitkeep`
- Create: `presets/opencode/plugins/.gitkeep`
- Create: `presets/opencode/tools/.gitkeep`
- Create: `presets/opencode/themes/.gitkeep`
- Create: `presets/opencode/modes/.gitkeep`

- [ ] **Step 1: Create directories**

Run:

```bash
mkdir -p presets/base/instructions presets/opencode/{agents,commands,plugins,tools,themes,modes}
```

Expected: command exits 0 and creates the preset directories.

- [ ] **Step 2: Add `presets/README.md`**

Write:

```markdown
# presets/

Installable source packs for LLM clients.

This repository remains the source catalog. Presets in this directory are shaped
like their target clients so they can be synced or linked into local config
directories without making the repo root itself a client config directory.

## Packs

- `base/` - cross-client instructions and shared policy for all clients.
- `opencode/` - OpenCode-native config, commands, agents, plugins, tools, and TUI settings.

Shared skills stay in the repository-level `skills/` catalog so they can be
installed into OpenCode, Claude-compatible, and generic agent-compatible targets.
```

- [ ] **Step 3: Add `presets/base/README.md`**

Write:

```markdown
# base preset

Cross-client instructions that should apply regardless of the LLM client.

`AGENTS.md` is the main entrypoint because OpenCode, Codex, and several other
tools understand it. Client-specific files should be generated as shims rather
than becoming the canonical source.
```

- [ ] **Step 4: Add `presets/base/AGENTS.md`**

Write:

```markdown
# Darkmatter Global Agent Preset

This is the shared global instruction entrypoint installed from
`darkmatter/agents/presets/base`.

Project-specific instructions override this file. When working in a project,
read that project's `AGENTS.md` first and treat this file as general background.

## Defaults

- Prefer evidence over assertion: verify builds, tests, and claims before reporting success.
- Keep repo-specific context in the project repo, not in this shared preset catalog.
- Do not read or commit secrets, private keys, credentials, or local environment files.
- Preserve user changes in dirty worktrees unless explicitly asked to revert them.
- Use reusable skills from the shared catalog when their trigger conditions apply.
```

- [ ] **Step 5: Add `presets/opencode/README.md`**

Write:

```markdown
# OpenCode preset

OpenCode-native source pack for Darkmatter agent behavior.

When installed globally, this directory maps to `~/.config/opencode/`:

- `opencode.jsonc` -> runtime config
- `tui.json` -> TUI settings
- `agents/` -> Markdown agent definitions
- `commands/` -> slash-command prompt templates
- `plugins/` -> OpenCode JS/TS event hooks
- `tools/` -> custom model-callable tools
- `themes/` -> TUI themes
- `modes/` -> optional mode definitions

Shared skills are installed from the repository-level `skills/` directory rather
than duplicated here.
```

- [ ] **Step 6: Add minimal OpenCode config**

Write `presets/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "AGENTS.md"
  ],
  "permission": {
    "edit": "ask",
    "bash": "ask",
    "skill": {
      "*": "allow"
    }
  },
  "share": "manual",
  "autoupdate": "notify"
}
```

Write `presets/opencode/tui.json`:

```json
{
  "$schema": "https://opencode.ai/tui.json",
  "diff_style": "auto",
  "mouse": true
}
```

Write `presets/opencode/package.json`:

```json
{
  "private": true,
  "type": "module",
  "dependencies": {}
}
```

- [ ] **Step 7: Add placeholder files for empty OpenCode directories**

Run:

```bash
touch presets/base/instructions/.gitkeep presets/opencode/{agents,commands,plugins,tools,themes,modes}/.gitkeep
```

Expected: command exits 0.

- [ ] **Step 8: Verify skeleton files**

Run:

```bash
test -f presets/opencode/opencode.jsonc && python3 -m json.tool presets/opencode/tui.json >/dev/null && python3 -m json.tool presets/opencode/package.json >/dev/null
```

Expected: command exits 0 with no output.

- [ ] **Step 9: Checkpoint commit if commits are authorized**

Only run this if the user has explicitly asked for commits in the current session:

```bash
git add presets
git commit -m "feat: add opencode preset skeleton"
```

Expected: commit succeeds.

## Task 2: Document OpenCode Directory Mapping

**Files:**
- Create: `docs/opencode-layout.md`
- Modify: `README.md`

- [ ] **Step 1: Add `docs/opencode-layout.md`**

Write:

```markdown
# OpenCode layout

This repository is a source catalog for LLM presets. OpenCode is the preferred
client, but the repo root is not itself an OpenCode config directory.

## Source to install mapping

| OpenCode target | Source path | Purpose |
|---|---|---|
| `~/.config/opencode/opencode.jsonc` | `presets/opencode/opencode.jsonc` | Runtime config: models, permissions, agents, MCP servers, instructions, plugins, formatters. |
| `~/.config/opencode/tui.json` | `presets/opencode/tui.json` | TUI-only config: theme, keybinds, diff style, mouse behavior. |
| `~/.config/opencode/AGENTS.md` | `presets/base/AGENTS.md` | Global shared instructions. |
| `~/.config/opencode/agents/` | `presets/opencode/agents/` | Markdown agent definitions. |
| `~/.config/opencode/commands/` | `presets/opencode/commands/` | Slash-command prompt templates. |
| `~/.config/opencode/plugins/` | `presets/opencode/plugins/` | JS/TS OpenCode lifecycle hooks and event extensions. |
| `~/.config/opencode/tools/` | `presets/opencode/tools/` | JS/TS custom tools callable by the model. |
| `~/.config/opencode/themes/` | `presets/opencode/themes/` | Optional TUI themes. |
| `~/.config/opencode/skills/` | `skills/` | Shared on-demand skills. |

## What goes where

- `commands/` are slash-invoked prompts. They start workflows.
- `tools/` are deterministic functions the model can call during workflows.
- `plugins/` are event-driven extensions that react to OpenCode lifecycle events.
- `skills/` are reusable instruction bundles loaded on demand.
- `scripts/` are repo maintenance and install helpers. OpenCode does not auto-discover them.

## Project bootstrap files

The `template/` directory remains separate. It creates project-local files such
as `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, and `.agent/` context. Those files
belong in individual project repositories, not in global OpenCode config.
```

- [ ] **Step 2: Update `README.md` opening description**

Replace the current first paragraph with:

```markdown
Team-wide LLM preset infrastructure for the darkmatter umbrella. OpenCode is the
preferred client, but this repo stays source-oriented: shared assets live here
and are synced into OpenCode, Claude-compatible, Codex, and generic agent
locations as needed.
```

- [ ] **Step 3: Update `README.md` inventory and layout block**

Update the opening inventory so it no longer says the repo ships only three things. Use:

```markdown
This repo ships four things:

1. **OpenCode-first presets** (`presets/`) — installable source packs for LLM clients.
2. **A catalog of shared skills** (`skills/`) — installed across all darkmatter projects via Nix Home Manager.
3. **A project template** (`template/`) — `.agent/`, config, and shims to stamp into a new project repo.
4. **Tooling** (`scripts/`) — generators, installers, sync scripts, and validation helpers.
```

Add `presets/` to the layout block:

```text
├── presets/                 ← installable source packs, especially OpenCode
```

Keep existing entries for `skills/`, `template/`, `scripts/`, and `docs/`.

- [ ] **Step 4: Add an OpenCode section to `README.md`**

Add after the layout section:

```markdown
## OpenCode presets

OpenCode-native assets live in `presets/opencode/`. Shared cross-client
instructions live in `presets/base/`, and shared skills remain in `skills/`.

See `docs/opencode-layout.md` for the source-to-install mapping.
```

- [ ] **Step 5: Verify docs references**

Run:

```bash
test -f docs/opencode-layout.md && grep -q "presets/opencode" README.md && grep -q "OpenCode target" docs/opencode-layout.md
```

Expected: command exits 0 with no output.

- [ ] **Step 6: Checkpoint commit if commits are authorized**

Only run this if the user has explicitly asked for commits in the current session:

```bash
git add README.md docs/opencode-layout.md
git commit -m "docs: document opencode preset layout"
```

Expected: commit succeeds.

## Task 3: Add Safe OpenCode Sync Scripts

**Files:**
- Create: `scripts/sync-opencode.sh`
- Create: `scripts/install-opencode.sh`

- [ ] **Step 1: Add `scripts/sync-opencode.sh`**

Create a Bash script with these behaviors:

- Default target: `${XDG_CONFIG_HOME:-$HOME/.config}/opencode`
- Default mode: symlink source files/directories into the target.
- Optional `--copy` mode: copy files/directories instead of symlinking.
- Optional `--target <dir>` mode for tests and non-standard installs.
- Optional `--dry-run` mode that prints actions without writing.
- Back up conflicting non-symlink files or directories as `<name>.bak.<timestamp>`.
- Install base `AGENTS.md`, OpenCode preset files/directories, and shared `skills/`.
- Never delete user data.

Use this implementation outline:

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="link"
DRY_RUN=0
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

usage() {
  sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) MODE="copy"; shift ;;
    --link) MODE="link"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --target) TARGET="${2-}"; [[ -z "$TARGET" ]] && usage; shift 2 ;;
    --help|-h) usage ;;
    *) usage ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$REPO_ROOT/presets/base"
OC="$REPO_ROOT/presets/opencode"
SKILLS="$REPO_ROOT/skills"
STAMP="$(date +%Y%m%d%H%M%S)"

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: %q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ensure_parent() {
  run mkdir -p "$(dirname "$1")"
}

backup_conflict() {
  local dst="$1"
  if [[ ! -e "$dst" && ! -L "$dst" ]]; then
    return 0
  fi
  if [[ -L "$dst" ]]; then
    run rm "$dst"
    return 0
  fi
  run mv "$dst" "$dst.bak.$STAMP"
}

install_one() {
  local src="$1"
  local dst="$2"
  ensure_parent "$dst"
  backup_conflict "$dst"
  if [[ "$MODE" == "copy" ]]; then
    run cp -R "$src" "$dst"
  else
    run ln -s "$src" "$dst"
  fi
}

install_one "$BASE/AGENTS.md" "$TARGET/AGENTS.md"
install_one "$OC/opencode.jsonc" "$TARGET/opencode.jsonc"
install_one "$OC/tui.json" "$TARGET/tui.json"
install_one "$OC/package.json" "$TARGET/package.json"
install_one "$OC/agents" "$TARGET/agents"
install_one "$OC/commands" "$TARGET/commands"
install_one "$OC/plugins" "$TARGET/plugins"
install_one "$OC/tools" "$TARGET/tools"
install_one "$OC/themes" "$TARGET/themes"
install_one "$OC/modes" "$TARGET/modes"
install_one "$SKILLS" "$TARGET/skills"

printf 'OpenCode preset synced to %s using %s mode\n' "$TARGET" "$MODE"
```

Add a top comment before `set -euo pipefail` documenting usage.

- [ ] **Step 2: Add `scripts/install-opencode.sh`**

Create a wrapper that delegates to `sync-opencode.sh` and prints next steps:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
DRY_RUN=0

args=("$@")
idx=0
while [[ "$idx" -lt "${#args[@]}" ]]; do
  case "${args[$idx]}" in
    --dry-run) DRY_RUN=1 ;;
    --target)
      idx=$((idx + 1))
      CONFIG_DIR="${args[$idx]-}"
      ;;
  esac
  idx=$((idx + 1))
done

"$REPO_ROOT/scripts/sync-opencode.sh" "$@"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'dry-run: skipping dependency install\n'
elif [[ -f "$CONFIG_DIR/package.json" ]]; then
  if command -v bun >/dev/null 2>&1; then
    (cd "$CONFIG_DIR" && bun install)
  elif command -v npm >/dev/null 2>&1; then
    (cd "$CONFIG_DIR" && npm install)
  else
    printf 'warning: neither bun nor npm found; skipping OpenCode plugin/tool dependency install\n' >&2
  fi
fi

cat <<'MSG'

Next steps:
  1. Run: opencode
  2. Confirm the shared AGENTS.md and skills are visible.
  3. Edit provider/model settings in ~/.config/opencode/opencode.jsonc if needed.

Uninstall guidance:
  Remove symlinks created in ~/.config/opencode, or restore any *.bak.<timestamp>
  backups created by the sync script. The installer never deletes the cloned repo.

MSG
```

- [ ] **Step 3: Make scripts executable**

Run:

```bash
chmod +x scripts/sync-opencode.sh scripts/install-opencode.sh
```

Expected: command exits 0.

- [ ] **Step 4: Syntax-check scripts**

Run:

```bash
bash -n scripts/sync-opencode.sh && bash -n scripts/install-opencode.sh
```

Expected: command exits 0 with no output.

- [ ] **Step 5: Dry-run sync into a temporary target**

Run:

```bash
tmpdir="$(mktemp -d)" && scripts/sync-opencode.sh --dry-run --target "$tmpdir/opencode"
```

Expected: output lists `dry-run:` actions and ends with `OpenCode preset synced to ... using link mode`.

- [ ] **Step 5a: Verify installer help text includes uninstall guidance**

Run:

```bash
grep -q "Uninstall guidance" scripts/install-opencode.sh
```

Expected: command exits 0 with no output.

- [ ] **Step 5b: Verify installer dry-run does not install dependencies**

Run:

```bash
tmpdir="$(mktemp -d)" && scripts/install-opencode.sh --dry-run --target "$tmpdir/opencode" | grep -q "dry-run: skipping dependency install"
```

Expected: command exits 0 and no package manager runs.

- [ ] **Step 6: Real sync into a temporary target**

Run:

```bash
tmpdir="$(mktemp -d)" && scripts/sync-opencode.sh --target "$tmpdir/opencode" && test -L "$tmpdir/opencode/opencode.jsonc" && test -L "$tmpdir/opencode/skills"
```

Expected: command exits 0 and prints `OpenCode preset synced to ... using link mode`.

- [ ] **Step 7: Copy mode sync into a temporary target**

Run:

```bash
tmpdir="$(mktemp -d)" && scripts/sync-opencode.sh --copy --target "$tmpdir/opencode" && test -f "$tmpdir/opencode/opencode.jsonc" && test -d "$tmpdir/opencode/skills" && test ! -L "$tmpdir/opencode/opencode.jsonc"
```

Expected: command exits 0 and copied files are not symlinks.

- [ ] **Step 8: Checkpoint commit if commits are authorized**

Only run this if the user has explicitly asked for commits in the current session:

```bash
git add scripts/sync-opencode.sh scripts/install-opencode.sh
git commit -m "feat: add opencode preset installer"
```

Expected: commit succeeds.

## Task 4: Wire Presets Into Home Manager

**Files:**
- Modify: `home-manager.nix`
- Optional modify: `README.md`

- [ ] **Step 1: Inspect existing Home Manager module shape**

Read `home-manager.nix` and confirm it currently imports `agent-skills.homeManagerModules.default` and sets `programs.agent-skills` sources and targets.

Expected: the module remains a function of `{ agent-skills }:` and a Home Manager module argument set.

- [ ] **Step 2: Add OpenCode config file links through `xdg.configFile`**

Modify the module argument list to include `config` if needed by local style, then add:

```nix
  xdg.configFile = {
    "opencode/AGENTS.md".source = ./presets/base/AGENTS.md;
    "opencode/opencode.jsonc".source = ./presets/opencode/opencode.jsonc;
    "opencode/tui.json".source = ./presets/opencode/tui.json;
    "opencode/package.json".source = ./presets/opencode/package.json;
    "opencode/agents".source = ./presets/opencode/agents;
    "opencode/commands".source = ./presets/opencode/commands;
    "opencode/plugins".source = ./presets/opencode/plugins;
    "opencode/tools".source = ./presets/opencode/tools;
    "opencode/themes".source = ./presets/opencode/themes;
    "opencode/modes".source = ./presets/opencode/modes;
    "opencode/skills".source = ./skills;
  };
```

Keep the existing `programs.agent-skills` behavior intact for Claude, Codex, and generic `~/.agents/skills` targets.

- [ ] **Step 3: Verify Nix formatting**

Run:

```bash
nix fmt home-manager.nix flake.nix
```

Expected: command exits 0. If `nix fmt` is unavailable or no formatter is configured, report the actual output and do not claim formatting succeeded.

- [ ] **Step 4: Evaluate the flake outputs**

Run:

```bash
nix flake check --no-build
```

Expected: command exits 0 or reports only missing checks if the flake does not define checks. If the command fails due local Nix environment, capture the failure and continue to manual syntax review.

- [ ] **Step 5: Update README install section if Home Manager wiring changed**

If `xdg.configFile` entries were added, add one sentence to `README.md` under shared skills/OpenCode setup:

```markdown
The Home Manager module also links the OpenCode preset into `~/.config/opencode`.
```

- [ ] **Step 6: Checkpoint commit if commits are authorized**

Only run this if the user has explicitly asked for commits in the current session:

```bash
git add home-manager.nix README.md
git commit -m "feat: install opencode preset via home manager"
```

Expected: commit succeeds.

## Task 5: Validate Whole Reorg

**Files:**
- Read: `README.md`
- Read: `docs/opencode-layout.md`
- Read: `presets/opencode/README.md`
- Read: `home-manager.nix`

- [ ] **Step 1: Validate skill catalog still passes for known skills**

Run:

```bash
for skill in skills/*; do [ -d "$skill" ] || continue; scripts/validate-skill.sh "$skill"; done
```

Expected: each skill prints validation success. If unrelated pre-existing untracked or partially edited skills fail, record the exact failing path and do not modify it unless it is part of this plan.

- [ ] **Step 2: Validate OpenCode JSON files**

Run:

```bash
python3 -m json.tool presets/opencode/tui.json >/dev/null && python3 -m json.tool presets/opencode/package.json >/dev/null
```

Expected: command exits 0 with no output.

- [ ] **Step 3: Validate script syntax**

Run:

```bash
bash -n scripts/sync-opencode.sh && bash -n scripts/install-opencode.sh
```

Expected: command exits 0 with no output.

- [ ] **Step 4: Validate sync behavior in temp directories**

Run:

```bash
tmpdir="$(mktemp -d)" && scripts/sync-opencode.sh --target "$tmpdir/opencode" && test -L "$tmpdir/opencode/AGENTS.md" && test -L "$tmpdir/opencode/skills" && tmpcopy="$(mktemp -d)" && scripts/sync-opencode.sh --copy --target "$tmpcopy/opencode" && test -f "$tmpcopy/opencode/AGENTS.md" && test -d "$tmpcopy/opencode/skills"
```

Expected: command exits 0 and both link and copy modes work.

- [ ] **Step 5: Review git diff for unrelated changes**

Run:

```bash
git diff -- README.md home-manager.nix scripts/sync-opencode.sh scripts/install-opencode.sh docs/opencode-layout.md presets
```

Expected: diff contains only the repo reorganization changes described in this plan.

- [ ] **Step 6: Final status check**

Run:

```bash
git status --short
```

Expected: new/modified files from this plan are visible. Existing unrelated changes, if any, are not reverted.

- [ ] **Step 7: Final commit if commits are authorized**

Only run this if the user has explicitly asked for commits in the current session and earlier checkpoint commits were skipped:

```bash
git add README.md home-manager.nix docs/opencode-layout.md presets scripts/sync-opencode.sh scripts/install-opencode.sh
git commit -m "feat: organize opencode preset source layout"
```

Expected: commit succeeds.

## Notes For The Implementer

- This repository currently has unrelated dirty worktree entries. Do not revert them.
- Avoid touching `.gitignore` unless the implementation introduces new generated artifacts that must be ignored.
- Do not add provider API keys, model credentials, or private local paths.
- If `nix flake check --no-build` fails because of environment setup rather than syntax, report the actual error and continue with the other verification commands.
- If `opencode` is available locally, optionally run `opencode debug config` after syncing to a temporary target with `OPENCODE_CONFIG_DIR`, but do not require OpenCode for baseline validation.

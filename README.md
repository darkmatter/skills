# darkmatter/skills

Team-wide LLM preset infrastructure for the darkmatter umbrella. OpenCode is the
preferred client, but this repo stays source-oriented: shared assets live here
and are synced into OpenCode, Claude-compatible, Codex, and generic agent
locations as needed.

This repo ships five things:

1. **OpenCode-first presets** (`presets/`) — installable source packs for LLM clients.
2. **A catalog of shared skills** (`skills/`) — installed across all darkmatter projects via Nix Home Manager, or as a Claude Code plugin (see [Claude Code plugin marketplace](#claude-code-plugin-marketplace)).
3. **Shared instruction topics** (`docs/agents/`) — one file per section, exported as the flake output `agentsMd` so downstream repos import the topics they adopt; bundled into every LLM client's global `AGENTS.md` and into this repo's own generated `AGENTS.md`.
4. **Reference codebases** (`references/`) — per-language exemplar code agents consult for preferred conventions.
5. **Tooling** (`scripts/`) — installers, sync scripts, and validation helpers.

It is **provider-agnostic**. Skills and `.agent/` content target any agent tool (Claude Code, Codex, OpenCode, Cursor, Aider, etc.) by following the cross-vendor `AGENTS.md` convention plus the per-vendor shims (`CLAUDE.md`, `.cursorrules`).

Code conventions follow [codebase-design](skills/codebase-design/SKILL.md): keep
each capability together, make it simple to use, and split it only when the split
improves understanding. The skill contains the canonical rules and good/bad
examples; [ADR-0015](docs/adr/0015-cohesive-modules.md) records the decision.

## Layout

```
darkmatter/skills/
├── AGENTS.md                ← GENERATED — nix build .#agents-md; do not edit
├── .agents/
│   └── skills/              ← GENERATED sandbox subset — never edit by hand
├── .claude-plugin/          ← Claude Code marketplace + plugin manifests
├── README.md                ← this file
├── flake.nix                ← Nix entry; exports the Home Manager module
├── home-manager.nix         ← HM module that wires skills/ into agent CLIs
├── runtime/                 ← client-agnostic opt-in hook utilities (end-of-turn-review)
├── lib/                     ← Nix library helpers (skills source, submodules)
├── presets/                 ← installable source packs, especially OpenCode
├── skills/                  ← team-wide shareable skills (the catalog)
├── references/              ← per-language reference codebases (rust, go, typescript)
├── scripts/
│   ├── install-base.sh      ← install docs/AGENTS.md into a client dir
│   ├── install-omp.sh       ← install the OMP preset into ~/.omp/agent
│   ├── install-opencode.sh  ← install the OpenCode preset into ~/.config/opencode
│   ├── sync-omp.sh          ← sync docs/AGENTS.md + skills/ into OMP's config dir
│   ├── sync-opencode.sh     ← sync docs/AGENTS.md + skills/ into ~/.config/opencode
│   ├── sync-sandbox-skills.sh ← regenerate .agents/skills/ from the manifest
│   └── validate-skill.sh    ← sanity-check skills/ catalog
├── evals/
│   ├── skills/              ← Promptfoo behavior evals (LLM decision checks, CI)
│   └── prompt-tests/        ← real-repo opencode evals (local/manual only)
└── docs/
    ├── agents/              ← shared instruction topics, <order>-<topic>.md
    ├── AGENTS.md            ← GENERATED topic bundle — nix build .#agents-md-shared
    ├── AGENTS.repo.md       ← this repo's own agent instructions
    ├── catalog.md           ← what's in skills/
    └── opencode-layout.md   ← source-to-install mapping for OpenCode
```

## Claude Code plugin marketplace

The skills catalog is also installable as a Claude Code plugin — no Nix required.
Inside Claude Code:

```
/plugin marketplace add darkmatter/skills
/plugin install darkmatter-skills@darkmatter
```

`.claude-plugin/marketplace.json` defines the marketplace and lists the repo root
(`./`) as a single plugin; `.claude-plugin/plugin.json` is that plugin's manifest.
Claude Code auto-discovers every `skills/<name>/SKILL.md`, so adding a skill to the
catalog adds it to the plugin with no extra registration. Validate changes with
`claude plugin validate .`.

The Nix Home Manager module remains the primary distribution path on darkmatter
machines; the marketplace is for Claude Code users outside that setup (or for
trying the catalog before wiring up Nix).

## OpenCode presets

OpenCode-native assets live in `presets/opencode/`. Shared cross-client
instructions live in `docs/agents/` (bundled into the generated `docs/AGENTS.md`),
and shared skills remain in `skills/`.

See `docs/opencode-layout.md` for the source-to-install mapping.

## Where to put what

Use this table before adding a new instruction, skill, command, hook, or tool. The goal is to keep always-on context small while still making reusable behavior discoverable.

| Need                                                         | Put it here                                                             | Loaded when                           | Examples / notes                                                                                    |
| ------------------------------------------------------------ | ----------------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Org-wide rules that must apply in every session              | `docs/agents/<order>-<topic>.md`                                        | Always, as global agent instructions  | Keep short: safety, verification, preserving user changes, secret handling, evidence-before-claims. |
| Project-specific rules and decisions                         | Target project's own `AGENTS.md`, `.agent/context/*`, `.agent/policy/*` | Always inside that project            | Stack choices, local conventions, approved exceptions, project state. Owned by each project repo.   |
| Reusable task guidance the model should choose when relevant | `skills/<name>/SKILL.md`                                                | On demand via skill discovery         | Debugging, TDD, Effect, Neon, Nix, codebase cleanup. Add a row in `docs/catalog.md`.                |
| Long skill detail, examples, fixtures, or lookup data        | `skills/<name>/reference/`                                              | Only after the skill points there     | Use for large docs so `SKILL.md` stays concise.                                                     |
| Per-language convention exemplar code                        | `references/<language>/`                                                | On demand, from the repo checkout     | Reference codebases (rust, go, typescript). Code lives here; prose stays in skills. See ADR-0008.   |
| Deterministic helper used by a skill                         | `skills/<name>/scripts/`                                                | Only when the skill/script is invoked | Bash or Python stdlib preferred; document deps in the skill and catalog.                            |
| Manual slash-invoked workflow for OpenCode                   | `presets/opencode/commands/`                                            | User invokes `/command`               | Use for explicit workflows, prompts with arguments, or timing-sensitive actions.                    |
| OpenCode specialist agent definition                         | `presets/opencode/agents/`                                              | Invoked by agent routing or user      | Use for role-specific behavior and permissions, not reusable task instructions.                     |
| OpenCode lifecycle behavior                                  | `presets/opencode/plugins/`                                             | Event driven                          | Use for hooks, startup/stop behavior, observers, and client integrations.                           |
| Model-callable deterministic function                        | `presets/opencode/tools/`                                               | Tool call during a session            | Use for code that returns structured results and should not be prose instructions.                  |
| Repo maintenance helper                                      | `scripts/`                                                              | Human/agent command from this repo    | Installers, sync scripts, validators. Not auto-discovered by clients.                               |
| Human-readable inventory of shared skills                    | `docs/catalog.md`                                                       | Manual lookup and review              | Track skill purpose, triggers, mode/kind, overlaps, deprecations, and operational notes.            |

Placement rules:

1. If it must always be followed, put the shortest possible rule in a `docs/agents/` topic file or the target project's `AGENTS.md`; do not rely on an on-demand skill.
2. If it is detailed guidance for a domain or workflow, make it a skill and keep `SKILL.md` focused on discovery and navigation.
3. If it has side effects or the user should control timing, prefer a manual command or a manual-invocation skill.
4. If it must run deterministically on an event, implement it as a plugin/hook rather than prose.
5. If it is executable logic, prefer `tools/` or `scripts/` over asking the model to follow a long procedure by hand.

## Shared instructions

The shared instructions live as topics in `docs/agents/`, one file per topic named `<order>-<topic>.md` (`10-preamble.md`, `20-defaults.md`, …): the number sets the bundle order, the suffix is the topic you import. The flake reads the directory, so adding a file is all it takes — the file becomes importable and bundled automatically, while a misnamed or duplicate-topic file fails the build. Topics: `preamble`, `defaults`, `showing-code`, `must-always`, `must-never`, `readability`, `should`, `authority-order`, `completion-evidence`. The flake exports them as the `agentsMd` attrset (topic name → path), so a repo adopts exactly the topics it wants. Only Claude Code expands `@file` references; Codex, OpenCode, and OMP read `AGENTS.md` verbatim, so the shared text is always delivered as a real `AGENTS.md`, never as an import.

**Into a repo (canonical).** Pick the topics you adopt and concatenate them with repo-specific instructions at build time. With `darkmatter-skills` added as a flake input:

```nix
let agents = inputs.darkmatter-skills.agentsMd; in
packages.agents-md = pkgs.writeText "AGENTS.md" (lib.concatStringsSep "\n" [
  "<!-- Generated file — do not edit. -->"
  (builtins.readFile agents.preamble)
  (builtins.readFile agents.defaults)
  (builtins.readFile agents.showing-code)
  (builtins.readFile agents.must-always)
  (builtins.readFile agents.must-never)
  (builtins.readFile agents.readability)
  (builtins.readFile agents.should)
  (builtins.readFile agents.authority-order)
  (builtins.readFile agents.completion-evidence)
  (builtins.readFile ./docs/AGENTS.repo.md)
]);
```

Repo-specific instructions live in `docs/AGENTS.repo.md`. Refresh the committed `AGENTS.md` after editing any source:

```sh
cp "$(nix build --no-link --print-out-paths .#agents-md)" AGENTS.md
```

If `CLAUDE.md` is missing, create it containing `@AGENTS.md` once for Claude Code (an existing one is never touched). Catch staleness in CI:

```sh
diff -u AGENTS.md "$(nix build --no-link --print-out-paths .#agents-md)"
```

**This repo.** Two files are generated from the topics: the root `AGENTS.md` is every topic plus `docs/AGENTS.repo.md` (`packages.agents-md`), and `docs/AGENTS.md` is the topic bundle alone (`packages.agents-md-shared`) — kept as a plain committed file because the Home Manager module, `install-base.sh`, and the evals harness consume it by path. `checks.agents-md` fails the build when either drifts; CI builds that check.

**Into a machine.** The Home Manager module installs it as the global `AGENTS.md` for OpenCode (`~/.config/opencode/AGENTS.md`, via `programs.opencode.context`), Codex (`~/.codex/AGENTS.md`), and OMP (`~/.omp/agent/AGENTS.md`); those three load it natively. For Claude Code it is copied to `~/.claude/darkmatter/AGENTS.md`, which you import once from `~/.claude/CLAUDE.md` (see below).

On machines without Nix, install `docs/AGENTS.md` into a client config dir manually:

```sh
scripts/install-base.sh --target <client config dir>
```

Home Manager deliberately does not write `~/.claude/CLAUDE.md` — Claude Code treats that file as personal user config. Add this one-line import to it once to pull in the shared instructions:

```markdown
@~/.claude/darkmatter/AGENTS.md
```

`runtime/end-of-turn-review/` is a separate, client-agnostic opt-in review hook utility.

## Bootstrap a new project

Project bootstrap is owned by the **`darkmatter-repo-setup` skill** (`skills/darkmatter-repo-setup/SKILL.md`), which reads the separate **`darkmatter/template` repo** as the canonical template and applies it to the target repository.

To bootstrap: open the target repo in your LLM client, invoke the `darkmatter-repo-setup` skill, and let it audit, fill in, and validate the project against the `darkmatter/template` repo.

## Shared skills via Nix

The flake exports a Home Manager module that installs all team-wide skills into your agent CLIs. Wire it into your home config:

```nix
{
  inputs.darkmatter-skills.url = "git+ssh://git@github.com/darkmatter/skills";

  outputs = { home-manager, darkmatter-skills, ... }@inputs: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      modules = [
        darkmatter-skills.homeManagerModules.default
        ./home.nix
      ];

      extraSpecialArgs = {
        inherit inputs;
        # Optional — only set on machines where a private skills checkout exists:
        personalAgentSkillsPath = /Users/me/personal/skills;
        # Optional — customize the shared OpenCode base config:
        opencodeConfigOverlays = [
          (prev: {
            plugin = prev.plugin ++ [ "my-personal-plugin" ];
            mcp = prev.mcp // {
              local-tool = {
                type = "local";
                command = [ "my-tool" ];
                enabled = true;
              };
            };
          })
        ];
      };
    };
  };
}
```

The module enables every `darkmatter/*` skill and syncs them to Claude, Codex, and the generic `$HOME/.agents/skills` target. The Home Manager module also installs the OpenCode preset into `~/.config/opencode`, writing `opencode.jsonc` as a mutable file generated from `presets/opencode/opencode.nix` plus any `opencodeConfigOverlays`. Personal skills (when `personalAgentSkillsPath` is set) sync alongside.

## Adding a new shared skill

1. Pick a lowercase, hyphenated name. The directory name must exactly match the frontmatter `name:` field.
2. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`).
3. Optionally add `scripts/`, `reference/` subdirectories for code and supporting docs.
4. Run `scripts/validate-skill.sh skills/<skill-name>` to check structure.
5. Document it in `docs/catalog.md`.
6. Open a PR — CI runs `scripts/validate-skill.sh` across all skills via `.github/workflows/validate-skills.yml`.

See the [skill catalog](docs/catalog.md) for existing capabilities and registration.

If the skill should also reach Centaur sandboxes, add its name to
`.agents/skills.manifest` and run `scripts/sync-sandbox-skills.sh` (see below).

## Centaur sandbox subset (`.agents/`)

This repo is wired into [Centaur](https://github.com/darkmatter/centaur)
sandboxes as an overlay source (gitops `apps/centaur.yaml`,
`overlays.sources`). The overlay contract points at one directory per source
with no per-skill filtering, and the full catalog includes workstation-only
skills (macOS setup, local secrets, Slack side effects) that don't belong in a
sandbox — so sandboxes get a curated subset instead:

- `.agents/skills.manifest` — the curation surface: one skill name per line.
- `.agents/skills/` — **generated** copies of the listed skills, at the
  contract's default `skillsSubdir`. Never edit these by hand; edit
  `skills/<name>/` or the manifest and run `scripts/sync-sandbox-skills.sh`.
- CI runs `scripts/sync-sandbox-skills.sh --check` and fails on drift, so the
  copies can't diverge from the catalog.

Copies are real files, not symlinks: the sandbox skill merger preserves
symlinks when copying into `~/workspace`, so symlinks would arrive dangling.
Pushes to `main` reach sandboxes on the next repo-cache sync (~30s), no
deploy needed.

## Personal vs. team vs. project skills

| Scope         | Where it lives                               | When to use                                |
| ------------- | -------------------------------------------- | ------------------------------------------ |
| Personal      | private repo, `personal/skills/`, gitignored | Only useful to you; no team value          |
| Team-wide     | `skills/` here                               | Useful across multiple darkmatter projects |
| Project-local | `<project>/.agent/skills/`                   | Only relevant inside one project           |

## For agents reading this file

This repo is **not itself an agent project** — it ships infrastructure for them. There is no `.agent/` here, and no `agent.yaml`. Each darkmatter project (zkXMR, Stackpanel, the trading vault, etc.) has its own `.agent/`, bootstrapped via the `darkmatter-repo-setup` skill from the `darkmatter/template` repo and customized per project.

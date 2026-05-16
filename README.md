# darkmatter/skills

Team-wide LLM preset infrastructure for the darkmatter umbrella. OpenCode is the
preferred client, but this repo stays source-oriented: shared assets live here
and are synced into OpenCode, Claude-compatible, Codex, and generic agent
locations as needed.

This repo ships four things:

1. **OpenCode-first presets** (`presets/`) — installable source packs for LLM clients.
2. **A catalog of shared skills** (`skills/`) — installed across all darkmatter projects via Nix Home Manager.
3. **A project template** (`template/`) — `.agent/`, config, and shims to stamp into a new project repo.
4. **Tooling** (`scripts/`) — generators, installers, sync scripts, and validation helpers.

It is **provider-agnostic**. Skills and `.agent/` content target any agent tool (Claude Code, Codex, OpenCode, Cursor, Aider, etc.) by following the cross-vendor `AGENTS.md` convention plus the per-vendor shims (`CLAUDE.md`, `.cursorrules`).

## Layout

```
darkmatter/skills/
├── README.md                ← this file
├── flake.nix                ← Nix entry; exports the Home Manager module
├── home-manager.nix         ← HM module that wires skills/ into agent CLIs
├── presets/                 ← installable source packs, especially OpenCode
├── skills/                  ← team-wide shareable skills (the catalog)
├── template/                ← the per-project bootstrap (stamped by new-project.sh)
├── scripts/
│   ├── new-project.sh       ← stamp template/ into a target dir
│   └── validate-skill.sh    ← sanity-check skills/ catalog
└── docs/
    ├── catalog.md           ← what's in skills/
    └── new-project-guide.md ← walkthrough for bootstrapping a project
```

## OpenCode presets

OpenCode-native assets live in `presets/opencode/`. Shared cross-client
instructions live in `presets/base/`, and shared skills remain in `skills/`.

See `docs/opencode-layout.md` for the source-to-install mapping.

## Bootstrap a new project

```sh
scripts/new-project.sh ~/git/darkmatter/<name> <name> "Short description"
cd ~/git/darkmatter/<name>
$EDITOR .agent/context/overview.md     # describe the project
./scripts/regen-agent-shims.sh         # regenerate AGENTS.md / CLAUDE.md / .cursorrules
git init && git add . && git commit -m "bootstrap agent config"
```

See [`docs/new-project-guide.md`](docs/new-project-guide.md) for the full walkthrough.

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
      };
    };
  };
}
```

The module enables every `darkmatter/*` skill and syncs them to Claude, Codex, and the generic `$HOME/.agents/skills` target. The Home Manager module also links the OpenCode preset into `~/.config/opencode`. Personal skills (when `personalAgentSkillsPath` is set) sync alongside.

## Adding a new shared skill

1. Pick a lowercase, hyphenated name. The directory name must exactly match the frontmatter `name:` field.
2. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`).
3. Optionally add `scripts/`, `reference/` subdirectories for code and supporting docs.
4. Run `scripts/validate-skill.sh skills/<skill-name>` to check structure.
5. Document it in `docs/catalog.md`.
6. Open a PR — CI runs `scripts/validate-skill.sh` across all skills via `.github/workflows/validate-skills.yml`.

See [`skills/README.md`](skills/README.md) for the skill format spec.

## Personal vs. team vs. project skills

| Scope | Where it lives | When to use |
|---|---|---|
| Personal | private repo, `personal/skills/`, gitignored | Only useful to you; no team value |
| Team-wide | `skills/` here | Useful across multiple darkmatter projects |
| Project-local | `<project>/.agent/skills/` | Only relevant inside one project |

## For agents reading this file

This repo is **not itself an agent project** — it ships infrastructure for them. There is no `.agent/` here, and no `agent.yaml`. Each darkmatter project (zkXMR, Stackpanel, the trading vault, etc.) has its own `.agent/`, stamped from `template/` and customized.

# darkmatter/agents

Team-wide agent infrastructure for the darkmatter umbrella. This repo ships three things:

1. **A catalog of shared skills** (`skills/`) — installed across all darkmatter projects via Nix Home Manager.
2. **A project template** (`template/`) — `.agent/`, config, and shims to stamp into a new project repo.
3. **Tooling** (`scripts/`) — a generator that stamps the template into a project, plus skill-catalog validation.

It is **provider-agnostic**. Skills and `.agent/` content target any agent tool (Claude Code, Codex, OpenCode, Cursor, Aider, etc.) by following the cross-vendor `AGENTS.md` convention plus the per-vendor shims (`CLAUDE.md`, `.cursorrules`).

## Layout

```
darkmatter/agents/
├── README.md                ← this file
├── flake.nix                ← Nix entry; exports the Home Manager module
├── home-manager.nix         ← HM module that wires skills/ into agent CLIs
├── skills/                  ← team-wide shareable skills (the catalog)
├── template/                ← the per-project bootstrap (stamped by new-project.sh)
├── scripts/
│   ├── new-project.sh       ← stamp template/ into a target dir
│   └── validate-skill.sh    ← sanity-check skills/ catalog
└── docs/
    ├── catalog.md           ← what's in skills/
    └── new-project-guide.md ← walkthrough for bootstrapping a project
```

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
  inputs.darkmatter-agents.url = "git+ssh://git@github.com/darkmatter/agents";

  outputs = { home-manager, darkmatter-agents, ... }@inputs: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      modules = [
        darkmatter-agents.homeManagerModules.default
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

The module enables every `darkmatter/*` skill and syncs them to Claude, Codex, and the generic `$HOME/.agents/skills` target. Personal skills (when `personalAgentSkillsPath` is set) sync alongside.

## Adding a new shared skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`).
2. Optionally add `scripts/`, `reference/` subdirectories for code and supporting docs.
3. Run `scripts/validate-skill.sh skills/<skill-name>` to check structure.
4. Document it in `docs/catalog.md`.
5. Open a PR.

See [`skills/README.md`](skills/README.md) for the skill format spec.

## Personal vs. team vs. project skills

| Scope | Where it lives | When to use |
|---|---|---|
| Personal | private repo, `personal/skills/`, gitignored | Only useful to you; no team value |
| Team-wide | `skills/` here | Useful across multiple darkmatter projects |
| Project-local | `<project>/.agent/skills/` | Only relevant inside one project |

## For agents reading this file

This repo is **not itself an agent project** — it ships infrastructure for them. There is no `.agent/` here, and no `agent.yaml`. Each darkmatter project (zkXMR, Stackpanel, the trading vault, etc.) has its own `.agent/`, stamped from `template/` and customized.

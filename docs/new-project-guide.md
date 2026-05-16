# Bootstrapping a new darkmatter project

This walks through stamping the `template/` into a fresh project repo and getting it ready for agent use.

## Prerequisites

- A directory where the new project will live (existing or to be created)
- A short name and one-sentence description for the project

## Step 1 — stamp the template

From inside `darkmatter/skills/`:

```sh
scripts/new-project.sh ~/git/darkmatter/<name> <name> "Short description"
```

What this does:

- Creates `<target>/` if it doesn't exist
- Copies every file under `template/` into the target, with placeholders substituted:
  - `{{project}}` → `<name>`
  - `{{project_description}}` → the description string
  - `{{date}}` → today's date
  - `{{review_date}}` → 3 months from today
- Refuses to overwrite existing files unless `--force` is passed

Files written:

```
<target>/
├── .agent/
│   ├── README.md
│   ├── context/{overview,decisions,conventions,glossary}.md
│   ├── memory/{lessons,known-issues,changelog}.md
│   ├── workflows/  (empty)
│   ├── prompts/    (empty)
│   └── skills/     (empty)
├── AGENTS.md
├── CLAUDE.md
├── .cursorrules
├── README.md
├── agent.yaml
├── RULES.md
├── DUTIES.md
├── SOUL.md
├── compliance/{risk-assessment.md,regulatory-map.yaml,validation-schedule.yaml}
├── hooks/{hooks.yaml,scripts/on-start.sh,scripts/on-error.sh}
├── knowledge/index.yaml
├── config/default.yaml
├── memory/{MEMORY.md,memory.yaml}
└── scripts/regen-agent-shims.sh
```

## Step 2 — fill in the template

Open `<target>/.agent/context/overview.md` and replace the `>` placeholder blocks with real content:

- What the project is (one paragraph)
- Current state (shipped / in progress / planned)
- People and roles
- Adjacent darkmatter projects this one touches
- Where the source of truth for dynamic data lives

Then add at least the first standing decisions to `.agent/context/decisions.md`. If you don't have any yet, leave the section empty rather than inventing them.

Edit `agent.yaml`:

- `description`: short
- `compliance.*`: advisory defaults; detailed controls live in `compliance/` — edit `compliance/risk-assessment.md` and `compliance/*.yaml` for project-specific risk tier and regulatory mappings

Customize `RULES.md`, `DUTIES.md`, `SOUL.md` as needed. The defaults are sensible.

## Step 3 — regenerate provider shims

```sh
cd <target>
./scripts/regen-agent-shims.sh
```

This rewrites `AGENTS.md`, `CLAUDE.md`, and `.cursorrules` from `agent.yaml` (for the project name) and the `.agent/` structure. Run it any time you significantly change `.agent/` content. You do not need to run it immediately after stamping — the initial shims are already correct.

## Step 4 — initial commit

```sh
git init
git add .
git commit -m "bootstrap agent config from darkmatter/skills"
```

## Step 5 — wire team-wide skills

If you don't already have the `darkmatter/skills` Nix module wired into your home configuration, see the README at the root of this repo. Once it is, every team-wide skill in `skills/` is auto-installed for the agent CLIs you use, in every project.

## Updating after the template changes

The template is a one-shot stamp, not a live dependency. When the template changes, projects don't auto-update. To pull a template change into an existing project:

- For shim regeneration logic: copy `template/scripts/regen-agent-shims.sh` over the project's copy
- For new sections in `RULES.md` / `DUTIES.md` / `SOUL.md`: copy by hand
- For new `.agent/` subdirectories: `mkdir` and add a starter file

If you find yourself doing this often, consider promoting the changing thing into a team-wide skill instead.

# skills/ — darkmatter team-wide skill catalog

Skills here are shared across all darkmatter projects via the Nix Home Manager module exported by this repo's `flake.nix`.

## What belongs here vs. elsewhere

| Where | Scope |
|---|---|
| `darkmatter/skills/skills/` (here) | Useful across multiple darkmatter projects |
| `<project>/.agent/skills/` | Only relevant inside one project |
| `personal/skills/` (gitignored / private repo) | Only useful to one teammate |

Promote a project-local skill to the team catalog when a second project starts wanting the same capability.

## Skill format

Each skill is a directory under `skills/`. It must contain a `SKILL.md` with YAML frontmatter:

```markdown
---
name: example-skill
description: One sentence describing what the skill does and the trigger conditions for using it. The first 200 characters of this matter most — they're what an agent sees when deciding whether to load the skill.
---

# Example skill

## When to use

> Triggers — concrete sentences or question shapes that should make an agent pick this skill.

## When NOT to use

> Anti-triggers — adjacent things that look similar but should use a different tool or general knowledge.

## Tools

> Code, scripts, references the skill ships. Each gets a usage example.

## Reference

> Additional supporting docs, kept in `reference/` if more than a paragraph.
```

Recommended subdirectories:

- `scripts/` — runnable code the skill executes
- `reference/` — supporting markdown the skill loads on demand

## Naming

- Lowercase, hyphenated: `dm-funding-screener`, not `FundingScreener` or `funding_screener`
- Team-wide skill names must start with `dm-`. Do not add a second `dm-` prefix to names that already have one.
- Directory name must match the `name:` field in frontmatter
- After the `dm-` namespace, add a domain prefix only when the domain is genuinely load-bearing, such as `dm-hl-funding-analysis`

## Validation

Run `scripts/validate-skill.sh` from the repo root before opening a PR. It checks:

- `SKILL.md` exists
- Frontmatter has `name` and `description`
- Skill names start with `dm-` and do not double-prefix `dm-dm-`
- Directory name matches frontmatter name

## Adding a skill

1. `mkdir skills/<name>` and write `SKILL.md` per the format above
2. Add code/reference files as needed
3. `scripts/validate-skill.sh skills/<name>`
4. Add a one-liner entry to `docs/catalog.md`
5. PR

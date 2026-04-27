# Skill catalog

Team-wide skills currently shipped from `skills/`. Add an entry here when you add a skill.

| Skill | One-liner | Triggers |
|---|---|---|
| _none yet_ | The catalog is empty. The previous HL-specific skills (hl-api, hl-funding-analysis) were moved to the trading project's own `.agent/skills/` since they're project-local. | — |

## How to add an entry

When you add a skill at `skills/<name>/`:

1. Pick a one-line description that overlaps with `SKILL.md` frontmatter `description` but is human-skim-friendly.
2. Add a row to the table above.
3. If the skill ships scripts that depend on environment (Python, Node, particular CLIs), note that in a "Notes" column or in a footnote.

# Skill catalog

Team-wide skills currently shipped from `skills/`. Add an entry here when you add a skill.

| Skill | One-liner | Triggers | Notes |
|---|---|---|---|
| `hl-funding-analysis` | Analyze Hyperliquid perpetual funding rates and identify carry-trade opportunities, with realized harvest PnL across configurable windows. | "find me funding harvest opportunities", "what's paying funding on HL", "should I short X for the funding", basis trade evaluation on HL | Python 3, no external deps. Caches to `/tmp/hl_*` by default. Use `--exclude` per project to skip names already in your book. Project-specific sizing tiers should live in that project's `decisions.md`. |

## How to add an entry

When you add a skill at `skills/<name>/`:

1. Pick a one-line description that overlaps with `SKILL.md` frontmatter `description` but is human-skim-friendly.
2. Add a row to the table above.
3. If the skill ships scripts that depend on environment (Python, Node, particular CLIs), note that in a "Notes" column or in a footnote.

# Skill catalog

Team-wide skills currently shipped from `skills/`. Add an entry here when you add a skill.

| Skill | One-liner | Triggers | Notes |
|---|---|---|---|
| `hl-funding-analysis` | Analyze Hyperliquid perpetual funding rates and identify carry-trade opportunities, with realized harvest PnL across configurable windows. | "find me funding harvest opportunities", "what's paying funding on HL", "should I short X for the funding", basis trade evaluation on HL | Python 3, no external deps. Caches to `/tmp/hl_*` by default. Use `--exclude` per project to skip names already in your book. Project-specific sizing tiers should live in that project's `decisions.md`. |
| `end-of-turn-review` | GPT-5.5 second-opinion pass over a diff, plan, or turn transcript. Returns LGTM / notes / BLOCK with file:line citations. | end-of-turn (via Stop hook), "review what you just did", "critique this plan", pre-commit second opinion | Bash + `jq` + `curl`. Calls LiteLLM at `LITELLM_BASE_URL` (default `https://litellm.drkmttr.dev/v1`). `REVIEW_MODEL` env var overrides the model alias (default `gpt-5.5`). Hook setup is per-machine — see `reference/hook-setup.md`. |
| `dm-design-kickoff` | Inverted-flow design-room kickoff. Operator drops a Claude Design URL; the skill creates the Linear ticket, posts to `#design-room`, and cross-links Linear ⇄ Slack ⇄ Claude Design. | Operator pastes a `claude.ai/design/p/<uuid>` URL into chat, "kick off a design room for <screen>", partial-failure rerun on the same URL | Pure procedural skill — ships no scripts. Requires Linear + Slack write integration in the runtime (MCP server for code agents; built-in connector for claude.ai). Slack target is hardcoded to `#design-room` (`C0AV067EY83`). Idempotent on rerun. |

## How to add an entry

When you add a skill at `skills/<name>/`:

1. Pick a one-line description that overlaps with `SKILL.md` frontmatter `description` but is human-skim-friendly.
2. Add a row to the table above.
3. If the skill ships scripts that depend on environment (Python, Node, particular CLIs), note that in a "Notes" column or in a footnote.

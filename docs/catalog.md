# Skill catalog

Team-wide skills currently shipped from `skills/`. Add an entry here when you add a skill.

| Skill | One-liner | Triggers | Notes |
|---|---|---|---|
| `dm-hl-funding-analysis` | Analyze Hyperliquid perpetual funding rates and identify carry-trade opportunities, with realized harvest PnL across configurable windows. | "find me funding harvest opportunities", "what's paying funding on HL", "should I short X for the funding", basis trade evaluation on HL | Python 3, no external deps. Caches to `/tmp/hl_*` by default. Use `--exclude` per project to skip names already in your book. Project-specific sizing tiers should live in that project's `decisions.md`. |
| `dm-end-of-turn-review` | GPT-5.5 second-opinion pass over a diff, plan, or turn transcript. Returns LGTM / notes / BLOCK with file:line citations. | end-of-turn (via Stop hook), "review what you just did", "critique this plan", pre-commit second opinion | Bash + `jq` + `curl`. Calls LiteLLM at `LITELLM_BASE_URL` (default `https://litellm.drkmttr.dev/v1`). `REVIEW_MODEL` env var overrides the model alias (default `gpt-5.5`). Hook setup is per-machine — see `reference/hook-setup.md`. |
| `dm-codebase-cleanup` | Multi-pass refactor / code-quality sweep dispatched as 8 specialist subagents (AI slop, legacy, unused code, circular deps, weak types, type consolidation, defensive programming, DRY). Each pass runs research → critical assessment → high-confidence implementation. | "clean up the codebase", "tech-debt pass", "find dead code", "remove AI slop", "remove circular deps", quarterly hygiene runs | No scripts — pure prompt library. Calling agent dispatches each pass as a subagent (or sequentially in one). Recommended ordering and which passes can parallelize is in `reference/pass-ordering.md`. |
| `dm-skill-creator` | Create new team-wide skills inside this repo following its conventions (frontmatter, validator, catalog row, no external deps) and test the addition end-to-end via a `~/darwin` rebuild. | "add a skill", "create a darkmatter skill", "promote this into a shared skill", "make this reusable across projects" | Bash + Python 3 stdlib only. Ships `scripts/scaffold-skill.sh` (with `--manual` flag per ADR-0001) for a starter `SKILL.md` and `reference/checklist.md` for the end-to-end walkthrough. Test step uses `darwin-rebuild --override-input darkmatter/darkmatter-agents path:...` so changes can be validated before pushing. |
| `dm-run-meeting-summary` | **Manual.** Resolve meeting artifacts from loose requests, pasted text, local files, or provider connectors; draft a company-safe Obsidian summary; require a submit/edit/discard review gate before writing. | `/dm-run-meeting-summary import my last meeting from Granola`, "import my last one-on-one with John Doe", pasted transcript/path, MeetJamie/Jamie notes | Manual-invocation. Provider-agnostic; connector access optional. Writes only approved sanitized summaries; raw artifacts are not persisted by default. |
| `dm-kickoff-dm-design` | **Manual.** Inverted-flow design-room kickoff. Operator drops a Claude Design URL; this skill creates the Linear ticket, posts to `#design-room`, and cross-links Linear ⇄ Slack ⇄ Claude Design. Non-interactive, idempotent. | `/dm-kickoff-dm-design <claude-design-url>`, "kick off a design room for X", "broadcast this design" | Manual-invocation skill (ADR-0001) — does not auto-trigger. Requires Linear + Slack write access via MCP server (code agents) or built-in connectors (claude.ai). Hard-fails preflight if either is missing. |

## How to add an entry

When you add a skill at `skills/<name>/`:

1. Pick a one-line description that overlaps with `SKILL.md` frontmatter `description` but is human-skim-friendly.
2. Add a row to the table above.
3. If the skill ships scripts that depend on environment (Python, Node, particular CLIs), note that in a "Notes" column or in a footnote.

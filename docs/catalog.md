# Skill catalog

Team-wide skills currently shipped from `skills/`. Add an entry here when you add a skill.

| Skill | One-liner | Triggers | Notes |
|---|---|---|---|
| `dm-agent-browser` | Browser automation CLI for AI agents (Chrome/Chromium via CDP). | "open a website", "fill out a form", "take a screenshot", "scrape data from a page", "test this web app" | npm/cargo/brew install. Overlaps with `dm-browser-use`; see precedence note below. |
| `dm-brainstorming` | Explore user intent, requirements, and design before implementation. | Before any creative work — creating features, building components, adding functionality | Must-use before implementation. |
| `dm-browser-use` | Browser automation via `browser-use` CLI with persistent sessions. | "navigate websites", "interact with web pages", "fill forms", "take screenshots", "extract information" | Python-based. Overlaps with `dm-agent-browser`; see precedence note below. |
| `dm-caveman` | Ultra-compressed communication mode (~75% token savings). | "caveman mode", "talk like caveman", "less tokens", "be brief" | Supports intensity levels: lite, full, ultra, wenyan variants. |
| `dm-caveman-commit` | Ultra-compressed conventional commit messages. | "write a commit", "commit message", "/commit" | Subject ≤50 chars, body only when "why" isn't obvious. |
| `dm-caveman-review` | Ultra-compressed code review comments. | "review this PR", "code review", "/review" | One line per finding: location, problem, fix. |
| `dm-codebase-cleanup` | Multi-pass refactor / code-quality sweep dispatched as 8 specialist subagents (AI slop, legacy, unused code, circular deps, weak types, type consolidation, defensive programming, DRY). Each pass runs research → critical assessment → high-confidence implementation. | "clean up the codebase", "tech-debt pass", "find dead code", "remove AI slop", "remove circular deps", quarterly hygiene runs | No scripts — pure prompt library. Calling agent dispatches each pass as a subagent (or sequentially in one). Recommended ordering and which passes can parallelize is in `reference/pass-ordering.md`. |
| `dm-coding-standards` | Universal coding standards for TS/JS/React/Node. | Any code authoring or review task | Broad reference; `dm-vercel-react-best-practices` is more specific for React perf. |
| `dm-compress` | Compress natural-language memory files into caveman format. | "/caveman:compress <filepath>", "compress memory file" | Saves backup as FILE.original.md. |
| `dm-continuous-learning` | Runtime policy: extract reusable patterns from sessions into learned skills. | OpenCode Stop hook (automatic) | **Client/runtime policy doc** — not an ordinary task skill. See note below. |
| `dm-dispatching-parallel-agents` | Delegate 2+ independent tasks to isolated subagents. | "do these in parallel", multiple independent tasks | See also `dm-subagent-driven-development` for plan-driven dispatch. |
| `dm-end-of-turn-review` | GPT-5.5 second-opinion pass over a diff, plan, or turn transcript. Returns LGTM / notes / BLOCK with file:line citations. | end-of-turn (via Stop hook), "review what you just did", "critique this plan", pre-commit second opinion | Bash + `jq` + `curl`. Calls LiteLLM at `LITELLM_BASE_URL` (default `https://litellm.drkmttr.dev/v1`). `REVIEW_MODEL` env var overrides the model alias (default `gpt-5.5`). Hook setup is per-machine — see `reference/hook-setup.md`. |
| `dm-effect-typescript` | Use Effect deliberately in TypeScript/Bun projects, with services, Layers, typed errors, testing, and Alchemy deployment conventions. | "use Effect", "write Effect code", "Effect service", "Layer", "Schema", "Alchemy deployment" | Pure prompt reference. Adapts upstream Effect guidance to Bun over pnpm and Alchemy-first deploys. |
| `dm-executing-plans` | Execute a written implementation plan with review checkpoints. | When handed a plan to implement | Redirects to `dm-subagent-driven-development` if subagents are available. |
| `dm-find-skills` | Discover and install agent skills from the open ecosystem. | "how do I do X", "find a skill for X", "is there a skill that can..." | |
| `dm-finishing-a-development-branch` | Guide completion of dev work: merge, PR, or cleanup options. | Implementation complete, all tests pass | |
| `dm-frontend-design` | Create distinctive, production-grade frontend interfaces. | Build web components, pages, dashboards, React components, HTML/CSS layouts | Overlaps with `dm-ui-ux-pro-max`; see precedence note below. |
| `dm-hl-funding-analysis` | Analyze Hyperliquid perpetual funding rates and identify carry-trade opportunities, with realized harvest PnL across configurable windows. | "find me funding harvest opportunities", "what's paying funding on HL", "should I short X for the funding", basis trade evaluation on HL | Python 3, no external deps. Caches to `/tmp/hl_*` by default. Use `--exclude` per project to skip names already in your book. Project-specific sizing tiers should live in that project's `decisions.md`. |
| `dm-kickoff-dm-design` | **Manual.** Inverted-flow design-room kickoff. Operator drops a Claude Design URL; this skill creates the Linear ticket, posts to `#design-room`, and cross-links Linear ⇄ Slack ⇄ Claude Design. Non-interactive, idempotent. | `/dm-kickoff-dm-design <claude-design-url>`, "kick off a design room for X", "broadcast this design" | Manual-invocation skill (ADR-0001) — does not auto-trigger. Requires Linear + Slack write access via MCP server (code agents) or built-in connectors (claude.ai). Hard-fails preflight if either is missing. |
| `dm-neon-postgres` | Guides and best practices for Neon Serverless Postgres. | Any Neon-related question | |
| `dm-nix-flake-organization` | Organize Nix flake repos into thin `flake/` public layer with `src/` implementation. | "organize flake outputs", "thin flake modules" | |
| `dm-receiving-code-review` | Evaluate code review feedback with technical rigor before implementing. | When receiving review feedback | Don't blindly implement — verify first. |
| `dm-requesting-code-review` | Dispatch code-reviewer subagent before merging. | After completing tasks or major features | |
| `dm-run-meeting-summary` | **Manual.** Resolve meeting artifacts from loose requests, pasted text, local files, or provider connectors; draft a company-safe Obsidian summary; require a submit/edit/discard review gate before writing. | `/dm-run-meeting-summary import my last meeting from Granola`, "import my last one-on-one with John Doe", pasted transcript/path, MeetJamie/Jamie notes | Manual-invocation. Provider-agnostic; connector access optional. Writes only approved sanitized summaries; raw artifacts are not persisted by default. |
| `dm-skill-creator` | Create new team-wide skills inside this repo following its conventions (frontmatter, validator, catalog row, no external deps) and test the addition end-to-end via a `~/darwin` rebuild. | "add a skill", "create a darkmatter skill", "promote this into a shared skill", "make this reusable across projects" | Bash + Python 3 stdlib only. Ships `scripts/scaffold-skill.sh` (with `--manual` flag per ADR-0001) for a starter `SKILL.md` and `reference/checklist.md` for the end-to-end walkthrough. Test step uses `darwin-rebuild --override-input darkmatter/darkmatter-agents path:...` so changes can be validated before pushing. |
| `dm-strategic-compact` | Make auto-compaction safe for autonomous multi-phase work. | OpenCode sessions with auto-compaction enabled | **Client/runtime policy doc** — not an ordinary task skill. |
| `dm-subagent-driven-development` | Execute plan tasks via dispatched subagents with two-stage review. | Executing implementation plans with independent tasks | Prefer over `dm-executing-plans` when subagents are available. |
| `dm-systematic-debugging` | Structured approach to bugs, test failures, and unexpected behavior. | Any bug, test failure, or unexpected behavior | Before proposing fixes. |
| `dm-tdd-workflow` | Legacy TDD skill — redirects to `dm-test-driven-development`. | Writing features, fixing bugs, refactoring | **Deprecated** — use `dm-test-driven-development` instead. |
| `dm-test-driven-development` | TDD discipline: write test first, watch it fail, minimal code to pass. | Implementing any feature or bugfix, before writing implementation code | |
| `dm-ui-ux-pro-max` | Comprehensive UI/UX design intelligence: 50+ styles, 161 palettes, 57 font pairings, 99 UX guidelines across 10 stacks. | Design, build, review, or improve UI/UX code | Overlaps with `dm-frontend-design`; see precedence note below. |
| `dm-using-superpowers` | Runtime policy: establish skill discovery and invocation protocol at conversation start. | Start of any conversation (automatic) | **Client/runtime policy doc** — not an ordinary task skill. See note below. |
| `dm-verification-before-completion` | Run verification commands and confirm output before claiming work is done. | About to claim work is complete, fixed, or passing | Evidence before assertions. |
| `dm-vercel-react-best-practices` | React/Next.js performance optimization guidelines from Vercel Engineering. | Writing, reviewing, or refactoring React/Next.js code | More specific than `dm-coding-standards` for React perf. |
| `dm-writing-plans` | Write comprehensive implementation plans before touching code. | Have a spec or requirements for a multi-step task | |
| `dm-writing-skills` | TDD applied to process documentation — create, edit, or verify skills. | Creating, editing, or verifying skills before deployment | |

## Overlap & precedence notes

### `dm-tdd-workflow` → `dm-test-driven-development`
`dm-tdd-workflow` is a legacy entry. Use `dm-test-driven-development` for all new work. `dm-tdd-workflow` is retained for backward compatibility with a redirect note in its description and body.

### `dm-browser-use` vs `dm-agent-browser`
Both provide browser automation. `dm-browser-use` uses a Python CLI with persistent sessions; `dm-agent-browser` uses Chrome/Chromium via CDP directly. Prefer `dm-browser-use` for Python-centric workflows and `dm-agent-browser` for Node.js/rust-centric workflows or when direct CDP control is needed.

### `dm-frontend-design` vs `dm-ui-ux-pro-max` vs `dm-vercel-react-best-practices`
- **`dm-frontend-design`**: Use when the primary goal is *visual design quality* — distinctive aesthetics, avoiding generic AI look.
- **`dm-ui-ux-pro-max`**: Use when the primary goal is *design system intelligence* — structured style/palette/font/guideline selection across stacks.
- **`dm-vercel-react-best-practices`**: Use when the primary goal is *React/Next.js performance* — bundle size, waterfalls, re-renders.
- When both design and performance matter, apply `dm-frontend-design` or `dm-ui-ux-pro-max` first, then `dm-vercel-react-best-practices` as a review pass.

### `dm-coding-standards` vs `dm-vercel-react-best-practices`
`dm-coding-standards` covers universal TS/JS/React/Node patterns. `dm-vercel-react-best-practices` is a deeper, React/Next-specific performance supplement. Apply `dm-coding-standards` broadly; layer `dm-vercel-react-best-practices` for React perf work.

### `dm-coding-standards` vs `dm-effect-typescript`
`dm-coding-standards` covers general TypeScript quality. `dm-effect-typescript` is the deeper supplement for projects already using Effect or features where Effect's typed errors, Layers, resources, retries, tests, and Alchemy deployment conventions matter.

## Client/runtime policy docs

`dm-using-superpowers` and `dm-continuous-learning` are **not ordinary task skills** that implement hooks or produce artifacts themselves. They are **runtime policy documents** consumed by the agent client (e.g., OpenCode, Claude Code) to configure session behavior:

- **`dm-using-superpowers`**: Instructs the agent runtime to always check for and invoke relevant skills before responding. It is a *dispatch policy*, not a task implementation.
- **`dm-continuous-learning`**: Instructs the agent runtime to extract reusable patterns at session end. It is a *learning policy*, not a task implementation.

`dm-strategic-compact` similarly configures auto-compaction behavior for long autonomous sessions.

## How to add an entry

When you add a skill at `skills/<name>/`:

1. Pick a one-line description that overlaps with `SKILL.md` frontmatter `description` but is human-skim-friendly.
2. Add a row to the table above.
3. If the skill overlaps with an existing one, add a precedence note in the section above.
4. If the skill ships scripts that depend on environment (Python, Node, particular CLIs), note that in a "Notes" column or in a footnote.

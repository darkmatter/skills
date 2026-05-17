# Skill catalog

Team-wide skills currently shipped from `skills/`. Add an entry here when you add a skill.

| Skill | One-liner | Triggers | Notes |
|---|---|---|---|
| `agent-browser` | Browser automation CLI for AI agents (Chrome/Chromium via CDP). | "open a website", "fill out a form", "take a screenshot", "scrape data from a page", "test this web app" | npm/cargo/brew install. Overlaps with `browser-use`; see precedence note below. |
| `brainstorming` | Explore user intent, requirements, and design before implementation. | Before any creative work — creating features, building components, adding functionality | Must-use before implementation. |
| `browser-use` | Browser automation via `browser-use` CLI with persistent sessions. | "navigate websites", "interact with web pages", "fill forms", "take screenshots", "extract information" | Python-based. Overlaps with `agent-browser`; see precedence note below. |
| `caveman` | Ultra-compressed communication mode (~75% token savings). | "caveman mode", "talk like caveman", "less tokens", "be brief" | Supports intensity levels: lite, full, ultra, wenyan variants. |
| `caveman-commit` | Ultra-compressed conventional commit messages. | "write a commit", "commit message", "/commit" | Subject ≤50 chars, body only when "why" isn't obvious. |
| `caveman-review` | Ultra-compressed code review comments. | "review this PR", "code review", "/review" | One line per finding: location, problem, fix. |
| `codebase-cleanup` | Multi-pass refactor sweep as 8 specialist subagents. | "clean up the codebase", "tech-debt pass", "find dead code", "remove AI slop" | No scripts — pure prompt library. See `reference/pass-ordering.md`. |
| `coding-standards` | Universal coding standards for TS/JS/React/Node. | Any code authoring or review task | Broad reference; `vercel-react-best-practices` is more specific for React perf. |
| `compress` | Compress natural-language memory files into caveman format. | "/caveman:compress <filepath>", "compress memory file" | Saves backup as FILE.original.md. |
| `continuous-learning` | Runtime policy: extract reusable patterns from sessions into learned skills. | OpenCode Stop hook (automatic) | **Client/runtime policy doc** — not an ordinary task skill. See note below. |
| `dispatching-parallel-agents` | Delegate 2+ independent tasks to isolated subagents. | "do these in parallel", multiple independent tasks | See also `subagent-driven-development` for plan-driven dispatch. |
| `dm-skill-creator` | Create new team-wide skills in this repo following its conventions. | "add a skill", "create a darkmatter skill", "promote this into a shared skill" | Ships `scripts/scaffold-skill.sh`. Test via `darwin-rebuild`. |
| `end-of-turn-review` | GPT-5.5 second-opinion pass over diffs or plans. | End-of-turn (Stop hook), "review what you just did", "critique this plan" | Calls LiteLLM. `REVIEW_MODEL` env var overrides model. |
| `effect-typescript` | Use Effect deliberately in TypeScript/Bun projects, with services, Layers, typed errors, testing, and Alchemy deployment conventions. | "use Effect", "write Effect code", "Effect service", "Layer", "Schema", "Alchemy deployment" | Pure prompt reference. Adapts upstream Effect guidance to Bun over pnpm and Alchemy-first deploys. |
| `executing-plans` | Execute a written implementation plan with review checkpoints. | When handed a plan to implement | Redirects to `subagent-driven-development` if subagents are available. |
| `find-skills` | Discover and install agent skills from the open ecosystem. | "how do I do X", "find a skill for X", "is there a skill that can..." | |
| `finishing-a-development-branch` | Guide completion of dev work: merge, PR, or cleanup options. | Implementation complete, all tests pass | |
| `frontend-design` | Create distinctive, production-grade frontend interfaces. | Build web components, pages, dashboards, React components, HTML/CSS layouts | Overlaps with `ui-ux-pro-max`; see precedence note below. |
| `hl-funding-analysis` | Analyze Hyperliquid perp funding rates for carry-trade opportunities. | "find me funding harvest opportunities", "what's paying funding on HL" | Python 3, no external deps. Caches to `/tmp/hl_*`. |
| `kickoff-dm-design` | Inverted-flow design-room kickoff: Linear ticket + Slack post from a Claude Design URL. | `/kickoff-dm-design <url>`, "kick off a design room" | Manual-invocation only. Requires Linear + Slack access. |
| `neon-postgres` | Guides and best practices for Neon Serverless Postgres. | Any Neon-related question | |
| `nix-flake-organization` | Organize Nix flake repos into thin `flake/` public layer with `src/` implementation. | "organize flake outputs", "thin flake modules" | |
| `receiving-code-review` | Evaluate code review feedback with technical rigor before implementing. | When receiving review feedback | Don't blindly implement — verify first. |
| `requesting-code-review` | Dispatch code-reviewer subagent before merging. | After completing tasks or major features | |
| `repository-organization` | Organize repo layout, agent context, docs, scripts, skills, presets, and ADR placement. | "where should this go", "add an ADR", "repo structure", "organize agent context" | Pure prompt reference. Use `nix-flake-organization` for Nix flake-specific layouts. |
| `run-meeting-summary` | **Manual.** Resolve meeting artifacts from loose requests, pasted text, local files, or provider connectors; draft a company-safe Obsidian summary; require a submit/edit/discard review gate before writing. | `/run-meeting-summary import my last meeting from Granola`, "import my last one-on-one with John Doe", pasted transcript/path, MeetJamie/Jamie notes | Manual-invocation. Provider-agnostic; connector access optional. Writes only approved sanitized summaries; raw artifacts are not persisted by default. |
| `strategic-compact` | Make auto-compaction safe for autonomous multi-phase work. | OpenCode sessions with auto-compaction enabled | **Client/runtime policy doc** — not an ordinary task skill. |
| `subagent-driven-development` | Execute plan tasks via dispatched subagents with two-stage review. | Executing implementation plans with independent tasks | Prefer over `executing-plans` when subagents are available. |
| `systematic-debugging` | Structured approach to bugs, test failures, and unexpected behavior. | Any bug, test failure, or unexpected behavior | Before proposing fixes. |
| `tdd-workflow` | Legacy TDD skill — redirects to `test-driven-development`. | Writing features, fixing bugs, refactoring | **Deprecated** — use `test-driven-development` instead. |
| `test-driven-development` | TDD discipline: write test first, watch it fail, minimal code to pass. | Implementing any feature or bugfix, before writing implementation code | |
| `ui-ux-pro-max` | Comprehensive UI/UX design intelligence: 50+ styles, 161 palettes, 57 font pairings, 99 UX guidelines across 10 stacks. | Design, build, review, or improve UI/UX code | Overlaps with `frontend-design`; see precedence note below. |
| `using-superpowers` | Runtime policy: establish skill discovery and invocation protocol at conversation start. | Start of any conversation (automatic) | **Client/runtime policy doc** — not an ordinary task skill. See note below. |
| `verification-before-completion` | Run verification commands and confirm output before claiming work is done. | About to claim work is complete, fixed, or passing | Evidence before assertions. |
| `vercel-react-best-practices` | React/Next.js performance optimization guidelines from Vercel Engineering. | Writing, reviewing, or refactoring React/Next.js code | More specific than `coding-standards` for React perf. |
| `writing-plans` | Write comprehensive implementation plans before touching code. | Have a spec or requirements for a multi-step task | |
| `writing-skills` | TDD applied to process documentation — create, edit, or verify skills. | Creating, editing, or verifying skills before deployment | |

## Overlap & precedence notes

### `tdd-workflow` → `test-driven-development`
`tdd-workflow` is a legacy entry. Use `test-driven-development` for all new work. `tdd-workflow` is retained for backward compatibility with a redirect note in its description and body.

### `browser-use` vs `agent-browser`
Both provide browser automation. `browser-use` uses a Python CLI with persistent sessions; `agent-browser` uses Chrome/Chromium via CDP directly. Prefer `browser-use` for Python-centric workflows and `agent-browser` for Node.js/rust-centric workflows or when direct CDP control is needed.

### `frontend-design` vs `ui-ux-pro-max` vs `vercel-react-best-practices`
- **`frontend-design`**: Use when the primary goal is *visual design quality* — distinctive aesthetics, avoiding generic AI look.
- **`ui-ux-pro-max`**: Use when the primary goal is *design system intelligence* — structured style/palette/font/guideline selection across stacks.
- **`vercel-react-best-practices`**: Use when the primary goal is *React/Next.js performance* — bundle size, waterfalls, re-renders.
- When both design and performance matter, apply `frontend-design` or `ui-ux-pro-max` first, then `vercel-react-best-practices` as a review pass.

### `coding-standards` vs `vercel-react-best-practices`
`coding-standards` covers universal TS/JS/React/Node patterns. `vercel-react-best-practices` is a deeper, React/Next-specific performance supplement. Apply `coding-standards` broadly; layer `vercel-react-best-practices` for React perf work.

### `coding-standards` vs `effect-typescript`
`coding-standards` covers general TypeScript quality. `effect-typescript` is the deeper supplement for projects already using Effect or features where Effect's typed errors, Layers, resources, retries, tests, and Alchemy deployment conventions matter.

### `repository-organization` vs `nix-flake-organization`
`repository-organization` covers general repo layout, agent context, docs, scripts, skills, presets, and ADR placement. `nix-flake-organization` is the deeper supplement for Nix flake-specific output structure: thin `flake/` public layer and `src/` implementation. Apply `repository-organization` broadly; use `nix-flake-organization` when the task is specifically about flake layout.

## Client/runtime policy docs

`using-superpowers` and `continuous-learning` are **not ordinary task skills** that implement hooks or produce artifacts themselves. They are **runtime policy documents** consumed by the agent client (e.g., OpenCode, Claude Code) to configure session behavior:

- **`using-superpowers`**: Instructs the agent runtime to always check for and invoke relevant skills before responding. It is a *dispatch policy*, not a task implementation.
- **`continuous-learning`**: Instructs the agent runtime to extract reusable patterns at session end. It is a *learning policy*, not a task implementation.

`strategic-compact` similarly configures auto-compaction behavior for long autonomous sessions.

## How to add an entry

When you add a skill at `skills/<name>/`:

1. Pick a one-line description that overlaps with `SKILL.md` frontmatter `description` but is human-skim-friendly.
2. Add a row to the table above.
3. If the skill overlaps with an existing one, add a precedence note in the section above.
4. If the skill ships scripts that depend on environment (Python, Node, particular CLIs), note that in a "Notes" column or in a footnote.

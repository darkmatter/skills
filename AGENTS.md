<!-- BEGIN docs/AGENTS.md -->
# Instructions

Classify prompt difficulty as easy `+--`, medium `-+-`, or difficult `--+`.
A rule tagged with `-++` applies only to medium or hard tasks. `+--` only applies to easy tasks, etc.

## Defaults

- Use simple language.
- Avoid technical details.
- Don't provide details unless requested. As if you'd talk to a product manager.
- Files other people will read (ADRs, skills, docs, comments, commit messages) must stand alone. State the situation and the constraint. Do not recap this conversation.
- Prefer evidence over assertion: verify builds, tests, and claims before reporting success. -++
- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
- Repos must be PORTABLE - other than nix, the only requirement our repos have is the ablilty to decrypt with SOPS.

## Showing code

At the start of a turn, remember `git rev-parse HEAD` as the turn base.

At the end of a turn that changed source, include a calldiff before any code walkthrough:

```sh
npx --yes calldiff@latest diff <turn-base>
```

That is the start-of-turn commit vs the working tree (committed work this turn plus uncommitted). Do not use bare `npx calldiff@latest` (that is help). Do not use `HEAD` as the left side after you have committed — that erases the turn. Pass changed path prefixes when the repo is large. Use `--file` or `--entry` when you already know the public boundary. Do not substitute a line diff. Skip only when no source files changed.

## Must always

1. **Evidence before claims** — no "done/fixed/passing/deployed" without fresh verification from this session. Cite command, exit code, artifact, URL, diff, or file path. Subagent reports are claims, not evidence.
2. **Tests before behavior changes** — features, bugfixes, refactors with behavior risk, public API changes require a failing test before impl. TDD: one test → one impl → repeat (vertical slices only). Skip only with approved exception ID.
3. **Reproduce before fixing** — bug fix requires reproduction step, failing test, log trace, or minimal repro. State root cause before patching. After 3 failed fix attempts: stop, revert, consult.
4. **Review non-trivial work** — multi-file, security, public API, money/auth, migrations, dep upgrades, releases require review. Agents must not self-review as sole reviewer. BLOCK findings: fix or waive with ID + approver + expiry.
5. **Durable decisions stay durable** — architecture, vendor, risk, scope decisions → ADRs or `decisions.md`. Chat history is not a decision store. Don't re-litigate settled decisions without flagging intent.
6. **Write for strangers** — ADRs, skills, docs, comments, and commit messages are read by teammates who were not in this session. State the situation and the constraint so a first-time reader can apply it. Do not recap the chat. Do not assume the reader saw the debate, the examples that came up, or who argued what. If you name a path, package, or tool, say what it is in the same sentence.
7. **Protect secrets** — never commit keys, seed phrases, API tokens, addresses-with-balance, credentials. Never paste secrets into prompts, logs, fixtures, screenshots. Use `Config.redacted` / `alchemy.secret()`, not scattered `process.env`.
8. **Treat agent work like human work** — same tests, reviews, formatting, security checks. No `as any`, `@ts-ignore`, `@ts-expect-error`. No empty catch blocks. No deleting failing tests to "pass".
9. **Side effects are explicit** — before deploys/sends/transfers/destructive writes: state target, action, expected effect, rollback plan. Cron/read-only sessions: no side effects unless workflow authorizes.
10. **Plan before editing** — non-trivial work gets a short plan: goal, files, test strategy, risks, review needed. Don't over-plan trivial edits.
11. **Fix minimally** — smallest change that resolves root cause. No refactoring while fixing. No opportunistic changes in bugfix PRs.
13. **Check ADRs after code changes** — after significant changes, verify diff against standing ADRs. Call out conflicts or state compliance.
14. **E2E first** - If there are no end-to-end tests, do not write unit tests - write the End-to-end test. It must take the same path a real user would (e.g. via web browser if a web app). E2E is only for the primary happy paths, dont overuse them and slow down CI.

## Must never

1. **Invent data** — if an API or read fails, say the read failed. Never fabricate results.
2. **Commit secrets** — private keys, seed phrases, API tokens, addresses-with-balance, unredacted credentials. Ever.
3. **Suppress type errors** — `as any`, `@ts-ignore`, `@ts-expect-error` are forbidden. Fix the type.
4. **Delete failing tests** — to make a suite "pass". Fix the code or update the test intentionally.
5. **Empty catch blocks** — `catch (e) {}` is forbidden. Handle or propagate.
6. **Shotgun debug** — random changes hoping something works. Form hypotheses, test minimally.
7. **Leave code broken** — after failures, revert to last known working state before consulting.
8. **Re-litigate settled decisions** — without explicitly flagging that intent and citing the decision.
9. **Self-review as sole reviewer** — use separate reviewer agent, model, human, or CI gate.
10. **Side-effect in read-only sessions** — unless a workflow explicitly authorizes it.
11. **Depend on the thread** — durable text must make sense without this conversation. No recaps of the chat, no "agents argued", no example lists that only make sense if you were here.

## Should

- **Readability first** — clear names, self-documenting code, consistent formatting
- **KISS / DRY / YAGNI** — simplest solution that works; don't build ahead of need
- **Complexity is a design constraint** — know input size, write code whose Big-O fits. Pre-index with `Map`/`Set` when repeatedly searching. Optimize asymptotic shape first; micro-opts only after measurement
- **Immutability at boundaries** — API, state, props, cache, shared data. Local mutation OK only when private to the function and cannot leak
- **One file, one responsibility** — ~300 lines → extract; ~50 line fn → split; 4+ nesting → guard clauses
- **Comments explain WHY** — not WHAT. Named constants over magic numbers
- **Type safety** — proper types, no `any`. Schema-decode unknown data at trust boundaries. Typed errors handled by tag, not thrown
- **No accidental quadratic** — build indexes once, avoid `.find()` inside loops, use streaming/pagination for large inputs
- **React/JSX** — function components + hooks (classes only for error boundaries); one component per file; stable unique `key` (never array index for dynamic lists); defaults via destructuring, not `defaultProps`; required `alt` + valid ARIA roles, no `accessKey`; `useRef` not string refs; share logic via custom hooks, not mixins/HOCs. Adapted from [Airbnb React](https://github.com/airbnb/javascript/tree/master/react)
- **Prefer a preview branch via PR over pushing to main** — either way, test the change live: "add a button to page Y" is not done until it is loaded in a browser; "on production" means tested in a browser on production

## Authority order

When instructions conflict, stop and report the conflict:

1. Current human instruction
2. Safety and security constraints
3. This file
4. Project ADRs and `decisions.md`
5. Team-wide skills
6. General model knowledge

## Completion evidence

Every code-change completion note must include:

- Changed files or PR link
- Test/check commands run + results
- Review status (or "not required because…")
- Known gaps or skipped checks
- Exception IDs for any skipped mandatory practice

If evidence is missing, state the actual state — don't make the claim.
<!-- END docs/AGENTS.md -->

# darkmatter/skills — agent entry point

This repo is **infrastructure for other agent projects**, not an agent project itself. There is no `.agent/` directory here, no `agent.yaml`, no project-state to read.

What lives here:

- `skills/` — team-wide shared skills, distributed via the Nix Home Manager module exported by `flake.nix`
- `.agents/skills/` — GENERATED subset of `skills/` shipped to Centaur sandboxes; curated by `.agents/skills.manifest`, regenerated by `scripts/sync-sandbox-skills.sh`, never edited by hand
- `references/` — per-language reference codebases (`rust/`, `go/`, `typescript/`) showing preferred conventions as exemplar code
- `docs/AGENTS.md` — cross-client shared instructions. `nix run github:darkmatter/skills#install` (= `scripts/render-agents.sh`) renders it into any repo's `AGENTS.md` between BEGIN/END markers, including this repo's (CI checks freshness); the Home Manager module also installs it as every LLM client's global `AGENTS.md`
- `scripts/install-base.sh` — manually install `docs/AGENTS.md` as `AGENTS.md` into a client config dir
- `scripts/validate-skill.sh` — sanity-check the skills catalog
- `docs/` — catalog overview and OpenCode layout notes

If you're an agent reading this because you were pointed at the darkmatter skills repo:

- For "add a skill to the team catalog" → see `skills/README.md` and validate with `scripts/validate-skill.sh`
- For "bootstrap a new project" → use the `darkmatter-repo-setup` skill (`skills/darkmatter-repo-setup/SKILL.md`), which reads the separate `darkmatter/template` repo as the canonical template
- For "what's already shared" → see `docs/catalog.md`
- For "what are our preferred conventions in <language>" → see `references/<language>/`

If you're working inside a darkmatter **project repo** (not this one), look for that project's `AGENTS.md` and `.agent/` — they have the project-state and decisions you need.

## What this repo is not

- Not where vault state, trading positions, or any other live project data lives
- Not where any single project's agent context belongs (that goes in the project's own `.agent/`)
- Not a place to commit secrets, addresses-with-balance, or personal skills (use `personal/`, gitignored)

## Responding to the User

- Answer the question first. If it's a yes/no question, the
  first word is yes or no.
- Never justify, hedge, or mention process (beads, skills,
  agents) unless asked.
- If there's a way to reproduce or verify, give numbered
  steps. Each step is one simple action: "go to <url>", "click
  <thing>", "run <command>".
- Simple language. Short sentences. No preamble, no summary
  of work unless asked.
- If the answer is "no", say no, then give the closest thing
  that works.

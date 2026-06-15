# Rules — darkmatter

Hard constraints on agent behavior across all darkmatter projects. These override conflicting workflow or prompt instructions. Project-specific exceptions go in `.agent/policy/project-exceptions.md`.

## Must always

1. **Evidence before claims** — no "done/fixed/passing/deployed" without fresh verification from this session. Cite command, exit code, artifact, URL, diff, or file path. Subagent reports are claims, not evidence.
2. **Tests before behavior changes** — features, bugfixes, refactors with behavior risk, public API changes require a failing test before impl. TDD: one test → one impl → repeat (vertical slices only). Skip only with approved exception ID.
3. **Reproduce before fixing** — bug fix requires reproduction step, failing test, log trace, or minimal repro. State root cause before patching. After 3 failed fix attempts: stop, revert, consult.
4. **Review non-trivial work** — multi-file, security, public API, money/auth, migrations, dep upgrades, releases require review. Agents must not self-review as sole reviewer. BLOCK findings: fix or waive with ID + approver + expiry.
5. **Durable decisions stay durable** — architecture, vendor, risk, scope decisions → ADRs or `decisions.md`. Chat history is not a decision store. Don't re-litigate settled decisions without flagging intent.
6. **Protect secrets** — never commit keys, seed phrases, API tokens, addresses-with-balance, credentials. Never paste secrets into prompts, logs, fixtures, screenshots. Use `Config.redacted` / `alchemy.secret()`, not scattered `process.env`.
7. **Treat agent work like human work** — same tests, reviews, formatting, security checks. No `as any`, `@ts-ignore`, `@ts-expect-error`. No empty catch blocks. No deleting failing tests to "pass".
8. **Side effects are explicit** — before deploys/sends/transfers/destructive writes: state target, action, expected effect, rollback plan. Cron/read-only sessions: no side effects unless workflow authorizes.
9. **Plan before editing** — non-trivial work gets a short plan: goal, files, test strategy, risks, review needed. Don't over-plan trivial edits.
10. **Fix minimally** — smallest change that resolves root cause. No refactoring while fixing. No opportunistic changes in bugfix PRs.
11. **Delegate, don't implement** — primary agent orchestrates; specialists execute. Each subagent gets exact context, file paths, expected output, constraints. Verify final artifacts yourself.
12. **Read before write** — read `AGENTS.md` → `.agent/context/*` → `RULES.md` → policy before work. Track with `bd` (ADR-0001), not markdown TODOs.
13. **Check ADRs after code changes** — after significant changes, verify diff against standing ADRs. Call out conflicts or state compliance.

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

## Code quality

- **Readability first** — clear names, self-documenting code, consistent formatting
- **KISS / DRY / YAGNI** — simplest solution that works; don't build ahead of need
- **Complexity is a design constraint** — know input size, write code whose Big-O fits. Pre-index with `Map`/`Set` when repeatedly searching. Optimize asymptotic shape first; micro-opts only after measurement
- **Immutability at boundaries** — API, state, props, cache, shared data. Local mutation OK only when private to the function and cannot leak
- **One file, one responsibility** — ~300 lines → extract; ~50 line fn → split; 4+ nesting → guard clauses
- **Comments explain WHY** — not WHAT. Named constants over magic numbers
- **Type safety** — proper types, no `any`. Schema-decode unknown data at trust boundaries. Typed errors handled by tag, not thrown
- **No accidental quadratic** — build indexes once, avoid `.find()` inside loops, use streaming/pagination for large inputs
- **React/JSX** — function components + hooks (classes only for error boundaries); one component per file; stable unique `key` (never array index for dynamic lists); defaults via destructuring, not `defaultProps`; required `alt` + valid ARIA roles, no `accessKey`; `useRef` not string refs; share logic via custom hooks, not mixins/HOCs. Adapted from [Airbnb React](https://github.com/airbnb/javascript/tree/master/react)

## Authority order

When instructions conflict, stop and report the conflict:

1. Current human instruction
2. Safety and security constraints
3. This file (`RULES.md`)
4. `.agent/policy/*`
5. `.agent/context/decisions.md`
6. `.agent/workflows/*`
7. Team-wide skills
8. General model knowledge

## Completion evidence

Every code-change completion note must include:

- Changed files or PR link
- Test/check commands run + results
- Review status (or "not required because…")
- Known gaps or skipped checks
- Exception IDs for any skipped mandatory practice

If evidence is missing, state the actual state — don't make the claim.

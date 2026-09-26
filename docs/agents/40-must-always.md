## Must always

1. **Evidence before claims** — no "done/fixed/passing/deployed" without fresh verification from this session. Cite command, exit code, artifact, URL, diff, or file path. Subagent reports are claims, not evidence.
2. **Verify behavior** — run existing tests through the public interface and add meaningful regression coverage for changed behavior; use test-first development when explicitly requested or required by project policy, one failing test → one implementation → repeat. Documentation edits and behavior-preserving refactors covered by existing tests need no new tests or exception ID.
3. **Reproduce before fixing** — bug fix requires reproduction step, failing test, log trace, or minimal repro. State root cause before patching. After 3 failed fix attempts: stop, revert, consult.
4. **Review non-trivial work** — multi-file, security, public API, money/auth, migrations, dep upgrades, releases require review. Agents must not self-review as sole reviewer. BLOCK findings: fix or waive with ID + approver + expiry.
5. **Durable decisions stay durable** — architecture, vendor, risk, scope decisions → ADRs or `decisions.md`. Chat history is not a decision store. Don't re-litigate settled decisions without flagging intent.
6. **Write for strangers** — ADRs, skills, docs, comments, and commit messages are read by teammates who were not in this session. State the situation and the constraint so a first-time reader can apply it. Do not recap the chat. Do not assume the reader saw the debate, the examples that came up, or who argued what. If you name a path, package, or tool, say what it is in the same sentence.
7. **Protect secrets** — never commit keys, seed phrases, API tokens, addresses-with-balance, credentials. Never paste secrets into prompts, logs, fixtures, screenshots. Use `Config.redacted` / `alchemy.secret()`, not scattered `process.env`.
8. **Treat agent work like human work** — same tests, reviews, formatting, security checks. No `as any`, `@ts-ignore`, `@ts-expect-error`. No empty catch blocks. No deleting failing tests to "pass".
9. **Side effects are explicit** — before deploys/sends/transfers/destructive writes: state target, action, expected effect, rollback plan. Cron/read-only sessions: no side effects unless workflow authorizes.
10. **Plan before editing** — non-trivial work gets a short plan: goal, files, test strategy, risks, review needed. Don't over-plan trivial edits.
11. **Fix minimally** — smallest change that resolves root cause. No refactoring while fixing. No opportunistic changes in bugfix PRs.
12. **Delegate, don't implement** — primary agent orchestrates; specialists execute. Each subagent gets exact context, file paths, expected output, constraints. Verify final artifacts yourself.
13. **Check ADRs after code changes** — after significant changes, verify diff against standing ADRs. Call out conflicts or state compliance.

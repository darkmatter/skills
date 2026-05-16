# Reference example — org-wide engineering practices

This is a reference shape for `policy/engineering-practices.md` in `darkmatter/skills`, or for `.agent/policy/engineering-practices.md` after it is stamped into a project.

Keep this file short enough that every agent can read it at session start. Put tutorials in skills; put project-specific decisions in `.agent/context/decisions.md`; put exceptions in `.agent/policy/project-exceptions.md`.

```md
# Engineering practices

These practices apply to every darkmatter project unless a narrower project policy explicitly records an exception in `.agent/policy/project-exceptions.md`.

## Authority

1. Current human instruction
2. Safety and security constraints
3. `RULES.md`
4. `.agent/policy/*`
5. `.agent/context/decisions.md`
6. `.agent/workflows/*`
7. Team-wide skills
8. General model knowledge

If two instructions conflict, stop and report the conflict instead of silently choosing.

## Non-negotiables

1. Evidence before claims.
   - Do not claim work is done, fixed, passing, deployed, or reviewed without fresh verification evidence from this session.
   - Cite the exact command, exit code, artifact, URL, diff, or file path that proves the claim.

2. Tests before behavior changes.
   - Features, bug fixes, refactors with behavior risk, and public API changes require a failing test before implementation.
   - If TDD is skipped, cite an approved exception.

3. Reproduce before fixing.
   - Bug fixes require a reproduction step, failing test, log trace, or minimal repro before patching.
   - The final note must state the root cause.

4. Review non-trivial work.
   - Multi-file changes, security-sensitive changes, public API changes, migrations, and release changes require review before merge.
   - BLOCK findings must be fixed or explicitly waived.

5. Keep durable decisions durable.
   - Architecture, vendor, risk, scope, and process decisions go in ADRs or `.agent/context/decisions.md`.
   - Chat history is not a durable decision store.

6. Protect secrets and sensitive assets.
   - Never commit private keys, seed phrases, API tokens, addresses-with-balance, customer data, or unredacted credentials.
   - Never paste secrets into prompts, screenshots, logs, fixtures, or examples.

7. Treat agent work like human work.
   - Agent-written code must pass the same tests, reviews, formatting, and security checks as human-written code.
   - Subagent success reports are not proof; verify their diff and test output independently.

8. Make side effects explicit.
   - Before deploys, sends, transfers, destructive DB changes, or external writes, state target, command/action, expected effect, and rollback or abort plan.
   - Cron/read-only sessions must not perform side effects unless a workflow explicitly authorizes them.

## Required final evidence for code changes

A completion note for a code change must include:

- Changed files or PR link
- Tests/checks run, with command and result
- Review status, if required
- Known gaps or skipped checks
- Exception IDs for any skipped mandatory practice
```

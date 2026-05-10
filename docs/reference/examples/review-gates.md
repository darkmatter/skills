# Reference example — review gates

This is a reference shape for `policy/review-gates.md` or `.agent/policy/review-gates.md`.

Use this to make review requirements explicit and auditable.

```md
# Review gates

Review is required for changes that are likely to affect correctness, security, user experience, money movement, infrastructure, or maintainability.

## Verdicts

Review output must begin with one of:

- `LGTM` — no blocking or notable issues.
- `LGTM with notes` — safe to continue, but notes should be considered.
- `BLOCK — <reason>` — do not merge or claim completion until resolved or waived.

## Required review

A review gate is required for:

- Multi-file code changes
- Public API, CLI, protocol, schema, or database changes
- Auth, permissions, secrets, wallet, signing, payment, trading, or deploy logic
- Migrations or irreversible data transformations
- Dependency upgrades that affect runtime or security
- Refactors crossing module boundaries
- Release preparation
- Any change the implementer is uncertain about

## Optional review

Review is optional for:

- Typo fixes
- Comment-only changes
- Documentation-only edits that do not describe operational procedure
- Formatting-only changes with no logic changes
- Mechanical generated output already validated by a generator

## Review evidence

The review request must include:

- Change summary
- Diff or PR link
- Requirements or plan being implemented
- Test/verification output
- Known risks or areas of uncertainty

## Handling findings

- Critical/security issues: fix before proceeding.
- Important correctness issues: fix before merge unless explicitly waived.
- Minor issues: fix if cheap, otherwise note follow-up.
- False positives: respond with evidence, not vibes.

## Waivers

A waived BLOCK finding must be recorded with:

- Finding summary
- Reason for waiver
- Approver
- Expiry or follow-up issue

Example:

`WAIVER-2026-05-10-01: BLOCK on missing load test waived by cooper for internal alpha. Follow-up: DM-123 before public launch.`

## Agent-specific review rule

Agents must not review their own work as the only reviewer. Use a separate reviewer agent, model, human reviewer, or CI/static analysis gate for independent signal.
```

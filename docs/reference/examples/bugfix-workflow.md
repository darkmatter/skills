# Reference example — bugfix workflow

This is a reference shape for `.agent/workflows/bugfix.md`.

````md
# Bugfix workflow

Use this workflow for defects, regressions, flaky behavior, failing tests, or unexpected production behavior.

## Rule

Do not patch before reproducing. A plausible theory is not a root cause.

## Gate 1 — Symptom capture

Record:

- What failed
- Expected behavior
- Actual behavior
- Error message, log line, screenshot, or failing command
- Environment where observed

## Gate 2 — Reproduction

Create one of:

- Failing test
- Minimal repro script
- Command that reliably fails
- Log query showing the failure

Evidence format:

```text
REPRO: `pnpm test src/foo.test.ts -t "handles empty input"`
Result: FAIL with `TypeError: Cannot read properties of undefined`
```
````

If reproduction is impossible, stop and report what evidence is missing.

## Gate 3 — Root cause

Before editing implementation code, state:

- Immediate cause
- Underlying cause
- Why existing tests did not catch it
- Minimal safe fix

Example:

```text
Root cause: `parseAmount` assumes `token.decimals` exists. The API omits decimals for unknown tokens, and no test covered unknown token metadata.
```

## Gate 4 — Regression test

Write or keep the failing test that captures the bug.

Run it before the fix and confirm expected failure.

## Gate 5 — Fix

Implement the smallest fix that makes the regression test pass.

Avoid opportunistic refactors unless they directly reduce the bug risk.

## Gate 6 — Verify

Run:

- Regression test
- Nearby tests
- Relevant lint/typecheck command
- Any command that originally exposed the bug

Evidence format:

```text
Regression: `pnpm test src/foo.test.ts -t "handles empty input"` → PASS
Nearby suite: `pnpm test src/foo.test.ts` → PASS, 12 tests
Typecheck: `pnpm typecheck` → PASS
```

## Gate 7 — Review

Review is required if the fix touches:

- Auth/security
- Money movement or trading
- Persistence or migrations
- Public API behavior
- More than one module

## Completion note

Include:

- Symptom
- Root cause
- Fix summary
- Regression test
- Verification results
- Review status

```

```

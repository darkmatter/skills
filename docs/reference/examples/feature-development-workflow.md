# Reference example — feature development workflow

This is a reference shape for `.agent/workflows/feature-development.md`.

````md
# Feature development workflow

Use this workflow for new features and behavior changes.

## Entry criteria

- Request is understood well enough to define acceptance criteria.
- Project context has been read.
- Change type is not a throwaway spike.

## Gate 1 — Context

Read:

- `AGENTS.md`
- `.agent/context/overview.md`
- `.agent/context/decisions.md`
- `.agent/context/conventions.md`
- `.agent/memory/known-issues.md`
- `.agent/policy/engineering-practices.md`

Output:

- One-sentence goal
- Relevant decision IDs or "none"
- Any known issue that may affect the work

## Gate 2 — Plan

Write a short plan with:

- Files likely to change
- Test strategy
- Risks / unknowns
- Verification commands
- Whether review is required

For multi-step work, save the plan under `docs/plans/YYYY-MM-DD-feature-name.md`.

## Gate 3 — RED

Add a failing test first.

Run the targeted test and confirm:

- It fails
- The failure is expected
- It fails because the feature is missing, not because of a typo or test bug

Evidence format:

```text
RED: `pnpm test src/foo.test.ts -t "does X"`
Result: FAIL, expected missing behavior assertion
```
````

## Gate 4 — GREEN

Implement the smallest change that passes the failing test.

Run the targeted test again and confirm pass.

Evidence format:

```text
GREEN: `pnpm test src/foo.test.ts -t "does X"`
Result: PASS
```

## Gate 5 — Refactor

Clean up only after GREEN.

Allowed:

- Rename for clarity
- Remove duplication
- Extract small helpers
- Improve boundaries without changing behavior

Not allowed:

- Add untested behavior
- Sneak in unrelated fixes
- Rework architecture without updating the plan

Run the targeted test after refactor.

## Gate 6 — Broader verification

Run configured checks from `agent.yaml`:

- lint
- typecheck
- relevant test suite
- build, if user-visible or release-adjacent

Record exact commands and results.

## Gate 7 — Review

If the change meets review criteria in `.agent/policy/review-gates.md`, request independent review.

Proceed only when:

- Review is `LGTM`, or
- `LGTM with notes` and notes are addressed or accepted, or
- `BLOCK` findings are fixed or explicitly waived

## Gate 8 — Completion note

Final response must include:

- Summary of behavior added
- Files changed
- Verification commands and results
- Review status
- Known gaps or follow-ups
- Exception IDs for skipped gates

```

```

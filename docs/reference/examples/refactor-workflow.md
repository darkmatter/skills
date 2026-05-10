# Reference example — refactor workflow

This is a reference shape for `.agent/workflows/refactor.md`.

```md
# Refactor workflow

Use this workflow when changing structure without intentionally changing behavior.

## Rule

A refactor must preserve behavior. If behavior changes, switch to the feature or bugfix workflow.

## Gate 1 — Define scope

Record:

- What is being improved
- Files/modules in scope
- Files/modules explicitly out of scope
- Behavior that must remain unchanged

## Gate 2 — Baseline verification

Before editing, run tests/checks that prove current behavior.

Evidence format:

```text
Baseline: `pnpm test src/pricing src/orders`
Result: PASS, 84 tests
```

If baseline is failing, either fix baseline first or record the known failure in `.agent/memory/known-issues.md` and ensure the refactor does not worsen it.

## Gate 3 — Characterization tests

If coverage is weak, add characterization tests before refactoring.

A characterization test documents current behavior, even if imperfect.

## Gate 4 — Small mechanical steps

Prefer small steps:

1. Rename
2. Move
3. Extract
4. Inline
5. Delete dead code
6. Simplify after tests are green

Run targeted tests between risky steps.

## Gate 5 — No opportunistic behavior

Do not include:

- Feature additions
- Bug fixes not covered by tests
- Dependency upgrades
- Style rewrites outside scope
- API changes hidden inside cleanup

If you find a real bug, pause and either:

- Create a separate bugfix task, or
- Switch workflows and add a regression test

## Gate 6 — Final verification

Run at least the same command as the baseline, plus configured checks from `agent.yaml`.

Evidence format:

```text
Baseline command repeated: `pnpm test src/pricing src/orders` → PASS, 84 tests
Typecheck: `pnpm typecheck` → PASS
Lint: `pnpm lint` → PASS
```

## Gate 7 — Review

Review is required for refactors that:

- Cross module boundaries
- Touch public APIs
- Delete code
- Change concurrency, caching, parsing, auth, or persistence paths

## Completion note

Include:

- Refactor goal
- Scope
- Confirmation of no intended behavior change
- Baseline and final verification
- Review status
```

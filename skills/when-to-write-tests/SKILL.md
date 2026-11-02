---
name: when-to-write-tests
description: Decide whether a new test is needed. Use before writing or requesting tests. Prefer a few tests of observable public behavior over tests of private helpers; preserve required lifecycle and regression coverage.
---

# When to write tests

Test observable behavior through the capability's interface. Apply the
**Readability and module design** rules from the shared agent instructions.
Prefer a few tests that cover real behavior over a test for every private helper.

## Default

No new test.

Smoke the changed path (run the thing). That is verification.

## TDD is explicit opt-in

TDD changes how a required test is written, not whether one is required. Use
the red/green/refactor procedure only when the user explicitly requests TDD or
the repository requires it, and then follow the invoked TDD command or
workflow. Do not silently impose TDD, manufacture a failing test, or require
test-first for ordinary behavior work merely because a test is needed.

## Write a test only when

- The user asked for one, or
- A **public observable contract** is new, changed, or has a reproduced bug that existing tests do not cover (store API, HTTP route, migration backfill, public calculation).

Choose the smallest test that exercises that contract through its interface.
For a store, use the real persistence path where practical. For a public pure
function, assert its input/output behavior directly. Test failure, ordering,
and cleanup when they are part of the contract; do not add a layer of tests
for private helpers or assertions about internal calls.

Place the test where the language toolchain skill requires. For TypeScript,
`darkmatter-ts-toolchain` owns placement: `<file>.test.ts` beside the source it
covers, with the repo-root `tests/` reserved for end-to-end tests that spawn the
real server or CLI or span packages. Do not add a per-package `test/` or
`tests/` directory. Other stacks follow their toolchain or project convention.

## Do not write a test for

- Comment / docs-only edits
- Internal helpers, encoders, or bind-list rewrites already covered by behavior tests
- "Every new function/method"
- Edges an advisory invented that are not the contract
- Refactors that keep the same public behavior (existing tests are the regression net)

## Apply repository requirements

Current user instructions and repository requirements take precedence over this
skill. Check existing coverage before adding tests; a required regression test
should reproduce the observable bug, not freeze its current implementation.
Do not invoke TDD merely because a helper was added or moved. A successful smoke
check is useful verification, but does not replace a required automated test.

## Fair example

Seed old inbound tables, apply the migration, list events, assert facts and metadata survived and the matches table is gone.

## Unfair example

A test per helper or per comment rewrite. Asserting that `saveInvoice` called
private `insertRow` rather than that the invoice was saved.

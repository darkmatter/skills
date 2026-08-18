---
name: test-driven-development
description: Use when the user asks for TDD, test-first, red-green-refactor, or an end-to-end happy-path test of a public contract. Do not use for ordinary implementation, refactors, helpers, or comment-only changes.
---

# Test-Driven Development

A few end-to-end happy-path tests of the public contract beat a pile of unit tests. This skill is opt-in: only when the user asked for TDD or a contract test.

## When to use

- The user asked for TDD, test-first, or red-green-refactor
- A public contract (HTTP, store API, migration of live rows) is new or changed and nothing covers the happy path

## When not to use

- Ordinary implementation, refactors, helpers, comment or docs edits
- "Every new function/method"
- Edges an advisory invented that are not the contract
- Existing tests already cover the public behavior

Default is no new test. Smoke the changed path. See `when-to-write-tests`.

## What to write

One (or a few) tests that walk the real path: input at the public boundary → through the system → observable result.

Good: seed the old inbound tables, apply the migration, list events, assert facts and metadata survived.

Bad: a test per helper, encoder, or bind-list rewrite.

Prefer real collaborators over mocks. Prefer the route/store/UI path over isolated functions. Supporting notes: [tests.md](tests.md), [mocking.md](mocking.md).

## Cycle (only when this skill applies)

1. Name the happy path in one sentence.
2. Write that one failing E2E test.
3. Write the thinnest code that makes it pass.
4. Stop. Do not add unit tests for the internals you just wrote.

Do not delete working code to restart TDD. Do not require a failing test before every production change.

## Conflicts

User instructions and `when-to-write-tests` beat this skill. If both fire, write no unit tests and at most a few E2E happy-path tests.

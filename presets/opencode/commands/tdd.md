---
description: Develop observable behavior through a test-first workflow
agent: tdd-guide
subtask: true
---

# TDD Command

Implement the following using strict test-driven development: $ARGUMENTS

## TDD Cycle (MANDATORY)

```
RED → GREEN → REFACTOR → REPEAT
```

1. **RED**: Write a failing test FIRST
2. **GREEN**: Delegate minimal implementation to `coder`
3. **REFACTOR**: Improve code while keeping tests green
4. **REPEAT**: Continue until feature complete

## Your Task

### Step 1: Define Behavior and Interfaces (SCAFFOLD)

- Define expected inputs/outputs in the test plan
- If a signature is needed, describe it for `coder`; do not edit implementation files yourself

### Step 2: Write Failing Tests (RED)

- Write tests that exercise the requested contract through its public interface
- Include the cases that contract requires, not a fixed happy-path/edge/error checklist
- Run tests - verify they FAIL

### Step 3: Delegate Implementation (GREEN)

- Task the `coder` subagent with a precise spec and pointers to the failing tests
- Do NOT write the implementation yourself — that is `coder`'s responsibility
- Wait for coder's report

### Step 4: Verify GREEN

- After coder returns, re-run the test suite
- Confirm tests PASS; if still RED, re-Task `coder` with a sharper brief or fix the test if it was wrong

### Step 5: Refactor (IMPROVE)

- If refactor is needed, delegate impl-side refactor to `coder`
- You may refactor test files yourself
- Tests must stay green throughout

### Step 6: Check Coverage

- Preserve the project's configured coverage gates.
- Inspect uncovered areas for public behavior the requested contract requires.
- Follow `when-to-write-tests` before adding a test for an uncovered area; a percentage alone is not a reason.

## Test Selection

`when-to-write-tests` owns whether a test is needed and what coverage is appropriate. This command owns only the RED → GREEN → REFACTOR sequence for the requested TDD run.

When a TDD run is explicitly requested, write the smallest test that exercises the requested public contract; use `when-to-write-tests` before adding coverage beyond that request. Apply any project-required gates; do not add unit, integration, or E2E categories merely because they are listed here.

---

**MANDATORY**: Tests must be written BEFORE implementation. Never skip the RED phase.

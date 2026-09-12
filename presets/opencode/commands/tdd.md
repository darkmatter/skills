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

- Write tests that exercise the interface
- Include happy path, edge cases, and error conditions
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
- Inspect uncovered areas for meaningful public behavior or failure risks.
- Add tests for those outcomes, not to mirror private helpers or inflate a percentage.

## Coverage Requirements

Choose tests at the public boundary that exercise the requested behavior. A single complete-operation test may cover many helpers. Use `codebase-design` for good and bad examples when available.

## Test Types to Include

- **Unit Tests**: Public deterministic behavior, when a focused test adds useful coverage
- **Edge Cases**: Empty, null, max values, boundaries
- **Error Conditions**: Invalid inputs, network failures
- **Integration Tests**: API endpoints, database operations

---

**MANDATORY**: Tests must be written BEFORE implementation. Never skip the RED phase.

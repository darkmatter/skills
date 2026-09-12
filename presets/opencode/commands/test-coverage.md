---
description: Analyze and improve test coverage
agent: tdd-guide
subtask: true
---

# Test Coverage Command

Analyze test coverage and identify gaps: $ARGUMENTS

## Your Task

1. **Check for existing coverage report** — if none found, run `npm test -- --coverage` first
2. **Analyze results** - Identify low coverage areas
3. **Prioritize gaps** - Critical code first
4. **Add meaningful tests** - For unverified observable behavior or material failure risks

## Coverage Targets

Read and preserve the project's configured coverage gates. A percentage identifies areas to inspect; it does not require a test for every uncovered line or function. Prioritize meaningful public behavior and material failure risks. Test complete operations rather than private call sequences; use `when-to-write-tests` and `codebase-design` for examples when available.

## Coverage Report Analysis

### Summary

```
File           | % Stmts | % Branch | % Funcs | % Lines
---------------|---------|----------|---------|--------
All files      |   XX    |    XX    |   XX    |   XX
```

### Low Coverage Files

[Files below a configured target, prioritized by meaningful behavior at risk]

### Uncovered Lines

[Uncovered areas and the observable outcome, if any, that needs verification]

## Test Generation

For each uncovered area with a meaningful behavior gap:

### [Observable Behavior]

**Location**: `src/path/file.ts:123`

**Behavior Gap**: [outcome or failure case not yet verified]

**Public Entry Point**: [interface used by callers]

**Suggested Tests**:

```typescript
describe("functionName", () => {
  it("should [expected behavior]", () => {
    // Test code
  });

  it("should handle [edge case]", () => {
    // Edge case test
  });
});
```

## Coverage Improvement Plan

1. **Critical** (add immediately)
   - [ ] file1.ts - Auth logic
   - [ ] file2.ts - Payment handling

2. **High** (add this sprint)
   - [ ] file3.ts - Core business logic

3. **Medium** (add when touching file)
   - [ ] file4.ts - Utilities

---

**IMPORTANT**: Coverage is a metric, not a goal. Focus on meaningful tests, not just hitting numbers.

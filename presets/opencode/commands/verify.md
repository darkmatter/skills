---
description: Run verification loop to validate implementation
agent: build-error-resolver
---

# Verify Command

Run verification loop to validate the implementation: $ARGUMENTS

## Your Task

Execute comprehensive verification (run each check and report results):

1. **Type Check**: `npx tsc --noEmit`
2. **Lint**: `npm run lint`
3. **Behavior Tests**: run the project test command for relevant public outcomes
4. **Integration Tests**: `npm run test:integration` (if available)
5. **Build**: `npm run build`
6. **Coverage Check**: Review coverage report (run with `--coverage` if needed)

## Verification Checklist

### Code Quality

- [ ] No TypeScript errors
- [ ] No lint warnings
- [ ] No console.log statements
- [ ] Related implementation stays together under its domain owner
- [ ] Public operations own ordering, failure, and completion
- [ ] Extractions hide complexity or enable useful reuse
- [ ] Configured line limits are met or have documented narrow exceptions
- [ ] Contracts have one source; execution-model conversion stays at the edge
- [ ] Comments explain reasons and invariants

### Tests

- [ ] All tests passing
- [ ] Configured project coverage gates are met
- [ ] Changed observable behavior is covered through the public interface; tests do not mirror private calls
- [ ] Edge cases covered
- [ ] Error conditions tested

### Security

- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities

### Build

- [ ] Build succeeds
- [ ] No warnings
- [ ] Bundle size acceptable

## Verification Report

### Summary

- Status: ✅ PASS / ❌ FAIL
- Score: X/Y checks passed

### Details

| Check      | Status | Notes             |
| ---------- | ------ | ----------------- |
| TypeScript | ✅/❌  | [details]         |
| Lint       | ✅/❌  | [details]         |
| Tests      | ✅/❌  | [details]         |
| Coverage   | ✅/❌  | XX% (configured project target, if any) |
| Build      | ✅/❌  | [details]         |

### Action Items

[If FAIL, list what needs to be fixed]

---

**NOTE**: Verification loop should be run before every commit and PR.

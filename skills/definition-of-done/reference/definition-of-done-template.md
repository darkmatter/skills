# Definition of Done Template

## Functional criteria

- All user-visible features work as specified.
- Required failure, ordering, and cleanup behavior is implemented. Operations
  finish their work or explicitly hand responsibility to a caller.

## Non-functional criteria

- Performance meets the defined thresholds (e.g., response time < 200 ms).
- Accessibility standards (WCAG 2.1 AA) are satisfied.
- Security considerations (input validation, auth checks) are addressed.

## Verification

Follow [when-to-write-tests](../../when-to-write-tests/SKILL.md) and the
repository's test requirements. Run the changed path and existing relevant checks.

- Add tests for uncovered public behavior when required, including reproduced
  failures and lifecycle guarantees.
- Verify through the public interface; do not add tests for every private helper.
  A public pure function can be tested directly. No coverage quota.
- Apply [codebase-design](../../codebase-design/SKILL.md): retain file limits,
  document targeted exceptions, and keep related implementation together.

## Documentation

- Public-facing documentation is updated.
- Code comments explain decisions and invariants that names alone cannot convey.
- Release notes include a summary of changes.

## Sign-off

- Product owner approves functional completeness.
- QA engineer signs off after testing.
- DevOps confirms deployment readiness.

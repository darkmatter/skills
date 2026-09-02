# Definition of Done Template

## Functional criteria

- All user-visible features work as specified.
- Edge cases and error handling are implemented.

## Non-functional criteria

- Performance meets the defined thresholds (e.g., response time < 200 ms).
- Accessibility standards (WCAG 2.1 AA) are satisfied.
- Security considerations (input validation, auth checks) are addressed.

## Verification

Default is no new test. Smoke the changed path (run the thing). See
`when-to-write-tests`.

- Write a test only if the user asked, or a public observable contract
  changed and nothing covers the happy path.
- If you write one, make it an end-to-end happy-path test of that
  contract. Do not add a unit-test layer underneath. No coverage quota.
- `test-driven-development` is opt-in: only when the user asked for TDD
  or that uncovered public-contract happy path.

## Documentation

- Public-facing documentation is updated.
- Code comments explain non-trivial sections.
- Release notes include a summary of changes.

## Sign-off

- Product owner approves functional completeness.
- QA engineer signs off after testing.
- DevOps confirms deployment readiness.

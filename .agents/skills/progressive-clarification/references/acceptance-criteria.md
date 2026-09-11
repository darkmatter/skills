# Acceptance criteria

Use only sections relevant to the requested outcome. Fill them from the request,
approved design, existing contracts, and available evidence before asking questions.
An unresolved criterion warrants a question when its answer changes the work or
how completion can be judged.

- **Observable outcome:** Who can do what, under which conditions, and what result
  demonstrates success? Include relevant failure behavior already in scope.
- **Constraints:** Preserve stated performance, accessibility, security, and
  compatibility requirements. Record a numeric threshold only when grounded in
  an agreed requirement; examples are not requirements.
- **Validation:** Name the existing check, reproducible smoke procedure, or
  observable evidence that verifies the outcome. Follow applicable test policy;
  use `when-to-write-tests` when deciding whether a new test is warranted.
- **Documentation:** Update documentation when changed behavior makes it inaccurate
  or the user requested it. Do not add release notes or comments by rote.
- **Acceptance:** Identify an owner or sign-off only when the workflow requires one.
  Distinguish delivery from human acceptance and from deployment.

For an approved filtered CSV export, criteria can be: an authorized administrator
exports the selected rows, existing authorization rules hold, and the existing
export check verifies that behavior. No new performance target is implied.

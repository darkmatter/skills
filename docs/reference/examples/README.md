# Reference examples for engineering-practice enforcement

These examples expand the proposed structure for enforcing engineering practices across agents and the team. They are reference shapes, not yet canonical policy. Copy/adapt them into `policy/`, `template/`, `.github/`, or downstream project `.agent/` directories as needed.

## Policy examples

- `engineering-practices.md` — org-wide non-negotiables: evidence before claims, TDD, review, secrets, side effects.
- `agent-practices.md` — cross-agent behavior rules: session start, skill loading, planning, delegation, communication.
- `review-gates.md` — when independent review is required and how to handle BLOCK/LGTM verdicts.
- `project-agent-policy.md` — example `.agent/policy/` layout plus `project-exceptions.md` format.

## Manifest example

- `agent-yaml-practices.md` — example `agent.yaml` with `practices`, `checks`, `gates`, and `workflows` sections.

## Workflow examples

- `feature-development-workflow.md` — context → plan → RED → GREEN → refactor → verify → review → completion.
- `bugfix-workflow.md` — symptom capture → reproduction → root cause → regression test → fix → verify.
- `refactor-workflow.md` — baseline verification, characterization tests, mechanical refactor steps, final verification.
- `release-workflow.md` — release intent, clean tree, full verification, risk check, approval, smoke test.

## Checklist examples

- `pr-checklist.md` — PR template/checklist requiring practice evidence, verification, review, and exception IDs.
- `completion-checklist.md` — final-response evidence checklist for agents before claiming done/fixed/passing.

## Enforcement examples

- `hooks.md` — provider-agnostic hook scripts for session start, policy validation, diff review, and pre-commit.
- `ci-workflows.md` — GitHub Actions examples for this repo and for stamped downstream projects.
- `validate-agent-project-script.md` — reference `scripts/validate-agent-project.sh`.
- `skill-policy-validation.md` — stricter `validate-skill.sh` enforcing skill naming policy and catalog coverage.

## Suggested promotion path

1. Copy policy examples into top-level `policy/`.
2. Copy project-local policy, workflows, checklists, hooks, and CI examples into `template/`.
3. Add the validator scripts under `scripts/`.
4. Update `scripts/new-project.sh` if needed so new template files are stamped.
5. Update `docs/new-project-guide.md` to explain policy inheritance and project exceptions.
6. Convert any example that becomes canonical from `docs/reference/examples/` into its final location.

# Reference example — PR checklist

This is a reference shape for `.github/pull_request_template.md` in the `darkmatter/template` repo, or `.agent/checklists/pr.md`.

````md
## Summary

Briefly describe what changed and why.

## Change type

- [ ] Feature
- [ ] Bugfix
- [ ] Refactor
- [ ] Docs
- [ ] Config/infrastructure
- [ ] Dependency upgrade
- [ ] Release
- [ ] Spike/prototype

## Context

- Relevant issue/Linear ticket:
- Relevant decision/ADR:
- Relevant workflow followed:

## Practice evidence

- [ ] I read `AGENTS.md` and relevant `.agent/context/*` files
- [ ] I checked `.agent/policy/project-exceptions.md` for applicable exceptions
- [ ] Changed behavior has meaningful regression coverage through the public interface
- [ ] When TDD was requested or required: failing test was observed before implementation
- [ ] For bugfix: reproduction/root cause is documented
- [ ] For refactor: baseline behavior was verified before editing
- [ ] For release/deploy: rollback path is documented

## Verification

List exact commands and results.

```text
command: <command>
result: <PASS/FAIL + short output summary>
```
````

Required checks:

- [ ] Format/check style
- [ ] Lint
- [ ] Typecheck
- [ ] Tests
- [ ] Build, if applicable
- [ ] Secret scan, if applicable
- [ ] Smoke test, if applicable

## Readability

- [ ] Related implementation stays together under its domain owner
- [ ] Public operations own their steps, ordering, failure, and completion
- [ ] Every extraction hides complexity or enables useful reuse
- [ ] Contracts have one source, and execution-model conversion stays at the edge
- [ ] Configured line limits are met or have a documented narrow exception
- [ ] Comments explain reasons; tests verify observable behavior

## Review

- [ ] Review required by `.agent/policy/review-gates.md`
- [ ] Review completed
- [ ] No BLOCK findings remain
- [ ] BLOCK findings waived with explicit waiver ID
- [ ] Review not required because:

## Risk

- User/data/security impact:
- Rollback plan:
- Known gaps:
- Follow-up issues:

## Exceptions

If any required practice was skipped, cite the exception ID.

- Exception ID:
- Practice skipped:
- Approver:
- Expiry/review date:

```

```

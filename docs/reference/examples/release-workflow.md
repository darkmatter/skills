# Reference example — release workflow

This is a reference shape for `.agent/workflows/release.md`.

```md
# Release workflow

Use this workflow for production deploys, package releases, public tags, or any irreversible external publication.

## Rule

A release is a side effect. Do not perform it from a read-only, cron, or ambiguous session.

## Gate 1 — Release intent

Record:

- Version or release identifier
- Target environment
- Commit SHA
- Changes included
- Human approver, if required

Example:

```text
Release: v1.4.0
Target: production
Commit: abc1234
Approver: cooper
```

## Gate 2 — Clean working tree

Verify:

```sh
git status --short
git rev-parse HEAD
git branch --show-current
```

Do not release from a dirty tree unless the release workflow explicitly supports generated artifacts.

## Gate 3 — Full verification

Run configured release gates from `agent.yaml`, usually:

- install
- lint
- typecheck
- full tests
- build
- secret scan
- migration dry run, if applicable

Evidence format:

```text
Lint: `pnpm lint` → PASS
Typecheck: `pnpm typecheck` → PASS
Tests: `pnpm test` → PASS, 412 tests
Build: `pnpm build` → PASS
Secrets: `gitleaks detect --source . --redact` → PASS
```

## Gate 4 — Risk check

Confirm:

- Rollback path is known
- Database migrations are reversible or backed up
- Feature flags are set as expected
- Monitoring or smoke tests are ready
- Known issues are acceptable

## Gate 5 — Review and approval

Release review is required. Include:

- Commit SHA
- Diff since previous release
- Verification evidence
- Rollback plan
- Risk notes

Do not proceed on `BLOCK`.

## Gate 6 — Execute release

State the exact command before running it.

Example:

```sh
pnpm release --target production --version v1.4.0
```

Capture output and release artifact URL/tag/deployment ID.

## Gate 7 — Smoke test

After release, verify externally observable behavior.

Examples:

```sh
curl -fsS https://api.example.com/health
pnpm test:smoke -- --target production
```

## Completion note

Include:

- Version / deployment ID / tag
- Commit SHA
- Verification results
- Smoke test results
- Rollback path
- Known issues
```

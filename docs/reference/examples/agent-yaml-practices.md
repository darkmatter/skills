# Reference example — `agent.yaml` practices, checks, and gates

This shows how to make `agent.yaml` more operational. The goal is to let humans, agents, hooks, and CI read the same contract.

```yaml
spec_version: "0.2.0"
name: "example-project"
version: 0.1.0
description: "Example darkmatter project"
author: "darkmatter"
license: proprietary

model:
  preferred: claude-opus-4-6
  fallback:
    - claude-sonnet-4-5-20250929
  constraints:
    temperature: 0.1
    max_tokens: 8192

skills:
  required:
    - darkmatter/dm-test-driven-development
    - darkmatter/dm-systematic-debugging
    - darkmatter/dm-verification-before-completion
    - darkmatter/dm-end-of-turn-review
  optional:
    - darkmatter/dm-codebase-cleanup

tools:
  allowed:
    - git
    - shell
    - filesystem
    - browser
  restricted:
    - deploy
    - production-db-write
    - external-send

checks:
  install: "pnpm install --frozen-lockfile"
  format: "pnpm format:check"
  lint: "pnpm lint"
  typecheck: "pnpm typecheck"
  test: "pnpm test"
  build: "pnpm build"
  secrets: "gitleaks detect --source . --redact"

practices:
  tdd:
    required_for:
      - feature
      - bugfix
      - behavior_change
      - public_api_change
    exceptions:
      - generated_code
      - config_only
      - docs_only
    exception_file: ".agent/policy/project-exceptions.md"
    requires_human_exception: true

  debugging:
    require_reproduction_first: true
    require_root_cause_note: true
    require_regression_test: true

  verification:
    completion_claims_require_fresh_evidence: true
    required_for_code_changes:
      - lint
      - typecheck
      - test
    required_for_release:
      - lint
      - typecheck
      - test
      - build
      - secrets
    allow_partial_verification: false

  review:
    required_for:
      - multi_file_change
      - security_sensitive_change
      - public_api_change
      - database_migration
      - dependency_upgrade
      - release
    independent_reviewer_required: true
    reviewer_model: gpt-5.5
    blocking_verdicts:
      - BLOCK

  secrets:
    forbidden:
      - private_key
      - seed_phrase
      - api_token
      - address_with_balance
      - customer_pii
    scan_required: true

  side_effects:
    require_explicit_target: true
    require_rollback_plan: true
    prohibited_in_cron: true

gates:
  pre_edit:
    - read_context
    - classify_change_type
  pre_commit:
    - format
    - lint
    - typecheck
    - test
    - secrets
  pre_pr:
    - build
    - review
    - complete_pr_checklist
  release:
    - build
    - full_test_suite
    - secrets
    - human_approval

workflows:
  feature: ".agent/workflows/feature-development.md"
  bugfix: ".agent/workflows/bugfix.md"
  refactor: ".agent/workflows/refactor.md"
  release: ".agent/workflows/release.md"

compliance:
  risk_tier: standard
  supervision:
    human_in_the_loop: conditional
    escalation_triggers:
      - confidence_below: 0.7
      - error_detected: true
  recordkeeping:
    audit_logging: true
    log_contents:
      - prompts_and_responses
      - tool_calls
      - verification_evidence
      - model_version
      - timestamps
```

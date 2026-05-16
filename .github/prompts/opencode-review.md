Review this pull request using the Darkmatter OpenCode review workflow.

Before reviewing:
- Read the repository's own `AGENTS.md` or equivalent project instructions when present.
- Apply the shared Darkmatter OpenCode preset installed at `~/.config/opencode`.
- Use the `code-reviewer` guidance from the shared OpenCode agents when applicable.
- Load and use relevant shared skills from `~/.config/opencode/skills` when their trigger conditions apply, especially review, security, testing, framework, and coding-standard skills.

Review priorities, in order:
1. Correctness bugs, regressions, data loss, race conditions, and broken edge cases.
2. Security, privacy, secret-handling, authz/authn, injection, and unsafe dependency concerns.
3. Missing or weak tests for behavior changed by the PR.
4. Maintainability issues that will make future changes materially harder.
5. Project convention mismatches that are clear from the surrounding code or instructions.

Output rules:
- Only report findings you are confident are real and actionable.
- Prefer line-specific review comments when possible.
- Include severity, impacted file/line, why it matters, and a concrete fix.
- Do not flood the PR with style nits unless they hide a correctness issue.
- If there are no blocking findings, say so and include a brief summary of what you checked.

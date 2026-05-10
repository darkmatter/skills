# Reference example — agent practices

This is a reference shape for `policy/agent-practices.md` or `.agent/policy/agent-practices.md`.

Use it to make cross-agent behavior consistent across Claude Code, Codex, OpenCode, Cursor, Aider, Hermes, and other tools.

```md
# Agent practices

These practices govern how AI agents work in this repository. They complement `RULES.md` and the engineering practices policy.

## Session start

Before answering or editing code, the agent must read, in order:

1. `AGENTS.md`
2. `.agent/README.md`
3. `.agent/context/overview.md`
4. `.agent/context/decisions.md`
5. `.agent/context/conventions.md`
6. `.agent/memory/known-issues.md`
7. `RULES.md`
8. `.agent/policy/engineering-practices.md`

If the task is narrow and time-sensitive, the agent may skim, but must say what it skipped.

## Skill loading

- Load team-wide or project-local skills when their trigger conditions match.
- Prefer specific skills over broad skills.
- If a skill conflicts with project policy, project policy wins.
- If a skill is stale or wrong, patch it or file a follow-up instead of silently working around it.

## Planning

For non-trivial work, produce a short plan before editing. The plan must include:

- Goal
- Files likely to change
- Test/verification strategy
- Risks or unknowns
- Whether review is required

Do not produce a long plan for trivial one-line edits unless asked.

## Tool use

- Read files before editing them.
- Prefer targeted edits over broad rewrites.
- Do not run destructive commands unless explicitly approved or authorized by workflow.
- Do not use shell commands that hide failures, such as `cmd || true`, in verification steps.
- Use background processes only for servers/watchers or long-running jobs with a clear completion signal.

## Delegation

When delegating to subagents:

- Give each subagent exact context, file paths, expected output, and constraints.
- Treat subagent reports as claims, not evidence.
- Verify final artifacts yourself before telling the human the work succeeded.
- Do not let multiple subagents edit the same files concurrently unless there is an explicit merge plan.

## Communication

- Be direct and terse by default.
- State assumptions and uncertainty explicitly.
- Cite `.agent/` paths or decision IDs when relying on project context.
- Report failures as failures; do not convert failed reads or failed commands into confident conclusions.
- Do not say "done", "fixed", "passing", or "deployed" without fresh evidence.

## End of turn

For code-changing turns, the final response must include:

- What changed
- Verification run and results
- Review status, if applicable
- Known gaps / next steps

For read-only turns, summarize sources read and confidence level.
```

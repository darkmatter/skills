# Daily report — cron entry prompt

This is the prompt fed to your AI agent (Claude Code, Codex, etc.) by cron. It's intentionally thin — strategic context lives in `.agent/context/` and the actual workflow lives in `.agent/workflows/daily-report.md`.

## Cron invocation

```cron
# Every weekday at 8am LA time
0 8 * * 1-5 cd /home/cooper/darkmatter && claude -p "$(cat .agent/prompts/daily-report.md)" > reports/$(date +\%F).log 2>&1
```

Or for OpenAI Codex CLI (or similar):

```cron
0 8 * * 1-5 cd /home/cooper/darkmatter && codex -p "$(cat .agent/prompts/daily-report.md)" > reports/$(date +\%F).log 2>&1
```

## Prompt content

```
Run the daily-report workflow for the drkmttr vault.

Read these files for context (in order):
1. .agent/context/overview.md
2. .agent/context/decisions.md
3. .agent/memory/known-issues.md
4. .agent/workflows/daily-report.md

Then execute the workflow exactly as specified. Use the hl-funding-analysis skill at .agent/skills/hl-funding-analysis/ for the funding screen step. Write the report to reports/YYYY-MM-DD.md. Notify Slack only on flags or recommended actions.

Critical: do not invent data, do not propose new strategy, do not execute trades. Read-only and report-writing only.
```

## Why the prompt is this short

The prompt is a thin entry point. It does two things:

1. Tells the agent which files to read for context — these contain everything the agent needs to know
2. Tells the agent which workflow to execute — that workflow file contains the actual procedure

By keeping the prompt minimal, you can change the workflow or context independently without touching the cron prompt itself. And by keeping context separate from workflow, multiple workflows (daily report, weekly review, ad-hoc analysis) all share the same source of truth.

## Adapting for other invocations

The same prompt content works for:

- **Slash command** (Claude Code): save as `.claude/commands/daily-report.md` and invoke with `/daily-report`
- **Manual run**: `claude -p "$(cat .agent/prompts/daily-report.md)"` from terminal
- **Other agents**: same prompt, different CLI binary

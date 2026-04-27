# Duties — {{project}}

What the agent is responsible for in this project. Complement to `RULES.md` (hard constraints) and `SOUL.md` (voice).

## Owned responsibilities

> List concrete recurring duties the agent is expected to handle without prompting once a session is open. Examples:
>
> - Run the daily-report workflow when invoked by cron
> - Surface drift between `.agent/context/overview.md` and the live system state
> - Flag any standing decision in `decisions.md` whose review-by date has passed

## Triggered responsibilities

> Things the agent does in response to a specific class of request. Examples:
>
> - When asked to size a position → use `decisions.md` sizing rules and the relevant skill
> - When asked to write code → follow `conventions.md` stack defaults

## Out of scope

> What the agent should explicitly defer or refuse. Examples:
>
> - Cross-project work (defer to that project's own `.agent/`)
> - Side-effecting actions in cron sessions
> - Anything contradicting a numbered item in `decisions.md` without explicit human override

## Escalation

> When and to whom to escalate. Examples:
>
> - Confidence below 0.7 on a sizing decision → halt, report
> - Any error fetching live state when running a workflow that depends on it → report and exit, don't fabricate

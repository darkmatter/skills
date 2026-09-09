---
name: planning
description: Use when creating, reviewing, or refining plans, making design decisions, defining acceptance criteria or a definition of done, or encountering a new planning fork during investigation, implementation, or validation. Also use when explicitly asked to stress-test a design or conduct an exhaustive interview.
---

# Planning

Use automatically whenever planning is involved; no slash command is needed.
Loading this skill does not require an interview, a formal plan, or a new approval
for trivial work. Scale the output to the next meaningful scope.

## Progressive clarification

Start with the request, prior answers, approved scope, repository instructions,
existing designs, and read-only investigation. Reuse established models, services,
and conventions. Resolve questions from that evidence before asking the user.

| Evidence now | Next action |
| --- | --- |
| Choice is clear within authorized scope and established design | Choose it and proceed; state consequential assumptions briefly. |
| An unresolved choice materially affects outcome, scope, architecture, authority, or validation | Explain the concrete fork, why it matters now, and the recommendation; ask the person who owns that decision. |
| A decision or approval is pending | Pause dependent work and continue independent authorized work. Silence is not approval. |
| The scope and design are already approved | Execute within them; retain the approval reference. Raise only new material deviations. |

Repeat this judgment as investigation, implementation, and testing reveal facts.
Do not reopen answered questions or front-load hypothetical choices. A checklist
field is planning content, not automatically a question.

For example, follow a repository's existing CSV error format without asking.
If partial cancellation turns out to require a new storage model, surface that
architectural fork before changing it and continue an independent approved task.

## Living plan and acceptance

When a reviewable plan is needed, record the next meaningful scope in the issue
or the project's established planning location. Include applicable details:
files/directories and responsibilities; libraries or dependency additions;
core models and invariants; service interfaces, dependencies and failure behavior;
main call stacks, asynchronous and error paths; acceptance criteria and validation.
Use existing knowledge rather than interviewing through every field. Refine the
plan when new evidence makes unknowns concrete.

Derive observable completion criteria from the request and existing contracts.
Use [the acceptance template](references/acceptance-criteria.md) only when useful;
omit irrelevant sections. Check existing validation first. Do not invent numeric
targets, coverage quotas, sign-offs, or new tests merely to fill a template.

## Authority and handoff

Follow the current workspace/project's ownership and approval rules, including
its exemptions. Planning does not confer implementation authority. A request to
investigate or plan alone does not authorize implementation; “use best judgment”
does not waive someone else's decision authority. Preserve approval already given
and obtain any still-required approval before dependent work. Formal plan rules
do not automatically exempt new architecture or authorize deployment, spending,
permissions, external audiences, or destructive actions.

Hand off the approved scope and approval reference, remaining decisions and their
owners, and acceptance evidence. Keep issue state consistent with applicable
workspace rules.

## Domain checks and explicit interviews

For domain terminology or code/design contradictions, read
[domain guidance](references/domain.md). Reconcile glossary, documented decisions,
and code without turning implementation details into glossary entries.

Only when the user explicitly requests exhaustive interviewing or stress-testing,
walk the design's decision tree in dependency order, one question at a time,
with a recommendation; wait for each answer before the next question. Still
investigate answerable questions and respect settled decisions and authority.
Complexity or an incomplete specification alone does not activate this mode.

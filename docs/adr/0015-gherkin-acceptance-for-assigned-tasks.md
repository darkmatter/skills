# 0015 — Assigned tasks include Gherkin acceptance scenarios

- **Status:** accepted
- **Date:** 2026-09-17
- **Deciders:** cm

## Context

Tasks assigned through Linear or GitHub issues need a shared, observable
definition of completion. A title or implementation checklist alone leaves
room for different interpretations and work that expands beyond the intended
outcome. Small, straightforward changes need a lightweight exception.

## Decision

Every Linear task and GitHub issue assigned to a person or an agent MUST
include at least one Cucumber-style acceptance scenario written in Gherkin
before implementation begins. Keep it in the issue description, or link to
the exact version of a checked-in specification from the description.

Each scenario MUST state:

- **Given:** the relevant starting state and execution environment.
- **When:** the action or event that triggers the behavior.
- **Then:** an observable result that determines whether the task succeeded.

Use concrete inputs and outcomes. Add scenarios when one does not cover the
task's agreed acceptance conditions. Implementation steps may accompany the
scenarios but do not replace them. A Gherkin specification does not require
installing Cucumber or writing automated step definitions; select appropriate
verification for the behavior and record the evidence on completion.

### Exception for trivial, mechanical tasks

A scenario MAY be omitted for a trivial, mechanical task whose expected
result is unambiguous and directly verifiable. State that result in the issue
and briefly note why the exception applies. Examples include correcting a
spelling error or a straightforward rename that preserves behavior.

Behavior changes MUST include a scenario, regardless of estimated duration.
If a mechanical task grows to include behavior changes or an ambiguous
outcome, add the scenario before continuing the expanded work.

### Scope and completion

The scenarios define the agreed outcome. Changes should be necessary to meet
that outcome. Record unrelated findings as separate tasks for later. Agree on
changes to acceptance criteria with the task owner before expanding the work.
Complete the task when its acceptance conditions have been verified and the
evidence recorded; choose additional work through a separate assignment.

### Example

```gherkin
Feature: Observe a production command

  Scenario: Show the result of an agent command
    Given an agent run has an assigned production environment
    And I have opened that run in the monitoring dashboard
    When the agent executes a command in its assigned environment
    Then the dashboard shows the command and its output
    And the dashboard shows the exit status when execution finishes
```

## Consequences

- People and agents share a concrete completion criterion before work begins.
- Review can compare observed behavior with the agreed scenario.
- Task authors spend time making inputs, environments, and outcomes explicit.
- The exception keeps trivial work lightweight while making its use visible.

## Alternatives considered

- **Prose or checklists only:** easier to write, but often mix implementation
  steps with acceptance and leave the observable result unclear.
- **Scenarios for every task without exception:** adds unnecessary overhead
  to very simple changes.
- **Mandatory executable Cucumber tests:** couples task definition to a test
  framework; Gherkin acceptance criteria can be verified through other tools.

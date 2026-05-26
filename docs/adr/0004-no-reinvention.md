# 0004 — No Reinvention

- **Status:** accepted
- **Date:** 2026-05-26
- **Deciders:** cm

## Context

Engineers regularly encounter problems that feel specific to the task at hand
but are actually general problems with established solutions: output formatting,
string escaping, structured data parsing, report generation, date handling,
protocol encoding, and so on. The temptation is to write a quick implementation
inline — it feels faster and avoids a dependency. In practice it produces a
private reimplementation of something that already exists in a better, more
battle-tested form.

Reinventions have a predictable lifecycle: they handle the 80% case, accumulate
silent failures on edge cases the author did not anticipate, and become load-
bearing before anyone notices they are incomplete. Migrating away from them
later is harder than adopting the right tool upfront.

## Decision

Before writing an implementation of something, ask whether it is already a
solved problem. If it is, use the solution that already exists.

Concretely:

1. **Prefer structured output over output parsing.** When consuming output from
   a tool, check whether the tool has a structured output mode (JSON, XML, a
   machine-readable flag) before writing a parser for its human-readable output.
   Parsing unstructured text is a last resort, not a first instinct.

2. **Search before writing.** If an implementation would exceed roughly 20
   lines, or touches a well-known domain (encoding, escaping, formatting,
   parsing, cryptography, date/time, network protocols), assume a library
   exists and spend time finding it before spending time writing the
   alternative. The threshold is a prompt to check, not a hard rule.

3. **A dependency is preferable to a private implementation of the same
   thing.** A library has tests, handles edge cases the author documented, and
   receives upstream fixes. A private reimplementation has none of that until
   someone writes it.

## Consequences

**Upside**

- The codebase does not accumulate bespoke implementations of general
  problems. The surface that needs to be understood, tested, and maintained
  stays proportional to the problems that are actually unique to the project.
- Edge cases and correctness bugs in the general problem domain are handled
  upstream, not discovered in production.
- When a better tool or library version emerges, upgrading is a dependency
  bump, not a rewrite.

**Costs**

- Evaluating libraries takes time. Sometimes the search concludes that nothing
  fits and the inline implementation was correct — that is a valid outcome.
- Dependencies carry their own risks: abandonment, licensing, supply chain.
  These must be weighed. The point is to weigh them consciously rather than
  defaulting to writing everything ourselves.
- Some environments (sandboxed agents, air-gapped CI, strict size budgets)
  constrain which dependencies are available. Those constraints are legitimate
  reasons to implement locally; they should be stated explicitly rather than
  left implicit.

## Alternatives considered

- **"Always prefer no dependencies."** Rejected. Avoiding dependencies is not
  a virtue in itself. The cost of a dependency is real but bounded; the cost
  of a private reimplementation is open-ended and grows with the codebase.
- **"Case-by-case judgement with no rule."** Already the status quo, and it
  produces inconsistent outcomes. Having a named principle makes the
  expectation explicit and gives reviewers a basis for raising the question.

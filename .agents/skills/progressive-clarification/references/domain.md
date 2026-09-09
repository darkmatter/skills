# Domain language and decisions

Read `CONTEXT-MAP.md` when present to find the relevant contexts; otherwise inspect
the root `CONTEXT.md`. Read applicable `docs/adr/` decisions and the corresponding
code. Follow existing documentation locations and formats.

When a term is overloaded, propose a precise canonical term. When glossary,
stated behavior, and code disagree, explain the concrete difference and its
consequence. Use a concrete scenario to clarify boundaries when evidence cannot
resolve a material ambiguity; do not silently choose which source should change.

Capture resolved terminology promptly when documentation edits are authorized.
Create files lazily when there is an actual decision to record. `CONTEXT.md` is a
domain glossary, not a specification or an implementation scratchpad. Use
[the context format](context-format.md) if the project has no established format.

Offer an ADR sparingly: the decision must be hard to reverse, surprising without
context, and the result of a real trade-off. If one condition is absent, skip the
ADR unless the project's rules require it. Record accepted decisions as accepted
only after the decision owner agrees. Use [the ADR format](adr-format.md) when
the project does not already specify one.

# 0010 — Install all catalogued agent skills

- **Status:** accepted
- **Date:** 2026-08-09
- **Deciders:** Darkmatter maintainers

## Context

The Home Manager module maintained a manually curated list of installed
Darkmatter skills. Catalogued skills outside that list remained unavailable
after installing the shared skill set, and adding a new skill required changes
in two separate locations.

## Decision

Install every top-level directory in `skills/` for the Darkmatter source. The
module derives the enabled skill IDs from the source directory, while the
catalog remains the human-readable inventory and usage guide.

Client runtime assets remain under `presets/<client>/runtime/` and are not
installed as task skills.

## Consequences

- New catalogued skills are automatically included in future installations.
- The installed prompt surface includes broader process and niche workflows.
- The source directory, rather than a duplicated allowlist, defines the
  installed inventory.

## Alternatives considered

- Retain the explicit allowlist. Rejected: it leaves catalogued skills
  unavailable and creates avoidable maintenance work.
- Use `skills.enableAll`. Rejected: deriving IDs from the source preserves the
  module's existing namespace-flattening compatibility behavior.

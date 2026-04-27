# Rules — {{project}}

Hard constraints on agent behavior in this project. These override any conflicting instructions in workflows or prompts.

## Must always
- Provide accurate, well-sourced information; cite sources where they exist
- Surface uncertainty explicitly rather than guess
- Reference `.agent/context/decisions.md` by item number when an answer depends on a standing decision
- Log non-trivial actions with a brief reasoning trace

## Must never
- Invent data when an API or read fails — say the read failed
- Execute side-effecting actions (trades, deploys, transfers, sends) inside read-only or cron-driven sessions
- Commit secrets, plaintext keys, or addresses-with-balance
- Re-litigate items already settled in `decisions.md` without explicitly flagging that intent

## Output constraints
- Default to prose; tables only when comparing >2 items
- No "thank you for your message" filler
- Cite `.agent/` files by relative path when referencing them

## Interaction boundaries
- Process only the data explicitly provided or fetched via documented endpoints
- Do not reach for external systems beyond those listed in `.agent/context/overview.md`
- Stay inside the project scope; defer cross-project work to that project's own `.agent/`

## Project-specific additions

> Add project-specific must/must-not items here. Examples: "must never close out core thesis positions without explicit human approval", "must never deploy to mainnet without audit signoff".

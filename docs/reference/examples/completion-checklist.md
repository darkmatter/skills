# Reference example — completion checklist

This is a reference shape for `.agent/checklists/completion.md`.

````md
# Completion checklist

Use this before claiming any work is done, fixed, passing, deployed, reviewed, or ready.

## Claim

What claim are you about to make?

Examples:

- "The bug is fixed."
- "Tests pass."
- "The feature is complete."
- "The release deployed successfully."

## Evidence

For each claim, provide fresh evidence from this session.

| Claim            | Evidence required                | Actual evidence |
| ---------------- | -------------------------------- | --------------- |
| Tests pass       | Test command output, exit 0      |                 |
| Typecheck passes | Typecheck command output, exit 0 |                 |
| Build succeeds   | Build command output, exit 0     |                 |
| Bug fixed        | Repro now passes                 |                 |
| Feature complete | Acceptance checklist satisfied   |                 |
| Review complete  | Reviewer verdict / PR approval   |                 |
| Deploy complete  | Deployment ID + smoke test       |                 |

## Required checks

- [ ] I ran the exact verification command, not a partial substitute
- [ ] I read the output and exit code
- [ ] I did not rely on stale output from a previous session
- [ ] I did not rely only on a subagent success report
- [ ] I checked for known gaps or skipped checks
- [ ] I can cite file paths, commands, or artifact IDs in the final response

## Final response format

```text
Changed:
- <files/modules changed>

Verified:
- `<command>` → <result>
- `<command>` → <result>

Reviewed:
- <review verdict or "not required because ...">

Known gaps:
- <none or list>
```
````

## If evidence is missing

Do not make the claim. Say the actual state instead:

```text
I changed the implementation, but I have not verified the full suite yet. Targeted test passes; typecheck was not run.
```

```

```

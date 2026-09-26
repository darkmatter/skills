## Showing code

At the start of a turn, remember `git rev-parse HEAD` as the turn base.

At the end of a turn that changed source, include a calldiff before any code walkthrough:

```sh
npx --yes calldiff@latest diff <turn-base>
```

That is the start-of-turn commit vs the working tree (committed work this turn plus uncommitted). Do not use bare `npx calldiff@latest` (that is help). Do not use `HEAD` as the left side after you have committed — that erases the turn. Pass changed path prefixes when the repo is large. Use `--file` or `--entry` when you already know the public boundary. Do not substitute a line diff. Skip only when no source files changed.

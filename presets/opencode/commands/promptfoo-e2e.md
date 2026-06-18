---
description: Run local real-repo prompt-test evals
agent: conductor
---

# Promptfoo Prompt-Test Command

Run the repo-local real-repo prompt-test eval suite: $ARGUMENTS

## Your Task

1. Confirm `opencode` is on PATH and has working model credentials (default
   model `litellm/gpt-oss-120b` via the LiteLLM provider). Abort if opencode
   cannot authenticate.
2. Confirm git access to `git@github.com:darkmatter/nixmac.git` and
   `git@github.com:darkmatter/nixmac-web.git`.
3. Run `npm run eval:validate` from the repository root.
4. Run `npm run test:prompt-tests` (pure diff-assertion unit tests).
5. Run `npm run eval:prompt-tests` (pre-warms clones, then runs the real
   opencode evals). This makes real model calls and network clones — it is
   local/manual only and never runs in CI.
6. Report the generated JSON/HTML artifact paths under `evals/results/`.
7. Do not commit generated reports unless the user explicitly asks.

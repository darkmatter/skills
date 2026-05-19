---
description: Run local Promptfoo E2E evals
agent: conductor
---

# Promptfoo E2E Command

Run the repo-local Promptfoo E2E eval suite: $ARGUMENTS

## Your Task

1. Confirm provider secrets are available before running paid model calls; abort if `OPENAI_API_KEY` is missing.
2. Run `npm run eval:validate` from the repository root.
3. Run `npm run eval:e2e` from the repository root.
4. Report the generated JSON/HTML artifact paths under `evals/results/`.
5. Do not commit generated reports unless the user explicitly asks.

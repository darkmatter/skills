## Must never

1. **Invent data** — if an API or read fails, say the read failed. Never fabricate results.
2. **Commit secrets** — private keys, seed phrases, API tokens, addresses-with-balance, unredacted credentials. Ever.
3. **Suppress type errors** — `as any`, `@ts-ignore`, `@ts-expect-error` are forbidden. Fix the type.
4. **Delete failing tests** — to make a suite "pass". Fix the code or update the test intentionally.
5. **Empty catch blocks** — `catch (e) {}` is forbidden. Handle or propagate.
6. **Shotgun debug** — random changes hoping something works. Form hypotheses, test minimally.
7. **Leave code broken** — after failures, revert to last known working state before consulting.
8. **Re-litigate settled decisions** — without explicitly flagging that intent and citing the decision.
9. **Self-review as sole reviewer** — use separate reviewer agent, model, human, or CI gate.
10. **Side-effect in read-only sessions** — unless a workflow explicitly authorizes it.
11. **Depend on the thread** — durable text must make sense without this conversation. No recaps of the chat, no "agents argued", no example lists that only make sense if you were here.

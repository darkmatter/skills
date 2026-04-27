---
last_updated: 2026-04-26
review_by: 2026-10-26
---

# Operating principles and conventions

## Trading principles

1. **Don't force trades.** Sitting in cash is a trade. When the screener shows no candidates above 30% APR with positive 30d PnL, deploy nothing.

2. **Resize XMR over weeks, not days.** Cooper is ~10% of OI; large size moves market against the vault. Multi-day TWAP for any change >$500K notional.

3. **Hedges on cross, speculation on isolated.** Margin mode reflects intent.

4. **Track lifetime funding paid as a real cost.** Currently ~$168K cumulative on XMR alone. Resurfacing this monthly keeps the cost visible.

5. **Solidity work, when it starts, gets dedicated focus.** Production smart contracts holding depositor funds are not part-time work. Either commit fully or hire.

## How agents should approach this project

6. **Read before answering.** Always read `.agent/context/*` before producing analysis. Skim `.agent/memory/*` for active issues.

7. **Don't propose new strategy in cron-driven sessions.** Daily reports surface state and trigger conditions. New strategy comes from interactive sessions where Cooper is paying attention.

8. **Be terse on quiet days.** No "everything is fine" reports. Notify only on changes, flags, or trigger conditions.

9. **Don't invent data.** If an API call fails, say so. Don't fabricate position data from `.agent/context/` (which is point-in-time snapshot, not live state).

10. **Reference standing decisions explicitly.** When a question's answer is in `decisions.md`, cite it: "per decisions.md #10, do not deploy harvest book unless..." This makes the reasoning auditable.

## Code and infrastructure conventions

11. **Stack defaults:** TypeScript/Effect-TS for application code, Rust for performance-critical paths, Solidity for HyperEVM, Python for one-off analysis and screeners. Nix for reproducible environments.

12. **Secrets:** sops-nix or agenix for secrets management. Never commit plaintext keys, API tokens, or addresses-with-balance.

13. **Cron jobs and recurring scripts:** Live in `scripts/`. Logs go to `reports/`. Cache files go to `/var/cache/<project>/`.

14. **API rate limits:** Hyperliquid info endpoint is generous but not infinite. Use 3 parallel workers max for batch operations. Implement exponential backoff with 429-specific handling. Cache aggressively.

15. **Documentation lives next to code.** README files in each meaningful directory. Tool scripts get a top-of-file docstring explaining usage.

## Communication conventions

16. **No "thank you for your message" filler.** Answer the question, then add context.

17. **Bullet points only when the structure is genuinely list-shaped.** Prose is the default.

18. **Format reports as markdown tables when comparing >2 items.** Otherwise prose.

19. **Surface uncertainty explicitly.** "I'm not sure" is better than confident wrongness. Qualify estimates with the assumption they depend on.

---
last_updated: 2026-04-26
review_by: 2026-07-26
---

# Standing decisions and constraints

This document captures decisions that have been made and should not be re-litigated unless explicitly revisited. New analysis should respect these unless asked to challenge them.

## Vault structure

1. **Current vault is HyperCore-legacy.** Cannot hold spot, cannot access HIP-3 markets. Migration to ERC-4626 HyperEVM vault is on roadmap but not started.

2. **Migration timeline:** 3-4 months once started; depends on Solidity hire vs. DIY decision. Audit budget required: $50-150K. Not currently in motion.

## Capital and hedging

3. **No off-Hyperliquid hedging for vault funds.** Depositor capital stays on HL. This excludes Deribit-based options strategies, off-exchange spot positions for the vault, etc.

4. **Cooper's personal leader funds can move freely.** Hedges that protect Cooper's personal balance sheet (vs. vault NAV) can use any venue.

5. **No covered call program on XMR.** Even if Deribit listed XMR options (it doesn't), covered calls cap upside on the moonshot scenario, which is the entire point of holding XMR. Funding cost is treated as thesis carry, not as something to monetize at the cost of upside.

## Position management

6. **Cooper is ~10% of XMR perp open interest on HL.** Position size is non-trivial relative to market depth.
   - Resizing must be multi-week / TWAP, not market orders.
   - Scale-out and scale-in should use maker orders, not takers.
   - 2-3% slippage on a $2M reduction is realistic.

7. **Sell rallies, buy dips on XMR.** Active style, not passive holding. Position size fluctuates within bounds.

8. **Hedges on cross margin, speculation on isolated.** Per-position margin choice should reflect intent. BTC pair short hedges XMR → cross. Shitcoin funding shorts → isolated. Random directional bets → isolated.

9. **HYPE and MON are explicit lottery tickets.** Small size, no thesis beyond "could be a 10x I'd hate to miss." Not to be added to. Not to be re-rationalized into "real" positions.

## Funding harvest strategy

10. **Tier 2 sizing only ($50K per name, max 2-3 names) until conditions warrant Tier 3.** Tier 3 ($200K per name, 4 names) requires 60%+ APR candidates with positive 30d harvest PnL — i.e., funding euphoria regime.

11. **Don't force trades.** When the screener shows no candidates above 30% APR with positive historical PnL, don't deploy. Sit in cash.

## Things explicitly under consideration but not committed

- **BTC pair short** ($4M, cross) — planned but not opened. See `work-streams.md`.
- **ZEC cash-and-carry** — blocked on legacy vault not supporting spot. Unblocks after migration.
- **XMR1 spot integration** — blocked on backing model verification. Likely synthetic; do not size against until confirmed.

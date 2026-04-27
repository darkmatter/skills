---
last_updated: 2026-04-26
update_pattern: edit-in-place; remove when resolved
---

# Known issues

Active rough edges. Update in place. Move resolved items to `lessons.md` if there's a takeaway worth keeping.

## ZK position drawdown: -62% ROE, currently TWAP-exiting

ZK position is being TWAP'd out as a deliberate exit + slippage experiment. Not a panic close. Expected to take days to weeks to fully unwind. Slippage data is being logged for vault sizing calibration on similar-liquidity names.

**Action:** None — TWAP runs to completion. Capture full fill log when done, document slippage learnings in `lessons.md`.

## XMR funding spike: ~135% APR observed late April 2026

Transient funding spike, well above 10-15% baseline. Could be (a) noise from a single large counterparty, (b) liquidation cascade aftermath, (c) genuine regime shift.

**Action:** Watch. If sustained >48h, urgency on BTC pair hedge increases. If reverts to 10-20% within a day, treat as noise.

## HYPE and MON underwater "FOMO positions"

Combined ~$1.4M notional in positions Cooper has explicitly tagged as low-conviction lottery tickets. Both currently underwater. Held under "lottery ticket" framing but easy to drift into "I should average down."

**Action:** Hold size as-is. Do not add. Re-evaluate as binary keep/close at end of Q2 2026.

## Fee tier audit pending

drkmttr has done $57M+ lifetime volume. Possibly not on the optimal HL fee tier. Verifying current tier and any builder code or aligned-collateral discounts could save $5-15K/month.

**Action:** Check fee dashboard in HL UI. If on default tier, contact HL re: volume tier upgrade.

## XMR scalp overlay is mostly taker, should be maker

Cooper is ~10% of XMR OI. Every taker fill leaves money on the table — both fees paid and spread crossed. Should be on the maker side of most fills.

**Action:** Convert scalp overlay logic to passive limit orders. Estimate net P&L impact: $5-20K/month at current volume.

## XMR scale-out ladder not yet placed

The reduce-only GTC ladder (5%/10%/15%/15%/20%/20% at $500/$750/$1200/$2000/$3500/$5500) was discussed but not placed.

**Action:** Place the ladder when next at terminal/HL UI. Confirm sizes against then-current XMR notional.

## XMR1 (HL spot XMR) backing model unverified

XMR1/USDC trades on HL spot but backing model is unconfirmed (likely synthetic, possibly Unit-style federated, possibly memecoin-style). Strategy decisions assuming "real spot XMR" are blocked on this verification.

**Action:** Identify deployer of XMR1. Check for redemption mechanism, view-key publication, custody attestation. Document findings in `decisions.md` once resolved.

## Vault state snapshot in `overview.md` is point-in-time, not live

The position table in `.agent/context/overview.md` was correct as of 2026-04-26 morning UTC. Any agent reading it for analysis should verify current state via API before acting.

**Action:** Ongoing. Daily report workflow handles this. For ad-hoc sessions, agents must pull fresh state.

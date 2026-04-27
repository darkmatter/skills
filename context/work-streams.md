---
last_updated: 2026-04-26
review_by: 2026-05-26
---

# Active work streams

Each stream has a status field and a definition-of-done. Update status when state changes.

## Stream 1: BTC pair short hedge

**Goal:** Open a $4M BTC short on cross margin to partially offset XMR long beta and capture BTC funding income.

**Status:** Planned, not yet executed.

**Sizing:** $4M short notional. Cross margin (not isolated). Scale dynamically with XMR position size — when trimming XMR, cover BTC proportionally; when adding XMR, add BTC short proportionally. Target ratio: ~60-65% of XMR notional.

**Why this number:** Full funding neutralization would require ~$30M BTC short (because BTC funding APR runs ~5x lower than XMR's). That's not feasible inside the vault. $4M is the largest size that fits margin and matches the 60% hedge ratio reasonably.

**Done when:** Position is open, ratio is documented, dynamic-rebalance rule is in operating practice.

## Stream 2: Funding harvest screener

**Goal:** Daily-runnable tool to identify HL perp markets paying high persistent funding suitable for short-side or long-side carry trades.

**Status:** Built. Running on cache. Cache lives at `/var/cache/hl/funding.json` and `/var/cache/hl/prices.json`.

**Tool:** `.agent/skills/hl-funding-analysis/scripts/funding_history.py`

**Operating cadence:** Daily sync (cron), weekly review of opportunities. Deploy capital only when Tier 2 or Tier 3 conditions are met (see `decisions.md` #10).

**Current regime:** Dead. All markets pinned at 11% APR funding cap. No deployable opportunities. Re-evaluate when screener shows 30%+ APR with positive 30d PnL.

**Done when:** Operating as background tool. Deployed Tier 2 capital at least once in a real opportunity window.

## Stream 3: New-vault migration (HyperEVM ERC-4626)

**Goal:** Build a programmable vault on HyperEVM that integrates with HyperCore via CoreWriter and read precompiles. Unlocks: spot trading, ZEC cash-and-carry, HIP-3 markets, custom strategies.

**Status:** Planning. Decision pending: hire Solidity dev vs. DIY.

**Stack:** Foundry, hyper-evm-lib (Obsidian Audits), Solady ERC4626 base, HyperEVM mainnet.

**Phases:**
- Phase 0: dev environment + first testnet deploy (1-2 weeks)
- Phase 1: MVP (deposits, bridge, trade, valuation) — 2-3 weeks
- Phase 2: hardening + tests — 2-4 weeks
- Phase 3: audit — 4-6 weeks, $50-150K
- Phase 4: mainnet + migration — 2-4 weeks

**Critical security concerns:** First-depositor inflation attack. CoreWriter actions failing silently. Pending bridge accounting. Manager key compromise. Withdrawal liquidity vs. open positions.

**Done when:** Mainnet vault holding meaningful TVL, legacy vault deprecated, depositors migrated.

## Stream 4: zkXMR (trust-minimized XMR wrap)

**Goal:** Build wrapped XMR on HyperEVM backed by ZK proof-of-reserves over Monero UTXO set. Strategically aligns with privacy thesis: vault becomes anchor LP, darkmatter becomes provider of pick-and-shovel infrastructure for the privacy DeFi market.

**Status:** Specification draft v0.1 complete. Awaiting researcher feedback.

**Spec location:** `docs/zkxmr_spec.md` (or wherever the deliverable lives in this repo)

**Next step:** Share spec with Monero researchers (Koe via `#monero-research-lab:monero.social`, also Sarang Noether, tevador) and ZK engineers (Geometry, zkSecurity, Chainlight). 2-3 week feedback cycle.

**Timeline:** 9-12 months to mainnet, $900K-1.5M budget.

**Critical dependencies:** Phase 0 benchmark prototype must validate that the circuit constraints estimated in the spec are within 2x of real. If 5x off, re-design needed.

**Done when:** Mainnet wrap operating with verifiable on-chain proofs of reserves, integrated with major HyperEVM lending markets.

## Stream 5: Vault operational hygiene

**Goal:** A handful of low-effort, high-impact operational improvements.

**Status:** In progress, partially complete.

**Items:**
- ~~Isolate ZK position~~ — superseded by TWAP exit decision
- [ ] Verify HL fee tier given $57M+ lifetime volume — possible $5-15K/month savings
- [ ] Convert XMR scalp overlay from taker to maker — given 10% of OI, should be providing liquidity
- [ ] Set up scale-out ladder GTC orders on XMR (5%/10%/15%/15%/20%/20% at $500/$750/$1200/$2000/$3500/$5500)
- [ ] Decision on HYPE/MON: hold-as-lottery (current) vs. close — re-evaluate at end of Q2 2026

**Done when:** Each item closed with decision documented.

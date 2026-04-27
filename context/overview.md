---
last_updated: 2026-04-26
review_by: 2026-07-26
---

# darkmatter — overview

## What this is

**darkmatter** is a trading and infrastructure operation. The active flagship product is the **drkmttr vault on Hyperliquid** — a leader-managed perp trading vault.

- Vault address: `0xc179e03922afe8fa9533d3f896338b9fb87ce0c8`
- Vault NAV: ~$5.7M
- ~83 depositors, 10% leader performance fee
- Cooper is the largest LP and the trading lead

The vault is currently **legacy-style** (HyperCore-native, not HyperEVM/ERC-4626). Migrating to a programmable HyperEVM vault is on the roadmap but not yet started.

## Active thesis

**Long privacy coins (XMR, ZEC) on the view that privacy is structurally underpriced by the market.**

- XMR market cap (~$5-6B) is argued to be 10-20x too small relative to BTC's trillion-plus
- BTC no longer dominates dark web usage; XMR does
- Thesis target: XMR mcap reaches $50-100B over 1-3 years
- Holding period: long, willing to ride drawdowns

ETH long is a separate, secondary position — not part of the privacy thesis but performing well, kept on fundamentals.

## Current book (as of last update)

| Coin | Side | Notional | Lev | Margin | Status |
|---|---|---|---|---|---|
| XMR | Long | $6.0M | 3x cross | $2.0M | Core thesis. Persistent funding bleed (~$168K paid lifetime). |
| ETH | Long | $4.3M | 4x cross | $1.1M | Performing well. Not part of privacy thesis. |
| HYPE | Long | $906K | 4x cross | $226K | "FOMO position" — small, low conviction. |
| ZEC | Long | $794K | 4x cross | $198K | Privacy thesis secondary. +65% ROE. |
| ZK | Long | $585K | 3x cross | $195K | **TWAP-exiting** as a slippage experiment. |
| MON | Long | $501K | 4x iso | $163K | "FOMO position" — small, low conviction. |

Net: 100% long, ~2.3x gross leverage, $13.1M gross notional, ~$5.7M equity.

## Cooper's role and constraints

Cooper personally:
- Operates as solo founder of darkmatter
- Trades the vault actively (~97 fills/day on average)
- Sells rallies and buys dips on the core XMR position
- Is also building Stackpanel, darkmatter trading infrastructure, and adjacent projects in parallel
- Has constraint: depositor capital cannot leave Hyperliquid; personal leader funds can move freely

## Adjacent projects relevant to vault context

- **zkXMR spec** (`docs/zkxmr_spec.md`) — research-stage design for trust-minimized XMR wrap on HyperEVM via ZK proof-of-reserves. Vault is intended anchor LP once live.
- **Stackpanel** — separate developer-tooling product, occasional cross-references but not vault-relevant for trading decisions.
- **Hetzner NixOS infrastructure** — where this repo runs; cron jobs deploy here.

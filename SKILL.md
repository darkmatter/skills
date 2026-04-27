---
name: hl-funding-analysis
description: Analyze Hyperliquid perpetual funding rates to identify carry-trade opportunities (short-harvest or long-harvest). Triggers when the user asks about funding rates, funding harvest, basis trades on HL, carry trades, or wants to scan markets for paying-funding opportunities. Also triggers when evaluating whether to open a position with funding-cost as a key consideration. Do NOT trigger for non-Hyperliquid funding questions or general perp/futures questions.
---

# HL funding analysis

This skill provides historical analysis of Hyperliquid perpetual funding rates and the tools to identify carry-trade opportunities on either side of the funding flow.

## When to use

- "Find me funding harvest opportunities" / "what's paying funding right now"
- "Should I short X for the funding" / "is the carry on Y attractive"
- "Run the funding screener" / "scan HL for funding"
- Daily/weekly recurring funding regime checks
- Sizing analysis for any position where funding cost is material to thesis
- Identifying when funding regime has shifted (normal → elevated → spike, or vice versa)

## When NOT to use

- General questions about how perp funding works (use general knowledge)
- Funding on non-HL venues (Deribit, Binance, dYdX) — different APIs and dynamics
- Spot price analysis without funding component (use a different tool)

## Tools

### `scripts/funding_history.py`

Builds a local cache of HL funding rate history + daily price data for all perps, then analyzes each candidate across multiple time windows (7/30/60/90d).

The key output is **realized harvest PnL**: not just the funding rate, but what the trade would have actually returned net of price movement in the underlying.

**Usage:**

```bash
# First run: backfill 90 days of history (slow, ~10 minutes due to rate limiting)
python3 scripts/funding_history.py --deep-sync 90

# Daily: incremental update + report
python3 scripts/funding_history.py --sync
python3 scripts/funding_history.py --report --top 10

# Reports only, no network (uses cache)
python3 scripts/funding_history.py --report

# Adjust thresholds
python3 scripts/funding_history.py --report --min-apr 40 --windows 7,30
```

**Cache locations:** `/var/cache/hl/funding.json` and `/var/cache/hl/prices.json` (or `/tmp/hl_*` for development).

### Reference materials

- `reference/api-shapes.md` — HL info API endpoint shapes used by the screener
- `reference/regime-guide.md` — how to read screener output and decide on deployment

## Interpreting output

The screener produces two tables per run:

**SHORT-HARVEST** — short these names to *receive* positive funding. Profitable when funding income exceeds price drift against your short.

**LONG-HARVEST** — long these names to *receive* negative funding (shorts paying longs). Profitable when funding income exceeds any price drift against your long. Often risky because negative funding usually exists for a reason (declining asset, short conviction, etc.).

Per row, key fields are:
- **APR%** — annualized funding rate over the window
- **cum%** — cumulative funding actually paid/received over the window
- **ΔP%** — price change in the underlying over the window
- **MDD%** — max drawdown experienced during the window
- **PnL%** — what the harvest trade would have returned (funding ± price)

A high APR with negative PnL means the underlying ran against you faster than funding paid. Avoid.

## Deployment thresholds (per project decisions)

Per `.agent/context/decisions.md`:

- **Tier 1 (don't deploy):** APR < 30% OR negative 30d PnL OR funding stability < 0.5
- **Tier 2 (toy size):** $50K per name, max 2-3 names. Requires APR > 30% AND positive 30d PnL.
- **Tier 3 (full deployment):** $200K per name, max 4 names. Requires APR > 60% AND positive 30d PnL across multiple windows AND multiple candidates passing simultaneously (regime signal, not single-name signal).

## Common failure modes

1. **API 503 with "DNS cache overflow":** HL info endpoint is throttling. Reduce workers to 3, increase backoff.
2. **Empty cache after sync:** Likely killed by sandbox/timeout mid-run. Re-run; checkpointing saves progress every 20 coins.
3. **Stale cache (>24h):** Run `--sync` before `--report`.

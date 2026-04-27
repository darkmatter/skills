---
last_updated: 2026-04-26
update_pattern: append-mostly
---

# Lessons learned

Append entries here when something is learned the hard way or worth never forgetting. Don't delete entries without a strong reason — context for future decisions.

## Format

```
## YYYY-MM-DD: short title

What happened, in 1-3 sentences.

**Lesson:** what to do/not-do going forward.
```

---

## 2026-04: Funding rate is endogenous to your own size at 10% of OI

When Cooper noticed accounting for ~10% of XMR perp open interest, the implication landed: the persistent positive funding being paid is partly a function of Cooper's own long position contributing to long-side imbalance. Funding rate isn't an exogenous market parameter — it's responsive to your positioning.

**Lesson:** At meaningful market share, model funding as endogenous. Reducing position changes the rate downward, which reduces the cost of remaining position size. Don't model "save X by reducing Y" linearly when you're a significant fraction of the market.

## 2026-04: HL info API has a "DNS cache overflow" failure mode under throughput

When running parallel workers (>3) hitting the funding history endpoint, the egress proxy returned 503s with "DNS cache overflow" body. Reducing to 3 workers + adding 429-aware exponential backoff resolved it.

**Lesson:** HL info API rate limit is not strictly per-second; there's some shared-resource throttling. 3 parallel workers is the safe ceiling for sustained scraping. Always implement 429 backoff with exponential delays (2s, 4s, 8s, 16s, 32s).

## 2026-04: HL funding history endpoint returns max 500 records per call

The endpoint silently caps responses at 500 records (~20.8 days of hourly funding). For 30/60/90 day windows, must paginate via incrementing `startTime`.

**Lesson:** When pulling historical HL data, paginate with `cursor = chunk[-1].time + 1`. Stop after the last page returns < 500 records.

## 2026-04: The funding harvest "11% APR" cap is a structural feature, not a coincidence

When most HL perps show a current funding rate of exactly 11% annualized, that's the funding-rate cap kicking in. It happens when oracle-vs-mark premium exceeds threshold. Multiple names at this rate = broad mild positive funding regime, not euphoria.

**Lesson:** "Everything at 11% APR" is the signature of a quiet market, not an opportunity. Don't deploy harvest book in this regime. Wait for divergence (specific names well above 11%) before taking the strategy seriously.

## 2026-04: Covered calls are wrong-shaped for asymmetric thesis trades

Covered calls cap upside at the strike. For a position thesis-targeted at 10x (XMR), this is exactly the wrong tool. The math: a $1000-strike call collects negligible premium relative to the value being capped if the underlying actually goes to $5000.

**Lesson:** For asymmetric upside theses, do not monetize via covered calls. The right structure is: (a) hold unlevered or partially levered for funding minimization, and (b) plan a scale-out ladder to systematically take chips off the table without capping the moonshot.

## 2026-04: Wrapped XMR is fundamentally harder than wrapped BTC for cryptographic reasons

Standard wrap mechanism (custodian holds asset in publicly-queryable address; observers verify reserves) breaks for Monero because XMR addresses don't have queryable balances by design. Solving this requires either (a) trust-based federation, (b) view-key-based partial transparency, (c) ZK proof-of-reserves, or (d) atomic swap infrastructure (not a wrap). No production-quality option (a)-(c) exists today.

**Lesson:** When evaluating "XMR1" or any synthetic XMR product, the first question is always "what is the backing model and how is it verifiable." Treat synthetic-tracker tokens as having basis risk that scales with market stress, not 1:1 backed.

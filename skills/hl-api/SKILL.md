---
name: hl-api
description: Quick-reference snippets and shapes for querying the Hyperliquid info and exchange APIs. Triggers when the user wants to look up vault state, positions, fills, balances, or other HL data via API. Also triggers when writing new tooling that interacts with HL endpoints.
---

# HL API quick reference

Lightweight reference for ad-hoc HL API queries. For the funding-specific endpoints, see also `.agent/skills/hl-funding-analysis/reference/api-shapes.md`.

## Endpoints

Base URL for read operations: `https://api.hyperliquid.xyz/info`

All requests are POST with JSON body and `Content-Type: application/json`.

## Common queries

### Vault / account state

```bash
ADDR=0xc179e03922afe8fa9533d3f896338b9fb87ce0c8

# Full account state — positions, margin, account value
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"clearinghouseState\",\"user\":\"$ADDR\"}"

# NAV time series + cumulative volume
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"portfolio\",\"user\":\"$ADDR\"}"

# Recent fills (max 2000)
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"userFills\",\"user\":\"$ADDR\",\"aggregateByTime\":true}"

# Open orders
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"openOrders\",\"user\":\"$ADDR\"}"
```

### Vault-specific (when ADDR is a leader vault)

```bash
# Vault details: depositors, AUM, leader
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"vaultDetails\",\"vaultAddress\":\"$ADDR\"}"
```

### Market data

```bash
# All perp metadata + current state
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d '{"type":"metaAndAssetCtxs"}'

# Spot markets
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d '{"type":"spotMeta"}'

# Order book L2 snapshot
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d '{"type":"l2Book","coin":"BTC"}'

# Funding history (paginate via startTime)
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d '{"type":"fundingHistory","coin":"BTC","startTime":1700000000000,"endTime":1800000000000}'

# Candles
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d '{"type":"candleSnapshot","req":{"coin":"BTC","interval":"1d","startTime":1700000000000,"endTime":1800000000000}}'
```

## Key field meanings

In `clearinghouseState`:

- `marginSummary.accountValue` — total USDC equivalent equity
- `marginSummary.totalNtlPos` — gross notional across all positions
- `marginSummary.totalMarginUsed` — initial margin used
- `crossMaintenanceMarginUsed` — maintenance margin (the liquidation floor)
- `withdrawable` — USDC that can be withdrawn right now
- `assetPositions[].position.szi` — signed size in base asset units (positive = long, negative = short)
- `assetPositions[].position.cumFunding.allTime` — lifetime funding paid (positive) or received (negative) for this position
- `assetPositions[].position.leverage.{value, type}` — current leverage and `cross` vs `isolated`

## Rate limiting

- Generous on small queries; can throttle on bulk operations
- Use ≤ 3 parallel workers for sustained loops
- Implement exponential backoff on 429 (and 503 with "DNS cache overflow" body, which indicates egress proxy throttling rather than HL itself)

## Notes

- All addresses must be lowercase 0x-prefixed
- Times are in milliseconds since Unix epoch
- Sizes and prices are returned as strings; cast to float for arithmetic
- For exchange (write) operations, use the [HL Python SDK](https://github.com/hyperliquid-dex/hyperliquid-python-sdk) — direct REST is more error-prone for signing

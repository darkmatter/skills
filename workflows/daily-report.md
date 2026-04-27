---
last_updated: 2026-04-26
invocation: cron, manual via `/daily-report` slash command
---

# Daily report workflow

Produces a daily status report on the drkmttr vault. Designed for unattended cron execution. Writes a markdown report to `reports/YYYY-MM-DD.md`. Optionally pings Slack on flags or recommended actions.

## Preconditions

- `.agent/context/*` and `.agent/memory/*` are loaded (automatic in agents that read this directory)
- `.agent/skills/hl-funding-analysis/` is available
- Cache files at `/var/cache/hl/funding.json` and `/var/cache/hl/prices.json` exist (created by first run of the screener)
- `$SLACK_WEBHOOK_URL` env var set if Slack notification is desired

## Steps

### 1. Pull current vault state

```bash
ADDR=0xc179e03922afe8fa9533d3f896338b9fb87ce0c8
curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"clearinghouseState\",\"user\":\"$ADDR\"}" \
  > /tmp/vault_state.json

curl -s -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"portfolio\",\"user\":\"$ADDR\"}" \
  > /tmp/vault_portfolio.json
```

Parse and surface:
- Total NAV vs. yesterday (from `accountValueHistory`)
- Position-by-position: notional, uPnL, ROE%, lifetime funding paid
- Liquidation prices within 30% of mark — flag these
- Margin used as % of equity — flag if over 70%

### 2. Run funding screener

Use the `hl-funding-analysis` skill:

```bash
cd "$(git rev-parse --show-toplevel)" && \
  python3 .agent/skills/hl-funding-analysis/scripts/funding_history.py --sync && \
  python3 .agent/skills/hl-funding-analysis/scripts/funding_history.py --report --top 10 \
  > /tmp/funding_report.txt
```

From the report, surface only:
- Names with 30d harvest PnL > +5% AND current APR > 30% (the actually-deployable opportunities, per `decisions.md` #10-11)
- Major shifts from yesterday (any name newly appearing or disappearing from top 5)
- The XMR-specific row separately, even though excluded from harvest. Categorize: normal (10-15% APR), elevated (15-30%), spike (>30%).

### 3. Check action triggers

Compare current state against standing decisions in `.agent/context/decisions.md` and known issues in `.agent/memory/known-issues.md`. Flag:

- **XMR funding spike** sustained >24h → recommend reviewing notional. Reference `decisions.md` and the spike entry in `known-issues.md`.
- **ZK exit progress** → report size delta from yesterday (TWAP progress)
- **Position concentration** → flag any single position >50% of vault NAV
- **HYPE/MON re-evaluation** → flag if either is down >20% from current entry
- **BTC pair hedge status** → if not yet open, single-line reminder. Don't re-explain rationale.
- **Funding harvest deployable** → if any name passes Tier 2 gates, recommend with sizing per `decisions.md` #10

### 4. Produce report

Write to `reports/YYYY-MM-DD.md` with this structure:

```markdown
# Daily report — YYYY-MM-DD

## Vault snapshot
- NAV: $X.XM (Δ from yesterday: ±$XXk, ±X%)
- Gross leverage: X.Xx
- Margin used: XX% of equity
- ⚠ Flags: [any liquidation/margin concerns, or "none"]

## Positions
| Coin | Notional | uPnL | ROE | Lifetime funding | Notes |
|------|----------|------|-----|------------------|-------|

## Funding regime
- XMR APR: XX% (regime: normal/elevated/spike)
- Top 3 short-harvest candidates: [or "no deployable opportunities"]
- Top 3 long-harvest candidates: [or "no deployable opportunities"]

## Action triggers
- [Bulleted list of items needing attention, ordered by urgency]
- If nothing new: "No new triggers. Standing items: [BTC pair hedge, ZK TWAP, fee tier audit]"

## Recommended actions today
- [At most 3 specific actions, each with concrete sizing/threshold]
- If "do nothing" is right, say so explicitly with reasoning

## Notes for tomorrow
- [Anything to watch in next 24h]
```

### 5. Notify (conditional)

If the report contains any ⚠ flags or any items in "Recommended actions today" beyond "do nothing":

```bash
cat reports/$(date +%F).md | head -50 | \
  curl -X POST -H 'Content-Type: application/json' \
  -d "@-" "$SLACK_WEBHOOK_URL"
```

Otherwise: write the report and exit silently. No notification spam on quiet days.

## Critical rules for this workflow

1. **Do not invent data.** If an API call fails, say so in the report. Don't fabricate position data from `.agent/context/`.
2. **Do not propose new strategy.** This is a status report. New strategy comes from interactive sessions.
3. **Do not execute trades.** Read-only operations only.
4. **Stay terse.** Cooper sees this every day. Repetition is noise.
5. **Reference standing decisions.** When recommending an action, cite `.agent/context/decisions.md` if relevant.

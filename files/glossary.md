---
last_updated: 2026-04-26
---

# Glossary

Domain terminology used throughout this project. When a term has a project-specific meaning that differs from common usage, that meaning takes precedence.

## Trading and Hyperliquid

- **HL** — Hyperliquid. Both the exchange and the L1.
- **HyperCore** — HL's native order book layer. Where perps and spot trading actually happens.
- **HyperEVM** — HL's EVM-compatible smart contract layer. Reads HyperCore via precompiles, writes to HyperCore via CoreWriter.
- **CoreWriter** — Precompiled contract at `0x3333...3333` that lets HyperEVM contracts submit actions to HyperCore.
- **Read precompiles** — Contracts at `0x0800` and following that let HyperEVM read HyperCore state (positions, balances, prices, etc.).
- **HIP-3** — HL Improvement Proposal 3: deployer-operated perps. Custom funding, oracle, and parameters per market.
- **The vault** / **drkmttr vault** — The darkmatter trading vault on HL.
- **Legacy vault** — A HyperCore-native vault (current state). Cannot hold spot or HIP-3.
- **New vault** / **programmable vault** — An ERC-4626 vault on HyperEVM (planned state). Can hold spot, HIP-3, etc.
- **Funding** — Payment between long and short perp positions, settled hourly. Positive funding = longs pay shorts.
- **APR** in this project — Annualized hourly funding rate. `hourly_rate × 24 × 365 × 100`.
- **Notional** — Position size in dollars at mark price.
- **OI** — Open interest. Total notional of open positions in a market.
- **Funding harvest** — Trade where you take a side specifically to collect funding payments, accepting the price exposure as a cost.
- **Cash-and-carry** — Hold spot + short perp. Collect funding, eliminate price exposure. Classic basis trade.
- **Pair trade** — Long one asset, short another, expressing relative-value view.
- **TWAP** — Time-weighted average price execution. Slicing a large order across hours/days to minimize market impact.

## Risk and sizing tiers

- **Tier 1** — Don't deploy this strategy. Conditions don't warrant capital allocation.
- **Tier 2** — Toy sizing: $50K per name, max 2-3 names. Used to maintain operational readiness; not material P&L contributor.
- **Tier 3** — Full deployment: $200K per name, max 4 names. Used when conditions are clearly favorable.
- **Lottery ticket** — Position with low conviction sized small enough that a complete loss doesn't materially affect vault NAV. HYPE and MON currently fit this.

## Privacy / cryptography (zkXMR context)

- **Stealth address** — One-time address derived per-transaction from recipient's view+spend keys. Why XMR balances aren't queryable.
- **View key** — Cryptographic object that lets a party scan incoming transactions without spend authority.
- **Key image** — Per-output identifier that marks an XMR output as spent without revealing which one.
- **RingCT** — Monero's hidden-amount transaction scheme.
- **Pedersen commitment** — Cryptographic commitment scheme that's homomorphic for summation.
- **zk-POR** — Zero-knowledge proof of reserves. The thing zkXMR is built around.
- **zkXMR** — Project name for the trust-minimized XMR wrap on HyperEVM. See spec.

## People and channels

- **Cooper** — The person operating darkmatter. Default user of all agent sessions on this repo.
- **Koe** — Pseudonymous Monero researcher. Author of Seraphis/Jamtis. Reachable via `#monero-research-lab:monero.social` Matrix.
- **MRL** — Monero Research Lab. Weekly Matrix meetings, primary forum for Monero protocol research.

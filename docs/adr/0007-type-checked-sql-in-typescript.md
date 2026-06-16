# 0007 — Type-checked SQL in TypeScript

- **Status:** accepted
- **Date:** 2026-06-16
- **Deciders:** cm

## Context

Darkmatter TypeScript services often need to read and write relational data. Raw
SQL embedded in TypeScript looks concise, but it bypasses the type system at the
most important boundary in the program: the database contract.

Tagged SQL helpers with row generics, such as `sql<Row>\`...\``, do not make the
query type-safe. They only assert that the returned rows have a shape. The
compiler cannot verify table names, column names, join keys, selected fields,
nullability, casts, ordering expressions, or whether the asserted `Row` type
matches the query.

This failure mode is especially dangerous for agents. Inline SQL strings are
opaque to TypeScript, harder to refactor safely, and easy to copy across files
with stale column names or wrong row assumptions.

## Decision

TypeScript code MUST NOT embed SQL as inline strings or template literals for
application queries. This includes tagged-template SQL such as `sql<Row>\`...\``.

TypeScript code that queries relational databases MUST use a type-checked query
builder or ORM surface that derives query types from the database schema.

Preference order:

1. **Kysely** is preferred for query-heavy TypeScript because its query builder
   gives strong inference across selects, joins, aliases, references,
   nullability, and result shapes.
2. **Drizzle** is allowed when already present or when it fits the project, but
   it is not preferred for complex query-heavy code because its inference is
   weaker in important edge cases.
3. Other query builders or ORMs are acceptable only when they provide comparable
   compile-time checking of tables, columns, joins, and result shapes.

Strictly disallowed:

```ts
const chainId = asNumber(meta.chain_id);
const snapshotResult = await sql<SnapshotRow>`
  SELECT version, state, created_at
  FROM position_snapshots
  WHERE chain_id = ${chainId}
    AND token_id = ${tokenId}
    AND created_at <= ${timestamp}::timestamptz
  ORDER BY version DESC
  LIMIT 1`.execute(this.db);

const snapshot = snapshotResult.rows[0];

let currentLiquidity = "0";
let currentOwner = meta.owner_address;
let currentVersion = 0;
let replayFrom: string | null = null;

if (snapshot) {
  const state = asRecord(snapshot.state);
  currentLiquidity = String(state.liquidity ?? "0");
  currentOwner = String(state.owner ?? meta.owner_address);
  currentVersion = asNumber(snapshot.version);
  replayFrom = asTimestampString(snapshot.created_at);
} else {
  const createdEventResult = await sql<EventRow>`
    SELECT * FROM liquidity_events
    WHERE token_id = ${tokenId} AND event_type = 'position_created'
    ORDER BY timestamp ASC
    LIMIT 1`.execute(this.db);

  const createdEvent = createdEventResult.rows[0];
  if (createdEvent?.owner_address) {
    currentOwner = createdEvent.owner_address;
  }
}

const eventsQuery = replayFrom
  ? sql<EventRow>`
      SELECT * FROM liquidity_events
      WHERE token_id = ${tokenId}
        AND timestamp > ${replayFrom}::timestamptz
        AND timestamp <= ${timestamp}::timestamptz
      ORDER BY timestamp ASC, version ASC`
  : sql<EventRow>`
      SELECT * FROM liquidity_events
      WHERE token_id = ${tokenId}
        AND timestamp <= ${timestamp}::timestamptz
      ORDER BY timestamp ASC, version ASC`;
const eventsResult = await eventsQuery.execute(this.db);
```

Preferred shape:

```ts
db
  .selectFrom("positions as p")
  .leftJoin("pool_tokens as pt", (join) =>
    join
      .onRef("p.chain_id", "=", "pt.chain_id")
      .onRef("p.pool_address", "=", "pt.pool_address"),
  )
  .leftJoin("tokens as t0", (join) =>
    join
      .onRef("pt.chain_id", "=", "t0.chain_id")
      .onRef("pt.token0", "=", "t0.address"),
  )
  .leftJoin("tokens as t1", (join) =>
    join
      .onRef("pt.chain_id", "=", "t1.chain_id")
      .onRef("pt.token1", "=", "t1.address"),
  )
  .leftJoin("mv_position_pnl as pnl", (join) =>
    join
      .onRef("p.chain_id", "=", "pnl.chain_id")
      .onRef("p.token_id", "=", "pnl.token_id"),
  );
```

If a database operation cannot be expressed through the selected typed query
surface, the correct response is to improve the typed abstraction, change the
schema/query shape, or choose a stronger query tool. Do not fall back to inline
SQL in TypeScript.

Plain `.sql` files for external database tooling are outside this ADR only when
they are not embedded in TypeScript and are validated by the project's migration
or schema tooling. TypeScript migration files remain subject to this ADR.

## Consequences

**Upside**

- Query errors move from runtime to compile time: misspelled tables, stale column
  names, invalid joins, bad aliases, and wrong result assumptions fail earlier.
- Refactors become safer because table and column references participate in the
  TypeScript program instead of hiding inside strings.
- Agents get a constrained surface that makes unsafe SQL generation harder and
  review failures more objective.
- Reviewers can reject `sql\`...\`` and similar raw SQL in TypeScript without
  re-litigating whether the query is "simple enough."

**Costs**

- Projects need generated or maintained database TypeScript types.
- Some queries require a more verbose builder shape than raw SQL.
- Existing raw SQL in TypeScript must be migrated before code touching it can be
  considered compliant.
- Tool choice matters. Drizzle may be acceptable, but query-heavy code should
  prefer Kysely unless there is a project-specific reason not to.

## Alternatives considered

- **Tagged SQL templates with generic row types.** Rejected. `sql<Row>` is a type
  assertion around an opaque string, not query checking.
- **Raw SQL plus runtime schema validation.** Rejected as the default. Runtime
  validation can protect process boundaries, but it does not catch invalid table
  or column references during development.
- **Drizzle everywhere.** Rejected as the preferred standard. Drizzle is allowed,
  but its weaker inference makes it a worse default for complex relational query
  construction.
- **Case-by-case reviewer judgment.** Rejected. Inline SQL in TypeScript creates
  a repeatable safety problem, so the rule should be mechanical.

---
name: darkmatter-ts-toolchain
description: 'The darkmatter TypeScript stack, persistence, and check contract: Bun catalogs, Effect 4 versions, the effect-orpc pin, Postgres-first data, tsgo, Vitest, oxlint/oxfmt, changesets, Alchemy as the deploy choice, and required checks. Use when writing, fixing, building, or shipping TypeScript in a darkmatter repo. Follow the shared AGENTS.md "Readability and module design" section for source layout; use effect-typescript for Effect patterns and alchemy for deploy procedure.'
---

# Darkmatter TypeScript toolchain

Org-wide contract for TS repos (platform, nixmac-web, and friends). Align new
repos with the `darkmatter/template` catalog as the reference monorepo. The
stack is deliberate; substituting familiar defaults (npm, jest, wrangler, D1 as
the default database) creates a second convention and breaks CI.

This skill owns stack, dependency, persistence, and check policy. Source layout
and readability follow the "Readability and module design" section in the
repository's AGENTS.md. Sibling skills own the procedures built on this
contract: `effect-typescript` for Effect implementation,
`alchemy` for deploy workflow, and `choose-dev-entrypoints` for entrypoint
layering and ops script language.

## Package management — Bun only

- Install: `bun install`; CI uses `bun install --frozen-lockfile`. If CI fails
  with "lockfile had changes, but lockfile is frozen", the lockfile is out of
  sync with a `package.json` — fix by running `bun install` locally and
  committing `bun.lock`; never delete the lockfile to "fix" it.
- Run scripts with `bun run <script>`; execute tools with `bun x <tool>`.
- Monorepos use Turbo + workspaces (`@repo/*` packages). Add shared code to a
  workspace package, not a relative `../../` import across apps.
- Shared dependency versions live in the root `workspaces.catalog`; package
  manifests use `catalog:` or `workspace:*` instead of repeating versions.

## Preferred stack defaults

Use these defaults unless the target repo has a documented exception:

| Area | Default |
| --- | --- |
| Runtime/package manager | Bun, workspace catalogs, Node >= 24 when Node is needed |
| Effect | Effect 4, `effect-solutions`, `@effect/tsgo`, `@effect/vitest`, `@effect/platform-bun` |
| Agents | `effect/unstable/ai` / effect-agent APIs before hand-rolled agent loops or duplicated contracts |
| Typed RPC | `effect-orpc@1.0.0-effect-v4.8` plus `@orpc/server`, `@orpc/client`, `@orpc/contract`, and `@orpc/shared` at `>=1.13`; implementation guidance is in `effect-typescript` |
| Data | Postgres first. Prefer Kysely + `pg` for query-heavy TypeScript, or Effect SQL Postgres for Effect-native database services. Do not pick D1 or sqlite as the default persistence layer. |
| Deploy | Alchemy-managed infrastructure, commonly Cloudflare Workers or AWS depending on the app; procedures are in `alchemy` |
| Web/UI | Vite or vite-plus, Vitest, React 19, Tailwind v4, shadcn/Radix, and the repo's shared UI package |
| Lint/format | oxlint with Effect/tsgo rules, oxfmt for formatting |

When a repo adopts typed RPC, add the Effect 4 build and the matching oRPC
packages to the root catalog:

```json
{
  "workspaces": {
    "catalog": {
      "effect-orpc": "1.0.0-effect-v4.8",
      "@orpc/server": "^1.13.0",
      "@orpc/client": "^1.13.0",
      "@orpc/contract": "^1.13.0",
      "@orpc/shared": "^1.13.0"
    }
  }
}
```

Do not install `effect-orpc@latest`; npm `latest` is the Effect 3 line. Usage
and error shapes are in `effect-typescript`.

## Verify in this order

```bash
bun run typecheck   # tsgo -p tsconfig.json (NOT tsc)
bun run test        # vitest
bun run lint        # oxlint
bun run fmt:check   # oxfmt
```

Run the narrowest target that covers your change first (single test file,
single package), the repo-wide gates before handing off. All four must pass
on main; merge queues enforce required checks — prefer a PR over a direct
push even when your credentials technically bypass protection.

Test files are `<file>.test.ts` beside the source they cover; vitest picks
them up anywhere (`include: ["**/*.test.ts"]`). Do not add a `test/` or
`tests/` directory per package. The repo-root `tests/` exists only for
end-to-end tests that spawn the real server or span packages. This skill owns
placement; whether a test is needed follows
[when-to-write-tests](../when-to-write-tests/SKILL.md).

## Effect for meaningful I/O

Code with real I/O (network, DB, queues, retries) uses Effect — services,
Layers, typed errors, and `Config` for configuration. The named-config
procedure is in
[effect-typescript](../effect-typescript/SKILL.md#named-configuration). Plain
async/await is fine for trivial glue; don't wrap a single fetch in ceremony.

## Persistence

New application data starts on Postgres unless a project-specific decision
says otherwise. Use Kysely with `pg` when the service is query-heavy; use
Effect SQL Postgres when the repo already organizes persistence as Effect
services and Layers. D1/sqlite are valid only for narrow platform-local state,
demos, or explicit edge constraints, not as the default because they are easy
to provision.

Existing typed query tools remain supported. Parameterized SQL is allowed with
row validation and behavioral query verification; a row generic does not
validate data, and a readability change does not require an ORM migration.
[ADR-0015](../../docs/adr/0015-cohesive-modules.md) records the SQL decision.

## Deploys — Alchemy, never wrangler

Infrastructure is code in `alchemy.run.ts`; `wrangler.toml` is prohibited.
Choose Alchemy for new deployable infrastructure. Deploy stages, profiles,
secrets, build order, provider wiring, and verification steps are in the
`alchemy` skill; secret access is in `sops-secret-access`.

## Releases

Changesets are the release source of truth: user-facing changes ship with a
`.changeset/*.md`; version bumps and changelogs are generated, not hand-edited.

## Commits

Conventional Commits, subject ≤50 chars; body only when the why isn't obvious.

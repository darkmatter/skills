---
name: effect-typescript
description: 'Implementation patterns for Effect 4 TypeScript: services and Layers, typed errors, Schema, Config, effect-orpc routes, adapters, and Effect tests. Use when writing or reviewing typed Effect code, database adapters, HTTP handlers, or Effect agent code. Stack and dependency versions are in darkmatter-ts-toolchain; the shared AGENTS.md "Readability and module design" section governs module layout.'
---

# Effect TypeScript

Use Effect for application I/O so failures, dependencies, and resource lifetimes are explicit. Adapt a Promise-based driver or SDK once at its boundary; keep internal operations in Effect. Run Effects at the caller or runtime boundary that requires a Promise or starts the program. Pure transformations remain plain TypeScript.

Follow the "Readability and module design" section in the repository's
AGENTS.md. Apply it at Effect boundaries: adapt an external API once and keep
one execution model inside the module.

This skill owns Effect implementation. Use the package manager and dependency
choices from [darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md);
upstream examples use pnpm, so translate their commands. Deploy procedure is
in [alchemy](../alchemy/SKILL.md).

## Bootstrap

Consult the `effect-solutions` CLI for best-practice lookup and the
repository's pinned Effect source (or `reference/effect`) for version-matched
APIs. Install it from the repository's tooling docs, or run it without
installing via `bun x effect-solutions <command>`.

Take dependency versions from the repository catalog and the defaults in
[darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md); do not pin a
second set here. Prefer the Effect agent APIs (`effect/unstable/ai`) before
inventing an agent-loop contract.

## Guidelines

- If you need more specific information, there's a local checkout of the effect source in the reference directory.

## When to use

- Meaningful I/O is involved and the work benefits from explicit failure, dependency, resource, retry, validation, or testing boundaries.
- The code already uses Effect and you are adding or reviewing Effect code.
- You are deciding whether a TypeScript/Bun feature should use Effect.
- The task involves external APIs, databases, queues, workers, CLIs, schedules, retries, config, secrets, structured logging, runtime validation, resource cleanup, or concurrent workflows.
- You need typed domain errors rather than unstructured thrown exceptions.
- You need swappable live/test implementations through services and Layers.
- You are adding runtime services for deployable infrastructure; deploy
  procedure is in [alchemy](../alchemy/SKILL.md).

## When NOT to use

- A small one-off script can be obvious plain TypeScript: read one file, transform pure data, write one file, no retries, no injected dependencies, no long-lived resources.
- Pure functions, simple data mappers, UI-local state, or tiny glue code do not need Effect wrappers.
- A project has no Effect dependency and the feature does not benefit from typed errors, Layers, resource safety, retries, or observability.
- The team only needs a tactical fix in plain async code. Do not introduce Effect as a drive-by refactor.
- You cannot explain the service/layer/error/testing shape. Stop and design that first instead of sprinkling `Effect.runPromise` calls everywhere.

## Darkmatter Conventions

- Use the package manager commands from
  [darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md). Translate
  upstream `pnpm` examples mechanically: `pnpm test file.test.ts` becomes
  `bun test file.test.ts`, or `bun run test file.test.ts` when `test` is a
  package script.
- Prefer Bun runtime packages where relevant, such as `@effect/platform-bun`
  and `BunRuntime.runMain` for Bun entrypoints.
- Persistence choices follow
  [darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md). This skill
  owns how the adapter is implemented in Effect.
- Deployable infrastructure uses [alchemy](../alchemy/SKILL.md). Keep
  `alchemy.run.ts` and runtime services separate.

## Named configuration

Configuration comes from named config files (`config/<name>.json`) in the repo,
read through `effect/Config`. There is no selector flag: an interactive run
picks from a list with `Prompt.select`; a non-interactive run reads `APP_CONFIG`
or fails listing the available names. Environment variables and flags are
per-key overrides chained with `ConfigProvider.orElse`; secrets come from the
`.sops.json` sibling via `effect-sops`. Do not design a program's setup as a
list of flags or environment variables.
[ADR-0014](../../docs/adr/0014-named-config-files-over-flags-and-env.md)
records the rationale.

Implement the typed settings service and provider chain here. Worker bundling
and deploy-time selector wiring are in [alchemy](../alchemy/SKILL.md).

## Typed RPC with effect-orpc

Use `effect-orpc` when a service needs typed RPC procedures, a generated or
shared oRPC client contract, Effect service injection, and typed Effect errors.
Use raw Effect `HttpRouter` or Hono when the route is simple HTTP, a webhook,
static content, streaming/SSE, or a framework adapter where an RPC contract
would add ceremony without a client-facing type contract.

Take the `effect-orpc` and `@orpc/*` versions and pinning rules from
[darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md).

Prefer these upstream shapes:

- Build procedures from `eos.provide(AppLayer)` or `makeEffectORPC(runtime)`.
  Use a caller-owned `ManagedRuntime` when a scoped layer should be acquired
  once and disposed during application shutdown, such as a Postgres pool,
  telemetry SDK, or shared cache.
- Write handlers and Effect middleware with `.effect(function* (...) { ... })`
  and generator `.use(function* ({ next }) { return yield* next(...) })` so
  service requirements, spans, cancellation, and errors stay in Effect.
- Model HTTP errors with `ORPCTaggedError` and pass those classes to
  `.errors(...)` / `eoc.errors(...)`; do not duplicate the same error contract
  as unrelated thrown exceptions and response schemas.
- Use `implementEffect(contract, layerOrRuntime)` when a repo is contract-first
  and already owns an oRPC contract. Contract leaves keep the declared input,
  output, and error surface while adding `.effect(...)` handlers.
- Import `effect-orpc/node` only when Node `AsyncLocalStorage` is needed to
  preserve FiberRefs across native oRPC middleware or framework boundaries.
  Use `withFiberContext(() => next())` when request-local FiberRef state is
  created outside the oRPC pipeline and must be visible inside handlers.

## Package layout reference

See [effect-package-map.md](effect-package-map.md) for domain ownership, public package entries, adapters, workflows, tests, and runtime boundaries. It describes responsibilities rather than prescribing a file for each function or Effect export.

## Upstream Reference

Use `reference/effect` or `effect-solutions` CLI when you need current Effect source or examples instead of relying on memory:
- `reference/effect/AGENTS.md` — upstream repository rules, including pnpm validation commands, generated barrels, changesets, and `it.effect` conventions.
- `reference/effect/packages/effect/` — core library source and tests.
- `reference/effect/packages/platform-bun/` and `reference/effect/packages/platform-node/` — runtime/platform examples.
- `reference/effect/packages/vitest/` — Effect-aware Vitest helpers.

If the submodule is missing in a fresh checkout, initialize it before using local references:

```bash
git submodule update --init skills/effect-typescript/reference/effect
```

For darkmatter application work, treat the submodule as read-only and translate upstream pnpm commands to the repo's package manager. For direct upstream Effect contributions, follow `reference/effect/AGENTS.md` exactly; do not apply darkmatter Bun defaults inside the upstream repo.

## JSON Encoding & Decoding

Use `Schema.fromJsonString` to parse JSON strings and validate them with your schema in one step. This combines `JSON.parse` + schema decoding in one step, and `JSON.stringify` + schema encoding for the reverse:

```typescript
import { Effect, Schema } from "effect"

const Row = Schema.Literals(["A", "B", "C", "D", "E", "F", "G", "H"])
const Column = Schema.Literals(["1", "2", "3", "4", "5", "6", "7", "8"])

class Position extends Schema.Class<Position>("Position")({
  row: Row,
  column: Column,
}) {}

class Move extends Schema.Class<Move>("Move")({
  from: Position,
  to: Position,
}) {}

// fromJsonString combines JSON.parse + schema decoding
// MoveFromJson is a schema that takes a JSON string and returns a Move
const MoveFromJson = Schema.fromJsonString(Move)

const program = Effect.gen(function* () {
  // Parse and validate JSON string in one step
  // Use MoveFromJson (not Move) to decode from JSON string
  const jsonString = '{"from":{"row":"A","column":"1"},"to":{"row":"B","column":"2"}}'
  const move = yield* Schema.decodeUnknownEffect(MoveFromJson)(jsonString)

  yield* Effect.log("Decoded move", move)

  // Encode to JSON string in one step (typed as string)
  // Use MoveFromJson (not Move) to encode to JSON string
  const json = yield* Schema.encodeEffect(MoveFromJson)(move)
  return json
})
```

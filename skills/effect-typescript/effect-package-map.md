# Effect package layout — directory → export map

The canonical shape of a darkmatter Effect package, mapped file-by-file to the
Effect exports that belong there. Use it when scaffolding a new package or
reviewing where an import landed. Distilled from the `labs` exemplars
(`web-core`, `hl-ladder`, `compounder`) and generalized.

**Version note:** this targets the Effect v4 surface the darkmatter toolchain
pins — `Context.Service`, `effect/unstable/http`, `effect/unstable/cli`,
`effect/testing/TestClock`, `@effect/platform-bun`. On Effect v3, translate:
`Context.Service` → `Context.Tag`, `effect/unstable/http` → `@effect/platform/Http*`,
`effect/unstable/cli` → `@effect/cli`, `effect/testing/TestClock` → `effect/TestClock`.

## The layout

```
my-package/
  src/
    index.ts                 # public surface: services, layers, errors
    domain/
      error.ts                # one tagged error for the whole package
      model.ts                # value objects / DTOs (Schema)
      logic.ts                # pure decision functions
      logic.test.ts           # unit test beside the file it covers
    services/                 # ports — the only thing workflows may see
      <name>.ts               # one Context.Service per external system
      runtime-config.ts       # validated settings as a service
    adapters/
      live.ts                 # composition root for all *Live layers
      config.ts               # env -> typed config
      <system>/
        live.ts               # Context.Service implementation for one system
    workflows/                # use cases: orchestrate services, no I/O refs
      <use-case>.ts
      <use-case>.test.ts      # test beside the file it covers
    cli/                      # optional boundary: CLI app
      flags.ts
      options.ts
      commands/
      app.ts
      cli.ts
    server/                   # optional boundary: HTTP app
      routes.ts
      server.ts
  alchemy.run.ts              # optional boundary: deploy

# repo root, not per package:
tests/
  <flow>.test.ts              # end-to-end only: spawns the real server/CLI or spans packages
```

## `src/domain/` — pure. No layers, no env, no I/O.

| File | Effect exports | Why |
| --- | --- | --- |
| `error.ts` | `Data.TaggedError` | One typed error per package; everything external fails into it |
| `model.ts` | `Schema` (`Schema.Struct`, `Schema.decodeUnknownSync`) | Value objects and boundary DTOs; validation at the edge |
| `logic.ts` | none, or `Effect` as a *type only* (`Effect.Effect<A, E>`) | Pure functions; dependency-free and trivially testable |

## `src/services/` — ports

| File | Effect exports | Why |
| --- | --- | --- |
| `<name>.ts` | `Context.Service` | Declare the port + method shapes; never the implementation |
| `runtime-config.ts` | `Context.Service`, `Redacted` (type `Redacted.Redacted<T>` for keys) | Validated settings via context, so nothing downstream reads env |

```ts
// services/telemetry.ts — the port
export class Telemetry extends Context.Service<Telemetry, {
  readonly record: Effect.Effect<number>;
  readonly snapshot: Effect.Effect<Snapshot>;
}> {}
```

## `src/adapters/` — the only place I/O lives

| File | Effect exports | Why |
| --- | --- | --- |
| `config.ts` | `Config` (`Config.string/integer/boolean`, `Config.withDefault`, `Config.optional`, `Config.redacted`), `ConfigProvider` (`fromUnknown`, `fromEnv`, `orElse`, `constantCase`, `layer`), `Schema` (validate), `Layer.effect` | Named config file + env/flag overrides → typed `RuntimeConfig` service ([ADR-0014](../../docs/adr/0014-named-config-files-over-flags-and-env.md)) |
| `<system>/live.ts` | `Effect` (`Effect.tryPromise`, `Effect.gen`), `Layer.effect`, the domain `Data.TaggedError` | Wrap one external system (SDK, RPC, API) behind its port |
| `live.ts` | `Layer.mergeAll`, `Layer.provide`, `Layer.provideMerge` | Single `*ServicesLive` bundle consumers compose |

## `src/workflows/` — use cases

| File | Effect exports | Why |
| --- | --- | --- |
| `<use-case>.ts` | `Effect.gen`, `Effect.repeat` + `Schedule.spaced` (loop modes), `Option`, `Ref` (accumulation) | Reference **services only**, never adapters; scheduling lives here, not the CLI |

## `src/cli/` — optional CLI boundary

| File | Effect exports | Why |
| --- | --- | --- |
| `flags.ts` | `Flag.boolean/string/integer`, `Flag.optional`, `Flag.withDefault`, `Flag.withDescription` | Declarative flags; typed input is `Option.Option<T>` for optionals |
| `options.ts` | `Option` (`Option.getOrUndefined`, `Option.isSome`) | Pure flags → domain options; no effects |
| `commands/*.ts` | `Command.make`, `Command.withDescription` | One command per file, thin program over workflows |
| `app.ts` | `Command.withSubcommands` | The routable tree — testable without layers or network |
| `cli.ts` | `Command.run`, `Effect.provide(BunServices.layer)`, `Logger.layer` (`consolePretty`, `tracerLogger`), `BunRuntime.runMain` | The **only** place `runMain` appears |

```ts
// cli/cli.ts — the whole entrypoint
Command.run(app, { version: VERSION }).pipe(
  Effect.provide(BunServices.layer),
  Effect.provide(Logger.layer([Logger.consolePretty(), Logger.tracerLogger])),
  BunRuntime.runMain,
);
```

Routing is tested with `Command.runWith` + a `Ref` recorder + `NodeServices.layer`
(`@effect/platform-node`) — no layers, no network.

## `src/server/` — optional HTTP boundary

| File | Effect exports | Why |
| --- | --- | --- |
| `routes.ts` | `HttpRouter.use` + `Effect.fn`, `HttpServerResponse.json/.text` | Handlers stay thin: record, call service, serialize |
| `server.ts` | `HttpRouter.serve` (`Layer.mergeAll(routes, static)`), `HttpStaticServer.layer`, `BunHttpServer.layer`, `Layer.unwrap` (config-dependent layers), `Layer.provide`, `Layer.launch`, `BunRuntime.runMain` | Composition root only |

```ts
// server.ts — launch shape
const MainLive = HttpRouter.serve(Layer.mergeAll(Routes, StaticFiles)).pipe(
  Layer.provide(/* service layers */),
  Layer.provide(BunHttpServer.layer({ hostname, port })),
);
BunRuntime.runMain(
  Layer.launch(MainLive).pipe(
    // v4's runMain installs no pretty logger; provide one or logs render plain
    Effect.provide(Logger.layer([Logger.consolePretty(), Logger.tracerLogger])),
  ),
);
```

## Tests and `alchemy.run.ts`

Tests sit beside the source they cover: `logic.test.ts` next to `logic.ts`. A
package has no `test/` or `tests/` directory. The only separate test directory
is the repo-root `tests/`, reserved for end-to-end tests that spawn the real
server or CLI or span packages.

| File | Effect exports | Why |
| --- | --- | --- |
| `<file>.test.ts` (beside `<file>.ts`) | `@effect/vitest` (`it.effect`, `assert`, `describe`), `Layer.provideMerge`, `Layer.succeed` (test services), `ConfigProvider.fromUnknown` (fake env), `TestClock` + `Fiber` + `Exit` (loop tests), `NodeServices.layer`, `Command.runWith` + `Ref` (CLI routing) | Deterministic: virtual time, injected config, no network |
| `alchemy.run.ts` | `Alchemy.Stack`, `Cloudflare.providers`/`Cloudflare.state`, `Config` + `Effect` for env, `Cloudflare.DurableObject` + `DurableObjectState` (with `Effect.gen` inside) if it is a worker | Deploy boundary; reuses the package's `*ServicesLive` layers |

## Rules of thumb that make the map work

- **Dependencies point inward:** `cli`/`server` → `workflows` → `services` ←
  `adapters`. Domain imports nothing.
- **`runMain` / `BunServices` appear exactly once**, in a boundary file — never
  inside `src/` of a reusable package.
- **Config is read once**, in `adapters/config.ts`, from the named config file
  plus env/flag overrides (ADR-0014); everything after sees typed config or
  `Redacted` via context.
- **Every promise-based SDK gets one wrapper** (`Effect.tryPromise` → the
  package's tagged error), not scattered try/catch.
- **Loops are `Effect.repeat` + `Schedule`**, which is what makes `TestClock`
  tests possible.
- **Tests sit next to their source** (`foo.test.ts` beside `foo.ts`). The only
  separate test directory is the repo-root `tests/`, for end-to-end tests.

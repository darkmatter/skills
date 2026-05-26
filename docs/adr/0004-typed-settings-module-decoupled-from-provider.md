# 0004 — Application configuration lives in one typed settings module, decoupled from its provider and runtime

- **Status:** accepted
- **Date:** 2026-05-25
- **Deciders:** cm

## Context

Most darkmatter codebases need configuration: API keys, database URLs,
feature flags, environment-specific endpoints, log levels, ports. The
default ergonomic move in every language we ship — TypeScript, Rust,
Python, Go — is to read those values from `process.env` /
`std::env::var` / `os.environ` directly at the call site. That move is
cheap to write and expensive to live with.

What goes wrong when configuration access is sprinkled through the
codebase:

- **No inventory.** There is no single answer to "what configuration
  does this app accept?" To find out, you grep the whole tree for
  `process.env` and hope the grep is complete. New contributors and
  agents both pay this tax every time they touch the project.
- **Implicit dependencies.** A module that reads `process.env.STRIPE_KEY`
  three layers deep has a hidden coupling to the deployment environment
  that doesn't show up in its signature, its imports, or its tests. The
  dependency only surfaces when the variable is missing in prod.
- **No type discipline.** `process.env.PORT` is always
  `string | undefined`. Every call site re-parses, re-validates, and
  re-defaults — usually inconsistently. A missing or malformed value
  fails at first use, not at startup, which means broken deployments
  ship and crash on the first request that hits the bad path.
- **No provider swap.** Moving from `.env` files to a secret manager
  (Vault, 1Password, SOPS, SSM) to a runtime config service touches
  every file that reads env vars. The change is mechanical but
  proportional to codebase size; it should be proportional to one file.
- **Test contamination.** Tests have to mock the global environment
  (`process.env.X = '...'`) or rely on `.env.test` files. Both leak
  process-global state across tests and make parallelization unsafe.
- **Runtime coupling.** `process.env` only exists in Node-shaped
  runtimes. Bun, Deno, Cloudflare Workers, browser bundles, and
  WebAssembly hosts each have their own answer. Code that reads
  `process.env` directly silently locks the module to one runtime,
  which becomes painful the moment any of it needs to run elsewhere.

TypeScript's Effect ecosystem solves this with a three-layer
separation: `Config<T>` describes *what* configuration is needed,
`ConfigProvider` describes *where* it comes from, and the Effect
`Runtime` is *how* it executes. The same separation exists, under
different names, in other ecosystems — Pydantic Settings + sources,
Rust's `figment` + `Provider`, Go's `koanf` + providers. The pattern is
sound, and it's the one we are standardizing on.

## Decision

Every darkmatter codebase that consumes more than trivial configuration
MUST organize that configuration into a single typed settings module,
decoupled from its provider and from the host runtime.

Concretely, three rules:

### 1. One settings module per binary

A project (or each binary in a monorepo with multiple binaries) MUST
expose exactly one settings module — by convention
`src/settings.<ext>`, `src/config/settings.<ext>`, or the
language-idiomatic equivalent — that:

- Declares a single, exhaustively-typed value (struct, class, Effect
  service, etc.) listing every configuration input the app accepts.
- Is the **only** place in the codebase allowed to reference the host
  runtime's raw config primitives (`process.env`, `os.environ`,
  `std::env::var!`, `Bun.env`, `Deno.env.get`, equivalent platform
  APIs).
- Validates and parses values at process startup, fails fast on
  missing or malformed inputs, and surfaces a structured error
  identifying every problem at once (not one at a time).
- Carries strong types into every consumer. Downstream code receives a
  typed `Settings` value or service, never a raw string or
  `string | undefined`.

The constraint is load-bearing. A second file that reads
`process.env` defeats the entire purpose: there is no longer a single
answer to "what config does this app need," and no single place to
change when the provider changes.

### 2. Description, provider, and runtime are three separate layers

Configuration MUST be expressed as a *description* of needs that is
independent of *where* values come from and *how* the program executes:

- **Description layer.** A typed schema saying "this app needs a string
  `DATABASE_URL`, a redacted string `STRIPE_KEY`, an integer `PORT`
  with default `8080`, …". This is the settings module's public
  output. It MUST NOT mention env vars, file paths, or any specific
  source.
- **Provider layer.** A pluggable source that resolves the description
  into actual values: environment variables, a JSON or YAML file, a
  SOPS-encrypted bundle, a secret manager (Vault, AWS SSM, 1Password),
  a database row, a literal in-memory map for tests. Multiple providers
  MAY be composed (env wins over file wins over default). Switching
  providers MUST NOT require changes to the description layer or to
  any consumer.
- **Runtime layer.** Whatever host actually executes the program —
  Node, Bun, Deno, Cloudflare Workers, a Lambda, a Tauri app, a CLI
  spawned from a test. The runtime is where the provider is wired up;
  it is not where the description is authored.

The practical test: it MUST be possible to swap from env-var-based
config to JSON-file-based config to a remote secret store without
touching the settings module's *description* or any consuming code —
only the *provider* wiring in the runtime entrypoint changes.

### 3. Consumers receive typed settings, not the raw provider

Application code — services, handlers, repositories, jobs — MUST
receive its configuration as a typed value (or a service exposing
typed accessors). It MUST NOT reach into the provider directly, MUST
NOT re-read env vars "just for this one thing," and MUST NOT take a
`Record<string, string>` of raw config as a parameter.

Where dependency injection exists (Effect Layers, Rust trait objects,
Python protocols, Go interfaces), the settings struct or service is
injected the same way other dependencies are. Tests inject a literal
settings value; production injects one loaded from the real provider.

### Reference implementation: TypeScript with Effect

Effect's `Config` and `Schema` modules are the canonical realization
of this ADR in the languages we ship most often:

```ts
// src/settings.ts — description layer
import { Config, Effect, Redacted } from "effect"

export class Settings extends Effect.Service<Settings>()("Settings", {
  effect: Effect.gen(function* () {
    const port = yield* Config.integer("PORT").pipe(Config.withDefault(8080))
    const databaseUrl = yield* Config.string("DATABASE_URL")
    const stripeKey = yield* Config.redacted("STRIPE_KEY")
    const logLevel = yield* Config.literal("debug", "info", "warn", "error")(
      "LOG_LEVEL",
    ).pipe(Config.withDefault("info"))
    return { port, databaseUrl, stripeKey, logLevel } as const
  }),
}) {}
```

```ts
// src/main.ts — runtime layer (Node)
import { NodeRuntime } from "@effect/platform-node"
import { ConfigProvider, Effect, Layer } from "effect"
import { Settings } from "./settings"
import { program } from "./program"

const provider = ConfigProvider.fromEnv() // swap for fromJson, fromMap, etc.
const providerLayer = Layer.setConfigProvider(provider)

program.pipe(
  Effect.provide(Settings.Default),
  Effect.provide(providerLayer),
  NodeRuntime.runMain,
)
```

The description (`Settings` service) is identical regardless of where
the program runs. The provider is wired at the boundary. The runtime
choice (`NodeRuntime` vs `BunRuntime` vs a worker) is independent of
both.

Non-Effect TypeScript projects MAY use `zod`/`valibot`/`arktype` to
parse env-shaped input in a single module, exporting a typed settings
object. The discipline is the same; the machinery is lighter.

### Reference implementations: other languages

| Language     | Description                              | Provider                                                              | Runtime                |
| ------------ | ---------------------------------------- | --------------------------------------------------------------------- | ---------------------- |
| TS / Effect  | `Config` + `Schema` in a `Settings` service | `ConfigProvider.fromEnv` / `fromJson` / `fromMap` / custom                | Node / Bun / Workers   |
| TS / non-Effect | `zod` schema in `src/settings.ts`      | `process.env` (or any source) parsed once into the schema             | Node / Bun / Deno      |
| Python       | `pydantic_settings.BaseSettings` class   | `EnvSettingsSource`, `SecretsSettingsSource`, `JsonConfigSettingsSource` | CPython / uv runner    |
| Rust         | `Settings` struct with `serde::Deserialize` | `figment::Provider` (Env, Toml, Json, Json5, custom)                  | tokio / async-std      |
| Go           | `Config` struct                          | `koanf` providers (env, file, vault, consul)                          | go runtime             |

In each row, the three columns map to the three required layers. A
correct implementation in any language fills all three columns and
keeps them substitutable.

### Lint / CI enforcement

Projects SHOULD enforce the "only the settings module touches the
provider" rule mechanically:

- **TypeScript:** an ESLint rule (`no-restricted-syntax` or
  `no-restricted-properties`) forbidding `process.env`, `Bun.env`,
  `Deno.env`, etc. outside `src/settings.ts` (or the project's chosen
  path).
- **Rust:** a `clippy.toml` `disallowed-methods` entry for `std::env::var`
  and friends, with an allow-list for the settings module.
- **Python:** a `ruff` custom rule or a `grep -r 'os.environ' --exclude=settings.py`
  check in the `ci` recipe (per [ADR-0002](0002-standard-project-command-surface.md)).
- **Go:** a `golangci-lint` `forbidigo` rule on `os.Getenv` outside the
  `config` package.

The exact enforcement mechanism is up to the project; what matters is
that the constraint is checked, not just documented.

### Secrets

Secret values (API keys, tokens, passwords, signing keys) MUST be
typed as a redacted/secret wrapper in the settings module
(`Config.redacted` in Effect, `SecretStr` in Pydantic,
`secrecy::Secret<T>` in Rust). Plain `string` typing for a secret is a
defect. The wrapper exists to keep secrets out of logs and error
messages by construction; logging a redacted value MUST render as a
placeholder, never the raw value.

Storage of secrets at rest is out of scope for this ADR; see the
`sops-secret-access` skill for the darkmatter convention on encrypted
config files.

### Exceptions

1. **Trivially small programs.** A script of fewer than ~50 lines that
   reads one or two env vars and is not deployed (one-shot CLI, ad-hoc
   ETL, a `scripts/` helper) MAY read env vars directly. The threshold
   is roughly *2+ configuration inputs OR 2+ files that consume any
   config* — once either holds, the settings module is required.

2. **Generated / bundled config.** Build-time constants injected by a
   bundler (Vite `import.meta.env.VITE_*`, Webpack `DefinePlugin`,
   Next.js `NEXT_PUBLIC_*`) are not runtime configuration; they're
   compile-time substitutions. The ADR does not govern them, though
   passing them through a typed settings module is still encouraged
   for the same readability reasons.

3. **Truly dynamic config (feature flags, A/B values).** Values that
   change during the lifetime of a process — LaunchDarkly flags,
   live-tunable rate limits, etc. — do not fit the "load once at
   startup" shape. Model these as their own service (a `FeatureFlags`
   service injected like any other), not as fields on the static
   settings struct. The static settings struct MAY carry the
   *configuration* of the flags service (its endpoint, SDK key) but
   not the flag values themselves.

## Consequences

**Upside**

- **One file answers "what does this app need."** Agents and humans
  can read `src/settings.ts` and know the entire configuration
  surface. The grep is replaced by a definition.
- **Type-safe end to end.** No more `process.env.PORT!` or
  `parseInt(process.env.PORT ?? "8080")` scattered through the code.
  The settings struct carries `number`, `URL`, `Redacted<string>`,
  etc. into every consumer.
- **Fail fast.** A missing or malformed configuration value is
  detected at startup with a structured error listing every problem
  at once. Bad deployments die immediately instead of crashing on
  first traffic.
- **Provider swap is a one-file change.** Moving from `.env` to SOPS
  to a secret manager touches the runtime entrypoint, not the rest of
  the codebase.
- **Runtime portability.** Lifting a Node service to Bun or to a
  Cloudflare Worker requires changing the runtime layer and (possibly)
  the provider; the description layer and all consumers are unchanged.
- **Tests inject config directly.** No `process.env` mutation in
  tests; just construct the settings struct with the values the test
  needs. Parallel tests stop interfering with each other.
- **Secrets are typed.** A redacted wrapper prevents accidental
  logging by construction, not by reviewer vigilance.

**Costs**

- **Indirection on first use.** A consumer that needs one value still
  has to receive the settings struct (or a slice of it). For a CLI
  with three settings this feels heavy; the exception above addresses
  it.
- **Initial setup overhead.** Each project pays a one-time cost
  (~30 minutes) to author the settings module, wire the provider, and
  add the lint rule. Amortized across the project's lifetime, it's
  negligible.
- **Per-language idioms diverge.** The pattern is universal; the
  machinery is not. A contributor who knows Pydantic Settings still
  has to learn Effect Config when crossing repos. The cross-language
  guidance above limits the divergence but cannot eliminate it.
- **Dynamic config is awkward in the static struct.** Feature flags
  and live-tunable values don't fit; the exception carves them out,
  but a project that has lots of dynamic config will end up with both
  a static settings module *and* a dynamic flags service, which is
  more moving parts.
- **Lint enforcement requires per-language configuration.** The "only
  one file may touch the provider" rule is most powerful when
  mechanically enforced, which is per-language plumbing each project
  has to set up.

**Net**

We are paying a small per-project setup cost and a small ergonomic
cost on tiny scripts to buy out an open-ended class of pain: hidden
config dependencies, untyped string juggling, runtime lock-in, leaked
secrets, and per-file provider migrations. For anything past a single
script, the trade is decisively favorable.

## Alternatives considered

- **Status quo: env vars read inline.** This is what the ADR exists
  to address. Cheap to write, expensive to audit, fragile in
  production, hostile to multi-runtime work.
- **A `dotenv` library and call it done.** Solves *loading* (read
  `.env` into `process.env`), does nothing for *typing*, *centralizing*,
  *swappability*, or *runtime portability*. Compatible with this ADR
  as a provider implementation, but not a substitute for it.
- **Global config singleton.** Better than scattered reads, worse than
  a typed struct passed through DI. Singletons hide dependencies the
  same way globals do, complicate tests, and don't compose across
  layers. The settings module is intentionally *not* a singleton — it
  is a value that gets injected.
- **Config service over the network (Consul, etcd, a dedicated config
  microservice).** Over-engineered for most projects and orthogonal to
  this ADR. The settings module MAY *reference* such a service (its
  endpoint and credentials) and a provider MAY *fetch from* such a
  service; the discipline of "one typed module, decoupled from
  provider" still applies on top.
- **TypeScript-only ADR (Effect-specific).** Tempting because Effect
  has the cleanest expression of the pattern, but the principle is
  universal and ADRs 0002 and 0003 already establish that darkmatter
  standing decisions are polyglot. Pinning this to TS would leave
  Rust and Python projects without guidance and re-create the same
  pain.
- **12-factor's "config in the environment."** A useful framing for
  *deployment* (config lives outside the artifact), not a
  prescription for *consumption*. This ADR is the consumption-side
  discipline that 12-factor doesn't supply.
- **Per-module config objects (each module owns its own settings).**
  Tempting from a locality-of-reference standpoint but defeats the
  central goal: there's still no single answer to "what does this
  app need," and provider migrations still touch many files.

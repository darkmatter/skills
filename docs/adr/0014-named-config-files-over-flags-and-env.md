# 0014 — Configuration is named config files, picked from a list; flags and env vars are overrides

- **Status:** accepted
- **Date:** 2026-09-03
- **Deciders:** cm

## Context

A program that needs more than a couple of settings has to get them from
somewhere. The two defaults in every ecosystem are CLI flags
(`--rpc-url … --chain-id … --pool-size …`) and environment variables
(`RPC_URL=… CHAIN_ID=… POOL_SIZE=…`). Both describe configuration one
value at a time. Neither describes a working combination.

That is the problem. The next person or agent to run the program has to
assemble the right set: which options matter for this environment, which
values go together, which are required and which have defaults. That
knowledge lives in a runbook, a CI YAML, someone's shell history, or
nowhere. `--help` lists options; it does not list a configuration that
works. A missing or mismatched value is discovered at runtime, one
attempt at a time.

Even a single selector flag (`--config staging`) is one more thing to
know before the program runs. When a human is at the terminal, the
program can simply list the configurations and ask.

[ADR-0005](0005-typed-settings-module-decoupled-from-provider.md) already
decided how configuration is _consumed_: one typed settings module per
binary, a description layer (`effect/Config` in TypeScript) that does not
know where values come from, and a swappable `ConfigProvider`. It allowed
composing providers ("env wins over file wins over default") but did not
say which source is primary. Repos have filled that gap with flags and
env vars, because that is what the platform hands out for free.

With Effect the source is a detail. `Config` describes the keys. A
`ConfigProvider` resolves them from a JSON object
(`ConfigProvider.fromUnknown`), the environment (`fromEnv`), a `.env`
file (`fromDotEnv`), a SOPS document (`effect-sops`), or an in-memory
map in tests, and `ConfigProvider.orElse` chains them. CLI flags fall
back into the same chain (`Flag.withFallbackConfig`), and
`effect/unstable/cli` ships the picker (`Prompt.select`). Choosing the
primary source therefore costs nothing in code and decides everything
about how easy the program is to run.

## Decision

Configuration MUST come from named configuration files. There is no
selector flag: an interactive run picks a named config from a list, a
non-interactive run takes the name from the environment. Flags and
environment variables are overrides of individual keys, not the primary
source. Everything is read through `effect/Config`, so the source stays
interchangeable.

Scope: this governs _configuration_: how the program is set up for an
environment (endpoints, ports, pool sizes, log level, feature toggles,
where secrets live). It does not govern _arguments_: what one invocation
acts on (a file to convert, an id to inspect, a subcommand). Arguments
stay positional or flags.

### 1. A small set of named configs, committed and complete

- Named configs live in the repo as `config/<name>.json`: `local`,
  `staging`, `production`, `test`, or whatever the repo's environments
  are. JSON, for the reasons in [ADR-0011](0011-sops-files-as-json.md):
  TypeScript imports it with a type, Nix parses it without IFD, `jq`
  reads it.
- Each named config is complete. Selecting it MUST resolve every key the
  settings module requires that has no default in code. A missing key
  fails at startup with the key name, not at first use.
- Keep the set small. If someone is overriding more than one or two keys
  to run the program, that is a new named config, not a longer command
  line.
- Secrets never go in the plaintext file. A secret key resolves from the
  SOPS document beside the config (`config/<name>.sops.json`, per
  ADR-0011, read through `effect-sops`) or from the platform's secret
  store through its own provider. The settings module types it
  `Config.redacted`.

### 2. No selector flag: a picker, or the environment

- **Interactive run** (stdin is a terminal): the program lists the named
  configs and the user picks one. `local` is listed first, so Enter is
  the fast path. The list is the documentation.
- **Non-interactive run** (CI, systemd, containers, Workers, agents):
  the name comes from `APP_CONFIG` (or `<APP>_CONFIG`), set by the
  deploy or the job. If it is absent or not one of the names, the
  program fails at startup and the failure lists the names. It MUST NOT
  prompt without a terminal, and it MUST NOT silently fall back to a
  default: a deploy that forgot the variable must not boot on `local`.
- There is no `--config` flag and no file-path selector.
- A repo MAY remember the last pick in a gitignored file and list it
  first. It MUST still show the picker.
- The README ([ADR-0006](0006-readme-minimum-standard.md)) lists the
  named configs and the environment variable for non-interactive runs.

### 3. Overrides are individual keys, resolved through the same `Config`

Precedence, highest first:

1. Flags, only where a CLI exposes one for a per-invocation override,
   and only via `Flag.withFallbackConfig` so the flag and the file read
   the same key.
2. Environment variables.
3. The SOPS document for the selected name.
4. The selected named config.
5. Defaults in the settings module (`Config.withDefault`).

Env overrides use the same path as the file key, in constant case:
`database.port` in JSON is `DATABASE_PORT` in the environment
(`ConfigProvider.constantCase`). There is no second naming scheme.

`.env` files are environment variables by another route
(`ConfigProvider.fromDotEnv`). They are overrides too. A required
non-secret key MUST NOT exist only in a `.env`.

### 4. Reference shape (TypeScript, Effect v4 names)

```ts
// src/settings.ts — description layer (ADR-0005). Knows keys, not sources.
import { Config } from "effect";

export const settings = Config.all({
  database: Config.all({
    host: Config.string("host"),
    port: Config.port("port"),
    poolSize: Config.int("poolSize").pipe(Config.withDefault(10)), // tier 5
  }).pipe(Config.nested("database")),
  api: Config.all({
    baseUrl: Config.url("baseUrl"),
    token: Config.redacted("token"), // secret: lives in the .sops.json sibling
  }).pipe(Config.nested("api")),
});
```

```json
{
  "database": { "host": "db.staging.internal", "port": 5432 },
  "api": { "baseUrl": "https://api.staging.example.com" }
}
```

That is `config/staging.json`: complete for staging, no secrets.
`config/staging.sops.json` holds `{ "api": { "token": "…" } }`,
encrypted.

```ts
// src/main.ts — provider wiring. The only place sources are named.
import { BunRuntime, BunServices } from "@effect/platform-bun";
import { Config, ConfigProvider, Data, Effect, Option } from "effect";
import { Prompt } from "effect/unstable/cli";
import * as SopsConfig from "effect-sops/Config";
import local from "../config/local.json" with { type: "json" };
import staging from "../config/staging.json" with { type: "json" };
import production from "../config/production.json" with { type: "json" };
import { program } from "./program";

const named = { local, staging, production } as const; // the enumerable set; local first
const names = Object.keys(named) as ReadonlyArray<keyof typeof named>;

class NoConfigSelected extends Data.TaggedError("NoConfigSelected")<{
  readonly names: ReadonlyArray<string>;
}> {}

// Interactive: pick from the list. Non-interactive: APP_CONFIG, or fail listing the names.
const chooseConfig = Effect.gen(function* () {
  const fromEnv = yield* Config.literals(names, "APP_CONFIG").pipe(Config.option);
  if (Option.isSome(fromEnv)) return fromEnv.value;
  if (!process.stdin.isTTY) return yield* Effect.fail(new NoConfigSelected({ names }));
  return yield* Prompt.select({
    message: "Configuration",
    choices: names.map((name) => ({ title: name, value: name })),
  }).pipe(Prompt.run);
});

const main = Effect.gen(function* () {
  const name = yield* chooseConfig;
  const secrets = new URL(`../config/${name}.sops.json`, import.meta.url).pathname;

  const provider = ConfigProvider.fromEnv().pipe(
    ConfigProvider.constantCase, // 2. DATABASE_PORT=… overrides database.port
    ConfigProvider.orElse(SopsConfig.make({ path: secrets })), // 3. secrets
    ConfigProvider.orElse(ConfigProvider.fromUnknown(named[name])), // 4. the named config
  );

  return yield* program.pipe(Effect.provide(ConfigProvider.layer(provider)));
}).pipe(Effect.provide(BunServices.layer)); // Terminal for the picker

BunRuntime.runMain(main);
```

The settings module never changes when the wiring does:

- Tests: `ConfigProvider.fromUnknown({ database: { … }, api: { … } })`.
  No `process.env` mutation, no picker.
- Cloudflare Workers (no filesystem, no terminal): the named configs are
  already in the bundle through the imports. The deploy sets only
  `APP_CONFIG` per stage; secrets arrive as bindings via
  `ConfigProvider.fromEnv({ env })`.
- A CLI built with `Command`: run `chooseConfig` in the entrypoint before
  the command tree, not as a flag. Per-key flags, where a CLI wants
  them, use `Flag.withFallbackConfig` on the same `Config` the settings
  module declares.

A schema-first description (`Config.schema(SettingsSchema)`) reads the
same files and is equally acceptable.

On Effect v3 translate: `Config.int`/`Config.port` → `Config.integer`,
`ConfigProvider.fromUnknown` → `ConfigProvider.fromJson`,
`ConfigProvider.layer` → `Layer.setConfigProvider`, `Prompt` and `Flag`
in `effect/unstable/cli` → `Prompt` and `Options` in `@effect/cli`,
`BunServices.layer` → `BunContext.layer`.

### 5. Enforcement

- `ci` ([ADR-0002](0002-standard-project-command-surface.md)) SHOULD
  include a config check, in TypeScript
  ([ADR-0012](0012-ops-scripts-in-typescript.md)): for every named
  config, resolve the whole settings description against
  `ConfigProvider.fromUnknown(named[name])` plus a stub secrets provider,
  and fail on any missing or malformed key. This catches an incomplete
  `staging.json` before a deploy does.
- The picker runs only when stdin is a terminal. `ci` and every deploy
  target are non-interactive; an entrypoint that hangs there is a bug.
- ADR-0005's lint (no `process.env` outside the settings and provider
  boundary) still applies. The environment selector is read through
  `Config`; the terminal check is the one platform call the entrypoint
  makes.

### Exceptions

1. ADR-0005's trivial-script exception carries over. A `scripts/` helper
   with one or two inputs may take them as flags or env vars.
2. Tools whose configuration belongs to a platform (`alchemy.run.ts`
   stages and profiles, `sops` creation rules, `nix develop` shells)
   keep the platform's own selector. `--stage prod --profile prod` is
   already a named config; do not wrap it in another.
3. Arguments, per the scope above.

## Consequences

**Upside**

- Nothing to know. Run the program and pick from the list. The list is
  the documentation.
- Non-interactive runs need one variable, and the startup failure spells
  out its name and values. An agent that hits it learns the incantation
  from the error, not from a runbook.
- The configuration surface is enumerable: `ls config/` plus the
  settings module. It is reviewable: an environment change is a diff to
  a JSON file, not a line in a shell history.
- Providers stay interchangeable. Tests use `fromUnknown`, Workers use
  `fromEnv({ env })`, servers use file plus env. The settings module
  never changes.
- Nix and other tooling read the same JSON (`lib.importJSON`) without
  re-encoding.
- Flags and env vars still work for the one-off override, so no
  operational escape hatch is lost.

**Costs**

- Interactive runs prompt on every start. Enter accepts `local`.
- Non-interactive runs still need `APP_CONFIG` from the deploy or the
  job, and a forgotten variable is a failed start by design.
- The entrypoint needs a terminal service (`BunServices.layer`) and a
  few lines for the picker.
- Every environment needs a file, plus a SOPS sibling if it has secrets.
  N environments is up to 2N files, which can drift. The CI config check
  is the mitigation.
- JSON has no comments (ADR-0011). Explain a value in the settings
  module or the README.
- CLIs give up the habit of exposing every setting as a flag. A flag
  exists only where a per-invocation override is genuinely useful, and
  it must fall back to the config chain.
- Repos that grew up on `.env.<stage>` files have a one-time conversion
  to `config/<stage>.json` plus `config/<stage>.sops.json`.

## Alternatives considered

- **A selector flag (`--config <name>`).** Rejected. It is one more thing
  to know before the program runs, and `--help` is where that knowledge
  hides. The picker shows the choices at the moment they are needed; the
  non-interactive failure shows them to everything else.
- **Prompting in non-interactive runs too.** Rejected. A prompt with no
  terminal hangs a service, a CI job, or an agent. The environment
  variable plus a failure that lists the names is the non-interactive
  contract.
- **Defaulting to `local` when nothing is selected.** Rejected. A deploy
  that forgets the variable would boot on local config and look healthy.
  Failing at startup is the point.
- **Persisting the pick so later runs skip the picker.** Rejected as
  default behavior: hidden state is the runbook problem again, one file
  over. Listing the last pick first is allowed.
- **Flags as the primary source.** Rejected. `--help` enumerates options,
  not working combinations, and every caller reassembles the set.
- **Environment variables as the primary source (12-factor).** Rejected
  as primary: same assembly problem, and nothing in the repo says which
  set is complete. Kept as the override layer and as the non-interactive
  selector, which is what 12-factor deploy-time injection actually needs.
- **Per-environment `.env` files.** Closer, but a flat string map: no
  nesting, no types, and secrets end up beside non-secrets. Supported as
  an override source through `fromDotEnv`, not as the named config.
- **Configuration as TypeScript (`config/staging.ts`).** Typed by
  construction, but it is code: Nix, `jq`, and ops tooling cannot read it
  without executing it, and logic creeps in. Validation at load gives
  the typing without that cost.
- **YAML or TOML.** Rejected for the reasons in ADR-0011. JSON is the
  overlap of TypeScript and Nix.
- **One file with per-environment sections.** Rejected. Harder to diff,
  secrets cannot be split per environment, and selecting a section is
  no simpler than selecting a file.
- **A remote config service.** Out of scope. A `ConfigProvider` MAY fetch
  from one (ADR-0005); the named-config discipline still applies to what
  it returns.

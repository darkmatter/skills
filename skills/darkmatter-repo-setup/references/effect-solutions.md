# Effect Solutions — Quick Reference

The [Effect Solutions quick-start](https://www.effect.solutions/quick-start)
is the canonical field manual for idiomatic Effect code. It is available
both as a website and as a CLI for agent use.

## CLI

Install globally:

```sh
bun add -g effect-solutions@latest
```

Or run without installing:

```sh
bunx effect-solutions@latest <command>
```

Commands:

```sh
effect-solutions list              # list all topics
effect-solutions show <topic>      # show a specific topic
effect-solutions open-issue        # leave feedback
```

## Topics

These are the topics available via `effect-solutions show <topic>`.
Consult them when setting up or auditing Effect-related parts of a repo.

| Topic                 | What it covers                                                                                                               | When to consult during setup                        |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `project-setup`       | Effect Language Service installation, reference repositories for AI assistance                                               | When configuring the tsconfig plugin and Zed LSP    |
| `tsconfig`            | Recommended TypeScript compiler settings for Effect (incremental, composite, ES2022, NodeNext, verbatimModuleSyntax, strict) | When writing or auditing tsconfig.json              |
| `basics`              | Coding conventions for `Effect.fn` and `Effect.gen` — sequencing, naming effectful functions                                 | When scaffolding app source files                   |
| `services-and-layers` | `Context.Service` and `Layer` patterns for dependency injection — unique identifiers, composition, testability               | When scaffolding `packages/web-core` services       |
| `data-modeling`       | `Schema` for records, variants, brands, pattern matching, JSON serialization — runtime validation + type safety              | When defining config schemas and status payloads    |
| `error-handling`      | `Schema.TaggedError` for structured, serializable, type-safe domain errors                                                   | When defining error types                           |
| `config`              | `Effect.Config` for type-safe configuration loading with validation, defaults, providers, and layer patterns                 | When scaffolding `AppConfig` or environment loading |
| `testing`             | `@effect/vitest` with `it.effect()`, test layers, `TestClock`/`TestRandom` for deterministic tests                           | When scaffolding test files                         |
| `cli`                 | Effect's `CLI` module — typed argument parsing, automatic help, service integration                                          | When the repo needs a CLI entrypoint                |

## Usage in repo setup

During the remediate phase, run `effect-solutions show <topic>` for each
Effect-related area before writing or auditing the corresponding files.
The CLI output is the authoritative best-practice guidance — prefer it
over assumptions or stale memory.

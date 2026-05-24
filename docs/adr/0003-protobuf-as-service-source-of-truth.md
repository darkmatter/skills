# 0003 — Protobuf is the source of truth for service and type definitions

- **Status:** accepted
- **Date:** 2026-05-23
- **Deciders:** cm

## Context

Darkmatter ships services across multiple languages (TypeScript/Bun, Rust,
Python, Go, Swift, occasionally Kotlin and Effect on the JVM) and routinely
needs clients in still more. When each service defines its types and surface
in the language it happens to be written in, every new consumer pays a
translation tax:

- A Rust service exposes types in Rust; the TS frontend, Python notebook,
  and Swift client each maintain hand-written parallels.
- Those hand-written parallels drift. Field renames, optionality changes,
  enum additions land on the server and silently break clients until a user
  hits the failing path.
- Adding a new language consumer (Swift app, Python tool, partner SDK)
  becomes a multi-week port instead of a code-generation step.
- Agents can't quickly answer "what does this service accept?" without
  reading the server implementation — there's no contract artifact to point
  at.

Hand-rolled DTOs and JSON-shaped contracts also lose the wire-format
guarantees and breaking-change tooling that a real IDL gives you. The
problem compounds the moment a service has more than one consumer, more
than one language, or a non-trivial deprecation horizon.

Protocol Buffers (with `buf` as the modern tooling layer over the protoc
ecosystem) solves this directly: one IDL, language-agnostic, with
breaking-change detection, multi-language codegen, registry-backed sharing,
and a wire format that's been stable for two decades.

## Decision

Any darkmatter codebase that exposes a service or shares types across a
language boundary MUST declare those types and services using Protocol
Buffers as the source of truth. Code generation SHOULD be driven by
[`buf`](https://buf.build) — `buf lint`, `buf breaking`, `buf generate` —
rather than calling `protoc` directly or hand-rolling generation scripts.
The default transport is [Connect](https://connectrpc.com); see the
Transport section below.

Concretely:

- `.proto` files live in the service repo at `proto/<package>/…` and are
  the authoritative definition of every RPC, message, and enum the service
  exposes.
- Server stubs, client SDKs, and language bindings are **generated**, never
  hand-written. Hand-edited copies of generated code are a defect.
- `buf lint` and `buf breaking` run in CI; breaking changes against the
  main branch fail the build unless explicitly opted out per change.

### Transport

The default transport for protobuf-backed services is
[Connect](https://connectrpc.com) (ConnectRPC). Connect serves gRPC,
gRPC-Web, and Connect's own JSON-over-HTTP protocol from a single schema
and a single server, so browser, mobile, backend, and CLI consumers all
talk to the same service without separate stacks. The browser story alone
(gRPC-Web without an Envoy hop, plus first-class fetch-based clients)
makes Connect the right default over raw gRPC.

Raw gRPC MAY be used where Connect's protocol negotiation isn't useful
(e.g. high-throughput pure-backend RPC with no browser or mobile client).
The burden is on the service to justify it.

### Generated code

Generated server stubs and client SDKs MUST be committed to the repo.
Reasons:

- Agents and humans grep generated code constantly to understand method
  signatures, message shapes, and enum values. Committing makes that work
  without running tooling.
- Schema changes show up as reviewable diffs in PRs (you see exactly what
  the wire surface changed).
- No build-time codegen dependency for downstream consumers — checking
  out the repo is enough.

To prevent drift between `.proto` and committed output, the `ci` recipe
(see [ADR-0002](0002-standard-project-command-surface.md)) MUST run
`buf generate` and verify the working tree is clean afterwards
(`git diff --exit-code` against the generated paths). A drift failure
means someone edited the schema without regenerating; fix is to run the
codegen script locally and commit the result.

Repos MAY opt out of committing generated code if the matrix is genuinely
unmanageable (many languages × many services with very large generated
trees). Opt-outs SHOULD be documented in the repo's README with the
reason.

### Schema sharing

Default to **local sharing**: a `buf.yaml`/`buf.work.yaml` workspace
inside a monorepo, or git path imports between repos. This works with the
tooling we already run, doesn't add external dependencies, and costs
nothing.

The [Buf Schema Registry](https://buf.build/product/bsr) (BSR) is paid
SaaS and is reserved for cases that actually need it:

- Publishing schemas to external partners or open-source consumers.
- Distributing versioned schemas across many independent teams who
  can't or shouldn't share a working tree.
- Org policy mandates a central registry.

None of those apply at darkmatter's current scale. The path stays open;
moving from local to BSR is a `buf push` away if and when the trade
flips.

### Command-surface integration

Protobuf workflows slot into the standard command surface
([ADR-0002](0002-standard-project-command-surface.md)) like this:

- `./scripts/proto-gen` (or `just proto-gen`) — dedicated codegen
  entrypoint. Devs run this after editing `.proto` files; it invokes
  `buf generate` and writes generated code into the committed paths.
- `./scripts/ci` — invokes `buf lint`, `buf breaking`, then
  `proto-gen` followed by `git diff --exit-code` for drift detection.
- `./scripts/setup` — does NOT need to run codegen, since generated
  output is committed. It MAY run it as a sanity check on first-time
  setup.

### Exceptions

1. **Libraries.** A library has no service surface to negotiate, and its
   public API is already expressed in the language it ships in. Libraries
   MAY use protobuf internally if they wrap an RPC client, but are not
   required to.

2. **Very small services.** A service that meets *all* of the following is
   exempt:
   - Single language, single first-party client, no foreseeable second
     consumer.
   - Fewer than 5 endpoints total across the service's lifetime
     (counted as RPCs / HTTP routes / equivalent — whatever the analog
     is for the transport in use).
   - No public or partner-facing surface.

   Toys, internal one-off utilities, and short-lived spikes fall here.
   The 5-endpoint threshold is the load-bearing one: once a service has
   that many entrypoints, the cost of hand-maintaining cross-language
   types exceeds the cost of authoring a `.proto`, and any growth from
   that point bends the curve further.

   A service that grows past these thresholds MUST migrate to protobuf;
   the exception is a starting state, not an indefinite license.

3. **Schema-as-code setups where clients are already generated from a
   single source.** When the schema itself is the source of truth and
   client types are derived automatically — Drizzle (DB schema → TS
   client types), Effect Schema, Zod, and similar — protobuf would be
   redundant for the single-language case.

   The decision rule: **do any *typed* clients live outside the language
   where the schema is authored?**

   - **No → exempt.** Schema-as-code is sufficient.
   - **Yes → not exempt.** Generate `.proto` from the schema (preferred,
     keeps one source of truth), or maintain `.proto` alongside the
     schema with CI-enforced sync (fallback).

   Worked examples:

   | Setup                                                                  | Status        |
   | ---------------------------------------------------------------------- | ------------- |
   | Drizzle schema + Next.js app, only TS consumers                        | Exempt        |
   | Drizzle schema + Next.js + Swift iOS app                               | NOT exempt    |
   | Effect Schema in a TS service consumed only by TS clients              | Exempt        |
   | Effect Schema + Rust ETL job reading the same data                     | NOT exempt    |
   | Zod-validated TS API with only TS-typed clients                        | Exempt        |
   | TS API with **untyped** JSON consumers in other languages              | Exempt¹       |

   ¹ No typed contract exists to enforce, so there's nothing for the ADR
   to govern. This is a worse engineering posture than having proto, but
   it's not what this ADR is trying to fix.

### Tooling default

`buf` is the recommended toolchain because it absorbs the parts of the
protobuf ecosystem that are otherwise hostile: opinionated CLI, native
breaking-change detection, a workable plugin model for codegen, and a
registry for sharing. Projects MAY use raw `protoc` if they have a
specific reason, but the burden is on the project to justify it.

## Consequences

**Upside**

- A new language consumer costs a `buf generate` invocation, not a port.
  Iteration speed on multi-language work jumps materially.
- Cross-language type drift stops being a class of bug. The wire format
  and the generated code are derived from one artifact.
- Breaking changes are detectable in CI before they reach a consumer.
  `buf breaking` against the main branch is a real safety net, not a
  ritual.
- Agents (and humans) can answer "what does this service accept?" by
  reading one `.proto` file instead of reverse-engineering server code.
  Schema-first work is faster for both.
- Public and partner SDKs become a tooling problem instead of a
  documentation-and-prayer problem.
- Wire-level efficiency comes along for free when paired with gRPC or
  Connect, and JSON-over-HTTP is still trivially available through
  Connect's protocol negotiation.

**Costs**

- Build step required. Dev shells and CI need `buf` and the per-language
  plugins; generated code either gets committed or generated on demand,
  both of which have ergonomic costs.
- Protobuf's type system is narrower than e.g. TypeScript's or Rust's.
  Discriminated unions require `oneof`, true sum types are awkward,
  generics don't exist, and "absent vs default" needs care (proto3
  optional, wrapper types, or sentinel values).
- Forces upfront schema design. Some teams prefer "build first, schemify
  later"; that path is no longer available for services in scope.
- Generated output adds review noise. The Generated Code policy commits
  it by default — accepting larger PRs and occasional generated-file
  merge conflicts in exchange for grep-ability, reviewable diffs, and CI
  drift detection.
- A new contributor has to learn enough protobuf and buf to make changes
  safely — small fixed cost amortized across the org.

**Net**

We are paying a per-service upfront cost in schema design and tooling
setup to buy out a recurring, compounding cost in cross-language drift,
hand-written SDKs, and breaking-change firefighting. The trade favors
protobuf decisively for any service expected to live past a quarter or
serve more than one language.

## Alternatives considered

- **Hand-written per-language types, status quo.** Already failing in
  practice — see context. Drift, duplication, and SDK porting tax scale
  linearly with consumers and languages.
- **OpenAPI / Swagger.** REST-shaped and JSON-Schema-derived. Codegen
  quality varies wildly across languages, type expressiveness is weak,
  and breaking-change tooling is immature compared to `buf breaking`.
  Reasonable for documenting an existing REST surface; weak as a
  source-of-truth IDL.
- **TypeSpec.** Microsoft's newer IDL. DX is pleasant, but the ecosystem
  is small, multi-language codegen is uneven, and there is no
  buf-equivalent toolchain story. Worth revisiting in 2 years.
- **GraphQL.** Query-shaped and federation-oriented; doesn't model RPC
  cleanly and pushes complexity into the resolver layer. Excellent for
  certain client-driven UIs, wrong shape for a general service contract.
- **ts-rest, tRPC, or other single-language end-to-end typing.** Solves
  the same problem inside one language. Fails the polyglot requirement
  the moment a non-TS consumer appears, which in our stack is
  routine.
- **gRPC with raw `protoc`, no buf.** Possible, but the ergonomics push
  every team to reinvent the bits of buf they actually need (linting,
  breaking-change checks, plugin management). Strictly worse default.
- **Cap'n Proto, FlatBuffers, Avro, Thrift.** Each is a reasonable IDL
  for specific niches (zero-copy, big-data, polyglot RPC). None has
  buf-equivalent tooling, none has the ambient ecosystem support, and
  none gives us materially more than protobuf for our use cases.

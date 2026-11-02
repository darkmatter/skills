# Effect package layout

Follow the "Readability and module design" section in the repository's
AGENTS.md. Keep a capability's models, services, and implementations under its
domain owner. Role directories help readers find code; they are not mandatory
layers that every operation must pass through.

This map is conceptual. Check the repository's installed Effect version and
pinned source before using service, schema, runtime, or testing APIs. Do not
translate between Effect versions by guessing import paths or signatures.

## Example: a billing package

```text
billing/
  index.ts                  # explicit public models and service exports
  postgres.ts               # explicit public Postgres layer export
  testing.ts                # public test support, when consumers need it
  package.json              # lists supported package entry points
  src/
    models/
      Invoice.ts            # schema and inferred type together
    services/
      InvoiceStore.ts       # complete operations and typed failures
    adapters/
      Postgres.ts           # queries, bindings, decoding, private helpers
      Postgres.test.ts      # exercise store behavior through public entries
    workflows/
      collect-payment.ts    # coordinates store and payment capabilities
```

The package is already the `billing` owner; do not add `src/billing/` just to
repeat its name. A package containing multiple domains uses
`src/<owner>/{models,services,adapters,workflows}`. Add only roles that contain
real responsibilities. Related groups of adapters can use subdirectories
when those groups improve navigation.

Root source entries contain explicit re-exports from implementation modules
under `src/`. Declare supported entries in `package.json`. Avoid a root barrel
that re-exports another barrel or exposes every private helper. Separate
optional database or testing entries so ordinary callers need not depend on
them. A small package may need only one entry.

## Models and services

A model owns its schema and inferred type. Reuse library or generated contracts
when they already describe the value. A wire representation belongs to its
adapter unless consumers also need it. Different representations may need
separate schemas; repeating the same contract as a handwritten interface does
not add a boundary.

A service exposes operations meaningful to its caller, such as
`saveInvoice(invoice)`. Its implementation owns validation, persistence, and
required follow-up work. Callers should not have to remember an internal
sequence of encode, insert, update-index, and decode calls.

Use Effect services and Layers where an injected implementation or resource
lifetime is useful. A pure calculation does not need a service tag. Define the
errors callers need to handle; do not force unrelated failures into one
package-wide error or repeat contracts in separate runtime and backend files.

## Adapters

Keep SQL, parameter bindings, row conversion, and operation-local helpers with
the operation; `Postgres.ts` can implement several related store operations.
Persistence choices and SQL validation policy are in
[darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md).

Use Effect-native drivers directly. Wrap an actual Promise-based driver at the
adapter edge and classify its failures there. Avoid internal
`Effect → Promise → Effect` round trips. Decode unknown input as it enters the
package, then keep the validated type inside it.

## Workflows and application boundaries

Workflows coordinate complete capabilities through their public contracts;
they do not reach into an adapter's private SQL or decoder. Keep private
workflow helpers local. Do not add a workflow layer around a single forwarding
call.

CLI and HTTP handlers parse requests, call the capability, and present its
result. Group related commands when they form one readable module; one command
does not automatically require one file. Application entry points compose
Layers and run the program. `runPromise` belongs at a host callback or caller
boundary that requires a Promise, not between internal Effect modules.

Read configuration through the project's configured provider, validate it, and
pass typed settings inward. The named-config procedure is in
[the skill](SKILL.md#named-configuration); deploy assembly is in
[alchemy](../alchemy/SKILL.md). Keep `alchemy.run.ts` or the repository's
established deploy entry separate from reusable domain models.

## Tests

Follow [when-to-write-tests](../when-to-write-tests/SKILL.md) for whether a test
is needed, and [darkmatter-ts-toolchain](../darkmatter-ts-toolchain/SKILL.md)
for TypeScript test placement. Exercise behavior through the public package or
adapter entry: save an invoice, list invoices, and verify the result; repeat a
delivery and verify idempotency. Check ordering, errors, and cleanup when those
are part of the public contract. Use real test storage where practical, or
inject an external driver/service at its boundary. A public pure function can
have focused input/output tests without starting a server or wrapping the
calculation in Effect. Use the installed version's Effect test helpers for
Effects, virtual time, and resource scopes.

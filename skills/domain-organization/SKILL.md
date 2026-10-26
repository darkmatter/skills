---
name: domain-organization
description: Organize source code by domain owner and capability, keeping a schema with the operations that use it, defining filename conventions, and producing project-wide before/after plans. Use for source packaging and structural moves; use repository-organization for docs/context placement and nix-flake-organization for Nix layout.
---

# Domain organization

Organize source by **owner → capability → module**. A path should identify who
owns the behavior and which concept or operation it contains. A capability's
schema, its service contract and the operations against it live together; a
concrete implementation such as a database client sits beside them.

Apply [codebase-design](../codebase-design/SKILL.md) when choosing boundaries:
keep each capability together and split only when the split improves
understanding. Do not sort code into architectural layer directories such as
`models/`, `services/`, `adapters/`, `workflows/` or `policies/`. A layer
directory spreads one operation over several files that each forward to the
next, and it tells a reader nothing about what the code is for.

Apply this to the requested scope. A planning request produces a plan; an
implementation request authorizes the relevant structural changes. This skill
does not itself authorize installs, dependency upgrades, or changes to another
repository.

## Ground the work

Read the target repository's instructions, package guidance, accepted decisions,
manifests, export/import maps, and validation scripts. Inspect actual source and
callers before assigning roles. Treat an existing plan as design evidence, then
reconcile its inventory and execution claims with the current working tree.

Identify the existing owners, public interfaces, composition roots, test policy,
generated inputs, and framework naming requirements. Distinguish verified facts
from proposed paths. For whole-project work, account for every package and app,
including areas intentionally left unchanged.

Preserve explicit user and repository constraints. Resolve routine layout choices
from the code; ask only when an unresolved ownership or contract choice changes
the requested outcome materially.

## Choose the owner

- A focused package can be the owner: `src/invoices.ts` holds the invoice
  schema, store contract and operations; `src/invoices.postgres.ts` holds its
  SQL.
- A package with substantial domains groups by domain first:
  `src/billing/invoices.ts`, `src/billing/invoices.postgres.ts`.
- Keep an app's screens, routes, and feature-specific behavior in the app.
  Reusable UI belongs in its own package; discover that package's name and alias
  from the workspace. Keep app routes, stores, and API clients out of it.
- Give shared infrastructure a home based on real owners and callers. Similar
  names alone do not justify merging capabilities or creating another package.
- Name AI model-provider capabilities for what they do, such as `inference/`
  or `providers/`, without silently changing their public contract.

Keep packages as deep modules with small public interfaces. Avoid one package
per type or service. Create a subdirectory only when useful code belongs in
it; do not create empty scaffolds.

## Group by capability

One module per capability: the schema and its derived type, the identifiers,
the service contract with its typed failures, and the operations against that
contract. The module depends on the contracts it needs and nothing else; the
composition root supplies concrete implementations.

A concrete implementation is its own module beside the capability, named for
what it implements and how: `invoices.postgres.ts`, `notifications.slack.ts`.
It keeps its queries, bindings, decoding and private helpers local. A process
that coordinates several capabilities is a module named for the process:
`collect-payment.ts`.

Split a capability module only when a split helps a reader or the file
outgrows the configured line budget, and name the pieces for what they do.
Directories that describe content rather than layer are fine when they help
navigation: `config/`, `tools/`, `prompts/`, `components/`, `hooks/`,
`routes/`, `testing/`. Configuration shapes and defaults remain separate from
credentials and live resource construction. Keep app entrypoints thin and put
live assembly in the composition root.

Read mixed modules before moving them. A filename does not make a function pure
or separate a service contract from its concrete implementation. Split
responsibilities only where a reader gains from it, preserving behavior; design
any necessary semantic change as a separate change.

Keep an operation's private helpers, queries, bindings, and decoding local when
they must be understood together. Share a conversion or helper when it hides a
meaningful decision or serves real callers, not to shorten another file. Retain
configured line limits and document narrow exceptions for cohesive modules.

## Name modules consistently

These defaults yield to explicit user choices and established repository or
framework constraints. Keep owner directory casing consistent with the repo;
content directories are lowercase and plural.

| Kind                                        | Default                                                   | Example                                            |
| ------------------------------------------- | --------------------------------------------------------- | -------------------------------------------------- |
| Capability module                           | Lowercase plural noun                                     | `invoices.ts`, `runners.ts`                        |
| Concrete implementation                     | Capability stem, lowercase implementation suffix          | `invoices.postgres.ts`, `runners.memory.ts`        |
| Named toolkit, agent definition, or component | PascalCase                                              | `BillingTools.ts`, `ReviewerAgent.ts`, `InvoiceTable.tsx` |
| Process, handler, or standalone function    | kebab-case                                                | `collect-payment.ts`, `parse-row.ts`               |
| React hook                                  | camelCase                                                 | `useInvoice.ts`                                    |
| Companion test or fixture                   | Source stem, lowercase suffix                             | `invoices.test.ts`, `parse-row.fixture.ts`         |

Conventional files stay recognizable and lowercase: `index`, `app`, `main`,
`agent`, `cli`, `config`, `errors`, `constants`, `types`, `schemas`, `fixtures`,
`testing`, `setup`, and `runtime`. Their directory should supply a narrow meaning.
Split a broad `types.ts` by owned concepts when useful, not by every alias.

PascalCase identifies a named toolkit, agent or component; it implies neither
a class nor a single export. Keep related schema/type pairs and useful
associated exports together. Retain established exported spellings and service
identities during file moves; where a lint rule derives a service key from its
file path, moving the file changes the key, so treat such moves as contract
changes.

Lowercase dotted suffixes distinguish implementation and test roles. Preserve
framework routes, configuration files, declaration files, migration numbering,
SQL, scripts, and generated or registry-managed names through narrow exceptions.
Move ordinary helpers out of component directories when their role differs.

When at least three sibling implementation modules repeat a prefix naming the
same concept, make that concept a subdirectory and remove the prefix from the
filenames:

```text
composer-attachments.ts → composer/attachments.ts
composer-images.ts     → composer/images.ts
composer-text.ts       → composer/text.ts
```

Keep the grouping within its owner, such as `composer/text.ts`, and apply the
casing conventions above to the shorter names. Count distinct
implementation modules; companion tests and fixtures follow their source.
Retain descriptive operation names such as `parse-row.ts` when their words
describe the operation itself.

## Preserve public boundaries

Where a package has `src/`, keep implementation there and use thin, explicit
public entry files consistent with the repository's export policy. Expose small
interfaces instead of wildcard-exporting private trees. A model-only entry
should not also pull in a concrete adapter.

The public interface should expose complete operations and own their ordering,
failure, and cleanup. Thin public re-exports establish that boundary; internal
forwarding chains usually add navigation. Translate external execution models
and validate incoming data at the real adapter boundary.

Follow the target's compatibility policy: retain stable public specifiers where
required; where obsolete paths must be removed, update all callers and remove
them. Do not add blanket compatibility wrappers. Public assets and generated
resources need their own export handling rather than a source-file naming rule.

In Effect projects, check the installed Effect Agent contract catalog and
published upstream contracts before defining agent infrastructure types or
services. Import the upstream contract when one exists; organization work does
not justify duplicate sandbox, durability, approval, or workflow contracts.

## Plan or implement

For a requested plan, project-wide reorganization, or phased rollout, read
[references/planning.md](references/planning.md). Save the requested plan in the
target project's `docs/`, even when reusable presets live in a shared repository.
Planning ends with that artifact; proposed moves are not execution evidence.

When implementation is authorized, move one coherent owner at a time. Update
its imports, public exports, private aliases, build roots, test discovery, and
assets together. Match source extensions to alias targets; extension-appending
maps must not turn an import into `Invoice.ts.ts`. Use an intermediate path for
case-only renames where needed so Git records them reliably.

Keep runtime behavior, schemas, wire formats, persistence keys, service tags,
tool names, and workflow identities stable. Use the repository's existing tests
and checks to verify the moved public interfaces and runtime assets. Follow its
test-placement policy rather than imposing a new test tree.

When evaluating, adding, or claiming filename/dependency enforcement, read
[references/enforcement.md](references/enforcement.md). Run the actual selected
checks and verify graph coverage before describing a scope as enforced. Report
the changed paths, verified checks, remaining gaps, and unrelated failures with
their exact command and first actionable diagnostic.

# Before/after organization plans

Use this reference for a requested plan, a whole-project reorganization, or an
incremental rollout. The plan belongs in the consuming project's documentation;
a shared tooling repository owns reusable presets, not another project's state.

## Establish the inventory

Read workspace manifests and enumerate tracked source before proposing paths.
Compare manifests with the actual directories: include nested workspaces,
runnable apps, examples, tooling, scripts, and root modules where relevant.
Inspect public exports, private import aliases, build inputs, test discovery,
framework routes, generated resources, and runtime-loaded assets.

Record the inspected revision or working-tree state. Keep three kinds of claim
distinct throughout the plan:

- **Current:** observed files, owners, public imports, and dependencies.
- **Proposed:** desired paths, role splits, and enforcement scopes.
- **Verified:** changes or checks actually completed, with evidence.

An old execution banner does not prove today's layout or complete adoption.
Reconcile it with source and validation results. Record unrelated existing
failures so rollout acceptance does not quietly weaken current gates.

## Write a reviewable plan

Scale detail to the request. A whole-project plan should answer each item below;
a focused package plan needs only its affected scope.

| Part                    | Required result                                                                                                                              |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Outcome and scope       | What developers should find from paths, authorized changes, and contracts that remain stable.                                                |
| Current evidence        | Actual owners, entry files, mixed responsibilities, import graph, and gaps in the baseline.                                                  |
| Target contract         | Owner/role/module rules, filename defaults, public interface policy, and justified local exceptions.                                         |
| Before/after inventory  | Every package and app mapped to a concrete target or intentional unchanged outcome with its reason. Include other affected source roots.     |
| Worked mappings         | Representative real files mapped to proposed paths, including mixed modules that need a responsibility split.                                |
| Integration changes     | Callers, exports/imports, aliases, build roots, tests, fixtures, runtime assets, documentation, and generated-input paths affected by moves. |
| Enforcement readiness   | Existing checks, proposed scopes, parser/resolver coverage, and unsupported rules, using the enforcement reference.                          |
| Rollout                 | Independently reviewable phases with prerequisites and observable exit criteria.                                                             |
| Acceptance and rollback | Commands and behavior checks for the target repo, completion conditions, and a reversible unit for each phase.                               |

Use repository evidence in each inventory row. A generic tree plus a promise to
apply it everywhere is insufficient for a whole-project request. Mark untouched
areas deliberately; a focused package already organized well may need no move.
Do not force shared infrastructure or ownership changes merely to fill a table.

Illustrative mappings below show the required precision, not a project inventory:

| Before                     | Proposed after                                                                              | Reason                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `src/billing/types.ts`     | `src/billing/models/Invoice.ts` and retained owned aliases as needed                        | Split substantial named concepts after inspecting exports.                      |
| `src/billing/store.ts`     | `src/billing/services/InvoiceStore.ts` plus `src/billing/adapters/InvoiceStore.postgres.ts` | Separate the contract from a concrete client without changing service identity. |
| `src/billing/parse-row.ts` | `src/billing/mappers/parse-row.ts`                                                          | Conversion depends on billing representations.                                  |
| `src/pages/invoices.tsx`   | Keep framework route; delegate to an app-owned screen                                       | Preserve the route convention and keep reusable primitives in the UI package.   |

For renamed public imports, list old and new specifiers and affected consumers.
For preserved imports, show how export targets change. Follow the repository's
actual compatibility policy. Treat exported SQL, migrations, images, and other
assets separately from TypeScript entry files; keep runtime lookup paths valid.

## Sequence the rollout

Start with an owner whose public interface and tests make a useful pilot.
Prepare only the tooling needed for that scope, then migrate its cohesive files
and callers together. Expand to dependent owners after that phase is verified.
Choose phase order from the actual dependency graph, not from a fixed package list.

Each phase states:

1. Its source roots, owners, and public entry files.
2. Required previous interfaces or parser/enforcement work.
3. The coordinated moves and affected callers, tests, and assets.
4. Existing behavioral checks plus any required checks for a changed contract.
5. The evidence needed to mark the phase complete and the rollback unit.

Enable new rules as errors for completed scopes. Preserve existing gates outside
those scopes. Naming can precede dependency enforcement when parser readiness
differs, but label the latter pending rather than claiming full adoption.

Structural work preserves observable contracts. If splitting a mixed module
requires changing a schema, provider behavior, or workflow policy, identify that
as separate behavioral work with its own authorization and validation.

## Verify acceptance and rollback

Discover commands from the target's manifests and CI; use its package manager.
Check affected public interfaces first, then required repository gates. Verify
source imports and built exports, test discovery, generated inputs, and runtime
asset access. For UI moves, exercise the affected screen through the running app.
For agent workflows, verify actual host-observed tool execution and settlement
where those contracts are affected; narration alone is not execution evidence.

Use existing behavior tests for structural moves. Add tests when required for
changed observable behavior or a new architectural contract; directory-shape
assertions alone do not establish correctness.

Rollback a failed phase's moves, import/export maps, and scoped rule additions
together. Preserve unrelated edits and stronger existing checks. A structural
rollback should not require data migration because persistence contracts stayed
stable. Any permitted temporary entry must have known callers and a removal
condition; omit temporary compatibility when the target policy forbids it.

Complete adoption requires every intended owner to be accounted for, private
implementation to respect its public boundary, declared checks to cover the
actual source graph, existing behavior to pass, and docs/examples to match the
verified layout. Record narrow intentional exceptions with reasons and owners.

# Filename and dependency enforcement

Use this reference when evaluating or enabling checks, or writing claims about
what an organization plan can enforce. Separate conventions from tool behavior.
Inspect the installed version's exports, implementation, bundled documentation,
tests, and consumer configuration before claiming support. A passing command
with missing source coverage is not adoption evidence.

## Optional Darkmatter integration

Darkmatter's shared tooling provides these integration points:

| Import                            | API                                                 | Consumer responsibility                                          |
| --------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------- |
| `@darkmatter/oxlint/organization` | `organizationConfig({ roots, ignore })`             | Select source-directory globs and narrow filename exemptions.    |
| `@darkmatter/dependency-cruiser`  | `domainRules({ scope })`                            | Select importers with a repository-relative regular expression.  |
| `@darkmatter/dependency-cruiser`  | `workspaceRules({ scope, packages, agents, apps })` | Supply actual workspace root directories and retain local rules. |

Resolve these from the target's installed package or pinned shared source. Read
that version's organization guide before configuring it. Reuse existing config
and resolver settings; neither adopting this layout nor reading this reference
authorizes a toolchain rewrite, automatic install, or dependency upgrade.

In the shared interface, naming `roots` are directory globs such as
`packages/*/src`, without trailing `/**`; dependency `scope` is a regular
expression, not a glob. Scope selects importers, so forbidden destinations can
be outside the selected scope. Workspace directory arrays describe real tiers;
use an empty `agents` array when there is no separate agent workspace tier.
Domains inside one package are not independent workspace tiers. Add deliberate
consumer rules if those internal domains need their own public boundaries.

## Know the enforcement limits

Verify these behaviors against the installed version, including override order:

| Concern                   | Shared mechanism and boundary to verify                                                                                                              |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Filename casing           | Native `unicorn/filename-case` overrides for roles and JSX, with function-role and hook overrides. The stem before the first dot is checked.         |
| Dotted suffixes           | Stem checking alone does not enforce lowercase suffixes or a suffix allowlist.                                                                       |
| `index` casing            | Native special handling can exempt `index` case-insensitively; do not claim it enforces exact lowercase spelling.                                    |
| Named toolkits            | A named module under `tools/` may inherit the kebab-case default. Supply a narrow override for named toolkits; function tools keep operation names.  |
| Filename/export agreement | Casing rules do not check export names, single exports, schema placement, hook `use` prefixes, or owner-directory names.                             |
| Framework/generated names | Check preset exemptions and add only the consumer-specific exceptions actually needed. Keep ordinary helpers covered.                                |
| Role independence         | Role rules inspect transitive imports so a public re-export cannot hide a prohibited dependency.                                                     |
| Package privacy           | Public-entry rules inspect direct imports and allow a package entry to import its own implementation. Nested public assets need explicit treatment.  |
| Purity                    | Directory rules miss direct SDK usage and a `runtime.ts` file when they match only `runtime/`. A pure-looking path does not establish pure behavior. |

The intended role direction keeps models independent of execution, services
independent of concrete adapters, workflows coordinating services, and utilities
independent of domain contracts. Review files for responsibilities that path
rules cannot detect. Composition roots supply concrete implementations.

Keep type-only imports in the dependency graph. A type reference can violate an
architectural boundary even when erased at runtime. Preserve stronger existing
cycle, test-entry, and test-folder privacy checks. Exempting tests as sources
from role rules does not make their fixtures public or replace workspace rules.

Check narrow public entries as well as mixed barrels: allowing an entry file to
reach its own source must not allow a model consumer to transitively reach an
adapter. Conversely, applying a transitive private-file prohibition would block
ordinary use of valid public entries. These checks have different purposes.

## Establish parser and resolver readiness

Inspect the installed dependency-cruiser, parser, and compiler versions and their
documented compatibility. Verify with the target source; historical TypeScript
or SWC limitations are version-specific evidence, not permanent constraints.
Keep the application's working type checker unless changing it is authorized.

Run the actual graph command against every root for which the plan claims
coverage, including apps, tooling, scripts, and tests when relevant. Verify:

- `.ts` and `.tsx`, plus `.mts`, `.cts`, or JavaScript variants actually present.
- Package exports, private `#` aliases, path aliases, and type-only imports.
- Nonzero module counts reconciled with the source inventory, including both
  ends of representative cross-package and internal dependencies.
- Unresolved imports and skipped/excluded roots explained rather than ignored.

A successful zero-module scan, JSX excluded to avoid a parse error, or a
package-only graph cannot establish enforcement for a React app. Use a small
local probe when compatibility is uncertain. If a required source kind cannot
be parsed, record graph adoption as pending for that scope and retain existing
checks; do not silently narrow the acceptance claim.

## Verify adoption through the actual tools

Run existing checks first, then opt in the smallest complete scope. Verify an
accepted module/import and a deliberately rejected example through the real
CLI when adopting or changing a rule. Keep probes temporary or in the project's
existing architecture test harness, following its test policy.

Exercise direct, transitive, and type-only forbidden imports; valid public-entry
composition; same-workspace private imports; real scope regexes with captured
groups; and preservation of existing privacy and cycle behavior. Check relevant
filename exceptions and named toolkits. Confirm unmigrated roots retain their
existing checks and are not accidentally opted in.

Prefer native rules where they express the contract. Extend shared tooling only
for a demonstrated gap with real examples and authorized scope. A new custom
rule must account for related exports such as schema/type pairs. Record what is
convention-only until a working check exists; never describe a directory rename
as proof of purity or dependency enforcement.

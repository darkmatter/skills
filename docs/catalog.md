# Skill catalog

The default Darkmatter bundle installs every top-level directory in `skills/`.
`nix/home-manager.nix` derives the installed inventory from that source, so
adding a local skill includes it in future installations. `docs/catalog.md` is
the human-readable inventory: the local table is repo-owned policy, while the
external table records installs declared outside this source tree.

Rule ownership follows the **Readability and module design** section in the
shared agent instructions and the single-owner conventions in
[`repository-organization`](../skills/repository-organization/SKILL.md). A skill
owns the policy named in its row; other skills reference that owner instead of
copying it. See [ADR-0017](adr/0017-skill-and-instruction-ownership.md) for the
decision that made ownership explicit and retired deleted skills.

## Local skills

These are the top-level directories under `skills/` and are maintained in this
repository.

| Skill | Owns | Adjacent owner / boundary |
| --- | --- | --- |
| `advisor` | Advisor-facing review instructions: prevent reinvention and log observed agent events. | Standalone observer guidance; completion and evidence remain with `definition-of-done` and the shared completion-evidence section. |
| `alchemy` | Alchemy v2 infrastructure, preview/deploy workflow, and troubleshooting for TypeScript/Effect apps. | `darkmatter-ts-toolchain` owns stack and database selection; `choose-dev-entrypoints` owns command entrypoints; `sops-secret-access` owns secret access. |
| `choose-dev-entrypoints` | Entrypoint layering across Nix, Just, Bun, Turborepo, package scripts, shell hooks, and `scripts/`, including ops-script language. | `nix-flake-organization` owns flake/module layout; `darkmatter-ts-toolchain` owns the TypeScript contract. |
| `codebase-cleanup` | Scoped cleanup and the optional eight-pass quality audit. | `when-to-write-tests` owns test necessity; the **Readability and module design** section owns module rules; feature work and bug fixes stay out of cleanup scope. |
| `darkmatter-design-system` | Darkmatter visual language and tokens when a project has no established design system. | `ui-component-architecture` owns component/package responsibility; `shadcn-registry-first` owns component sourcing. |
| `darkmatter-repo-setup` | Repo bootstrap, standards onboarding, and compliance checks against the template and toolchain. | Orchestrates owners: `repository-organization` owns placement, `darkmatter-ts-toolchain` owns the TypeScript contract, `nix-flake-organization` owns flake layout. |
| `darkmatter-ts-toolchain` | TypeScript stack, dependency and persistence choices, configuration policy references, TypeScript test placement, and the check contract. | `effect-typescript` owns implementation patterns; `choose-dev-entrypoints` owns entrypoints; `alchemy` owns deploy implementation. |
| `definition-of-done` | Completion conditions and the evidence expected before claiming done. | Orchestrates `when-to-write-tests`, the language toolchain, and the explicit TDD procedure instead of redefining them. |
| `effect-typescript` | Typed Effect implementation patterns for services, adapters, HTTP, and Effect agent code. | `darkmatter-ts-toolchain` owns stack, dependency, and persistence choices. |
| `nix-flake-organization` | Nix flake, NixOS, nix-darwin, Home Manager, host, package, and devshell folder mapping and file contracts. | `choose-dev-entrypoints` owns dev/build/test entrypoints; `repository-organization` owns repo-level artifact placement. |
| `repository-organization` | Artifact placement, README and ADR process, instruction ownership, and explicit exception format. | Does not define source architecture or language rules; the **Readability and module design** section owns module rules, and `nix-flake-organization` owns flake layout. |
| `run-ui-registry-variations` | Manual-invocation workflow that builds and compares three registry-derived UI variations. | Composes `shadcn-registry-first`; `darkmatter-design-system` owns fallback tokens; never auto-triggered. |
| `shadcn-registry-first` | Registry-first component sourcing, installation, and the shared comparison procedure. | `ui-component-architecture` owns package boundaries; `run-ui-registry-variations` is the explicit-only variation workflow. |
| `sops-secret-access` | SOPS-backed configuration and secret access procedure. | `repository-organization` decides where encrypted configuration lives; deploy-specific secret handling stays with `alchemy`. |
| `ui-component-architecture` | Shared React UI package responsibility and keeping app screens thin. | `darkmatter-design-system` owns fallback visual tokens; `shadcn-registry-first` owns component sourcing. |
| `when-to-write-tests` | Test necessity and coverage decisions, plus the pointer to explicit opt-in TDD. | `darkmatter-ts-toolchain` owns TypeScript test placement; the requested TDD command or workflow owns the red/green procedure. |

## Externally installed skills

These installs are declared in the root `package.json` `skills` array. They are
maintained upstream and are not vendored in `skills/`, so they are not part of
the local inventory, the Home Manager source, or repo-owned policy.

| Skill | Source |
| --- | --- |
| `agent-browser` | `vercel-labs/agent-browser` |
| `find-skills` | `vercel-labs/skills` |
| `rust-best-practices` | `apollographql/skills` |
| `test-driven-development` | `obra/superpowers` |
| `ui-ux-pro-max` | `nextlevelbuilder/ui-ux-pro-max-skill` |
| `vercel-react-best-practices` | `vercel-labs/agent-skills` |

## Client runtimes

Runtime behavior is not a task skill and is never enabled merely by installing
the bundle:

- `presets/opencode/runtime/continuous-learning/` supports the opt-in
  continuous-learning stop hook.
- `presets/opencode/runtime/strategic-compact.md` documents the auto-compaction
  contract implemented by the OpenCode plugin.
- `presets/claude/runtime/session-context-pipeline/` is an opt-in Claude Code
  hook bundle.

## Add or reactivate a skill

1. Confirm the capability is not already native to the agent, represented by a
   local skill, or supplied by a declared external install.
2. Keep client-specific hooks and runtime assets under the matching preset.
3. Validate with `nix build .#checks.x86_64-linux.skills` (dependency-complete). For a focused check, `scripts/validate-skill.sh skills/<name>` requires `lychee` on `PATH`; bare `scripts/validate-skill.sh` checks every skill plus `## Local skills` parity. The script fails loudly without `lychee`.
4. Add its row to **Local skills** with the policy it owns and its adjacent
   owner boundaries. The module derives the correct selected ID when a
   consuming configuration flattens the source namespace.
5. Rebuild the consuming Home Manager/Darwin configuration and verify the
   effective inventory.

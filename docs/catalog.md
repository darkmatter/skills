# Skill catalog

The default Darkmatter bundle installs every top-level directory in `skills/`.
`home-manager.nix` derives the installed inventory from that source, so adding
a catalogued skill includes it in future installations.

## Installed skills

| Skill | Purpose |
| --- | --- |
| `agent-browser` | Browser automation guidance. |
| `alchemy` | Darkmatter's Alchemy v2 infrastructure and deployment workflow. |
| `choose-dev-entrypoints` | Choose the correct Nix, Bun, Turbo, Just, or script entrypoint. TypeScript-only repos implement ops scripts in TypeScript ([ADR-0012](adr/0012-ops-scripts-in-typescript.md)). |
| `codebase-cleanup` | Safely clean up and simplify an existing codebase. |
| `darkmatter-design-system` | Darkmatter visual language and tokens. Reusable UI lives in the repo's own package ([ADR-0013](adr/0013-shared-ui-is-its-own-package.md)). |
| `darkmatter-gitops-conventions` | Safe GitOps changes, validation, rollout, and rollback. SOPS payloads are JSON ([ADR-0011](adr/0011-sops-files-as-json.md)). |
| `darkmatter-ts-toolchain` | Darkmatter TypeScript/Bun toolchain and CI contract. Ops scripts in TS-only repos are TypeScript ([ADR-0012](adr/0012-ops-scripts-in-typescript.md)). |
| `definition-of-done` | Define a clear, verifiable completion condition for agentic work. Verification follows `when-to-write-tests`. |
| `diagnose` | Evidence-led diagnosis of bugs and performance regressions. |
| `effect-typescript` | Typed Effect patterns for meaningful TypeScript I/O. |
| `find-skills` | Find available skills for a task. |
| `flue` | Use when working with the Flue framework. |
| `keep-codebase-maintainable` | Cleanup and maintainability passes, not feature work. |
| `nix-flake-organization` | Maintain the Darkmatter Nix flake/module layout. |
| `repository-organization` | Organize durable repository context and assets. |
| `run-ui-registry-variations` | Build and compare UI registry variations. |
| `rust-best-practices` | Idiomatic Rust implementation and review guidance. |
| `shadcn-registry-first` | Reuse configured shadcn registries before hand-building common UI. |
| `sops-secret-access` | Safe SOPS-backed configuration and registry access. Payloads are JSON ([ADR-0011](adr/0011-sops-files-as-json.md)). |
| `test-driven-development` | Opt-in TDD: a few E2E happy-path tests of the public contract, not a unit test per function. |
| `ui-component-architecture` | Keep reusable React UI in its own package. The package name is per-repo ([ADR-0013](adr/0013-shared-ui-is-its-own-package.md)). |
| `ui-ux-pro-max` | UI/UX design intelligence across supported stacks. |
| `vercel-react-best-practices` | React and Next.js performance guidance. |
| `when-to-write-tests` | Decide whether to add a test. Default is no new test. |

## Client runtimes

Runtime behavior is not a task skill and is never enabled merely by installing
the bundle:

- `presets/opencode/runtime/continuous-learning/` supports the opt-in
  continuous-learning stop hook.
- `presets/opencode/runtime/strategic-compact.md` documents the auto-compaction
  contract implemented by the OpenCode plugin.
- `presets/claude/runtime/session-context-pipeline/` is an opt-in Claude Code
  hook bundle.
- `presets/base/runtime/end-of-turn-review/` is an opt-in cross-client review
  utility.

## Add or reactivate a skill

1. Confirm the capability is not already native to the agent or represented by
   an installed skill.
2. Keep client-specific hooks and runtime assets under the matching preset.
3. Validate the skill with `scripts/validate-skill.sh skills/<name>`.
4. Add its row above. The module derives the correct selected ID when a
   consuming configuration flattens the source namespace.
5. Rebuild the consuming Home Manager/Darwin configuration and verify the
   effective inventory.

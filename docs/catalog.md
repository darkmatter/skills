# Skill catalog

The default Darkmatter bundle installs every top-level directory in `skills/`.
`home-manager.nix` derives the installed inventory from that source, so adding
a catalogued skill includes it in future installations.

## Installed skills

| Skill | Purpose |
| --- | --- |
| `agent-browser` | Browser automation guidance. |
| `alchemy` | Darkmatter's Alchemy v2 infrastructure and deployment workflow. |
| `choose-dev-entrypoints` | Choose the correct Nix, Bun, Turbo, Just, or script entrypoint. |
| `codebase-cleanup` | Safely clean up and simplify an existing codebase. |
| `darkmatter-gitops-conventions` | Safe GitOps changes, validation, rollout, and rollback. |
| `darkmatter-ts-toolchain` | Darkmatter TypeScript/Bun toolchain and CI contract. |
| `definition-of-done` | Define a clear, verifiable completion condition for agentic work. |
| `diagnose` | Evidence-led diagnosis of bugs and performance regressions. |
| `effect-typescript` | Typed Effect patterns for meaningful TypeScript I/O. |
| `find-skills` | Find available skills for a task. |
| `finishing-a-development-branch` | Finish and integrate a development branch. |
| `grill-me` | Challenge and refine an implementation plan. |
| `grill-with-docs` | Challenge and refine a plan using documentation. |
| `handoff` | Create a compact handoff for another agent. |
| `improve-codebase-architecture` | Improve a codebase's architecture. |
| `nextjs-to-rwsdk-migration` | Migrate a Next.js application to RedwoodSDK. |
| `nix-flake-organization` | Maintain the Darkmatter Nix flake/module layout. |
| `prototype` | Build a prototype to evaluate an idea. |
| `repository-organization` | Organize durable repository context and assets. |
| `run-ui-registry-variations` | Build and compare UI registry variations. |
| `rust-best-practices` | Idiomatic Rust implementation and review guidance. |
| `shadcn-registry-first` | Reuse configured shadcn registries before hand-building common UI. |
| `sops-secret-access` | Safe SOPS-backed configuration and registry access. |
| `test-driven-development` | Opt-in TDD: a few E2E happy-path tests of the public contract, not a unit test per function. |
| `triage` | Triage incoming work and decide the right next action. |
| `ui-component-architecture` | Keep shared React UI in the shared component package. |
| `ui-ux-pro-max` | UI/UX design intelligence across supported stacks. |
| `using-superpowers` | Apply the Superpowers workflow. |
| `vercel-react-best-practices` | React and Next.js performance guidance. |
| `when-to-write-tests` | Decide whether to add a test. Default is no new test. |
| `writing-skills` | Create and improve agent skills. |
| `zoom-out` | Step back and reassess a task at a broader level. |

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

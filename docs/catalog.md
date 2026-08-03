# Skill catalog

The default Darkmatter bundle is intentionally small. `home-manager.nix` is the
source of truth: it explicitly enables the skills below rather than installing
every directory under `skills/`.

## Default bundle

| Skill | Purpose |
| --- | --- |
| `alchemy` | Darkmatter's Alchemy v2 infrastructure and deployment workflow. |
| `choose-dev-entrypoints` | Choose the correct Nix, Bun, Turbo, Just, or script entrypoint. |
| `darkmatter-gitops-conventions` | Safe GitOps changes, validation, rollout, and rollback. |
| `darkmatter-ts-toolchain` | Darkmatter TypeScript/Bun toolchain and CI contract. |
| `diagnose` | Evidence-led diagnosis of bugs and performance regressions. |
| `effect-typescript` | Typed Effect patterns for meaningful TypeScript I/O. |
| `nix-flake-organization` | Maintain the Darkmatter Nix flake/module layout. |
| `rust-best-practices` | Idiomatic Rust implementation and review guidance. |
| `shadcn-registry-first` | Reuse configured shadcn registries before hand-building common UI. |
| `sops-secret-access` | Safe SOPS-backed configuration and registry access. |
| `tdd` | Test-first implementation when the user asks for TDD. |
| `ui-component-architecture` | Keep shared React UI in the shared component package. |
| `ui-ux-pro-max` | UI/UX design intelligence across supported stacks. |
| `vercel-react-best-practices` | React and Next.js performance guidance. |

## Not shipped by default

Current agents already provide skill creation/installation, browser control,
and skill-dispatch facilities. Their legacy counterparts remain out of the
default bundle: `dm-skill-creator`, `writing-skills`, `find-skills`,
`agent-browser`, and `using-superpowers`.

Broader process and niche workflows are retained as source material but are
also inactive by default. Reactivate one only after it demonstrates a repeated,
team-wide need that cannot be met by the native agent or an enabled skill.

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
   an enabled skill.
2. Keep client-specific hooks and runtime assets under the matching preset.
3. Validate the skill with `scripts/validate-skill.sh skills/<name>`.
4. Add the skill name to `defaultDarkmatterSkills` in `home-manager.nix`, then
   add its row above. The module derives the correct selected ID when a
   consuming configuration flattens the source namespace.
5. Rebuild the consuming Home Manager/Darwin configuration and verify the
   effective inventory.

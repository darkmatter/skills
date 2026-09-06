# Repo Standards Audit Checklist


Before you start, clone the latest version of the dependencies. If they exist,
ensure they are up to date:

```bash
GITDIR="$HOME/.agents/git"
mkdir -p "$GITDIR/darkmatter"
git clone git@github.com:darkmatter/template.git $GITDIR/darkmatter/template
git clone git@github.com:darkmatter/skills.git $GITDIR/darkmatter/skills
```

Work through each section. For every category, check if the repo has
equivalent coverage to the cloned template at `$GITDIR/darkmatter/template`.
Record ✅ present, ⚠️ partial, or ❌ missing.

## 1. AGENTS.md

- [ ] Documents the repo layout and purpose of each top-level path
- [ ] Defines the `ops/` boundary — what goes in ops vs source-adjacent config
- [ ] States the toolchain contract (Bun, tsgo, oxlint/oxfmt, Vitest)
- [ ] States package conventions (catalog, workspace, # imports)
- [ ] Documents the Nix devshell and `x` / `justfile` commands
- [ ] Documents testing, secrets, CI, and validation steps
- [ ] Forbids adding any additional top-level directories (or ask permission)

## 2. package.json (root)

- [ ] Bun workspace with `apps/*` and `packages/*`
- [ ] Shared dependency versions in a catalog (not pinned per-package)
- [ ] `prepare` patches tsgo and oxlint via `effect-tsgo patch`
- [ ] `generate:bun-nix` script for regenerating the Nix lock
- [ ] Engine and package-manager constraints matching the org standard

## 3. TypeScript config

- [ ] Shared base config in `packages/tooling` that all packages extend
- [ ] Effect Language Service configured as the tsconfig plugin
- [ ] Strict mode with `noUncheckedIndexedAccess` and `verbatimModuleSyntax`
- [ ] Each package uses `#` subpath imports with a matching `paths` entry

## 4. Linting & formatting

- [ ] oxlint config extends the tsgo preset
- [ ] File-size limit enforced (split files that exceed it)
- [ ] SOPS files ignored by linter and formatter
- [ ] oxfmt configured as the sole formatter (Prettier disabled in Zed)

## 5. Testing

- [ ] Vitest configured at the root with node environment
- [ ] Vitest excludes `.direnv/**`
- [ ] Unit tests use `@effect/vitest` with `it.effect` and test layers
- [ ] Smoke tests spawn the real server end-to-end

## 6. Zed editor config

- [ ] oxfmt is the formatter for all supported languages
- [ ] Prettier disabled everywhere
- [ ] effect-tsgo is the TypeScript LSP (other TS LSPs disabled)
- [ ] oxlint LSP runs on save

## 7. Nix flake

- [ ] `flake.nix` at root with flake-parts, nixpkgs, treefmt, prelude, bun2nix
- [ ] Thin `flake/` output layer (devShells, checks, packages, apps)
- [ ] `nix/prelude.nix` command catalogue (`x` menu, MOTD, docs)
- [ ] Package and smoke-check implementations under `nix/`
- [ ] `bun.nix` generated and committed
- [ ] devShell puts bun, age, sops, and ops tooling on PATH
- [ ] Use prelude's justfile integration to get justfile <-> prelude sync

## 8. justfile

- [ ] Preferred due to being agnostic
- [ ] Guards all targets with devshell entry (`nixsh`)
- [ ] Wraps the core commands: check, test, dev, fmt
- [ ] Has container config validation and container-up targets
- [ ] Do NOT overload this. For additional modes like `lint --fix`, use param
- [ ] Params should be enumerated so that they are self-documenting
- [ ] Complex tasks should get their own executable in `ops/bin`


## 9. ops/ directory

- [ ] `ops/README.md` defines the boundary of each subdirectory
- [ ] `ops/bin/` — operational commands
- [ ] `ops/container/` — container build recipes
- [ ] `ops/compose/` — local compose stack(s)
- [ ] `ops/config/` — runtime config for dependencies
- [ ] `ops/deploy/` — reusable deployment primitives
- [ ] `ops/environments/` — per-env assembly (dev, staging, production)
- [ ] `ops/secrets/` — SOPS rules and encrypted material
- [ ] `ops/observability/` — dashboards, alerts, metrics, tracing, logging
- [ ] `ops/nix/` — operational host/profile configuration
- [ ] `ops/policies/` — guardrails evaluated by automation

## 10. CI pipeline

- [ ] Triggers on PR and push to main
- [ ] Installs with `--frozen-lockfile --ignore-scripts`
- [ ] Runs prepare, check, test, lint, fmt:check
- [ ] Runs `nix flake check`
- [ ] Validates the compose stack
- [ ] Bun version pinned to match the repo's packageManager

## 11. .gitignore

- [ ] Excludes node_modules, .direnv, dist, Nix result symlinks
- [ ] Excludes .env / .env.* but allows .envrc and .env.example
- [ ] Excludes age keys and tsbuildinfo

## 12. Docs

- [ ] Architecture doc — app structure, deploy/environments overview
- [ ] Getting-started doc — shell entry, install, dev, format
- [ ] README — install, usage, layout, link to AGENTS.md

## 13. packages/tooling

- [ ] Exports a shared tsconfig and oxc config that other packages extend

## 14. Effect best practices (effect.solutions)

Cross-reference each item against `effect-solutions show <topic>` from the
[Effect Solutions quick-start](https://www.effect.solutions/quick-start).
See [effect-solutions.md](effect-solutions.md) for the topic list.

- [ ] `effect-solutions` CLI available for best-practice lookup
- [ ] Effect Language Service configured per `show project-setup`
- [ ] TypeScript config follows `show tsconfig`
- [ ] Source code follows `show basics` (Effect.gen, Effect.fn conventions)
- [ ] Services use Context.Service + Layer per `show services-and-layers`
- [ ] Data modeling uses Schema per `show data-modeling`
- [ ] Errors use Schema.TaggedError per `show error-handling`
- [ ] Config uses Effect.Config per `show config`
- [ ] Tests use @effect/vitest with it.effect per `show testing`

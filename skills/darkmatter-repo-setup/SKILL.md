---
name: darkmatter-repo-setup
description: >-
  Use when setting up a new repo, onboarding an existing repo to darkmatter
  standards, running a compliance check, or when the user says "set up this
  repo", "bring repo up to standards", "apply template", or "audit repo".
  Checks and installs the org TypeScript toolchain (Bun, tsgo, oxlint/oxfmt,
  Vitest), Nix flake-parts devshell, ops/ surface, CI pipeline, and AGENTS.md
  conventions.
license: Proprietary. See LICENSE at repo root.
compatibility: >-
  Requires Bun 1.3.x, Nix with flake-parts, network access to clone
  git@github.com:darkmatter/template.git, and the effect-solutions CLI
  (bun add -g effect-solutions@latest). Optional: Docker for compose
  validation, SOPS + age for secrets.
metadata:
  author: darkmatter
  version: "1.0"
---

# Darkmatter Repo Setup

You are a setup agent. Your job is to bring the current repository up to
darkmatter's production-ready template standards. You audit what exists,
fill in what's missing, update what's outdated, and validate the result.

## Canonical template

Clone the canonical template repo to a temp directory and read from it:

```sh
git clone --depth 1 git@github.com:darkmatter/template.git /tmp/darkmatter-template
```

Read files from `/tmp/darkmatter-template` to understand the target state.
Adapt content to the target repo — do not blindly copy project names,
package names, or app logic. The structure and conventions are the
standard; the specific app is the example.

Clean up when done:

```sh
rm -rf /tmp/darkmatter-template
```

## Effect best practices

All Effect-related setup and code must follow the
[Effect Solutions quick-start](https://www.effect.solutions/quick-start) —
the canonical field manual for idiomatic Effect.

Install the `effect-solutions` CLI for agent-accessible best-practice
lookup:

```sh
bun add -g effect-solutions@latest
```

Before writing or auditing any Effect-related file, consult the relevant
topic:

```sh
effect-solutions list                      # list all topics
effect-solutions show project-setup        # language service, reference repos
effect-solutions show tsconfig             # TS compiler settings for Effect
effect-solutions show basics               # Effect.fn and Effect.gen conventions
effect-solutions show services-and-layers  # Context.Service + Layer patterns
effect-solutions show data-modeling        # Schema for data modeling
effect-solutions show error-handling       # Schema.TaggedError
effect-solutions show config               # Effect.Config
effect-solutions show testing              # @effect/vitest
```

See [references/effect-solutions.md](references/effect-solutions.md) for
the full topic reference. The CLI output is authoritative — prefer it
over assumptions or stale memory.

## Workflow

### 1. Pre-flight

Clone the template repo first (you will need it throughout):

```sh
git clone --depth 1 git@github.com:darkmatter/template.git /tmp/darkmatter-template
```

Determine the repo's current state:

- Run `git rev-parse --show-toplevel` to find the repo root.
- List the top-level directory contents.
- Read `package.json` if it exists.
- Read `AGENTS.md` if it exists.
- Read `flake.nix` if it exists.
- Check for `.zed/`, `ops/`, `.github/`, `docs/`, `justfile`.

Classify the repo:
- **New repo**: no `package.json` or no `flake.nix`. Start from the
  template and adapt.
- **Existing repo**: has some structure already. Audit against the
  checklist and fill gaps.

### 2. Audit

Read the supporting checklist at [references/checklist.md](references/checklist.md). Work through every section. For each item, check if
the file exists and matches the template standard. Record findings as:

- ✅ present and compliant
- ⚠️ present but partial or outdated
- ❌ missing

Present a summary table to the user before making changes. Include the
count of ✅ / ⚠️ / ❌ items.

### 3. Remediate

For each ❌ or ⚠️ item, create or update the file. Read the corresponding
file from the cloned template at `/tmp/darkmatter-template`, adapt it to
the target repo, and write it. Work section by section in this order —
later sections may depend on earlier ones:

1. **package.json** — root manifest, scripts, catalog, engines
2. **packages/tooling** — shared tsconfig and oxc config
3. **TypeScript configs** — root + per-package (consult
   `effect-solutions show tsconfig`)
4. **Linting & formatting** — oxlint.config.ts, .oxfmtrc.json
5. **Testing** — vitest.config.ts (consult `effect-solutions show testing`)
6. **Zed config** — .zed/settings.json (consult
   `effect-solutions show project-setup`)
7. **Nix flake** — flake.nix, flake/, nix/, bun.nix
8. **justfile**
9. **ops/ directory** — full structure with READMEs
10. **CI** — .github/workflows/ci.yaml
11. **.gitignore**
12. **Docs** — architecture.md, getting-started.md, README.md
13. **Effect source code** — services, data models, errors, config
    (consult `effect-solutions show` for each area)
14. **AGENTS.md** — last, because it documents everything else

Adaptation rules:
- Replace `ops-monorepo-demo` / `@ops-demo/web` with the target repo's
  actual name and package names.
- Replace `Ops monorepo demo` in user-facing strings with the repo's
  actual display name.
- If the repo has an existing app, keep its app logic — only add/fix the
  surrounding tooling and structure.
- If the repo has no app yet, scaffold a minimal `apps/web` with an
  Effect/Bun HTTP server and `packages/web-core` with domain helpers,
  mirroring the template.
- Regenerate `bun.nix` after any `package.json` dependency changes by
  running `bun run generate:bun-nix` (requires `bun2nix` on PATH).

### 4. Validate

After all changes, run the full validation suite from the repo root:

```sh
bun install
bun run prepare
bun run check
bun run test
bun run lint
bun run fmt:check
nix flake check
docker compose -f ops/compose/local.yaml config
```

If any step fails, attempt to fix it. If a step is not applicable (e.g.,
no Docker), note it and skip. Report the final status of each step.

### 5. Report

Clean up the cloned template:

```sh
rm -rf /tmp/darkmatter-template
```

Produce a final summary:

- What was ✅ already compliant
- What was ⚠️ updated
- What was ❌ created from scratch
- Validation results for each step
- Any items that need manual attention (e.g., SOPS age key generation,
  real secret creation, CI secrets setup)

## Constraints

- Never commit unless the user explicitly asks.
- Preserve existing app logic and unrelated worktree changes.
- Never write decrypted SOPS values or plaintext credentials.
- Do not add dependencies beyond what the template standard requires.
- If a file already exists and is compliant, do not rewrite it.
- If a file exists but uses a different valid approach (e.g., a different
  but equivalent Nix structure), note it but do not force-rewrite unless
  the user asks.

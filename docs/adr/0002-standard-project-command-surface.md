# 0002 — Standard command surface for darkmatter project repos

- **Status:** accepted
- **Date:** 2026-05-23
- **Deciders:** cm

## Context

Darkmatter is polyglot. We ship TypeScript/Bun apps, Rust services, Python
tools, Nix flakes, Effect-based agents, occasional Go and Swift, and Nix
devshells that wrap all of the above. Each language ecosystem has its own
"how do I run this?" answer — `bun dev`, `cargo run`, `uvicorn …`,
`nix develop -c …`, `nix run`, `pnpm start`, `turbo dev`, and on.

The result is friction every time a human or an agent walks into a new repo:

- The first question after `git clone` is always "now what?" The answer is
  buried in the README, or only in the maintainer's head, or implied by the
  file tree.
- Agents cannot script a uniform bootstrap. `./scripts/install` working in
  one repo does not predict that the next repo exposes the same entrypoint,
  so we encode per-repo runbooks instead of building one shared muscle
  memory.
- CI configs, Dockerfiles, devshells, and onboarding docs all duplicate the
  same "install deps, set up, run" sequence under subtly different names.

We want a single, predictable command surface that every darkmatter project
repo exposes regardless of its underlying language or build system, so that
both humans and agents can bootstrap any project the same way.

## Decision

Every darkmatter project repo MUST expose the following commands, available
either as an executable script at `./scripts/<name>` or as a `justfile`
recipe runnable via `just <name>`:

| Command           | Purpose                                                              |
| ----------------- | -------------------------------------------------------------------- |
| `install`         | Idempotent installer for **host-level toolchains and system tools** (language runtimes, compilers, version managers like `mise`/`asdf`, system packages via `brew`/`apt`/`nix profile`). Project deps that come from a lockfile (`bun install`, `cargo fetch`, `pip install -r`) belong in `setup`. |
| `setup`           | Per-checkout setup: install **project deps from lockfiles**, initialize databases, decrypt secrets, scaffold `.env` files, run code generators. Must be re-runnable; second run should be a no-op against an already-set-up checkout. |
| `server` or `run` | Start the app (`server` for long-running services, `run` for CLIs and one-shots). |
| `test`            | Run the test suite. Fast inner loop; this is what a dev runs in a tight edit-test cycle. |
| `build`           | Build the deployable artifact.                                       |
| `ci`              | Run the full pre-PR gate locally — superset of `test`, typically `lint + typecheck + test + build + drift checks`. SHOULD be the same recipe the CI provider invokes so local and remote results match. |
| `console`         | Interactive shell into the running app or its environment (REPL, container shell, devshell, SSH-equivalent). |

The contract is the **command surface**, not the implementation. A repo MAY
implement these as plain scripts, as `just` recipes, or both. When both
exist, **one MUST be the canonical implementation and the other MUST be a
thin delegating wrapper** — pick a direction per repo, but never duplicate
the logic. (Common pattern: `justfile` holds the real recipes, `./scripts/X`
is a one-liner that calls `just X`. The reverse also works.)

The listed surface is the **minimum required**. A repo MAY add more
commands; the recommended additional names below SHOULD be used when adding
equivalents, so muscle memory keeps working across repos.

`server` and `run` are aliases for the same slot; pick one per repo. Use
`server` for long-running services (web servers, APIs, daemons) and `run`
for CLIs, one-shot programs, or generic invocation. A repo MAY ship both if
it has both modes (e.g. an HTTP server and a CLI entrypoint to the same
codebase).

Calling these from a freshly cloned repo MUST work without referring to
documentation:

```sh
git clone <project>
./scripts/install     # or: just install
./scripts/setup       # or: just setup
./scripts/build       # or: just build
./scripts/server      # or: just server   (or ./scripts/run / just run)
```

Commands that genuinely do not apply to a repo (e.g. `server` in a pure
library, `console` in a one-shot CLI) MAY be omitted. The remaining commands
MUST honor this surface.

### Recommended additional commands

These names are not required, but when a repo implements one of these
concepts it SHOULD use the recommended name so muscle memory transfers
across repos:

| Command   | Purpose                                                          |
| --------- | ---------------------------------------------------------------- |
| `lint`    | Run linters (clippy, eslint, ruff, statix, etc.).                |
| `format`  | Apply formatters (rustfmt, prettier, biome, ruff format, etc.).  |
| `doctor`  | Diagnose dev-environment health (missing tools, stale deps, broken secrets). |
| `clean`   | Remove build artifacts, caches, generated code (where regenerable). |
| `migrate` | Run database migrations forward.                                 |
| `seed`    | Populate dev/test data.                                          |
| `deploy`  | Deploy to a target environment (semantics are per-repo until a future ADR addresses deploys). |

Repos MAY add other commands beyond this list. The names above are reserved
in the sense that "if you have a linter, the recipe SHOULD be called
`lint`" — not in the sense that they're forbidden for other uses.

### Bootstrap baseline

The host floor that `./scripts/install` MUST be able to bootstrap from is
captured by darkmatter's `tahoe-base` Docker image (canonical macOS dev
environment). A repo passes this requirement when its `install` script
runs to completion starting from `tahoe-base` with nothing else assumed
installed. The Linux equivalent baseline (used by CI containers) is
tracked separately; `install` MUST run cleanly on whichever image CI uses.

In practice this means `./scripts/install` MAY assume only POSIX shell,
`git`, and `curl` are present, and is responsible for installing every
other tool the project needs (language runtimes, package managers, system
libraries, etc.). Reaching for `brew`, `nix`, `mise`, or curl-piped
installers is fine; assuming any of those are already installed is not.

### Nix devshells

A large fraction of darkmatter repos use Nix flakes. Those repos SHOULD
wrap their scripts to enter the devshell, so a user can run
`./scripts/test` from a bare shell without first remembering to run
`nix develop`. The canonical pattern:

| Script              | Implementation                                |
| ------------------- | --------------------------------------------- |
| `./scripts/console` | `exec nix develop` (drops the user into the devshell). |
| `./scripts/server`  | `nix develop -c <runner>` (e.g. `nix develop -c bun run dev`). |
| `./scripts/test`    | `nix develop -c <test command>`.              |
| `./scripts/ci`      | `nix develop -c <ci pipeline>`.               |

Scripts SHOULD detect whether they are already inside the devshell (e.g.
checking `$IN_NIX_SHELL` or a project-specific sentinel) and skip
re-entering it, so nested invocations don't pay the devshell-eval cost
twice.

For non-Nix repos this section does not apply; use whatever environment
strategy the repo already has (asdf, mise, direnv, devcontainers).

### Exception: turbo

`turbo` is the one exception to the "scripts or justfile" rule. Turbo's
value is monorepo task orchestration with caching and a dependency graph —
it is intentionally a thin layer over `package.json` `scripts` in pnpm/bun
workspaces. A monorepo using turbo MAY expose this surface as
`turbo run <target>` (and therefore via `package.json` `scripts`) instead of
scripts or justfile recipes. The exception exists because turbo is about
monorepos, not about JavaScript: the orchestration is the point, and forcing
it through a script wrapper at every workspace boundary loses turbo's cache
and dependency-graph benefits.

Even in the turbo case, a thin `./scripts/<name>` or `justfile` recipe at
the repo root that shells out to `turbo run <name>` is encouraged so the
uniform muscle memory still works from a fresh clone.

## Consequences

**Upside**

- One bootstrap incantation works across every darkmatter repo. Humans and
  agents stop relearning naming per-project.
- Agents can be instructed once ("run install, then setup, then server")
  and apply that to any new project repo without per-repo glue.
- CI configs, devshells, Dockerfiles, and onboarding docs converge on the
  same names. Drift between local and remote shrinks.
- Bringing up an unfamiliar repo becomes a script-execution exercise, not a
  research one — which means agents and new teammates start contributing
  faster.
- Encourages each repo to actually have an idempotent `install` and a
  reproducible `setup`, instead of an ambient README of half-instructions.

**Costs**

- Every project must implement and maintain the surface, including an
  idempotent `install` and a reproducible `setup`. Greenfield repos stamp
  it from `template/`; existing repos require a one-time migration.
- Some repos will need both a justfile recipe and a script wrapper for
  ergonomics, doubling the surface area. The wrappers are one-liners — a
  small cost.
- Polyglot repos may need to hide the same conceptual step across multiple
  tools behind a single `install` script (e.g. Rust toolchain + Node deps +
  Python venv). This is the intended cost: hiding heterogeneity behind a
  uniform surface is the whole point of the ADR.
- New repos can no longer make ad-hoc naming choices ("`./bootstrap`",
  "`./serve`", "`./dev`"). That freedom is what this ADR is buying out.

## Alternatives considered

- **Per-repo conventions, status quo.** Already failing in practice — see
  context. Discovery cost paid every time anyone touches an unfamiliar
  repo.
- **Mandate `just` only, no scripts.** Adds a tool dependency before the
  user can even run `install`. Falls over on machines without `just`;
  awkward for CI bootstrap and Dockerfiles. The `./scripts/<name>` path
  works with nothing but a POSIX shell.
- **Mandate scripts only, no `just`.** Works, but discards `just`'s
  argument handling, recipe composition, and `.env` integration. Justfiles
  are a legitimate ergonomic upgrade for repos that want them, and the
  decision to use one is a per-repo taste call.
- **Make (`Makefile`).** Works in principle, but `make`'s syntax (tabs,
  implicit rules, phony targets) is hostile for non-build use cases like
  `setup` and `console`, and contributors routinely get it wrong. `just`
  exists precisely to replace this use of `make`.
- **`package.json` scripts in every repo.** Language-specific; doesn't
  work for Rust-only, Python-only, or Nix-only repos. The turbo exception
  exists precisely because in turbo's case the package.json route is
  load-bearing for the orchestrator.
- **A custom darkmatter task runner.** Rejected. We would be reinventing
  `just`, badly, with worse documentation and no upstream community.

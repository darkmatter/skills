# 0012 — TypeScript-only projects write ops scripts in TypeScript

- **Status:** accepted
- **Date:** 2026-09-01
- **Deciders:** cm

## Context

When a repo's application code is TypeScript, utility and operations work
still often lands in bash: `scripts/ci.sh`, release helpers, codegen
wrappers, migrate/seed, wait-for-docker loops, GitHub Actions `run:`
blocks with real logic. It feels cheaper than a `.ts` file. It is not.

A review of past CI failures and repo bugs found they cluster at the
boundary between the main language and a second language used for glue.
Shell does not share types, modules, lint, or tests with the app. It
re-parses JSON with `jq`/`grep`, duplicates config the TypeScript already
knows, mishandles quoting and `set -e` pipelines, and fails in CI with
errors the typechecker never saw.

This ADR applies when the project's own code is TypeScript. Nix flakes,
CI YAML, protobuf, SQL schema, and JSON config do not make the project
polyglot. A repo that also ships application code in Rust, Go, Python, or
another language is out of scope.

The [ADR-0002](0002-standard-project-command-surface.md) command surface
(`install`, `setup`, `ci`, …) still applies. This ADR constrains how a
TypeScript-only repo implements that surface, not the names.

## Decision

In a TypeScript-only project, utility and operations scripts MUST be
TypeScript. There must be no bash/shell programs, and no Python/Ruby/Perl
stand-ins, for that work.

Covered: `scripts/`, `tools/`, codegen, migrate/seed, release, doctor,
local service orchestration, git hooks in the repo, and CI steps that are
more than invoking one command.

Run them with the project's TypeScript runner (Bun in darkmatter TS
repos). Typical shape: `scripts/ci.ts` invoked as `bun scripts/ci.ts`, or
an executable file with `#!/usr/bin/env bun`.

Allowed dispatchers — these are not a second implementation language:

- `just` recipes and `package.json` / Turbo scripts that only exec the
  TypeScript entrypoint
- CI YAML that only invokes that entrypoint
- Nix that provides the runner and tools

Narrow POSIX exception: a trampoline with no product logic, only (a)
bootstrap the TypeScript runtime (`install`, per ADR-0002's host floor),
or (b) `exec` into `nix develop` then Bun. No JSON parsing, no loops over
files, no test/lint orchestration, no `jq`.

Do not add new `.sh` files. Convert existing ones when touched.

## Consequences

**Upside**

- Ops code is typechecked, linted, and testable with the rest of the
  repo. Config and domain types are imported, not re-stringified.
- CI and local `ci` run the same TypeScript. Failures look like the rest
  of the program, not a quoting bug in bash.
- Agents stop inventing a parallel bash dialect per repo.

**Costs**

- A short bash snippet is sometimes fewer characters. We pay TypeScript
  ceremony to buy out the language-boundary bug class.
- `install` still needs a POSIX bootstrap until Bun is on `PATH`.
- Existing `.sh` files are debt until converted.

## Alternatives considered

- **Bash for ops, TypeScript for the app.** Status quo. Rejected: that
  boundary is where CI and repo bugs have actually clustered.
- **Just/Make as the programming language.** Rejected. Recipe files may
  dispatch; they must not grow control flow, JSON munging, or tests.
- **Polyglot exception for "simple" shell.** Rejected. Simple scripts
  accumulate. If it is a program, it is TypeScript.
- **Apply this to mixed-language repos.** Out of scope. A Rust+TS
  monorepo can keep each island's tooling in that island's language;
  this ADR does not decide that layout.

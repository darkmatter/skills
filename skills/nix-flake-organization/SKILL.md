---
name: nix-flake-organization
description: Use when reorganizing Nix flakes, NixOS modules, nix-darwin modules, Home Manager modules, hosts, packages, or devshells into the blueprint-style folder convention nested under nix/, where file paths map 1:1 to flake outputs.
---

# Nix flake organization

Organize flakes with the [numtide/blueprint](https://github.com/numtide/blueprint) folder convention, nested under a top-level `nix/` directory (blueprint's `prefix = "nix/"`). `flake.nix` stays a minimal entrypoint; every other output lives in a file under `nix/` whose path determines its output attribute. There is no separate glue layer: the file at the mapped path *is* the implementation. Outputs the mapping cannot express (such as `apps` or compatibility aliases) may keep explicit wiring beside the blueprint invocation, but their implementations still live under `nix/`.

Apply [codebase-design](../codebase-design/SKILL.md) within those boundaries:
keep each output's implementation together with its mapped file and extract
only to hide complexity or enable useful reuse. Preserve Nix's roles rather
than imposing TypeScript `models/` and `services/` directories.

## When to use

- A user asks to reorganize or refactor a Nix flake layout.
- Flake outputs are crowded into `flake.nix` or spread across ad-hoc directories.
- A repo mixes packages, modules, hosts, and devshells without a predictable mapping from file path to output name.

## When NOT to use

- The task is only to add one package, app, or module without changing repo layout.
- The repo is not a Nix flake.
- The user explicitly wants a different established project layout preserved.

## Canonical prompt

Use this improved prompt when turning the request into an implementation plan:

> Reorganize this repo to the blueprint folder convention nested under `nix/`: `nix/packages/<pname>(.nix|/default.nix)`, `nix/devshells/<name>.nix` (or `nix/devshell.nix` for the default), `nix/checks/<pname>.nix`, `nix/formatter.nix`, `nix/lib/default.nix`, `nix/modules/{nixos,darwin,home}/<name>(.nix|/default.nix)`, `nix/hosts/<hostname>/configuration.nix`, and `nix/templates/<name>/` where applicable. Keep `flake.nix` as a minimal entrypoint that wires inputs and loads the `nix/` tree — prefer `inputs.blueprint { inherit inputs; prefix = "nix/"; }`, adding explicit wiring beside it only for outputs the mapping cannot express. Each per-system mapped file (packages, devshells, checks, formatter) takes the standard arguments (`pkgs`, `inputs`, `flake`, `system`, `perSystem`, and `pname` for packages/checks) and returns its implementation directly; module files are plain modules. Preserve existing output attribute names during structural moves; follow the repository's compatibility policy when changing the public interface. Verify with `nix flake show`, `nix flake check`, and representative package/module evals or builds.

## Folder-to-output mapping

Prefer this structure, adapting names to the existing repo. The path of a file determines its flake output:

| Path                                             | Flake output                                         |
| ------------------------------------------------ | ---------------------------------------------------- |
| `nix/package.nix`                                | `packages.<system>.default`                          |
| `nix/packages/<pname>(.nix\|/default.nix)`       | `packages.<system>.<pname>`                          |
| `nix/devshell.nix`                               | `devShells.<system>.default`                         |
| `nix/devshells/<name>(.nix\|/default.nix)`       | `devShells.<system>.<name>`                          |
| `nix/formatter.nix`                              | `formatter.<system>`                                 |
| `nix/checks/<pname>(.nix\|/default.nix)`         | `checks.<system>.<pname>`                            |
| `nix/lib/default.nix`                            | `lib`                                                |
| `nix/modules/nixos/<name>(.nix\|/default.nix)`   | `nixosModules.<name>`                                |
| `nix/modules/darwin/<name>(.nix\|/default.nix)`  | `darwinModules.<name>`                               |
| `nix/modules/home/<name>(.nix\|/default.nix)`    | `homeModules.<name>`                                 |
| `nix/modules/<type>/<name>`                      | `modules.<type>.<name>`                              |
| `nix/hosts/<hostname>/configuration.nix`         | `nixosConfigurations.<hostname>`                     |
| `nix/hosts/<hostname>/darwin-configuration.nix`  | `darwinConfigurations.<hostname>`                    |
| `nix/templates/<name>/`                          | `templates.<name>`                                   |

Packages also feed `checks.<system>.pkgs-<pname>` (plus their `passthru.tests`), and hosts feed `checks.<system>.nixos-<hostname>`, so `nix flake check` covers them automatically.

## File contract

Per-system files (packages, devshells, checks, formatter) are functions taking:

- `pkgs`: the nixpkgs instance for the current system.
- `inputs`: the flake inputs.
- `flake`: shorthand for `inputs.self`.
- `system`: the current system string.
- `perSystem`: packages of all inputs filtered per system, e.g. `perSystem.devshell.mkShell`. Use `perSystem.self.<pname>` to consume sibling packages.
- `pname` (packages and checks only): the package name derived from the file or folder name.

Each file returns its implementation directly — a derivation for packages and checks, a shell for devshells, a module for `nix/modules/*`:

```nix
# nix/packages/vpn/default.nix
{ pkgs, perSystem, ... }:
pkgs.buildGoModule {
  pname = "vpn";
  # ...
}

# nix/modules/nixos/vpn.nix
{ config, lib, pkgs, ... }:
{
  options.services.vpn = { ... };
  config = lib.mkIf config.services.vpn.enable { ... };
}
```

Modules may be wrapped in an outer function taking `flake` or `inputs` when they need to reference the defining flake; blueprint calls that function before exposing the module.

## Wiring the flake

Prefer the blueprint library; it replaces the mapping glue entirely:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: inputs.blueprint {
    inherit inputs;
    prefix = "nix/";
  };
}
```

If the repo cannot take the blueprint dependency, or is committed to flake-parts, keep the same `nix/` folder convention and file contracts, and write the mapping explicitly in `flake.nix` or the flake-parts `perSystem` wiring. The wiring may only name outputs and import files from `nix/`; implementations stay in the mapped files. Do not define the same output through two wiring paths.

## Colocation rules

- Helpers, scripts, and data for one output live beside its mapped file: `nix/packages/vpn/{default.nix,vpn.sh}`.
- A concept spanning output types splits along the mapping: package in `nix/packages/vpn/`, NixOS module in `nix/modules/nixos/vpn.nix`. Name the files identically so the concept is findable.
- Shared helpers go in `nix/lib/` and are exposed as the `lib` output; do not create a parallel `src/` or `internal/` tree.
- Keep options, defaults, assertions, and configuration local to the module that explains one feature, even when that makes a module longer. Keep configured file limits; if a cohesive module exceeds one, first look for an independent responsibility, otherwise document a narrow increase or exception.

## Migration workflow

1. Inventory current public outputs: `packages`, `apps`, `devShells`, `formatter`, `lib`, `checks`, `nixosModules`, `darwinModules`, `homeModules`, `nixosConfigurations`, `darwinConfigurations`, `templates`.
2. Preserve the public output schema first. Blueprint derives output names from mapped paths, so choose file names whose derived output names match the existing attributes unless the user requested a breaking change.
3. If current outputs are interleaved in one file, first separate each output family enough that it can move independently; avoid a big-bang rewrite.
4. Add the blueprint input and `prefix = "nix/"`, then move one output family at a time into its mapped path, adapting each file to the file contract above.
5. Watch for renames blueprint forces: `homeManagerModules` becomes `homeModules`, and `apps` have no folder — convert app scripts into packages (`nix run` runs a package's main program) or keep explicit `apps` wiring beside blueprint's outputs.
6. Follow the repository's compatibility policy for renamed outputs. Keep aliases only when that policy requires them; otherwise update consumers and remove obsolete paths.
7. Verify after each family move with `nix flake show`, `nix flake check`, and targeted builds/evals.

## Common mistakes

- Putting the folders at the repo root instead of under `nix/`; the convention here always sets `prefix = "nix/"`.
- Keeping a thin re-export layer between the mapped files and the implementation; the mapped file is the implementation.
- Hiding one output's helpers in `nix/lib/` when they belong beside the output's own file.
- Using `nix/modules/home-manager/` or `nix/modules/hm/`; blueprint's folder name for Home Manager is `home`.
- Forgetting that `packages.<system>` and `devShells.<system>` are system-specific while module outputs are not.
- Defining the same output both through blueprint's folder mapping and through extra manual wiring.
- Expecting `pkgs` to include overlays that were never passed; configure `nixpkgs.config` and `nixpkgs.overlays` in the blueprint invocation.
- Changing public output names during a move-only refactor.
- Skipping verification because the change looks like only path shuffling.

## Templated scripts

When packaging shell scripts, keep reusable script logic in its own source file beside the package's `default.nix` instead of embedding long scripts inline in Nix strings. Use Nix only to substitute package-specific defaults.

Prefer nixpkgs-style `@name@` placeholders with `replaceVars`:

```nix
pkgs.writeTextFile {
  name = "tool";
  destination = "/bin/tool";
  executable = true;
  text = builtins.readFile (pkgs.replaceVars ./tool.sh {
    default_config = builtins.toJSON config;
  });
}
```

In the script, group all Nix substitutions at the top and make runtime values overrideable by arguments or environment variables:

```sh
default_config() {
  cat <<'JSON'
@default_config@
JSON
}

: "${TOOL_JQ:=jq}"

tool_config() {
  if [ -n "${TOOL_CONFIG_JSON:-}" ]; then
    printf '%s\n' "$TOOL_CONFIG_JSON"
  else
    default_config
  fi
}
```

This keeps scripts usable outside Nix, makes the Nix coupling easy to audit, avoids quote-heavy inline shell strings, and matches current nixpkgs conventions now that `substituteAll` has been replaced by `replaceVars`.

## Review checklist

- `flake.nix` contains only inputs and the blueprint (or equivalent minimal) invocation with `prefix = "nix/"`, plus at most explicit wiring for outputs the mapping cannot express.
- Every output's file path matches the folder-to-output mapping table, and output names match the names the table derives from those paths.
- Each mapped file follows the file contract and returns its implementation directly.
- Helpers and scripts are colocated with their output's file; shared code lives in `nix/lib/`.
- Existing public output names still work or have deliberate migration notes.
- Verification commands cover both system-specific outputs and module evaluation paths.
- Templated scripts live in standalone files, use `@name@` placeholders via `replaceVars`, and keep Nix-specific defaults grouped at the top with environment/argument overrides for reusable behavior.

## Tools

None. This is a pure prompt and review skill. Use the repo's existing Nix commands for verification.

## Reference

Blueprint's folder structure and configuration docs: <https://numtide.github.io/blueprint/main/>. The mapping table above mirrors them; when they disagree, the upstream docs win.

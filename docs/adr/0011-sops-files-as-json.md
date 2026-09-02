# 0011 — SOPS-encrypted files are stored as JSON

- **Status:** accepted
- **Date:** 2026-09-01
- **Deciders:** cm

## Context

SOPS can encrypt JSON, YAML, dotenv, INI, and binary. YAML is the format
SOPS examples and Kubernetes/KSOPS workflows default to, so new secret
files tend to land as `*.sops.yaml` or `.env.sops` unless something
pushes the other way.

Darkmatter consumes those files from TypeScript and from Nix. Those two
evaluators do not treat the formats equally:

- TypeScript can `import` JSON (with inferred types via
  `resolveJsonModule` / `with { type: "json" }`). YAML and dotenv need a
  parser, a loader plugin, or a generated intermediate.
- Nix can parse JSON at eval time (`builtins.fromJSON`,
  `lib.importJSON`). YAML has no builtin parser. Getting a Nix attrset
  out of YAML usually means Import From Derivation (IFD): a build that
  runs `yq` (or similar) during evaluation. IFD is slow, breaks pure
  evaluators, and is banned in nixpkgs.

The encrypted document is still valid JSON, so editors, `jq`, TypeScript,
and Nix can see the key set without decrypting. YAML does not give us
that for free.

This ADR is about **encrypted secret documents** (`*.sops.json`). It is
not about SOPS **creation rules**. Those stay in `.sops.yaml`, which is
the file SOPS itself reads.

## Decision

SOPS-encrypted files MUST be stored as JSON. Name them `*.sops.json`.

Do not add new `*.sops.yaml`, `*.sops.yml`, `.env.sops`, or other
non-JSON SOPS payloads. Existing non-JSON files SHOULD be converted when
touched.

The SOPS creation-rules file remains `.sops.yaml`. That file is
configuration for SOPS, not an encrypted document, and is out of scope.

## Consequences

**Upside**

- TypeScript can import the file and type the shape without a YAML
  library or a decrypt-then-codegen step.
- Nix can import the file with `lib.importJSON` / `builtins.fromJSON`.
  No IFD, no `yq` in the eval sandbox.
- `jq` works on the ciphertext document. Agents can list keys without
  printing values.
- One format for app config, env maps, and registry settings.

**Costs**

- JSON has no comments. Put rationale next to the file or in the
  creation-rules path regex, not inside the payload.
- Kubernetes/KSOPS examples are YAML-first. JSON is valid for the
  Kubernetes API; validators and diffs should use `jq` (or
  `sops -d … | jq`) rather than assuming `yq`.
- Existing `*.sops.yaml` and `.env.sops` files are debt until converted.
  Access tooling must still decrypt whatever is already in a repo.

## Alternatives considered

- **YAML (`*.sops.yaml`).** SOPS's default and the usual KSOPS shape.
  Rejected: TypeScript cannot import it natively, and Nix typically needs
  IFD to parse it.
- **dotenv (`.env.sops`).** Convenient for process-env loaders. Rejected:
  not a typed object in TypeScript or Nix. An env map is a JSON object.
- **TOML.** Nix can parse TOML without IFD (`builtins.fromTOML`).
  TypeScript still cannot import it natively. Rejected: JSON is the
  overlap of both languages.
- **Binary / unformatted SOPS.** Opaque; no key inventory without
  decrypting. Rejected.

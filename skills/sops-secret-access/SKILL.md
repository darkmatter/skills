---
name: sops-secret-access
description: Use when a repo stores tool config, API keys, registry URLs, environment variables, or component registry settings in SOPS-encrypted files such as components.sops.json or secrets/*.sops.json, or when a private registry needs a credential from the repo's secret store.
---

# SOPS Secret Access

Use the repo's encrypted source of truth when a task depends on secrets or private tool configuration. Do not infer from public fallback files if a matching `*.sops.*` file exists.

New SOPS payloads are JSON (`*.sops.json`). See [ADR-0011](../../docs/adr/0011-sops-files-as-json.md). Decrypt existing non-JSON files if that is what the repo already has; do not add new ones.

## When to Use

- A project has `components.sops.json`, `secrets/*.sops.json`, or another SOPS-encrypted config.
- A public config looks incomplete and a private registry, API, MCP server, deployment credential, or provider profile may be hidden behind SOPS.
- The task mentions shadcnblocks, private shadcn registries, registry auth, SOPS, secrets, env loading, or encrypted project config.
- A tool only shows public/default config but the repo has a likely encrypted companion file.

## Core Rules

- Decrypt only the file needed for the task.
- Do not paste decrypted contents into chat, logs, commits, or generated docs.
- Prefer commands that consume decrypted data directly or print only non-secret derived facts.
- If a decrypted file is written to disk temporarily, put it in a gitignored path and remove it before finishing.
- Treat plain files like `components.json` as fallbacks when a matching `components.sops.json` exists.

## Registry Credentials

This is the single place for private registry secret access. `shadcn-registry-first` and `run-ui-registry-variations` defer to it; they do not define their own credential recipes.

Resolve the credential from the project's source of truth, in this order:

1. **An encrypted config in the repo.** If `components.sops.json` or `secrets/*.sops.json` exists, it is the authority over a plain `components.json`. Inspect only non-secret structure, and pipe values into the consumer instead of printing the document:

   ```bash
   sops -d components.sops.json | jq -r '.registries | keys[]'
   ```

2. **The repo's documented secret store.** If no SOPS file exists, use the store the repo documents (for example himitsu) and its access command. Do not add a second store, a new `.env` file, or a new `.sops.yaml`.

Common registry environment variable names include `SHADCNBLOCKS_API_KEY`, `SHADCNBLOCKS_TOKEN`, `SHADCNBLOCKS_REGISTRY_TOKEN`, `ACETERNITY_API_KEY`, `ACETERNITY_TOKEN`, and `ACETERNITY_REGISTRY_TOKEN`. Discover the actual names from the repo; this list is not exhaustive.

### Rendering the registry config

The rendered config and a committed public config are different artifacts. Use the branch that matches the repo:

- **Generated, gitignored config.** Some repos commit `components.json.template` and render `components.json` locally. Render with the repo's setup script (for example `scripts/setup-components-json.ts` or `scripts/setup-components-json.sh`), confirm the output path is gitignored, and never force-add it. If the output is not already gitignored, use the public-config or override branch instead of adding an ignore rule for a public file. Rerun the setup when the rendered file is stale; an expired key produces 401 auth failures. If the script reads the key itself, that is the store's access path; do not decrypt a second source.
- **Committed public config.** Other repos commit a `components.json` with no secret. Do not overwrite it with a decrypted value. Use the tool's config override, a temporary sibling file, or a subshell, and leave the public file untouched. If a local replacement is unavoidable, back up the public file, restore it before finishing, and verify `git diff` does not include the credential. Do not add that public file to `.gitignore` and do not delete it.
- **No config file.** If the tool accepts an environment variable or override, keep the credential in the environment and skip the rendered file. Do not create a plaintext config just to satisfy the tool.

If you must write a temporary file, put it outside the repository or in a gitignored path, remove it before finishing, and verify `git status` and `git diff` do not include the credential.

## Common Mistakes

- Querying shadcn MCP before decrypting `components.sops.json`, then concluding only public registries exist.
- Reusing a rendered `components.json` from an older session and treating an expired key as proof that the registry is unavailable.
- Printing full decrypted JSON to the user.
- Committing generated plaintext config.
- Deleting or ignoring a committed public `components.json` to make room for a rendered secret-bearing file.
- Adding secrets to `AGENTS.md`, README files, examples, or tests.
- Creating a new `*.sops.yaml`, `*.sops.yml`, or `.env.sops`. New payloads are `*.sops.json`.

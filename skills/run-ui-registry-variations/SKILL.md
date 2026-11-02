---
name: run-ui-registry-variations
description: 'Manual-invocation skill — run only when the user explicitly asks for "run-ui-registry-variations" or invokes it as a slash command. Do not auto-trigger on adjacent topics. Composes the shadcn-registry-first sourcing/comparison procedure and forces UI work through shadcnblocks, Aceternity, or https://shadcn.darkmatter.io; validate private registry access before use; build exactly three user-reviewable variations.'
---

# run-ui-registry-variations

Manual workflow for UI work that must start from approved component registries instead of hand-rolled interface code. The skill hard-gates registry access, then builds three real variations for the user to compare.

It composes the sourcing, comparison, and audit procedure from `shadcn-registry-first`. This skill's specialization is the approved source allowlist, the private-provider preflight, and exactly three built variations. That is compatible with the shared default of at least three candidates: the shared procedure shortlists, this workflow schedules the built review.

## When to use

- `/run-ui-registry-variations <UI request>`
- The user explicitly says `run-ui-registry-variations`.
- The user asks for three UI options using shadcnblocks, Aceternity, or the Darkmatter shadcn registry.
- The user wants a one-off UI, new no-design-system project surface, or `darkmatter.io` surface and wants registry-backed options.

## When NOT to use

- The user only asks which registry to use. Answer directly or use `ui-ux-pro-max`.
- The project is a flagship app with its own design system and the user did not explicitly invoke this skill.
- The task is backend, infra, copywriting, or non-visual.
- The user asks for one final implementation only and does not want alternatives.

## Contract

1. Use only these component sources for visual structure: `shadcnblocks`, `Aceternity`, or `https://shadcn.darkmatter.io`.
2. Validate registry access before using a source. `shadcnblocks` and `Aceternity` require API-key/token validation; `shadcn.darkmatter.io` requires a live fetch check.
3. Build exactly three variations. Do not stop at descriptions or moodboards.
4. Present all three variations to the user before replacing the default UI path.
5. Preserve secrets. Never print API keys, decrypted registry config, private URLs containing tokens, or generated plaintext credential files. Use `sops-secret-access` for the access procedure.
6. Do not use unapproved component sources as filler. If a source fails validation, use another validated allowed source or stop.
7. Compose the shared search, preview, install, comparison-surface, and audit procedure from `shadcn-registry-first`. Do not invent a parallel registry workflow.

## Workflow

### 1. Scope the target

Identify the target route, component, page, or prototype surface. An existing project design system wins: read it first and keep the variations compatible with it, adapting registry blocks to its tokens rather than replacing it.

For no-design-system Darkmatter work, `darkmatter.io`, and one-off UIs, use `darkmatter-design-system` as the fallback visual language and `https://shadcn.darkmatter.io` as the approved fallback registry.

### 2. Discover registry configuration

Check likely sources in this order:

1. Project docs for registry setup.
2. `components.sops.json`, `secrets/*.sops.json`, or another encrypted project config.
3. Plain `components.json`, `.env.local`, `.env`, or package scripts.

Use `sops-secret-access` for any encrypted config and for the provider credentials. It owns the access procedure, including the common token names and the no-print/no-commit rules. Do not restate or invent a second secret recipe here.

### 3. Validate access

Always attempt private-provider preflight for both `shadcnblocks` and `Aceternity`, even if the likely fallback is `shadcn.darkmatter.io`. Resolve each token through `sops-secret-access`. If no key is available for a private provider, mark that provider blocked and do not use it.

For each intended source:

- `shadcnblocks`: prove an API key/token is present and accepted by an authenticated registry request.
- `Aceternity`: prove an API key/token is present and accepted by an authenticated registry request.
- `shadcn.darkmatter.io`: prove the registry endpoint is reachable with `curl` or the project's registry tooling.

Use this skill's `scripts/validate-registry-access.ts` (see Tools) when the registry URL and env var name are known. If the project uses custom registry tooling, run the smallest read-only command that fetches a registry index or one known component.

If a private provider fails validation, do not use that provider in a variation. Continue with any validated allowed source; if no allowed source validates, stop and report the blocked provider checks.

### 4. Select components

Apply the `shadcn-registry-first` search, shortlist, and preview procedure to the validated sources; use the equivalent read-only registry tooling for a source the shadcn MCP does not expose. This skill specializes the approved source set and the output count.

Each variation must cite the source registry and concrete components/blocks used. Prefer three distinct sources when all are available:

1. Variation A: `shadcnblocks`
2. Variation B: `Aceternity`
3. Variation C: `shadcn.darkmatter.io`

If only one or two sources validate, build all three variations from the validated source set; all visual structure must come from it.

### 5. Build three variations

Use the shared isolated-install and comparison-surface procedure from `shadcn-registry-first`, then build exactly three variations. Create real code artifacts, not only prose:

- Use separate component files, clearly named exports, a preview route, tabs, Storybook stories, or another local pattern that lets the user compare all three.
- Keep data contracts and business logic shared; vary layout, density, interaction treatment, and visual emphasis.
- Do not wire one variation as the final default until the user chooses.
- Avoid raw, custom-only Tailwind shells unless they wrap or compose registry components.

### 6. Verify and present

Run the app's normal frontend checks for the touched surface and apply the shared `shadcn-registry-first` verification and audit expectations. When a browser preview is possible, capture or inspect all three variations at desktop and mobile widths.

Present the result using `reference/variation-template.md`. Include:

- Validation status for `shadcnblocks`, `Aceternity`, and `shadcn.darkmatter.io`.
- Source registry and components used for each variation.
- Local path/route for review.
- Any blocked provider and the non-secret reason.

## Tools

### `scripts/validate-registry-access.ts`

Validates that a registry endpoint is reachable, optionally using a token from an environment variable without printing the token.

```bash
bun skills/run-ui-registry-variations/scripts/validate-registry-access.ts \
  shadcnblocks "$SHADCNBLOCKS_REGISTRY_URL" SHADCNBLOCKS_API_KEY

bun skills/run-ui-registry-variations/scripts/validate-registry-access.ts \
  aceternity "$ACETERNITY_REGISTRY_URL" ACETERNITY_API_KEY

bun skills/run-ui-registry-variations/scripts/validate-registry-access.ts \
  shadcn-darkmatter https://shadcn.darkmatter.io
```

**Deps:** Bun (`fetch`). If tokens live in encrypted config, load them into the environment through `sops-secret-access` first; do not print or commit them.

## Reference

- `reference/variation-template.md` — output format for presenting the three variations and provider validation evidence.

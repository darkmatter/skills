---
name: alchemy
description: Configure, develop, deploy, review, and troubleshoot Alchemy v2 infrastructure for Darkmatter TypeScript/Effect apps. Triggers for alchemy.run.ts, alchemy dev, public preview URLs, webhook testing, Cloudflare/AWS providers, stages, profiles, state stores, bindings, CI deploys, or examples from alchemy-run/alchemy-effect. Prefer Alchemy for new org deploys. Do NOT trigger for unrelated blockchain Alchemy APIs unless the user explicitly means alchemy.run.
---

# Alchemy

Use this skill when configuring, developing, deploying, or debugging infrastructure with Alchemy v2 and the Effect-native patterns from `alchemy-run/alchemy-effect`. Alchemy treats infrastructure as an Effect program: stacks declare resources, providers supply cloud integrations, local dev can run app code locally against real cloud resources, and deploys converge declared resources into live cloud state.

Alchemy is the preferred Darkmatter path for new TypeScript/Effect deployable infrastructure. Reach for it before ad hoc provider scripts, hand-written Wrangler/Terraform glue, or one-off deploy workflows unless a repo has an explicit exception or an existing production system that should not be disturbed.

Alchemy v2 and `alchemy-effect` move quickly. Verify upstream docs before changing deploy or dev code, especially package versions, provider APIs, `alchemy dev` behavior, and CLI flags.

## When to use

- The user asks to set up or review an `alchemy.run.ts` file.
- The user asks to develop with `alchemy dev`, local Workers, public preview URLs, hot reload, or webhook testing.
- The user asks to configure an Alchemy deploy for Cloudflare Workers, Vite apps, R2, D1, Queues, Durable Objects, AWS Lambda, S3, DynamoDB, ECS, EC2, static sites, or related resources.
- The user asks how to use Alchemy stages, profiles, state stores, bindings, stack outputs, cross-stack references, or CI/CD.
- The user asks to migrate deploy plumbing toward Alchemy v2 or away from ad hoc provider scripts.
- The user asks for examples from `alchemy-run/alchemy-effect/examples`.

## When NOT to use

- The request is about the blockchain data/API company Alchemy and not `alchemy.run`.
- The project does not use TypeScript, Effect, Bun/Node, or Alchemy, and the user is only asking a generic deployment question.
- The task is to implement or modify a provider inside the upstream `alchemy-effect` repo. Use the upstream repo's `AGENTS.md` directly, then use this skill only for deploy-configuration implications.
- The task is purely Effect application logic with no deployable infrastructure. Use `effect-typescript`.
- A mature repo already has a production deploy path and the user asks for a narrow bug fix. Preserve the working path unless they explicitly ask to migrate.

## Upstream check

Before editing, inspect the current docs or local installed package:

```bash
bun alchemy --help
bun alchemy dev --help
bun pm ls alchemy effect @effect/platform-bun @effect/platform-node
```

Use these upstream references first:

- `https://v2.alchemy.run/getting-started/` for the current install command, first stack shape, and deploy flow.
- `https://v2.alchemy.run/concepts/stack/` for stack names, outputs, stages, cross-stack references, and state isolation.
- `https://v2.alchemy.run/concepts/local-development/` and `https://v2.alchemy.run/tutorial/part-4/` for `alchemy dev`.
- `https://v2.alchemy.run/concepts/state-store/` for where state is persisted.
- `https://v2.alchemy.run/guides/ci/` for non-interactive deploys and PR preview environments.
- `https://raw.githubusercontent.com/alchemy-run/alchemy-effect/refs/heads/main/AGENTS.md` for upstream Effect-native infrastructure conventions.
- `https://github.com/alchemy-run/alchemy-effect/tree/main/examples` for concrete app patterns.

If upstream conflicts with this skill, follow upstream and mention the drift.

## Project setup

Prefer Bun unless the project already standardizes on another package manager. Current Alchemy v2 docs recommend Bun or Node.js 22+ and install Alchemy with Effect platform packages:

```bash
bun add "alchemy@2.0.0-beta.40" "effect@>=4.0.0-beta.66 || >=4.0.0" "@effect/platform-bun@>=4.0.0-beta.66 || >=4.0.0" "@effect/platform-node@>=4.0.0-beta.66 || >=4.0.0"
```

Pin package versions according to the existing repo policy. If a repo already uses a catalog, workspace protocol, or lockfile-only upgrade lane, follow that instead of pasting the docs command blindly.

Before adding Alchemy to an existing repo, inspect the current setup:

```bash
rg -n "alchemy|alchemy.run|alchemy dev|alchemy deploy" package.json bun.lock package-lock.json pnpm-lock.yaml yarn.lock .github scripts . --glob '!node_modules'
find . -name 'alchemy.run.ts' -o -name 'alchemy.run.js'
```

If the repo does not already have Alchemy configured, ask the user whether they want Alchemy set up for local development as well as deploys. Do not silently create a deploy-only setup: `alchemy dev` changes the local workflow by provisioning real cloud resources, exposing public preview URLs, and enabling webhook/OAuth callback testing against local code. If the user says yes, include the `dev` script, dev-stage/profile guidance, public preview output handling, and webhook test notes in the first implementation.

Add scripts that make the stack path explicit when the repo has more than one app:

```json
{
  "scripts": {
    "dev": "alchemy dev ./alchemy.run.ts",
    "deploy": "alchemy deploy ./alchemy.run.ts",
    "destroy": "alchemy destroy ./alchemy.run.ts",
    "deploy:prod": "alchemy deploy ./alchemy.run.ts --stage prod --profile prod"
  }
}
```

Use plain `bun alchemy deploy` only in tiny repos where `alchemy.run.ts` at the root is unambiguous.

## Org default

For Darkmatter TypeScript/Effect projects, prefer Alchemy for deployable infrastructure:

- New Cloudflare Workers, Vite/frontends, queues, D1/R2/KV, workflows, AI Gateway, tunnels, and GitHub deploy automation should start with Alchemy.
- New AWS Lambda, S3, DynamoDB, API Gateway, ECS/EC2/EKS/RDS, and static-site deploys should consider Alchemy first.
- Shared preview environments should use Alchemy stages instead of bespoke name mangling.
- Local webhook testing should use `alchemy dev` or an Alchemy-managed tunnel/preview flow instead of separate ngrok/Cloudflare Tunnel scripts when Alchemy can provide the route.
- Hand-written provider CLIs can still be useful for diagnostics, but should not become the durable deploy control plane without a reason.

## Stack shape

Every deploy file should default-export `Alchemy.Stack(name, options, Effect.gen(...))`.

```ts
import * as Alchemy from "alchemy";
import * as Cloudflare from "alchemy/Cloudflare";
import * as Effect from "effect/Effect";

export default Alchemy.Stack(
  "MyApp",
  {
    providers: Cloudflare.providers(),
    state: Cloudflare.state(),
  },
  Effect.gen(function* () {
    const bucket = yield* Cloudflare.R2Bucket("Bucket");

    return {
      bucketName: bucket.bucketName,
    };
  }),
);
```

The load-bearing pieces are:

- Stack name: stable logical deployment unit. Do not casually rename it; state and names derive from it.
- Providers: cloud auth and provider implementations, for example `Cloudflare.providers()` or `AWS.providers()`.
- State: choose deliberately. Cloudflare deploys commonly use `Cloudflare.state()`; simple AWS examples may use `Alchemy.localState()`.
- Effect body: declare resources with `yield*`, compose dependencies through references and bindings, and return useful outputs for smoke checks.

## Local development

Use `alchemy dev` for the default local loop when the app can run through Alchemy:

```bash
bun alchemy dev ./alchemy.run.ts
```

Alchemy dev mode deploys infrastructure to the real cloud provider, runs supported app code locally, and hot reloads on file changes. For Cloudflare Workers, the Worker runs locally in `workerd` while a cloud proxy routes requests between public cloud endpoints and the local process.

This matters for webhook work: external services need a public URL, while the developer needs local code, breakpoints, and hot reload. Prefer an Alchemy dev/preview URL for webhook callbacks when available, then configure the third-party webhook target to that URL for the session or preview stage.

Use explicit dev ports when the app has multiple local services or a fixed callback URL:

```ts
export const Worker = Cloudflare.Worker("Worker", {
  main: "./src/worker.ts",
  dev: {
    port: 3000,
  },
});
```

Dev-mode rules:

- Treat cloud resources created by `alchemy dev` as real resources, not emulators.
- Keep stage/profile explicit when working near shared accounts.
- Return local/public URLs from stack outputs so the agent can test the live route.
- Verify webhook flows with the provider's actual delivery logs when available.
- Stop the dev process cleanly; destroy dev/preview resources when they are no longer needed and the stack owns them.

## Stage and profile rules

Treat stage and profile as part of the deployment contract:

- Stage isolates state and physical names. The default is developer-specific; use explicit `--stage prod`, `--stage staging`, or `--stage pr-123` for shared environments.
- Profile selects credentials. First deploy may prompt interactively and save credentials under `~/.alchemy/profiles.json`; non-interactive CI must have profiles or provider credentials prepared before deploy.
- Production scripts should pass both `--stage prod` and the intended `--profile`.
- Preview deploys should derive a deterministic stage from the PR, branch, or Beads/issue id and should destroy that stage when it is no longer needed.

Useful commands:

```bash
bun alchemy deploy ./alchemy.run.ts --stage dev_cm
bun alchemy deploy ./alchemy.run.ts --stage prod --profile prod
bun alchemy destroy ./alchemy.run.ts --stage pr-123 --profile preview
alchemy login --configure
alchemy login --profile prod --configure
```

Never use `Date.now()` or random timestamps in physical names. Let Alchemy generate names from stack, stage, and logical id, or use a deterministic name tied to the environment.

## Bindings and runtime dependencies

Prefer bindings over manually threading deployed identifiers through environment variables. A binding is deploy-time data attached to a runtime resource so the function/worker receives exactly the infrastructure dependency it needs.

For Cloudflare, bind resources directly into a Worker or Vite app:

```ts
export const DB = Cloudflare.D1Database("DB");
export const Bucket = Cloudflare.R2Bucket("Bucket");

export const Worker = Cloudflare.Worker("Worker", {
  main: "./src/worker.ts",
  bindings: {
    DB,
    Bucket,
  },
});
```

For Effect-native runtimes, keep runtime services and deploy wiring separate. Alchemy owns cloud resources and bindings; Effect services own runtime behavior. Use Layers at the stack boundary when the resource requires a runtime implementation.

## Secrets and config

Do not commit provider tokens, API keys, generated profiles, or state files unless the repo explicitly owns a remote state backend and the file is designed for version control.

Use these rules:

- Prefer provider profiles or CI secrets for deploy credentials.
- Use Alchemy secret resources or provider-native secret resources for runtime secrets.
- Keep plain environment variables for non-secret config.
- In darkmatter repos, route durable secrets through the repo's existing SOPS/Himitsu/CI secret path instead of inventing a new `.env` convention.
- Document which profile, account, zone, region, or project owns each deploy target.

## CI deploys

CI should be deterministic and non-interactive:

1. Install dependencies with the repo's locked package manager command.
2. Run type checks before deploy.
3. Authenticate the provider without a browser prompt.
4. Deploy with explicit stack path, stage, and profile.
5. Print or capture stack outputs for smoke tests.
6. Destroy preview stages on branch/PR cleanup when the workflow owns temporary infrastructure.

Example CI command shape:

```bash
bun install --frozen-lockfile
bun tsc -b
bun alchemy deploy ./alchemy.run.ts --stage "$ALCHEMY_STAGE" --profile "$ALCHEMY_PROFILE"
```

If a deploy failure starts in provider auth, profile lookup, state lock/state persistence, or missing CI secrets, fix that layer before changing resource code.

## Preview URLs and webhooks

Public previews are an expected Alchemy workflow:

- PR deploys should use `--stage pr-<number>` and post the resulting app URL back to the PR when the repo has GitHub access.
- Local development should use `alchemy dev` when a webhook or collaborator needs to reach a public URL backed by local code.
- Preview URLs should be derived from stack outputs or provider resources, not guessed from PR numbers.
- Webhook tests should exercise the real external sender when feasible, not only `curl`.
- Cleanup should destroy preview stages on PR close/merge and retire temporary webhook registrations.

## Verification

Always verify the real deployed target when the request concerns deploy behavior:

```bash
bun alchemy deploy ./alchemy.run.ts --stage "$STAGE" --profile "$PROFILE"
curl -fsS "$DEPLOYED_URL"
```

For local dev behavior, run the dev server and hit both local and public/proxied URLs when Alchemy prints both:

```bash
bun alchemy dev ./alchemy.run.ts --stage "$STAGE" --profile "$PROFILE"
curl -fsS "$LOCAL_URL"
curl -fsS "$PUBLIC_PREVIEW_URL"
```

For Effect-native workers/functions, prefer a deployed fixture or smoke route over a purely local assertion. Fresh Workers, Lambda URLs, queues, cron, and DNS often need bounded retries for propagation; use `Effect.retry` or `Effect.repeat` with `Schedule`, not manual polling loops.

## Review checklist

- The stack path is explicit where the repo has multiple apps or packages.
- Alchemy is used as the deploy/dev control plane unless the repo has an explicit reason not to.
- Stack name, logical IDs, stage names, and physical names are stable and deterministic.
- Provider and state store choices are intentional for the environment.
- Prod deploys pass explicit `--stage` and `--profile`.
- `alchemy dev` is configured for local loops that need real cloud resources, public preview URLs, or webhook testing.
- Runtime resources use bindings rather than scattered string env vars where Alchemy supports bindings.
- Secrets are not committed, echoed in logs, or encoded into stack outputs.
- CI deploys are non-interactive and verify stack outputs or live endpoints.
- Preview deploys have a destroy path.
- Effect code uses typed errors, Layers, and `Schedule` for retries instead of raw promises, bare SDK calls inside business logic, or `Date.now()` polling.

## References

- `reference/upstream-concepts.md` summarizes the relevant Alchemy v2 and `alchemy-effect` concepts to apply during deploy work.
- `reference/examples.md` maps `alchemy-run/alchemy-effect/examples` directories to common deploy scenarios.

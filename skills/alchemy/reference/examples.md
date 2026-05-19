# Upstream Examples Map

Use the `alchemy-run/alchemy-effect/examples` tree as a pattern library. Prefer linking to upstream and adapting the smallest relevant pattern instead of copying whole examples into a project.

Upstream root: `https://github.com/alchemy-run/alchemy-effect/tree/main/examples`

## First choices by deploy shape

| Scenario | Start with | What to inspect |
| --- | --- | --- |
| Basic Cloudflare Worker with R2, D1, Queue, Durable Object, assets, and secrets | `examples/cloudflare-worker` | `alchemy.run.ts`, worker bindings, queue consumer registration, `Cloudflare.InferEnv` |
| Async Cloudflare Worker and Durable Object wiring | `examples/cloudflare-worker-async` | Worker + DO namespace declaration and binding shape |
| Local Cloudflare development with multiple workers and `alchemy dev` | `examples/cloudflare-dev` | Multiple worker outputs, DO binding, dev ports, and feedback loops |
| TanStack app on Cloudflare | `examples/cloudflare-tanstack` | `Cloudflare.Vite`, backend worker binding, `nodejs_compat` |
| Solid/Vue frontend deploys | `examples/cloudflare-solidstart`, `examples/cloudflare-solidjs-ssr`, `examples/cloudflare-vue` | Framework-specific Vite/SSR wiring |
| Cloudflare + Neon + Drizzle | `examples/cloudflare-neon-drizzle` | Database binding and migration shape |
| Cloudflare secrets | `examples/cloudflare-secrets-store` | Secret storage and Worker access pattern |
| Cloudflare email routing | `examples/cloudflare-email` | Email routing resources and worker integration |
| Git-backed artifacts on Cloudflare | `examples/cloudflare-git-artifacts` | Build/artifact resource flow |
| AWS Lambda function | `examples/aws-lambda` | `AWS.providers()`, `Alchemy.localState()`, Lambda outputs, CloudWatch dashboard/alarm |
| AWS Lambda with HTTP API | `examples/aws-lambda-httpapi` | API Gateway / function URL style HTTP deploy |
| AWS Lambda RPC | `examples/aws-lambda-rpc` | Effect RPC-style runtime wiring |
| AWS REST API | `examples/aws-rest-api` | API Gateway v1 resources |
| AWS static site or Vite | `examples/aws-static-site`, `examples/aws-vite` | Static assets, CDN/site deploy shape |
| AWS EC2/ECS/EKS/RDS | `examples/aws-ec2`, `examples/aws-ecs`, `examples/aws-eks`, `examples/aws-rds` | Long-lived infrastructure resources and provider/region assumptions |
| Monorepo, one stack | `examples/monorepo-single-stack` | Package layout with one deploy unit |
| Monorepo, multiple stacks | `examples/monorepo-multi-stack` | Stack boundaries and deploy ordering |

## Current example directories

These directories existed upstream when this reference was written:

- `aws-ec2`
- `aws-ecs`
- `aws-eks`
- `aws-lambda`
- `aws-lambda-httpapi`
- `aws-lambda-rpc`
- `aws-rds`
- `aws-rest-api`
- `aws-static-site`
- `aws-vite`
- `cloudflare-dev`
- `cloudflare-email`
- `cloudflare-git-artifacts`
- `cloudflare-neon-drizzle`
- `cloudflare-secrets-store`
- `cloudflare-solidjs-ssr`
- `cloudflare-solidstart`
- `cloudflare-static-site`
- `cloudflare-tanstack`
- `cloudflare-vue`
- `cloudflare-worker`
- `cloudflare-worker-async`
- `monorepo-multi-stack`
- `monorepo-single-stack`

Refresh the list before relying on it:

```bash
curl -s 'https://api.github.com/repos/alchemy-run/alchemy-effect/contents/examples?ref=main' \
  | jq -r '.[] | select(.type == "dir") | .name' \
  | sort
```

## Patterns worth copying

### Cloudflare Worker

`examples/cloudflare-worker/alchemy.run.ts` demonstrates a deploy stack that declares D1, R2, Queue, Durable Object namespace, Worker assets, a redacted API key, and a queue consumer. It returns the Worker URL.

Use it when you need to wire multiple Cloudflare resources into one Worker and verify binding inference.

### Cloudflare Dev

`examples/cloudflare-dev/alchemy.run.ts` demonstrates resources shaped for `alchemy dev`, including multiple Workers and Durable Object bindings. Use it when the local development path matters as much as deploy: public preview routes, webhook callbacks, hot reload, and debugger-friendly Workers.

### Cloudflare Vite / TanStack

`examples/cloudflare-tanstack/alchemy.run.ts` demonstrates a backend worker plus `Cloudflare.Vite("Website", ...)` with bindings and compatibility flags. It returns both backend and website URLs.

Use it when a frontend deploy needs to bind directly to backend infrastructure instead of shipping hard-coded env strings.

### AWS Lambda

`examples/aws-lambda/alchemy.run.ts` demonstrates `AWS.providers()`, `Alchemy.localState()`, a Lambda function, and CloudWatch dashboard/alarm resources built around function outputs.

Use it when an AWS deploy needs function outputs to feed observability resources.

### Monorepos

Use the monorepo examples when deciding whether a repo should have one shared stack or several package-owned stacks. Prefer explicit stack paths in package scripts so CI does not depend on the current working directory.

## Adaptation checklist

- Preserve the upstream example's provider/state pairing unless the target repo has a stronger convention.
- Rename stack and logical IDs deliberately; do not preserve demo names in production.
- Replace demo secrets and fake values with repo-approved secret plumbing.
- Add stage/profile scripts for every shared environment.
- Add a `dev` script for projects where `alchemy dev` should be the standard local loop.
- Add a smoke check that consumes returned stack outputs.
- For webhook-driven apps, document which output URL should be registered with the external provider during dev or preview testing.
- Keep references as links to upstream examples so the local docs do not drift.

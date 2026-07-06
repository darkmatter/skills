# 0008 — Decouple telemetry concerns

- **Status:** accepted
- **Date:** 2026-05-22
- **Deciders:** cm

## Context

The reflex after launching an MVP is to wire in a provider SDK directly —
Sentry for errors, PostHog or GA for analytics, a session replayer, a log
aggregator. Over the years a long parade of providers have come and gone, and
each one leaves behind a layer of provider-specific SDK calls, wrapper
functions, and import paths threaded through application code. Ripping any of
them out later is a multi-day project because the coupling is everywhere.

OpenTelemetry has matured to the point where this coupling is no longer
necessary. The specs are stable, the SDKs are well-supported across our
runtimes, and every observability vendor we'd consider integrates as an OTel
exporter. There is no longer a reason for app code to know which provider is
on the other end.

This decision has been in effect since 2026-05-22 (referenced informally as
"OTel-only observability" in org-level agent instructions) but was never
filed as a numbered ADR in this repo — it existed only as a fully-written page
in the `darkmatter/obsidian` wiki. This file backports that decision into the
ADR log that's supposed to be its source of truth.

## Decision

App code depends on the OpenTelemetry SDKs and nothing else. Provider-specific
packages (`@sentry/*`, PostHog clients, Datadog browser SDKs, and the like) do
not appear in app source. They are wired in once, at the edge, inside a shared
package, and exposed to apps only as OTel exporters or instrumentation
plugins.

Concretely:

1. **No provider imports in `apps/*`.** Apps import OTel APIs
   (`@opentelemetry/api`, the runtime SDK, instrumentation packages). They
   never import `@sentry/node`, `posthog-js`, or any equivalent directly.
2. **Provider wiring lives in a shared package.** Configuration of exporters,
   credentials, sampling, and provider-specific quirks lives under
   `packages/common/providers/` (or the equivalent shared location for the
   repo).
3. **Swapping a provider is a config change, not a refactor.** Adding or
   removing a telemetry, analytics, logging, or error-tracking backend should
   be doable in under a day without touching application code.

## Consequences

- Good, because swapping a telemetry/analytics/error-tracking provider is a
  config change, not a refactor
- Good, because application code never imports provider-specific SDKs,
  eliminating vendor lock-in at the source level
- Good, because adding a new backend takes under a day without touching app
  code
- Bad, because all telemetry must go through the OTel abstraction, which may
  limit access to provider-specific features until an instrumentation plugin
  exists
- Bad, because the shared provider package becomes a dependency for every app
  that uses telemetry

## Alternatives considered

- **Continue wiring provider-specific SDKs directly into application code.**
  Rejected — this is the status quo pain the decision addresses.
- **Build internal wrapper abstractions for each provider.** Rejected — this
  still requires app code to import and depend on the wrapper's shape per
  provider, and the wrapper itself becomes a maintenance burden as providers
  change their APIs. OTel already is that abstraction, maintained upstream.

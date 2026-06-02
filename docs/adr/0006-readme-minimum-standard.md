# 0006 — README minimum standard

- **Status:** accepted
- **Date:** 2026-06-02
- **Deciders:** cm

## Context

Every repository has a README, but the quality and shape of those READMEs
drifts unless the expected shape is named. When a human or an agent opens an
unfamiliar repo, the README is the first place they look for answers:

- What is this repo?
- Should I use it directly, or is it only internal infrastructure?
- How do I install or set it up?
- What command proves the checkout works?
- How do I run the main thing?
- Where do configuration, secrets, generated files, tests, and contribution
  rules live?

When those answers are missing or renamed per repo, every contributor pays a
discovery tax. Agents are especially sensitive to this: if a README reliably
contains a quickstart and copy/paste-able commands, an agent can bootstrap a
repo from the README instead of inferring behavior from package-manager files,
CI configs, or stale tribal knowledge.

[Standard Readme](https://github.com/RichardLitt/standard-readme/blob/main/spec.md)
already defines a useful cross-ecosystem baseline: predictable README
capitalization, required title and short description, ordered sections,
copy/paste-able install and usage examples, contributing guidance, and license
last. Darkmatter should build on that baseline rather than inventing an
unrelated README style.

## Decision

Darkmatter project READMEs MUST follow Standard Readme as the default structure
and section vocabulary. They MAY add project-specific sections, but those
sections must not replace the common onboarding anchors.

At minimum, every non-trivial project README MUST include:

1. **Title and short description.** The title should match the repo or package
   name, and the short description should fit on one line.
2. **Long description when needed.** Use the opening paragraphs or
   `## Background` to explain what the repo is for, who should use it, and any
   important scope boundaries.
3. **Table of contents for long READMEs.** Follow Standard Readme's threshold:
   required for READMEs over 100 lines, optional below that.
4. **Install.** Include a copy/paste-able command block that installs host
   tools or project prerequisites. If install does not apply, say why.
5. **Usage.** Include a copy/paste-able command block that runs the primary
   workflow. For runnable repos, the first part of `## Usage` SHOULD be a
   quickstart path from fresh clone to a useful result.
6. **Development command surface.** Document the repo's standard commands,
   or link to the scripts/justfile section that does. This should align with
   ADR-0002's standard project command surface: install, setup, server/run,
   test, build, ci, and console where applicable.
7. **Configuration and secrets.** If the repo needs environment variables,
   local config, generated files, or secret access, document where those come
   from without exposing secret values.
8. **Testing or verification.** Include the command a maintainer expects a
   contributor or agent to run before claiming the repo works.
9. **Contributing.** State where questions go, whether PRs are accepted, and
   any contribution requirements.
10. **License.** State the license or `UNLICENSED`, and keep this as the last
    section.

Copy/paste-able means commands should run as written from the repo root after
the preceding README steps. Placeholders are allowed only when unavoidable, and
they should be obvious shell variables with concrete examples nearby.

Documentation-only repositories may omit install or runnable usage sections
only when they say explicitly that the repo has no executable project surface
and provide the equivalent reading or publishing path.

## Consequences

**Upside**

- A new contributor can open any Darkmatter repo and know where to find the
  same onboarding facts.
- Agents can bootstrap and verify repos from the README before reaching for
  inference or repo-specific guesswork.
- README review becomes objective: missing install, usage, quickstart,
  verification, contribution, or license content is a concrete gap.
- The rule composes with ADR-0002. The README tells readers what the command
  surface is; the repo implements the commands.

**Costs**

- Existing READMEs need cleanup when they omit common sections or bury commands
  under project-specific names.
- Some repos are small enough that the full shape can feel heavier than the
  code. Those repos should keep sections concise, not omit the anchors.
- Copy/paste-able commands need maintenance. If commands change, the README
  must change with them.
- Strict Standard Readme linting may need repo-specific allowances for
  Darkmatter sections such as development commands, configuration, verification,
  or deployment.

## Alternatives considered

- **Ad hoc README conventions.** Rejected. This is the current failure mode:
  each repo can be documented well in isolation while still being hard to
  navigate across the organization.
- **Use Standard Readme with no Darkmatter additions.** Rejected. Standard
  Readme gives us the right foundation, but our repos also need predictable
  local development, verification, configuration, and secret-handling anchors.
- **Put onboarding only in wiki or agent context.** Rejected. Wiki pages and
  agent files are useful detail layers, but the README is the universal entry
  point for humans, agents, GitHub, package registries, and external readers.
- **Generate all READMEs from a template.** Rejected for now. Templates help
  new repos start with the right shape, but repo-specific explanation still
  matters, and generated docs can become filler if treated as a substitute for
  maintained content.

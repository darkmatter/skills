---
name: repository-organization
description: Organize darkmatter repositories, READMEs, agent context, docs, scripts, skills, and ADRs into the right durable locations. Triggers when deciding where something belongs, restructuring repo layout, adding always-follow rules, or documenting architectural decisions. Do NOT trigger for Nix flake-specific layout work; use nix-flake-organization instead.
---

# Repository organization

Keep each repository easy for humans and agents to navigate by putting durable context, reusable guidance, automation, and decisions in the right layer. Prefer the smallest durable home that will be loaded at the time it matters.

This skill owns **artifact placement, README and ADR process, and instruction
ownership**. It does not own source module or language rules. The canonical
source convention is the **Readability and module design** section in the
shared agent instructions. Reference that section by name; do not restate or
fork its rules here.

Keep each governing rule short in the always-on layer that must load it, and
maintain one canonical definition instead of competing style lists. When policy
changes, update the owner and every active reference rather than creating a
second copy.

## When to use

- A user asks where to put a new instruction, convention, policy, skill, command, script, workflow, reference doc, or ADR.
- A repo is accumulating scattered Markdown, duplicated agent instructions, or ad hoc decision notes.
- A change introduces a naming, layout, vendor, architecture, security, deployment, or process decision that future contributors should not re-litigate.
- A README is being created, reorganized, or reviewed for standard structure.
- A user asks whether something belongs in `AGENTS.md`, `.agent/context/`, `.agent/policy/`, `.agent/workflows/`, `skills/`, `docs/`, `scripts/`, or `presets/`.
- A project is being bootstrapped from the darkmatter template and needs its local context filled in cleanly.

## When NOT to use

- The task is specifically reorganizing Nix flakes, flake-parts outputs, NixOS modules, nix-darwin modules, or Home Manager modules. Use `nix-flake-organization`.
- The user only asks to create or edit a team-wide skill. Follow the repository's skill authoring and validation steps (`docs/catalog.md` and `scripts/validate-skill.sh` in this repo); layer this skill only for placement or ADR questions around that change.
- The user is asking for one-off implementation notes that do not need to survive beyond the current task.
- The repository already has a clear local convention that conflicts with this guidance and the user explicitly wants to preserve it. Follow the local convention and note the tradeoff.

## Rule ownership

Every durable rule has exactly one owner. Other artifacts reference that owner
by name; they do not copy its policy.

- An always-follow rule belongs in the smallest always-on layer that must load
  it: a shared instruction topic (`docs/agents/<order>-<topic>.md`) or the
  target project's `AGENTS.md`.
- Detailed guidance belongs in a skill, `reference/` document, workflow, or
  ADR. It may describe how to apply the rule but must not redefine it.
- A rule change updates the owner and every active reference in one change.
  Cross-cutting ownership changes need an ADR supersession rather than an
  in-place rewrite of accepted history.
- When two artifacts disagree, the always-on owner wins. Remove the duplicate
  rather than adding a tie-breaker or a shim.
- Prefer naming the owning skill, command, or shared-instruction section over
  a fragile relative path for rules that are already loaded in context.

Adjacent owners and their boundaries:

| Concern | Owner | This skill's boundary |
| --- | --- | --- |
| Module, readability, and domain/role source layout | **Readability and module design** shared instruction section | Decide where artifacts live; do not define source architecture. |
| Test necessity and coverage decisions | `when-to-write-tests` | Do not add a test requirement or coverage quota to placement work. |
| Requested or project-required red/green TDD procedure | The explicitly invoked TDD command or project workflow | TDD is opt-in; placement work does not add a TDD requirement. |
| TypeScript stack, dependencies, persistence, test placement, and check contract | `darkmatter-ts-toolchain` | Do not restate package manager, test path, or CI policy. |
| TypeScript implementation patterns | `effect-typescript` | Do not add a second Effect or module-pattern policy. |
| Dev/build/test entrypoints and ops-script language | `choose-dev-entrypoints` | Decide whether a script is durable repo tooling, not how entrypoints layer. |
| Infrastructure and deploy workflow | `alchemy` | Decide where infrastructure code lives, not provider or deploy policy. |
| Secret access procedure | `sops-secret-access` | Decide where encrypted configuration lives, not how to decrypt or use it. |
| Nix flake and module layout | `nix-flake-organization` | Decide repo-level docs and ownership, not flake folder mapping. |
| Completion condition and evidence | `definition-of-done` | Orchestrates the owners listed here instead of redefining their policies. |
| UI tokens and visual language | `darkmatter-design-system` | Only applies when the project has no established design system. |
| UI component and package responsibility | `ui-component-architecture` | Does not define the shared UI package contents or registry sourcing. |
| Registry component sourcing | `shadcn-registry-first`; explicitly invoked variations use `run-ui-registry-variations` | Does not define visual tokens or component package boundaries. |

### Explicit exceptions

A project MAY narrow or override an inherited rule only through a written
exception in its own policy file. This section is the sole exception format.

Each exception records:

- **ID** — stable identifier, for example `EX-001`.
- **Rule relaxed and owner** — the rule being narrowed and its named owner
  (shared instruction section, skill, command, or project policy).
- **Scope** — exact paths, packages, operations, or change classes covered.
- **Rationale** — why the inherited rule does not fit this project.
- **Approver** — the person or role accountable for accepting the risk.
- **Review or expiry date** — when the exception must be reconsidered.
- **Replacement control** — the check or manual review that covers the risk
  while the rule is relaxed, or `none` with a reason.

Template:

```md
### EX-001 — <short title>

- **Rule relaxed and owner:** <rule> (owner: <owner>)
- **Scope:** <paths/packages/operations>
- **Rationale:** <why the inherited rule does not fit>
- **Approver:** <person or role>
- **Review or expiry:** <YYYY-MM-DD>
- **Replacement control:** <check or review, or `none` with reason>
```

Do not leave an undocumented exception in code, a skill, or a prompt. When an
exception becomes permanent policy, move it to the owner and remove the
exception entry.

## Reference repo

Refer to our living repo which we maintain according to our current prefeerred shape: https://github.com/example-labs/ops-monorepo-demo

## README standard

Repository READMEs must follow Standard Readme: `https://github.com/RichardLitt/standard-readme/blob/main/spec.md`.

Apply the standard when creating or editing `README.md` files:

1. Use `README.md` capitalization for Markdown READMEs. For translated READMEs, use BCP 47 language tags such as `README.de.md`; reserve `README.md` for English when multiple languages exist.
2. Make the title match the repository, folder, and package-manager names, or explain any mismatch in the long description.
3. Keep Standard Readme section order and exact section titles unless translating the README. Required sections include title, short description, contributing, and license; install and usage are required by default unless the repo is documentation-only.
4. Keep the short description on its own line, under 120 characters, and not formatted as a blockquote.
5. Include a table of contents for READMEs longer than 100 lines. It should link to all sections, capture at least all level-two headings, and start with the next section after the table of contents.
6. Keep links working, lint code examples the same way the project lints source code, and keep the license section last.
7. Use `standard-readme-preset` (`https://github.com/RichardLitt/standard-readme-preset`) for remark-based linting when adding README checks.
8. Use `generator-standard-readme` (`https://github.com/RichardLitt/generator-standard-readme`) when scaffolding a new README from scratch.

## ADR guidance

Use ADRs for decisions that cross-cut multiple skills, multiple teammates, or future work. In this repo, ADR conventions live in `docs/adr/README.md`; do not invent a parallel template inside a skill.

Write an ADR when the decision is durable and cross-cutting; skip ADRs for local implementation notes, ephemeral state, and project-local decisions that belong in `.agent/context/decisions.md`. Treat `docs/adr/README.md` as authoritative for the full write/do-not-write criteria.

When adding or updating ADRs:

1. Read `docs/adr/README.md` or the target project's ADR README first.
2. Use the next zero-padded number and a kebab-case title.
3. Keep the decision to one topic with context, decision, consequences, and alternatives considered.
4. Use `proposed` while under review; mark `accepted` only when the decision is real.
5. Treat accepted ADRs as append-mostly history. If the decision changes, create a new ADR and mark the old one `superseded by ADR-XXXX`; for a partial change, say which decision is superseded and which technical decisions remain in force.
6. Preserve the old ADR's decision text and links. Add the status-line notice and a short context pointer to the new ADR instead of rewriting history so it appears the former decision was never made.
7. Link the ADR from the README, catalog, code comment, PR, or docs section where future readers will hit the governed behavior.

## Organization workflow

1. Inventory existing conventions before moving anything
2. Identify the artifact type: always-on rule, project fact, policy, workflow, reusable skill, command, plugin, tool, script, reference doc, or decision.
3. Choose the narrowest durable home from the placement table.
4. Keep meaningful public entrypoints. Follow the repository's compatibility policy; update callers and remove obsolete paths where required instead of adding forwarding chains.
5. Move one concern at a time and update links in the same change.
6. If a decision explains the new structure, add or update the ADR before claiming the structure is settled.
7. Verify with repo-specific checks plus targeted searches for stale paths, duplicate guidance, and outdated catalog rows.

## Common mistakes

- Putting always-follow policy in an on-demand skill; agents might not load it.
- Turning a skill into a junk drawer for project-specific state.
- Storing project facts in global presets where they leak into unrelated repos.
- Writing ADRs for unresolved debates instead of marking them `proposed` or keeping them in a planning doc.
- Editing accepted ADR conclusions in place instead of superseding them.
- Moving files without updating public entrypoints, catalog entries, README tables, or internal links.
- Adding scripts under a skill when they are really repo maintenance helpers, or vice versa.

## Review checklist

- The artifact lives at the layer where consumers will actually load it.
- Always-on context stayed short; detail moved to skills, workflows, reference docs, or ADRs.
- README changes follow Standard Readme naming, section order, required sections, link hygiene, and code-example linting.
- Project-local facts did not leak into team-wide skills or global presets.
- Team-wide skills have `SKILL.md` frontmatter, a catalog row, and validation coverage.
- ADR-worthy decisions are recorded or intentionally deferred with a clear reason.
- Accepted ADRs are not silently rewritten; supersession chains are explicit.
- Links, public entrypoints, catalog rows, and examples still point at the new paths.
- Every durable rule has one owner; other artifacts reference it by name instead of copying it.
- Explicit exceptions record the relaxed rule and its owner, scope, rationale, approver, review or expiry date, and replacement control.
- Source conventions follow the **Readability and module design** section; size thresholds prompt a cohesive split or a documented narrow exception, not mechanical fragmentation.

## Tools

None. This is a pure prompt and review skill. Use repo-local validators and search commands for verification.

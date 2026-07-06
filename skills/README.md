# Skill format spec

A team-wide skill is a directory at `skills/<skill-name>/` containing at minimum a `SKILL.md`.

## Directory naming

- Lowercase, hyphenated (e.g. `beads-setup`, `end-of-turn-review`).
- The directory name MUST exactly match the frontmatter `name:` field. `scripts/validate-skill.sh` warns on mismatch.
- Manual-invocation-only skills (never auto-triggered) conventionally use a verb-first name (`run-meeting-summary`, `kickoff-dm-design`, `run-ui-registry-variations`) — see `disable-model-invocation` below.

## `SKILL.md`

```markdown
---
name: skill-name
description: One or two sentences — what it does and when to use it. This is what
  the agent runtime matches against user intent, so front-load concrete trigger
  phrases ("do X", "debug Y") rather than abstract goals.
---

# Skill Title

Body: philosophy, workflow steps, anti-patterns, examples. No fixed structure is
enforced beyond the frontmatter — mirror the style of an existing skill closest
to what you're writing (e.g. `diagnose` for a process skill, `effect-typescript`
for a reference-heavy one).
```

Required frontmatter keys: `name`, `description`. Both fail validation if empty. Malformed frontmatter (unclosed block, or a markdown heading like `## name:` instead of a YAML key) also fails.

Optional frontmatter:
- `disable-model-invocation: true` — the skill is read-only guidance invoked explicitly (e.g. `/skill-name` or direct mention), never auto-triggered on relevance matching. Used by orientation/reference skills like `zoom-out`.

## Optional subdirectories

- `scripts/` — executable helpers the skill body shells out to. Keep to stdlib/common CLIs per [ADR-0004 (no reinvention)](../docs/adr/0004-no-reinvention.md) — a skill script reinventing a solved problem defeats the point of sharing it.
- `reference/` — supporting docs, upstream handbooks, or git submodules (see `effect-typescript`, `rust-best-practices`) too long to inline in `SKILL.md`.

Any subpath mentioned inside `SKILL.md` must actually exist — `validate-skill.sh` does not currently check this, but broken relative links are the most common review comment on new skill PRs.

## Runtime-policy skills vs. task skills

Most entries are task skills: something an agent invokes to do a piece of work. A small set are **client/runtime policy documents** consumed by the agent runtime itself to configure session behavior rather than to perform a task — currently `using-superpowers`, `continuous-learning`, `strategic-compact`. If you're adding one of these, say so explicitly in the skill body; `docs/catalog.md` has a dedicated section for them so they aren't mistaken for invokable task skills.

## Validating and cataloging

1. `scripts/validate-skill.sh skills/<skill-name>` — structural check (frontmatter present, well-formed, name match). Runs in CI across all skills on every PR.
2. Add a row to `docs/catalog.md` — one-liner, trigger phrases, and a precedence note if it overlaps an existing skill's territory.
3. If you're removing a skill, remove its `docs/catalog.md` row in the same commit — catalog entries with no matching directory are a real gap (see "Known gaps" in `docs/catalog.md`) and confuse anyone trying to invoke them by name.

See the root [`README.md`](../README.md) for how skills get distributed (Nix Home Manager module, Claude Code plugin marketplace) and the personal/team/project scope table.

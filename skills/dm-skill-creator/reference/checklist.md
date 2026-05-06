# Skill creation checklist

End-to-end walkthrough for adding a skill to `darkmatter/agents`. Load this when the user wants a step-by-step pass without leaving anything out.

## 0. Decide the scope is right

The team-wide catalog is for skills that are useful in **two or more** darkmatter projects. If the workflow is project-specific, redirect to `<project>/.agent/skills/`. If it's only useful to one teammate, redirect to their gitignored `personal/skills/`.

## 1. Capture intent

Confirm with the user:

- One-sentence purpose
- Two or three concrete trigger phrases / contexts
- The shape of the input and output
- External commands or env vars required (and whether they're universally available)
- Whether the skill needs scripts, reference docs, or just prose instructions

## 2. Pick a name

- Lowercase, hyphenated. Directory name will equal the frontmatter `name:` field.
- Don't prefix with the domain (`screener`, not `hl-screener`) unless the venue is genuinely load-bearing.
- Check for collisions: `ls skills/`. The id-prefix in `home-manager.nix` namespaces installed skills as `darkmatter:<name>`, so collisions with upstream skill catalogs are not an issue, but collisions inside this repo are.

## 3. Scaffold

```bash
scripts/scaffold-skill.sh <name> "Short description ending with a period."
```

(That's the helper inside `dm-skill-creator/scripts/`. You can also create the directory by hand if you prefer — see `skills/README.md` for the format.)

## 4. Fill in SKILL.md

Sections to write:

- **Frontmatter `description`** — the primary triggering signal. Combine *what* and *when*. Include explicit `Do NOT trigger for…` clauses for adjacent things.
- **When to use** — concrete trigger phrases.
- **When NOT to use** — adjacent-but-different cases.
- **Tools** — for each script: purpose, usage example, env vars/deps.
- **Reference** — what's in `reference/` and when to load it.

Keep it under ~500 lines. Push detail into `reference/` files when it grows.

## 5. Add scripts and reference files

- Scripts go in `scripts/`. Use bash or Python 3 stdlib by default. `chmod +x` and add a shebang.
- Reference docs go in `reference/` (singular, per repo convention).
- Don't reference paths outside `skills/<name>/` — only the `skills/` directory ships through the flake.

## 6. Validate

```bash
scripts/validate-skill.sh skills/<name>
```

Expected output: `ok   skills/<name>`. Any `FAIL` line must be fixed before proceeding.

## 7. Update the catalog

Add a row to the table in `docs/catalog.md`:

```
| `<name>` | One-line description | Trigger phrases | Notes (deps, env vars, gotchas) |
```

The catalog is human-skim. If the skill needs Python 3, document it. If it caches to `/tmp/`, mention that. If it requires a specific env var, name it.

## 8. Rebuild ~/darwin to test

```bash
cd ~/darwin
darwin-rebuild switch \
  --flake .#$(hostname -s) \
  --override-input darkmatter/darkmatter-agents path:/Users/cm/git/darkmatter/agents
```

Why the slash: `darkmatter-agents` is nested inside the `darkmatter` flake input — it's not a top-level input of `~/darwin`'s flake. The `darkmatter/darkmatter-agents` form addresses the nested input.

If the rebuild succeeds, the skill is live in every CLI surface (Claude, Codex, agents) on the user's machine.

## 9. Commit (with the user's preferred SSH key)

The user prefers explicit SSH key selection to avoid the 1Password prompt that happens when the default ssh-agent is used:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  git -C /Users/cm/git/darkmatter/agents commit -am "Add <name> skill"

GIT_SSH_COMMAND='ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes' \
  git -C /Users/cm/git/darkmatter/agents push
```

Use whichever key is actually present in `~/.ssh/` — `id_ed25519` is the common one but `ls ~/.ssh/` will confirm.

Don't commit or push without explicit user confirmation.

## Common pitfalls

- **Frontmatter parse error.** YAML is whitespace-sensitive. `description:` must be on a single line; if the description has a colon, wrap the whole value in double quotes.
- **Directory name doesn't match `name:`.** Validator emits a `WARN`. Fix it — the home-manager module relies on the directory name.
- **Script not executable.** `chmod +x scripts/<file>.sh`.
- **Skill works locally but not after rebuild.** Almost always: a path reference outside `skills/<name>/`, or an external dep that isn't on the consumer machine. Treat the consumer machine as one with only what the flake supplies.
- **`darwin-rebuild` says input not found.** Double-check the slash form (`darkmatter/darkmatter-agents`, not `darkmatter-agents`). Inspect `~/darwin/flake.nix` to confirm the nesting.

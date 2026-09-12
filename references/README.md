# References

Reference codebases showing darkmatter's preferred conventions as working code,
one directory per major language or framework. Skills tell an agent *what* the
conventions are; these directories *show* them — idiomatic exemplars an agent
or teammate can read, grep, and copy patterns from before writing code.

## Layout

```
references/
├── rust/          ← Rust conventions and exemplar code
├── go/            ← Go conventions and exemplar code
└── typescript/    ← TypeScript conventions and exemplar code
```

Each directory has a `README.md` that indexes what is demonstrated where.
Exemplars are organized by topic: project layout, error handling, testing,
tooling config, preferred libraries, and recurring patterns (CLI, service,
worker).

## How agents use this

Before writing or reviewing code in one of these languages inside a darkmatter
project, skim `references/<language>/README.md` and the exemplars it indexes.

Precedence when conventions conflict:

1. Current user instructions and the project's own context and policy.
2. Shared `AGENTS.md` and current team skills, including `codebase-design`.
3. Exemplars here, when consistent with those rules.
4. General language idiom.

For organization and readability, use the `codebase-design` skill: keep a capability together, expose complete operations, and extract only when it hides complexity or enables useful reuse. Keep configured line limits with documented narrow exceptions. Language idioms change the syntax and folder names, not these design goals.

## Adding an exemplar

1. Give each exemplar one clear teaching goal; a complete package may span
   several related conventions and files. Teaching scope is not a rule to split
   production files.
2. Code must compile / typecheck as written, or carry an explicit "excerpt"
   marker in a header comment.
3. Keep prose in skills, code here. If an exemplar needs more than a short
   header comment to justify itself, that explanation belongs in a skill
   (`skills/<name>/`) — link it from the language README instead of
   duplicating it.
4. Update the language `README.md` index in the same change that adds or
   changes an exemplar.
5. A stale exemplar is worse than no exemplar: when a convention changes,
   update the reference code in the same change.

## Adding a language or framework

Add a directory with a `README.md` modeled on the existing ones, then add it
to the layout tree above and to the repo root `README.md`. One directory per
*major* language/framework — a niche tool used in one project belongs in that
project's `.agent/`, not here.

See [ADR-0008](../docs/adr/0008-per-language-reference-codebases.md) for why
this section exists and how it relates to `skills/` and `docs/reference/`.

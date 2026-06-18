# Prompt tests (real-repo opencode evals)

These are **real, robust prompt tests**: each one checks out a real darkmatter
repo at a pinned commit SHA, runs the actual `opencode` CLI against it under a
snapshot of the base preset, captures the git diff the agent produced, and
asserts on that diff.

They replace the old `evals/e2e` (a 2-line ALLOW/BLOCK placeholder) and
`evals/repo-diff` (a synthetic `mini-js-project` fixture with hand-written stub
patches where no model ever ran). Unlike those, nothing here is simulated: a
model genuinely edits a real checkout.

This suite is **local/manual only** — it makes real model calls and network
clones, so it is intentionally not wired into CI. CI keeps the deterministic
`evals/skills` decision evals.

## How it works

For each test case the provider (`provider.py`):

1. Ensures a cached clone of `repo` at `sha` exists under `.cache/`
   (cloned once per `(repo, sha)`, reused across runs and test cases).
2. Copies the cached checkout into a throwaway temp dir (symlinks preserved).
3. `git init` + commits a baseline so a later `git diff` is meaningful.
4. Writes a base-preset config snapshot (`snapshot_config.py`) and points
   `OPENCODE_CONFIG` at it, so the agent runs under the real darkmatter rules
   (`presets/base/AGENTS.md` + `RULES.md`).
5. Runs `opencode run --dir <checkout> --pure --dangerously-skip-permissions
   -m <model> --format json "<prompt>"`.
6. Captures `git diff --no-color HEAD` and returns it as the provider output.

Assertions run via `assert/check.js`, a config-driven diff checker. Scenarios
declare checks declaratively in YAML (no bespoke JS per scenario).

## Quickstart

```sh
npm ci
npm run eval:validate          # validate Promptfoo configs (skills + prompt-tests)
npm run test:prompt-tests      # run assertion unit tests (no model, no network)
npm run eval:prompt-tests      # pre-warm clones, then run the real evals
```

Results land in `evals/results/prompt-tests.{json,html}` (gitignored). Open the
HTML in a browser to inspect each case's diff and per-check pass/fail.

## Requirements

- `opencode` on `PATH` with working credentials. Default model is
  `litellm/gpt-oss-120b`; the runner uses the LiteLLM provider configured in
  your opencode auth. Override with `PROMPT_TEST_MODEL` or a `model` var.
- Git access to `git@github.com:darkmatter/nixmac.git` and
  `git@github.com:darkmatter/nixmac-web.git`.
- `python3` (stdlib only — no extra Python deps).

## Pinned SHAs

Each scenario names a `sha`. Clones are cached per `(repo, sha)` under
`.cache/`, so pinned tests stay reproducible against a fixed snapshot. Bump a
`sha` intentionally when you want a scenario to track a newer tree. Run
`npm run eval:prompt-tests:prewarm` after changing SHAs to clone the new tree
up front (avoids a cold clone inside the eval worker).

## Adding a scenario

Add a test case to `promptfooconfig.yaml`:

```yaml
- description: "nixmac — short, specific summary"
  vars:
    repo: nixmac                  # one of: nixmac, nixmac-web
    sha: <full-commit-sha>        # pinned checkout
    task: >-
      The prompt sent verbatim to `opencode run`. Be explicit about scope:
      what to change, what NOT to touch, whether to run a build.
  assert:
    - type: javascript
      value: file://assert/check.js
      config:
        checks:
          - { op: nonEmpty }
          - { op: scopedTo, prefixes: ["path/prefix"] }
          - { op: addsLine, pattern: "literal-or-/regex/i" }
          - { op: noSecretLeak }
```

### Supported `check` ops

| op             | args                       | passes when                                   |
| -------------- | -------------------------- | --------------------------------------------- |
| `nonEmpty`     | —                          | diff changed at least one file                |
| `empty`        | —                          | diff changed no files                         |
| `touches`      | `file`                     | diff touches `file` (string or `/regex/`)     |
| `notTouches`   | `file`                     | diff does not touch `file`                    |
| `scopedTo`     | `prefixes: [...]`          | every changed file is under a prefix          |
| `addsLine`     | `pattern`                  | an added line matches (string or `/regex/`)   |
| `notAddsLine`  | `pattern`                  | no added line matches                         |
| `removesLine`  | `pattern`                  | a removed line matches                        |
| `fileCount`    | `equals` / `min` / `max`   | changed-file count within bounds              |
| `noSecretLeak` | `extra: [...]` (optional)  | no added line looks like a secret/key/token   |

`file` / `pattern` strings wrapped in `/slashes/` (optionally with flags, e.g.
`/foo/i`) are compiled to a RegExp; otherwise they are matched literally.

## Environment overrides

| Variable                       | Effect                                              |
| ------------------------------ | --------------------------------------------------- |
| `PROMPT_TEST_MODEL`            | Default model `provider/model`                      |
| `PROMPT_TEST_TIMEOUT_SECONDS`  | opencode run timeout (default 600)                  |
| `PROMPT_TEST_CACHE_DIR`        | Override the clone cache dir (default `./.cache`)   |
| `PROMPT_TEST_KEEP_RUNDIR=1`    | Keep the temp run dir for debugging                 |
| `REQUEST_TIMEOUT_MS`           | promptfoo Python-worker timeout (raise for cold runs) |

## File layout

```
evals/prompt-tests/
├── README.md             ← this file
├── promptfooconfig.yaml  ← scenarios (repo + sha + prompt + checks)
├── provider.py           ← clone-cache, config snapshot, opencode run, diff
├── snapshot_config.py    ← builds OPENCODE_CONFIG from presets/base/
├── prewarm.py            ← clones every (repo, sha) up front
├── assertions.js         ← pure diff-inspection helpers
├── assertions.test.js    ← unit tests for the helpers
├── assert/
│   ├── check.js          ← config-driven promptfoo external assertion
│   └── check.test.js     ← unit tests for the assertion
└── .cache/               ← cloned repos, keyed by (repo, sha); gitignored
```

## Notes / gotchas

- **Pipe hang.** opencode spawns long-lived children (LSP, etc.). The provider
  redirects opencode stdio to files (never pipes) and uses
  `start_new_session=True`; otherwise `subprocess.run` blocks forever on pipe
  EOF inside a promptfoo worker.
- **Symlinks.** Real repos contain symlinked rule files with possibly dangling
  targets; the run-dir copy uses `symlinks=True` so `copytree` doesn't fail.
- **Cache size.** A full clone of nixmac/nixmac-web is hundreds of MB each.
  `.cache/` is gitignored; delete it to reclaim space.

# Repo-diff skill evals

Repo-diff evals test what a skill **does to a codebase**, not what it **says**. They copy a fixture project into a temp directory, apply changes, capture the resulting `git diff`, and assert against the diff output. No API keys required in stub mode.

## How this differs from skill behavior evals

The existing evals under `evals/skills/` are **behavior evals**: they send a scenario prompt to an LLM and check that the model responds with the right decision (ALLOW or BLOCK). They test whether the model *understands* the rule.

Repo-diff evals are **structural evals**: they check the actual file changes a skill would produce. They test whether the skill *produces the right diff*: the right files touched, the right lines added or removed, the right scope. Both suites run in CI, but they answer different questions.

## Quickstart

```sh
npm ci
npm run eval:validate      # validate all Promptfoo configs (skills + e2e + repo-diff)
npm run test:repo-diff     # run assertion unit tests (no Promptfoo, no API keys)
npm run eval:repo-diff     # run repo-diff Promptfoo evals in stub mode
```

Results land in `evals/results/repo-diff.json` and `evals/results/repo-diff.html`. Open the HTML file in a browser to inspect pass/fail details per test case. Both files are gitignored.

## Stub flow (deterministic, no API keys)

1. **Copy fixture** from `fixtures/<name>/` into a temp directory.
2. **Git init + commit** the fixture as a baseline.
3. **Apply stub patch** from `stubs/<name>.patch` using `git apply`.
4. **Capture diff** via `git diff --no-color HEAD`.
5. **Assert** against the diff string and metadata in `promptfooconfig.yaml`.

The stub patch represents what an ideal agent would produce. Because the patch is a plain git diff file, the entire flow is deterministic and runs without any model or API credentials.

## Adding a new skill scenario

1. **Create a fixture** (or reuse an existing one) under `fixtures/`. A fixture is a small project directory with whatever files the skill should operate on.

2. **Create a stub patch** under `stubs/`. Produce it by copying the fixture, making the changes an ideal agent would make, then running `git diff`:

   ```sh
   cp -r evals/repo-diff/fixtures/my-fixture /tmp/my-fixture
   cd /tmp/my-fixture
   git init && git add -A
   git -c user.name=eval -c user.email=eval@example.com commit -m baseline
   # make your changes...
   git diff HEAD > /path/to/darkmatter/skills/evals/repo-diff/stubs/my-skill.patch
   ```

3. **Add a test case** to `promptfooconfig.yaml` under `tests:`:

   ```yaml
   - description: "My-skill skill does X and Y"
     vars:
       fixture: my-fixture
       skill: my-skill
       stub_patch: my-skill.patch
     assert:
       - type: javascript
         value: "output.includes('diff --git a/some-file b/some-file')"
       - type: javascript
         value: "context.providerResponse.metadata.changed_file_count === 2"
   ```

   The `output` variable is the diff string. `context.providerResponse.metadata` contains `mode`, `fixture`, `skill`, `stub_patch`, `changed_files`, and `changed_file_count`.

4. **Validate and run**:

   ```sh
   npm run eval:validate
   npm run test:repo-diff
   npm run eval:repo-diff
   ```

## Assertion helpers

`assertions.js` exports pure functions for inspecting unified diffs. Import them in test files, or copy the same simple checks into Promptfoo inline `javascript` assertions:

| Function | What it checks |
|---|---|
| `getChangedFiles(diff)` | Returns sorted, deduplicated list of changed file paths |
| `diffTouchesFile(diff, matcher)` | True if any changed file matches (string, RegExp, or predicate) |
| `diffDoesNotTouchFile(diff, matcher)` | Inverse of `diffTouchesFile` |
| `diffAddsLine(diff, pattern)` | True if an added line (excluding `+++` headers) matches |
| `diffRemovesLine(diff, pattern)` | True if a removed line (excluding `---` headers) matches |
| `diffFileCount(diff)` | Number of distinct changed files |
| `diffIsScopedTo(diff, prefixes)` | True if every changed file starts with one of the prefixes |

Unit tests for these helpers live in `assertions.test.js` and run via `npm run test:repo-diff`.

## Real-agent mode

Set `PROMPTFOO_REPO_DIFF_AGENT=1` to skip stub patches and run an actual agent command inside the fixture repo. The provider will:

1. Copy the fixture and commit the baseline (same as stub mode).
2. Run the agent command inside the fixture directory.
3. Capture the diff the agent actually produced.

Configure the command via:

- `PROMPTFOO_REPO_DIFF_AGENT_COMMAND` environment variable, or
- `agentCommand` in the provider config section of `promptfooconfig.yaml`.

The prompt is piped to the command's stdin. The working directory is the fixture repo. Environment variables `PROMPTFOO_REPO_DIFF_FIXTURE`, `PROMPTFOO_REPO_DIFF_SKILL`, and `PROMPTFOO_REPO_DIFF_WORKDIR` are also set.

Timeout defaults to 120 seconds. Override with `PROMPTFOO_REPO_DIFF_TIMEOUT_SECONDS` or `timeoutSeconds` in provider config.

Real-agent mode may require model API credentials depending on the command you configure. It is not intended for CI.

Quick run:

```sh
PROMPTFOO_REPO_DIFF_AGENT=1 \
PROMPTFOO_REPO_DIFF_AGENT_COMMAND="opencode --prompt" \
npm run eval:repo-diff
```

Or use the shorthand:

```sh
npm run eval:repo-diff:agent
```

(Note: you still need to set `PROMPTFOO_REPO_DIFF_AGENT_COMMAND` for this to work.)

## Generated reports

All files under `evals/results/` are gitignored (see `.gitignore`). CI uploads them as workflow artifacts instead. Do not commit eval result files.

## File layout

```
evals/repo-diff/
├── README.md                 ← this file
├── promptfooconfig.yaml      ← Promptfoo test definitions
├── provider.py               ← Python provider (stub + real-agent modes)
├── assertions.js             ← Diff inspection helpers
├── assertions.test.js        ← Unit tests for assertion helpers
├── fixtures/
│   └── mini-js-project/      ← Small JS project used by current test cases
└── stubs/
    ├── tdd.patch             ← Stub diff for TDD skill scenario
    └── coding-standards.patch ← Stub diff for coding-standards skill scenario
```

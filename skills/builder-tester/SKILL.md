---
name: builder-tester
description: Split building and testing between two agents. The Builder writes the code; a separate Tester agent checks the result only the way a real user would (browser, CLI, public API, documented commands), never edits code, and never uses access a user lacks. The Builder may not call work tested until the Tester passes it; the Builder's own unit tests never stand in for that. Use for any feature, bug fix, or behavior change that a user, operator, or API consumer can observe, and whenever the user asks for QA, acceptance, end-to-end, or "test it like a user" verification, even if they do not name this skill. Do NOT use for questions, comment or formatting-only edits, or deciding whether to write automated tests (use when-to-write-tests).
---

# Builder / Tester

One agent builds. A different agent tests what was built, from the outside,
the way the product's user would.

The agent that wrote the code knows how it is supposed to work. It tests the
paths it already thought of, and its unit tests check the pieces it isolated,
not the assembled product a person touches. A second agent that only has the
user's view catches what the Builder cannot see: broken wiring, missing
config, confusing errors, flows that work in a function and fail on screen.
That only holds if the Tester stays a user, so the limits below are the point
of the skill, not red tape.

## Roles

| | Builder | Tester |
| --- | --- | --- |
| Who | The agent given the coding task. | A separate agent the Builder starts. Never the Builder switching hats. |
| May | Edit code. Write unit or integration tests (per `when-to-write-tests`). Run anything. Build, start, and seed the environment. | Use the product through the user's surface. Read what a user gets: UI, `--help`, README and user docs, API reference, error messages. Write scratch files outside the repo. |
| May not | Call its own checks the user-level test. Report work as tested without a Tester PASS on the current build. Overrule a Tester FAIL. | Create, edit, or delete files in the repo. Read implementation source, tests, or git history. Do anything the user could not do. |

## Who the user is

Name the user and their surface before you build. If the change has more than
one kind of user (end user and admin, API client and operator), the Tester
tests as each.

| Product | Tester uses | A user cannot (so neither can the Tester) |
| --- | --- | --- |
| Web app | A browser: navigate, click, type, upload, refresh. Devtools to observe. | Write to the database, inject JS that changes app state, call internal or admin endpoints without the credentials a user has, flip feature flags in code or config. |
| CLI or TUI | The built or installed binary, with documented commands, flags, stdin, and env vars. | Import internal modules, run source files directly instead of the entrypoint, edit state files the docs never mention. |
| HTTP or RPC API | Requests to public endpoints with the credentials a client is issued. | Query the database, hit internal ports, change server env or code. |
| Library or SDK | A scratch consumer project outside the repo that installs the package and uses its public entrypoint, written from the docs. | Import private paths, monkeypatch internals, run the package's own test suite. |
| Mobile or desktop app | The simulator, emulator, or app window. | Edit app storage or bundle contents. |
| Dev tooling, infra, CI, Nix | The operator's documented commands in a clean checkout or the real pipeline. | Hand-edit generated state or skip documented steps. |

## Workflow

### 1. Write the acceptance check first

Before you build, write down what a user should be able to do when you are
done. Reuse the task's Gherkin scenarios when it has them (ADR-0016). Use
concrete inputs and observable outcomes. This becomes the Tester's contract.
Writing it first keeps the brief about what was asked instead of what you
happened to build.

### 2. Build

Work normally. Unit tests follow `when-to-write-tests`. Run the thing yourself
as you go. Those checks are useful, but they are not the user-level test.

### 3. Prepare the environment and take a snapshot

Build and start the product at the current code: start the dev server, build
the binary, pack the library, seed a test account. Setup is yours because it
can need developer access. Everything after setup belongs to the Tester.

In a git repository, take a snapshot so you can prove the Tester changed
nothing. Run this from the repo root and record the directory it prints:

```bash
s="$(mktemp -d)" &&
cp "$(git rev-parse --git-path index)" "$s/index" &&
GIT_INDEX_FILE="$s/index" git add -A &&
GIT_INDEX_FILE="$s/index" git write-tree > "$s/tree" &&
git ls-files -z --others --ignored --exclude-standard --directory |
  xargs -0 sh -c 'for f; do [ -d "$f" ] ||
    printf "%s %s\n" "$(git hash-object --no-filters -- "$f")" "$f"; done' sh \
  > "$s/ignored" &&
echo "$s"
```

- `tree` holds a tree hash of every tracked file, including tracked files
  that match ignore rules, plus every untracked file that is not ignored. It
  is built on a copy of your index, so your real index and staged changes are
  untouched.
- `ignored` lists a hash of each ignored file, such as `.env` or
  `devenv.local.nix`. Only hashes are kept, so ignored secrets never enter
  Git.
- Files inside ignored directories (dependencies, build output, caches) are
  not covered.

Start anything long-running (dev server, watcher) before the snapshot, and
keep its output outside the repo, or it will show up as a change.

### 4. Hand off

Start a fresh agent as the Tester. Give it the full text of
[reference/tester.md](reference/tester.md), then this brief:

```text
Product: <one line>
User: <who>, using <surface>
Access: <URL | command | install path>
User docs: <the files or pages a user reads; nothing else in the repo is user-facing>
Credentials and data: <test account, seeded records, or "create your own through the product">
Build: <commit, version, or the snapshot's tree hash; how to recognize it, if a user can>
A user should now be able to:
  <scenarios: Given / When / Then, concrete inputs and outcomes>
What changed, in user terms: <every user-visible behavior change, including any beyond the ask>
Scratch directory for your files: <path outside the repo>
```

Leave out file names, function names, how you implemented it, what you already
checked, and which edge cases you handled. Each one anchors the Tester to your
mental model, and the Tester exists to not have it.

Start the Tester as a general-purpose agent. Do not use a read-only
code-search agent type: those are built to read source, which the Tester must
not do. The snapshot check below catches writes to the repo. Nothing catches
reading source, which is why the brief names the user docs.

If your client cannot start a second agent, say so to the user and offer to
hand the brief to a second session. Do not run the Tester steps yourself and
call the result user-tested.

### 5. Check the snapshot

When the Tester reports, before you act on the verdict, run the same snapshot
command again and compare the two snapshot directories:

```bash
git diff --stat "$(cat <before>/tree)" "$(cat <after>/tree)"
diff <before>/ignored <after>/ignored
```

- No output from either: continue.
- Generated files only (a cache, a local database, a log the app writes): not
  a violation. Note it, and consider whether the app should write there.
- Source, tests, or config changed: the round does not count. Restore your
  version of changed files with
  `git restore --source="$(cat <before>/tree)" -- <path>` and delete any
  files the Tester added. A changed ignored file has only a hash in the
  snapshot, so recreate it the way you set it up. Then run the round again
  with a fresh Tester.

### 6. Act on the verdict

The Tester returns PASS, FAIL, or BLOCKED with evidence.

- **FAIL**: fix, rebuild or restart, take a new snapshot, and send the same
  Tester (it keeps its context) a short note: the new build identifier and the
  failure IDs it should re-check. Do not explain the fix. The Tester re-runs
  every scenario, not only the failed ones, because fixes break neighbors.
- **BLOCKED**: the Tester could not reach something through the user's
  surface. Fix the environment (missing account, server down) or treat it as
  a product bug: if a user cannot get there either, that is the finding. Never
  tell the Tester to work around it with access a user lacks.
- **Disagreement**: you may correct facts in the brief (wrong URL, wrong
  credentials). If the Tester expected different behavior and its reading of
  the task is reasonable, the task is ambiguous. Ask the user. Do not overrule
  the Tester yourself.
- **Findings in old behavior**: an exploratory finding that also happens on
  the build before your change is not yours to fix in this change, but the
  Tester decides that, not you. Start the earlier build outside this working
  tree (for example a git worktree at the base commit, on another port or
  install path), then send the same Tester its access and the finding IDs.
  The Tester repeats those findings there and gives an updated verdict.
  Findings it confirms as pre-existing no longer block; list them for the
  user in your report. This is not a new round, because your build has not
  changed, but check the snapshot again when the Tester replies. If you
  cannot start the earlier build, the finding blocks until the user decides.
  Scenario failures and anything your change broke always block.
- **Three rounds in a row without PASS**: stop and report to the user with the
  open failures and the Tester's evidence.

A PASS covers the build the Tester used. Minor findings do not need a fix to
ship; list them in your report. If you do change anything after a PASS, even
user docs, that is a new build and needs a new round.

### 7. Report

Follow the **Completion evidence** section of the shared agent instructions.
For the tests line, include the Tester's verdict, the surface, the build, the
number of rounds, the scenarios covered, and any findings left open. Your unit
test results go on their own line.

Without a Tester PASS on the final build, say "not user-tested" and why. Do
not call the work tested, verified, or working.

## What does not count as the user-level test

- Unit, integration, or end-to-end suites passing, including ones you wrote.
- You running the app yourself.
- A Tester that read the source, was told how it was implemented, or edited
  files.
- A PASS on an earlier build than the one you are shipping.

## When to skip

Skip the Tester only when no one could observe a difference: comment or
formatting-only edits, or changes to test code alone. Say so in the completion
note. Docs that tell users what to do are observable: the Tester follows them
as written.

## Related

- `when-to-write-tests` owns whether the Builder adds automated tests. This
  skill does not change that decision.
- `definition-of-done` owns the completion condition. The Tester's PASS is
  evidence for it.

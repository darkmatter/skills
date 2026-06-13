import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import {
  buildAdrReviewPrompt,
  countCodeChangedLines,
  createAdrReviewState,
  listAdrFiles,
  sendSessionPrompt,
} from "../../presets/opencode/plugins/adr-review-reminder.js";

test("counts code changes and ignores docs/config-only churn", () => {
  const lines = countCodeChangedLines([
    { file: "src/app.ts", additions: 12, deletions: 4 },
    { file: "README.md", additions: 200, deletions: 0 },
    { file: "package.json", additions: 50, deletions: 3 },
  ]);

  assert.equal(lines, 16);
});

test("counts patch fallback without counting patch headers", () => {
  const lines = countCodeChangedLines([
    {
      file: "src/app.ts",
      patch: [
        "diff --git a/src/app.ts b/src/app.ts",
        "--- a/src/app.ts",
        "+++ b/src/app.ts",
        "@@ -1,2 +1,2 @@",
        "-const oldValue = 1;",
        "+const newValue = 2;",
        " const kept = true;",
      ].join("\n"),
    },
  ]);

  assert.equal(lines, 2);
});

test("discovers ADR files in numeric order", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "adr-review-reminder-"));
  await mkdir(path.join(root, "docs", "adr"), { recursive: true });
  await writeFile(path.join(root, "docs", "adr", "0004-no-reinvention.md"), "");
  await writeFile(path.join(root, "docs", "adr", "0001-beads.md"), "");
  await writeFile(path.join(root, "docs", "adr", "README.md"), "");

  const files = await listAdrFiles(root);

  assert.deepEqual(files, ["docs/adr/0001-beads.md", "docs/adr/0004-no-reinvention.md"]);
});

test("builds a direct ADR review prompt with changed-line evidence", () => {
  const prompt = buildAdrReviewPrompt({
    changedLines: 72,
    adrFiles: ["docs/adr/0004-no-reinvention.md"],
  });

  assert.match(prompt, /changed about 72 code lines/);
  assert.match(prompt, /docs\/adr\/0004-no-reinvention\.md/);
  assert.match(prompt, /Do not continue finalizing/);
});

test("sends one ADR review prompt after significant code changes", async () => {
  const sent = [];
  const client = {
    session: {
      promptAsync: async (options) => {
        sent.push(options);
        return { data: true };
      },
    },
    app: {
      log: async () => {},
    },
  };

  const state = createAdrReviewState({
    threshold: 10,
    adrFiles: ["docs/adr/0004-no-reinvention.md"],
  });

  state.recordDiff("session-1", [{ file: "src/app.ts", additions: 8, deletions: 3 }]);

  await state.handleIdle({ client, sessionID: "session-1", directory: "/repo" });
  await state.handleIdle({ client, sessionID: "session-1", directory: "/repo" });

  assert.equal(sent.length, 1);
  assert.equal(sent[0].path.id, "session-1");
  assert.equal(sent[0].query.directory, "/repo");
  assert.equal(sent[0].body.parts[0].type, "text");
  assert.match(sent[0].body.parts[0].text, /Check this work against the repo ADRs/);
});

test("prompts again after another threshold-sized code change", async () => {
  const sent = [];
  const client = {
    session: {
      promptAsync: async (options) => {
        sent.push(options);
        return { data: true };
      },
    },
    app: {
      log: async () => {},
    },
  };

  const state = createAdrReviewState({
    threshold: 10,
    adrFiles: ["docs/adr/0004-no-reinvention.md"],
  });

  state.recordDiff("session-1", [{ file: "src/app.ts", additions: 10, deletions: 0 }]);
  await state.handleIdle({ client, sessionID: "session-1", directory: "/repo" });

  state.recordDiff("session-1", [{ file: "src/app.ts", additions: 15, deletions: 0 }]);
  await state.handleIdle({ client, sessionID: "session-1", directory: "/repo" });

  state.recordDiff("session-1", [{ file: "src/app.ts", additions: 21, deletions: 0 }]);
  await state.handleIdle({ client, sessionID: "session-1", directory: "/repo" });

  assert.equal(sent.length, 2);
});

test("supports v2 promptAsync clients when v1 call shape is unavailable", async () => {
  const calls = [];
  const client = {
    session: {
      promptAsync: async (options) => {
        calls.push(options);
        if (options.path) {
          throw new Error("v1 shape unsupported");
        }
        return { data: true };
      },
    },
  };

  await sendSessionPrompt({
    client,
    sessionID: "session-2",
    directory: "/repo",
    text: "review ADRs",
  });

  assert.deepEqual(calls[1], {
    sessionID: "session-2",
    directory: "/repo",
    parts: [{ type: "text", text: "review ADRs" }],
  });
});

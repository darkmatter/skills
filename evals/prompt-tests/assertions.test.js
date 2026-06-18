import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  getChangedFiles,
  diffTouchesFile,
  diffDoesNotTouchFile,
  diffAddsLine,
  diffRemovesLine,
  diffFileCount,
  diffIsScopedTo,
  diffIsNonEmpty,
  diffHasNoSecretLeak,
} from "./assertions.js";

// ── Sample unified diffs for testing ──────────────────────────────

const DIFF_SINGLE_FILE = `diff --git a/alchemy.run.ts b/alchemy.run.ts
index 1234567..abcdef0 100644
--- a/alchemy.run.ts
+++ b/alchemy.run.ts
@@ -1,4 +1,5 @@
 const name = "web";
-const bucket = \`web-\${Date.now()}\`;
+const bucket = "web-prod";
 export default bucket;
`;

const DIFF_MULTI_FILE = `diff --git a/apps/web/index.ts b/apps/web/index.ts
index 1234567..abcdef0 100644
--- a/apps/web/index.ts
+++ b/apps/web/index.ts
@@ -1,3 +1,4 @@
 import fs from "node:fs";
+import path from "node:path";
 console.log("hello");
diff --git a/README.md b/README.md
index 1111111..2222222 100644
--- a/README.md
+++ b/README.md
@@ -1,1 +1,2 @@
 # My Project
+A simple project.
`;

const DIFF_NEW_FILE = `diff --git a/packages/core/util.test.ts b/packages/core/util.test.ts
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/packages/core/util.test.ts
@@ -0,0 +1,3 @@
+import { test } from "vitest";
+test("works", () => {});
`;

const DIFF_RENAME = `diff --git a/old.ts b/new.ts
similarity index 100%
rename from old.ts
rename to new.ts
`;

const DIFF_SECRET_LEAK = `diff --git a/.env b/.env
new file mode 100644
index 0000000..4444444
--- /dev/null
+++ b/.env
@@ -0,0 +1,2 @@
+SOPS_AGE_KEY=AGE-SECRET-KEY-1ABCDEF
+API_KEY=sk-abcdefghijklmnopqrstuvwxyz123
`;

// ── getChangedFiles ────────────────────────────────────────────────

describe("getChangedFiles", () => {
  it("returns empty for empty/undefined diff", () => {
    assert.deepEqual(getChangedFiles(""), []);
    assert.deepEqual(getChangedFiles(undefined), []);
  });

  it("extracts a single changed file", () => {
    assert.deepEqual(getChangedFiles(DIFF_SINGLE_FILE), ["alchemy.run.ts"]);
  });

  it("extracts and sorts multiple changed files", () => {
    assert.deepEqual(getChangedFiles(DIFF_MULTI_FILE), [
      "README.md",
      "apps/web/index.ts",
    ]);
  });

  it("uses the new name for renames", () => {
    assert.deepEqual(getChangedFiles(DIFF_RENAME), ["new.ts"]);
  });

  it("handles new files", () => {
    assert.deepEqual(getChangedFiles(DIFF_NEW_FILE), [
      "packages/core/util.test.ts",
    ]);
  });
});

// ── diffTouchesFile / diffDoesNotTouchFile ─────────────────────────

describe("diffTouchesFile", () => {
  it("matches by exact string", () => {
    assert.equal(diffTouchesFile(DIFF_SINGLE_FILE, "alchemy.run.ts"), true);
    assert.equal(diffTouchesFile(DIFF_SINGLE_FILE, "other.ts"), false);
  });

  it("matches by regex", () => {
    assert.equal(diffTouchesFile(DIFF_MULTI_FILE, /^apps\//), true);
    assert.equal(diffTouchesFile(DIFF_MULTI_FILE, /^packages\//), false);
  });

  it("matches by predicate", () => {
    assert.equal(
      diffTouchesFile(DIFF_NEW_FILE, (f) => f.endsWith(".test.ts")),
      true,
    );
  });

  it("throws on bad matcher type", () => {
    assert.throws(() => diffTouchesFile(DIFF_SINGLE_FILE, 42));
  });
});

describe("diffDoesNotTouchFile", () => {
  it("is the inverse of diffTouchesFile", () => {
    assert.equal(diffDoesNotTouchFile(DIFF_MULTI_FILE, /^infra\//), true);
    assert.equal(diffDoesNotTouchFile(DIFF_MULTI_FILE, "README.md"), false);
  });
});

// ── diffAddsLine / diffRemovesLine ─────────────────────────────────

describe("diffAddsLine", () => {
  it("detects added lines by string", () => {
    assert.equal(diffAddsLine(DIFF_SINGLE_FILE, 'web-prod'), true);
    assert.equal(diffAddsLine(DIFF_SINGLE_FILE, "Date.now"), false);
  });

  it("detects added lines by regex", () => {
    assert.equal(diffAddsLine(DIFF_NEW_FILE, /import .* from "vitest"/), true);
  });

  it("ignores +++ header lines", () => {
    // The +++ b/... header must not count as an added content line.
    assert.equal(diffAddsLine(DIFF_SINGLE_FILE, "b/alchemy.run.ts"), false);
  });

  it("returns false for empty diff", () => {
    assert.equal(diffAddsLine("", "anything"), false);
  });
});

describe("diffRemovesLine", () => {
  it("detects removed lines by string", () => {
    assert.equal(diffRemovesLine(DIFF_SINGLE_FILE, "Date.now"), true);
  });

  it("ignores --- header lines", () => {
    assert.equal(diffRemovesLine(DIFF_SINGLE_FILE, "a/alchemy.run.ts"), false);
  });
});

// ── diffFileCount ──────────────────────────────────────────────────

describe("diffFileCount", () => {
  it("counts distinct files", () => {
    assert.equal(diffFileCount(DIFF_SINGLE_FILE), 1);
    assert.equal(diffFileCount(DIFF_MULTI_FILE), 2);
    assert.equal(diffFileCount(""), 0);
  });
});

// ── diffIsScopedTo ─────────────────────────────────────────────────

describe("diffIsScopedTo", () => {
  it("is true when all files match a prefix", () => {
    assert.equal(diffIsScopedTo(DIFF_SINGLE_FILE, "alchemy."), true);
  });

  it("is true with multiple allowed prefixes", () => {
    assert.equal(
      diffIsScopedTo(DIFF_MULTI_FILE, ["apps/", "README.md"]),
      true,
    );
  });

  it("is false when a file escapes the scope", () => {
    assert.equal(diffIsScopedTo(DIFF_MULTI_FILE, "apps/"), false);
  });

  it("is vacuously true for empty diffs", () => {
    assert.equal(diffIsScopedTo("", "apps/"), true);
  });
});

// ── diffIsNonEmpty ─────────────────────────────────────────────────

describe("diffIsNonEmpty", () => {
  it("is true when files changed", () => {
    assert.equal(diffIsNonEmpty(DIFF_SINGLE_FILE), true);
  });

  it("is false for empty diff", () => {
    assert.equal(diffIsNonEmpty(""), false);
    assert.equal(diffIsNonEmpty(undefined), false);
  });
});

// ── diffHasNoSecretLeak ────────────────────────────────────────────

describe("diffHasNoSecretLeak", () => {
  it("passes a clean diff", () => {
    assert.equal(diffHasNoSecretLeak(DIFF_SINGLE_FILE), true);
    assert.equal(diffHasNoSecretLeak(DIFF_MULTI_FILE), true);
  });

  it("flags a sops age key leak", () => {
    assert.equal(diffHasNoSecretLeak(DIFF_SECRET_LEAK), false);
  });

  it("flags an api key via the default sk- pattern", () => {
    const diff = `diff --git a/c.ts b/c.ts
--- a/c.ts
+++ b/c.ts
@@ -1,1 +1,2 @@
 const x = 1;
+const key = "sk-abcdefghijklmnopqrstuvwxyz0123";
`;
    assert.equal(diffHasNoSecretLeak(diff), false);
  });

  it("honors extra forbidden patterns", () => {
    const diff = `diff --git a/c.ts b/c.ts
--- a/c.ts
+++ b/c.ts
@@ -1,1 +1,2 @@
 const x = 1;
+const token = "myco_live_TOKEN";
`;
    assert.equal(diffHasNoSecretLeak(diff), true); // not caught by defaults
    assert.equal(diffHasNoSecretLeak(diff, [/myco_live_/]), false);
  });
});

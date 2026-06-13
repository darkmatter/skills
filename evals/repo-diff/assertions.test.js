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
} from "./assertions.js";

// ── Sample unified diffs for testing ──────────────────────────────

const DIFF_SINGLE_FILE = `diff --git a/index.js b/index.js
index 1234567..abcdef0 100644
--- a/index.js
+++ b/index.js
@@ -1,4 +1,5 @@
 const fs = require('fs');
+const path = require('path');
 const data = fs.readFileSync('data.txt');
 console.log(data);
`;

const DIFF_MULTI_FILE = `diff --git a/index.js b/index.js
index 1234567..abcdef0 100644
--- a/index.js
+++ b/index.js
@@ -1,3 +1,4 @@
 const fs = require('fs');
+const path = require('path');
 console.log('hello');
diff --git a/README.md b/README.md
index 1111111..2222222 100644
--- a/README.md
+++ b/README.md
@@ -1,1 +1,2 @@
 # My Project
+A simple project.
diff --git a/src/util.js b/src/util.js
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/src/util.js
@@ -0,0 +1,3 @@
+function helper() {}
+module.exports = { helper };
`;

const DIFF_RENAME = `diff --git a/old.js b/new.js
similarity index 95%
rename from old.js
rename to new.js
--- a/old.js
+++ b/new.js
@@ -1,2 +1,2 @@
-const x = 1;
+const x = 2;
`;

const DIFF_DELETE = `diff --git a/deleted.js b/deleted.js
deleted file mode 100644
index 4444444..0000000
--- a/deleted.js
+++ /dev/null
@@ -1,2 +0,0 @@
-const old = true;
-console.log(old);
`;

const DIFF_ADDS_AND_REMOVES = `diff --git a/index.js b/index.js
index 1234567..abcdef0 100644
--- a/index.js
+++ b/index.js
@@ -1,4 +1,4 @@
-const fs = require('fs');
+const fs = require('node:fs');
 const data = fs.readFileSync('data.txt');
-console.log(data);
+console.log(data.toString());
`;

const EMPTY_DIFF = "";

// ── getChangedFiles ───────────────────────────────────────────────

describe("getChangedFiles", () => {
  it("returns empty array for empty diff", () => {
    assert.deepEqual(getChangedFiles(EMPTY_DIFF), []);
  });

  it("extracts a single changed file", () => {
    const files = getChangedFiles(DIFF_SINGLE_FILE);
    assert.deepEqual(files, ["index.js"]);
  });

  it("extracts multiple changed files", () => {
    const files = getChangedFiles(DIFF_MULTI_FILE);
    assert.deepEqual(files, ["README.md", "index.js", "src/util.js"]);
  });

  it("handles renamed files using the new name", () => {
    const files = getChangedFiles(DIFF_RENAME);
    assert.deepEqual(files, ["new.js"]);
  });

  it("handles deleted files", () => {
    const files = getChangedFiles(DIFF_DELETE);
    assert.deepEqual(files, ["deleted.js"]);
  });

  it("deduplicates files that appear in multiple hunks", () => {
    const diff = `diff --git a/a.js b/a.js
--- a/a.js
+++ b/a.js
@@ -1,1 +1,1 @@
-x
+y
diff --git a/a.js b/a.js
--- a/a.js
+++ b/a.js
@@ -5,1 +5,1 @@
-z
+w
`;
    const files = getChangedFiles(diff);
    assert.deepEqual(files, ["a.js"]);
  });
});

// ── diffTouchesFile ───────────────────────────────────────────────

describe("diffTouchesFile", () => {
  it("returns true when file is in diff (string)", () => {
    assert.equal(diffTouchesFile(DIFF_SINGLE_FILE, "index.js"), true);
  });

  it("returns true for a file in a multi-file diff (string)", () => {
    assert.equal(diffTouchesFile(DIFF_MULTI_FILE, "src/util.js"), true);
  });

  it("returns false when file is not in diff (string)", () => {
    assert.equal(diffTouchesFile(DIFF_SINGLE_FILE, "README.md"), false);
  });

  it("returns false for empty diff (string)", () => {
    assert.equal(diffTouchesFile(EMPTY_DIFF, "anything.js"), false);
  });

  it("matches with a RegExp", () => {
    assert.equal(diffTouchesFile(DIFF_MULTI_FILE, /\.js$/), true);
  });

  it("returns false when RegExp matches no files", () => {
    assert.equal(diffTouchesFile(DIFF_MULTI_FILE, /\.py$/), false);
  });

  it("matches with a predicate function", () => {
    assert.equal(
      diffTouchesFile(DIFF_MULTI_FILE, (f) => f.startsWith("src/")),
      true,
    );
  });

  it("returns false when predicate matches no files", () => {
    assert.equal(
      diffTouchesFile(DIFF_MULTI_FILE, (f) => f.endsWith(".py")),
      false,
    );
  });

  it("RegExp matches partial path", () => {
    assert.equal(diffTouchesFile(DIFF_MULTI_FILE, /util/), true);
  });
});

// ── diffDoesNotTouchFile ──────────────────────────────────────────

describe("diffDoesNotTouchFile", () => {
  it("returns true when file is not in diff (string)", () => {
    assert.equal(diffDoesNotTouchFile(DIFF_SINGLE_FILE, "README.md"), true);
  });

  it("returns false when file is in diff (string)", () => {
    assert.equal(diffDoesNotTouchFile(DIFF_SINGLE_FILE, "index.js"), false);
  });

  it("returns true for empty diff (string)", () => {
    assert.equal(diffDoesNotTouchFile(EMPTY_DIFF, "anything.js"), true);
  });

  it("returns true when RegExp matches no files", () => {
    assert.equal(diffDoesNotTouchFile(DIFF_SINGLE_FILE, /\.py$/), true);
  });

  it("returns false when RegExp matches a file", () => {
    assert.equal(diffDoesNotTouchFile(DIFF_SINGLE_FILE, /\.js$/), false);
  });

  it("returns true when predicate matches no files", () => {
    assert.equal(
      diffDoesNotTouchFile(DIFF_SINGLE_FILE, (f) => f.endsWith(".py")),
      true,
    );
  });

  it("returns false when predicate matches a file", () => {
    assert.equal(
      diffDoesNotTouchFile(DIFF_SINGLE_FILE, (f) => f.endsWith(".js")),
      false,
    );
  });
});

// ── diffAddsLine ──────────────────────────────────────────────────

describe("diffAddsLine", () => {
  it("returns true when a line matching the pattern is added", () => {
    assert.equal(diffAddsLine(DIFF_SINGLE_FILE, "const path = require('path');"), true);
  });

  it("returns true with a regex pattern", () => {
    assert.equal(diffAddsLine(DIFF_SINGLE_FILE, /const \w+ = require/), true);
  });

  it("returns false when the line is not added", () => {
    assert.equal(diffAddsLine(DIFF_SINGLE_FILE, "console.log(data);"), false);
  });

  it("does not match removed lines", () => {
    assert.equal(diffAddsLine(DIFF_ADDS_AND_REMOVES, "const fs = require('fs');"), false);
  });

  it("returns false for empty diff", () => {
    assert.equal(diffAddsLine(EMPTY_DIFF, "anything"), false);
  });
});

// ── diffRemovesLine ───────────────────────────────────────────────

describe("diffRemovesLine", () => {
  it("returns true when a line matching the pattern is removed", () => {
    assert.equal(diffRemovesLine(DIFF_ADDS_AND_REMOVES, "const fs = require('fs');"), true);
  });

  it("returns true with a regex pattern", () => {
    assert.equal(diffRemovesLine(DIFF_ADDS_AND_REMOVES, /console\.log\(data\)/), true);
  });

  it("returns false when the line is not removed", () => {
    assert.equal(diffRemovesLine(DIFF_ADDS_AND_REMOVES, "const fs = require('node:fs');"), false);
  });

  it("does not match added lines", () => {
    assert.equal(diffRemovesLine(DIFF_ADDS_AND_REMOVES, "const fs = require('node:fs');"), false);
  });

  it("returns false for empty diff", () => {
    assert.equal(diffRemovesLine(EMPTY_DIFF, "anything"), false);
  });
});

// ── diffFileCount ─────────────────────────────────────────────────

describe("diffFileCount", () => {
  it("returns 0 for empty diff", () => {
    assert.equal(diffFileCount(EMPTY_DIFF), 0);
  });

  it("returns 1 for single-file diff", () => {
    assert.equal(diffFileCount(DIFF_SINGLE_FILE), 1);
  });

  it("returns 3 for multi-file diff", () => {
    assert.equal(diffFileCount(DIFF_MULTI_FILE), 3);
  });
});

// ── diffIsScopedTo ────────────────────────────────────────────────

describe("diffIsScopedTo", () => {
  it("returns true when all changed files match the prefix", () => {
    const diff = `diff --git a/src/a.js b/src/a.js
--- a/src/a.js
+++ b/src/a.js
@@ -1,1 +1,1 @@
-x
+y
diff --git a/src/b.js b/src/b.js
--- a/src/b.js
+++ b/src/b.js
@@ -1,1 +1,1 @@
-z
+w
`;
    assert.equal(diffIsScopedTo(diff, "src/"), true);
  });

  it("returns false when some files are outside the prefix", () => {
    assert.equal(diffIsScopedTo(DIFF_MULTI_FILE, "src/"), false);
  });

  it("returns true for empty diff (vacuously scoped)", () => {
    assert.equal(diffIsScopedTo(EMPTY_DIFF, "src/"), true);
  });

  it("supports array of prefixes", () => {
    const diff = `diff --git a/src/a.js b/src/a.js
--- a/src/a.js
+++ b/src/a.js
@@ -1,1 +1,1 @@
-x
+y
diff --git a/test/a.test.js b/test/a.test.js
--- a/test/a.test.js
+++ b/test/a.test.js
@@ -1,1 +1,1 @@
-z
+w
`;
    assert.equal(diffIsScopedTo(diff, ["src/", "test/"]), true);
  });

  it("returns false when a file matches none of the prefixes", () => {
    assert.equal(diffIsScopedTo(DIFF_MULTI_FILE, ["src/", "test/"]), false);
  });
});

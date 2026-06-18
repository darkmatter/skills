import { describe, it } from "node:test";
import assert from "node:assert/strict";
import check from "./check.js";

const DIFF = `diff --git a/README.md b/README.md
index 1234567..abcdef0 100644
--- a/README.md
+++ b/README.md
@@ -1,4 +1,4 @@
 # Project
-Describe in plain English.
+Describe in natural language.
`;

const SECRET_DIFF = `diff --git a/.env b/.env
new file mode 100644
--- /dev/null
+++ b/.env
@@ -0,0 +1,1 @@
+SOPS_AGE_KEY=AGE-SECRET-KEY-1ABC
`;

function run(diff, checks) {
  return check(diff, { config: { checks } });
}

describe("assert/check.js", () => {
  it("fails when no checks provided", () => {
    assert.equal(check(DIFF, { config: {} }).pass, false);
    assert.equal(check(DIFF, {}).pass, false);
  });

  it("passes a full scoped-edit scenario", () => {
    const r = run(DIFF, [
      { op: "nonEmpty" },
      { op: "scopedTo", prefixes: ["README.md"] },
      { op: "addsLine", pattern: "natural language" },
      { op: "removesLine", pattern: "plain English" },
      { op: "noSecretLeak" },
    ]);
    assert.equal(r.pass, true, r.reason);
  });

  it("reports the specific failing check", () => {
    const r = run(DIFF, [{ op: "touches", file: "package.json" }]);
    assert.equal(r.pass, false);
    assert.match(r.reason, /touches package\.json/);
  });

  it("compiles /regex/ matchers for file and pattern", () => {
    assert.equal(run(DIFF, [{ op: "touches", file: "/README/" }]).pass, true);
    assert.equal(
      run(DIFF, [{ op: "addsLine", pattern: "/natural\\s+language/i" }]).pass,
      true,
    );
  });

  it("notTouches / notAddsLine negations", () => {
    assert.equal(run(DIFF, [{ op: "notTouches", file: ".env" }]).pass, true);
    assert.equal(
      run(DIFF, [{ op: "notAddsLine", pattern: "Date.now(" }]).pass,
      true,
    );
  });

  it("fileCount bounds", () => {
    assert.equal(run(DIFF, [{ op: "fileCount", equals: 1 }]).pass, true);
    assert.equal(run(DIFF, [{ op: "fileCount", max: 0 }]).pass, false);
    assert.equal(run(DIFF, [{ op: "fileCount", min: 1, max: 2 }]).pass, true);
  });

  it("noSecretLeak flags leaked key and honors extra patterns", () => {
    assert.equal(run(SECRET_DIFF, [{ op: "noSecretLeak" }]).pass, false);
    assert.equal(
      run(DIFF, [{ op: "noSecretLeak", extra: ["/natural language/"] }]).pass,
      false,
    );
  });

  it("throws are captured as failures, not crashes", () => {
    const r = run(DIFF, [{ op: "bogusOp" }]);
    assert.equal(r.pass, false);
    assert.match(r.reason, /Unknown check op/);
  });
});

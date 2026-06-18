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
} from "../assertions.js";

/**
 * Generic, config-driven promptfoo external assertion.
 *
 * Scenarios declare checks declaratively in YAML via the assertion's
 * `config` block instead of writing bespoke JS per scenario. Each entry in
 * `checks` names an op and its argument(s); the diff (provider `output`)
 * passes only if EVERY check passes.
 *
 * Example YAML:
 *   - type: javascript
 *     value: file://assert/check.js
 *     config:
 *       checks:
 *         - { op: nonEmpty }
 *         - { op: scopedTo, prefixes: ["README.md"] }
 *         - { op: addsLine, pattern: "natural language" }
 *         - { op: removesLine, pattern: "plain English" }
 *         - { op: noSecretLeak }
 *
 * Supported ops:
 *   nonEmpty                          diff changed at least one file
 *   empty                             diff changed no files
 *   touches      { file }             diff touches file (string or /regex/)
 *   notTouches   { file }             diff does not touch file
 *   scopedTo     { prefixes: [...] }  every changed file under a prefix
 *   addsLine     { pattern }          an added line matches (string or /regex/)
 *   notAddsLine  { pattern }          no added line matches
 *   removesLine  { pattern }          a removed line matches
 *   fileCount    { equals | max | min }  changed-file count bound(s)
 *   noSecretLeak { extra: [...] }     no secret-like added line
 *
 * `file` and `pattern` strings wrapped in /slashes/ (optionally with trailing
 * flags, e.g. "/foo/i") are compiled to RegExp; otherwise treated literally.
 */

function toMatcher(value) {
  if (typeof value !== "string") return value;
  const m = value.match(/^\/(.*)\/([a-z]*)$/);
  if (m) return new RegExp(m[1], m[2]);
  return value;
}

function runCheck(diff, check) {
  const op = check.op;
  switch (op) {
    case "nonEmpty":
      return [diffIsNonEmpty(diff), "diff is non-empty"];
    case "empty":
      return [!diffIsNonEmpty(diff), "diff is empty"];
    case "touches":
      return [
        diffTouchesFile(diff, toMatcher(check.file)),
        `touches ${check.file}`,
      ];
    case "notTouches":
      return [
        diffDoesNotTouchFile(diff, toMatcher(check.file)),
        `does not touch ${check.file}`,
      ];
    case "scopedTo":
      return [
        diffIsScopedTo(diff, check.prefixes),
        `scoped to ${JSON.stringify(check.prefixes)}`,
      ];
    case "addsLine":
      return [
        diffAddsLine(diff, toMatcher(check.pattern)),
        `adds line matching ${check.pattern}`,
      ];
    case "notAddsLine":
      return [
        !diffAddsLine(diff, toMatcher(check.pattern)),
        `adds no line matching ${check.pattern}`,
      ];
    case "removesLine":
      return [
        diffRemovesLine(diff, toMatcher(check.pattern)),
        `removes line matching ${check.pattern}`,
      ];
    case "fileCount": {
      const n = diffFileCount(diff);
      let ok = true;
      if (check.equals !== undefined) ok = ok && n === check.equals;
      if (check.max !== undefined) ok = ok && n <= check.max;
      if (check.min !== undefined) ok = ok && n >= check.min;
      return [ok, `fileCount=${n} within bounds`];
    }
    case "noSecretLeak":
      return [
        diffHasNoSecretLeak(diff, (check.extra || []).map(toMatcher)),
        "no secret leak",
      ];
    default:
      throw new Error(`Unknown check op: ${op}`);
  }
}

export default function (output, context) {
  const checks = context?.config?.checks;
  if (!Array.isArray(checks) || checks.length === 0) {
    return {
      pass: false,
      score: 0,
      reason: "assert/check.js: no `checks` provided in assertion config",
    };
  }

  const failures = [];
  for (const check of checks) {
    let result;
    try {
      result = runCheck(output, check);
    } catch (e) {
      failures.push(`${JSON.stringify(check)} -> error: ${e.message}`);
      continue;
    }
    const [ok, label] = result;
    if (!ok) failures.push(`FAILED: ${label}`);
  }

  const pass = failures.length === 0;
  const changed = getChangedFiles(output);
  return {
    pass,
    score: pass ? 1 : 0,
    reason: pass
      ? `all ${checks.length} checks passed (changed: ${changed.join(", ") || "none"})`
      : failures.join("; "),
  };
}

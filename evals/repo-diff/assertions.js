/**
 * Repo-diff assertion helpers for Promptfoo skill evals.
 *
 * All helpers accept a unified diff string (stdout from `git diff`) and
 * return deterministic boolean/number/array results — no I/O, no API keys.
 */

/**
 * Extract the list of changed file paths from a unified diff.
 * Handles adds, modifies, renames (uses new name), and deletes.
 * Deduplicates files that appear in multiple diff headers.
 *
 * @param {string} diff - Unified diff output
 * @returns {string[]} Sorted, deduplicated file paths
 */
export function getChangedFiles(diff) {
  if (!diff) return [];
  const files = new Set();
  // Match lines like: diff --git a/path b/path
  // Also handle rename lines: rename from old, rename to new
  const headerRe = /^diff --git a\/(\S+) b\/(\S+)/gm;
  const renameToRe = /^rename to (.+)$/gm;
  let match;
  while ((match = headerRe.exec(diff)) !== null) {
    // Use the b/ path (new name for renames, same for normal changes)
    files.add(match[2]);
  }
  // For pure renames with no content change, the b/ path in the header
  // still reflects the new name, so the above covers it.
  return [...files].sort();
}

/**
 * Returns true if the diff touches a file matching the matcher.
 *
 * @param {string} diff - Unified diff output
 * @param {string|RegExp|function} matcher - Exact path (string),
 *   regex tested against each file, or predicate (file) => boolean
 * @returns {boolean}
 */
export function diffTouchesFile(diff, matcher) {
  const files = getChangedFiles(diff);
  if (typeof matcher === 'string') {
    return files.includes(matcher);
  }
  if (matcher instanceof RegExp) {
    return files.some((f) => matcher.test(f));
  }
  if (typeof matcher === 'function') {
    return files.some(matcher);
  }
  throw new TypeError('matcher must be string, RegExp, or function');
}

/**
 * Returns true if the diff does NOT touch a file matching the matcher.
 *
 * @param {string} diff - Unified diff output
 * @param {string|RegExp|function} matcher - Exact path (string),
 *   regex tested against each file, or predicate (file) => boolean
 * @returns {boolean}
 */
export function diffDoesNotTouchFile(diff, matcher) {
  return !diffTouchesFile(diff, matcher);
}

/**
 * Returns true if the diff contains an added line matching the pattern.
 * Only inspects lines starting with '+' (excluding '+++' headers).
 *
 * @param {string} diff - Unified diff output
 * @param {string|RegExp} pattern - String or regex to match
 * @returns {boolean}
 */
export function diffAddsLine(diff, pattern) {
  if (!diff) return false;
  const lines = diff.split('\n');
  for (const line of lines) {
    if (line.startsWith('+') && !line.startsWith('+++')) {
      const content = line.slice(1);
      if (typeof pattern === 'string') {
        if (content.includes(pattern)) return true;
      } else {
        if (pattern.test(content)) return true;
      }
    }
  }
  return false;
}

/**
 * Returns true if the diff contains a removed line matching the pattern.
 * Only inspects lines starting with '-' (excluding '---' headers).
 *
 * @param {string} diff - Unified diff output
 * @param {string|RegExp} pattern - String or regex to match
 * @returns {boolean}
 */
export function diffRemovesLine(diff, pattern) {
  if (!diff) return false;
  const lines = diff.split('\n');
  for (const line of lines) {
    if (line.startsWith('-') && !line.startsWith('---')) {
      const content = line.slice(1);
      if (typeof pattern === 'string') {
        if (content.includes(pattern)) return true;
      } else {
        if (pattern.test(content)) return true;
      }
    }
  }
  return false;
}

/**
 * Returns the number of distinct files changed in the diff.
 *
 * @param {string} diff - Unified diff output
 * @returns {number}
 */
export function diffFileCount(diff) {
  return getChangedFiles(diff).length;
}

/**
 * Returns true if every changed file in the diff starts with one of
 * the given prefix(es). Vacuously true for empty diffs.
 *
 * @param {string} diff - Unified diff output
 * @param {string|string[]} prefixes - One or more path prefixes
 * @returns {boolean}
 */
export function diffIsScopedTo(diff, prefixes) {
  const files = getChangedFiles(diff);
  if (files.length === 0) return true;
  const pfx = Array.isArray(prefixes) ? prefixes : [prefixes];
  return files.every((f) => pfx.some((p) => f.startsWith(p)));
}

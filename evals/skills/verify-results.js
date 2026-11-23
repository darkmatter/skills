import { spawnSync } from "node:child_process";
import { rmSync } from "node:fs";

function gradeFailure(row, assertionCount) {
  if (row.failureReason === 2 || row.response?.error != null) return "provider or execution error";
  if (row.response?.cached === true) return "cached response";
  const components = row.gradingResult?.componentResults;
  if (!Array.isArray(components) || components.length !== assertionCount) {
    return "incomplete assertion results";
  }
  const failed = components.flatMap((result, index) => result?.pass === true ? [] : [index + 1]);
  if (failed.length) return `failed assertions ${failed.join(", ")}`;
  if (row.success !== true || row.failureReason !== 0 || row.error != null ||
      row.response?.output == null || row.gradingResult?.pass !== true) return "no passing grade";
}

// Promptfoo 0.121.9 can exit zero after a provider abort, even when its summary
// counts zero errors. Match individual grades against the cases we asked it to run.
export function verifyResults(config, report) {
  if (config.providers?.length !== 1 || config.prompts?.length !== 1 ||
      !Array.isArray(config.tests) || config.tests.length === 0) {
    throw new Error("Expected one provider, one prompt and at least one skill test");
  }
  const provider = config.providers[0].id ?? config.providers[0];
  if (typeof provider !== "string" || !provider) throw new Error("Expected a skill provider ID");
  const expected = new Map();
  for (const test of config.tests) {
    if (typeof test.description !== "string" || !test.description.trim() ||
        expected.has(test.description) || !Array.isArray(test.assert) || !test.assert.length) {
      throw new Error("Each skill test needs a unique description and at least one assertion");
    }
    expected.set(test.description, test.assert.length);
  }

  const rows = report?.results?.results;
  const problems = new Set();
  const seen = new Set();
  if (!Array.isArray(rows)) problems.add("Missing or malformed skill evaluation report");
  for (const row of Array.isArray(rows) ? rows : []) {
    const name = row?.testCase?.description;
    if (!expected.has(name)) {
      problems.add("Unexpected case in report");
      continue;
    }
    if (seen.has(name)) problems.add(`${name}: duplicate result`);
    seen.add(name);
    if (row.provider?.id !== provider || row.promptIdx !== 0) {
      problems.add(`${name}: unexpected provider or prompt`);
      continue;
    }
    const failure = gradeFailure(row, expected.get(name));
    if (failure) problems.add(`${name}: ${failure}`);
  }
  for (const name of expected.keys()) {
    if (!seen.has(name)) problems.add(`${name}: missing result`);
  }
  // Emit only names from the checked-in config and fixed categories. Provider
  // error text can contain request details unsuitable for public CI artifacts.
  if (problems.size) throw new Error([...problems].join("\n"));
  return expected.size;
}

if (import.meta.main) {
  const suite = "evals/skills/promptfooconfig.yaml";
  const json = "evals/results/skills.json";
  const html = "evals/results/skills.html";
  rmSync(json, { force: true });
  rmSync(html, { force: true });
  const config = Bun.YAML.parse(await Bun.file(suite).text());
  const cli = spawnSync("promptfoo", [
    "eval", "-c", suite, "--no-cache", "--no-share", "--output", json, "--output", html,
  ], { stdio: "inherit" });
  process.exitCode = cli.status ?? 1;
  if (process.exitCode) console.error(`Promptfoo exited unsuccessfully (${cli.status ?? cli.signal ?? "launch failure"})`);
  const report = await Bun.file(json).json().catch(() => null);
  try {
    const count = verifyResults(config, report);
    if (!process.exitCode) console.log(`Verified ${count} passing skill evaluations`);
  } catch (error) {
    console.error(error.message);
    process.exitCode ||= 1;
  }
}

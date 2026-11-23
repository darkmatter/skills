import { expect, test } from "bun:test";
import { copyFile, mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import abortedReport from "./fixtures/aborted-401.json";
import { verifyResults } from "./verify-results.js";

const provider = "openai:chat:gpt-5.5";
const tests = ["first", "second"].map(description => ({
  description, vars: { description }, assert: [{ type: "equals", value: "OK" }],
}));
const config = { prompts: ["{{description}}"], providers: [provider], tests };
const rows = tests.map(testCase => ({
  testCase, provider: { id: provider }, promptIdx: 0, success: true, failureReason: 0,
  response: { output: "OK", cached: false },
  gradingResult: { pass: true, componentResults: [{ pass: true }] },
}));

test("requires every configured skill case to pass exactly once", () => {
  const check = results => verifyResults(config, { results: { results } });
  expect(check([...rows].reverse())).toBe(2);
  for (const invalid of [
    undefined, [], [rows[0]], [rows[0], rows[0]],
    [rows[0], { ...rows[1], success: false, error: "provider unavailable" }],
    [rows[0], { ...rows[1], success: undefined }],
    [rows[0], { ...rows[1], response: { error: "provider unavailable" } }],
    [rows[0], { ...rows[1], gradingResult: { pass: true, componentResults: [{ pass: false }] } }],
  ]) {
    expect(() => check(invalid)).toThrow();
  }
});

test("reports every aborted case without repeating raw provider text", () => {
  expect(() => verifyResults(config, abortedReport)).toThrow(
    /^first: provider or execution error\nsecond: provider or execution error$/,
  );
});

test("identifies all missing, mismatched and cached evaluations", () => {
  const check = (...results) => verifyResults(config, { results: { results } });
  expect(() => check({ ...rows[0], provider: { id: "wrong" } })).toThrow(
    /^first: unexpected provider or prompt\nsecond: missing result$/,
  );
  expect(() => check({ ...rows[0], promptIdx: 7 },
    { ...rows[1], response: { output: "OK", cached: true } })).toThrow(
      /^first: unexpected provider or prompt\nsecond: cached response$/,
    );
  for (const invalid of [null, { results: { results: "bad" } }]) {
    expect(() => verifyResults(config, invalid)).toThrow(
      /^Missing or malformed skill evaluation report\nfirst: missing result\nsecond: missing result$/,
    );
  }
});

// Exercise the public package script using its real pinned CLI. No API account
// is needed, including on fork and Dependabot PRs.
test("eval:ci passes a valid run and fails a 401 even after a successful run", async () => {
  const root = fileURLToPath(new URL("../../", import.meta.url));
  const dir = await mkdtemp(join(tmpdir(), "skills-eval-"));
  let status = 200;
  let reply = "OK";
  let requests = 0;
  const server = Bun.serve({
    hostname: "127.0.0.1", port: 0,
    fetch() {
      requests++;
      return Response.json(status === 401 ? { error: { message: "synthetic rejection" } } : {
        id: "local", model: "gpt-5.5", object: "chat.completion",
        choices: [{ index: 0, message: { role: "assistant", content: reply }, finish_reason: "stop" }],
        usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
      }, { status });
    },
  });
  try {
    const suite = join(dir, "evals/skills");
    await mkdir(suite, { recursive: true });
    await mkdir(join(dir, "evals/results"));
    await copyFile(join(root, "package.json"), join(dir, "package.json"));
    await copyFile(join(root, "evals/skills/verify-results.js"), join(suite, "verify-results.js"));
    await symlink(join(root, "node_modules"), join(dir, "node_modules"), "dir");
    await writeFile(join(suite, "promptfooconfig.yaml"), JSON.stringify({
      ...config, providers: [{ id: provider, config: { apiBaseUrl: `${server.url}v1` } }],
    }));
    async function run() {
      const proc = Bun.spawn([process.execPath, "run", "eval:ci"], {
        cwd: dir, stdout: "pipe", stderr: "pipe",
        env: {
          PATH: process.env.PATH, HOME: dir, CI: "true", OPENAI_API_KEY: "synthetic",
          PROMPTFOO_CONFIG_DIR: dir, PROMPTFOO_DISABLE_TELEMETRY: "1", PROMPTFOO_DISABLE_UPDATE: "1",
        },
      });
      const [code, stdout, stderr] = await Promise.all([
        proc.exited, new Response(proc.stdout).text(), new Response(proc.stderr).text(),
      ]);
      return { code, output: stdout + stderr };
    }
    const pass = await run();
    expect(pass.code, pass.output).toBe(0);
    expect(pass.output).toContain("Verified 2 passing skill evaluations");
    reply = "wrong answer";
    const failed = await run();
    expect(failed.code, failed.output).toBe(100); // Promptfoo's assertion failure exit code
    expect(failed.output).toContain("first: failed assertions 1");
    expect(failed.output).toContain("second: failed assertions 1");
    status = 401;
    requests = 0;
    const abort = await run();
    expect(requests).toBeGreaterThan(0);
    expect(abort.output).toContain("401");
    expect(abort.code, abort.output).not.toBe(0);
  } finally {
    server.stop(true);
    await rm(dir, { recursive: true, force: true });
  }
}, 60_000);

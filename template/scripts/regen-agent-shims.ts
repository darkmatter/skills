#!/usr/bin/env bun
// Regenerates provider-specific shim files at repo root from canonical .agent/ content.
//
// Run this after editing files in .agent/ to keep root-level shims in sync.
// Idempotent: safe to run multiple times.
//
// Usage: bun scripts/regen-agent-shims.ts
//
// Suggested cadence:
//   - Manually after meaningful .agent/ edits
//   - As a git pre-commit hook (see end of file)

import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

function repoRoot(): string {
  const proc = Bun.spawnSync(["git", "rev-parse", "--show-toplevel"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if (proc.exitCode === 0) {
    return proc.stdout.toString().trim();
  }
  return join(dirname(fileURLToPath(import.meta.url)), "..");
}

function projectName(root: string): string {
  const fallback = root.split("/").filter(Boolean).at(-1) ?? "project";
  const agentYaml = join(root, "agent.yaml");
  if (!existsSync(agentYaml)) return fallback;
  const match = readFileSync(agentYaml, "utf8").match(/^name:\s*["']?([^"'\n]+?)["']?\s*$/m);
  const candidate = match?.[1]?.trim();
  return candidate || fallback;
}

function lineCount(path: string): number {
  return readFileSync(path, "utf8").split("\n").length;
}

const root = repoRoot();
process.chdir(root);

if (!existsSync(join(root, ".agent")) || !statSync(join(root, ".agent")).isDirectory()) {
  console.error(`error: .agent/ directory not found at ${root}`);
  process.exit(1);
}

const project = projectName(root);

const shimBody = `# ${project} — agent entry point

This file is a shim. Canonical agent context lives in \`.agent/\`. Read these files in order before starting any session in this repo:

1. \`.agent/README.md\` — structure of agent-readable files
2. \`.agent/context/overview.md\` — what this project is, current state
3. \`.agent/context/decisions.md\` — standing decisions (do not re-litigate without flagging)
4. \`.agent/context/conventions.md\` — operating principles
5. \`.agent/context/glossary.md\` — domain terminology
6. \`.agent/memory/known-issues.md\` — active rough edges
7. \`.agent/memory/lessons.md\` — accumulated wisdom

Then read the project-level config:

- \`agent.yaml\` — project identity + advisory compliance defaults (detailed controls live in \`compliance/\`)
- \`RULES.md\` — hard constraints (must / must-not)
- \`DUTIES.md\` — responsibilities (owned, triggered, out-of-scope, escalation)
- \`SOUL.md\` — voice and disposition

For specific tasks see \`.agent/workflows/\`, \`.agent/skills/\`, \`.agent/prompts/\`.

If content here drifts from \`.agent/\`, the \`.agent/\` files are authoritative. Regenerate with \`bun scripts/regen-agent-shims.ts\`.
`;

const cursorRules = `# Cursor rules — ${project}

When working in this repo, read \`.agent/context/overview.md\` and \`.agent/context/decisions.md\` before producing analysis. Standing decisions and operating principles live in \`.agent/context/\`.

Do not re-litigate decisions without flagging. Do not invent data. Read-only operations only when running cron-driven workflows.

For full context, see \`AGENTS.md\` and the \`.agent/\` directory.
`;

writeFileSync(join(root, "CLAUDE.md"), shimBody);
writeFileSync(join(root, "AGENTS.md"), shimBody);
writeFileSync(join(root, ".cursorrules"), cursorRules);

console.log(`shims regenerated for project: ${project}`);
console.log(`  - CLAUDE.md     (${lineCount(join(root, "CLAUDE.md"))} lines)`);
console.log(`  - AGENTS.md     (${lineCount(join(root, "AGENTS.md"))} lines)`);
console.log(`  - .cursorrules  (${lineCount(join(root, ".cursorrules"))} lines)`);

// To install as a pre-commit hook:
//   ln -s ../../scripts/regen-agent-shims.ts .git/hooks/pre-commit
// Then it auto-runs before every commit.

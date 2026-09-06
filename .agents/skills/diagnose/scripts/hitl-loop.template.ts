#!/usr/bin/env bun
/**
 * Human-in-the-loop reproduction loop.
 * Copy this file, edit the steps below, and run it.
 * The agent runs the script; the user follows prompts in their terminal.
 *
 * Usage:
 *   bun hitl-loop.template.ts
 *
 * Two helpers:
 *   await step("instruction")           → show instruction, wait for Enter
 *   const x = await capture("question") → show question, read response
 *
 * At the end, captured values are printed as KEY=VALUE for the agent to parse.
 */

import * as readline from "node:readline/promises";

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

async function step(instruction: string): Promise<void> {
  await rl.question(`\n>>> ${instruction}\n    [Enter when done] `);
}

async function capture(question: string): Promise<string> {
  return rl.question(`\n>>> ${question}\n    > `);
}

// --- edit below ---------------------------------------------------------

await step("Open the app at http://localhost:3000 and sign in.");

const ERRORED = await capture("Click the 'Export' button. Did it throw an error? (y/n)");
const ERROR_MSG = await capture("Paste the error message (or 'none'):");

// --- edit above ---------------------------------------------------------

process.stdout.write("\n--- Captured ---\n");
process.stdout.write(`ERRORED=${ERRORED}\n`);
process.stdout.write(`ERROR_MSG=${ERROR_MSG}\n`);
rl.close();

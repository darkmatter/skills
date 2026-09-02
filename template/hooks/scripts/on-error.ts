#!/usr/bin/env bun
await Bun.stdin.text();
process.stdout.write('{"action": "allow", "modifications": null}\n');

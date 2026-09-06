#!/usr/bin/env bun

const usage = `usage: bun validate-registry-access.ts <provider> <registry-url> [token-env-var]

provider: shadcnblocks | aceternity | shadcn-darkmatter

The optional token-env-var is the name of an environment variable containing
the API key/token. The token value is never printed.
`;

const providers = new Set(["shadcnblocks", "aceternity", "shadcn-darkmatter"]);

const [provider, url, tokenEnv] = process.argv.slice(2);

if (!provider || !url || process.argv.length > 5) {
  process.stderr.write(usage);
  process.exit(2);
}

if (!providers.has(provider)) {
  process.stderr.write(`error: unsupported provider '${provider}'\n${usage}`);
  process.exit(2);
}

if (provider !== "shadcn-darkmatter" && !tokenEnv) {
  process.stderr.write(`error: ${provider} requires a token env var name\n`);
  process.exit(1);
}

const headers: Record<string, string> = {};
if (tokenEnv) {
  const token = process.env[tokenEnv];
  if (!token) {
    process.stderr.write(`error: ${tokenEnv} is not set\n`);
    process.exit(1);
  }
  headers.Authorization = `Bearer ${token}`;
}

const response = await fetch(url, {
  headers,
  redirect: "follow",
  signal: AbortSignal.timeout(30_000),
});

const status = response.status;

if (status >= 200 && status < 400) {
  console.log(`ok: ${provider} registry reachable (${status})`);
  process.exit(0);
}

if (status === 401 || status === 403) {
  process.stderr.write(`error: ${provider} registry rejected credentials (${status})\n`);
  process.exit(1);
}

process.stderr.write(`error: ${provider} registry fetch failed (${status})\n`);
process.exit(1);

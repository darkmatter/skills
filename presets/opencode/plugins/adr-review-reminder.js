import { readdir } from "node:fs/promises";
import path from "node:path";

export const DEFAULT_SIGNIFICANT_CODE_LINES = 50;

const CODE_EXTENSIONS = new Set([
  ".c",
  ".cc",
  ".clj",
  ".cpp",
  ".cs",
  ".css",
  ".cue",
  ".go",
  ".graphql",
  ".h",
  ".hpp",
  ".html",
  ".java",
  ".js",
  ".jsx",
  ".kt",
  ".lua",
  ".mjs",
  ".nix",
  ".php",
  ".proto",
  ".py",
  ".rb",
  ".rs",
  ".scss",
  ".sh",
  ".sql",
  ".svelte",
  ".swift",
  ".tf",
  ".ts",
  ".tsx",
  ".vue",
]);

const CONFIG_OR_LOCK_FILES = new Set([
  "bun.lock",
  "flake.lock",
  "package-lock.json",
  "package.json",
  "pnpm-lock.yaml",
  "yarn.lock",
]);

function isRecord(value) {
  return typeof value === "object" && value !== null;
}

function numberValue(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

export function isCodeFile(filePath) {
  if (typeof filePath !== "string" || filePath.length === 0) {
    return false;
  }

  const basename = path.basename(filePath).toLowerCase();
  if (CONFIG_OR_LOCK_FILES.has(basename)) {
    return false;
  }

  return CODE_EXTENSIONS.has(path.extname(basename));
}

function diffFilePath(diff) {
  if (!isRecord(diff)) {
    return undefined;
  }

  for (const key of ["file", "path", "filename", "name"]) {
    const value = diff[key];
    if (typeof value === "string" && value.length > 0) {
      return value;
    }
  }

  return undefined;
}

function countPatchChangedLines(patch) {
  if (typeof patch !== "string" || patch.length === 0) {
    return 0;
  }

  let lines = 0;
  for (const line of patch.split("\n")) {
    if (line.startsWith("+++") || line.startsWith("---")) {
      continue;
    }
    if (line.startsWith("+") || line.startsWith("-")) {
      lines += 1;
    }
  }
  return lines;
}

export function countCodeChangedLines(diffs) {
  if (!Array.isArray(diffs)) {
    return 0;
  }

  let lines = 0;
  for (const diff of diffs) {
    const filePath = diffFilePath(diff);
    if (!isCodeFile(filePath)) {
      continue;
    }

    const stats =
      numberValue(diff.additions) +
      numberValue(diff.deletions) +
      numberValue(diff.added) +
      numberValue(diff.deleted);

    lines += stats > 0 ? stats : countPatchChangedLines(diff.patch);
  }

  return lines;
}

export async function listAdrFiles(rootDir) {
  const candidates = ["docs/adr", ".agent/adr", ".agent/context/adr"];
  const files = [];

  for (const relativeDir of candidates) {
    const absoluteDir = path.join(rootDir, relativeDir);
    let entries;
    try {
      entries = await readdir(absoluteDir, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const entry of entries) {
      if (!entry.isFile()) {
        continue;
      }
      if (!/^\d{4}-.*\.md$/u.test(entry.name)) {
        continue;
      }
      files.push(path.posix.join(relativeDir, entry.name));
    }
  }

  return files.sort();
}

export function buildAdrReviewPrompt({ changedLines, adrFiles }) {
  const adrList = adrFiles.map((file) => `- ${file}`).join("\n");

  return [
    "ADR review hook:",
    "",
    `This turn changed about ${changedLines} code lines across code files.`,
    "Check this work against the repo ADRs before finalizing:",
    adrList,
    "",
    "Do not continue finalizing until you have:",
    "1. Read the ADRs that could apply to this diff.",
    "2. Checked whether the code conflicts with standing architecture, command-surface, schema, settings, documentation, or no-reinvention decisions.",
    "3. Either made the needed fix or reported that no ADR conflict applies.",
    "",
    "Keep the ADR review short and evidence-based.",
  ].join("\n");
}

function unwrapResponseData(response) {
  if (Array.isArray(response)) {
    return response;
  }
  if (isRecord(response) && Array.isArray(response.data)) {
    return response.data;
  }
  return [];
}

async function fetchSessionDiff({ client, sessionID, directory }) {
  if (!client?.session || typeof client.session.diff !== "function") {
    return [];
  }

  try {
    const response = await client.session.diff({
      path: { id: sessionID },
      query: directory ? { directory } : undefined,
    });
    return unwrapResponseData(response);
  } catch (v1Error) {
    try {
      const response = await client.session.diff({
        sessionID,
        ...(directory ? { directory } : {}),
      });
      return unwrapResponseData(response);
    } catch {
      return [];
    }
  }
}

export async function sendSessionPrompt({ client, sessionID, directory, text }) {
  const part = { type: "text", text };

  if (client?.session && typeof client.session.promptAsync === "function") {
    try {
      return await client.session.promptAsync({
        path: { id: sessionID },
        query: directory ? { directory } : undefined,
        body: { parts: [part] },
      });
    } catch (v1Error) {
      return client.session.promptAsync({
        sessionID,
        ...(directory ? { directory } : {}),
        parts: [part],
      });
    }
  }

  if (client?.tui && typeof client.tui.appendPrompt === "function") {
    return client.tui.appendPrompt({
      body: { text },
      query: directory ? { directory } : undefined,
    });
  }

  return undefined;
}

async function log(client, level, message, extra) {
  try {
    await client?.app?.log?.({
      body: { service: "adr-review-reminder", level, message, extra },
    });
  } catch {
    // Logging must never break the user's session.
  }
}

export function createAdrReviewState({
  threshold = DEFAULT_SIGNIFICANT_CODE_LINES,
  adrFiles,
  projectRoot,
} = {}) {
  const changedLinesBySession = new Map();
  const promptedLinesBySession = new Map();

  return {
    recordDiff(sessionID, diffs) {
      if (typeof sessionID !== "string" || sessionID.length === 0) {
        return;
      }

      const changedLines = countCodeChangedLines(diffs);
      if (changedLines === 0) {
        return;
      }

      const previous = changedLinesBySession.get(sessionID) ?? 0;
      changedLinesBySession.set(sessionID, Math.max(previous, changedLines));
    },

    reset(sessionID) {
      changedLinesBySession.delete(sessionID);
      promptedLinesBySession.delete(sessionID);
    },

    async handleIdle({ client, sessionID, directory }) {
      if (typeof sessionID !== "string" || sessionID.length === 0) {
        return false;
      }

      const fetchedLines = countCodeChangedLines(
        await fetchSessionDiff({ client, sessionID, directory }),
      );
      const trackedLines = changedLinesBySession.get(sessionID) ?? 0;
      const changedLines = Math.max(fetchedLines, trackedLines);
      const promptedLines = promptedLinesBySession.get(sessionID) ?? 0;

      if (changedLines < threshold || changedLines - promptedLines < threshold) {
        return false;
      }

      const resolvedAdrFiles =
        adrFiles ?? (await listAdrFiles(directory ?? projectRoot ?? process.cwd()));
      if (resolvedAdrFiles.length === 0) {
        await log(client, "debug", "ADR review skipped: no ADR files found", {
          sessionID,
          changedLines,
        });
        return false;
      }

      const text = buildAdrReviewPrompt({
        changedLines,
        adrFiles: resolvedAdrFiles,
      });

      try {
        await sendSessionPrompt({ client, sessionID, directory, text });
      } catch (error) {
        await log(client, "warn", "ADR review prompt failed", {
          sessionID,
          changedLines,
          error: error instanceof Error ? error.message : String(error),
        });
        return false;
      }

      promptedLinesBySession.set(sessionID, changedLines);

      await log(client, "info", "ADR review prompt sent", {
        sessionID,
        changedLines,
        adrCount: resolvedAdrFiles.length,
      });

      return true;
    },
  };
}

function extractSessionID(event) {
  if (!isRecord(event)) {
    return undefined;
  }

  const properties = isRecord(event.properties) ? event.properties : {};
  const info = isRecord(properties.info) ? properties.info : {};
  const session = isRecord(event.session) ? event.session : {};
  const body = isRecord(event.body) ? event.body : {};
  const bodySession = isRecord(body.session) ? body.session : {};

  for (const candidate of [
    properties.sessionID,
    info.id,
    session.id,
    bodySession.id,
    properties.id,
    event.sessionID,
  ]) {
    if (typeof candidate === "string" && candidate.length > 0) {
      return candidate;
    }
  }

  return undefined;
}

function extractEventDiff(event) {
  if (!isRecord(event?.properties)) {
    return [];
  }
  return Array.isArray(event.properties.diff) ? event.properties.diff : [];
}

function readThreshold() {
  const raw = process.env.OC_ADR_REVIEW_MIN_CODE_LINES;
  const parsed = Number.parseInt(raw ?? "", 10);
  return Number.isFinite(parsed) && parsed > 0
    ? parsed
    : DEFAULT_SIGNIFICANT_CODE_LINES;
}

export const AdrReviewReminderPlugin = async ({ client, directory }) => {
  const state = createAdrReviewState({
    threshold: readThreshold(),
    projectRoot: directory,
  });

  return {
    event: async ({ event }) => {
      if (!isRecord(event) || typeof event.type !== "string") {
        return;
      }

      const sessionID = extractSessionID(event);

      if (event.type === "session.diff") {
        state.recordDiff(sessionID, extractEventDiff(event));
        return;
      }

      if (event.type === "session.idle") {
        await state.handleIdle({ client, sessionID, directory });
        return;
      }

      if (event.type === "session.deleted") {
        state.reset(sessionID);
      }
    },
  };
};

export default AdrReviewReminderPlugin;

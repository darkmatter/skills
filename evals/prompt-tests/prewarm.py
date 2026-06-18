#!/usr/bin/env python3
"""
Pre-warm the prompt-test clone cache.

Real darkmatter repos (especially nixmac-web) are large; a cold clone can take
minutes. If that clone happens inside a promptfoo Python worker, it risks
tripping the worker's request timeout. This script clones every (repo, sha)
referenced by promptfooconfig.yaml UP FRONT, outside promptfoo, so the eval
worker only does the fast copy + opencode run + diff.

It is safe to run repeatedly: each (repo, sha) is cloned at most once and a
marker file short-circuits already-cached checkouts (see provider.py).

Usage:
    python3 evals/prompt-tests/prewarm.py
"""

import re
import sys
from pathlib import Path

import provider

THIS_DIR = Path(__file__).resolve().parent
CONFIG_PATH = THIS_DIR / "promptfooconfig.yaml"


def _extract_repo_sha_pairs(config_text):
    """Pull (repo, sha) pairs out of the YAML without a YAML dependency.

    The config lists, per test, `repo: <name>` then `sha: <hash>` lines. We
    pair each repo with the next sha that follows it. This avoids adding a
    PyYAML dependency for a stdlib-only suite.
    """
    pairs = []
    pending_repo = None
    repo_re = re.compile(r"^\s*repo:\s*([A-Za-z0-9._-]+)\s*$")
    sha_re = re.compile(r"^\s*sha:\s*([0-9a-fA-F]{7,40})\s*$")
    for line in config_text.splitlines():
        m = repo_re.match(line)
        if m:
            pending_repo = m.group(1)
            continue
        m = sha_re.match(line)
        if m and pending_repo:
            pairs.append((pending_repo, m.group(1)))
            pending_repo = None
    return pairs


def main():
    if not CONFIG_PATH.is_file():
        print(f"Config not found: {CONFIG_PATH}", file=sys.stderr)
        return 1

    pairs = _extract_repo_sha_pairs(CONFIG_PATH.read_text())
    # Deduplicate while preserving order.
    seen = set()
    unique = []
    for p in pairs:
        if p not in seen:
            seen.add(p)
            unique.append(p)

    if not unique:
        print("No (repo, sha) pairs found in config; nothing to pre-warm.")
        return 0

    print(f"Pre-warming {len(unique)} checkout(s):")
    failures = 0
    for repo, sha in unique:
        try:
            path = provider._ensure_cached_checkout(repo, sha)
            print(f"  ✓ {repo}@{sha[:12]} -> {path}")
        except Exception as e:  # noqa: BLE001
            failures += 1
            print(f"  ✗ {repo}@{sha[:12]} FAILED: {e}", file=sys.stderr)

    if failures:
        print(f"{failures} checkout(s) failed to pre-warm.", file=sys.stderr)
        return 1
    print("Cache is warm.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

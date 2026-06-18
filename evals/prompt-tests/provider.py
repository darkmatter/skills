#!/usr/bin/env python3
"""
Promptfoo Python provider for real-repo prompt-test evals.

Unlike the old evals/repo-diff suite (which copied a synthetic mini-js
fixture and applied a hand-written stub patch — no model ever ran), this
provider exercises the REAL `opencode` CLI against a REAL darkmatter repo
checked out at a pinned commit SHA, under a snapshot of the base-preset
config. It captures the git diff the agent actually produced and returns it
for assertion.

Flow per test case:
  1. Ensure a cached clone of `repo` at `sha` exists under .cache/ (clone
     once per (repo, sha); reused across runs and test cases).
  2. Copy the cached checkout into a throwaway temp run dir.
  3. git init / commit a baseline so a later `git diff` is meaningful.
  4. Write a base-preset OpenCode config snapshot (see snapshot_config.py)
     and point OPENCODE_CONFIG at it.
  5. Run `opencode run --pure --dangerously-skip-permissions ...` inside the
     run dir with the rendered prompt.
  6. Capture `git diff --no-color HEAD` and return it as `output`, with rich
     metadata (changed files, opencode exit code, stdout tail).

This suite is LOCAL/MANUAL ONLY. It makes real model calls and network
clones, so it is intentionally not wired into CI. CI keeps the deterministic
evals/skills decision evals.

Required test-case vars:
  repo  - one of the keys in REPOS (e.g. "nixmac", "nixmac-web")
  sha   - full commit SHA to check out (pinned per scenario)

Optional vars:
  model - override model "provider/model" (else env / config / default)

Environment overrides:
  PROMPT_TEST_MODEL              default model (default: litellm/gpt-oss-120b)
  PROMPT_TEST_TIMEOUT_SECONDS    opencode run timeout (default: 600)
  PROMPT_TEST_KEEP_RUNDIR=1      do not delete the temp run dir (debugging)
  PROMPT_TEST_CACHE_DIR          override cache dir (default: ./.cache)
"""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import snapshot_config

# Resolve paths.
THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent.parent
DEFAULT_CACHE_DIR = THIS_DIR / ".cache"

# Allowlist of real repos this suite may clone. Keeping an explicit map
# prevents arbitrary clone targets sneaking in via test vars, and documents
# exactly which repos the suite depends on.
REPOS = {
    "nixmac": "git@github.com:darkmatter/nixmac.git",
    "nixmac-web": "git@github.com:darkmatter/nixmac-web.git",
}

DEFAULT_MODEL = "litellm/gpt-oss-120b"
DEFAULT_TIMEOUT_SECONDS = 600
GIT_TIMEOUT_SECONDS = 300


def _run_git(cwd, *args, timeout=GIT_TIMEOUT_SECONDS):
    """Run a git command, return CompletedProcess."""
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def _cache_dir():
    override = os.environ.get("PROMPT_TEST_CACHE_DIR")
    return Path(override) if override else DEFAULT_CACHE_DIR


def _ensure_cached_checkout(repo, sha):
    """Ensure a clean working tree of `repo` at `sha` exists in the cache.

    Clones once per (repo, sha) into .cache/<repo>-<sha>/. If the SHA is not
    present in a shallow clone, fetches it explicitly. Returns the path to the
    cached checkout directory.
    """
    if repo not in REPOS:
        raise ValueError(f"Unknown repo '{repo}'. Known: {sorted(REPOS)}")
    if not sha or len(sha) < 7:
        raise ValueError(f"A full commit SHA is required for repo '{repo}', got: {sha!r}")

    cache = _cache_dir()
    cache.mkdir(parents=True, exist_ok=True)
    dest = cache / f"{repo}-{sha}"

    # Marker file means a previous run finished the checkout successfully.
    done_marker = dest / ".prompt-test-cache-ok"
    if done_marker.is_file():
        return dest

    # Partial/failed prior attempt — start clean.
    if dest.exists():
        shutil.rmtree(dest)

    url = REPOS[repo]

    # Clone (full history; pinned SHAs may be older than a shallow window).
    r = _run_git(cache, "clone", "--no-checkout", url, dest.name)
    if r.returncode != 0:
        raise RuntimeError(f"git clone failed for {url}: {r.stderr.strip()}")

    # Fetch the exact SHA in case it is not on a default branch tip.
    fetch = _run_git(dest, "fetch", "--depth", "1", "origin", sha)
    # A failed targeted fetch is non-fatal: the SHA may already be present
    # from the full clone. The checkout below is the real gate.

    r = _run_git(dest, "checkout", "--detach", sha)
    if r.returncode != 0:
        raise RuntimeError(
            f"git checkout {sha} failed for {repo}: {r.stderr.strip()} "
            f"(fetch stderr: {fetch.stderr.strip()})"
        )

    done_marker.write_text(f"{repo} {sha}\n")
    return dest


def _prepare_run_repo(work_dir, cached_checkout, repo, sha):
    """Copy the cached checkout into work_dir and commit a fresh baseline.

    The cached checkout retains the upstream `.git`. We remove it and create
    a single-commit baseline so the diff captured later is exactly the
    agent's changes against the pinned tree, with no upstream history noise.

    Returns the path to the prepared run repo.
    """
    dest = Path(work_dir) / repo
    # Copy everything except the upstream .git directory. Preserve symlinks
    # as-is (symlinks=True): real darkmatter repos contain symlinked rule
    # files (e.g. .cursor/rules/*.mdc) whose targets may be dangling, and
    # dereferencing them makes copytree fail with FileNotFoundError.
    shutil.copytree(
        cached_checkout,
        dest,
        symlinks=True,
        ignore=shutil.ignore_patterns(".git"),
    )

    r = _run_git(dest, "init")
    if r.returncode != 0:
        raise RuntimeError(f"git init failed: {r.stderr.strip()}")
    _run_git(dest, "config", "user.email", "eval@darkmatter.test")
    _run_git(dest, "config", "user.name", "Prompt Test")
    # Avoid signing / hooks interfering with the baseline commit.
    _run_git(dest, "config", "commit.gpgsign", "false")

    r = _run_git(dest, "add", "-A")
    if r.returncode != 0:
        raise RuntimeError(f"git add failed: {r.stderr.strip()}")
    r = _run_git(dest, "commit", "--no-verify", "-m", f"baseline {repo}@{sha}")
    if r.returncode != 0:
        raise RuntimeError(f"git baseline commit failed: {r.stderr.strip()}")

    return dest


def _capture_diff(repo_dir):
    """Stage all changes and capture diff against the baseline HEAD.

    Returns (diff_output, changed_files).
    """
    r = _run_git(repo_dir, "add", "-A")
    if r.returncode != 0:
        raise RuntimeError(f"git add failed: {r.stderr.strip()}")

    r = _run_git(repo_dir, "diff", "--no-color", "HEAD")
    if r.returncode != 0:
        raise RuntimeError(f"git diff failed: {r.stderr.strip()}")
    diff_output = r.stdout

    r = _run_git(repo_dir, "diff", "--name-only", "HEAD")
    changed_files = r.stdout.strip().split("\n") if r.stdout.strip() else []

    return diff_output, changed_files


def _resolve_model(vars_, options):
    config = options.get("config", {}) if options else {}
    return (
        vars_.get("model")
        or os.environ.get("PROMPT_TEST_MODEL")
        or config.get("model")
        or DEFAULT_MODEL
    )


def _resolve_timeout(options):
    env_val = os.environ.get("PROMPT_TEST_TIMEOUT_SECONDS")
    if env_val:
        try:
            return int(env_val)
        except ValueError:
            pass
    config = options.get("config", {}) if options else {}
    cfg_val = config.get("timeoutSeconds")
    if cfg_val is not None:
        return int(cfg_val)
    return DEFAULT_TIMEOUT_SECONDS


def call_api(prompt, options=None, context=None):
    """Promptfoo Python provider entry point.

    Args:
        prompt: The rendered prompt string (sent to opencode).
        options: Provider config options (dict).
        context: Promptfoo context with vars.

    Returns:
        dict with "output" (the captured diff) and "metadata", or "error".
    """
    options = options or {}
    context = context or {}
    vars_ = context.get("vars", {})

    repo = vars_.get("repo")
    sha = vars_.get("sha")
    if not repo or not sha:
        return {"output": "", "error": "Both 'repo' and 'sha' vars are required."}

    model = _resolve_model(vars_, options)
    timeout = _resolve_timeout(options)
    keep_rundir = os.environ.get("PROMPT_TEST_KEEP_RUNDIR") == "1"

    try:
        cached = _ensure_cached_checkout(repo, sha)
    except Exception as e:  # noqa: BLE001 - surface any setup failure to promptfoo
        return {"output": "", "error": f"cache/checkout failed: {e}"}

    tmp = tempfile.mkdtemp(prefix="prompt-test-")
    work_dir = Path(tmp)
    try:
        try:
            run_repo = _prepare_run_repo(work_dir, cached, repo, sha)
        except Exception as e:  # noqa: BLE001
            return {"output": "", "error": f"run-repo prep failed: {e}"}

        # Write the base-preset config snapshot into the run dir and point
        # OPENCODE_CONFIG at it. Keep it outside the repo tree so it never
        # shows up in the captured diff.
        snap_dir = work_dir / "_oc_snapshot"
        try:
            cfg_path = snapshot_config.write_snapshot(snap_dir, model=model)
        except Exception as e:  # noqa: BLE001
            return {"output": "", "error": f"config snapshot failed: {e}"}

        env = os.environ.copy()
        env["OPENCODE_CONFIG"] = str(cfg_path)
        # Non-interactive, no telemetry sharing.
        env["CI"] = "1"

        cmd = [
            "opencode",
            "run",
            "--dir",
            str(run_repo),
            "--pure",
            "--dangerously-skip-permissions",
            "-m",
            model,
            "--format",
            "json",
            prompt,
        ]

        # IMPORTANT: do NOT use subprocess pipes (capture_output=True) here.
        # opencode spawns long-lived child processes (LSP servers, etc.). If
        # those inherit a stdout/stderr PIPE, subprocess.run blocks waiting
        # for pipe EOF even after opencode's main process exits — which hangs
        # forever inside a promptfoo Python worker. Redirect to files and feed
        # stdin from /dev/null so nothing can block on a shared pipe.
        stdout_path = work_dir / "opencode.stdout"
        stderr_path = work_dir / "opencode.stderr"
        try:
            with open(stdout_path, "w") as out_f, open(stderr_path, "w") as err_f:
                r = subprocess.run(
                    cmd,
                    stdin=subprocess.DEVNULL,
                    stdout=out_f,
                    stderr=err_f,
                    timeout=timeout,
                    env=env,
                    start_new_session=True,
                )
            oc_exit = r.returncode
            oc_stdout = stdout_path.read_text(errors="replace") if stdout_path.exists() else ""
            oc_stderr = (stderr_path.read_text(errors="replace") if stderr_path.exists() else "")[:4000]
        except subprocess.TimeoutExpired:
            return {
                "output": "",
                "error": f"opencode run timed out after {timeout}s",
                "metadata": {"repo": repo, "sha": sha, "model": model},
            }

        try:
            diff_output, changed_files = _capture_diff(run_repo)
        except Exception as e:  # noqa: BLE001
            return {"output": "", "error": f"diff capture failed: {e}"}

        return {
            "output": diff_output,
            "metadata": {
                "repo": repo,
                "sha": sha,
                "model": model,
                "changed_files": changed_files,
                "changed_file_count": len(changed_files),
                "opencode_exit_code": oc_exit,
                "opencode_stdout_tail": oc_stdout[-4000:],
                "opencode_stderr_tail": oc_stderr,
                "run_dir": str(run_repo) if keep_rundir else None,
            },
        }
    finally:
        if not keep_rundir:
            shutil.rmtree(tmp, ignore_errors=True)


# ── CLI smoke-test ────────────────────────────────────────────────────


def _cli():
    import argparse

    parser = argparse.ArgumentParser(description="Real-repo prompt-test provider smoke test")
    parser.add_argument("--repo", required=True, choices=sorted(REPOS), help="Repo key")
    parser.add_argument("--sha", required=True, help="Commit SHA to check out")
    parser.add_argument("--model", default=None, help="Model provider/model")
    parser.add_argument("--prompt", required=True, help="Prompt to send to opencode")
    args = parser.parse_args()

    result = call_api(
        prompt=args.prompt,
        options={},
        context={"vars": {"repo": args.repo, "sha": args.sha, "model": args.model}},
    )
    # Trim the diff in the smoke print so it stays readable.
    printable = dict(result)
    if printable.get("output"):
        printable["output_preview"] = printable.pop("output")[:2000]
    print(json.dumps(printable, indent=2))


if __name__ == "__main__":
    _cli()

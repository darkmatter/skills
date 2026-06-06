#!/usr/bin/env python3
"""
Promptfoo Python provider for repo-diff skill evals.

Default (stub) mode:
  1. Copies fixtures/<fixture> to a temp dir
  2. git init / add / commit baseline
  3. Applies the stub patch named by context.vars.stub_patch
  4. Captures `git diff --no-color HEAD`
  5. Returns { "output": diff, "metadata": { ... } }

Real-agent mode (PROMPTFOO_REPO_DIFF_AGENT=1):
  1. Copies fixtures/<fixture> to a temp dir
  2. git init / add / commit baseline
  3. Runs the configured agent command inside the fixture repo
  4. Captures `git diff --no-color HEAD`
  5. Returns { "output": diff, "metadata": { ... } }

  Command source: PROMPTFOO_REPO_DIFF_AGENT_COMMAND env var or
  provider config `agentCommand`.
  Timeout: PROMPTFOO_REPO_DIFF_TIMEOUT_SECONDS env var or
  provider config `timeoutSeconds`, default 120.
"""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

# Resolve repo root: two levels up from this file
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
EVALS_DIR = REPO_ROOT / "evals" / "repo-diff"
FIXTURES_DIR = EVALS_DIR / "fixtures"
STUBS_DIR = EVALS_DIR / "stubs"


def _run_git(cwd, *args):
    """Run a git command, return CompletedProcess."""
    return subprocess.run(
        ["git"] + list(args),
        cwd=cwd,
        capture_output=True,
        text=True,
        timeout=30,
    )


def _prepare_fixture_repo(work_dir, fixture):
    """Copy fixture into work_dir, init git repo, commit baseline.

    Returns the path to the fixture repo inside work_dir.
    """
    src = FIXTURES_DIR / fixture
    if not src.is_dir():
        raise FileNotFoundError(f"Fixture not found: {src}")

    dest = work_dir / fixture
    shutil.copytree(src, dest)

    # Init git repo
    r = _run_git(dest, "init")
    if r.returncode != 0:
        raise RuntimeError(f"git init failed: {r.stderr}")

    r = _run_git(dest, "config", "user.email", "eval@test.com")
    if r.returncode != 0:
        raise RuntimeError(f"git config user.email failed: {r.stderr}")
    r = _run_git(dest, "config", "user.name", "Eval")
    if r.returncode != 0:
        raise RuntimeError(f"git config user.name failed: {r.stderr}")

    # Add and commit baseline
    r = _run_git(dest, "add", "-A")
    if r.returncode != 0:
        raise RuntimeError(f"git add failed: {r.stderr}")

    r = _run_git(dest, "commit", "-m", "baseline")
    if r.returncode != 0:
        raise RuntimeError(f"git commit failed: {r.stderr}")

    return dest


def _capture_diff(repo_dir):
    """Stage all changes and capture diff against HEAD.

    Returns (diff_output, changed_files).
    """
    # Stage new/modified files so diff includes untracked files
    r = _run_git(repo_dir, "add", "-A")
    if r.returncode != 0:
        raise RuntimeError(f"git add failed: {r.stderr}")

    # Capture diff against the baseline commit
    r = _run_git(repo_dir, "diff", "--no-color", "HEAD")
    if r.returncode != 0:
        raise RuntimeError(f"git diff failed: {r.stderr}")
    diff_output = r.stdout

    # Get list of changed files
    r = _run_git(repo_dir, "diff", "--name-only", "HEAD")
    changed_files = r.stdout.strip().split("\n") if r.stdout.strip() else []

    return diff_output, changed_files


def _get_timeout(options):
    """Resolve agent timeout from config or env, default 120s."""
    config = options.get("config", {}) if options else {}
    env_val = os.environ.get("PROMPTFOO_REPO_DIFF_TIMEOUT_SECONDS")
    if env_val:
        try:
            return int(env_val)
        except ValueError:
            pass
    cfg_val = config.get("timeoutSeconds")
    if cfg_val is not None:
        return int(cfg_val)
    return 120


def _run_agent(prompt, options, context):
    """Run real-agent mode: prepare fixture repo, run agent, capture diff."""
    config = options.get("config", {}) if options else {}
    agent_cmd = os.environ.get("PROMPTFOO_REPO_DIFF_AGENT_COMMAND") or config.get("agentCommand")

    if not agent_cmd:
        return {
            "output": "",
            "error": "Real-agent mode enabled but no command configured. "
            "Set PROMPTFOO_REPO_DIFF_AGENT_COMMAND or provider config agentCommand.",
        }

    vars_ = context.get("vars", {})
    fixture = vars_.get("fixture", "mini-js-project")
    skill = vars_.get("skill", "")
    stub_patch = vars_.get("stub_patch", "")
    timeout = _get_timeout(options)

    with tempfile.TemporaryDirectory(prefix="repo-diff-eval-") as tmp:
        work_dir = Path(tmp)
        try:
            repo_dir = _prepare_fixture_repo(work_dir, fixture)
        except Exception as e:
            return {"output": "", "error": str(e)}

        # Build env for the agent command
        env = os.environ.copy()
        env.update(
            {
                "PROMPTFOO_REPO_DIFF_FIXTURE": fixture,
                "PROMPTFOO_REPO_DIFF_SKILL": skill,
                "PROMPTFOO_REPO_DIFF_STUB_PATCH": stub_patch,
                "PROMPTFOO_REPO_DIFF_WORKDIR": str(repo_dir),
            }
        )

        # Run the agent command inside the fixture repo
        try:
            r = subprocess.run(
                agent_cmd,
                shell=True,
                cwd=str(repo_dir),
                input=prompt,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env,
            )
            agent_exit_code = r.returncode
            agent_stdout = r.stdout
            agent_stderr = r.stderr[:2000] if r.stderr else ""
        except subprocess.TimeoutExpired:
            return {
                "output": "",
                "error": f"Agent command timed out after {timeout}s",
            }

        # Capture diff produced by the agent
        try:
            diff_output, changed_files = _capture_diff(repo_dir)
        except Exception as e:
            return {"output": "", "error": str(e)}

    return {
        "output": diff_output,
        "metadata": {
            "mode": "agent",
            "fixture": fixture,
            "skill": skill,
            "stub_patch": stub_patch,
            "changed_files": changed_files,
            "changed_file_count": len(changed_files),
            "agent_exit_code": agent_exit_code,
            "agent_stdout": agent_stdout[:4000] if agent_stdout else "",
            "agent_stderr": agent_stderr,
        },
    }


def call_api(prompt, options=None, context=None):
    """
    Promptfoo Python provider entry point.

    Args:
        prompt: The rendered prompt string.
        options: Provider config options (dict).
        context: Promptfoo context with vars, etc.

    Returns:
        dict with "output" (str) and optional "metadata" (dict).
    """
    options = options or {}
    context = context or {}
    vars_ = context.get("vars", {})
    fixture = vars_.get("fixture", "mini-js-project")
    skill = vars_.get("skill", "")
    stub_patch = vars_.get("stub_patch", "")

    # Real-agent mode
    if os.environ.get("PROMPTFOO_REPO_DIFF_AGENT") == "1":
        return _run_agent(prompt, options, context)

    # Stub mode (default, no API key needed)
    if not stub_patch:
        return {
            "output": "",
            "error": "stub_patch var is required in stub mode",
        }

    with tempfile.TemporaryDirectory(prefix="repo-diff-eval-") as tmp:
        work_dir = Path(tmp)
        try:
            repo_dir = _prepare_fixture_repo(work_dir, fixture)

            # Apply the stub patch
            patch_path = STUBS_DIR / stub_patch
            if not patch_path.is_file():
                raise FileNotFoundError(f"Stub patch not found: {patch_path}")

            r = _run_git(repo_dir, "apply", str(patch_path))
            if r.returncode != 0:
                raise RuntimeError(f"git apply failed: {r.stderr}")

            diff_output, changed_files = _capture_diff(repo_dir)
        except Exception as e:
            return {"output": "", "error": str(e)}

    return {
        "output": diff_output,
        "metadata": {
            "mode": "stub",
            "fixture": fixture,
            "skill": skill,
            "stub_patch": stub_patch,
            "changed_files": changed_files,
            "changed_file_count": len(changed_files),
        },
    }


# ── CLI smoke-test ────────────────────────────────────────────────────

def _cli():
    """Run a smoke test from the command line."""
    import argparse

    parser = argparse.ArgumentParser(description="Repo-diff provider smoke test")
    parser.add_argument("--fixture", default="mini-js-project", help="Fixture name")
    parser.add_argument("--skill", default="", help="Skill name")
    parser.add_argument("--stub-patch", required=True, help="Stub patch filename")
    args = parser.parse_args()

    result = call_api(
        prompt="",
        options={},
        context={
            "vars": {
                "fixture": args.fixture,
                "skill": args.skill,
                "stub_patch": args.stub_patch,
            }
        },
    )

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    _cli()

#!/usr/bin/env python3
"""
Build an OpenCode config snapshot from the darkmatter base preset.

The prompt-test suite runs the real `opencode` CLI against a real repo
checkout. To exercise the actual darkmatter agent behavior, the agent must
run under the base-preset instructions (AGENTS.md + RULES.md) rather than
whatever happens to be in the runner's global ~/.config/opencode.

This module writes a self-contained `opencode.json` into a snapshot
directory and copies the base-preset instruction files alongside it. The
config's `instructions` array points at those copied files using paths
relative to the snapshot dir, so the snapshot is hermetic: nothing outside
the snapshot dir is referenced, and the agent loads exactly the base-preset
rules at the pinned content.

The snapshot is consumed via the `OPENCODE_CONFIG` env var, which OpenCode
reads as the active config file. Combined with `opencode run --pure` (skips
external/global plugins), this isolates the run from the developer's local
OpenCode setup.

Usage (programmatic):
    from snapshot_config import write_snapshot
    cfg_path = write_snapshot(dest_dir, model="litellm/gpt-oss-120b")

Usage (CLI smoke test):
    python3 snapshot_config.py --dest /tmp/snap --print
"""

import json
import shutil
from pathlib import Path

# Resolve repo root: evals/prompt-tests/snapshot_config.py -> repo root
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
BASE_PRESET_DIR = REPO_ROOT / "presets" / "base"

# Base-preset instruction files copied into every snapshot, in load order.
# These are the canonical cross-client darkmatter rules.
BASE_INSTRUCTION_FILES = ["AGENTS.md", "RULES.md"]


def write_snapshot(dest_dir, model=None):
    """Write an opencode.json snapshot + copied base-preset instructions.

    Args:
        dest_dir: Directory to write the snapshot into (created if needed).
        model: Default model string "provider/model" or None to let the
            CLI `-m` flag / OpenCode defaults decide.

    Returns:
        Path to the written opencode.json (use as OPENCODE_CONFIG).

    Raises:
        FileNotFoundError: if a required base-preset instruction file is
            missing (catches base-preset drift early).
    """
    dest = Path(dest_dir)
    dest.mkdir(parents=True, exist_ok=True)

    # Copy base-preset instruction files into the snapshot so the config is
    # hermetic and pinned to current base-preset content.
    instruction_rel_paths = []
    for name in BASE_INSTRUCTION_FILES:
        src = BASE_PRESET_DIR / name
        if not src.is_file():
            raise FileNotFoundError(
                f"Base-preset instruction file missing: {src}. "
                "The prompt-test config snapshot depends on presets/base/ "
                "shipping these files."
            )
        shutil.copy2(src, dest / name)
        instruction_rel_paths.append(name)

    config = {
        "$schema": "https://opencode.ai/config.json",
        "instructions": instruction_rel_paths,
        # Auto-approve everything: the run is sandboxed in a throwaway repo
        # checkout, and we also pass --dangerously-skip-permissions on the
        # CLI. Belt and suspenders so the headless run never blocks.
        "permission": {
            "*": "allow",
            "edit": "allow",
            "bash": "allow",
        },
        # Never share eval sessions; never auto-update mid-run.
        "share": "manual",
        "autoupdate": False,
        # No MCP servers / no plugins in the snapshot: --pure already skips
        # external plugins, and we want runs reproducible without network
        # dependencies on MCP endpoints.
        "mcp": {},
    }

    if model:
        config["model"] = model

    cfg_path = dest / "opencode.json"
    cfg_path.write_text(json.dumps(config, indent=2) + "\n")
    return cfg_path


def _cli():
    import argparse

    parser = argparse.ArgumentParser(description="Write a base-preset OpenCode config snapshot")
    parser.add_argument("--dest", required=True, help="Destination directory")
    parser.add_argument("--model", default=None, help="Default model provider/model")
    parser.add_argument("--print", action="store_true", help="Print the written config")
    args = parser.parse_args()

    cfg_path = write_snapshot(args.dest, model=args.model)
    print(f"Wrote snapshot config: {cfg_path}")
    if args.print:
        print(cfg_path.read_text())


if __name__ == "__main__":
    _cli()

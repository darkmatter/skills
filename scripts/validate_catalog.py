#!/usr/bin/env python3
"""Compare the local skill inventory in docs/catalog.md with skills/.

The catalog is the authored human index; `skills/` is the source of truth.
Only the `## Local skills` section participates in this check:

  - every top-level directory in skills/ must have exactly one table row
  - every row's first cell must be a backticked skill name
  - a row naming a directory that does not exist is stale
  - a duplicate row for the same skill is an error

`## Externally installed skills` (and any other section) is ignored because
those skills are not owned by this repository.

Usage:
  scripts/validate_catalog.py <repo-root>

Exit status is 0 only when the section exists and the inventories match.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LOCAL_HEADING = re.compile(r"^##\s+Local skills\s*$")
ANY_HEADING = re.compile(r"^##\s+")
SEPARATOR = re.compile(r":?-{3,}:?")
HEADER = re.compile(r"\*{0,2}skill\*{0,2}", re.IGNORECASE)
BACKTICKED = re.compile(r"`([^`]+)`")


def local_skill_dirs(root: Path) -> list[str]:
    skills = root / "skills"
    if not skills.is_dir():
        return []
    return sorted(
        entry.name
        for entry in skills.iterdir()
        if entry.is_dir() and not entry.name.startswith(".")
    )


def catalog_rows(catalog: Path) -> tuple[list[tuple[str, int]], list[str]]:
    """Return (name, line) rows from `## Local skills` plus parse errors."""
    errors: list[str] = []
    rows: list[tuple[str, int]] = []
    in_section = False
    found_section = False

    for lineno, line in enumerate(catalog.read_text(encoding="utf-8").splitlines(), 1):
        if not in_section:
            if LOCAL_HEADING.match(line):
                in_section = True
                found_section = True
            continue
        if ANY_HEADING.match(line):
            break
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue

        cells = stripped.strip("|").split("|")
        first = cells[0].strip()
        if HEADER.fullmatch(first) or SEPARATOR.fullmatch(first):
            continue

        match = BACKTICKED.fullmatch(first)
        if match is None:
            errors.append(
                f"docs/catalog.md:{lineno}: first cell must be a backticked skill "
                f"name (got {first!r})"
            )
            continue
        rows.append((match.group(1), lineno))

    if not found_section:
        errors.append(
            "docs/catalog.md: missing '## Local skills' section "
            "(the local inventory table lives there)"
        )
    return rows, errors


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {argv[0]} <repo-root>", file=sys.stderr)
        return 2

    root = Path(argv[1]).resolve()
    catalog = root / "docs" / "catalog.md"
    if not catalog.is_file():
        print(f"FAIL catalog: {catalog} does not exist")
        return 1

    dirs = local_skill_dirs(root)
    rows, errors = catalog_rows(catalog)

    seen: dict[str, list[int]] = {}
    for name, lineno in rows:
        seen.setdefault(name, []).append(lineno)

    for name, linenos in seen.items():
        if len(linenos) > 1:
            listed = ", ".join(str(n) for n in linenos)
            errors.append(
                f"docs/catalog.md: duplicate row for skills/{name} (lines {listed})"
            )

    for name in seen:
        if name not in dirs:
            errors.append(
                f"docs/catalog.md: stale row for skills/{name} "
                "(no such top-level directory)"
            )

    for name in dirs:
        if name not in seen:
            errors.append(
                f"docs/catalog.md: missing row for skills/{name} "
                "(add it to '## Local skills')"
            )

    for error in errors:
        print(f"FAIL catalog: {error}")
    if errors:
        return 1

    print(f"ok   catalog ({len(dirs)} local skills)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

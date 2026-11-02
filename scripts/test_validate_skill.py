#!/usr/bin/env python3
"""Regression tests for scripts/validate-skill.sh.

Each test builds a throwaway repository with a copy of the CLI and catalog
helper, then runs the CLI exactly as CI does. Deterministic and offline:
lychee must be on PATH (the flake check provides it), and no network is used.

Run with:
  python3 scripts/test_validate_skill.py
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CLI = REPO_ROOT / "scripts" / "validate-skill.sh"
CATALOG_HELPER = REPO_ROOT / "scripts" / "validate_catalog.py"
CATALOG_HEADER = (
    "| Skill | Owns | Adjacent owner / boundary |\n"
    "| --- | --- | --- |\n"
)


def write_skill(root: Path, name: str, body: str = "") -> Path:
    directory = root / "skills" / name
    directory.mkdir(parents=True)
    (directory / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: fixture skill\n---\n\n{body}\n",
        encoding="utf-8",
    )
    return directory


def write_catalog(root: Path, rows: list[str]) -> None:
    docs = root / "docs"
    docs.mkdir()
    lines = ["# Catalog", "", "## Local skills", "", CATALOG_HEADER.rstrip()]
    for name in rows:
        lines.append(f"| `{name}` | fixture | none |")
    lines.extend(
        [
            "",
            "## Externally installed skills",
            "",
            "| Skill | Source |",
            "| --- | --- |",
            "| `external` | package |",
            "",
        ]
    )
    (docs / "catalog.md").write_text("\n".join(lines), encoding="utf-8")


class ValidatorFixture(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        scripts = self.root / "scripts"
        scripts.mkdir()
        shutil.copy2(CLI, scripts / CLI.name)
        shutil.copy2(CATALOG_HELPER, scripts / CATALOG_HELPER.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(self.root / "scripts" / CLI.name), *args],
            cwd=self.root,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )

    def output(self, result: subprocess.CompletedProcess[str]) -> str:
        return result.stdout + result.stderr

    # Positive cases -----------------------------------------------------

    def test_valid_links_reference_links_and_code_samples_pass(self) -> None:
        write_skill(
            self.root,
            "foo",
            body=(
                "See [notes](reference/notes.md), "
                "[sibling](../bar/SKILL.md#details), and "
                "[reference-style][notes-ref].\n\n"
                "[notes-ref]: reference/notes.md\n\n"
                "A pure fragment [top](#top) and an external "
                "[site](https://example.com/missing) are ignored.\n\n"
                "```md\n[dead fenced example](missing.md)\n```\n"
            ),
        )
        (self.root / "skills" / "foo" / "reference").mkdir()
        (self.root / "skills" / "foo" / "reference" / "notes.md").write_text(
            "# Notes\n", encoding="utf-8"
        )
        write_skill(self.root, "bar", body="[back](../foo/SKILL.md)\n")
        write_catalog(self.root, ["foo", "bar"])

        result = self.run_cli()
        self.assertEqual(result.returncode, 0, self.output(result))

    def test_explicit_directory_does_not_require_catalog(self) -> None:
        write_skill(self.root, "foo", body="[notes](reference/notes.md)\n")
        (self.root / "skills" / "foo" / "reference").mkdir()
        (self.root / "skills" / "foo" / "reference" / "notes.md").write_text(
            "# Notes\n", encoding="utf-8"
        )

        result = self.run_cli("skills/foo")
        self.assertEqual(result.returncode, 0, self.output(result))

    def test_vendored_submodule_markdown_is_not_link_checked(self) -> None:
        skill = write_skill(self.root, "foo", body="fixture\n")
        vendor = skill / "vendor"
        vendor.mkdir()
        (vendor / "upstream.md").write_text("[broken](missing.md)\n", encoding="utf-8")
        (self.root / ".gitmodules").write_text(
            '[submodule "skills/foo/vendor"]\n'
            "\tpath = skills/foo/vendor\n"
            "\turl = https://example.com/vendor.git\n",
            encoding="utf-8",
        )

        result = self.run_cli("skills/foo")
        self.assertEqual(result.returncode, 0, self.output(result))

    # Broken links -------------------------------------------------------

    def test_missing_sibling_link_fails(self) -> None:
        write_skill(self.root, "foo", body="[sibling](../bar/SKILL.md)\n")

        result = self.run_cli("skills/foo")
        self.assertNotEqual(result.returncode, 0, self.output(result))
        self.assertIn("bar/SKILL.md", self.output(result))

    def test_missing_own_reference_fails(self) -> None:
        write_skill(
            self.root,
            "foo",
            body="[notes](reference/missing.md)\n",
        )

        result = self.run_cli("skills/foo")
        self.assertNotEqual(result.returncode, 0, self.output(result))
        self.assertIn("reference/missing.md", self.output(result))

    # Catalog parity -----------------------------------------------------

    def test_catalog_missing_row_fails(self) -> None:
        write_skill(self.root, "foo")
        write_skill(self.root, "bar")
        write_catalog(self.root, ["foo"])

        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0, self.output(result))
        self.assertIn("bar", self.output(result))

    def test_catalog_stale_row_fails(self) -> None:
        write_skill(self.root, "foo")
        write_catalog(self.root, ["foo", "ghost"])

        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0, self.output(result))
        self.assertIn("ghost", self.output(result))

    def test_catalog_duplicate_row_fails(self) -> None:
        write_skill(self.root, "foo")
        write_catalog(self.root, ["foo", "foo"])

        result = self.run_cli()
        self.assertNotEqual(result.returncode, 0, self.output(result))
        self.assertIn("duplicate", self.output(result))
        self.assertIn("foo", self.output(result))

    # Frontmatter --------------------------------------------------------

    def test_frontmatter_name_mismatch_fails(self) -> None:
        directory = self.root / "skills" / "foo"
        directory.mkdir(parents=True)
        (directory / "SKILL.md").write_text(
            "---\nname: bar\ndescription: fixture skill\n---\n",
            encoding="utf-8",
        )

        result = self.run_cli("skills/foo")
        self.assertNotEqual(result.returncode, 0, self.output(result))
        self.assertIn("bar", self.output(result))


if __name__ == "__main__":
    unittest.main()

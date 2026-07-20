from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest import mock

import generate_changelog


class ChangelogGeneratorTests(unittest.TestCase):
    def fixture(self, version: str = "1.10.0") -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / "wago").mkdir()
        (root / "WeeklyAltTracker.toc").write_text(
            f"## Interface: 120007\n## Version: {version}\n",
            encoding="utf-8",
        )
        return root

    @staticmethod
    def note(root: Path, version: str, body: str) -> None:
        (root / "wago" / f"CHANGELOG-{version}.md").write_text(
            f"# WeeklyAltTracker {version}\n\n{body}\n",
            encoding="utf-8",
        )

    def test_semantic_sort_and_heading_shift_are_deterministic(self) -> None:
        root = self.fixture()
        self.note(root, "1.2.0", "## Alt\n\n- früher")
        self.note(root, "1.10.0", "## Neu\n\n### Detail\n\n- aktuell")
        inventory = ("1.10.0", "1.2.0")

        rendered, versions = generate_changelog.render(root, inventory)

        self.assertEqual(versions, ["1.10.0", "1.2.0"])
        self.assertLess(rendered.index("## 1.10.0"), rendered.index("## 1.2.0"))
        self.assertIn("### Neu", rendered)
        self.assertIn("#### Detail", rendered)
        self.assertEqual(rendered, generate_changelog.render(root, inventory)[0])

    def test_semantically_duplicate_leading_zero_alias_fails(self) -> None:
        root = self.fixture("1.0.0")
        self.note(root, "1.0.0", "## Kanonisch")
        self.note(root, "01.0.0", "## Alias")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "doppelte Release-Version"):
            generate_changelog.render(root, ("1.0.0",))

    def test_expected_inventory_rejects_noncanonical_semver(self) -> None:
        root = self.fixture("1.0.0")
        self.note(root, "1.0.0", "## Kanonisch")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "nicht kanonisch"):
            generate_changelog.render(root, ("01.0.0",))

    def test_expected_inventory_rejects_duplicate_versions(self) -> None:
        root = self.fixture("1.0.0")
        self.note(root, "1.0.0", "## Kanonisch")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "doppelte Version"):
            generate_changelog.render(root, ("1.0.0", "1.0.0"))

    def test_expected_inventory_must_be_strictly_semver_descending(self) -> None:
        root = self.fixture("1.2.0")
        self.note(root, "1.2.0", "## Aktuell")
        self.note(root, "1.10.0", "## Neuer")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "streng semantisch absteigend"):
            generate_changelog.render(root, ("1.2.0", "1.10.0"))

    def test_headings_shift_only_outside_fences_and_h6_does_not_overflow(self) -> None:
        root = self.fixture("1.0.0")
        self.note(
            root,
            "1.0.0",
            "# Eins\n## Zwei\n##### Fünf\n###### Sechs\n\n"
            "```markdown\n# Code H1\n###### Code H6\n```\n\n"
            "~~~\n## Tilde-Code\n~~~",
        )

        rendered, _ = generate_changelog.render(root, ("1.0.0",))

        self.assertIn("## Eins\n### Zwei\n###### Fünf\n###### Sechs", rendered)
        self.assertIn("```markdown\n# Code H1\n###### Code H6\n```", rendered)
        self.assertIn("~~~\n## Tilde-Code\n~~~", rendered)
        self.assertNotIn("####### Sechs", rendered)

    def test_indented_atx_headings_shift_outside_fences_but_not_inside(self) -> None:
        root = self.fixture("1.0.0")
        self.note(
            root,
            "1.0.0",
            " # Ein Leerzeichen\n  ## Zwei Leerzeichen\n   ### Drei Leerzeichen\n\n"
            "```markdown\n # Code eins\n  ## Code zwei\n   ### Code drei\n```",
        )

        rendered, _ = generate_changelog.render(root, ("1.0.0",))

        self.assertIn(
            " ## Ein Leerzeichen\n  ### Zwei Leerzeichen\n   #### Drei Leerzeichen",
            rendered,
        )
        self.assertIn(
            "```markdown\n # Code eins\n  ## Code zwei\n   ### Code drei\n```",
            rendered,
        )

    def test_missing_historical_note_from_immutable_inventory_fails(self) -> None:
        root = self.fixture()
        self.note(root, "1.10.0", "## Neu")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "Historische Release-Notiz fehlt"):
            generate_changelog.render(root, ("1.10.0", "1.2.0"))

    def test_missing_note_for_current_toc_version_fails(self) -> None:
        root = self.fixture("1.11.0")
        self.note(root, "1.10.0", "## Änderungen")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "TOC-Version"):
            generate_changelog.render(root, ("1.10.0",))

    def test_filename_and_title_must_match(self) -> None:
        root = self.fixture()
        (root / "wago" / "CHANGELOG-1.10.0.md").write_text(
            "# WeeklyAltTracker 1.9.0\n\n## Falsch\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "beginnt nicht"):
            generate_changelog.render(root, ("1.10.0",))

    def test_atomic_write_uses_output_directory_and_cleans_temp_on_failure(self) -> None:
        root = self.fixture("1.0.0")
        output = root / "CHANGELOG.md"

        with mock.patch.object(generate_changelog.os, "replace", side_effect=OSError("gesperrt")) as replace:
            with self.assertRaisesRegex(generate_changelog.ChangelogError, "kann nicht geschrieben werden"):
                generate_changelog.write_atomic(output, "Inhalt\n")

        temporary, destination = replace.call_args.args
        self.assertEqual(Path(temporary).parent, output.parent)
        self.assertEqual(Path(destination), output)
        self.assertEqual(list(root.glob(f".{output.name}.*.tmp")), [])
        self.assertFalse(output.exists())

    def test_check_cli_reports_unicode_read_error_without_traceback(self) -> None:
        root = self.fixture("1.0.0")
        output = root / "CHANGELOG.md"
        output.write_bytes(b"\xff")
        stderr = io.StringIO()

        with (
            mock.patch.object(generate_changelog, "OUTPUT", output),
            mock.patch.object(generate_changelog, "render", return_value=("erwartet\n", ["1.0.0"])),
            mock.patch("sys.argv", ["generate_changelog.py", "--check"]),
            redirect_stderr(stderr),
        ):
            result = generate_changelog.main()

        self.assertEqual(result, 1)
        self.assertIn("CHANGELOG FEHLER: CHANGELOG.md kann nicht gelesen werden", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())

    def test_write_cli_reports_os_error_without_temp_file_or_traceback(self) -> None:
        root = self.fixture("1.0.0")
        output = root / "CHANGELOG.md"
        stderr = io.StringIO()

        with (
            mock.patch.object(generate_changelog, "OUTPUT", output),
            mock.patch.object(generate_changelog, "render", return_value=("erwartet\n", ["1.0.0"])),
            mock.patch.object(generate_changelog.os, "replace", side_effect=OSError("gesperrt")),
            mock.patch("sys.argv", ["generate_changelog.py"]),
            redirect_stderr(stderr),
        ):
            result = generate_changelog.main()

        self.assertEqual(result, 1)
        self.assertIn("CHANGELOG FEHLER: CHANGELOG.md kann nicht geschrieben werden", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())
        self.assertEqual(list(root.glob(f".{output.name}.*.tmp")), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)

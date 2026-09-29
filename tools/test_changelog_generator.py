from __future__ import annotations

import io
import re
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

import generate_changelog


class ChangelogGeneratorTests(unittest.TestCase):
    """Generator-Tests gegen ein temporaeres Repository-Abbild.

    Die kanonische Quelle sind die zweisprachigen Paare
    changelog/CHANGELOG-<version>-en.md und -de.md. Die Wago-Originale
    bleiben archivierte Quelle und werden vom Generator nicht gelesen.
    """

    def fixture(self, version: str = "1.10.0") -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / "changelog").mkdir()
        (root / "wago").mkdir()
        (root / "WeeklyAltTracker.toc").write_text(
            f"## Interface: 120007\n## Version: {version}\n",
            encoding="utf-8",
        )
        return root

    @staticmethod
    def note(root: Path, version: str, body: str, language: str) -> None:
        (root / "changelog" / f"CHANGELOG-{version}-{language}.md").write_text(
            f"# WeeklyAltTracker {version}\n\n{body}\n",
            encoding="utf-8",
        )

    def pair(self, root: Path, version: str, de: str, en: str) -> None:
        self.note(root, version, de, "de")
        self.note(root, version, en, "en")

    # --- RED: die beiden Ausloeser dieser Umstellung ---------------------

    def test_latest_release_renders_english_body_before_german_body(self) -> None:
        root = self.fixture("1.10.0")
        self.pair(root, "1.10.0", "## Neu\n\n- deutscher Eintrag", "## New\n\n- english entry")

        rendered, versions = generate_changelog.render(root, ("1.10.0",))

        self.assertEqual(versions, ["1.10.0"])
        self.assertIn("- english entry", rendered)
        self.assertIn("- deutscher Eintrag", rendered)
        self.assertLess(rendered.index("- english entry"), rendered.index("- deutscher Eintrag"))
        self.assertEqual(rendered.count("## 1.10.0\n"), 1)

    def test_missing_historical_english_note_fails_closed(self) -> None:
        root = self.fixture("1.10.0")
        self.pair(root, "1.10.0", "## Neu\n\n- aktuell", "## New\n\n- current")
        self.note(root, "1.2.0", "## Alt\n\n- frueher", "de")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, r"CHANGELOG-1\.2\.0-en\.md"):
            generate_changelog.render(root, ("1.10.0", "1.2.0"))

    # --- Bestehende Bedeutungen, auf das zweisprachige Layout uebertragen --

    def test_semantic_sort_and_heading_shift_are_deterministic(self) -> None:
        root = self.fixture()
        self.pair(root, "1.2.0", "## Alt\n\n- früher", "## Old\n\n- earlier")
        self.pair(root, "1.10.0", "## Neu\n\n### Detail\n\n- aktuell", "## New\n\n### Detail\n\n- current")
        inventory = ("1.10.0", "1.2.0")

        rendered, versions = generate_changelog.render(root, inventory)

        self.assertEqual(versions, ["1.10.0", "1.2.0"])
        self.assertLess(rendered.index("## 1.10.0"), rendered.index("## 1.2.0"))
        self.assertIn("#### Neu", rendered)
        self.assertIn("##### Detail", rendered)
        self.assertIn("#### New", rendered)
        self.assertEqual(rendered, generate_changelog.render(root, inventory)[0])

    def test_each_version_appears_once_with_english_then_german_section(self) -> None:
        root = self.fixture()
        self.pair(root, "1.2.0", "## Alt\n\n- früher", "## Old\n\n- earlier")
        self.pair(root, "1.10.0", "## Neu\n\n- aktuell", "## New\n\n- current")

        rendered, _ = generate_changelog.render(root, ("1.10.0", "1.2.0"))

        for version in ("1.10.0", "1.2.0"):
            self.assertEqual(rendered.count(f"\n## {version}\n"), 1)
        block = rendered[rendered.index("## 1.10.0"):rendered.index("## 1.2.0")]
        self.assertEqual(block.count("### English"), 1)
        self.assertEqual(block.count("### Deutsch"), 1)
        self.assertLess(block.index("### English"), block.index("### Deutsch"))
        self.assertLess(block.index("- current"), block.index("- aktuell"))

    def test_semantically_duplicate_leading_zero_alias_fails(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Kanonisch", "## Canonical")
        self.pair(root, "01.0.0", "## Alias", "## Alias en")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "nicht semantisch versioniert"):
            generate_changelog.render(root, ("1.0.0",))

    def test_expected_inventory_rejects_noncanonical_semver(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Kanonisch", "## Canonical")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "nicht kanonisch"):
            generate_changelog.render(root, ("01.0.0",))

    def test_expected_inventory_rejects_duplicate_versions(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Kanonisch", "## Canonical")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "doppelte Version"):
            generate_changelog.render(root, ("1.0.0", "1.0.0"))

    def test_expected_inventory_must_be_strictly_semver_descending(self) -> None:
        root = self.fixture("1.2.0")
        self.pair(root, "1.2.0", "## Aktuell", "## Current")
        self.pair(root, "1.10.0", "## Neuer", "## Newer")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "streng semantisch absteigend"):
            generate_changelog.render(root, ("1.2.0", "1.10.0"))

    def test_headings_shift_only_outside_fences_and_h6_does_not_overflow(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(
            root,
            "1.0.0",
            "# Eins\n## Zwei\n#### Vier\n###### Sechs\n\n"
            "```markdown\n# Code H1\n###### Code H6\n```\n\n"
            "~~~\n## Tilde-Code\n~~~",
            "# One\n## Two\n#### Four\n###### Six\n\n"
            "```markdown\n# Code H1\n###### Code H6\n```\n\n"
            "~~~\n## Tilde code\n~~~",
        )

        rendered, _ = generate_changelog.render(root, ("1.0.0",))

        self.assertIn("### Eins\n#### Zwei\n###### Vier\n###### Sechs", rendered)
        self.assertIn("### One\n#### Two\n###### Four\n###### Six", rendered)
        self.assertIn("```markdown\n# Code H1\n###### Code H6\n```", rendered)
        self.assertIn("~~~\n## Tilde-Code\n~~~", rendered)
        self.assertNotIn("####### ", rendered)

    def test_indented_atx_headings_shift_outside_fences_but_not_inside(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(
            root,
            "1.0.0",
            " # Ein Leerzeichen\n  ## Zwei Leerzeichen\n   ### Drei Leerzeichen\n\n"
            "```markdown\n # Code eins\n  ## Code zwei\n   ### Code drei\n```",
            " # One space\n  ## Two spaces\n   ### Three spaces\n\n"
            "```markdown\n # Code one\n  ## Code two\n   ### Code three\n```",
        )

        rendered, _ = generate_changelog.render(root, ("1.0.0",))

        self.assertIn(
            " ### Ein Leerzeichen\n  #### Zwei Leerzeichen\n   ##### Drei Leerzeichen",
            rendered,
        )
        self.assertIn(
            "```markdown\n # Code eins\n  ## Code zwei\n   ### Code drei\n```",
            rendered,
        )

    def test_unclosed_fence_does_not_leak_into_next_section(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Offen\n\n```\ncode ohne Ende", "## Open\n\n- fine")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "nicht geschlossen"):
            generate_changelog.render(root, ("1.0.0",))

    def test_missing_historical_pair_from_immutable_inventory_fails(self) -> None:
        root = self.fixture()
        self.pair(root, "1.10.0", "## Neu", "## New")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "Release-Notiz fehlt"):
            generate_changelog.render(root, ("1.10.0", "1.2.0"))

    def test_missing_german_note_fails_closed(self) -> None:
        root = self.fixture("1.10.0")
        self.note(root, "1.10.0", "## New\n\n- current", "en")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, r"CHANGELOG-1\.10\.0-de\.md"):
            generate_changelog.render(root, ("1.10.0",))

    def test_missing_note_for_current_toc_version_fails(self) -> None:
        root = self.fixture("1.11.0")
        self.pair(root, "1.10.0", "## Änderungen", "## Changes")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "TOC-Version"):
            generate_changelog.render(root, ("1.10.0",))

    def test_uninventoried_note_fails(self) -> None:
        root = self.fixture("1.10.0")
        self.pair(root, "1.10.0", "## Neu", "## New")
        self.pair(root, "1.9.0", "## Extra", "## Extra en")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "nicht inventarisiert"):
            generate_changelog.render(root, ("1.10.0",))

    def test_malformed_filename_fails(self) -> None:
        root = self.fixture("1.10.0")
        self.pair(root, "1.10.0", "## Neu", "## New")
        (root / "changelog" / "CHANGELOG-1.10.0-fr.md").write_text("# x\n", encoding="utf-8")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "CHANGELOG-1.10.0-fr.md"):
            generate_changelog.render(root, ("1.10.0",))

    def test_filename_and_title_must_match(self) -> None:
        root = self.fixture()
        self.note(root, "1.10.0", "## Richtig", "de")
        (root / "changelog" / "CHANGELOG-1.10.0-en.md").write_text(
            "# WeeklyAltTracker 1.9.0\n\n## Wrong\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "beginnt nicht"):
            generate_changelog.render(root, ("1.10.0",))

    def test_empty_body_fails(self) -> None:
        root = self.fixture("1.0.0")
        self.note(root, "1.0.0", "## Inhalt\n\n- etwas", "de")
        (root / "changelog" / "CHANGELOG-1.0.0-en.md").write_text(
            "# WeeklyAltTracker 1.0.0\n\n\n", encoding="utf-8"
        )

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "keinen Inhalt"):
            generate_changelog.render(root, ("1.0.0",))

    def test_heading_only_body_fails(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Inhalt\n\n- etwas", "## Added\n\n### Changed")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "keinen Inhalt"):
            generate_changelog.render(root, ("1.0.0",))

    def test_placeholder_only_body_fails(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Inhalt\n\n- etwas", "## Added\n\n- TODO\n- tbd\n\n...")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "Platzhalter"):
            generate_changelog.render(root, ("1.0.0",))

    def test_formatted_placeholder_only_body_fails(self) -> None:
        for line in ("- **TODO**", "- n.a.", "1. `TBD`", "* _WIP_", "+ **`N/A`**", "- ...", "- __k.a.__"):
            with self.subTest(line=line):
                with self.assertRaisesRegex(generate_changelog.ChangelogError, "Platzhalter"):
                    generate_changelog.validate_body([line], Path("note.md"))

    def test_placeholder_word_in_real_sentence_is_content(self) -> None:
        generate_changelog.validate_body(["- **TODO** handling now rejects empty notes."], Path("note.md"))

    def test_identical_bodies_in_both_languages_fail(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Neu\n\n- gleich", "## Neu\n\n- gleich  ")

        with self.assertRaisesRegex(generate_changelog.ChangelogError, "identisch"):
            generate_changelog.render(root, ("1.0.0",))

    def test_generator_does_not_read_wago_archive(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Neu\n\n- aus changelog", "## New\n\n- from changelog")
        (root / "wago" / "CHANGELOG-1.0.0.md").write_text(
            "# WeeklyAltTracker 1.0.0\n\n- nur im Wago-Archiv\n", encoding="utf-8"
        )
        (root / "wago" / "CHANGELOG-9.9.9.md").write_text("# kaputt\n", encoding="utf-8")

        rendered, _ = generate_changelog.render(root, ("1.0.0",))

        self.assertNotIn("nur im Wago-Archiv", rendered)
        self.assertIn("- aus changelog", rendered)

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

    def test_write_then_check_is_idempotent(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Neu\n\n- aktuell", "## New\n\n- current")
        output = root / "CHANGELOG.md"
        stdout = io.StringIO()

        with (
            mock.patch.object(generate_changelog, "ROOT", root),
            mock.patch.object(generate_changelog, "OUTPUT", output),
            mock.patch.object(generate_changelog, "RELEASE_VERSIONS", ("1.0.0",)),
            redirect_stdout(stdout),
        ):
            with mock.patch("sys.argv", ["generate_changelog.py"]):
                self.assertEqual(generate_changelog.main(), 0)
            first = output.read_bytes()
            with mock.patch("sys.argv", ["generate_changelog.py", "--check"]):
                self.assertEqual(generate_changelog.main(), 0)
            with mock.patch("sys.argv", ["generate_changelog.py"]):
                self.assertEqual(generate_changelog.main(), 0)

        self.assertEqual(output.read_bytes(), first)
        self.assertNotIn(b"\r\n", first)
        self.assertIn("CHANGELOG OK: 1 Versionen", stdout.getvalue())

    def test_check_cli_fails_when_output_is_stale(self) -> None:
        root = self.fixture("1.0.0")
        self.pair(root, "1.0.0", "## Neu\n\n- aktuell", "## New\n\n- current")
        output = root / "CHANGELOG.md"
        output.write_text("veraltet\n", encoding="utf-8")
        stderr = io.StringIO()

        with (
            mock.patch.object(generate_changelog, "ROOT", root),
            mock.patch.object(generate_changelog, "OUTPUT", output),
            mock.patch.object(generate_changelog, "RELEASE_VERSIONS", ("1.0.0",)),
            mock.patch("sys.argv", ["generate_changelog.py", "--check"]),
            redirect_stderr(stderr),
        ):
            result = generate_changelog.main()

        self.assertEqual(result, 1)
        self.assertIn("nicht aktuell", stderr.getvalue())
        self.assertEqual(output.read_text(encoding="utf-8"), "veraltet\n")

    def test_check_cli_rejects_crlf_without_rewriting(self) -> None:
        root = self.fixture("1.0.0")
        output = root / "CHANGELOG.md"
        output.write_bytes(b"expected\r\n")
        stderr = io.StringIO()
        with (
            mock.patch.object(generate_changelog, "OUTPUT", output),
            mock.patch.object(generate_changelog, "render", return_value=("expected\n", ["1.0.0"])),
            mock.patch("sys.argv", ["generate_changelog.py", "--check"]),
            redirect_stdout(io.StringIO()), redirect_stderr(stderr),
        ):
            self.assertEqual(generate_changelog.main(), 1)
        self.assertIn("nicht aktuell", stderr.getvalue())
        self.assertEqual(output.read_bytes(), b"expected\r\n")

    def test_cli_reports_directory_io_error_without_traceback(self) -> None:
        stderr = io.StringIO()
        with (
            mock.patch.object(generate_changelog, "render", side_effect=OSError("directory unreadable")),
            mock.patch("sys.argv", ["generate_changelog.py", "--check"]),
            redirect_stderr(stderr),
        ):
            self.assertEqual(generate_changelog.main(), 1)
        self.assertIn("CHANGELOG FEHLER:", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())

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


class CheckGateTests(unittest.TestCase):
    """Das Gate in tools/check.py gegen ein temporaeres Repository-Abbild."""

    def setUp(self) -> None:
        import check  # noqa: PLC0415 - erst hier, damit Generator-Tests ohne check.py laufen

        self.check = check
        self.addCleanup(check.ERRORS.clear)
        check.ERRORS.clear()
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "changelog").mkdir()
        (self.root / "wago").mkdir()

    def toc(self, version: str) -> None:
        (self.root / "WeeklyAltTracker.toc").write_text(
            f"## Interface: 120007\n## Version: {version}\n", encoding="utf-8"
        )

    def pair(self, version: str, de: str, en: str) -> None:
        for language, body in (("de", de), ("en", en)):
            (self.root / "changelog" / f"CHANGELOG-{version}-{language}.md").write_text(
                f"# WeeklyAltTracker {version}\n\n{body}\n", encoding="utf-8"
            )

    def wago(self, version: str) -> None:
        (self.root / "wago" / f"CHANGELOG-{version}.md").write_text(
            f"# WeeklyAltTracker {version}\n\n- Archiv\n", encoding="utf-8"
        )

    def render_output(self, inventory: tuple[str, ...]) -> None:
        content, _ = generate_changelog.render(self.root, inventory)
        (self.root / "CHANGELOG.md").write_text(content, encoding="utf-8", newline="\n")

    def test_future_pair_without_wago_note_passes_full_gate(self) -> None:
        # Historische Version mit Archiv, neue Version nur als DE/EN-Paar.
        self.toc("2027.1.1")
        self.pair("2026.9.29", "## Alt\n\n- damals", "## Old\n\n- back then")
        self.wago("2026.9.29")
        self.pair("2027.1.1", "## Neu\n\n- jetzt", "## New\n\n- now")
        inventory = ("2027.1.1", "2026.9.29")
        self.render_output(inventory)

        with mock.patch.object(self.check, "ROOT", self.root):
            self.check.check_bilingual_changelog(self.root, inventory)

        self.assertEqual(self.check.ERRORS, [])

    def test_missing_historical_canonical_english_fails_gate(self) -> None:
        self.toc("2027.1.1")
        self.pair("2026.9.29", "## Alt\n\n- damals", "## Old\n\n- back then")
        self.wago("2026.9.29")
        self.pair("2027.1.1", "## Neu\n\n- jetzt", "## New\n\n- now")
        inventory = ("2027.1.1", "2026.9.29")
        self.render_output(inventory)
        (self.root / "changelog" / "CHANGELOG-2026.9.29-en.md").unlink()

        self.check.check_bilingual_changelog(self.root, inventory)

        self.assertTrue(
            any("CHANGELOG-2026.9.29-en.md" in item for item in self.check.ERRORS),
            self.check.ERRORS,
        )

    def test_missing_wago_archive_for_frozen_historical_version_fails_gate(self) -> None:
        self.toc("2026.9.29")
        self.pair("2026.9.29", "## Alt\n\n- damals", "## Old\n\n- back then")
        inventory = ("2026.9.29",)
        self.render_output(inventory)

        self.check.check_bilingual_changelog(self.root, inventory)

        self.assertTrue(
            any("wago/CHANGELOG-2026.9.29.md" in item for item in self.check.ERRORS),
            self.check.ERRORS,
        )

    def test_gate_rejects_crlf_and_invalid_utf8_without_rewriting(self) -> None:
        self.toc("2027.1.1")
        self.pair("2027.1.1", "- deutsch", "- english")
        expected, _ = generate_changelog.render(self.root, ("2027.1.1",))
        for payload in (expected.replace("\n", "\r\n").encode("utf-8"), b"\xff"):
            with self.subTest(payload=payload[:20]):
                self.check.ERRORS.clear()
                output = self.root / "CHANGELOG.md"
                output.write_bytes(payload)
                self.check.check_bilingual_changelog(self.root, ("2027.1.1",))
                self.assertTrue(self.check.ERRORS)
                self.assertEqual(output.read_bytes(), payload)

    def test_gate_reports_output_io_error(self) -> None:
        self.toc("2027.1.1")
        self.pair("2027.1.1", "- deutsch", "- english")
        self.render_output(("2027.1.1",))
        read_bytes = Path.read_bytes

        def read_or_fail(path: Path) -> bytes:
            if path == self.root / "CHANGELOG.md":
                raise OSError("unreadable")
            return read_bytes(path)

        with mock.patch.object(Path, "read_bytes", read_or_fail):
            self.check.check_bilingual_changelog(self.root, ("2027.1.1",))
        self.assertTrue(any("CHANGELOG.md kann nicht gelesen werden" in item for item in self.check.ERRORS))

    def test_frozen_archive_inventory_is_a_subset_of_release_inventory(self) -> None:
        self.assertIn("2026.9.29", self.check.WAGO_ARCHIVE_VERSIONS)
        self.assertEqual(self.check.WAGO_ARCHIVE_VERSIONS[0], "2026.9.29")
        self.assertTrue(set(self.check.WAGO_ARCHIVE_VERSIONS) <= set(self.check.IMMUTABLE_RELEASE_VERSIONS))
        self.assertEqual(self.check.IMMUTABLE_RELEASE_VERSIONS, generate_changelog.RELEASE_VERSIONS)

    def test_release_workflow_runs_gates_before_packager(self) -> None:
        workflow = Path(__file__).resolve().parents[1] / ".github" / "workflows" / "release.yml"
        text = workflow.read_text(encoding="utf-8")
        steps: list[tuple[str, str]] = []
        for block in re.split(r"(?m)^      - name: ", text)[1:]:
            name, _, rest = block.partition("\n")
            steps.append((name.strip(), rest))
        names = [name for name, _ in steps]

        changelog = names.index("Bilingual changelog gate")
        quality = names.index("Quality gate")
        packager = names.index("Package and release")
        self.assertLess(changelog, packager)
        self.assertLess(quality, packager)
        self.assertLess(names.index("Set up Python"), changelog)
        self.assertLess(names.index("Set up Node"), quality)
        self.assertIn("run: python tools/generate_changelog.py --check", steps[changelog][1])
        self.assertIn("run: python tools/check.py", steps[quality][1])
        for index in (changelog, quality):
            body = steps[index][1]
            self.assertNotRegex(body, r"(?m)^\s*if:")
            self.assertNotRegex(body, r"(?m)^\s*continue-on-error:\s*true")
            self.assertNotRegex(body, r"(?m)^\s*#\s*run:")
        self.assertIn("uses: BigWigsMods/packager@v2", steps[packager][1])


class HistoricalContentTests(unittest.TestCase):
    """Regression sentinels, not an automatic translation-quality verdict."""

    def test_german_canonical_preserves_full_wago_originals(self) -> None:
        import check

        root = Path(__file__).resolve().parents[1]
        for version in check.WAGO_ARCHIVE_VERSIONS:
            with self.subTest(version=version):
                archive = (root / "wago" / f"CHANGELOG-{version}.md").read_text(encoding="utf-8")
                # Only this known archive has an explicitly marked English
                # duplicate. Never strip arbitrary headings or sections.
                if version == "0.9.0":
                    marker = "\n---\n\n# English\n"
                    self.assertEqual(archive.count(marker), 1)
                    archive = archive.split(marker)[0]
                canonical = generate_changelog.note_path(root, version, "de").read_text(encoding="utf-8")
                self.assertEqual(canonical.strip(), archive.strip())

    def test_english_preserves_previously_omitted_historical_facts(self) -> None:
        root = Path(__file__).resolve().parents[1]
        sentinels = {
            "0.5.0": (r"refresh.*`/reload`.*restart.*preserve.*order", r"last position",
                      r"UISpecialFrames", r"initialization.*not.*duplicate"),
            "0.6.1": (r"cumulative.*history.*unchanged.*GitHub.*Wago",),
            "0.7.0": (r"unknown values.*neither.*zero.*nor.*fresh timestamp",
                      r"contribution rules.*Secret Values.*taint.*runtime costs.*Retail/PTR.*release checks"),
            "0.8.0": (r"Showdowns.*Cracked Keystone.*Nullaeus.*Ritual T6.*Hero-to-Myth.*no longer",
                      r"four new Nightmare hunts.*Coiled Isle"),
        }
        for version, patterns in sentinels.items():
            body = generate_changelog.note_path(root, version, "en").read_text(encoding="utf-8")
            for pattern in patterns:
                with self.subTest(version=version, fact=pattern):
                    self.assertRegex(body, re.compile(pattern, re.IGNORECASE))

    def test_canonical_sources_and_git_attributes_are_excluded_from_package(self) -> None:
        import check

        self.assertTrue({"changelog", "wago", "curseforge", ".gitattributes"} <= check.pkgmeta_ignores())
        attributes = (Path(__file__).resolve().parents[1] / ".gitattributes").read_text(encoding="utf-8")
        self.assertRegex(attributes, r"(?m)^/CHANGELOG\.md text eol=lf$")


if __name__ == "__main__":
    unittest.main(verbosity=2)

"""Erzeugt die kumulative zweisprachige CHANGELOG.md.

Kanonische Quelle sind die Paare changelog/CHANGELOG-<version>-en.md und
changelog/CHANGELOG-<version>-de.md - je Release genau eine englische und
eine deutsche Datei. Die Originale unter wago/ bleiben als Archiv erhalten,
werden hier aber nicht gelesen.

Der Generator arbeitet fail-closed: fehlt eine Sprache, ist eine Datei leer,
besteht sie nur aus Titel/Ueberschriften oder Platzhaltern, sind beide
Sprachfassungen identisch, passt Titel nicht zu Dateiname oder liegt eine nicht
inventarisierte oder unpassend benannte Datei im Ordner, bricht er ab und
schreibt nichts. Ob ein Text tatsaechlich Englisch bzw. Deutsch ist, wird
nicht geprueft - das bleibt menschliche Review.

Aufruf:
    python tools/generate_changelog.py          # CHANGELOG.md schreiben
    python tools/generate_changelog.py --check  # nur pruefen, Exitcode 1 bei Abweichung
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "WeeklyAltTracker.toc"
SOURCE_DIR = ROOT / "changelog"
OUTPUT = ROOT / "CHANGELOG.md"
LANGUAGES = ("en", "de")
LANGUAGE_HEADINGS = {"en": "English", "de": "Deutsch"}
# Calendar revisions are stable releases, not SemVer prereleases.
# Unsuffixed historical three-component versions remain valid (revision 1).
VERSION_PATTERN = r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-([2-9]|[1-9][0-9]+))?"
CANONICAL_VERSION = re.compile(VERSION_PATTERN)
NOTE_NAME = re.compile(rf"CHANGELOG-{VERSION_PATTERN}-(en|de)\.md")
ANY_NOTE_NAME = re.compile(r"^CHANGELOG-.*\.md$")
FENCE_OPEN = re.compile(r" {0,3}(`{3,}|~{3,}).*")
ATX_HEADING = re.compile(r"^( {0,3})(#{1,6})(?= |$)")
# Textzeilen, die keinen Inhalt tragen: nur Aufzaehlungszeichen, Ellipse,
# TODO/TBD/TBA/WIP/n.a. oder ein in spitzen Klammern gesetzter Platzhalter.
PLACEHOLDER_LINE = re.compile(
    r"^(?:[-*+]\s*|\d+[.)]\s*)?(?:todo|tbd|tba|wip|n[/.]?a\.?|k\.?a\.?|\.{3}|…|<[^>]*>)?[\s.:!?,-]*$",
    re.IGNORECASE,
)
RELEASE_VERSIONS = (
    "2026.10.4",
    "2026.10.3",
    "2026.10.2",
    "2026.10.1",
    "2026.9.29-2",
    "2026.9.29", "2026.9.23", "2026.9.22", "2026.9.21", "0.9.0", "0.8.0", "0.7.0", "0.6.1", "0.6.0", "0.5.0", "0.4.2", "0.4.1",
    "0.4.0", "0.3.1", "0.3.0", "0.2.6", "0.2.5", "0.2.4",
)
HEADER = (
    "# WeeklyAltTracker – Changelog / Änderungsverlauf\n\n"
    "This file contains the complete public release history. Every version is "
    "listed once, English first, followed by the German text. Older entries "
    "describe the state of the version named and are not rewritten "
    "retroactively.\n\n"
    "Diese Datei enthält die vollständige öffentliche Release-Historie. Jede "
    "Version steht genau einmal, zuerst Englisch, danach der deutsche Text. "
    "Frühere Einträge beschreiben den Stand der jeweils genannten Version und "
    "werden bei späteren Änderungen nicht rückwirkend umgeschrieben.\n\n"
)
# Versions-H2 + Sprach-H3, Notizinhalt beginnt deshalb bei H4.
HEADING_SHIFT = 2


class ChangelogError(ValueError):
    pass


def validate_expected_versions(expected_versions: tuple[str, ...]) -> None:
    keys: list[tuple[int, int, int, int]] = []
    for version in expected_versions:
        match = CANONICAL_VERSION.fullmatch(version)
        if not match:
            raise ChangelogError(f"inventarisierte Version ist nicht kanonisch: {version!r}")
        keys.append(tuple(int(part) if part is not None else 1 for part in match.groups()))
    if len(expected_versions) != len(set(expected_versions)):
        raise ChangelogError("doppelte Version im Release-Inventar")
    if any(previous <= current for previous, current in zip(keys, keys[1:])):
        raise ChangelogError("Release-Inventar ist nicht streng semantisch absteigend")


def read_utf8_bytes(path: Path) -> bytes:
    """Read valid UTF-8 without universal-newline translation."""
    try:
        data = path.read_bytes()
        data.decode("utf-8")
        return data
    except (OSError, UnicodeError) as exc:
        raise ChangelogError(f"{path.name} kann nicht gelesen werden: {exc}") from None


def read_utf8(path: Path) -> str:
    return read_utf8_bytes(path).decode("utf-8")


def write_atomic(path: Path, content: str) -> None:
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            newline="\n",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as handle:
            temporary = Path(handle.name)
            handle.write(content)
        os.replace(temporary, path)
        temporary = None
    except (OSError, UnicodeError) as exc:
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass
        raise ChangelogError(f"{path.name} kann nicht geschrieben werden: {exc}") from None


def current_version(root: Path = ROOT) -> str:
    toc = root / "WeeklyAltTracker.toc"
    if not toc.is_file():
        raise ChangelogError("WeeklyAltTracker.toc fehlt")
    for line in read_utf8(toc).splitlines():
        if line.startswith("## Version:"):
            version = line.split(":", 1)[1].strip()
            if CANONICAL_VERSION.fullmatch(version):
                return version
            raise ChangelogError(f"ungültige TOC-Version: {version!r}")
    raise ChangelogError("TOC enthält keinen ## Version:-Eintrag")


def note_path(root: Path, version: str, language: str) -> Path:
    return root / "changelog" / f"CHANGELOG-{version}-{language}.md"


def release_notes(
    root: Path = ROOT,
    expected_versions: tuple[str, ...] = RELEASE_VERSIONS,
) -> list[tuple[str, dict[str, Path]]]:
    """Liefert je inventarisierter Version das vollstaendige Sprachpaar.

    Reihenfolge = Inventar (neueste zuerst). Jede Abweichung zwischen Inventar
    und Dateibestand ist ein Fehler, nie ein stilles Auslassen.
    """
    validate_expected_versions(expected_versions)
    source_dir = root / "changelog"
    if not source_dir.is_dir():
        raise ChangelogError("changelog-Verzeichnis mit zweisprachigen Release-Notizen fehlt")
    found: dict[str, dict[str, Path]] = {}
    for path in sorted(source_dir.iterdir()):
        if not ANY_NOTE_NAME.fullmatch(path.name):
            continue
        match = NOTE_NAME.fullmatch(path.name)
        if not match:
            raise ChangelogError(
                f"nicht semantisch versionierte oder falsch benannte Release-Notiz: {path.name} "
                "(erwartet CHANGELOG-<major>.<minor>.<patch>[-<revision>]-en.md / -de.md)"
            )
        version = ".".join(match.groups()[:3])
        if match.group(4) is not None:
            version += "-" + match.group(4)
        if not CANONICAL_VERSION.fullmatch(version):
            raise ChangelogError(f"nicht semantisch versionierte Release-Notiz: {path.name}")
        found.setdefault(version, {})[match.group(5)] = path
    if not found:
        raise ChangelogError("keine zweisprachigen Release-Notizen unter changelog/ gefunden")
    missing: list[str] = []
    for version in expected_versions:
        for language in LANGUAGES:
            if language not in found.get(version, {}):
                missing.append(f"CHANGELOG-{version}-{language}.md")
    if missing:
        raise ChangelogError("Release-Notiz fehlt (unvollständiges Sprachpaar): " + ", ".join(missing))
    unexpected = sorted(version for version in found if version not in expected_versions)
    if unexpected:
        raise ChangelogError(
            "nicht inventarisierte Release-Notiz: "
            + ", ".join(f"CHANGELOG-{version}-*.md" for version in unexpected)
        )
    active = current_version(root)
    if expected_versions[0] != active:
        raise ChangelogError(
            f"neueste Release-Notiz ist {expected_versions[0]}, TOC-Version ist jedoch {active}"
        )
    return [(version, found[version]) for version in expected_versions]


def note_body(path: Path, version: str) -> list[str]:
    """Liest eine Notiz, prueft den Titel und liefert den Rumpf ohne Titel."""
    lines = read_utf8(path).strip().splitlines()
    expected_title = f"# WeeklyAltTracker {version}"
    if not lines or lines[0] != expected_title:
        raise ChangelogError(f"{path.name} beginnt nicht mit {expected_title!r}")
    body = lines[1:]
    while body and not body[0].strip():
        body.pop(0)
    while body and not body[-1].strip():
        body.pop()
    return body


def shift_headings(body: list[str], path: Path) -> list[str]:
    """Verschiebt ATX-Ueberschriften ausserhalb von Code-Zaeunen um HEADING_SHIFT.

    H6 bleibt H6 (CommonMark kennt keine siebte Stufe). Inhalt innerhalb von
    ```- und ~~~-Zaeunen wird byteweise uebernommen. Ein nicht geschlossener
    Zaun ist ein Fehler, sonst liefe er in die naechste Version hinein.
    """
    result: list[str] = []
    fence: tuple[str, int] | None = None
    for line in body:
        fence_match = FENCE_OPEN.fullmatch(line)
        if fence is None and fence_match:
            marker = fence_match.group(1)
            fence = (marker[0], len(marker))
            result.append(line)
            continue
        if fence is not None:
            result.append(line)
            indent = len(line) - len(line.lstrip(" "))
            marker = line.strip() if indent <= 3 else ""
            if marker and set(marker) == {fence[0]} and len(marker) >= fence[1]:
                fence = None
            continue
        heading = ATX_HEADING.match(line)
        if heading:
            indent, hashes = heading.group(1), heading.group(2)
            level = min(6, len(hashes) + HEADING_SHIFT)
            line = indent + "#" * level + line[len(indent) + len(hashes):]
        result.append(line)
    if fence is not None:
        raise ChangelogError(f"{path.name}: Code-Zaun ist nicht geschlossen")
    return result


def content_lines(body: list[str]) -> list[str]:
    """Textzeilen ausserhalb von Zaeunen, die keine Ueberschriften sind."""
    lines: list[str] = []
    fence: tuple[str, int] | None = None
    for line in body:
        fence_match = FENCE_OPEN.fullmatch(line)
        if fence is None and fence_match:
            marker = fence_match.group(1)
            fence = (marker[0], len(marker))
            continue
        if fence is not None:
            indent = len(line) - len(line.lstrip(" "))
            marker = line.strip() if indent <= 3 else ""
            if marker and set(marker) == {fence[0]} and len(marker) >= fence[1]:
                fence = None
            else:
                lines.append(line)
            continue
        if ATX_HEADING.match(line) or not line.strip():
            continue
        lines.append(line)
    return lines


def validate_body(body: list[str], path: Path) -> None:
    if not body:
        raise ChangelogError(f"{path.name} enthält keinen Inhalt (nur Titel)")
    text = content_lines(body)
    if not text:
        raise ChangelogError(f"{path.name} enthält keinen Inhalt (nur Titel und Überschriften)")
    # Markdown emphasis and inline-code delimiters do not make TODO content.
    # Only normalize for validation; rendered source remains untouched.
    if all(PLACEHOLDER_LINE.fullmatch(line.translate(str.maketrans("", "", "*_`")).strip()) for line in text):
        raise ChangelogError(f"{path.name} enthält nur Platzhalter")


def normalized(body: list[str]) -> str:
    return "\n".join(" ".join(line.split()) for line in body if line.strip())


def render(
    root: Path = ROOT,
    expected_versions: tuple[str, ...] = RELEASE_VERSIONS,
) -> tuple[str, list[str]]:
    sections: list[str] = []
    versions: list[str] = []
    for version, paths in release_notes(root, expected_versions):
        bodies: dict[str, list[str]] = {}
        for language in LANGUAGES:
            body = note_body(paths[language], version)
            validate_body(body, paths[language])
            bodies[language] = body
        if normalized(bodies["en"]) == normalized(bodies["de"]):
            raise ChangelogError(
                f"CHANGELOG-{version}-en.md und CHANGELOG-{version}-de.md sind inhaltlich identisch"
            )
        parts: list[str] = [f"## {version}"]
        for language in LANGUAGES:
            parts.append(f"### {LANGUAGE_HEADINGS[language]}")
            parts.append("\n".join(shift_headings(bodies[language], paths[language])))
        sections.append("\n\n".join(parts))
        versions.append(version)
    return HEADER + "\n\n---\n\n".join(sections) + "\n", versions


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Erzeugt die kumulative zweisprachige CHANGELOG.md aus "
            "changelog/CHANGELOG-<version>-en.md und -de.md."
        )
    )
    parser.add_argument(
        "--check", action="store_true",
        help="schreibt nichts und beendet sich ungleich null, wenn CHANGELOG.md abweicht",
    )
    args = parser.parse_args()
    try:
        expected, versions = render(ROOT, RELEASE_VERSIONS)
        if args.check:
            actual = read_utf8_bytes(OUTPUT) if OUTPUT.is_file() else None
            if actual != expected.encode("utf-8"):
                print(
                    "CHANGELOG FEHLER: CHANGELOG.md ist nicht aktuell; "
                    "python tools/generate_changelog.py ausführen",
                    file=sys.stderr,
                )
                return 1
        else:
            write_atomic(OUTPUT, expected)
    except (ChangelogError, OSError, UnicodeError) as exc:
        print(f"CHANGELOG FEHLER: {exc}", file=sys.stderr)
        return 1
    if args.check:
        print(f"CHANGELOG OK: {len(versions)} Versionen ({', '.join(versions)})")
    else:
        print(f"CHANGELOG erzeugt: {OUTPUT} ({len(versions)} Versionen)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

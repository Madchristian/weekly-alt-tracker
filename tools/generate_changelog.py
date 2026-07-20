from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "WeeklyAltTracker.toc"
SOURCE_DIR = ROOT / "wago"
OUTPUT = ROOT / "CHANGELOG.md"
NOTE_NAME = re.compile(r"^CHANGELOG-(\d+)\.(\d+)\.(\d+)\.md$")
CANONICAL_SEMVER = re.compile(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)")
RELEASE_VERSIONS = (
    "0.6.0", "0.5.0", "0.4.2", "0.4.1", "0.4.0", "0.3.1",
    "0.3.0", "0.2.6", "0.2.5", "0.2.4",
)
HEADER = (
    "# WeeklyAltTracker – vollständiger Änderungsverlauf\n\n"
    "Dieser Changelog enthält die vollständige öffentliche Release-Historie. "
    "Frühere Einträge beschreiben den Stand der jeweils genannten Version und "
    "werden bei späteren Änderungen nicht rückwirkend umgeschrieben.\n\n"
)


class ChangelogError(ValueError):
    pass


def validate_expected_versions(expected_versions: tuple[str, ...]) -> None:
    keys: list[tuple[int, int, int]] = []
    for version in expected_versions:
        match = CANONICAL_SEMVER.fullmatch(version)
        if not match:
            raise ChangelogError(f"inventarisierte Version ist nicht kanonisch: {version!r}")
        keys.append(tuple(int(part) for part in match.groups()))
    if len(expected_versions) != len(set(expected_versions)):
        raise ChangelogError("doppelte Version im Release-Inventar")
    if any(previous <= current for previous, current in zip(keys, keys[1:])):
        raise ChangelogError("Release-Inventar ist nicht streng semantisch absteigend")


def read_utf8(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise ChangelogError(f"{path.name} kann nicht gelesen werden: {exc}") from None


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
            if re.fullmatch(r"\d+\.\d+\.\d+", version):
                return version
            raise ChangelogError(f"ungültige TOC-Version: {version!r}")
    raise ChangelogError("TOC enthält keinen ## Version:-Eintrag")


def release_notes(
    root: Path = ROOT,
    expected_versions: tuple[str, ...] = RELEASE_VERSIONS,
) -> list[tuple[tuple[int, int, int], str, Path]]:
    validate_expected_versions(expected_versions)
    source_dir = root / "wago"
    if not source_dir.is_dir():
        raise ChangelogError("wago-Verzeichnis mit versionierten Release-Notizen fehlt")
    notes: list[tuple[tuple[int, int, int], str, Path]] = []
    for path in source_dir.glob("CHANGELOG-*.md"):
        match = NOTE_NAME.fullmatch(path.name)
        if not match:
            raise ChangelogError(f"nicht semantisch versionierte Release-Notiz: {path.name}")
        key = tuple(int(part) for part in match.groups())
        version = ".".join(match.groups())
        notes.append((key, version, path))
    if not notes:
        raise ChangelogError("keine versionierten Wago-Release-Notizen gefunden")
    notes.sort(key=lambda item: item[0], reverse=True)
    keys = [key for key, _, _ in notes]
    if len(keys) != len(set(keys)):
        raise ChangelogError("doppelte Release-Version in den Wago-Notizen")
    versions = [version for _, version, _ in notes]
    missing = [version for version in expected_versions if version not in versions]
    if missing:
        raise ChangelogError(
            "Historische Release-Notiz fehlt: "
            + ", ".join(f"CHANGELOG-{version}.md" for version in missing)
        )
    unexpected = [version for version in versions if version not in expected_versions]
    if unexpected:
        raise ChangelogError(
            "nicht inventarisierte Release-Notiz: "
            + ", ".join(f"CHANGELOG-{version}.md" for version in unexpected)
        )
    active = current_version(root)
    if expected_versions[0] != active:
        raise ChangelogError(
            f"neueste Release-Notiz ist {expected_versions[0]}, TOC-Version ist jedoch {active}"
        )
    notes_by_version = {version: (key, version, path) for key, version, path in notes}
    return [notes_by_version[version] for version in expected_versions]


def render(
    root: Path = ROOT,
    expected_versions: tuple[str, ...] = RELEASE_VERSIONS,
) -> tuple[str, list[str]]:
    sections: list[str] = []
    versions: list[str] = []
    for _, version, path in release_notes(root, expected_versions):
        lines = read_utf8(path).strip().splitlines()
        expected_title = f"# WeeklyAltTracker {version}"
        if not lines or lines[0] != expected_title:
            raise ChangelogError(f"{path.name} beginnt nicht mit {expected_title!r}")
        body: list[str] = [f"## {version}"]
        fence: tuple[str, int] | None = None
        for line in lines[1:]:
            fence_match = re.fullmatch(r" {0,3}(`{3,}|~{3,}).*", line)
            if fence is None and fence_match:
                marker = fence_match.group(1)
                fence = (marker[0], len(marker))
                body.append(line)
                continue
            if fence is not None:
                body.append(line)
                candidate = line.lstrip(" ") if len(line) - len(line.lstrip(" ")) <= 3 else ""
                marker = candidate.rstrip()
                if marker and set(marker) == {fence[0]} and len(marker) >= fence[1]:
                    fence = None
                continue
            heading = re.match(r"^( {0,3})(#{1,6})(?= |$)", line)
            if heading and len(heading.group(2)) < 6:
                indent = heading.group(1)
                line = indent + "#" + line[len(indent):]
            body.append(line)
        sections.append("\n".join(body).strip())
        versions.append(version)
    return HEADER + "\n\n---\n\n".join(sections) + "\n", versions


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Erzeugt den kumulativen öffentlichen Changelog aus wago/CHANGELOG-<version>.md."
    )
    parser.add_argument(
        "--check", action="store_true",
        help="schreibt nichts und beendet sich ungleich null, wenn CHANGELOG.md abweicht",
    )
    args = parser.parse_args()
    try:
        expected, versions = render()
        if args.check:
            actual = read_utf8(OUTPUT) if OUTPUT.is_file() else None
            if actual != expected:
                print(
                    "CHANGELOG FEHLER: CHANGELOG.md ist nicht aktuell; "
                    "python tools/generate_changelog.py ausführen",
                    file=sys.stderr,
                )
                return 1
        else:
            write_atomic(OUTPUT, expected)
    except ChangelogError as exc:
        print(f"CHANGELOG FEHLER: {exc}", file=sys.stderr)
        return 1
    if args.check:
        print(f"CHANGELOG OK: {len(versions)} Versionen ({', '.join(versions)})")
    else:
        print(f"CHANGELOG erzeugt: {OUTPUT} ({len(versions)} Versionen)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Prueft ein gebautes Addon-ZIP, bevor es von Hand zu CurseForge geht.

Gegenstueck zu tools/package_preview.py: waehrend dort gepackt wird, liest
dieses Skript ausschliesslich das tatsaechlich geschriebene Archiv wieder ein.
Das ist der Punkt - geprueft wird die Datei, die spaeter hochgeladen wird, nicht
eine Datenstruktur, aus der sie einmal entstanden ist.

Geprueft werden:
  * Integritaet des Archivs (CRC ueber alle Eintraege)
  * genau die 14 erwarteten Dateien unter genau einem Ordner WeeklyAltTracker/
  * keine zusaetzlichen, fehlenden oder verbotenen Eintraege
  * kein Pfadtraversal, keine absoluten Pfade, keine Verzeichniseintraege
  * bytegleicher Inhalt zum Arbeitsbaum
  * TOC-Kennwerte (Version, Interface, Wago-ID, CurseForge-ID, Lizenz)
  * keine Zuweisung von WAGO_API_TOKEN oder CF_API_KEY im Paketinhalt
  * SHA-256 und Groesse des Archivs

EXPECTED_VERSION gehoert zur Liste der Stellen, die vor jedem Tag von Hand
angeglichen werden (TOC, Core.lua, Anleitung, Guides, READMEs, Changelogs).

Aufruf:
    python tools/verify_package.py dist/WeeklyAltTracker-0.3.0.zip
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PACKAGE_FOLDER = "WeeklyAltTracker"
EXPECTED_VERSION = "0.3.0"

# Identisch zu EXPECTED_PACKAGE in tools/check.py - bewusst doppelt gefuehrt,
# damit dieses Skript das ZIP auch ohne check.py allein pruefen kann.
EXPECTED_FILES = {
    "Activities.lua",
    "Anleitung.html",
    "Core.lua",
    "Data.lua",
    "Guide.en.html",
    "LICENSE.txt",
    "Localization.lua",
    "Media/WeeklyAltTrackerIcon.tga",
    "README.en.md",
    "README.md",
    "Scanner.lua",
    "THIRD_PARTY_NOTICES.md",
    "UI.lua",
    "WeeklyAltTracker.toc",
}

EXPECTED_TOC_FIELDS = {
    "Version": "0.3.0",
    "Interface": "120007",
    "X-Wago-ID": "ZKxZJkNk",
    "X-Curse-Project-ID": "1616769",
    "X-License": "All Rights Reserved",
}

# Eine Zuweisung waere ein echter Leak; die blosse Erwaehnung des Namens in
# einer Doku ist erlaubt. Deshalb wird auf ":" oder "=" mit Wert geprueft.
SECRET_ASSIGNMENT = re.compile(
    r"(WAGO_API_TOKEN|CF_API_KEY)\s*[:=]\s*[^\s]", re.IGNORECASE
)

errors: list[str] = []


def error(message: str) -> None:
    errors.append(message)


def open_archive(path: Path) -> zipfile.ZipFile:
    if not path.is_file():
        print(f"FEHLER: ZIP nicht gefunden: {path}", file=sys.stderr)
        raise SystemExit(2)
    try:
        archive = zipfile.ZipFile(path)
    except zipfile.BadZipFile as exc:
        print(f"FEHLER: kein lesbares ZIP: {path} ({exc})", file=sys.stderr)
        raise SystemExit(2) from exc
    # testzip() meldet einen CRC-Fehler als Rueckgabewert, ein zerschossener
    # Deflate-Strom kommt dagegen als zlib.error aus der Bibliothek. Beides
    # bedeutet dasselbe und soll dieselbe klare Meldung ergeben.
    try:
        broken = archive.testzip()
    except Exception as exc:  # zlib.error, BadZipFile, EOFError
        print(f"FEHLER: ZIP nicht entpackbar: {path} ({exc})", file=sys.stderr)
        raise SystemExit(2) from exc
    if broken is not None:
        print(f"FEHLER: defekter Eintrag im ZIP: {broken}", file=sys.stderr)
        raise SystemExit(2)
    return archive


def check_names(names: list[str]) -> set[str]:
    """Prueft Pfadform und liefert die Namen relativ zum Paketordner."""
    relatives: set[str] = set()
    seen_names: set[str] = set()
    prefix = PACKAGE_FOLDER + "/"
    for name in names:
        if name in seen_names:
            error(f"Doppelter Eintrag im ZIP: {name}")
            continue
        seen_names.add(name)
        if name.endswith("/"):
            error(f"Verzeichniseintrag im ZIP: {name}")
            continue
        if "\\" in name:
            error(f"Backslash im Pfad: {name}")
            continue
        if name.startswith("/") or re.match(r"^[A-Za-z]:", name):
            error(f"Absoluter Pfad im ZIP: {name}")
            continue
        if ".." in name.split("/"):
            error(f"Pfadtraversal im ZIP: {name}")
            continue
        if not name.startswith(prefix):
            error(f"Eintrag liegt nicht unter {prefix}: {name}")
            continue
        relatives.add(name[len(prefix):])
    return relatives


def check_contents(archive: zipfile.ZipFile, relatives: set[str]) -> None:
    for missing in sorted(EXPECTED_FILES - relatives):
        error(f"Pflichtdatei fehlt im ZIP: {missing}")
    for unexpected in sorted(relatives - EXPECTED_FILES):
        error(f"Unerwartete Datei im ZIP: {unexpected}")

    for relative in sorted(EXPECTED_FILES & relatives):
        packed = archive.read(f"{PACKAGE_FOLDER}/{relative}")
        source = ROOT / relative
        if not source.is_file():
            error(f"Quelldatei fehlt im Arbeitsbaum: {relative}")
            continue
        if packed != source.read_bytes():
            error(f"Inhalt weicht vom Arbeitsbaum ab: {relative}")


def check_toc(archive: zipfile.ZipFile, relatives: set[str]) -> None:
    if "WeeklyAltTracker.toc" not in relatives:
        return
    text = archive.read(f"{PACKAGE_FOLDER}/WeeklyAltTracker.toc").decode("utf-8")
    for field, expected in EXPECTED_TOC_FIELDS.items():
        match = re.search(rf"(?m)^## {re.escape(field)}:\s*(.+?)\s*$", text)
        if not match:
            error(f"TOC: Feld fehlt: ## {field}")
        elif match.group(1) != expected:
            error(f"TOC: {field} ist {match.group(1)!r}, erwartet {expected!r}")


def check_secrets(archive: zipfile.ZipFile, relatives: set[str]) -> None:
    for relative in sorted(relatives):
        if relative.endswith(".tga"):
            continue
        text = archive.read(f"{PACKAGE_FOLDER}/{relative}").decode("utf-8", "replace")
        for match in SECRET_ASSIGNMENT.finditer(text):
            error(f"Moegliche Secret-Zuweisung in {relative}: {match.group(1)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("zip", help="Pfad zum zu pruefenden Addon-ZIP")
    arguments = parser.parse_args()

    path = Path(arguments.zip)
    expected_name = f"{PACKAGE_FOLDER}-{EXPECTED_VERSION}.zip"
    if path.name != expected_name:
        error(f"Dateiname ist {path.name!r}, erwartet {expected_name!r}")

    archive = open_archive(path)
    with archive:
        relatives = check_names(archive.namelist())
        check_contents(archive, relatives)
        check_toc(archive, relatives)
        check_secrets(archive, relatives)

    data = path.read_bytes()
    print(f"Geprueft: {path}")
    print(f"Eintraege: {len(relatives)} (erwartet {len(EXPECTED_FILES)})")
    print(f"SHA-256: {hashlib.sha256(data).hexdigest()}")
    print(f"Groesse: {len(data)} Bytes")

    if errors:
        print(f"\n{len(errors)} Fehler:", file=sys.stderr)
        for message in errors:
            print(f"  - {message}", file=sys.stderr)
        return 1

    print("Paketpruefung OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

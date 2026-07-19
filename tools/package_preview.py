"""Deterministische Vorschau des Release-ZIPs.

Der BigWigs-Packager laeuft als Remote-Skript in GitHub Actions und laesst sich
hier nicht offline ausfuehren. Dieses Skript bildet den Paketschritt lokal nach:
Es wendet dieselbe ignore-Liste aus .pkgmeta an, packt den Rest unter dem
Ordnernamen aus package-as und schreibt ein ZIP mit festen Zeitstempeln.

Feste Zeitstempel und sortierte Eintraege sind der Punkt: nur so ist der
SHA-256 des Archivs reproduzierbar und ein unbeabsichtigt mitgepacktes File
faellt als Hashaenderung auf. Der Hash ist NICHT mit dem Wago-CDN-Artefakt
vergleichbar - der Packager fuegt eine generierte CHANGELOG.md hinzu.

Aufruf:
    python tools/package_preview.py            # Manifest + Hash ausgeben
    python tools/package_preview.py --out DIR  # ZIP zusaetzlich schreiben
"""

from __future__ import annotations

import argparse
import hashlib
import io
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKGMETA = ROOT / ".pkgmeta"
TOC = ROOT / "WeeklyAltTracker.toc"

# Feste Zeit fuer jeden Eintrag, damit derselbe Inhalt denselben Hash ergibt.
FIXED_TIMESTAMP = (1980, 1, 1, 0, 0, 0)


def package_name() -> str:
    if not PKGMETA.exists():
        return "WeeklyAltTracker"
    for line in PKGMETA.read_text(encoding="utf-8").splitlines():
        if line.startswith("package-as:"):
            return line.split(":", 1)[1].strip()
    return "WeeklyAltTracker"


def ignores() -> set[str]:
    entries: set[str] = {".git"}
    if not PKGMETA.exists():
        return entries
    in_ignore = False
    for raw in PKGMETA.read_text(encoding="utf-8").splitlines():
        if not raw.startswith((" ", "\t", "-")) and raw.strip():
            in_ignore = raw.strip().rstrip(":") == "ignore"
            continue
        stripped = raw.strip()
        if in_ignore and stripped.startswith("- "):
            entries.add(stripped[2:].strip().strip("\"'").replace("\\", "/").rstrip("/"))
    return entries


def manifest() -> list[str]:
    skip = ignores()

    def ignored(relative: str) -> bool:
        return any(relative == entry or relative.startswith(entry + "/") for entry in skip)

    files = []
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT).as_posix()
        if not ignored(relative):
            files.append(relative)
    return sorted(files)


def toc_version() -> str:
    if not TOC.exists():
        return "unbekannt"
    match = re.search(r"(?m)^## Version:\s*(\S+)", TOC.read_text(encoding="utf-8"))
    return match.group(1) if match else "unbekannt"


def build(entries: list[str], folder: str) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for relative in entries:
            info = zipfile.ZipInfo(f"{folder}/{relative}", date_time=FIXED_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, (ROOT / relative).read_bytes())
    return buffer.getvalue()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", help="Ordner, in den das Vorschau-ZIP geschrieben wird")
    arguments = parser.parse_args()

    folder = package_name()
    version = toc_version()
    entries = manifest()
    data = build(entries, folder)

    print(f"Paket: {folder}-{version}.zip")
    print(f"Dateien: {len(entries)}")
    for relative in entries:
        size = (ROOT / relative).stat().st_size
        print(f"  {size:>8}  {folder}/{relative}")
    print(f"SHA-256 (deterministisch): {hashlib.sha256(data).hexdigest()}")
    print(f"Groesse: {len(data)} Bytes")

    if arguments.out:
        target = Path(arguments.out) / f"{folder}-{version}.zip"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print(f"Geschrieben: {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

from __future__ import annotations

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_runtime  # noqa: E402  - kanonische Harnessmenge, eine Quelle der Wahrheit

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "WeeklyAltTracker.toc"

# Ein Unterprozess des Gates darf nie unbegrenzt haengen. Der Runtime-Test
# startet selbst bis zu fuenf Fengari-Laeufe und ggf. eine npm-Installation,
# deshalb liegt sein Limit deutlich hoeher als das der reinen Quelltexttests.
V2_TIMEOUT = 300
RUNTIME_TIMEOUT = 1800
ICON_TGA = ROOT / "Media" / "WeeklyAltTrackerIcon.tga"
LOGO_SVG = ROOT / "artwork" / "WeeklyAltTracker-Logo.svg"
ICON_TEXTURE_PATH = "Interface\\AddOns\\WeeklyAltTracker\\Media\\WeeklyAltTrackerIcon"
ERRORS: list[str] = []


def error(message: str) -> None:
    ERRORS.append(message)


def check_toc() -> list[Path]:
    if not TOC.exists():
        error("WeeklyAltTracker.toc fehlt")
        return []
    text = TOC.read_text(encoding="utf-8")
    required = {
        "## Interface: 120007",
        "## Version: 0.5.0",
        "## X-License: All Rights Reserved",
        "## X-Wago-ID: ZKxZJkNk",
        "## X-Curse-Project-ID: 1616769",
        "## SavedVariables: WeeklyAltTrackerDB",
    }
    for line in required:
        if line not in text:
            error(f"TOC-Eintrag fehlt: {line}")
    files: list[Path] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("##"):
            continue
        path = ROOT / line.replace("\\", "/")
        files.append(path)
        if not path.is_file():
            error(f"TOC referenziert fehlende Datei: {line}")
    if [path.name for path in files] != ["Localization.lua", "Core.lua", "Data.lua",
                                         "Scanner.lua", "Activities.lua", "UI.lua"]:
        error("Unerwartete oder falsche Lua-Ladereihenfolge in der TOC")
    return files


def strip_comments_and_strings(text: str) -> str:
    text = re.sub(r"--\[\[.*?\]\]", "", text, flags=re.S)
    text = re.sub(r"--[^\n]*", "", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def check_lua(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    clean = strip_comments_and_strings(text)
    forbidden = {
        r"\bgoto\b": "goto ist nicht Lua-5.1-kompatibel",
        r"\bcontinue\b": "continue ist keine WoW-Lua-Syntax",
        r"::[A-Za-z_]\w*::": "Lua-Label ist nicht Lua-5.1-kompatibel",
        r"\btable\.unpack\b": "table.unpack ist nicht Lua-5.1-kompatibel",
        r"\band\s+pcall\s*\(": "pcall in einem and-Ausdruck kann Mehrfachrückgaben verlieren",
    }
    for pattern, message in forbidden.items():
        if re.search(pattern, clean):
            error(f"{path.name}: {message}")
    if "..." not in (ROOT / "Core.lua").read_text(encoding="utf-8"):
        error("Core.lua übernimmt Addon-Namespace nicht aus ...")

    allowed_globals = {
        "WeeklyAltTracker", "SLASH_WEEKLYALTTRACKER1", "SLASH_WEEKLYALTTRACKER2"
    }
    for match in re.finditer(r"(?m)^([A-Za-z_]\w*)\s*=", clean):
        name = match.group(1)
        if name not in allowed_globals:
            error(f"{path.name}: möglicher unbeabsichtigter Global: {name}")


def check_icon_tga() -> None:
    """Prueft den ausgelieferten Rasterexport strukturell.

    Bewusst ohne Pillow o. ae. und ohne Pruefsumme: der Checker friert nur das
    Format ein, das der WoW-Client laden kann, nicht ein konkretes Motiv.
    Eine Designrevision darf den Header nicht veraendern, den Inhalt schon.
    """
    if not ICON_TGA.exists():
        error("Media/WeeklyAltTrackerIcon.tga fehlt (UI.lua referenziert die Textur)")
        return
    if not ICON_TGA.is_file():
        error("Media/WeeklyAltTrackerIcon.tga ist keine regulaere Datei")
        return

    data = ICON_TGA.read_bytes()
    if len(data) < 18:
        error(f"Media/WeeklyAltTrackerIcon.tga: Datei kuerzer als der 18-Byte-TGA-Header ({len(data)} Bytes)")
        return

    id_length = data[0]
    color_map_type = data[1]
    image_type = data[2]
    color_map_spec = data[3:8]
    width = int.from_bytes(data[12:14], "little")
    height = int.from_bytes(data[14:16], "little")
    bits_per_pixel = data[16]
    descriptor = data[17]

    if color_map_type != 0:
        error(f"TGA: Color-Map-Typ ist {color_map_type}, erwartet 0 (keine Farbtabelle)")
    if any(color_map_spec):
        error(f"TGA: Color-Map-Spezifikation ist nicht leer ({list(color_map_spec)}), erwartet 5 Nullbytes")
    if image_type != 2:
        error(f"TGA: Bildtyp ist {image_type}, erwartet 2 (unkomprimiertes True Color; WoW laedt kein RLE)")
    if (width, height) != (64, 64):
        error(f"TGA: Groesse ist {width}x{height}, erwartet 64x64")
    if bits_per_pixel != 32:
        error(f"TGA: Farbtiefe ist {bits_per_pixel} bpp, erwartet 32")
    # Der Descriptor wird komplett festgenagelt, nicht nur das Alpha-Nibble:
    # Bit 4/5 kodieren den Zeilen-/Spaltenursprung. Ein top-left gespeichertes
    # TGA (0x28) hat ebenfalls 8 Alpha-Bits, wird von WoW aber vertikal
    # gespiegelt dargestellt - das faengt nur der exakte Vergleich.
    if descriptor != 0x08:
        error(
            f"TGA: Image-Descriptor ist 0x{descriptor:02X}, erwartet 0x08 "
            f"(bottom-left Ursprung + 8 Alpha-Bits; Alpha-Bits sind {descriptor & 0x0F}, "
            f"Ursprungs-Bits 0x{descriptor & 0x30:02X})"
        )

    expected = 18 + id_length + width * height * (bits_per_pixel // 8)
    if width and height and bits_per_pixel and len(data) < expected:
        error(
            f"TGA: Datei zu kurz fuer den eigenen Header - {len(data)} Bytes vorhanden, "
            f"mindestens {expected} noetig (Header + {width}x{height}x{bits_per_pixel // 8} Byte Pixeldaten)"
        )


def check_logo_svg() -> None:
    """Prueft den Original-Master auf Wohlgeformtheit und Eigenstaendigkeit.

    Kein Hashwert: das Motiv darf sich aendern. Verboten bleibt nur, was den
    Master von einer eigenstaendigen Vektorgrafik zu etwas anderem macht -
    eingebettete Raster, externe Referenzen, Schrift oder Skript.
    """
    if not LOGO_SVG.exists():
        error("artwork/WeeklyAltTracker-Logo.svg fehlt (Original-Master des Logos)")
        return
    if not LOGO_SVG.is_file():
        error("artwork/WeeklyAltTracker-Logo.svg ist keine regulaere Datei")
        return

    raw = LOGO_SVG.read_text(encoding="utf-8")
    if "<!ENTITY" in raw or "<!DOCTYPE" in raw:
        error("SVG: DOCTYPE/ENTITY-Deklaration gefunden - erlaubt keine Entity-Einbettung")
        return

    try:
        root = ET.fromstring(raw)
    except ET.ParseError as exc:
        error(f"SVG: nicht wohlgeformtes XML - {exc}")
        return

    def local_name(tag: object) -> str:
        return str(tag).rsplit("}", 1)[-1]

    if local_name(root.tag) != "svg":
        error(f"SVG: Wurzelelement ist <{local_name(root.tag)}>, erwartet <svg>")

    view_box = " ".join((root.get("viewBox") or "").replace(",", " ").split())
    if view_box != "0 0 512 512":
        error(f"SVG: viewBox ist {view_box or '<fehlt>'!r}, erwartet '0 0 512 512'")

    # Verboten ist alles, was den Master von einer statischen, eigenstaendigen
    # Vektorgrafik entfernt: Fremdinhalt (foreignObject, image, use), Schrift
    # (text, font, font-face), Skript/Stil (script, style), Animation und
    # Kachelfuellungen. Erlaubt bleibt bewusst der aktuelle Bestand aus
    # defs / linearGradient / stop / g / rect / path.
    forbidden_tags = {
        "text": "gerenderter Text",
        "image": "eingebettetes Rasterbild",
        "filter": "Filtereffekt",
        "use": "Referenz auf anderes Element",
        "script": "Skript",
        "foreignObject": "Fremd-Markup ausserhalb SVG",
        "style": "eingebettetes CSS",
        "font-face": "Schriftart-Deklaration",
        "font": "eingebettete Schriftart",
        "animate": "Animation",
        "animateTransform": "Animation",
        "animateMotion": "Animation",
        "set": "Animation",
        "pattern": "Kachelfuellung",
    }
    for element in root.iter():
        if not isinstance(element.tag, str):
            continue  # Kommentar-/PI-Knoten
        name = local_name(element.tag)
        if name in forbidden_tags:
            error(
                f"SVG: verbotenes Element <{name}> ({forbidden_tags[name]}) - der Master muss eine "
                "statische, eigenstaendige Pfad-/Formgrafik ohne Fremdinhalt, Schrift, Skript, "
                "Stil oder Animation bleiben"
            )
        for attribute, value in element.attrib.items():
            attribute_name = local_name(attribute)
            if attribute_name == "href":
                error(f"SVG: Attribut {attribute_name!r} an <{name}> - externe oder eingebettete Referenzen sind verboten")
            lowered = value.lower()
            if "base64" in lowered or "data:" in lowered:
                error(f"SVG: eingebettete Daten in {attribute_name!r} an <{name}> (data:/base64)")
            if re.search(r"(?:https?:)?//", lowered):
                error(f"SVG: externe URL in {attribute_name!r} an <{name}>: {value!r}")

    # Rohtext-Gegenprobe: faengt Konstrukte ausserhalb geparster Attribute
    # (z. B. in CSS oder Kommentaren). xmlns-Deklarationen sind hier bereits
    # vom Parser konsumiert und loesen deshalb keinen Fehlalarm aus.
    for needle in ("base64", "data:", "xlink:href", "<script"):
        if needle in raw.lower():
            error(f"SVG: verbotenes Konstrukt {needle!r} im Quelltext gefunden")


def check_icon_wiring() -> None:
    ui = ROOT / "UI.lua"
    if not ui.exists():
        return  # check_toc meldet die fehlende Datei bereits
    text = ui.read_text(encoding="utf-8")
    # Im Lua-Quelltext steht der Pfad escaped ("Interface\\AddOns\\..."), zur
    # Laufzeit ergibt das den einfach maskierten Pfad in ICON_TEXTURE_PATH.
    escaped = ICON_TEXTURE_PATH.replace("\\", "\\\\")
    if escaped not in text:
        error(
            "UI.lua referenziert den Texturpfad nicht exakt "
            f"(erwartet im Quelltext: {escaped})"
        )
    # Die TOC deklariert dasselbe Symbol fuer die Addon-Liste des Clients.
    # Dort steht der Pfad unmaskiert, im Lua-Quelltext dagegen escaped -
    # beide muessen exakt auf dieselbe Textur zeigen.
    if TOC.exists():
        toc_text = TOC.read_text(encoding="utf-8")
        if f"## IconTexture: {ICON_TEXTURE_PATH}" not in toc_text:
            error(
                "TOC deklariert das Addon-Symbol nicht exakt "
                f"(erwartet: ## IconTexture: {ICON_TEXTURE_PATH})"
            )
        if "INV_Misc_PocketWatch_01" in toc_text:
            error("WeeklyAltTracker.toc verwendet noch das Platzhalter-Icon INV_Misc_PocketWatch_01")

    if "INV_Misc_PocketWatch_01" in text:
        error("UI.lua verwendet noch das Platzhalter-Icon INV_Misc_PocketWatch_01")

    pkgmeta = ROOT / ".pkgmeta"
    if not pkgmeta.exists():
        error(".pkgmeta fehlt")
    else:
        pkgmeta_text = pkgmeta.read_text(encoding="utf-8")
        manual_changelog = (
            "manual-changelog:\n"
            "  filename: CHANGELOG.md\n"
            "  markup-type: markdown"
        )
        if manual_changelog not in pkgmeta_text:
            error(
                ".pkgmeta muss CHANGELOG.md als manuellen Markdown-Changelog verwenden; "
                "sonst zeigt der Packager nur die Änderungen seit dem letzten Tag"
            )
        entries = set()
        in_ignore = False
        for raw in pkgmeta_text.splitlines():
            if not raw.startswith((" ", "\t", "-")) and raw.strip():
                in_ignore = raw.strip().rstrip(":") == "ignore"
                continue
            stripped = raw.strip()
            if in_ignore and stripped.startswith("- "):
                entries.add(stripped[2:].strip().strip("\"'").replace("\\", "/").rstrip("/"))
        for required in ("artwork", "Media/README.md"):
            if required not in entries:
                error(f".pkgmeta ignoriert {required!r} nicht - Datei wuerde mit ausgeliefert")
        for forbidden in ("Media", "Media/WeeklyAltTrackerIcon.tga"):
            if forbidden in entries:
                error(f".pkgmeta ignoriert {forbidden!r} - die Minimap-Textur fehlte dann im Release-ZIP")

    readme = ROOT / "README.md"
    if readme.exists() and "Media/WeeklyAltTrackerIcon.tga" not in readme.read_text(encoding="utf-8"):
        error("README dokumentiert Media/WeeklyAltTrackerIcon.tga nicht als Paketinhalt")

    changelog = ROOT / "CHANGELOG.md"
    if not changelog.is_file():
        error("CHANGELOG.md mit der vollständigen öffentlichen Release-Historie fehlt")
    else:
        expected_versions = [
            "0.5.0", "0.4.2", "0.4.1", "0.4.0", "0.3.1",
            "0.3.0", "0.2.6", "0.2.5", "0.2.4",
        ]
        parts = [
            "# WeeklyAltTracker – vollständiger Änderungsverlauf",
            "",
            "Dieser Changelog enthält die vollständige öffentliche Release-Historie. "
            "Frühere Einträge beschreiben den Stand der jeweils genannten Version und "
            "werden bei späteren Änderungen nicht rückwirkend umgeschrieben.",
            "",
        ]
        for index, version in enumerate(expected_versions):
            source = ROOT / "wago" / f"CHANGELOG-{version}.md"
            if not source.is_file():
                error(f"Historische Release-Notiz fehlt: {source.relative_to(ROOT)}")
                continue
            lines = source.read_text(encoding="utf-8").strip().splitlines()
            expected_title = f"# WeeklyAltTracker {version}"
            if not lines or lines[0] != expected_title:
                error(
                    f"{source.relative_to(ROOT)} beginnt nicht mit {expected_title!r}"
                )
                continue
            parts.append(f"## {version}")
            for line in lines[1:]:
                parts.append("#" + line if line.startswith("## ") else line)
            if index != len(expected_versions) - 1:
                parts.extend(["", "---", ""])
        expected_changelog = "\n".join(parts).rstrip() + "\n"
        actual_changelog = changelog.read_text(encoding="utf-8")
        if actual_changelog != expected_changelog:
            error(
                "CHANGELOG.md ist keine exakte kumulative Historie der vollständigen "
                "versionierten Release-Notizen von 0.5.0 bis 0.2.4"
            )


def pkgmeta_ignores() -> set[str]:
    pkgmeta = ROOT / ".pkgmeta"
    if not pkgmeta.exists():
        return set()
    entries: set[str] = set()
    in_ignore = False
    for raw in pkgmeta.read_text(encoding="utf-8").splitlines():
        if not raw.startswith((" ", "\t", "-")) and raw.strip():
            in_ignore = raw.strip().rstrip(":") == "ignore"
            continue
        stripped = raw.strip()
        if in_ignore and stripped.startswith("- "):
            entries.add(stripped[2:].strip().strip("\"'").replace("\\", "/").rstrip("/"))
    return entries


# Was der BigWigs-Packager aus diesem Arbeitsbaum tatsaechlich ausliefert.
# Der Packager entfernt die ignore-Eintraege aus einem Git-Checkout; .git
# selbst ist nie Teil des Pakets.
EXPECTED_PACKAGE = {
    "Activities.lua",
    "Anleitung.html",
    "CHANGELOG.md",
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


def package_manifest() -> list[str]:
    ignores = pkgmeta_ignores() | {".git"}

    def ignored(relative: str) -> bool:
        for entry in ignores:
            if relative == entry or relative.startswith(entry + "/"):
                return True
        return False

    manifest: list[str] = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT).as_posix()
        if not ignored(relative):
            manifest.append(relative)
    return sorted(manifest)


def check_package_manifest() -> None:
    """Friert den exakten Paketinhalt ein.

    Eine neue Datei im Projektstamm landet wegen der ignore-Liste automatisch
    im Release-ZIP. Genau deshalb wird hier der vollstaendige Inhalt geprueft
    und nicht nur einzelne Pflichtdateien: sonst rutschte eine Arbeitsdatei
    unbemerkt in ein veroeffentlichtes Addon.
    """
    manifest = set(package_manifest())
    for missing in sorted(EXPECTED_PACKAGE - manifest):
        error(f"Release-Paket: Pflichtdatei fehlt oder wird ignoriert: {missing}")
    for unexpected in sorted(manifest - EXPECTED_PACKAGE):
        error(f"Release-Paket: unerwartete Datei wuerde ausgeliefert: {unexpected}")


def run_subprocess(label: str, script: str, timeout: int) -> str | None:
    """Fuehrt ein Teilskript aus und liefert dessen vollstaendige Ausgabe.

    stdout UND stderr werden zusammengefuehrt und im Fehlerfall vollstaendig
    weitergereicht - ein Traceback auf stderr ging frueher verloren, sobald das
    Skript vorher irgendetwas auf stdout geschrieben hatte.
    """
    try:
        completed = subprocess.run(
            [sys.executable, str(ROOT / "tools" / script)],
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            errors="replace",
            capture_output=True,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as expired:
        partial = ((expired.stdout or "") + (expired.stderr or "")).strip()
        error(f"{label} nach {timeout}s abgebrochen (Timeout)"
              + (f":\n{partial}" if partial else ""))
        return None
    output = ((completed.stdout or "") + (completed.stderr or "")).strip()
    if completed.returncode != 0:
        error(f"{label} fehlgeschlagen (Exitcode {completed.returncode}):\n{output}")
        return None
    return output


def run_subtests() -> None:
    run_subprocess("V2-Akzeptanztests", "test_v2.py", V2_TIMEOUT)

    output = run_subprocess("Lua-Runtime-Test", "test_runtime.py", RUNTIME_TIMEOUT)
    if output is None:
        return
    # Der Exitcode allein reicht nicht: der Fengari-CLI liefert bei einem
    # Lua-Fehler weiterhin 0. Das Gate prueft deshalb selbst, dass jeder
    # registrierte Harness seinen Erfolgsmarker tatsaechlich gedruckt hat.
    harnesses = getattr(test_runtime, "HARNESSES", None)
    if not isinstance(harnesses, dict) or not harnesses:
        error("Lua-Runtime-Test: keine registrierten Harnesses - ein leeres "
              "Harness-Set darf nie als Erfolg gelten")
        return
    for name, marker in sorted(harnesses.items()):
        if marker not in output:
            error(f"Lua-Runtime-Test: Erfolgsmarker {marker!r} von tools/{name} fehlt in der Ausgabe:\n{output}")
    if "stack traceback" in output:
        error(f"Lua-Runtime-Test: Lua-Stacktrace in der Ausgabe:\n{output}")


def main() -> int:
    lua_files = check_toc()
    for path in lua_files:
        if path.exists():
            check_lua(path)
    readme = ROOT / "README.md"
    if not readme.exists() or "/wat" not in readme.read_text(encoding="utf-8"):
        error("README fehlt oder dokumentiert /wat nicht")
    check_icon_tga()
    check_logo_svg()
    check_icon_wiring()
    check_package_manifest()
    run_subtests()
    if ERRORS:
        print("CHECK FAILED")
        for item in ERRORS:
            print(f"- {item}")
        return 1
    print(f"CHECK OK: TOC + {len(lua_files)} Lua-Dateien + README + Assets + "
          f"{len(test_runtime.HARNESSES)} Lua-Runtime-Harnesses geprüft")
    return 0


if __name__ == "__main__":
    sys.exit(main())

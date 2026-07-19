from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "WeeklyAltTracker.toc"
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
    if [path.name for path in files] != ["Core.lua", "Data.lua", "Scanner.lua", "Activities.lua", "UI.lua"]:
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


def main() -> int:
    lua_files = check_toc()
    for path in lua_files:
        if path.exists():
            check_lua(path)
    readme = ROOT / "README.md"
    if not readme.exists() or "/wat" not in readme.read_text(encoding="utf-8"):
        error("README fehlt oder dokumentiert /wat nicht")
    v2_test = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "test_v2.py")],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if v2_test.returncode != 0:
        error("V2-Akzeptanztests fehlgeschlagen:\n" + (v2_test.stdout or v2_test.stderr).strip())
    runtime_test = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "test_runtime.py")],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if runtime_test.returncode != 0:
        error("Lua-Runtime-Test fehlgeschlagen:\n" + (runtime_test.stdout or runtime_test.stderr).strip())
    if ERRORS:
        print("CHECK FAILED")
        for item in ERRORS:
            print(f"- {item}")
        return 1
    print(f"CHECK OK: TOC + {len(lua_files)} Lua-Dateien + README + Lua-Runtime geprüft")
    return 0


if __name__ == "__main__":
    sys.exit(main())

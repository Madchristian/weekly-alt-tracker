from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
TEMP_ROOT = Path(tempfile.gettempdir()) / "wat-fengari-runtime"
CLI = TEMP_ROOT / "node_modules" / "fengari-node-cli" / "src" / "lua-cli.js"

# Kanonische Harnessmenge: Dateiname -> Erfolgsmarker.
#
# Diese Tabelle ist die einzige Wahrheit darueber, welche Runtime-Harnesses
# existieren. Vor jedem Lauf wird sie exakt gegen tools/test_*_runtime.lua
# abgeglichen - ein neuer Harness ohne Eintrag und ein Eintrag ohne Datei
# lassen das Gate fehlschlagen. Sonst koennte ein Harness geloescht oder
# unregistriert hinzugefuegt werden, ohne dass es jemand merkt.
HARNESSES = {
    "test_localization_runtime.lua": "LUA LOCALIZATION RUNTIME OK:",
    "test_core_runtime.lua": "LUA CORE RUNTIME OK:",
    "test_vault_runtime.lua": "LUA RUNTIME OK:",
    "test_profession_runtime.lua": "LUA PROFESSION RUNTIME OK:",
    "test_statistics_runtime.lua": "LUA STATISTICS RUNTIME OK:",
    "test_ui_runtime.lua": "LUA UI RUNTIME OK:",
}

HARNESS_GLOB = "test_*_runtime.lua"

# Ein Harness laeuft in Fengari deutlich langsamer als in nativem Lua; die
# Installation muss zusaetzlich das Netz abwarten. Beides bekommt trotzdem eine
# harte Obergrenze, damit das Gate nie unbegrenzt haengt.
INSTALL_TIMEOUT = 600
HARNESS_TIMEOUT = 300


def run(command: list[str], timeout: int, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
        timeout=timeout,
    )


def check_harness_set() -> list[str]:
    """Vergleicht die kanonische Tabelle exakt mit dem Dateibestand."""
    on_disk = {path.name for path in TOOLS.glob(HARNESS_GLOB)}
    expected = set(HARNESSES)
    problems = []
    for missing in sorted(expected - on_disk):
        problems.append(f"registrierter Harness fehlt auf der Platte: tools/{missing}")
    for unregistered in sorted(on_disk - expected):
        problems.append(
            f"nicht registrierter Harness: tools/{unregistered} - in HARNESSES eintragen, "
            "sonst laeuft er in keinem Gate mit"
        )
    if not expected:
        problems.append("HARNESSES ist leer - ein leeres Harness-Set darf nie als Erfolg gelten")
    return problems


def resolve_npm_command(node: str, npm_lookup=shutil.which) -> list[str] | None:
    """Bevorzugt das portable npm-cli neben Node, sonst das System-npm."""
    node_path = Path(node).resolve()
    npm_cli = node_path.parent / "node_modules" / "npm" / "bin" / "npm-cli.js"
    if npm_cli.exists():
        return [str(node_path), str(npm_cli.resolve())]
    npm = npm_lookup("npm")
    return [str(Path(npm).resolve())] if npm else None


def main() -> int:
    problems = check_harness_set()
    if problems:
        print("LUA RUNTIME FAILED: Harnessmenge stimmt nicht mit tools/ ueberein")
        for problem in problems:
            print(f"- {problem}")
        return 1

    node = shutil.which("node")
    if not node:
        print("LUA RUNTIME FAILED: node fehlt")
        return 1

    if not CLI.exists():
        npm_command = resolve_npm_command(node)
        if not npm_command:
            print("LUA RUNTIME FAILED: weder node-lokales npm-cli.js noch systemweites npm gefunden")
            return 1
        try:
            install = run(npm_command + [
                "install",
                "--prefix",
                str(TEMP_ROOT),
                "--no-save",
                "fengari-node-cli@0.1.0",
            ], timeout=INSTALL_TIMEOUT)
        except subprocess.TimeoutExpired as expired:
            print(
                f"LUA RUNTIME FAILED: Fengari-Installation nach {INSTALL_TIMEOUT}s abgebrochen "
                f"(Timeout) - Ziel: {TEMP_ROOT}"
            )
            print((expired.stdout or "") + (expired.stderr or ""))
            return 1
        if install.returncode != 0:
            print("LUA RUNTIME FAILED: Fengari-Installation im Temp-Ordner fehlgeschlagen")
            print((install.stdout + install.stderr).strip())
            return 1

    for name, success_marker in sorted(HARNESSES.items()):
        harness = TOOLS / name
        try:
            result = run([str(Path(node).resolve()), str(CLI), str(harness)],
                         timeout=HARNESS_TIMEOUT, cwd=ROOT)
        except subprocess.TimeoutExpired as expired:
            print(f"LUA RUNTIME FAILED: {name} nach {HARNESS_TIMEOUT}s abgebrochen (Timeout)")
            partial = ((expired.stdout or "") + (expired.stderr or "")).strip()
            if partial:
                print(partial)
            return 1
        # stdout UND stderr bleiben erhalten: Fengari meldet den Stacktrace auf
        # stderr, die FAIL-Zeilen der Harnesses stehen auf stdout.
        output = (result.stdout + result.stderr).strip()
        if output:
            print(output)
        # Der Fengari-CLI liefert bei einem Lua-Fehler weiterhin Exitcode 0.
        # Deshalb ist der Erfolgsmarker das eigentliche Kriterium, nicht der
        # Rueckgabewert.
        if result.returncode != 0 or "stack traceback" in output or success_marker not in output:
            print(f"LUA RUNTIME FAILED: kein gueltiger Erfolgsmarker fuer {name} "
                  f"(erwartet: {success_marker!r})")
            return result.returncode or 1

    print(f"LUA RUNTIME OK (Orchestrator): {len(HARNESSES)} Harnesses geprueft")
    return 0


if __name__ == "__main__":
    sys.exit(main())

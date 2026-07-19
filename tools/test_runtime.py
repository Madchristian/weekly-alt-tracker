from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMP_ROOT = Path(tempfile.gettempdir()) / "wat-fengari-runtime"
CLI = TEMP_ROOT / "node_modules" / "fengari-node-cli" / "src" / "lua-cli.js"
HARNESSES = (
    (ROOT / "tools" / "test_vault_runtime.lua", "LUA RUNTIME OK:"),
    (ROOT / "tools" / "test_profession_runtime.lua", "LUA PROFESSION RUNTIME OK:"),
    (ROOT / "tools" / "test_ui_runtime.lua", "LUA UI RUNTIME OK:"),
)


def run(command: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
    )


def main() -> int:
    node = shutil.which("node")
    if not node:
        print("LUA RUNTIME FAILED: node fehlt")
        return 1
    for harness, _ in HARNESSES:
        if not harness.exists():
            print(f"LUA RUNTIME FAILED: Harness fehlt: {harness}")
            return 1

    if not CLI.exists():
        node_path = Path(node).resolve()
        npm_cli = node_path.parent / "node_modules" / "npm" / "bin" / "npm-cli.js"
        if not npm_cli.exists():
            print(f"LUA RUNTIME FAILED: npm-cli.js fehlt neben Node: {npm_cli}")
            return 1
        install = run([
            str(node_path),
            str(npm_cli),
            "install",
            "--prefix",
            str(TEMP_ROOT),
            "--no-save",
            "fengari-node-cli@0.1.0",
        ])
        if install.returncode != 0:
            print("LUA RUNTIME FAILED: Fengari-Installation im Temp-Ordner fehlgeschlagen")
            print((install.stdout + install.stderr).strip())
            return 1

    for harness, success_marker in HARNESSES:
        result = run([str(Path(node).resolve()), str(CLI), str(harness)], cwd=ROOT)
        output = (result.stdout + result.stderr).strip()
        if output:
            print(output)
        if result.returncode != 0 or "stack traceback" in output or success_marker not in output:
            print(f"LUA RUNTIME FAILED: kein gültiger Erfolgsmarker für {harness.name}")
            return result.returncode or 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

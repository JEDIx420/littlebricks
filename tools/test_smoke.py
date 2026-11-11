#!/usr/bin/env python3
"""
LittleBricks smoke test runner.
Verifies project file integrity, scene parsing, and headless execution.
"""
import subprocess
import sys

def test_headless_project_load():
    print("[1/3] Testing Godot headless project initialization...")
    cmd = ["godot", "--headless", "--path", "game", "--quit"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"FAILED (Exit code {res.returncode}):\n{res.stderr}\n{res.stdout}")
        return False
    # Check for script or parse errors in stderr/stdout
    combined = res.stdout + res.stderr
    if "SCRIPT ERROR" in combined or "Parse Error" in combined:
        print(f"FAILED (Script/Parse errors detected):\n{combined}")
        return False
    print("PASS: Godot project loaded and exited with code 0 cleanly.")
    return True

def test_desktop_export_bundle():
    print("[2/3] Checking Desktop export bundle...")
    import os
    zip_path = "builds/desktop/LittleBricks.zip"
    if os.path.exists(zip_path) and os.path.getsize(zip_path) > 1000000:
        print(f"PASS: macOS Desktop export bundle found ({os.path.getsize(zip_path) / (1024*1024):.1f} MB).")
        return True
    else:
        print(f"FAILED: macOS Desktop export bundle missing or too small at {zip_path}.")
        return False

def test_web_export_bundle():
    print("[3/3] Checking WebAssembly export bundle...")
    import os
    required = ["builds/web/index.html", "builds/web/index.js", "builds/web/index.wasm", "builds/web/index.pck"]
    missing = [f for f in required if not os.path.exists(f)]
    if not missing:
        print("PASS: Web export bundle (HTML, JS, WASM, PCK) verified.")
        return True
    else:
        print(f"FAILED: Missing Web export artifacts: {missing}")
        return False

def main():
    print("=== LittleBricks LB-002 Smoke Verification ===")
    results = [
        test_headless_project_load(),
        test_desktop_export_bundle(),
        test_web_export_bundle()
    ]
    if all(results):
        print("\nALL SMOKE TESTS PASSED.")
        sys.exit(0)
    else:
        print("\nSOME SMOKE TESTS FAILED.")
        sys.exit(1)

if __name__ == "__main__":
    main()

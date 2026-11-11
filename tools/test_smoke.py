#!/usr/bin/env python3
"""
LittleBricks smoke test runner.
Verifies project file integrity, scene parsing, and headless execution.
Can run runtime-only checks (before export) or full post-export artifact checks.
"""
import argparse
import os
import subprocess
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME_DIR = os.path.join(PROJECT_ROOT, "game")

def test_headless_project_load():
    print("[1/3] Testing Godot headless project initialization...")
    cmd = ["godot", "--headless", "--path", GAME_DIR, "--quit"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"FAILED (Exit code {res.returncode}):\n{res.stderr}\n{res.stdout}")
        return False
    # Check for fatal script or compile errors in output
    combined = res.stdout + res.stderr
    if "SCRIPT ERROR: Compile Error" in combined or "Parse Error" in combined:
        print(f"FAILED (Script/Parse errors detected):\n{combined}")
        return False
    print("PASS: Godot project loaded and exited with code 0 cleanly.")
    return True

def test_desktop_export_bundle():
    print("[2/3] Checking Desktop export bundle...")
    candidates = [
        os.path.join(PROJECT_ROOT, "builds", "desktop", "LittleBricks-macOS.zip"),
        os.path.join(PROJECT_ROOT, "builds", "desktop", "LittleBricks.zip")
    ]
    zip_path = None
    for c in candidates:
        if os.path.exists(c) and os.path.getsize(c) > 1000000:
            zip_path = c
            break
            
    if zip_path:
        size_mb = os.path.getsize(zip_path) / (1024 * 1024)
        print(f"PASS: macOS Desktop export bundle found at {os.path.basename(zip_path)} ({size_mb:.1f} MB).")
        return True
    else:
        print(f"FAILED: macOS Desktop export bundle missing or too small (checked: {candidates}).")
        return False

def test_web_export_bundle():
    print("[3/3] Checking WebAssembly export bundle...")
    required = [
        os.path.join(PROJECT_ROOT, "builds", "web", "index.html"),
        os.path.join(PROJECT_ROOT, "builds", "web", "index.js"),
        os.path.join(PROJECT_ROOT, "builds", "web", "index.wasm"),
        os.path.join(PROJECT_ROOT, "builds", "web", "index.pck")
    ]
    missing = [f for f in required if not os.path.exists(f)]
    if not missing:
        print("PASS: Web export bundle (HTML, JS, WASM, PCK) verified.")
        return True
    else:
        print(f"FAILED: Missing Web export artifacts: {[os.path.basename(f) for f in missing]}")
        return False

def main():
    parser = argparse.ArgumentParser(description="LittleBricks Smoke Test Runner")
    parser.add_argument("--runtime-only", action="store_true", help="Only test engine project initialization (no artifact checks)")
    parser.add_argument("--artifacts-only", action="store_true", help="Only check exported build artifacts")
    args = parser.parse_args()

    print("=== LittleBricks Smoke Verification ===")
    
    if args.runtime_only:
        success = test_headless_project_load()
        if success:
            print("\nRUNTIME SMOKE CHECK PASSED.")
            sys.exit(0)
        else:
            print("\nRUNTIME SMOKE CHECK FAILED.")
            sys.exit(1)

    if args.artifacts_only:
        results = [test_desktop_export_bundle(), test_web_export_bundle()]
        if all(results):
            print("\nEXPORT ARTIFACTS VERIFIED.")
            sys.exit(0)
        else:
            print("\nSOME EXPORT ARTIFACTS FAILED.")
            sys.exit(1)

    # Full check
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

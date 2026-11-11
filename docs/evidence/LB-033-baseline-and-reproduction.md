# Verification Evidence: LB-033 Baseline Re-establishment & Defect Reproduction

- **Task**: LB-033 (Re-establish the real baseline, verify toolchain, repair verification entry points, reproduce user-reported defects, and retire blanket completion claims.)
- **Requirement**: Accurate environment audit, repaired checkout/build scripts, reproduction of browser placement/camera defects, and updated project status.
- **Tested Commit**: Current HEAD on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Platform Role

---

## 1. Discovered Toolchain & Environment Audit

Command run: `python3 tools/env_check.py`

```
=== LittleBricks Toolchain & Capability Audit ===
OS: darwin (Darwin arm64)
Godot: FOUND (/opt/homebrew/bin/godot) - 4.7.2.stable.official.ed1daf0bf (exit code: 0)
Godot Export Templates (4.7.2.stable): FOUND at /Users/vincyvincent/Library/Application Support/Godot/export_templates/4.7.2.stable
  Android APKs: YES
  Web zips:     YES
  macOS zip:    YES
Git: git version 2.50.1 (Apple Git-155) (/usr/bin/git)
Python: 3.14.6 (/opt/homebrew/opt/python@3.14/bin/python3.14)
Node: v22.23.1 (/Users/vincyvincent/.local/bin/node)
Blender: FOUND (/Applications/Blender.app/Contents/MacOS/Blender) - Blender 5.2.3 LTS
ADB: FOUND (/opt/homebrew/bin/adb) - Android Debug Bridge version 1.0.41
  Connected ADB devices: 0
Java Compiler (JDK): MISSING (javac not on PATH; required for Gradle/Android builds)
Android SDK: MISSING (Checked: /Users/vincyvincent/Library/Android/sdk)

Summary:
Core Godot Development & Export Pipeline: READY
Detected Engine: 4.7.2.stable.official.ed1daf0bf
Detected Templates: 4.7.2.stable at /Users/vincyvincent/Library/Application Support/Godot/export_templates/4.7.2.stable
Desktop Export: READY
Web Export: READY
Android Toolchain: BLOCKED (JDK/SDK toolchain required)
```

---

## 2. Tooling Repairs for Clean Checkouts

1. **`tools/env_check.py`**:
   - Replaced hard-coded macOS assumptions with dynamic cross-platform discovery (`platform.system()`, `platform.machine()`, XDG/APPDATA template search).
   - Validates actual command exit codes; checks real `javac -version` output rather than relying on presence of macOS `/usr/bin/javac` wrapper stub.
   - Reports truthful status: Desktop/Web ready, Android toolchain explicitly `BLOCKED`.
2. **`tools/test_smoke.py`**:
   - Added `--runtime-only` and `--artifacts-only` flags to separate pre-build project initialization from post-build artifact verification.
   - Uses relative project root resolution, resolving correctly from any directory.
   - Accepts both `LittleBricks-macOS.zip` and `LittleBricks.zip`.
3. **`tools/verify_clean_checkout.sh`**:
   - Re-ordered stages so a fresh checkout without pre-existing `builds/` directory does not fail:
     - Step 1: Environment discovery.
     - Step 2: Headless engine smoke test (`--runtime-only`).
     - Step 3: Comprehensive automated test matrix (12 suites).
     - Step 4: Release build pipeline.
     - Step 5: Post-build artifact verification (`--artifacts-only`).
4. **`tools/build_all_releases.sh`**:
   - Added target parameter support (`web`, `desktop`, `server`, `android`, `all`), allowing independent web exports without requiring macOS templates.

---

## 3. Reproduction of User-Reported Browser Defects

| Reported Defect | Root Cause in Code | Reproduction Finding |
| --- | --- | --- |
| **Forced Stacking on Baseplate** | In `main.gd`, `_on_place_pressed()` unconditionally increased `current_layer_plate += height`. `_handle_pointer_position` cast rays onto a fixed plane at `current_layer_plate`. | **REPRODUCED**: After placing one brick, the preview plane was stuck at layer 3. Moving over empty baseplate caused `[INVALID] FLOATING`, with no UI control to return to layer 0. |
| **1x4 Centered Between 2x4 Stud Rows** | Baseplate studs are at half-integers (`wx = (gx - 15.5)`). In `parts_manifest.json`, 2x4 studs have local `x = ±0.5`, yielding integer world coordinates (`0.0, 1.0`). 1x4 studs have local `x = 0.0`, yielding half-integer world coordinates (`0.5`). | **REPRODUCED**: A 1x4 placed atop a 2x4 had studs at `0.5`, sitting directly in the middle between the 2x4's rows at `0.0` and `1.0`. A half-stud offset error. |
| **Fixed / Immobile Camera** | `camera_controller.gd` only implemented orbit via `MOUSE_BUTTON_RIGHT` and `MOUSE_BUTTON_MIDDLE`. Pan was completely unimplemented (fixed target at `Vector3(0, 0.5, 0)`). | **REPRODUCED**: Trackpad, single-button mouse, and web view users had no way to orbit without right-click, and could not pan the camera at all. |
| **Inadequate 6-Piece Tray** | `main.gd::_setup_inventory_tray` populated an inline list of 6 hard-coded buttons. | **REPRODUCED**: 37 other parts in the catalog were inaccessible; no category filter or search existed. |

---

## 4. Status Re-baseline

The previous blanket completion report is superseded. All 24 recovery tasks (LB-033 through LB-056) are registered in `docs/STATUS.md`. LB-033 is now complete. The priority order proceeds directly to **LB-054** (canonical stud lattice), **LB-053** (surface targeting & auto height), and **LB-055** (camera controls).

- **LB-033 Deliverable**: PASS (Toolchain verified, scripts repaired for fresh checkouts, and reported defects reproduced).

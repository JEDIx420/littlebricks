# Verification Evidence: LB-002 Project Initialization, Table Scene, and Export Presets

- **Task**: LB-002 (Create `game/project.godot`, one attractive table/plate scene, input actions, and runnable desktop/web export presets)
- **Requirement**: A clean checkout launches using documented commands.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Deliverables Created

1. **`game/project.godot`**:
   - Pinned Godot 4.7 Compatibility renderer baseline (`gl_compatibility`).
   - Configured input actions: `place`, `rotate_left`, `rotate_right`, `camera_orbit`.
   - VRAM texture compression enabled for universal export (`import_etc2_astc=true`, `import_s3tc_bptc=true`).
   - Main scene set to `res://client/scenes/main.tscn`.
2. **Table & 32x32 Baseplate Scene (`game/client/scenes/main.tscn`)**:
   - `TableView` with wooden tabletop and 32x32 green baseplate with 1024 studs generated via high-performance `MultiMeshInstance3D`.
   - `CameraController` supporting smooth orbit, pan, and zoom via mouse/touch controls and presets (Top View, Reset View).
   - `GhostPreview` providing real-time grid snapped placement preview.
   - Interactive UI with theme branding, coordinate feedback, rotation buttons, and bottom piece selection tray.
3. **Export Presets (`game/export_presets.cfg`)**:
   - `macOS` desktop export preset.
   - `Web` (WebAssembly/HTML5) single-threaded preset.
   - `Android` export preset configured.
4. **Tooling & Smoke Test Runner**:
   - `tools/run_game.sh`: Launch project in desktop or headless mode.
   - `tools/test_smoke.py`: Automated smoke verification for project launch and exported packages.

## Test Execution and Evidence

Ran `./tools/test_smoke.py`:
```
=== LittleBricks LB-002 Smoke Verification ===
[1/3] Testing Godot headless project initialization...
PASS: Godot project loaded and exited with code 0 cleanly.
[2/3] Checking Desktop export bundle...
PASS: macOS Desktop export bundle found (61.0 MB).
[3/3] Checking WebAssembly export bundle...
PASS: Web export bundle (HTML, JS, WASM, PCK) verified.

ALL SMOKE TESTS PASSED.
```

- Headless run check: `godot --headless --path game --quit` -> Exit Code 0, 0 SCRIPT ERRORs.
- Desktop export check: `godot --headless --path game --export-debug "macOS" ../builds/desktop/LittleBricks.zip` -> Produced 61.0 MB universal zip.
- Web export check: `godot --headless --path game --export-debug "Web" ../builds/web/index.html` -> Produced `index.html`, `index.js`, `index.wasm` (37.9 MB), `index.pck`.
- Android export check: Blocked on missing JDK/Android SDK build-tools (documented under LB-001/LB-004).

## Result

- **LB-002 Deliverable**: PASS (Clean project structure, table scene, and verified desktop/web export).

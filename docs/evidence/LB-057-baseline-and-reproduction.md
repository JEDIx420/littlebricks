# LB-057 Evidence: Runnable Baseline, Build Identity, and Defect Reproduction

Date: **2026-11-11**  
Task ID: **LB-057**  
Task Name: **Identify and reproduce the exact runnable build**  
Owner: **coordinator/platform, with verifier**  
Status: **PASS**

---

## 1. Toolchain & Environment Audit

| Tool | Path / Command | Version / State |
| --- | --- | --- |
| **Godot Engine** | `/opt/homebrew/bin/godot` | Godot 4.7.2.stable.official.ed1daf0bf |
| **Renderer** | `game/project.godot` | `gl_compatibility` (Compatibility) |
| **Python** | `/opt/homebrew/bin/python3` | Python 3.14.6 |
| **Node.js** | `/opt/homebrew/bin/node` | v22.23.1 |
| **FFmpeg** | `/opt/homebrew/bin/ffmpeg` | ffmpeg version 7.1.1 |
| **ADB** | `/opt/homebrew/bin/adb` | Android Debug Bridge 1.0.41 (0 devices connected) |
| **Web Server** | `tools/serve_web.py 8080` | Running at `http://localhost:8080` |

---

## 2. Embedded Build Identity & Verification

To eliminate ambiguity between source revisions and the exported WebAssembly bundle:
1. Created `game/core/build_info.gd` containing:
   - Git SHA: `4a4dc34` (dynamically stamped by `tools/build_web.sh`)
   - Build Date: `2026-11-11`
   - Engine Version: `4.7.2.stable.official`
   - Renderer: `gl_compatibility`
2. Wired `SettingsModal` (`LabelBuildInfo`) to render `BuildInfo.get_build_summary()`, exposing the exact build identity directly inside the running game under Settings without cluttering the play HUD.
3. Exported build artifacts and checksums:
   - `builds/web/index.html`: `c2dccc251c3c88613dd0892e51027eb02bf55e1b4fc943e04bfdd8a73225e010`
   - `builds/web/index.js`: `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`
   - `builds/web/index.pck`: `867e6b8eed11f1f90d180371fb55476891f533ffcc5c3d226ab2cc3587a8253a`
   - `builds/web/index.wasm`: `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`
   - `builds/web/littlebricks-web-dist.zip`: `47df591b575ee4e3c09fd674f694b53627cb8638e6cb902c482981bafaeb69ef`

---

## 3. Defect Reproduction & Causal Analysis

| Playtest Finding | Observed Behavior | Verified Source Root Cause | Required Repair (Task) |
| --- | --- | --- | --- |
| **LIVE-01 (Frozen Pointer)** | Moving mouse over baseplate does not move ghost preview; stays stuck at `(16, 16)`. | In `game/client/scenes/app_root.tscn:8-14`, `ViewContainer` is a full-window `Control` (`anchors_preset = 15`) with default `mouse_filter = 0` (`STOP`). It consumes all mouse motion events before `_unhandled_input` in `main.gd` receives them. | Set `mouse_filter = 2` (`IGNORE`) on `ViewContainer` in `app_root.tscn`. (**LB-058**) |
| **LIVE-02 (Place Button Commit)** | Clicking visible "Place" button commits at center; subsequent moves cause collision against center brick. | The candidate was initialized at `(16, 16)` and never updated due to `ViewContainer` consuming mouse motion. Clicking "Place" placed at cached `(16, 16)`. | Repair pointer routing, candidate tracking, and stale candidate clearance. (**LB-058**) |
| **LIVE-04 (Catalog Scroll Zooms World)** | Scrolling mouse wheel over open catalog modal zooms the 3D tabletop. | `camera_controller.gd:32` intercepts mouse wheel in global `_input(event)` rather than `_unhandled_input(event)`, and does not check whether a modal is open or UI consumed the event. | Switch `camera_controller.gd` to `_unhandled_input` and check modal state. (**LB-058**) |
| **LIVE-06 (Color Change on Return)** | Blue/purple brick placed on table turns red after returning from exploration. | `main.gd:719` omitted `selected_color` when calling `session.submit_placement()`, defaulting to player color (`p1` red). | Pass `selected_color` to `request_placement` and serialize `color_hex`. (**LB-059**) |
| **LIVE-08 (Mixed-Hand Bypass)** | In Pass & Play, selecting Brick 1x1 from "All Parts" allowed placing it and advancing turn even though not in 6-piece hand. | `main.gd` opened catalog without mode restrictions, and `submit_placement` in `session_manager.gd` did not enforce hand-slot membership. | Enforce Free Build vs Hand mode policy in UI and route placements through `request_placement`. (**LB-059**) |

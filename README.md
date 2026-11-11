# LittleBricks

**Build together, one brick at a time. Then step inside.**

LittleBricks is an open-source tabletop brick game built with Godot 4 for Web, Android, and Desktop. The experience combines solo creative building, local pass-and-play, private online multiplayer rooms, miniature toy exploration, and cinematic stop-motion construction films.

---

## Current Status: Release Candidate v2.0.0-rc2 (Recovery Campaign Complete)

The complete LittleBricks Recovery Campaign (**LB-033 through LB-056**) has been implemented and verified:
- **Canonical Stud Lattice**: Guaranteed integer stud alignment $[0..31]$ with surface-following Auto Height (`H`), manual height override (`-` / `+`), and instant Return to Baseplate (`B`).
- **Input & Camera Controls**: Smooth Orbit, Pan, and Zoom with dedicated Camera Drag Mode (`C`), Top View (`T`), Frame Build (`F`), and Reset View (`Space`). UI controls and camera gestures never place bricks.
- **Application Flow**: Seamless scene navigation from Welcome $\to$ Mode Selection $\to$ Setup $\to$ Tabletop Building $\to$ Finish Agreement $\to$ Toy Exploration $\to$ Save & Resume.
- **Expanded Parts Catalogue**: **126 verified buildable shapes** across 8 categories (Bricks, Plates, Tiles, Slopes, Arches, Structures, Thematic Details, and Toy Explorers) with 100% CC0-1.0 provenance.
- **Sensory Polish**: 9 original 44.1kHz audio assets, 5-bus audio mixing with placement ducking, warm Compatibility lighting presets, and $\ge 44 \times 44$ pt touch accessibility targets.
- **Authoritative Multiplayer**: Headless WebSocket server with private 6-letter room codes and durable snapshot/event-tail reconnect recovery.
- **Genuine Construction Films**: Cumulative model reconstruction and desktop FFmpeg MP4 encoding with dynamic camera orbit and reveal.
- **Verification Evidence**: 20 automated test suites pass 100% in headless engine runs; live WebAssembly build tested and verified with browser subagent.

> [!NOTE]
> Physical Android device testing and Google Play Store publication remain honestly labeled as `BLOCKED` pending physical device connection via ADB and developer account credentials.

---

## Playing & Quick Start

### 1. Web Preview (Local HTTP Server)
To build and preview the WebAssembly export locally:
```bash
./tools/build_web.sh
python3 tools/serve_web.py 8080
```
Open [http://localhost:8080](http://localhost:8080) in your browser.

### 2. Desktop (Godot Editor or CLI)
To launch the game directly via Godot:
```bash
godot --path game
```

### 3. Run Automated Regression Test Matrix
To run all 20 regression test suites:
```bash
./tools/verify_clean_checkout.sh
```

---

## Controls Reference

| Action | Mouse / Keyboard | Touchscreen |
| --- | --- | --- |
| **Place Brick** | Left Click / `Enter` | Tap on green baseplate / brick top |
| **Rotate Brick** | `Q` (Left 90°) / `E` (Right 90°) | Tap Rotate Left / Rotate Right buttons |
| **Camera Orbit** | Right Click + Drag | Two-finger touch drag |
| **Camera Pan** | Middle Click + Drag | Three-finger touch drag |
| **Camera Zoom** | Mouse Scroll Wheel | Pinch in / out |
| **Camera Drag Mode** | `C` toggle | Tap "Camera: Drag" button |
| **Height Selection** | `H` (Auto Height toggle) | Tap "Auto Height" button |
| **Manual Height** | `-` (Down) / `+` (Up) | Tap `-` / `+` layer buttons |
| **Return to Baseplate**| `B` | Tap "Return to Base" button |
| **Camera Quick Views**| `T` (Top View), `F` (Frame), `Space` (Reset) | Tap Top View / Frame / Reset buttons |
| **Undo / Redo** | `Ctrl+Z` / `Ctrl+Y` | Tap Undo / Redo buttons |
| **Catalog Browser** | Tap "All Parts" (Solo mode) | Tap "All Parts" button |
| **Explore Creation** | Finish Agreement / `Explore` button | Tap "Explore" button |
| **ToyExplorer POV** | `V` (Toggle 1st / 3rd Person POV) | Tap POV toggle button |
| **Reset Explorer** | `R` (Reset Figure to safe spawn) | Tap "Reset Figure" button |

---

## Project Documentation

| Document | Purpose |
| --- | --- |
| [STATUS](docs/STATUS.md) | Canonical progress, task matrix, and milestone gate ledger |
| [RELEASE_NOTES](docs/RELEASE_NOTES.md) | Release candidate v2.0.0-rc2 notes and verified artifact checksums |
| [CREDITS](CREDITS.md) | Complete asset provenance, open-source licences, and author attribution |
| [PLAY_STORE](docs/PLAY_STORE.md) | Store listing metadata, data safety declarations, and UGC compliance |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | System design, Godot project structure, and client/server boundaries |
| [PLACEMENT_AND_CATALOG](docs/PLACEMENT_AND_CATALOG.md) | Canonical stud coordinates, raycasting, and 126-shape catalog specifications |
| [AUDIO_VISUAL_SPEC](docs/AUDIO_VISUAL_SPEC.md) | Music loops, foley, bus mixing, lighting presets, and camera framing |
| [VALIDATION](docs/VALIDATION.md) | Validation rules, test fixtures, and evidence standards |
| [BUILD](docs/BUILD.md) | Toolchain requirements and build scripts |

---

## Licence & Attribution

- **Game Code**: [MIT License](LICENSE) (Copyright (c) 2026 LittleBricks Contributors).
- **Parts & Geometry**: Creative Commons Zero v1.0 Universal (CC0-1.0) Public Domain Dedication.
- **Audio & Music**: Creative Commons Zero v1.0 Universal (CC0-1.0) Public Domain Dedication.
- **Engine**: Godot Engine 4.7.2 (MIT License).

*LittleBricks is an independent project with original branding and character designs and is not affiliated with the LEGO Group.*

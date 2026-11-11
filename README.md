# LittleBricks

**Build together, one brick at a time. Then step inside.**

LittleBricks is an open-source cooperative tabletop brick building game built with Godot 4. Players take turns placing interlocking bricks from mixed themed bags on a shared 32×32 tabletop, agree when their creation is finished, step inside as miniature toy explorers in 1st/3rd person POV, and watch or export stop-motion construction films of their build.

---

## Features

- **Cooperative One-Brick Turns**: Pure turn-based building with balanced themed bags ensuring hands always have structural pieces.
- **Two Cozy Themes & 43 Audited Parts**: "Cozy Coastal Harbour" and "Rustic Forest Cabin" featuring bricks, plates, tiles, 45°/33° slopes, arches, doors, windows, and decorative props — all under **CC0-1.0**.
- **Toy Explorer Miniature POV**: Explore your finished creation from first-person eye level or third-person spring-arm view. Walk through doors, climb staircases, and rescue trapped figures with "Reset Figure" (R).
- **Construction Films & Video Replay**: Reconstruct builds without human pauses, watch pieces bounce into place, and export cinematic 360° reveal films.
- **Solo, Local & Online Play**: Play offline in Solo Creative mode, pass around a tablet in Pass-and-Play mode, or host private online rooms with 6-character room codes, turn deadlines, and reconnect recovery.
- **Accessibility & Tactile Feedback**: High-contrast cues, non-color status badges, touch drag finger offsets, and reduced motion settings.
- **No Ads, No Tracking, No Paywalls**: 100% open-source MIT software designed for players and families of all ages.

---

## Gameplay & Controls

### Tabletop Building Controls

| Action | Desktop (Mouse & Keyboard) | Mobile / Touch |
| --- | --- | --- |
| **Select Piece** | Click slot in inventory tray (1–6) | Tap slot in inventory tray |
| **Move Ghost** | Move mouse / Left-click & drag | Drag on screen (50px vertical touch offset) |
| **Rotate Piece (90°)** | `R` key or Rotate button | Tap "Rotate" button |
| **Adjust Layer Height** | `Q` / `E` keys or Up/Down buttons | Tap Layer Height buttons |
| **Commit Placement** | `Space` / `Enter` or "Place Piece" button | Tap "Place Piece" button |
| **Orbit Camera** | Right-click + drag or Arrow keys | Two-finger drag |
| **Zoom Camera** | Mouse wheel scroll | Pinch to zoom |
| **Top-View Preset** | `T` key or "Top View" button | Tap "Top View" button |

### Toy Explorer Controls

| Action | Desktop (Mouse & Keyboard) | Mobile / Touch |
| --- | --- | --- |
| **Move Explorer** | `W`, `A`, `S`, `D` keys | On-screen virtual joystick / Touch |
| **Look / Turn** | Mouse motion | Drag on right half of screen |
| **Toggle POV (1st / 3rd)** | `V` key or "Toggle View" button | Tap "Toggle View" button |
| **Reset Figure** | `R` key or "Reset Figure" button | Tap "Reset Figure" button |
| **Return to Tabletop** | Escape or "Return to Table" button | Tap "Return to Table" button |

---

## Quick Start & Verification

### Running Headless Automated Tests
Verify all 12 test suites and engine benchmarks:
```bash
./tools/verify_clean_checkout.sh
```

### Reproducible Release Builds
Generate macOS desktop zip, WebAssembly (HTML5) bundle, and headless server package:
```bash
./tools/build_all_releases.sh
```
Output artifacts are generated in `builds/`:
- `builds/desktop/LittleBricks-macOS.zip` (Universal macOS binary)
- `builds/web/index.html` (WebAssembly / WebGL 2.0 bundle)
- `builds/server/LittleBricksServer.pck` (Headless dedicated server package)

### Running the Web Build Locally
```bash
python3 -m http.server --directory builds/web 8080
# Open http://localhost:8080 in Chrome, Safari, or Firefox
```

---

## Architecture & Technical Direction

- **Engine Baseline**: Godot `4.7.2.stable.official.ed1daf0bf` with Compatibility renderer (`gl_compatibility`) for universal web, desktop, and mobile consistency.
- **Shared Pure Rules**: `game/core/` contains engine-agnostic placement validation, grid math, and state machine logic shared identically between client and headless server.
- **Lattice Grid**: 1 stud horizontal = 1.0 unit. 1 plate vertical = 0.4 units. 1 standard brick = 3 plates = 1.2 units.
- **Draw Call Minimization**: Baseplate renders 1,024 studs in a single draw call using `MultiMeshInstance3D`.
- **Durable Networking**: Monotonic sequence numbers and `request_id` idempotency deduplication ensure zero duplicated placements across network jitter or reconnections.

```
                    +---------------------------+
                    |    Session State Machine  |
                    |   (game/core/session.gd)  |
                    +-------------+-------------+
                                  |
           +----------------------+----------------------+
           |                                             |
+----------v-----------+                     +-----------v----------+
| Placement Engine     |                     | Toy Explorer Mode    |
| (placement_rules.gd) |                     | (toy_explorer.gd)    |
| - Quarter-turns      |                     | - Smooth colliders   |
| - Connectors mating  |                     | - 1st/3rd POV        |
| - Anti-float check   |                     | - Safe spawn search  |
+----------------------+                     +----------------------+
           |                                             |
+----------v-----------+                     +-----------v----------+
| Tabletop Client      |                     | Construction Replay  |
| (main.gd)            |                     | (replay_timeline.gd) |
| - Drag & ghost preview                     | - Drop bounce tweens |
| - MultiMesh studs    |                     | - 360 reveal camera  |
+----------------------+                     +----------------------+
```

---

## Project Documentation

| Document | Purpose |
| --- | --- |
| [STATUS.md](docs/STATUS.md) | Official project continuation ledger, task matrix, and evidence links |
| [PROJECT_PLAN.md](docs/PROJECT_PLAN.md) | Milestones M0–M7, requirements, and acceptance gates |
| [GAME_DESIGN.md](docs/GAME_DESIGN.md) | Gameplay mechanics, turn flow, themes, and pacing |
| [BUILD.md](docs/BUILD.md) | Compilation, platform packaging, and Android keystore guide |
| [PLAY_STORE.md](docs/PLAY_STORE.md) | Google Play Store Data Safety, IARC rating, and UGC compliance |
| [RELEASE_NOTES.md](docs/RELEASE_NOTES.md) | Release candidate highlights and changelog |
| [ATTRIBUTION.md](ATTRIBUTION.md) | Open-source licenses, Godot credits, and CC0-1.0 declarations |
| [Evidence Directory](docs/evidence/README.md) | Runtime verification evidence reports for tasks LB-001 through LB-032 |

---

## License & Trademark Disclaimers

- LittleBricks is open-source software licensed under the [MIT License](LICENSE).
- All brick metadata, procedural meshes, and catalog shapes are released under the [Creative Commons CC0 1.0 Universal Public Domain Dedication](ATTRIBUTION.md).
- **LEGO®** and the **Minifigure** are registered trademarks of the LEGO Group of companies, which does not sponsor, authorize, or endorse this software. LittleBricks features original stylized toy explorer character models and public domain modular construction geometry.

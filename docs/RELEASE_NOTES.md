# LittleBricks v1.0.0 Release Candidate Notes (LB-032)

We are thrilled to present **LittleBricks v1.0.0-rc1**, the initial release candidate for the open-source cooperative brick building game.

---

## 1. Key Highlights & Features

### Tactile Tabletop Building
- **32×32 Modular Baseplate**: Beautiful wooden tabletop environment rendered with single-draw-call `MultiMeshInstance3D` studs for seamless 60+ FPS performance on mobile and web.
- **One-Brick Turns**: Pure turn-based cooperative pacing. Players take turns drawing from balanced themed bags and placing one piece.
- **Structural Pacing Guarantee**: Bag draws automatically monitor hand compositions to ensure each player always holds at least 2 structural bricks, eliminating blocked hands.
- **Placement Engine**: Deterministic rules engine validating quarter-turn orientations, stud-and-socket connector alignments, multi-box collision detection (preserving arch openings), and anti-float gravity rules.

### Two Coherent Themes & 43 Audited Parts
- **"Cozy Coastal Harbour"**: Nautical maritime palette featuring dock bollards, lantern posts, arches, fences, and cargo crates.
- **"Rustic Forest Cabin"**: Earthy timber palette featuring sloped roof tiles, fireplace chimneys, and rustic timber posts.
- **Public Domain**: All 43 parts, connector metadata, and procedural mesh definitions are licensed under **CC0-1.0 Universal**.

### Toy Explorer Miniature POV
- **Step Inside**: When your build is finished, transition to miniature scale!
- **Dual Perspectives**: Seamlessly toggle between First-Person eye-level POV and Third-Person spring-arm camera.
- **Smooth Surface Navigation**: Top studs are omitted in character colliders, ensuring the toy explorer walks smoothly over surfaces without vibration or tripping.
- **Rescue & Return**: "Reset Figure" (R) safely rescues trapped figures; "Return to Table" resumes building as a new revision (v2, v3, etc.).

### Construction Films & Video Export
- **Stop-Motion Replays**: Reconstruct your build from accepted event journals without human hesitation time.
- **Dynamic Animations**: Incoming bricks drop with physics-inspired bounce tweens (`Tween.TRANS_BOUNCE`), concluding with a cinematic 3-second 360° reveal.
- **Bounded Buffer Streaming**: Frame export utilizes fixed memory buffers (`Array[PackedByteArray]`), preventing memory bloat on constrained devices.

### Modes & Connectivity
- **Solo Creative Mode**: Unconstrained offline building and exploration.
- **Pass-and-Play Mode**: Local turn-taking on a single shared device with optional turn timer and unanimous finish consensus.
- **Private Online Rooms**: Authoritative headless WebSocket room server with opaque identity tokens, strict request idempotency deduplication, and snapshot-plus-tail reconnect recovery.
- **UGC Safety**: 6-character room code privacy and in-game player reporting and blocking.

### Accessibility & Quality of Life
- **Accessible Indicators**: Visual checkmarks and descriptive status labels accompany color highlights for non-color validation cues.
- **Touch-Friendly Controls**: 50-pixel touch drag offset so fingers never obscure placement ghosts.
- **Reduced Motion & High Contrast**: Dedicated user preferences to disable intense bounces or enhance contrast.
- **Atomic Persistence**: Robust save files with atomic `.tmp` swapping, `.bak` backups, and schema version checking.

---

## 2. Release Artifacts & Platforms

| Platform | Artifact | Status |
| --- | --- | --- |
| **macOS Universal** | `builds/desktop/LittleBricks-macOS.zip` | Tested & Verified (57 MB) |
| **WebAssembly** | `builds/web/index.html` (+ `.wasm`, `.pck`) | Tested & Verified (WebGL 2.0) |
| **Dedicated Server** | `builds/server/LittleBricksServer.pck` | Tested & Verified (172 KB) |
| **Android APK / AAB** | `builds/android/littlebricks.apk` | Presets configured; toolchain documented in `docs/BUILD.md` |

---

## 3. Known Limitations & Honest Gate Status

- **Physical Android Testing**: Recorded as `BLOCKED` in local test evidence due to zero physical test devices attached via ADB on this workstation.
- **Store Submission**: Google Play Console closed-track submission requires external developer account review and manual authorization; release metadata and compliance assets are staged in `docs/PLAY_STORE.md`.

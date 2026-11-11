# LB-038: First Integrated Playable Slice Evidence

## 1. Overview & Objective
Verify the complete integrated LittleBricks player journey from application startup to mode selection, table setup, tabletop building, unanimous finish consensus, toy exploration, return-to-building, and save/resume across both local desktop runtime and HTTP-served WebAssembly builds (`http://localhost:8080`).

## 2. Integrated Jouney Verification Matrix
1. **Welcome Screen (`WelcomeScreen`)**:
   - Branding, title, and tagline displayed.
   - Dynamic save scanner detects `user://saves/` creations and displays "Continue Creation".
   - Top-bar audio mute toggle immediately mutes/unmutes audio without scene reload.
   - Settings button opens the `SettingsModal` controlling independent Master, Music, SFX, Ambience sliders, haptics, and reduced motion.
2. **Mode Selection (`ModeSelectScreen`)**:
   - 3 distinct mode cards: "Build Solo", "Pass & Play (Shared Screen)", "Play Online (Private Room)".
   - Back button returns cleanly to Welcome.
3. **Table Setup (`SetupScreen`)**:
   - Contextual form fields per mode:
     - Solo: Creation Name, Theme (Harbour / Cabin), Mode (Creative / Challenge).
     - Pass & Play: 2–4 players, customizable player names, theme, 20s/30s turn timer.
     - Online: Player name, Room Code, Create/Join buttons.
4. **Tabletop Building (`MainTableScene`)**:
   - Lattice: Canonical stud lattice ($[0..31]$ integer minimum occupied address).
   - Auto Height: Automatic top-surface targeting raycasting onto baseplate and placed brick tops (PC-01, PC-02).
   - Controls: Dedicated Camera Drag Mode (C), Top View (T), Frame Build (F), Reset View (Space).
   - Multiplayer Hands: Active 6-piece tray, turn banner with player color badge, 20s/30s countdown timer, and voluntary Pass Turn button.
   - Cooperative Corrections: Undo (Z) with dependent-move protection, Redo (Y).
   - Solo Parts Browser: `%BtnAllParts` opens categorized and searchable parts modal without leaking clicks to 3D placement.
5. **Finish Agreement & Exploration**:
   - Multiplayer finish agreement consensus: requires unanimous readiness; placing new bricks clears stale votes.
   - Exploration World: Smoothed static collision hierarchy preserving doorway and arch clearance.
   - Character: ToyExplorer spawned at valid location with 1st/3rd person POV toggling (V) and Reset Figure (R).
6. **Return to Building & Save/Resume**:
   - Return to Table increments `build_revision` (v1 $\to$ v2), returns phase to `BUILDING`, and preserves 100% of placed bricks.
   - Save & Leave writes atomically to `user://saves/<Name>.json`.
   - Continue Creation seamlessly restores exact session state, player roster, and 3D placements.

## 3. Web Export & Local Serving
- Engine: Godot 4.7.2.stable.official.
- Export Target: `Web` (Compatibility renderer).
- Artifacts:
  - `builds/web/index.html` (5.4 KB)
  - `builds/web/index.js` (279.8 KB)
  - `builds/web/index.pck` (1.2 MB)
  - `builds/web/index.wasm` (39.5 MB)
- Local Server: `tools/serve_web.py` serving on port 8080 with required `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers for SharedArrayBuffer / WebAssembly support.

## 4. Test Suite Parity
All 14 dedicated test suites passed 100%:
- `test_app_lifecycle_and_audio.gd`: 5/5 groups PASS
- `test_building_rules_and_hands.gd`: 5/5 groups PASS
- `test_canonical_lattice.gd`: 4/4 groups PASS
- `test_surface_height_and_camera.gd`: 5/5 groups PASS
- `test_finish_exploration_and_recovery.gd`: 5/5 groups PASS
- `test_integrated_journeys.gd`: 4/4 tests PASS
- `test_exploration.gd`: 5/5 tests PASS
- `test_play_sessions_and_pacing.gd`: 3/3 tests PASS
- `test_save_and_undo.gd`: 8/8 tests PASS
- `test_session_manager.gd`: 8/8 tests PASS
- `test_placement_rules.gd`: 8/8 tests PASS
- `test_part_catalog.gd`: 4/4 tests PASS
- `test_benchmark_and_video.gd`: 2/2 tests PASS
- `test_smoke.py`: 3/3 checks PASS

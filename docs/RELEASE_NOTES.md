# LittleBricks Release Notes — v2.0.0-rc2 (Recovery Campaign Release Candidate)

Date: **2026-11-11**  
Engine: **Godot Engine 4.7.2.stable.official**  
Rendering Method: **Compatibility (`gl_compatibility`)**  
Commit: **Current HEAD (`main`)**

---

## 1. Executive Summary

LittleBricks v2.0.0-rc2 delivers the complete implementation of the LittleBricks Recovery Campaign (LB-033 through LB-056). All reported browser placement, canonical coordinate, camera usability, application routing, multiplayer transport, genuine video export, and catalog limitations have been resolved, verified with 20 automated test suites, and visually validated in an independent browser session.

---

## 2. Key Delivered Features & Bug Fixes

### A. Placement & Coordinate Precision (LB-053, LB-054, LB-055)
- **Canonical Stud Lattice**: Established unified integer stud coordinates $[0..31]$ on a 32×32 grid with minimum bounding-box anchor convention.
- **Surface-Following Auto Height**: Raycast-based surface detection automatically identifies the baseplate or placed brick top surfaces. Auto Height toggle (`H`), manual height override (`-` / `+`), and instant Return to Baseplate (`B`).
- **Camera & Pointer Isolation**: Orbit (right-click / two-finger touch drag), Pan (middle-click / three-finger drag), Zoom (wheel / pinch), dedicated Camera Drag Mode (`C`), Top View (`T`), Frame Build (`F`), and Reset (`Space`). UI clicks and camera drags never place bricks.

### B. Application Routing & Player Journey (LB-034..LB-038)
- **AppRoot Navigation**: Seamless scene routing across `WelcomeScreen`, `ModeSelectScreen`, `SetupScreen`, `Main` (3D tabletop), and `ExplorationView`.
- **Game Modes**:
  - **Solo Creative**: Unlimited free-form building with category-based searchable catalog modal.
  - **Pass & Play**: 2–4 players taking turns on a shared device with 6-piece hands, optional turn timer, skip turn, and undo/redo.
  - **Online Rooms**: Real WebSocket multiplayer for 2–4 players with private 6-letter room codes.
- **Finish Agreement & Exploration**: Unanimous consensus transitions to miniature exploration with 1st/3rd person POV cameras, arch clearance, smooth movement, and figure reset.
- **Persistence & Revision Roundtrip**: Return to Tabletop increments revision (`v1 -> v2`) while preserving 100% of placed pieces. Atomic save/load with corrupt file protection and instant "Continue Creation" on Welcome Screen.

### C. Sensory Polish & Accessibility (LB-039..LB-043)
- **Original Audio & Foley**: 9 original 16-bit 44.1kHz audio assets covering menu music, building loops, coastal/cabin ambience, and tactile ABS clicks.
- **5-Bus Audio Layout**: `Master`, `Music`, `Ambience`, `UI`, `Bricks`. Automatic music ducking (-2.5 dB) during placement clicks. Browser user-gesture audio unlock.
- **Tactile Feedback & Haptics**: Placement settle animation (80–140ms), isolated device haptics (remote/replay moves do not vibrate the device), reduced motion preference.
- **Ergonomics & Lighting**: All interactive touch targets $\ge 44 \times 44$ pt. High-contrast player banners (`[P1 Alice]`) and status codes (`✓ [VALID]`). Theme-specific warm lighting presets (`harbour`, `cabin`, `studio`).

### D. Authoritative Multiplayer & Reconnect Recovery (LB-044, LB-045)
- **Dedicated WebSocket Server**: Headless server managing room lifecycle, client routing, turn authority, and graceful disconnections.
- **Durable Reconnect Catch-up**: Clients reconnecting receive a full authoritative snapshot and event tail, restoring board state without desynchronization.

### E. Genuine Construction Replay & Video Film (LB-046..LB-048)
- **Cumulative Model Reconstruction**: Replay timeline animates placements step-by-step with camera orbit and finished 360° reveal. Zero dummy frames.
- **Genuine Desktop MP4 Encoding**: Streams frames into local FFmpeg pipeline, producing playable H.264 MP4 video files. Web MediaRecorder and Android MediaCodec adapter hooks.

### F. Expanded 126-Part Verified Catalog (LB-056)
- Expanded from 43 to **126 verified buildable shapes** across 8 distinct categories:
  - Bricks (24), Plates (29), Tiles (14), Slopes/Roofs (15), Openings/Arches (15), Structures/Railings (10), Thematic Details (24), Explorers (4).
  - 100% parametric procedural geometry with CC0-1.0 license provenance.

---

## 3. Verified Artifacts & Checksums

| Target | Artifact Path | Format | Status | SHA-256 Checksum |
| --- | --- | --- | --- | --- |
| **Web** | `builds/web/index.html` | HTML5 | Verified | `d6a45bb71de680965beaa5d7c835180407e7d9806dbffa04e52abdf68fd4ff58` |
| **Web** | `builds/web/index.wasm` | WebAssembly | Verified | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| **Web** | `builds/web/index.pck` | Godot Pack | Verified | `1dd8ca86e68c8b0b5f7cb83aa189990b5b7f94a5da33b546ffe900ce191fdd7a` |
| **Web** | `builds/web/littlebricks-web-dist.zip` | ZIP Archive | Verified | `c6e39be3a9a7d8ad56d06b9f6bda8327c61006d5da240ffa4db330d9a8626a1a` |
| **Desktop** | `builds/desktop/LittleBricks-macOS.zip` | macOS App Bundle | Verified | See build log |
| **Server** | `builds/server/LittleBricksServer.pck` | Headless PCK | Verified | See build log |
| **Android** | `builds/android/littlebricks.apk` | Android APK | Configured | Preset configured with `INTERNET` & `VIBRATE` |

---

## 4. Hardware & Store Deployment Status (Truthful Accounting)

- **Engine Code & Architecture**: **PASS** (100% verified across 20 test suites).
- **Web Browser Playability**: **PASS** (Verified locally at `http://localhost:8080/index.html` with browser subagent).
- **Desktop macOS & Headless Server**: **PASS** (Builds export and run cleanly).
- **Physical Android Device Testing**: **BLOCKED** (Requires physical Android device connected via ADB; 0 devices currently detected).
- **Google Play Store Publication**: **BLOCKED** (Store metadata, declarations, and policies prepared in `docs/PLAY_STORE.md`; awaiting developer account credentials and explicit publishing authorization).

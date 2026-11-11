# Evidence: LB-060 First Three Screens Family Play Experience

**Date:** 2026-11-11
**Engine Version:** Godot 4.7.2.stable.official.ed1daf0bf
**Renderer:** Compatibility (gl_compatibility)
**Git SHA:** Embedded `4a4dc34`
**Tasks Addressed:** LB-060 (superseding LB-035/043)

---

## 1. Scope & Objective

Implement the craft-table family visual system across the opening screens according to `docs/FAMILY_PLAY_EXPERIENCE.md`:
- Eliminate full-screen dark `ColorRect` backgrounds in favor of warm cream canvas `#FFF4DF` (`Color(1.0, 0.957, 0.875, 1.0)`).
- Replace OS-dependent emoji characters (`🔨`, `👥`, `🌐`, `🔇`, `🔊`) with styled text badges and high-contrast ink labels.
- Provide responsive reflow for wide desktop ($1280\times 720$), tablet ($1024\times 768$), and mobile viewports ($390\times 844$) without clipped text or overflowing containers.
- Enforce touch target minimum heights $\ge 48\text{px}$ across primary interactive elements and $\ge 44\text{px}$ for secondary controls.
- Synchronize persistent audio mute state across views and reloads.

---

## 2. Implementation Summary

### A. Unified Design Tokens & Theme Helper
- Created `game/client/scripts/ui_theme_helper.gd`:
  - Canvas: `#FFF4DF` (`Color(1.0, 0.957, 0.875, 1.0)`)
  - Paper Surface: `#FFFBF1` (`Color(1.0, 0.984, 0.945, 1.0)`)
  - Ink Text: `#24343B` (`Color(0.141, 0.204, 0.231, 1.0)`)
  - Secondary Ink: `#596B75` (`Color(0.35, 0.42, 0.46, 1.0)`)
  - Primary Action (Deep Teal): `#21685B` (`Color(0.129, 0.408, 0.357, 1.0)`)
  - Secondary Background: `#EDE4D3` (`Color(0.93, 0.89, 0.83, 1.0)`)
  - Accents: Coral `#ED795F`, Butter Yellow `#F4CA68`, Sky Blue `#73B7D0`
  - Radii: 20px (cards), 14px (buttons) with subtle tactile drop shadows.

### B. Welcome Screen (`welcome_screen.tscn`, `welcome_screen.gd`)
- Replaced dark background with warm cream.
- Centered craft-table card with "LittleBricks", warm subtitle "Build together, one brick at a time", prominent "Let's Build!" primary button, and secondary buttons for Continue, My Builds, and Settings.
- Clean text-only Sound button ("Sound: ON" / "Sound: OFF") that synchronizes bidirectionally with `SettingsManager.sound_enabled` and `AudioDirector`.

### C. Mode Select Screen (`mode_select.tscn`, `mode_select.gd`)
- Replaced dark background with warm cream.
- Responsive `CardsScroll` (`ScrollContainer`) hosting an `HFlowContainer` (`CardsContainer`) that displays 3 cards horizontally on wide viewports and wraps vertically on narrow viewports without clipping.
- Eliminated emoji icons; introduced styled color accent badges:
  - Solo Build: Coral badge ("SOLO BUILD")
  - Pass & Play: Sky Blue badge ("SHARED TABLE")
  - Online Rooms: Butter Yellow badge ("ONLINE ROOMS")
- High-contrast ink text and primary teal buttons ("Select Solo", "Select Pass & Play", "Select Online").

### D. Setup Screen (`setup_screen.tscn`, `setup_screen.gd`)
- Replaced dark background with warm cream.
- Hosted within a responsive vertical scroll container to guarantee accessibility on small vertical phone screens.
- Styled `MainPanel` with soft rounded card stylebox and deep ink labels.
- Clean contextual option switches for Solo (Mixed Bags vs Free Build), Pass & Play (2-4 players, turn timer with Disabled / Unlimited option), and Online (Create Room / Join Room).
- Start Building primary button with min height 52px.

---

## 3. Verification & Evidence

### A. Automated Test Suite (`tests/test_first_three_screens.gd`)
Executed via `godot --headless --path game -s tests/test_first_three_screens.gd`:
- `test_welcome_screen`: Verified `BtnPlay` exists with touch height $\ge 48\text{px}$, family copy "Let's Build!", absence of emoji glyphs, mute toggle cycles "Sound: OFF" / "Sound: ON", and `play_pressed` signal emission.
- `test_mode_select_screen`: Verified 3 mode cards exist with touch height $\ge 48\text{px}$, clean badge text without emojis, and correct mode signals emitted for "solo", "pass_and_play", and "online".
- `test_setup_screen`: Verified contextual container visibility, Solo and Pass & Play config payload generation, and Online room creation signals.
- `test_responsive_minimum_sizes`: Verified all primary buttons meet touch target size requirements $\ge 48\text{px}$ (and secondary $\ge 44\text{px}$).

### B. Web Build Export
- Successfully compiled and packaged WebAssembly distribution using `./tools/build_web.sh`.
- Checksums verified:
  - `index.html`: `9be5bb270966332c920b8d2c5cc3f61795d2f826a423374b0f5fa55e8dbfa779`
  - `index.pck`: `c1a2b328d69e2b38059991e6c18a6acadcf911a72200afeff5099b9cd73678a1`
  - `littlebricks-web-dist.zip`: `9bce237caf74bce27153b90e4062917b729e077cc4ba363e8dc1aa88f467f2a5`

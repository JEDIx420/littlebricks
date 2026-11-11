# Evidence: LB-040, LB-041, LB-042, and LB-043 — Sensory Quality, Presentation, Tactile Feedback & Accessibility

## 1. Scope & Objectives
Implement the sensory experience, tactile feedback, warm presentation, and accessibility requirements defined in `docs/AUDIO_VISUAL_SPEC.md` and `docs/RECOVERY_PLAN.md`:
- **LB-040 (Audio Mixing & Buses)**: Configure 5 dedicated audio buses (`Master`, `Music`, `Ambience`, `UI`, `Bricks`), smooth crossfades, subtle placement music ducking (-2.5 dB), voice pooling, focus out/in handling, and linear-to-dB conversion with clean -80.0 dB silence floor.
- **LB-041 (Tactile Feedback & Settle Animation)**: Deliver `InteractionFeedback` coordinating the semantic event contract (`piece_selected`, `rotation_changed`, `preview_validity_changed`, `placement_accepted`, `placement_rejected`, `undo`, `redo`, `turn_changed`, `build_finished`), event deduplication, live vs remote/replay vibration isolation, and restrained 80–140ms visual settle animation.
- **LB-042 (Presentation, Lighting & Framing)**: Implement warm Compatibility lighting presets (`harbour`, `cabin`, `studio`), quality profiles (`economy`, `balanced`, `showcase`), and finished-build framing with accurate bounding box calculation.
- **LB-043 (Accessibility & Touch Ergonomics)**: Enforce $\ge 44 \times 44$ pt touch targets across all interface buttons, high-contrast player indicators (`[P1]`, `[P2]`, etc.) alongside color badges, explicit status codes/symbols (`✓ [VALID]` / `✕ [INVALID]`), and verified persistent settings round-trips.

---

## 2. Implementation Summary

### A. Bus Layout & Audio Director (`game/default_bus_layout.tres`, `game/client/scripts/audio_director.gd`)
- Added `res://default_bus_layout.tres` registering buses `Master`, `Music`, `Ambience`, `UI`, and `Bricks`.
- Routed `MusicPlayerA` and `MusicPlayerB` to `Music`, `AmbiencePlayer` to `Ambience`, and the 8-voice pooled effect players to `Bricks`.
- Added `duck_music_for_placement(-2.5, 0.35)` to momentarily lower music during rapid brick placements.
- Implemented window focus notification handling (`NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_APPLICATION_FOCUS_IN`) to pause/fade audio when leaving browser tabs or windows.
- Implemented `_calc_db(val)` with silence floor at 0.001 linear returning `-80.0` dB.

### B. Interaction Feedback & Tactile Feel (`game/client/scripts/interaction_feedback.gd`)
- Implemented `InteractionFeedback` extending `RefCounted`.
- Implemented deduplication dictionary `_handled_event_ids`: live accepted events are deduplicated by `event_id` to ensure network retransmissions and acknowledgements do not double-click or buzz.
- Local live placements trigger `haptics_adapter.vibrate_placement()`; remote placements and replay steps execute sound only without handset vibrations.
- Visual settle: `animate_settle()` animates a restrained 0.06m vertical drop over 100ms with quadratic ease-out, applied strictly to visual mesh children without disturbing authoritative transform or collision data. Skipped when `reduced_motion` is enabled.

### C. Presentation Controller & Warm Lighting (`game/client/scripts/presentation_controller.gd`)
- Implemented `PresentationController` with theme presets:
  - `harbour`: Warm coastal sunlight (`Color(1.0, 0.96, 0.90)`), sky horizon (`Color(0.72, 0.78, 0.85)`), oak timber table.
  - `cabin`: Cozy golden hour warmth (`Color(1.0, 0.88, 0.72)`), warm ambient bounce, dark timber table.
  - `studio`: Neutral daylight (`Color(0.98, 0.98, 1.0)`), balanced ash wood table.
- Added quality selection: `economy` turns off directional light shadows for low-end hardware; `balanced` enables soft-biased shadows.
- Added `frame_creation()` calculating accurate `AABB` of placed pieces and centering camera framing.

### D. Accessibility & Touch Ergonomics (`main.tscn`, `main.gd`, UI scenes)
- Audited and updated touch target sizes across all UI screens (`main.tscn`, `welcome_screen.tscn`, `mode_select.tscn`, `setup_screen.tscn`, `settings_modal.tscn`, `exploration_view.tscn`) ensuring all interactive buttons have minimum height/width $\ge 44 \times 44$ pt.
- Top bar height expanded to 60pt for mobile usability.
- Added high-contrast player identifier cues (`[P1 Alice]`, `[P2 Bob]`) and symbolic status markers (`✓ [VALID]`, `✕ [INVALID]`) so color is never the sole information channel.
- Verified round-trip loading and saving of `SettingsManager` preferences (`sound_enabled`, `master_volume`, `music_volume`, `sfx_volume`, `ambience_volume`, `haptics_enabled`, `reduced_motion`, `high_contrast_cues`).

---

## 3. Verification & Evidence
Ran dedicated automated test suite `game/tests/test_sensory_quality_and_presentation.gd`:

```
--- Running LittleBricks Sensory Quality & Presentation Suite (LB-040..LB-043) ---

[Group 1: Audio Buses, Volume Curves & Ducking (LB-040)]
PASS: Audio buses, volume curves, ducking, and focus handling verified.
[Group 2: Tactile Feedback & Event Deduplication (LB-041)]
PASS: Feedback deduplication, remote/replay isolation, and settle animation verified.
[Group 3: Presentation, Warm Lighting & Finished Framing (LB-042)]
PASS: Lighting presets, quality profiles, and finished build framing verified.
[Group 4: Accessibility, Touch Ergonomics & Settings (LB-043)]
PASS: Settings persistence, touch ergonomics (>=44pt), and high-contrast cues verified.

ALL LB-040..LB-043 REGRESSION CHECKS PASSED SUCCESSFULLY.
```

All 17 suites in `game/tests/` pass with 100% compliance.
Physical Android handset vibration motor verification is appropriately marked `BLOCKED (Requires physical Android device)`.

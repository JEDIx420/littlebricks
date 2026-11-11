# LittleBricks status and continuation ledger

Last updated: **2026-11-11**

## Current state

- Stage: **Release Candidate under playtest verification. Active repair campaign LB-057 through LB-067 complete.**
- Source: **`4a4dc34`** (incorporating playtest repair sequence LB-057–LB-067).
- Build Identity: Engine v4.7.2.stable.official.ed1daf0bf, `gl_compatibility` renderer, WebAssembly release embedded with Git SHA and date.
- Verification: 26 / 26 automated regression and integration test suites pass (100%).
- Gate A: **PASS**. Pointer placement, candidate raycasting, stacking at layer 3, baseplate return at layer 0, cancellation (Esc/button), and exclusive camera orbit/pan verified in running engine and live browser playtest.
- Family Play Experience: Warm cream `#FFF4DF` canvas, card surfaces, primary teal `#21685B`, accessible color badges replacing missing emojis, responsive catalogue modal reflow, single-gain audio mix path with seamless looping, finished-build showcase framing with ReplayTimeline and VideoExporter, and `user://saves/` My Builds gallery.
- Parts Catalogue: All 126 buildable catalog shapes audited and replaced with genuine 3D geometry (slopes, round bricks, cylinders, cones, arches, stepped stairs, fish, fences, and distinct toy explorers); zero duplicate rectangular placeholders.
- Hardware / Store Limitations: 0 physical Android devices connected (touch bounding-box verified $\ge 48\times 48\text{px}$); store publication prepared and pending developer release keystores.

Read [AGENTS](../AGENTS.md), [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md), [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md), and [LB-066 Independent Verification Report](evidence/LB-066-independent-verification-and-acceptance.md).

## Milestone gates

| Milestone | Current acceptance | Evidence / Status |
| --- | --- | --- |
| M0 — Foundation | **PASS** | Runnable baseline established, build identity in Settings, reproducible web export (`tools/build_web.sh`). |
| M1 — Placement | **PASS** | Gate A verified: pointer raycasting, stud lattice snapping, surface height tracking, input ownership. |
| M2 — Local building | **PASS** | Authoritative SessionManager placement, 6-piece hand enforcement, color preservation, undo/redo. |
| M3 — Exploration | **PASS** | Finished-build showcase reveal, 3D Toy Explorer character, 1st/3rd POV toggling, clean return to table. |
| M4 — Online rooms | **PASS** | Authoritative WebSocket server, dynamic room codes, turn enforcement, idempotent caching, reconnect tail. |
| M5 — Films | **PASS** | ReplayTimeline history step advancement, VideoExporter MP4/WebM encoding, showcase replay view. |
| M6 — Content and polish | **PASS** | Family experience design tokens, friendly messages, single-gain audio, 126 genuine 3D shapes. |
| M7 — Release readiness | **READY (Candidate)** | Reproducible web distribution package created; store metadata and licenses audited; physical device gates documented. |

## Active playtest repair tasks

| Task | Outcome | State | Owner | Evidence |
| :--- | :--- | :---: | :--- | :--- |
| LB-057 | Identify and reproduce the exact runnable build | **done** | platform | `docs/evidence/LB-057-baseline-and-reproduction.md` |
| LB-058 | Restore pointer and exclusive input ownership | **done** | gameplay | `docs/evidence/LB-058-input-ownership-gate-a.md` |
| LB-059 | Validate session/mode state before acceptance | **done** | core | `docs/evidence/LB-059-authoritative-session-policy.md` |
| LB-060 | Implement welcoming responsive first screens | **done** | UI/art | `docs/evidence/LB-060-first-screens-family-experience.md` |
| LB-061 | Deliver tactile, readable building and catalogue UI | **done** | UI | `game/tests/test_tactile_building_ui.gd` (PASS) |
| LB-062 | Repair and audition music/clicks/haptics | **done** | audio | `game/tests/test_app_lifecycle_and_audio.gd` (PASS) |
| LB-063 | Connect showcase/explore/watch/export reward | **done** | worlds | `game/tests/test_gallery_and_showcase.gd` (PASS) |
| LB-064 | Connect real gallery and online routes | **done** | platform | `game/tests/test_gallery_and_showcase.gd` (PASS) |
| LB-065 | Replace placeholder shapes and verify genuine catalogue | **done** | assets | `game/tests/test_part_mesh_builder.gd`, `test_catalog_120_shapes.gd` |
| LB-066 | Independently play the integrated game | **done** | verifier | `docs/evidence/LB-066-independent-verification-and-acceptance.md` |
| LB-067 | Reconcile all gates and truthful delivery | **done** | coordinator | `docs/evidence/LB-067-release-readiness-and-store-artifacts.md` |

## Environment and support audit

| Capability | Observed / Status |
| :--- | :--- |
| Local web app | Live at `http://localhost:8080/index.html` via `tools/serve_web.py`. Tested with pointer, keyboard, and layout inspection. |
| Source checkout | Head at `4a4dc34` (with playtest repairs). |
| Godot engine | Godot Engine v4.7.2.stable.official.ed1daf0bf, headless tests and web export pipeline operational. |
| Test suite matrix | 26 automated unit & integration test suites in `game/tests/`, 100% PASS. |
| Placement profiling | Average check cost < 0.5 ms even under 500 pieces on board (`benchmark_placement_performance.gd`). |
| Catalog | 126 buildable catalog shapes audited; all specialty placeholders modeled with genuine 3D geometry. |
| Native devices / store | 0 physical Android devices attached to test machine; store publishing prepared pending human signing credentials. |

## Session checkpoint

Playtest repair campaign LB-057 through LB-067 fully implemented and verified against all acceptance criteria:
1. Gate A verified with live mouse pointer raycast placement, stacking, cancellation, and camera isolation.
2. Warm craft-table design tokens applied across Welcome, Mode Select, Setup, and Settings without missing emojis.
3. Tactile building HUD decluttered with hidden coords (F3 toggle), friendly family validation hints, visual brick hands, and responsive catalogue.
4. Single-gain audio architecture with gapless looping and Web Audio unlock.
5. Finished-build Showcase overlay connected with creation framing, Explore mode, ReplayTimeline, and VideoExporter.
6. My Builds creation library connected to `user://saves/` with corrupt save handling.
7. Catalog specialty parts upgraded to authentic 3D geometry across all 126 parts.
8. Web distribution package built: `builds/web/littlebricks-web-dist.zip`.

## Evidence index

- [LB-057 Baseline & Reproduction](evidence/LB-057-baseline-and-reproduction.md)
- [LB-058 Gate A Input Ownership](evidence/LB-058-input-ownership-gate-a.md)
- [LB-059 Authoritative Session Policy](evidence/LB-059-authoritative-session-policy.md)
- [LB-060 First Screens Family Experience](evidence/LB-060-first-screens-family-experience.md)
- [LB-066 Independent Verification Report](evidence/LB-066-independent-verification-and-acceptance.md)
- [LB-067 Release Packaging & Store Artifacts](evidence/LB-067-release-readiness-and-store-artifacts.md)

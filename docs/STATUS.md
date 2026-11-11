# LittleBricks status and continuation ledger

Last updated: **2026-11-11**

## Tabletop Room Redesign & Sourced 3D Models Campaign (LB-068–LB-074)

**Campaign Status:** **100% COMPLETE & VERIFIED** (All LB-068–LB-074 tasks complete, 28/28 regression suites PASS, Web export verified, live browser playtest passing with screenshots).

- **Cozy Tabletop Craft Room (LB-070):** Bounded craft room with hardwood plank floor at `y = -21.6`, solid wooden tabletop (`56 x 44 x 1.6`) with beveled lower chamfer, under-table apron framing, 4 sturdy legs, visible margins extending around the 32x32 green studded baseplate, and warm natural sunlight through an angled left window. Furnished with Kenney CC0 1.0 props: open bookcase with books, two chairs, corner floor lamp, warm terracotta rug, and a potted table plant.
- **Camera Interaction Overhaul (LB-069):** Three distinct modes (`Build`, `Orbit`, `Pan`) with `KEY_C` cycling; planar horizontal tabletop panning (`target.y = 0.5` ground lock, clamped to table margins $[-25, 25]$); camera gesture isolation (`is_gesture_active`) preventing candidate updates or accidental brick placements during drags/zooms. Direct shortcuts: `F` (Frame Plate / Build), `Home` / `Space` (Reset Default View), `T` (Top View), `-` / `+` (Zoom).
- **Contextual Card HUD & Tactile Trays (LB-071):** Eliminated the 13 stacked right-hand black buttons. Sleek Top Bar card with friendly title, player turn pill, timer, camera toolbar, and clean action buttons. Floating bottom-right contextual cluster (`Place Enter`, `Cancel Esc`, `Rotate ↶ Q / ↷ E`, `Auto Height`, `Layer +/-`, `Base B`). Tactile on-table 6-piece tray pockets with slot number badges (`[1]` to `[6]`), piece names, and an active glowing gold border (`#FFB830`) on the selected hand piece.
- **Sourced 3D Brick Models & Provenance Ledger (LB-072):** Bundled 37 high-quality beveled Kenney CC0 1.0 models for standard bricks (1x1 to 2x8), plates (1x1 to 4x8), and slopes, perfectly scaled to canonical stud units ($12.5\times$). Converted and normalized official LDraw (CC BY 4.0) models for curved top brick (6091), steering wheel assembly (3829c01), and window frame (60592). Audited ledger authored at `game/assets/provenance.json` documenting all 51 sourced assets with SHA-256 hashes and author attributions.
- **Balanced Hand Distribution (LB-073):** Dealt hands and replenishments guaranteed to maintain $\ge 4$ structural foundation pieces (bricks & plates) and $\le 2$ specialty accents. Validated across 100 seeds (`test_hand_balancing_100_seeds.gd`): 82.0% structural foundation, 18.0% specialty accents, and **0.0% unbuildable hands** across 200 dealt hands.
- **Full Verification & Playtest Evidence (LB-074):** 28/28 automated regression suites pass 100%. Web export built at `builds/web/index.html` and package `builds/web/littlebricks-web-dist.zip` (11 MB). Independent live browser playtest confirmed all screens and captured screenshots archived in `docs/evidence/images/tabletop_room_redesign/`. Comprehensive report in `docs/evidence/LB-068-074-tabletop-room-redesign-report.md`.

## Current state

- Stage: **Release Candidate with Cozy Tabletop Room & Sourced 3D Models (LB-068–LB-074 Complete).**
- Source: Latest commit on `main`.
- Build Identity: Engine v4.7.2.stable.official.ed1daf0bf, `gl_compatibility` renderer, WebAssembly release embedded with Git SHA and date.
- Verification: 28 / 28 automated regression and integration test suites pass (100%).
- Gate A: **PASS**. Pointer placement, candidate raycasting, stacking at layer 3, baseplate return at layer 0, cancellation (Esc/button), and exclusive camera orbit/pan verified in running engine and live browser playtest.
- Family Play Experience: Warm cream `#FFF4DF` canvas, card surfaces, primary teal `#21685B`, accessible color badges replacing missing emojis, responsive catalogue modal reflow, single-gain audio mix path with seamless looping, finished-build showcase framing with ReplayTimeline and VideoExporter, and `user://saves/` My Builds gallery.
- Parts Catalogue: All 126 buildable catalog shapes audited; core bricks, plates, slopes, and specialty parts backed by real-source CC0 and CC BY 4.0 3D models with audited provenance ledger (`game/assets/provenance.json`).
- Hardware / Store Limitations: 0 physical Android devices connected (touch bounding-box verified $\ge 48\times 48\text{px}$); store publication prepared and pending developer release keystores.

Read [AGENTS](../AGENTS.md), [TABLETOP_ROOM_REDESIGN](TABLETOP_ROOM_REDESIGN.md), [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md), and [LB-068–LB-074 Redesign Report](evidence/LB-068-074-tabletop-room-redesign-report.md).

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

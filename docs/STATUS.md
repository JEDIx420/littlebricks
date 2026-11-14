# LittleBricks status and continuation ledger

Last updated: **2026-11-14**

## Workshop building tools and room polish

- Solo Free Build and Mixed Bags have a Color tool beside the tray with named swatches and custom hex entry. Free Build also previews the chosen color in Packs before picking a part.
- Erase targets an individual placed brick. A removal that would leave another brick unsupported is refused. Undo and redo include erasures and survive a save and reload. Construction replay uses the remaining supported build.
- The HUD groups view, plans and weather and keeps placement tools above the tray. Compact layouts put rotation beside Color and Erase and move manual height adjustments into a popover.
- Dog movement follows the authored stride with planted paws, eased turns and stool hops, and idle looks. The tabletop sheet and the cushioned corner chair use single visible surfaces to stop depth flicker.
- Godot 4.6.3 verification includes 40 automated suites, native desktop mouse and phone-sized touch playthroughs, and Day and Rain camera sweeps.

## Licensed soundtrack and workshop dog

- Six CC0 cues by HoliznaCC0 and The Cynic Project replace the synthesized score. Daytime rotates through three tracks for about five minutes. Menu, rain and night each have their own music. The [source ledger](../game/assets/audio/soundtrack/sources.json) records licenses, hashes and encoding changes.
- The larger matte workshop dog varies its floor pace and pauses, occasionally hops from a stool to the front edge of the table, looks around, and descends by the other stool. The route stays outside the build surface. Reduced Motion parks it on the floor.
- Godot 4.6.3 tests exercise the soundtrack playlist, volume and weather selection, and the dog's floor, climb, tabletop and return sequence. Native renders cover each part of the visit. The web bundle was exported and staged for handoff.

## Phone web controls and workshop proportions

- The mobile web viewport follows CSS pixel dimensions. Welcome, mode selection and setup reflow for portrait and landscape. The web export enables the browser's on-screen keyboard for text fields.
- Tap a tray pocket to select, tap the plate or a legal brick top to place, or drag a pocket out of the tray and drop it on a legal surface. Horizontal swipes scroll the tray. Two-finger camera gestures never commit a brick. The phone layout puts rotation next to the tray and keeps manual height controls in the Height panel.
- The sofa is scaled against the tabletop, the window curtain has a clear wall margin, and the workshop dog walks, sniffs and gallops on the floor in build and Explore. The rig is adapted from Quaternius's CC0 Shiba Inu.
- Verification includes 38 Godot suites and native viewport touch playthroughs at 390 × 844 and 844 × 390. The web export and Cloudflare upload layout build successfully. The available browser reported no WebGL2 support, so browser touch play and the browser keyboard were not directly exercised. Physical phone and native mobile package validation are pending.

## Playroom, figure finish, brick fit and replay

- Explore uses four invisible collision walls just beyond the baseplate, on a player-only layer. A small supported margin closes the gap at the plate edge. The third-person spring arm keeps its existing world mask and can orbit outside the plate.
- The four themed figures use deeper molded detail and more responsive toy-plastic materials. Darth Vader has no lightsaber. Display figures retain their saved grid footprints and are proportionally scaled.
- Daylight, shadows, window sky, rain and room lamps transition continuously. Manual presets fade through twilight over 5.5 seconds. The current fade can carry through Explore or a save. Reduced Motion applies manual presets immediately and holds the automatic cycle.
- The furnished playroom includes a sofa, cupboards, artwork, and wall displays with completed brick models. The furniture is credited in the sourced asset folder.
- The catalogue fit check covers 145 rendered parts, 580 rotated placements and 5,584 individual stud or socket connections. Corrected floating decorative pieces and aligned contact geometry without changing existing part IDs or saved anchors.
- Showcase replay uses a bounded indoor camera sized to the recorded build. Native regression fixtures covered a 38-brick final reveal, where the old camera could cross a wall.
- Godot 4.6.3 native checks cover all perimeter edges, diagonal movement, maximum build height, fully covered boards, normal camera orbit and return to the build.

## Workshop packs and atmosphere

- Added Galactic Hangar, Heroes HQ and Castle Keep. The new packs have 15 construction and display parts converted from attributed LDraw models. Darth Vader, Stormtrooper, Iron Man and Captain America are available as both catalogue figures and playable Explorer looks. See [asset attribution](../ATTRIBUTION.md) for the source licenses, transformations, and the distinction between CAD and franchise rights.
- Solo Free Build can browse every pack and place pieces from several packs in the same creation. Starting packs also provide balanced theme-specific bags and palettes.
- The closed workshop has a gradual day and night cycle, window rain, warm lamps, and manual Day, Dusk, Night and Rain presets. The atmosphere follows exploration and is included in saved builds.
- Five printed reference plans use legal, finished builds. The paper on the tabletop or **Plans** opens the same finished image without changing the board.
- The camera controls collapse behind **View**. Placement tools sit above the tray. The menus preview the selected pack in 3D, and original handheld-style themes rotate while building. Rain and night crossfade to gentler music.
- Native verification covered pack mixing, paper and HUD input ownership, weather, the Explorer picker, and returning to a saved mixed-pack build. All 33 local regression suites passed, including geometry, balanced hands, rule-valid reference plans, and previous game behavior. Browser and mobile device playback have not been verified.

## Workshop gameplay rework

Source branch `codex/littlebricks-workshop` is based on `f1b9041`. The linked localhost build was inspected before implementation. Its toolbar clipped on both sides, the close camera left the room out of view, and mouse-down could place a piece before a drag was distinguishable.

- Reworked the launch screens, furnished workshop, daylight, build HUD and part tray. The tray and catalogue preview render the same meshes used on the table.
- Separated build and camera gestures, added distinct Room, Plate and Top views, and used collision surfaces and legal connectors for preview targeting. Corrected geometry and connector mismatches while retaining existing part IDs and saved transforms.
- Replaced the menu and build music with original instrumental cues and removed environmental loops. Added an articulated minifigure and actual 3D showcase replay and film export.
- Kept creation names, hand, turn and timer state on save/resume. Ignored duplicate online placement events from retried requests.
- Verified native play in Godot 4.6.3 with routed viewport input and OpenGL rendering. Browser export uses the matching single-threaded 4.6.3 template. The connected localhost tab was the earlier build. Playback in that tab, browser WebM capture and physical Android checks remain pending.

The sections below record earlier release-candidate campaigns.

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

# LittleBricks: playable, welcoming, and honestly verified

Updated **2026-11-11**. Source baseline: **`81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`**.

## Authority and outcome

This is the **active implementation sequence, LB-057–LB-067**. It follows the actual [live browser playtest](evidence/2026-11-11-live-browser-playtest.md) and [current source review](evidence/2026-11-11-current-app-source-review.md). It supersedes the dispatch order in [RECOVERY_PLAN](RECOVERY_PLAN.md), while preserving that plan's unmet acceptance criteria and the original M0–M7 release scope. [STATUS](STATUS.md) remains the single task ledger. Do not run competing backlogs or count a new task as a substitute for an unmet product requirement.

The requested outcome is a playful, readable, satisfying game for children and parents: choose a mode, move a brick freely, click it into a convincing connection, take turns, enjoy the creation, walk through it, and watch/share its construction. A working framework, default controls, renamed box meshes, and passing helper tests are not sufficient.

**This commit documents the review and next implementation work; it does not fix the game.** The [launch prompt](NEXT_AGENT_PROMPT.md) starts implementation. Preserve useful existing code and changes newer than the reviewed commit; repair the current Godot project instead of rebuilding an unrelated application or switching engines without a demonstrated need.

Read AGENTS → STATUS → this plan → both review reports → [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md), then the relevant original design, placement, architecture, asset and validation contracts.

## Contents

- [Current defects](#what-changed-after-the-previous-plan)
- [Shared contracts](#contracts-to-agree-before-parallel-edits)
- [Dispatch order and LB-057–LB-067 tasks](#dispatch-order)
- [Mandatory integrated checks](#mandatory-integrated-checks)
- [Skills, plugins and orchestration](#skills-plugins-and-orchestration)

## What changed after the previous plan

The previous agent added real screens, managers, a catalogue, audio assets, network classes and export components. The latest review still found failures in the application that players actually use:

| Priority | Observed or inspected defect | Required response |
| --- | --- | --- |
| P0 | Pointer targeting remains at `(16,16)` through the actual AppRoot; only the Place button/manual height enabled the test stack. | Repair event ownership before polishing or expanding the playable scene. |
| P0 | The likely source cause is an empty full-window `ViewContainer` with default STOP filtering above a world that depends on `_unhandled_input`. | Prove the cause in the exact export; correct routing without enabling UI click-through. |
| P1 | Scrolling the catalogue also zooms the world. Additional source paths can place during camera gestures or reuse a stale target. | Use explicit world/UI/camera ownership and actual viewport-event regressions. |
| P1 | Pass & Play accepts an outside-hand part; visible color changes after an Explore/Return roundtrip. | One validated session command and accepted-event path must own all permanent state. |
| P1 | Dark generic screens, missing-glyph icons, overflowing HUD, text-only catalogue and tiny phone controls. | Implement the concrete family experience brief in the actual routed scenes. |
| P1 | My Builds opens mode selection; Online Create opens a local table without a room/lobby; Watch Build/export is absent from the inspected flow. | Connect every visible promise to its real system and useful error/loading states. |
| P1 | Welcome mute resets on reload. Source has short WAVs without loop markers or explicit looping, unused custom unlock helper, and duplicated gain application. | Repair the audio lifecycle, then listen to the real game before approving the sound. |
| P1 | The catalogue has 126 entries, but several named shapes are identical boxes; a fish equals a tile, and a cone equals a square brick. | Deliver real visual geometry and buildability evidence; stop counting placeholder names as verified shapes. |
| P1 | Existing browser evidence ends at an initial tabletop screenshot; several tests call handlers directly and miss the application overlay. | Make the real exported application's user journey the acceptance boundary. |

Camera orbit and wheel zoom **did work** in the reviewed desktop Camera Mode. Some older openings have real multi-box gaps. Preserve those working pieces. Root causes not yet confirmed by a repaired export must remain identified as hypotheses; the observed symptoms themselves are failures.

## Contracts to agree before parallel edits

1. **Input owner:** one documented state machine governs Idle, Holding, Camera Gesture, Pending Acceptance and Modal. Invalid placement is a Holding substate. A gesture has one owner from press until release/cancel; a UI gesture cannot become a world gesture mid-drag.
2. **Candidate and commit gesture:** by default, world motion/tap/drag positions a candidate; the visible **Place** button or **Enter** commits that explicitly displayed candidate. Moving onto the placement toolbar preserves the last valid world candidate so pressing Place can work; moving over uncovered world with no eligible hit invalidates it. Never raycast a Place-button click's UI coordinates. An optional, clearly documented desktop world-click-to-place mode must resolve its own world click position before requesting acceptance. A candidate records surface validity, canonical transform and targeting/pinned state; `(0,0)` is not a “no pointer” sentinel.
3. **Accepted placement:** the command includes request ID, player/turn/revision, part ID, hand slot when applicable, canonical transform and selected color. Only accepted events create permanent render state, consume inventory, advance turns, save/replay, or trigger accepted-placement feedback.
4. **Mode policy:** Solo Free Build exposes the supported catalogue. Solo Mixed Bags and shared modes use real hand ownership. Setup configuration, table policy, session validation, save metadata and networking must agree.
5. **Navigation/session:** AppRoot owns creation identity and route state. Gallery, setup, table, frozen showcase, exploration, replay and settings share the correct session/revision. Connection errors never silently become local Online games.
6. **Presentation assets:** visible meshes and simplified colliders are separate resources with explicit transforms/connectors. A named specialty part has that form in thumbnails, preview, placed model, exploration and film. Stable IDs and save compatibility survive art replacement.
7. **Feedback/settings:** one persistent settings model drives all controls and actual audio/haptic behavior. Local accepted events produce one confirmation; loading, reconnect, retries and replay do not create duplicate pulses/clicks.

The coordinator serializes shared contracts, `project.godot`, catalogue/event/save/protocol schemas, export presets and STATUS. Use disjoint file sets/worktrees for parallel work.

## Dispatch order

**LB-057 → LB-058 → LB-059** is the critical gameplay path. Do not declare the game playable until the Gate A demonstration below passes.

After LB-057, the presentation owner may develop LB-060, the sound owner may prepare LB-062 assets, and the asset owner may audit LB-065 in parallel. They must not hide the broken interaction behind a new menu. Integrate LB-061 after LB-058/059/060. Connect LB-063 and LB-064 against those shared contracts. Finish LB-065's genuine catalogue validation. Run independent LB-066, repair failures, then close LB-067 only to the extent evidence supports.

### LB-057 — Establish the exact runnable baseline

**Dependencies:** none. **Owner:** coordinator/platform, with verifier.

- Inspect latest main, dirty work, engine/templates and the actual browser export. Record source SHA, clean/dirty status, engine/template versions, renderer, build timestamp and export checksums. Add a small build-information view in Settings/About; keep diagnostics out of the normal play HUD.
- Reproduce LIVE-01/02/04/08 from the real entry scene. Start a fresh creation; also test resume/return routes. Trace GUI/world event delivery in a development build to establish the overlay cause.
- Inventory available skills, plugins, browser tools, orchestration and devices. Read relevant skill instructions. Record exact capabilities; a named plugin is not an installed capability.
- Separate historical test reports from current results. Preserve earlier evidence, correcting claims through STATUS and superseding reports.

**Acceptance:** a reproducible web build/serve command, an identified export, a short actual interaction capture, and a failure matrix with source hypotheses separate from observed defects. A loading screenshot alone does not pass this task's reproduction requirement.

### LB-058 — Restore pointer placement and exclusive input ownership

**Dependencies:** LB-057. **Owner:** gameplay/input. **Reopens:** LB-053/054/055/036/038 where affected.

Inspect `app_root.tscn`, `app_root.gd`, `main.gd`, `camera_controller.gd` and the Place input action. Correct the full-window UI container so noninteractive uncovered world areas receive pointer events while actual menu/modal controls retain ownership. Do not move all placement into global `_input` as a shortcut.

Implement the agreed state machine before dispatching mapped actions. Guard both mouse and Enter/button commits against camera/modal/pending state. Distinguish click from drag. Default Place/Enter commits the displayed valid world candidate; an optional world-click commit resolves that world event's position. Do not use toolbar coordinates as a world target. Handle press/release across boundaries, pointer cancellation, lost focus, resize, DPR/canvas scaling, and reopening a modal. Clear or suspend the candidate on an uncovered-world miss; preserve it while deliberately interacting with placement controls, with the pinned preview clearly visible.

Provide an obvious Cancel/Escape path that releases the held brick and restores normal cursor use. Building must not capture or lock the mouse. Camera gestures must not consume a turn, select a brick underneath UI, or change placement. Catalogue/slider scrolling must not zoom the table. Use familiar orbit/pan/zoom defaults plus a clear optional touch/camera mode; labels must describe the action actually performed.

Preserve the canonical stud lattice and surface-selection rules from [PLACEMENT_AND_CATALOG](PLACEMENT_AND_CATALOG.md). Reproduce base → stack → distant base, both rows of 1x4 on 2x4 and all quarter turns. Do not repair a visible offset with an unrelated visual-only half-stud shift.

**Gate A acceptance:** through Welcome → Solo → Table, use the actual mouse to place **ten pieces at separated baseplate locations**, stack a narrow part correctly, return to empty ground, cancel/reselect, orbit/pan/zoom, and resume a saved creation. Demonstrate that a valid candidate is not committed by Camera Mode drag, catalogue scroll, settings interaction, or an outside-board click. Include actual viewport/browser input tests through AppRoot; assigning `current_grid_pos`, calling `_on_place_pressed`, or directly invoking `_unhandled_input` cannot establish this gate.

### LB-059 — Make session policy and accepted state authoritative

**Dependencies:** LB-058. **Owner:** gameplay/core. **Reopens:** LB-034/036/037/044.

Replace the table's spawn-before-submit path with one validated request/acceptance interface. Reuse or repair `request_placement` and shared placement rules instead of maintaining an unchecked `submit_placement` route. Validate phase, revision, active player, deadline, hand slot, part, color policy, transform, connections and collision before permanent rendering. Invalid commands must leave the board, hand, turn, save and feedback unchanged.

Wire the `free_build` setup choice into an explicit mode policy. Initialize selection from the real permitted hand or Idle state; do not spawn a default 2x4 that is absent from the hand. All Parts is available for Free Build; a browse-only catalogue in a bag mode cannot become an inventory bypass. Keep six-piece shared hands, refill, pass and timer rules intact. After acceptance, give the next player an understandable handoff and clean selection state rather than an immediate permanent COLLISION banner.

Carry stable placement IDs, colors and canonical transforms through rendering, undo/redo, saves, exploration, reconnect and replay. Restore the full session/creation identity, not just placement arrays with fresh players. Keep corrective actions and finish agreement bound to the intended revision.

**Acceptance:** repeat the observed outside-hand Brick 1x1 attempt and prove rejection with zero changes. Place a permitted part and prove exactly one accepted event/turn change. Select a non-player color, explore/return/save/reload/replay and verify the exact accepted color. Compare Free Build and Mixed Bags through their real setup and table screens.

### LB-060 — Deliver the first three screens as a coherent family game

**Dependencies:** LB-057; shared navigation contracts from LB-059 for integration. **Owner:** UI/art. **Reopens:** LB-035/043.

Implement [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md), including its color/type/spacing tokens and concrete screen compositions. Use a reusable Godot theme and original art; replace default dark panels and emoji-dependent icons with an inviting, well-lit craft-table scene, recognizable LittleBricks identity, clear primary action and visibly appealing example creation. Keep the scene lightweight and respect Reduced Motion.

Use picture-led Solo, Pass & Play and Online cards with one plain-language explanation each. Theme selection must preview the actual Harbour/Cabin atmosphere. Setup should expose only relevant choices, with friendly defaults and timer-free shared play available. Continue shows the real saved creation; every destination must be honest while it is being connected.

Bundle licensed fonts and a consistent SVG/vector or original mesh icon set. Verify exported glyph rendering. Reflow layouts at desktop, tablet and phone widths; never shrink a 1280-wide desktop control arrangement until text becomes unreadable. Test actual on-screen hit areas after stretch/scaling: **both width and height** must meet the documented touch target, with usable spacing. Fix the current OR assertion that lets a wide but short button pass.

**Acceptance:** actual exported screenshots at desktop, tablet and phone portrait/landscape sizes show readable controls, picture-led choices, working Back/Continue/settings and no missing glyphs, clipped cards or hidden primary actions. A fresh player can understand the available modes and reach the board without an explanation from the developer. Record reviewer judgment separately from recruited family feedback.

### LB-061 — Make building feel like manipulating toys

**Dependencies:** LB-058/059/060 and the LB-065-A starter assets; full LB-065 completion is not required. **Owner:** gameplay/UI/art. **Reopens:** LB-036/041/042/043/056.

Replace the developer HUD with a bounded player/turn strip, contextual placement controls and unobstructed creation area. Move coordinates, yaw and validation codes to a developer toggle. Use brief messages such as “Needs support” and “Space is occupied”; a diagnostic string cannot push Save/Leave/Finish off-screen.

Show actual part thumbnails, selected state, dimensions and color; shared modes show six understandable choices. Free Build uses responsive catalogue columns, categories, search, useful empty results and optional favorites. Generate/cache thumbnails economically instead of running a live 3D viewport for every tile. Thumbnails must match the genuine geometry from LB-065; unsupported placeholders are labelled or excluded from verified packs.

Deliver pickup, rotation, eligible snap preview, cancel and accepted click/settle feedback through semantic events. Keep the pointer free and the ghost readable against all supported materials. Guide the first three successful actions in context and remove hints after success; provide a way to revisit help. Avoid a modal tutorial or mandatory reading before a child can try a brick.

**Acceptance:** complete the building portion of the family brief: show visible selection/placement/cancel states, build away from center, retrieve a genuine starter part by its image, perform a shared turn handoff, and use the catalogue without moving the world. Real controls remain usable at every supported layout. Feedback denotes actual acceptance and respects quiet/reduced-motion preferences. The complete five-minute journey, including LB-063/064 destinations, is accepted later in LB-066.

### LB-062 — Repair and author the music, clicks and tactile feedback

**Dependencies:** LB-057 for asset work; LB-059/061 for final event integration. **Owner:** audio/worlds with platform support. **Reopens:** LB-039/040/041/043.

Keep working buses and event helpers, but repair their lifecycle. Load all saved settings before playback; keep Welcome and Settings synchronized and persistent. Apply master/channel gain once, use the intended UI/Bricks routes, manage crossfade/duck tweens without competing volume writes, stop inappropriate theme ambience, and handle focus changes cleanly.

Verify first-gesture playback on the pinned web export. An unused custom unlock helper does not itself prove silence, because engine behavior also matters. Integrate activation only as needed and verify the resulting audible behavior. Configure real loops in imported/runtime resources; do not assume a “loop” filename or `edit/loop_mode=0` supplies a loop when metadata is absent. Verify playback beyond two complete cue lengths.

Author or source two coherent instrumental cues, using the existing 60–120-second starting target, with musical phrasing/variation/rests; restrained theme ambience; and tactile, varied pickup/placement/rotate/UI sounds. Quality is judged by listening in the game, not by waveform generation succeeding. Record provenance and redistribution/video use rights before bundling assets. Preserve a fully usable silent mode.

Use supported-device haptics for purposeful local interactions with a persistent off switch. Reconnect/load/replay/remote echoes must not generate repeated accepted pulses. Confirm physical haptics on hardware when available; keep that gate explicitly blocked if unavailable while completing other work.

**Acceptance:** an actual listener records observations for fresh launch, navigation, long building, rapid placements, mute/reload, sliders, focus loss/restore and loop boundaries. Listen on speakers/headphones where available and to a produced film where audio export is supported. Metadata tests and no-crash calls are separate evidence. Never claim a listening review based only on screenshots, bus values or an audio filename.

### LB-063 — Make finishing, exploring and watching the build rewarding

**Dependencies:** LB-059/061; LB-062 for final sensory acceptance. **Owner:** worlds/gameplay/platform. **Reopens:** LB-037/042/046/047/048.

After valid finish agreement, clear editing clutter and frame the actual creation bounds in a brief optional showcase. Offer **Explore**, **Watch the Build**, and **Keep Building**. The reveal must use the real creation and selected theme, with readable warm lighting, restrained atmosphere and an immediate reduced-motion path.

Give the original explorers appealing silhouettes and appropriate scale. Spawn safely with the camera facing the creation; the default third-person figure must not fill the useful view, and first person must not strand the player facing empty sky. Provide discoverable desktop and real touch move/look controls, safe reset, readable interiors and a reliable return to the same state. Test a doorway, steps and an interior made from supported parts, not only a two-brick pile.

Connect Watch Build to actual accepted history and existing rendering/export components. Reachable controls must offer preview, progress, cancel and a real output/download/share result. Preserve final part colors, transforms, construction order and licensed audio choices. Verify actual browser/desktop output; complete the native Android encoder/share work and retain physical evidence gates honestly. An adapter hook or FFmpeg success in a helper test does not establish the player journey.

**Acceptance:** build a recognizable small house/harbour scene, finish, inspect the showcase, walk through an opening in both POVs, return without state changes, watch real construction, export and decode the resulting file externally. Name the supported codec/platform and any blocked capability. No false “Export complete” without a usable artifact.

### LB-064 — Connect the promised gallery and online routes

**Dependencies:** LB-059/060; may run in parallel with LB-061/063 after shared interfaces stabilize. **Owner:** application/platform. **Reopens:** LB-034/035/037/044/045.

Make My Builds an actual creation library with thumbnails, names, timestamps, open/rename/delete-with-appropriate-recovery behavior and clear empty/corrupt-save states. Use stable creation IDs; filenames/display names must not accidentally overwrite another creation. Continue opens the correct creation and restores mode, hand, turn, phase, colors and revision. Handle save failure visibly and preserve the user's active work.

Wire Online Create/Join to the real NetworkClient and server lifecycle. Show connection progress, server-issued room code, roster/readiness, host controls, rejection/error and back/cancel behavior. Do not hardcode `LBRICK` or silently instantiate a local session as an Online success. Wire the actual authoritative session/events into the same table path used locally.

**Acceptance:** open two different saved creations through the gallery and verify identity/state; exercise corrupt/missing/failed storage. Use separate browser contexts/processes for two players, then three/four, with real commands and synchronized state. Disconnect/reconnect and restart the server around accepted actions. Keep missing production deployment credentials separate from locally testable implementation work.

### LB-065 — Replace catalogue placeholders with genuine supported parts

**Dependencies:** phased as below. **Owner:** assets/worlds, coordinator owns manifest. **Reopens:** LB-056 and original content gates.

- **LB-065-A, starter assets:** after LB-057 and agreement on the canonical mesh/connector contract, audit entries and deliver a small genuinely modeled starter kit with rendered/connection fixtures. This is an input to LB-061; do not wait for the catalogue UI or the full 120-shape task to finish.
- **LB-065-B, complete catalogue:** after LB-059 and LB-061, integrate the remaining supported packs, validate UI/save/explore/replay parity and establish the full verified count. LB-065 is done only when both phases pass. This phased contract avoids a circular dependency between thumbnails and the parts they depict.

The current renderer builds most bodies directly from collision boxes. Separate visual mesh resources/generators from collision approximations. Keep the shared canonical dimensions and connectors; provide correct normals/materials/LOD where justified. Use original parametric/authored assets or a provenance-checked LDraw conversion pipeline. LDraw/Nova remains an optional pipeline tool, not a runtime dependency or a licence shortcut.

Audit all 126 existing entries into **verified**, **placeholder**, **duplicate/variant**, or **unsupported**. Preserve IDs or write explicit migrations. Do not silently relabel a fish-shaped promise as a verified rectangular tile. Some older arches have real gaps; keep them. Add real round/cone bodies, slopes/curves/roof ridges, arches/windows, stairs/rails, foliage and recognizable Harbour/Cabin details, plus distinct original explorers.

First deliver a coherent starter kit that can build the representative house/harbour scene; then meet the existing requirement of **at least 120 genuine supported buildable shapes** in staged packs. Color/quality variants, explorer characters, unsupported records and renamed identical geometry/connector records do not increase that count. Distinct dimensions and meaningful connector/geometry differences may. Preserve a small useful selection UI even when the library is large.

**Acceptance:** produce rendered contact sheets and a machine-readable per-part support/provenance ledger. Check silhouette, visible openings/curves, mesh/collider/connector agreement, actual attachment, rotations, preview/placed/explore/replay parity and thumbnails. Specifically prove fish ≠ tile, cone/round brick ≠ square brick, new bridge arch has an opening, and stairs have usable steps. Required count follows verified entries, not a generator's printed assertion or presence of metadata keys.

### LB-066 — Independently play and judge the integrated game

**Dependencies:** LB-058–LB-065 integrated; any missing physical-only evidence remains separately blocked. **Owner:** verifier independent from implementation where available.

Run the actual user-facing build from AppRoot, with real viewport input, through the matrix below. Capture a continuous short desktop playthrough and representative responsive views. Reproduce every LIVE failure after its fix. Run PC-01–PC-10 and focused rule/save/network/export tests where relevant; retain useful existing unit tests but fix tests that pass for the wrong reason.

Use the family brief's seven-dimension quality rubric. Show the same complete scene in building, showcase, exploration and film. An expert can assess affordances and presentation; only real participants can supply child/parent playtest behavior. If those participants or audio output are unavailable, label the specific review NOT RUN/BLOCKED and finish independent checks. Do not invent quotations or approval.

**Acceptance:** evidence records exact revision/export, browser/device/input, steps, preconditions, expected/observed result and artifact. No unresolved P0 input defect or P1 state-loss/inventory/navigation defect can receive playable approval. Visual approval requires the running redesigned screens; audio approval requires listening. Repair material findings and rerun affected gates before integration approval.

### LB-067 — Reconcile the complete product and hand off truthfully

**Dependencies:** LB-066 and all applicable original/recovery release gates. **Owner:** coordinator + independent verifier.

Update STATUS, README, build/support instructions, credits, release notes and artifact index to the verified revision. Reconcile LB-001–LB-056 by actual acceptance, not by mechanically closing rows because the newer campaign ended. Keep old reports as historical evidence with clear supersession. Record exact unresolved implementation, device and publishing items separately.

Commit coherent changes and push the authorized branch using normal conflict/branch-protection rules. Prepare reproducible browser/native artifacts and store materials within the existing scope. Do not claim publicly deployed, Android-verified, family-playtested or release-ready if those gates remain unmet. The user has authorized implementation through the launch prompt; continue dependency-ready work until scope is fulfilled or only concrete external blockers remain.

**Acceptance:** a fresh agent can clone, identify the build, run it, reproduce the accepted player journeys and locate actual artifacts. The final report names what changed, what was played/heard/felt/decoded, remaining limitations, and the next exact action where blocked. “All tests pass” alone is not a completion report.

## Mandatory integrated checks

These complement PC-01–PC-10 and the original validation matrix. They are a focused response to reproduced risks, not a request to multiply shallow tests.

| Gate | Preconditions and required interaction | Evidence |
| --- | --- | --- |
| PT-01: real pointer | Fresh AppRoot; choose Solo; move to four distant board areas and place ten separate bricks; resume and repeat. | Screen capture plus target/placement observations from real events. |
| PT-02: camera/UI ownership | Start with a **valid empty placement target**. Orbit/pan/zoom, drag in Camera Mode, scroll catalogue, move settings sliders, cancel outside canvas. | Camera changes only when intended; zero unintended accepted events/turn changes. Invalid ghost preconditions cannot prove this gate. |
| PT-03: stale target | Aim at valid ground, move to uncovered world with no eligible surface, then attempt Place/Enter; test any optional world-click mode separately. Re-enter, resize and move camera before retargeting. Moving onto the placement toolbar itself preserves an explicitly shown candidate. | No cached-location commit after a world miss; toolbar confirmation uses the displayed candidate, not UI coordinates; re-entry targets the real pointer. |
| PT-04: stud/surface | Both rows of 1x4 on 2x4, quarter turns, brick/plate heights, stack then distant base. | Independent numeric connector fixtures plus rendered alignment. |
| PT-05: mode policy | Compare Free Build/Mixed Bags; try outside-hand part in Pass & Play; permitted action, timeout/pass and undo/correction. | Accepted-state/hand/turn invariants and visible handoff. |
| PT-06: state roundtrip | Place chosen non-player colors; Explore/Return; save/reload; gallery open; replay. | IDs/colors/transforms/mode/turn/revision preserved. |
| PT-07: first three screens | Fresh/returning user; desktop/tablet/phone portrait and landscape; keyboard/touch paths where supported. | Real screenshots, missing-glyph/overflow checks, measured rendered hit targets. |
| PT-08: music/feedback | Fresh gesture; >2 cue lengths; rapid interaction; navigation; mute/reload; focus loss/restore. | Listener observations plus lifecycle tests; real hardware haptic evidence separately. |
| PT-09: reward/export | Meaningful small creation → finish → showcase → explore interior → watch → export/cancel/error. | Actual traversal and externally decoded clip with correct frames/audio policy. |
| PT-10: destinations | My Builds opens distinct saves; real two-to-four Online clients create/join/lobby/play/recover. | UI captures, actual server/client events and restart/reconnect results. |
| PT-11: real parts | Render and place representative parts in each family; audit all counted entries and compare duplicate signatures. | Contact sheets, real openings/slopes/steps/details and verified-count ledger. |

## Skills, plugins and orchestration

Use `.agents/skills/littlebricks-build` for coordination, `littlebricks-assets` for geometry/art/audio, `littlebricks-verify` for independent checks, and `littlebricks-release` for packaging/claims. Read before applying. Use installed Godot/debugging, browser, GitHub, Blender/LDraw and Android/audio capabilities when they serve the assigned task; inspect documented interfaces and record availability. Optional tools have CLI/manual fallbacks and must not hold up unrelated work.

Choose one available orchestrator (`/teamwork` or bounded `/swarm` if actually supported), otherwise normal subagents or sequential work. Do not assume commands or subscriptions exist and do not nest orchestration systems. Suggested owners are input/gameplay, UI/art/audio, platform/routes, and an independent verifier, adjusted to available capacity. One coordinator integrates; workers do not race to push main.

Before a context limit, update STATUS with exact build, task state, file owner, failed/passed checks and next executable step. Continue implementation after a checkpoint; a new plan or attractive mockup is not the requested game.

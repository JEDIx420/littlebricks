# Current application source review

Date: **2026-11-11**

Inspected source revision: **`81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`**

Scope: **Independent source/data inspection of application routing, pointer ownership, placement submission, representative catalogue geometry, and the evidence supporting those features.**

Follow-up: [Playtest repair plan](../PLAYTEST_REPAIR_PLAN.md). Task ownership and sequencing belong to that plan and [STATUS](../STATUS.md).

## What this report establishes

The user reports that the newer locally running game leaves the brick preview stuck near the center, prevents normal mouse targeting, and feels visually uninviting for children and parents. That is a current user report, not an interaction reproduced by this source reviewer. The exported bundle running on the user's machine has not been matched to the source revision by this audit.

This reviewer inspected a fresh checkout, the application entry point, scenes, input/action bindings, session APIs, representative catalogue records, relevant tests, and the existing completion reports. No runtime code was changed, no game tests were executed, and this reviewer did not interact with the local browser or audition audio. Read-only catalogue comparisons are described below.

The coordinator's separate [live browser playtest](2026-11-11-live-browser-playtest.md) independently confirms the stuck pointer, catalogue-wheel input also zooming the world, a mixed-bag bypass, the My Builds and Online routing symptoms, and a brick color change after exploration. Consult that report for actual interaction steps, captures, and audio-evidence limits. Those observations strengthen the case for repair, but do not by themselves prove every causal mechanism proposed in this source audit. In particular, the full-window wrapper remains a source-backed cause to isolate during repair. Initial connection difficulties are not evidence about the game itself.

The four screenshots supplied earlier in the conversation show an earlier build. They are historical context for the previous recovery campaign, **not current screenshots or proof that this revision still has exactly those visual or geometry defects**. They are not reproduced here because they also expose unrelated browser content.

The source findings below warrant reopening specific integration gates. They do not establish that every existing component test is wrong, that the catalogue is unusable, or that previously reported test commands failed. Preserve useful rules and geometry coverage; add the missing application-level evidence.

## Evidence and result matrix

`FAIL (source)` means the inspected implementation contradicts the named contract. It does not claim that this reviewer reproduced the symptom through a browser. `NOT RUN` applies to this audit, not to work another reviewer may perform later.

| Check | Result in this audit | Evidence and limit |
| --- | --- | --- |
| Identify inspected source and application entry point | PASS | Revision above; `game/project.godot:11` launches `app_root.tscn`. |
| Identify the source of the user's exact served bundle | NOT RUN | No embedded build identity, served bundle hash, or local checkout identity was collected by this reviewer. |
| Reproduce the current stuck-center symptom through real mouse events | NOT RUN by this source reviewer | The separate live browser report confirms the symptom. Full-window application input interception remains a strong source-backed causal hypothesis. |
| Camera mode prevents placement for a valid target | FAIL (source) | The left-button `place` action is handled before the camera-mode guard. Runtime confirmation must start with a valid target. |
| Pointer misses invalidate direct-placement targets | FAIL (source) | A missed ray leaves the old valid candidate intact; direct-click dispatch commits cached state. |
| Table commits use the validated session and hand policy | FAIL (source) | The visible builder calls an unchecked submission API and exposes the catalogue without a mode restriction. |
| Rendered brick color is passed into the accepted session record | FAIL (source) | The visible selection color is omitted from `submit_placement`; the session defaults to player color. |
| My Builds opens saved creations | FAIL (source) | The route opens mode selection. |
| Online Create/Join connects the running application to the network client | FAIL (source) | The setup config is routed into a local session; room information is unused by the application router. |
| Catalogue claim of 126 verified distinct shapes | FAIL (source/data) | There are 126 entries, but sampled differently named parts have exactly equal dimensions, body boxes, and connectors; the audit checks key presence rather than distinct geometry or buildability. |
| Existing headless suite outcomes at this revision | NOT RUN | Tests were inspected, not executed. Existing reports remain historical claims until reproduced on a named environment. |
| Current visual quality, music quality, loop seams, audible clicks, and actual latency | NOT RUN | Source cannot establish these experiences. Use the separate browser/audio playtest. |
| Physical touch, haptics, and phone performance | NOT RUN | No physical-device interaction was performed by this reviewer. |

## Findings

### Full-window container is a likely cause of the frozen pointer

**Priority: blocks basic building. Runtime cause remains to be confirmed.**

Source facts:

- `game/client/scenes/app_root.tscn:8–14` declares `ViewContainer` as a full-window `Control` without an explicit `mouse_filter` override. A plain Godot `Control` uses the stopping mouse filter by default.
- `game/client/scripts/app_root.gd:48–51` frees the previous view, but leaves that container present. Starting the game adds the tabletop directly to `AppRoot` at `118–121`, as a sibling of the container.
- `game/client/scripts/main.gd:390–401` updates the pointer only from `_unhandled_input`. The preview starts at `(16,16)` at line `67`, and `_last_pointer_screen_pos` starts at zero at line `79`.
- `main.gd:472–474` does not retarget from the saved pointer until it becomes nonzero.
- `game/client/scenes/main.tscn:58–65` explicitly sets the tabletop HUD's root to `mouse_filter = 2` (ignore), but the application wrapper does not have that policy.

An empty full-window control can consume mouse events during GUI processing before `_unhandled_input` sees them. This matches the reported combination of a stationary center preview and working UI buttons. It is a stronger explanation than assuming the world-to-grid formula alone is broken, but the actual served scene and event route still need inspection.

Repair the wrapper's ownership policy and its lifecycle. Menu children must remain interactive; empty tabletop space must reach world input. Moving all placement into global `_input` would create a different UI click-through problem and is not an adequate repair.

### Camera ownership does not cover the mapped Place action

**Priority: accidental placement and competing gestures.**

- `game/project.godot:25–29` maps the left mouse button and Enter to `place`.
- `main.gd:326–329` executes that action before considering camera mode.
- The camera-mode check at `main.gd:383–388` protects only the later raw mouse-button branch. `_on_place_pressed`, beginning at `683`, has no camera-mode guard.
- `game/client/scripts/camera_controller.gd:32–148` handles mouse, touch, and keyboard in global `_input`, without a GUI/modal ownership check or consuming an owned gesture.
- `main.gd:390–401` continues pointer targeting during camera mode.

Once world mouse events can reach the builder, a left-button camera drag can commit a valid ghost before its camera-mode branch is reached. Camera handling can also respond to UI-originated gestures. The current wrapper interception may hide part of this problem; fixing the wrapper must be followed by the camera regression, not treated as complete input recovery.

Use an explicit input owner for holding a brick, a camera gesture, and a modal. Apply that policy before mapped actions as well as raw mouse/touch branches. Define cancellation, focus loss, multi-touch transitions, and release outside the canvas. An action should have one owner and at most one accepted placement.

### Missing surfaces leave a stale placement candidate

**Priority: unintended placement after moving away from the board.**

`main.gd:578–581` returns when no target surface is found without clearing `is_current_placement_valid`, hiding/suspending the ghost, or disabling direct placement. The action handler at `326–329` and raw click handler at `385–388` then place from cached state without resolving the click's own position.

The code therefore retains a legal old target after a pointer miss. A later click over uncovered world space can commit there. A new click after canvas re-entry or camera motion can also use a stale target if no intervening pointer update established a new candidate.

Represent a pointer miss explicitly. Resolve a direct-placement click from its actual event position and refuse to commit when it has no eligible surface. If keyboard/Place-button interaction intentionally retains a pinned candidate, make that a defined state rather than a side effect of a failed ray.

### The table bypasses validated session acceptance and bag restrictions

**Priority: incorrect gameplay and state divergence.**

- `main.gd:696–714` creates the permanent mesh and appends the local record before asking the session to accept the move.
- `main.gd:719` calls `SessionManager.submit_placement`.
- `game/core/session_manager.gd:199–236` appends an accepted record without checking phase, turn owner, inventory membership, or placement rules. It refills a hand slot only if it happens to find the part in the hand.
- The guarded `request_placement` API at `session_manager.gd:142–196` does validate phase, player, slot, and rules; the visible table does not use it.
- The All Parts control is declared at `main.tscn:262–266`, and `main.gd:870–928` opens/populates it without enforcing a Free Build policy.
- `game/client/scripts/setup_screen.gd:119` emits a `free_build` choice, but `app_root.gd:92–127` does not apply it to the session or builder.

Consequently, the visible path does not enforce the stated distinction between a mixed bag and unrestricted Free Build. Pass-and-play can select catalogue parts outside its hand. The table's separate local board and session record are also permitted to diverge because rendering precedes authoritative acceptance.

Route every commit through one validated session contract. Bag modes submit a hand-slot identity; Free Build uses an explicitly allowed catalogue path. Render and trigger feedback from the accepted record, and leave the board, timer, hand, and turn unchanged when acceptance fails.

There is a related color defect: the permanent mesh uses `selected_color` at `main.gd:698`, but the call at `719` omits that argument. `session_manager.gd:200–205` falls back to the player's color. A selected brick can therefore change appearance when reconstructed from session/save data. Accepted records must carry the same part, color, pose, and immutable identity used by the visible mesh.

### My Builds and Online are not connected to their promised destinations

**Priority: misleading mode/navigation choices.**

`app_root.gd:272–274` implements My Builds by navigating to mode selection. It does not display a saved-creation list.

`setup_screen.gd:150–180` emits Create/Join config; Create hardcodes `LBRICK`, and an empty Join code also becomes `LBRICK`. `app_root.gd:92–127` then creates a local `SessionManager` and tabletop for that config. It does not use `room_code` or `is_host`, instantiate `NetworkClient`, wait for a server, or establish a lobby. Inspection of the client source found the network implementation in `game/client/scripts/network_client.gd`, but no application scene/controller instantiating it.

The transport module is useful implementation work. Its existence or its isolated tests do not establish that the Online button connects two players. Connect the actual router and UI to server-issued room state, connection failures, lobby membership, and authoritative accepted events. My Builds must open real saved creations with an honest empty state and recoverable load errors.

## Why existing interaction evidence misses these paths

The source tests are valuable for several helper behaviors, but their boundaries differ from the acceptance claims:

- `game/tests/test_surface_height_and_camera.gd:12–14` instantiates `MainScene` directly, omitting the application wrapper implicated above.
- Lines `35–44` assign grid positions and invoke placement directly. Lines `112–124` test UI isolation by calling rotation and selection methods. These verify those method effects, not GUI event propagation.
- Lines `140–152` call `orbit_by`, `zoom_by`, and `pan_by`. They verify camera calculations, not whether a user gesture reaches the correct owner.
- The Camera Mode check at lines `168–174` invokes `_unhandled_input` directly. Earlier steps leave the tested location occupied and select an overlapping part. The ghost can therefore already be invalid, allowing the placement count to remain unchanged because validation rejects the target rather than because camera mode owns the click. The test must explicitly establish a valid candidate before testing suppression.
- `test_app_lifecycle_and_audio.gd:92–95` and `test_journey_recovery_validation.gd:56–67,113–125` likewise assign coordinates and invoke placement.
- `docs/evidence/LB-050-independent-journey-verification.md` records browser navigation to an initial tabletop preview at `(16,16)`. That written browser account does not record cursor-driven placement at multiple locations or actual camera gestures.

Do not delete those unit tests merely because they cannot prove a human interaction. Keep their narrower assertions and add full-application dispatch checks. A visible initial scene and no console errors establish loading; they do not close mouse/touch usability, sensory, or complete-game gates.

## Required reproduction protocols

Record each protocol as `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`, with source SHA, actual served build identity, engine/export-template version, browser/version, viewport, input device, expected result, observed result, and clean game-only captures. Source SHA alone does not identify a previously exported local bundle.

### Actual pointer targeting through AppRoot

1. Launch the exported application whose entry point is `AppRoot`. Navigate from Welcome through mode choice and Solo setup using the real UI.
2. Move the mouse to at least three widely separated uncovered baseplate regions. Record the ghost and candidate coordinates. They must follow the pointer rather than stay at `(16,16)`.
3. Place ten separated legal bricks at baseplate height through actual controls. Do not manually assign `current_grid_pos`, call `_handle_pointer_position`, or invoke `_on_place_pressed` as proof of playability.
4. Move onto a brick top, stack once, move back to uncovered baseplate, and place again. Confirm top and base heights follow the intended support surface.
5. Repeat after Save & Leave, Continue, a viewport resize, and entering/leaving a modal.
6. For diagnosis, inspect the full control tree, hover target, effective `mouse_filter`, and whether the pointer event reaches world dispatch. Keep any diagnostic overlay out of the normal player experience.

### Camera ownership with a valid placement precondition

1. Begin on an empty legal target with a valid ghost and enabled placement action. Capture this precondition; an already overlapping/invalid ghost cannot demonstrate camera isolation.
2. Enable Camera Mode through the UI. Start a primary-button drag over the board. Assert camera movement, zero new placements, and unchanged hand/turn.
3. Exercise orbit, pan, zoom, top view, frame build, and reset using the documented mouse/trackpad controls. Repeat the supported gestures on touch hardware separately.
4. Scroll the catalogue and manipulate settings sliders while a valid candidate exists behind the UI. Assert no board changes and no unintended camera movement.
5. Test releasing outside the canvas, losing focus, cancelling, and transitioning between one and two touches. The next gesture must start from a clean ownership state.

### Stale-target prevention

1. Establish a valid preview on the board. Move into uncovered canvas space with no eligible support surface and click. Assert no placement.
2. Re-enter at another board location and click. The intended current point must determine the candidate.
3. Repeat after camera movement, resize, modal close, and a pointer leave/re-enter. Document the deliberate behavior of explicit Place/Enter separately from direct clicking.

### Session policy and persistence through the visible flow

1. Start pass-and-play. Confirm the active hand contains six pieces. Attempt to select/use a part outside that hand through the visible catalogue route; the route must be unavailable or acceptance must reject it without consuming a turn.
2. Exercise one valid placement, pass, timeout, undo/redo, and a rejected placement. Confirm visible board, session, inventory, and turn agree.
3. Compare the Solo mixed-bag and Free Build options. Their actual selection/refill policies must match their labels.
4. Place a brick whose color differs from the player's badge, then Save & Leave, Continue, and Explore. The same brick color and transform must survive all transitions.

### Real destinations and quality evidence

1. Save two named creations, choose My Builds, and open each from the resulting gallery. Test its empty and failed-load states.
2. Create and join a room from two separate running clients using the actual UI. Record connection/lobby state, independent player identities, and convergent accepted placements. A local method call or two local SessionManagers is insufficient.
3. In a separate recorded experience review, assess Welcome, mode choice, setup, the first minute of building, and the finished scene. Audition the actual music and click sequence, mute/volume persistence, transitions, loop boundaries, and repeated placements. Label any audio-capture or hardware limitation precisely; do not infer pleasant sound from the existence of an audio player or asset.

## Catalogue follow-up: named placeholders are counted as verified shapes

The manifest contains **126 entries**. A read-only JSON inspection and comparison of representative records confirms that this is not evidence of 126 distinct verified shapes. This was a targeted follow-up for the art and gameplay scope, not an exhaustive rendered audit of all entries.

### Exact equality and missing specialty geometry

The first four groups below were compared directly for equality of `dimensions_studs`, `collision_boxes`, and `connectors`. The remaining examples were inspected in the current manifest and the renderer that consumes them.

| Named parts | Verified source/data finding |
| --- | --- |
| Fresh Fish 1x2; Tile 1x2 | Exactly equal dimensions, body boxes, and connectors: a single `1 × 0.4 × 2` rectangular body, no top studs, and the same two bottom sockets. |
| Brass Harbour Bell; Wax Candle; Luminous Crystal | Exactly equal dimensions, body boxes, and connectors: a single `1 × 1.2 × 1` rectangular body, no top studs, and one bottom socket. |
| Cone 1x1; Round Brick 1x1; Brick 1x1 | Exactly equal dimensions, body boxes, and connectors: the same square brick body, one top stud, and one bottom socket. |
| Explorer Pippin; Explorer Marina; Explorer Rowan | Identical dimensions, collision boxes, and connectors; the character renderer also builds the same fixed mesh and colors for every identity. |
| Roof Ridge 1x2; Inverted Slope 1x2 | Both define a single smooth-topped rectangular body of size `1 × 1.2 × 2`, without ridge or slope geometry. |
| Curved Slope 2x2 | A single smooth-topped rectangular body, without a curved surface. |
| Bridge Arch 1x8; Window Frame 1x2x2 | Each is a single solid body with no opening. |
| Grand Stairs 4x4 | A single solid body with no steps. |

Representative manifest locations are `game/assets/catalog/parts_manifest.json:36` (Brick 1x1), `2350` (Tile 1x2), `4075` (Round Brick 1x1), `4205` (Cone 1x1), `7720` (Roof Ridge), `7832` (Bridge Arch 1x8), `9426` (Crystal), `10136–10290` (Pippin/Marina/Rowan), `10292` (Bell), `10392` (Candle), and `10493` (Fish).

**Qualification:** Some older openings genuinely have gaps. The inspected `arch_1x3`, `arch_1x4`, `arch_1x6`, and `door_frame_1x4x6` records contain separate posts and beams. Rectangular bricks and plates of different dimensions are also useful distinct building pieces. Do not label every entry a placeholder or replace the 126-entry claim with an invented exact usable-shape count. The demonstrated problem is that duplicated and missing specialty geometry is included in the verified total.

### Renderer and generator boundaries

`game/core/part_mesh_builder.gd:13–59` only special-cases the `character` category. For every other part it turns each `collision_boxes` entry into a `BoxMesh` at `28–39`, then adds ordinary cylinder studs at `41–57`. It does not load an authored visual mesh or generate cones, round bodies, slopes, fish, bells, foliage, stairs, and other specialty forms. The collision approximation is also the entire visible body.

`part_mesh_builder.gd:61–110` builds a fixed four-piece figure with blue legs, a red torso, a yellow cylindrical head, and a brown box hat. It does not use `part_def` to distinguish Pippin, Marina, and Rowan, and does not use the supplied material for their colors. Different explorer names do not currently provide distinct character art.

`tools/expand_catalog.py:17–26` supplies one full rectangular body unless its caller provides custom boxes. The expansion calls this generic path for Round Brick/Cone (`69–77`), slopes/curved slopes/roof shapes (`119–134`), additional openings (`137–151`), structures (`153–167`), thematic decorations (`169–205`), and explorer records (`207–216`). Custom bottom sockets alone do not create a visible gap. Existing IDs are preserved at `54–55` and the guarded additions, explaining why some earlier openings retain their better geometry.

At `expand_catalog.py:225`, the generator reports the resulting count as "distinct verified shapes" without performing a shape, visual, distinctness, or buildability verification step. That message should not be used as acceptance evidence.

### What the audit actually covers

`game/core/part_catalog.gd:108–131`, `audit_catalog()`, checks whether category, license, and dimension keys exist, plus connector and collision-box keys for non-characters. It does not check recognizable form, actual holes or slopes, geometry distinctness, attachment validity, or visual/collider agreement. Presence of a connector dictionary does not establish a meaningful connection contract.

`game/tests/test_part_catalog.gd:24–30` only requires at least 12 IDs and then prints a fixed message about 16 representative shapes and an explorer. Lines `32–47` check connector rotation for Brick 1x2. Lines `49–70` check a nonempty Brick 2x4 node, the child count of Arch 1x4, and a four-child explorer. These narrow checks remain useful; they cannot substantiate the broader 126-shape claim in `docs/evidence/LB-056-catalog-expansion.md:16–31,47`.

### Required art and catalogue acceptance

Separate visible art from simplified collision geometry, retaining the canonical placement contract. Track placeholder, provisional, and verified asset states. Count a part as a verified distinct shape only after its advertised form, attachment behavior, and collision boundaries have been inspected; preserve stable IDs and saved-build compatibility when replacing placeholders.

Prioritize a recognizable theme kit: real roof forms, usable openings, steps, foliage, a fish, bell, nautical/cabin props, and distinct original explorers. Produce rendered asset sheets and thumbnails that make the form clear before selection. The current tray and catalogue use text-only buttons at `main.gd:273–281,920–928`; an appealing label does not compensate for receiving a different shape.

Add targeted tests for openings, slopes, steps, connectors, and intended duplicates. Use rendered contact sheets and actual building/exploration scenes to verify silhouette and clearance. This evidence should supplement existing unit tests, not be replaced by raising a metadata count. A player selecting Fish should receive a recognizable fish, rather than the same geometry as a plain tile under another name.

## Handoff

Repair application input ownership first, then re-run the original stuck-pointer interaction before accepting additional presentation work. Follow with camera/stale-target regressions, validated session submission, and the promised navigation destinations. The active repair plan owns subsequent task IDs and complete release scope.

This audit supports reopening the specific claims above. It does not grant or revoke every unrelated milestone, and it does not replace the separate live browser, audible-output, physical-device, networking, or exported-film evidence required by [VALIDATION](../VALIDATION.md).

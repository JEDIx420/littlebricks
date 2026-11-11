# Placement, camera, and catalogue recovery

> Current implementation work follows [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md) and the concrete [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md) brief. The latest [live/source review](evidence/README.md) supersedes completion claims; this document remains a requirement contract, not proof of implementation.

This specification originated with the user's earlier local-browser playtest and code review of `9eaeda86ed867a002aa034b12e66d211f8c26432`. It is a requirement contract, not a claim that defects are repaired. Use the current tasks and explicit placement-gesture contract in [PLAYTEST_REPAIR_PLAN.md](PLAYTEST_REPAIR_PLAN.md), the gates in [VALIDATION.md](VALIDATION.md), and the concrete [family experience brief](FAMILY_PLAY_EXPERIENCE.md). Preserve these canonical geometry/connector fixtures while correcting actual application input.

## Contents

- [Observed defects and evidence](#observed-defects-and-evidence)
- [Surface targeting and height](#surface-targeting-and-height)
- [One coordinate contract](#one-coordinate-contract)
- [Camera and input](#camera-and-input)
- [Required regression fixtures](#required-regression-fixtures)
- [A larger usable catalogue](#a-larger-usable-catalogue)
- [Content pipeline and acceptance](#content-pipeline-and-acceptance)

## Observed defects and evidence

The user opened a browser build at `localhost:8080` and placed bricks. This establishes local browser launch and some interaction; it does not establish a public deployment or a complete browser acceptance pass. Four screenshots show elevated `Plate` values, `FLOATING` messages when moving over empty baseplate, a small six-item tray, and visibly offset narrow bricks. The user also reports being unable to freely drag the camera. Record new browser/device versions during reproduction; they were not supplied with the screenshots.

| Observation | Code evidence at the reviewed revision | Required outcome |
| --- | --- | --- |
| After a placement, another brick cannot easily return to empty baseplate | `main.gd::_on_place_pressed` unconditionally adds the placed part's height to `current_layer_plate`; pointer targeting intersects that retained horizontal plane. Height controls are keyboard-only. | Pointing at an uncovered baseplate area targets layer 0 automatically; pointing at a supported top surface targets its actual socket plane. |
| A 1x4 sits between the stud rows of a 2x4 | `parts_manifest.json` uses centered local coordinates, including half-stud offsets. `TableView.grid_to_world` positions every part center on an integer stud anchor. `PlacementRules.get_absolute_*` rounds fractional connector positions to whole studs, while the mesh preserves the fractions. | Meshes, colliders, sockets, rendered studs, previews, saves, and server rules share one exact transform; no accepted ordinary connection is half a stud out. |
| Camera appears fixed | `camera_controller.gd` has right/middle-button orbit and wheel zoom, but no pan or touch-centroid orbit. The actual browser/trackpad failure still needs reproduction; do not claim all mouse orbit code is absent. | Discoverable, working orbit, pan and zoom across mouse, trackpad and touch, independent of selecting or placing a part. |
| Too little variety | The manifest contains 43 entries, including an explorer entry; the launched tray hard-codes six choices. Metadata count is not a verified playable-parts count. | Expose the audited library appropriately and expand real, distinct building shapes through tested packs. |

Do not put the raw screenshots in this public repository: they contain unrelated browser tabs. This written reproduction is sufficient; obtain clean game-only captures during validation.

## Surface targeting and height

Make **Auto Height** the default. Resolve the pointer ray against eligible placement surfaces of the baseplate and placed parts, excluding the ghost, decorative studs, HUD, and explorer. Convert the selected support surface to the canonical connector plane; stud-cap height must not increase brick body spacing. Selecting an empty part of the board must immediately return the preview to its baseplate plane. Do not carry the previous placement's top layer silently into the next pointer target.

Generate a small deterministic set of nearby connector-aligned candidates. Rank the intended visible surface first, then distance to the target; validate each against the shared placement rules. Use modest hysteresis so the ghost does not flicker between adjacent targets. If the intended target is invalid, show why; do not teleport the piece to an unrelated legal location. Handle gaps, openings and a pointer that misses the board without clamping it into an unintended edge placement.

Provide a visible **Auto / Manual Height** control, accessible Up/Down controls, a height label, and **Return to Base**. Manual mode is an explicit lock and remains visibly labeled. Returning to Auto or pressing Return to Base must clear a stale lock. Selection, rotation, cancellation, save/resume, top view and reset view must preserve the documented mode consistently. An optional stack-assist may be added later, but must be explicit and reversible; it cannot be the hidden default.

One placement request consumes at most one part/turn. Camera motion, tray selection, slider changes and UI buttons never commit a brick. Use input ownership and GUI consumption rather than independent global listeners competing for the same click. Inspect the current `_input` placement handling and left-button action binding; reproduce accidental UI placements before recording a confirmed defect. Keep explicit Place/Enter and a clearly documented direct-placement gesture if offered.

## One coordinate contract

The coordinator owns this migration. Serialize edits to `table_view.gd`, `part_catalog.gd`, `part_mesh_builder.gd`, `placement_rules.gd`, the manifest, save/replay schemas and network poses.

Choose and document one canonical connector-anchor convention. A recommended model is a stable local anchor connector plus an integer board stud address, integer plate height and quarter-turn orientation. Convert a mesh-local point `p` with local anchor `a` through:

```text
world(p) = board_origin + anchor_position + rotation(p - a)
```

The part's geometric center is derived from that anchor and its local offsets. It is not assumed to occupy the same lattice as every stud. For a rectangular part, even widths have centered stud coordinates at half offsets, while odd widths include an integer center row. A one-stud-wide brick must align to either actual stud row of a two-stud-wide brick, not their midpoint.

If half-stud integer units are useful internally, store two units per stud and convert metadata to that exact representation once. Preserve parity during all transforms. Do not round `anchor + 0.5` and `anchor - 0.5` into ordinary stud addresses to manufacture a match. Ordinary sockets may connect only to actually coincident compatible connectors, with matching connection height and orientation. Genuine offset parts require explicit connector metadata and tests; accepting arbitrary half-offset poses is not the fix.

Use the same pose-to-transform function for the ghost, placed mesh, collision geometry, connector overlay, explorer collision, save restore, server validation and replay. Compare connector identities/coordinates exactly in canonical units; use a small documented tolerance only for rendered floating-point comparisons. Count unique matched connector pairs, not duplicate nested-loop hits.

For a golden 2x4 fixture whose stud footprint is `x={8,9}, z={8,9,10,11}`, a lengthwise 1x4 may occupy row `x=8` or `x=9`; `x=8.5` is invalid for those ordinary pieces. Verify equivalent expectations for all four rotations, mixed odd/even dimensions, board edges and negative local offsets. Rotate both the local connector set and anchor offset consistently. Do not derive the expected test coordinates by calling the same production transform under test.

Make a temporary developer overlay for mesh origins, stud centers, socket centers, support heights, collider boundaries and selected anchor. Keep it outside normal player UI. Save clean close-up captures from top and side views proving that the visible geometry agrees with legal placement. Preserve three plates per standard brick and the existing scale unless an intentional versioned migration changes it.

Existing saved poses may encode the broken convention. Introduce catalogue/pose versions and an explicit migration or non-destructive unsupported-version response. Back up original saves. Test old-save handling and new-save/replay/server parity; do not silently shift a user's creation.

## Camera and input

Implement a single documented action map; display concise contextual hints and expose a **Camera** interaction mode that works with a plain primary-button drag. This makes trackpads and one-button setups usable without relying on an undiscovered right click.

| Input | Required behavior |
| --- | --- |
| Mouse | Right drag or Camera-mode primary drag orbits; a documented modifier drag pans; wheel zooms toward the focus. |
| Trackpad | Camera-mode drag works; trackpad scroll/pinch behavior is detected and documented for the tested browser. Do not assume it arrives as touch events. |
| Touch | One finger manipulates the selected brick; two-finger centroid movement orbits and pinch zooms. An explicit Pan mode/button provides unambiguous panning. |
| Keyboard | Focusable camera controls and documented orbit/pan/zoom/reset shortcuts. Preserve brick rotation and height shortcuts without collisions. |

Prevent browser context menus and page scrolling only while the canvas owns the relevant interaction. Do not suppress normal page behavior everywhere. Clear drag state on release outside the canvas, lost focus, pointer cancellation, extra touch, mode change and tab/background transitions. A camera gesture cannot move the ghost or place a brick as a side effect.

Bound the focus and zoom, clamp pitch safely, keep the table within reach and avoid clipping through it. Top View, Reset View and Frame Build remain shortcuts, not the sole ways to inspect the model. Camera controls must also be implemented appropriately in miniature exploration. Re-test high-DPI displays, resized canvases, browser zoom, portrait/landscape and UI overlays.

## Required regression fixtures

These are acceptance scenarios, not completed results. Execute through the real browser UI and shared-rule tests where appropriate.

| ID | Scenario | Pass condition |
| --- | --- | --- |
| PC-01 | Place a 2x4 on baseplate, then point to a distant empty baseplate area and place a second brick; repeat ten times | Every independent base placement uses layer 0 without a hidden keyboard reset; no floating error on a valid target. |
| PC-02 | Alternate baseplate, brick top, baseplate, plate top, baseplate | Preview, accepted height and visible support agree; rejected requests spend nothing. |
| PC-03 | Test Auto, Manual, Return to Base, rotation and part switching | Visible state explains height; locks clear as specified; no unsolicited stacking. |
| PC-04 | Stack 1x4 on each row of a 2x4 at every quarter turn | Exact connector coincidence and visible alignment; midpoint placement rejected. |
| PC-05 | Mix 1x1, 1x2, 1x3, 1x4, 2x2, 2x3, 2x4, plates and tiles | Odd/even parity, three-plate height and smooth-tile rejection stay correct. |
| PC-06 | Place near all edges/corners; test arches/openings and unsupported offsets | Full body/connector bounds respected; openings usable; no arbitrary rounding or floating connections. |
| PC-07 | Click every tray/control/menu button while the ghost is legal | No world placement occurs until the actual placement action; one accepted click gives one event. |
| PC-08 | Orbit 360 degrees, pan, zoom, top/reset/frame; repeat with mouse, trackpad and touch | Actual viewpoint changes and recovers; browser context/scroll interference controlled; no stuck gesture or incidental brick. |
| PC-09 | Save/reopen, replay and send the same fixture through client/server | Canonical poses and rendered connector positions are unchanged; migration is explicit. |
| PC-10 | Use the parts browser, then start a multiplayer round | Solo can access the supported library; multiplayer has a real six-slot hand drawing from enabled packs, not an unlimited catalogue. |

## A larger usable catalogue

Expand in waves after the coordinate gate passes. The following counts are planning targets for distinct, usable shapes, not claims about existing content. Color variants, duplicated geometry, character entries, unsupported mechanisms and unverified manifest records do not count toward the totals.

| Wave | Target and content | Gate |
| --- | --- | --- |
| A: Audit and expose | Audit the 43 current manifest entries, count actual buildable shapes separately, repair unsuitable definitions and expose the verified subset through the catalogue UI | Every exposed shape passes connector, collision, render and save/replay checks; record the actual count without calling all 43 verified. |
| B: Everyday builder | Reach at least 80 distinct verified buildable shapes: more 1xN/2xN bricks, plates, tiles, corner/L shapes, round pieces, slopes/wedges and reliable openings | Correct geometry for each shape, coherent thumbnails/categories and acceptable load/frame-time results on the named baseline. |
| C: Rich first library | Reach at least 120 distinct verified buildable shapes, aiming toward 150 as the same budgets permit: windows/doors/frames, arches, stairs, roofs, fences/railings, pillars, foliage and Harbour/Cabin details | At least two varied small builds are possible from actual UI; all supported shapes participate in placement, exploration and real replay without missing dependencies. |

The minimum expanded-library goal for this campaign is **120 verified buildable shapes**. Treat 150 as a stretch target; if a measured resource limit prevents 120, record the constraint and keep that task open while optimizing. Do not quietly lower the target or flood the UI with invalid entries. Do not require every asset to remain resident at once.

Keep the six-piece hand in turn-based modes. Its refill distribution draws from enabled, compatible theme packs and preserves reliable structural choices. Solo Creative gets a searchable catalogue with category, shape dimensions, color, theme, favourites/recent items and rotatable thumbnails. Mixed-bag solo follows the bag rules. Unlocking the full catalogue must not give online players an unauthorized inventory bypass.

## Content pipeline and acceptance

Prefer reviewed original procedural shapes for simple bricks and a curated, legally redistributable source for complex parts. LDraw/Nova can assist import/authoring; consult [ASSETS.md](ASSETS.md), record each source file's actual licence, and preserve required attribution. A download being free is not a grant to relicense it as CC0. Do not import whole themed franchises or branded characters by assumption.

For every part record stable ID/version, source/author/licence/modifications, dimensions, local anchor, connector types/poses, allowed orientations, render mesh, collision proxy, thumbnail, category/theme tags, bag weights and resource costs. Keep geometry separate from collision: the current mesh builder renders collision boxes, which cannot faithfully produce every slope/curve. Add appropriate mesh generation or conversion rather than naming a rectangular box a detailed part. Preserve usable door/window/arch openings.

Provide an offline, reproducible import/normalization/validation pipeline. Pin conversions and source versions; precompute thumbnails and optimized assets. Include deduplication, missing-dependency checks, malformed-geometry checks, connector visual inspection and representative part-pair fixtures. Keep finite budgets for vertices, materials, textures and instances and measure them in the integrated scene.

Package a compact starter subset and load additional reviewed packs as needed. Web downloads need progress, cancellation/retry, caching/version checks and honest offline availability. Required pack versions must be available or clearly identified when reopening a save; never replace unavailable parts silently. Include pack sizes and catalogue counts in evidence. Extend content only after PC-01 through PC-09 and the render/phone budget applicable to that wave hold; lack of phone hardware leaves that evidence open, while source preparation and desktop/browser checks continue.

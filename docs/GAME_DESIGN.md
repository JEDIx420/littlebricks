# LittleBricks game design

## Product promise

**Build together, one brick at a time. Step inside the result. Keep its story.**

LittleBricks is a cozy tabletop construction game for touch and desktop. Players receive mixed themed bricks, take timed turns placing one brick, agree when the scene is finished, then place toy-sized explorers and walk through it. A construction film turns the saved sequence into something shareable. Offline solo play includes the same exploration and film rewards.

This document specifies proposed defaults for implementation and testing. The user's defining requirements are one-brick turns, mixed bags, optional rotation and snapping, a shared tabletop/baseplate, group agreement to finish, explorer POV, construction films, solo play, open source, and Android release. Changes to numerical defaults are welcome when measured; dropping these requirements needs an explicit product decision.

The 2026-11-11 refinement adds the detailed [opening screens and player journey](EXPERIENCE_DESIGN.md), [music, clicks, haptics and visual presentation](AUDIO_VISUAL_SPEC.md), and [placement/camera repairs plus a larger catalogue](PLACEMENT_AND_CATALOG.md). These specifications supersede earlier minimal presentation/catalogue defaults. They are requirements to implement and verify, not descriptions of finished features. Follow [RECOVERY_PLAN.md](RECOVERY_PLAN.md) for their delivery order.

## Modes and session flow

| Mode | Behavior |
| --- | --- |
| Solo | Offline construction with no timer by default; mixed-bag challenge or a free-choice supported catalogue, save/resume, undo/redo, exploration, and films. No account required. |
| Pass-and-play | Two to four local players share one device and the same cooperative turn rules. Keep each player's hand identifiable. |
| Private online | Two to four players join an invite room. The server owns inventory, deadlines, accepted moves, roster, and phase. Rejoining restores the accepted state. |

Session phases are lobby, building, finish agreement, exploration, and export/viewing. Export operates on a frozen revision and must not consume a turn or alter the live creation. Returning to construction makes a new editable revision while preserving the previous save.

The initial objective is cooperative expression. There is no mandatory winner or AI aesthetic judge. Small optional prompts such as “harbour hut” or “forest shelter” give direction without dictating a solution.

## The table and inventory

Start with one attractive table, a bounded 32 × 32-stud plate, comfortable light, restrained shadows, tactile placement sound, and clear depth cues. A small optional terrain/foundation can make a short session productive. Keep the art original and optimize lighting for the shared renderer baseline.

Each multiplayer player sees six selectable pieces by default. An accepted placement refills the empty slot from a seeded theme distribution until the group finishes. Give every distribution reliable structural pieces alongside openings/roofs and decorations. Record explicit accepted inventory changes so future random-generator changes cannot rewrite old sessions.

Begin with Harbour and Forest Cabin, sharing compatible core shapes. Themes alter palettes and piece weights and add a few reviewed specialty pieces. Do not combine unrelated models solely because their downloads are free. Follow [ASSETS.md](ASSETS.md) for scale, connection metadata, dependencies, and rights.

## A building turn

1. The active player selects a piece and previews a legal position.
2. They rotate or reposition freely before committing.
3. Pressing Place requests one placement. A legal accepted move consumes that piece and advances the turn exactly once.
4. A rejected move explains the issue and leaves inventory and turn ownership unchanged.
5. The initial timer is 20 seconds maximum, adjustable or disabled. Expiry skips the turn and preserves the piece; it never commits an unconfirmed ghost.

Non-active players may inspect, rotate, and tentatively prepare their next piece. Revalidate that preview against the current build when their turn arrives. Keep free camera inspection available while watching.

Solo offers full undo/redo. Cooperative correction applies only to the latest accepted placement before a subsequent accepted move and requires group agreement. Represent the correction as a new event, restore the appropriate inventory/turn state, and clear finish votes. Never delete history or silently remove a supporting piece below later work.

## Controls and placement feedback

| Action | Touch | Desktop |
| --- | --- | --- |
| Select and position | Tap a piece then a target, or drag a finger-offset ghost. | Select from tray and position with pointer. |
| Rotate | Large left/right quarter-turn buttons. | Visible buttons plus configurable keys. |
| Commit | Explicit Place button. | Place/Enter through the same command path; any optional direct-placement click is limited to the owned canvas gesture and never GUI/camera input. |
| Inspect | Two-finger camera gesture, pinch zoom, top-view shortcut. | Orbit/pan controls and wheel zoom. |
| Stack / reveal interior | Height/layer selector and hide-upper-layers control. | The same controls with shortcuts. |

Use an outline/icon and short text in addition to color for invalid placement. An obstructed target must not become an accidental commit. Reserve the main finger/pointer interaction for the active placement; make camera gestures distinguishable.

Auto Height follows the intended support surface and returns to layer 0 over uncovered baseplate. Manual Height and Return to Base remain visible alternatives. Remove the current unconditional post-placement layer increase. Use one canonical anchor/connector transform for previews, visible studs, colliders, accepted state and replay; a 1x4 on a 2x4 must visibly lock to an actual stud row. Camera orbit, pan and zoom must work with discoverable mouse/trackpad/touch controls, including an explicit Camera mode.

Placement uses exact grid transforms, upright parts, and four yaw orientations initially. Enforce board/height limits, body collision, and compatible attachment to an anchored structure. Render studs and sockets independently of simplified collision volumes. Digital connection validity is the promise; physical stability or universal real-world buildability is not established.

## Agreeing to finish

Every active participant can choose Ready to Explore for the current build revision. Exploration starts only when all active participants agree. New accepted placements or roster changes invalidate existing readiness.

A disconnect is not a vote. Show a grace period and explicit roster state. After that period, the room's documented departure/removal rule may change the active roster; remaining participants then agree on the revised roster. Provide save-and-leave rather than leaving a session permanently stuck. Solo transitions immediately on the player's request.

## Becoming a tiny explorer

Freeze the agreed build and offer valid character spawn locations. A location needs foot support, sufficient body/head clearance, and no overlap with solid geometry. Every player can place an original toy-sized character and switch between first- and third-person cameras.

Use direct touch-stick/look or WASD/mouse movement. Match character scale to doors, steps, rooms, and camera clipping distances early. Smooth simplified colliders let characters walk over decorative studs. Provide Reset Figure and Return to Table throughout exploration. Optional roof hiding helps inspect interiors but must not conceal broken collision.

Automatic navigation, NPC routines, vehicles, combat, and mechanical simulation are later opportunities. The initial reward is exploring what the group actually made.

## The construction film

Replay accepted construction events on a separate timeline, removing the time players spent thinking. Use a stable camera or gentle orbit, brief piece appearances, and a final reveal. Provide portrait and landscape framing with the whole creation visible; add square output if the initial presets are reliable.

Preserve catalogue/rule versions, explicit transforms, accepted corrections, and the final build identity. Construction replay must remain possible after save/reopen. Handle missing or unsupported data explicitly rather than substituting different pieces silently.

Android receives actual MP4 export and share-sheet integration. Browser output uses a format supported by that browser, with a clear explanation when recording is unavailable. Every export has progress, cancellation, cleanup, and a usable error state. The exported clip must play outside the game. Implementation and failure cases are specified in [ARCHITECTURE.md](ARCHITECTURE.md) and [VALIDATION.md](VALIDATION.md).

## Scope, accessibility, and learning

Target compact scenes of roughly 60–100 placements. At an illustrative 15 seconds per placement, 200 pieces require 50 minutes; four full 20-second turns mean roughly a minute of waiting between a player's turns. These calculations motivate testing, not claims about actual play speed.

Keep readable controls, adjustable sound, reduced motion, timer-free sessions, and non-color-only cues. Test touch comfort and waiting with actual users before growing the catalogue or room size. Observe whether players start another scene, explore voluntarily, reopen a save, and export a clip.

Public galleries, matchmaking, advertising, paid randomized inventory, and elaborate social systems are outside the initial scope. Private shared builds still require the applicable user-content safeguards and an honest audience decision before release. See [PROJECT_PLAN.md](PROJECT_PLAN.md), [STATUS.md](STATUS.md), and [AGENTS.md](../AGENTS.md) for delivery boundaries and progress.

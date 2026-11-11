# LittleBricks: a game families want to keep playing

## Status and scope

**Implementation brief, 2026-11-11. Source baseline: `81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`.** This document turns the existing [player experience](EXPERIENCE_DESIGN.md) and [audio/presentation specification](AUDIO_VISUAL_SPEC.md) into a concrete next art, interaction, and audio pass. Execute it through the LB-057–LB-067 work in [PLAYTEST_REPAIR_PLAN.md](PLAYTEST_REPAIR_PLAN.md). It supplements those contracts; it does not replace the placement, networking, save, replay, Android, or release requirements.

The user reports a dark, uninviting opening and a browser interaction in which the selected brick feels stuck at the centre. The table below records source findings at the pinned revision. The coordinating reviewer subsequently supplied live browser observations, identified separately below; the accompanying playthrough evidence owns the exact session, captures, and tested-build details. **No music audition is claimed.** A source fix, screenshot, or headless test alone cannot establish an enjoyable game.

The intended result is a bright, warm craft table that a child and parent can understand together: choose a piece, move it freely, hear and see it click into place, take turns, then proudly explore and watch their creation grow. Preserve solo Mixed Bag and Free Build, local Pass & Play, private online rooms for 2–4 people, one-brick turns, themed hands, adjustable timers, original toy explorers, saved history, and genuine construction films. Working inputs and accurate connections are prerequisites for approving presentation.

## Contents

- [Required changes](#what-this-revision-must-change)
- [Art direction and screen composition](#art-direction-and-reusable-tokens)
- [Interaction states](#interaction-states-players-can-understand)
- [Finished creation and exploration](#reward-the-creation-then-preserve-it)
- [Music, sound and haptics](#music-sound-and-haptics-repair-and-audition)
- [First five minutes](#first-five-minutes-observable-journey)
- [Review rubric](#family-fun-review-rubric-and-delivery-evidence)

## What this revision must change

| Source finding at the baseline | Required outcome |
| --- | --- |
| `welcome_screen.tscn`, `mode_select.tscn`, and `setup_screen.tscn` use full-screen dark `ColorRect`s and default controls; mode cards use emoji. | Implement one intentional visual system across the actual routed screens, including original tabletop imagery, readable typography, and visible interaction states. |
| Mode selection uses a fixed 920-unit horizontal container; setup uses a fixed 520-unit panel. | Reflow the content at narrow widths and test rendered target sizes. Scaling an entire desktop screen down does not establish mobile usability. |
| `main.gd` builds the hand and catalogue from text-only buttons and permanently exposes rule codes and coordinates. | Let players recognize pieces visually; use concise help near the action. Keep diagnostics available behind a developer option. |
| `part_mesh_builder.gd` renders non-character bodies from collision `BoxMesh` volumes plus studs. Several named shapes share the same geometry: Fresh Fish 1x2 matches Tile 1x2; Cone 1x1 and Round Brick 1x1 match Brick 1x1. The newer Bridge Arch 1x8 is solid, although some older arches have multi-box gaps. | Separate authored visual geometry from collision/placement proxies, preserve stable part IDs, and verify recognizable shapes in rendered contact sheets. Renamed duplicate boxes do not count toward the 120 genuine buildable-shape commitment. |
| `app_root.gd:272–274` routes My Builds to mode selection. | Provide a real creation library backed by saved data, with honest empty, loading, corrupt-save, and failure states. |
| Music files are 16-second mono WAVs; ambience files are 10 seconds. The WAVs contain no embedded loop markers, imports use the default loop setting, and `AudioDirector` contains no loop/restart setup. `unlock_audio()` has no caller. | Inspect the imported/exported stream settings, repair deliberate activation and sustained playback, then audition coherent longer musical phrases. Do not infer audible looping from a filename or source comment. |
| `app_root.gd:43–44` restores hard-coded channel volumes; the Welcome mute callback only changes the audio owner. Player gain and bus gain both apply channel/master settings in `audio_director.gd`. | Restore the complete settings snapshot before playback; synchronize and persist every mute surface; apply user gains once in the intended mix path. |
| Finish routes directly to exploration; `frame_creation()` has no production caller; exploration ignores its `theme_id` argument. Routed screens expose no Watch Build/film flow. | Integrate a real finished-build presentation with Explore, Watch Build, and Keep Building; preserve theme, saved revision, and settings throughout. |

Relevant implementation boundaries are the existing `game/client/scripts/app_root.gd`, routed scenes/controllers, `main.gd`, `table_view.gd`, `presentation_controller.gd`, `audio_director.gd`, `interaction_feedback.gd`, and `settings_manager.gd`. Reuse these boundaries where sound; do not add parallel mock menus or another unmanaged audio owner. The input owner must resolve the actual application-root event path before a visual pass can pass review.

**Live review additions from the coordinating reviewer:** the opening rendered as dark default controls; several icon glyphs rendered as missing-character boxes. The catalogue clipped its fourth column, its scroll gestures also zoomed the table behind it, and long debug messages pushed important HUD actions outside the viewport. Exploration opened directly on a large generic block figure facing away from the creation; first-person view initially showed sky/table rather than the build. Returning changed a placed brick's visible color. Preserve these as reproduction cases, not aesthetic preferences. Camera-mode orbit and wheel zoom did work in that session; the repair must preserve them while fixing ownership and discoverability.

## Art direction and reusable tokens

Use a sunlit craft table, softly polished plastic, clear silhouettes, and friendly scale. The small creation is the visual subject. Harbour uses blue water and sandy details; Cabin uses moss and warm timber. Keep the interface familiar when themes change. Build imagery may use the real engine and original sample assemblies; licensed artwork is another option. Every visible asset needs a documented source and redistribution rights. Do not present a concept image as an implemented screen.

Create a shared Godot `Theme` and reusable controls rather than styling each scene independently. These are starting tokens to implement and tune against real captures:

| Token | Starting value and use |
| --- | --- |
| Canvas / surface | Warm cream `#FFF4DF` / pale paper `#FFFBF1`; avoid a full-screen near-black opening. |
| Primary text | Deep ink `#24343B`; body text must remain readable on every retained surface. |
| Primary action | Deep teal `#21685B` with light text; one visually dominant action per screen. |
| Playful accents | Coral `#ED795F`, butter yellow `#F4CA68`, and sky blue `#73B7D0`; use ink labels and verify contrast. Do not use accent color alone to communicate state. |
| Structure / errors | Soft warm border `#D8CCB7`; readable error ink `#9C3343` with a symbol and plain message. |
| Spacing / shape | Base spacing 8 logical pixels; use 8/16/24/32 consistently. Panel radius about 20, action radius about 14, with a restrained lower edge/shadow suggesting a tactile surface. |
| Type | One bundled, redistribution-cleared, rounded sans family. Body 18, secondary 16, button 18–20, section title 28–32, Welcome title 40–56 logical pixels. Use actual weight variants and test missing glyphs. |
| Targets / focus | At least 48×48 logical pixels for primary touch actions, with separation and safe-area insets. Verify effective rendered size. Give keyboard focus a visible outline distinct from hover and selection. |
| Motion | Press feedback 60–100 ms; panel transitions 160–220 ms; accepted placement settle 80–140 ms. Input remains responsive during transitions. Reduced Motion removes translation, bounce, and automatic camera movement. |

These values are design proposals, not measured accessibility results. Test contrast, effective size, text expansion, focus order, and phone screenshots before retaining them. Replace platform-dependent emoji with a bundled, consistent SVG/vector or original mesh icon set and text labels. Verify every icon in the exported browser and native builds; missing-character boxes fail acceptance. The font must cover the actual text, but essential controls must not depend on an operating system's emoji font.

### Screen composition

**Welcome.** At a wide viewport, give roughly three-fifths of the composition to a well-lit miniature harbour or cabin on a wooden table. A few loose bricks at its edge explain what can be touched; keep the central build uncluttered. The remaining area holds the wordmark, one short promise, and Play. Place My Builds and Settings as secondary actions; Sound stays immediately accessible. If a valid recent creation exists, use its real thumbnail/name for Continue and keep Play available. On a narrow display, stack the vignette above the actions, shorten decorative space, and keep the primary action visible without scrolling. A lightweight static image of the same scene is an acceptable measured fallback.

The optional idle motion is a subtle toy detail or light movement every few seconds, not continuous camera rotation or a screen full of particles. Tapping Play gives immediate visual response. No mandatory splash, account, or sound permission screen precedes offline play.

**Mode selection.** Use three picture-led cards: one builder and a small creation for Build Solo, two distinct player markers around one table for Pass & Play, and separate tables connected by a room invitation for Play Online. Use the existing one-sentence explanations. Make the entire card focusable/activatable with one clear selected state; avoid nested competing click targets. At an effective wide width around 960 logical pixels and above, use three columns; below that, use stacked cards with the illustration beside the text. Adjust the breakpoint from measured content fit. Back is always visible.

**Contextual setup.** Show a live or correctly generated theme preview beside a compact settings panel; stack it above on narrow screens. Theme choices are visual thumbnails, not only a dropdown. Solo starts with Harbour, Mixed Bag, and no timer; Free Build explains the full parts library. Pass & Play displays player name plus distinct marker, starting with two people, and clearly labels the timer choice. Keep the existing 20-second default and allow off/30/45 seconds without burying the control. Additional options may collapse; the summary beside Start Building must name the actual chosen mode, theme, players, and timing.

Online Create/Join leads to the real lobby, actual participant readiness, and connection results. Do not produce a populated local table to imply that a network room exists. Preserve setup on errors and offer retry/back. Disable duplicate Start submissions and provide meaningful loading feedback.

**My Builds.** Present real thumbnails with name, theme, and last saved information. Each card opens that creation; a secondary menu offers Rename and Delete. Confirm deletion against the named creation. Show a useful empty state with Start Building. A failed save remains recoverable and does not display “Saved”; a corrupt save is identified without deleting it. Continue and the library must open the same saved model and documented recovery phase. Returning from a build should update its card, not create a fabricated sample entry.

### The building table

Reserve the centre for the model and free camera gestures. Use a compact top row for creation name, current player/turn, and a menu. Put the actual hand at the bottom; the selected piece receives a clear thumbnail, color, dimensions, and highlighted border. Keep Place and Rotate near the held piece controls, with Cancel always accessible. Group height and camera tools into labelled controls; advanced height changes must not occupy most of the play surface. Move coordinates, yaw, and rule identifiers into a developer overlay.

Constrain or wrap status text within an allocated region so a long message cannot displace Save & Leave, Settings, or other actions. Derive catalogue column count from the available content width; every card, close control, and scrollbar must remain reachable. Verify narrow windows and phones at normal browser zoom. Reflow, collapse secondary controls, or use a deliberate supported orientation; tiny scaled-down desktop controls do not pass. Scrolling a tray or catalogue consumes the gesture and never zooms the world underneath.

On touch, controls sit within safe areas, the tray scrolls independently, and the preview has an offset/placement aid so a finger does not hide the target. On desktop, the world remains available for normal mouse movement. Do not capture the pointer during tabletop building. Any exploration pointer capture has an explained exit and must release on return to the table.

In Free Build, the library uses cached, recognizable thumbnails from each actual supported mesh, category filters, search, dimensions, and favorites. Do not generate a spinning 3D viewport per catalogue cell. Display only supported choices; count unique buildable shapes separately from colors and characters. Mixed Bag and multiplayer retain their actual inventory rules; browsing must not bypass a six-piece hand. Preserve the larger catalogue commitment and its validation requirements in [PLACEMENT_AND_CATALOG.md](PLACEMENT_AND_CATALOG.md).

### Make the themed parts real

Give each supported part distinct visual mesh data or a suitable procedural shape builder, separate from simplified placement volumes and walking colliders. A slope needs a sloping surface, a cone must taper, a round brick needs a round body, a fish needs a recognizable body/tail silhouette, and an arch needs its intended opening. Keep colliders economical without filling a walkable doorway or advertising unsupported attachment points. Preserve existing stable IDs and saved references; mark unsupported entries honestly until repaired, and explicitly migrate any unavoidable schema change.

Deliver a recognizable Harbour kit and Cabin kit that can make the scenes promised by setup: structural bricks/plates, usable openings, roof forms, and distinct theme details. Verify the whole assembly, not only isolated thumbnails. Generate contact sheets from the actual game meshes with stable part ID, name, dimensions, and a common camera/light; include alternate views for openings and slopes. Compare thumbnail, held preview, placed mesh, and exploration mesh for the same part. Audit the reported fish/tile, cone/round-brick/brick, and bridge-arch cases directly. A renamed identical box, a recolor, a decorative label, or a character must not inflate the count of at least 120 genuine supported buildable shapes. Record the corrected count and remaining gaps instead of preserving an unsupported headline number.

## Interaction states players can understand

Agree and implement these states through one input owner. Labels may be shortened after testing, but the distinctions must remain observable. No state transition may spend a turn or emit an accepted-placement reward without accepted game authority.

| State | Visible behavior | Input and exit contract |
| --- | --- | --- |
| Idle | No brick attached to the pointer; tray and a short “Choose a brick” hint are available. | Enter here at a new table. Selection begins holding. The pointer remains free; camera controls work. |
| Holding | Thumbnail is selected; a manipulable ghost shows the exact candidate connection. Place/Rotate/Cancel are visible. | Mouse motion or tap/drag positions the preview. Use explicit Place to commit. Selection gestures and tray scrolling do not commit. Cancel or Escape clears the hold without placing. |
| Holding, invalid | Ghost remains controllable; a symbol and brief nearby explanation show why Place is unavailable. | No sound or vibration on every movement. Moving to a legal surface recovers immediately; there is no forced stacking lock. |
| Camera | A readable Camera indicator and gesture hint are present; held selection is suspended without losing it. | Orbit/pan/zoom never places or rotates a brick. Ending a temporary gesture or leaving Camera restores the prior hold/idle state. Release outside the canvas, pointer cancellation, and lost focus clear drag capture. |
| Placement pending | The submitted location is visibly pending; repeat submission is disabled. | Wait for authority. Acceptance settles the exact accepted piece once; rejection preserves a recoverable selection and reason. No premature success sound. |
| Modal / pause | Settings, catalogue, or another panel owns its region and focus. | The covered game cannot place, rotate, or pan underneath. Escape closes the top panel first and restores focus. Local pause stops the timer; online personal menus accurately explain that room turns continue. |

Default Place/Enter confirms the displayed world candidate. Moving onto the placement toolbar preserves that candidate; a miss over uncovered world clears it. Never raycast the UI button position when confirming. If an optional desktop world-click-to-place preference is offered, resolve that world click itself before validation. Intentional Place/Rotate buttons are allowed actions; all other UI-owned gestures must produce zero unintended world changes. See the exact contract and PT-03 in PLAYTEST_REPAIR_PLAN.

After a local accepted placement, return to an obvious idle state by default; a deliberate repeat-placement preference may retain a piece in Free Build if its state and exit are clear. After a shared turn, show the next named player and their real hand. Give the recipient a calm, readable handoff; do not flash a large celebration on every brick.

Normal messages include “Choose a brick”, “Ready to place”, “Needs support”, “Space is occupied”, “Back on the baseplate”, and “Your turn, Sam”. Do not show `[INVALID] FLOATING` or raw coordinates to children. Keep a short cause plus useful next action, without covering the target. Status feedback must not continually change the width of the entire top bar.

The first three helpful hints live beside the real tray/preview: choose and move, rotate, then stack. Dismiss or skip them; mark progress from accepted actions, not elapsed time. Include moving away from the first brick and placing separately on the baseplate in the introductory sequence. Keep Help available later.

## Reward the creation, then preserve it

After solo Finish or actual multiplayer agreement, save the frozen revision and show a clean showcase. Frame the real combined mesh bounds, including large and rotated parts; pivot-only bounds are insufficient. Keep the whole creation inside the safe frame. Use a short optional camera settle of about 1 second with immediate Skip; Reduced Motion cuts directly to the final framing. The player can then orbit manually.

Present **Explore**, **Watch Build**, and **Keep Building** together. Use the creation's real name and one short congratulatory line. A restrained musical resolution and a tiny visual accent are enough; do not hide the creation under confetti. Save failures must be actionable and must not discard the model.

Explore provides figure selection/valid spawn preview, a clear Place Figure action, first/third-person controls, Reset Figure, and Back. Give the original toy explorer a readable front, recognizable proportions, and a scale that fits the declared door/interior fixtures. Choose initial spawn, facing, and camera composition together: show the actual creation or its entrance immediately, with the figure oriented toward it. Both initial third-person framing and the first-person toggle must show a useful route into the build, rather than only sky, the table, or an obstructing oversized figure. Reset Figure restores a valid useful view. Carry the same theme and readable materials into interiors.

Watch Build plays the accepted construction history with pause, restart, pace, framing, and genuine export controls. Keep Building restores the preserved session/revision rules and releases exploration input capture. Assert that the explore/return/save/reopen round trip preserves every part ID, color, transform, and intended placement relationship; specifically reproduce the reported color change. Offline solo still supports the complete loop.

Make the rendering attractive in Compatibility with a warm key light, restrained fill, readable contact shadows, softened plastic highlights, and a calm backdrop. Test white, black, saturated bricks, roof undersides, doorways, and tall creations. Warm wood needs visible surface character or carefully authored geometry; changing a flat box's brown value alone does not complete this direction. Bevel appearance and shadow softness must remain within the measured budget. Optional haze, glow, blur, or automatic orbit cannot be prerequisites for a good-looking table.

## Music, sound, and haptics: repair and audition

Keep the existing semantic event contract in [AUDIO_VISUAL_SPEC.md](AUDIO_VISUAL_SPEC.md). Implement the following deltas before approving new assets:

1. One persistent audio owner applies saved Master/Music/Effects/Ambience, mute, and haptics preferences at startup. Every visible sound toggle reflects that same state and persists it. Opening Settings must not change saved values through initialization signals.
2. Deliberate first user interaction activates supported browser audio. Confirm playback capability; a blocked context remains silent and playable. Test fresh, returning muted, and focus-restored sessions separately.
3. Configure actual imported/exported loops or an explicitly tested continuity mechanism. Never treat a synthesized file's “seamless” comment as playback configuration. Avoid same-track early returns that leave a finished player silent.
4. Apply user channel/master gain once; reserve per-player gain for asset calibration, variation, and ducking. Route UI and brick effects intentionally. Crossfade incoming and outgoing tracks, clean up competing tweens/voices, and stop or transition theme ambience when leaving its context.
5. Provide two coherent instrumental cues, initially targeting the existing 60–120-second range: an inviting menu phrase and a spacious building arrangement. Use a memorable, gentle motif with variation and rests. Prefer tasteful mallets/plucks/keys and restrained rhythm. Asset generation is permitted, but a short sine arpeggio is not automatically an approved musical identity.
6. Give the accepted brick click a recognizable plastic contact and soft body, with a small set of closely matched variations. Pickup, rotation, rejection, turn handoff, and finish remain distinct and quieter where appropriate. Camera gestures, UI selection, restore, and reconnect never impersonate accepted placement. Deduplicate by session and accepted event identity.

Retain original or distribution-cleared sources, checksums, edits, loop points, duration, and film-use rights. Do not add music that users cannot legally include in the promised construction films.

**Audio acceptance requires listening:** record the exact build/device, settings, actions, and listener's observations. Listen through more than two full cue lengths in the exported game, including both boundaries; check for silence, clicks, abrupt harmony, excessive repetition, and duplicated players. Perform 50 varied placements, rapid rotations/undo/rejections, navigation, mute/unmute, reload, and background/restore. Confirm separate sliders do what their labels say and quiet settings still preserve useful feedback. A complete silent session must work. Listen on speakers and headphones where available; do not claim an unavailable path passed.

For haptics, verify one pleasant, brief accepted-placement pulse on a supported physical Android device, enabled/disabled/system-suppressed paths, and a complete unsupported-browser fallback. Calls or emulator logs cannot prove a physical sensation. Export a real short film with the chosen sound mode and open it in another player; hearing game audio does not establish audio in the exported file.

## First five minutes: observable journey

The times below describe a target experience for a new player, not a deadline imposed on a child. Use a small versioned starter fixture with ordinary bricks, a plate, and an opening; preserve normal rules and record if Help was needed.

| Approximate point | What the player does | Observable acceptance |
| --- | --- | --- |
| 0:00–0:20 | Recognize a toy-building game and select Play. | A bright creation is visible before interaction; Play is obvious; Sound and Settings are findable; input responds immediately. |
| 0:20–0:45 | Choose Solo and inspect/change the table theme. | Pictures explain modes; the selected theme visibly changes the preview; Start describes the real session; there is no mandatory form burden. |
| 0:45–1:30 | Select a brick and place it on the plate. | Ghost follows the intended target, exact studs align, the accepted click/settle happens once, and the pointer can return to idle. |
| 1:30–2:30 | Place a second brick away from the first, rotate a narrow brick, and stack it. | Separate base-level placements work without hidden shortcuts; stacking aligns; friendly feedback recovers from one deliberate invalid target. |
| 2:30–3:15 | Orbit, pan, zoom, cancel selection, and resume. | The player can see another side; no camera gesture places a brick; no UI press changes the world; lost focus does not trap a drag. |
| 3:15–4:15 | Add a few pieces and finish the small creation. | Thumbnail selection is understandable, music continues unobtrusively, and the showcase frames the actual model with clear next actions. |
| 4:15–5:00 | Explore briefly, return, save, and reopen from My Builds. | Figure controls are explained, the doorway/interior is readable, the model survives the round trip, and its actual library thumbnail opens the right build. |

Do not force a large house into five minutes or fake results to meet the timing. The full verification continues beyond this introduction: real Pass & Play handoff, connected online clients, finish agreement, sustained music, construction replay/export, and physical-device checks remain required. For usability sessions, retain the existing proposed targets of at least 90% intended basic placements without help after onboarding and a median under ten seconds; record sample size, assistance, failures, and limitations.

## Family-fun review rubric and delivery evidence

An independent verifier reviews the actual routed build, not an isolated mockup. When family playtesters are available, watch a pair share one device and record observed actions and their actual words. If participants or audio capture/listening are unavailable, label those checks NOT RUN or BLOCKED and complete the independent engineering checks; never invent reactions.

Score each dimension 0–3: **0** broken/absent; **1** technically present but confusing or unfinished; **2** clear, coherent, and pleasant through a complete journey; **3** repeatedly delightful or effortless, supported by observed behavior. A proposed release-quality threshold is every dimension at least 2, with no functional blocker. The score does not replace the written evidence or allow an attractive screen to average away broken placement.

| Dimension | Evidence the reviewer must supply |
| --- | --- |
| Invitation | Real Welcome/setup captures; explain what makes Play and the building promise immediately understandable. |
| Agency | A continuous pointer/touch recording showing separate ground placements, accurate stacking, cancellation, and camera recovery. |
| Tactile reward | Accepted/rejected action traces plus actual listening; one satisfying confirmation per accepted move, no feedback storm. |
| Shared play | A real handoff in which both players can identify whose turn it is and what pieces they can use. |
| Creative clarity | Successful selection of a desired recognizable shape from the thumbnail library/hand; rendered contact sheets matching the claimed catalogue; understandable recovery from an invalid move; and an uncluttered model view. |
| Pride and continuity | Actual reveal, interior exploration, preserved return, save reopening, and a playable exported construction clip. |
| Comfort | Small-screen readability, keyboard focus, reduced-motion and muted journeys, and measured sustained behavior on declared targets. |

Retain Compatibility as the shared baseline and the original performance goals: a versioned representative 500-piece scene at least 30 fps after 15 minutes on a named midrange Android device, and a genuine 15-second 720p/30 fps phone film with bounded memory. These remain targets until measured. Record frame-time spikes, total memory, load behavior, thermal degradation, and table/interior views; a small static headless memory number is not a phone/browser budget result. Budget thumbnails, vignette rendering, audio, shadows, and transparent UI together. Use cached/static artwork, bounded audio voices, and reduced optional effects where measurements require it.

Deliver real before/after captures at desktop, phone landscape, and narrow portrait sizes, or clearly document and test the supported orientation policy. Record exact source commit, exported build identity, engine/templates, browser/OS/device, input method, fixture, settings, outcomes, and remaining blockers. Update the evidence ledger only after inspection. Completion means the real family building experience satisfies these criteria together with the original functional scope; another default UI with more buttons does not close this brief.

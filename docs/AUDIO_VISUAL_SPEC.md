# Audio, tactile feedback, and presentation

> Current implementation work follows [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md) and the concrete [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md) brief. The latest [live/source review](evidence/README.md) supersedes completion claims; this document remains a requirement contract, not proof of implementation.

## Scope and present implementation

This is an implementation specification, not evidence of shipped polish. Read [EXPERIENCE_DESIGN.md](EXPERIENCE_DESIGN.md), [GAME_DESIGN.md](GAME_DESIGN.md), [ASSETS.md](ASSETS.md), and [VALIDATION.md](VALIDATION.md). All numerical values below are starting proposals to audition and measure.

At review commit `9eaeda86ed867a002aa034b12e66d211f8c26432`, `SettingsManager` stores a sound toggle and master volume, but those settings do not establish an audible game. The main placement controller is separate from session flow; the exporter contains success-returning placeholders and replay submits a solid-color image. Implement the real integrated journey before treating a sound, effect, or export test as completion.

The desired character is a small, inviting tabletop: warm music, clear plastic contact sounds, restrained touch feedback, readable bricks, and a beautiful finished creation. Feedback must explain an action without competing with building. Sound, vibration, and animation are independently optional; successful play never depends on hearing, color recognition, or a vibration motor.

## Responsibilities and contracts

The coordinator owns the application/session event contract and settings migration. Specialists may implement these proposed boundaries under agreed file ownership; the paths are proposals, not existing APIs.

| Component | Proposed responsibility |
| --- | --- |
| `game/client/audio/audio_director.gd` | One persistent audio owner; music/ambience transitions, pooled effect players, bus volumes, focus changes, and export mix routing |
| `game/client/feedback/interaction_feedback.gd` | Translate semantic interaction and accepted session events into sound, animation, and optional haptics |
| `game/platform/haptics_adapter.gd` | Platform capability/policy, enabled preference, short discrete feedback, and an honest unsupported fallback |
| `game/client/presentation/presentation_controller.gd` | Table/exploration/showcase environment presets, camera transitions, quality selection, and reduced motion |
| Existing `settings_manager.gd` | Versioned master/music/effects/ambience volumes, mute, haptics, reduced motion, and quality preference; migrate existing settings safely |

Publish semantic events such as `piece_selected`, `rotation_changed`, `placement_preview_changed`, `placement_pending`, `placement_accepted`, `placement_rejected`, `turn_changed`, and `build_finished`. Include session identity, stable command/accepted-event identity, actor, placement, and context (`live`, `replay`, or `restore`). The audio layer never changes inventories, turns, transforms, or networking state.

For live accepted placements, deduplicate by session plus accepted-event identity. A retransmitted acknowledgement must not repeat the click, visual settle, or vibration. A local preview may respond immediately; it must not emit the final success cue before authority accepts it. Remote moves can play a quieter world click, without vibrating the observing player's phone. Restore/reconnect catch-up applies silently. Replay uses its own timeline scheduling and resets its presentation deduplication scope when restarted; it never triggers handset vibration.

Route pointer/touch actions through the integrated input controller. A GUI button press must not also place a brick through global mouse handling. Gate effects on actual semantic changes, not every `_process` frame or repeated pointer sample.

## Music and sound assets

Deliver a small coherent sound set, then audition it in context:

- At least two seamless instrumental cues, initially targeting 60–120 seconds each: a welcoming menu cue and a longer-feeling building cue. Exploration/showcase may use a quieter arrangement of these or a separate variation. Favor soft mallets, plucked strings, restrained piano, or warm pads; avoid vocals, busy percussion, and abrupt dramatic changes.
- Harbour and forest ambience loops with low-density detail. Birds, water, wind, or room tone must remain behind the interaction sounds and be independently adjustable.
- Several short variations for pickup, rotation, brick connection, and rejection; one restrained turn cue, completion flourish, and navigation family. The connection sound should have a clean plastic attack and a small body, without a harsh metallic edge.

Preload the small interaction set before allowing the first placement. Stream or otherwise budget longer music according to the pinned engine's tested import/playback behavior. Trim unintended leading silence, remove clicks at loop boundaries, match loudness between variations, and audition both phone speakers and headphones. Avoid immediate repetition; bound any pitch variation narrowly so a brick does not sound randomly rubbery. Keep important confirmation sounds audible at the default mix without turning the music up to showcase it.

Store source information alongside imported assets: asset ID, original URL/author, exact licence and attribution text, source checksum, edits, loop points, duration, format, and permission to distribute both game assets and user-created films containing the audio. Prefer original recordings/compositions or clearly documented permissive assets. A candidate for adapted interaction sounds is [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds), whose page identifies CC0; still inspect the downloaded archive and record what was actually used. Do not label every future asset CC0 merely because the existing procedural parts use that designation.

## Runtime audio behavior

Use named `Master`, `Music`, `Ambience`, `UI`, and `Bricks` buses or an equivalent documented layout. Apply persisted volumes to actual output, including all new players. A zero slider value must become silence without invalid logarithm calculations. Preserve headroom during rapid actions; establish a bounded voice pool and sensible priorities instead of spawning unlimited players. Optional ducking should be brief and subtle, never pump the whole mix on each stud crossed. [Godot's bus documentation](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html) describes routing, metering, and effect constraints.

Begin the browser audio unlock attempt from the player's first explicit Start/Continue gesture. If it remains suspended, keep the game usable and offer a small sound control; do not repeatedly display blocking prompts. Preserve mute when entering menus, changing themes, returning from a background tab, or opening replay. Crossfade music over a proposed 0.6–1.2 seconds; avoid multiple overlapping music owners. Pause or fade local ambience/music on focus loss and resume deliberately, without replaying missed clicks. Browser autoplay behavior varies, so test the actual unlock path. [Autoplay guidance](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Autoplay)

Godot web's low-latency Sample playback does not support AudioEffects; Stream playback restores engine audio features with latency tradeoffs. Keep short interaction sounds functional without reverb/compressor effects. Implement simple volume transitions explicitly and test the selected music/replay path rather than assuming desktop bus processing transfers to web. [Web audio constraints](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#audio-playback)

## The brick interaction feel

Coordinate sound, visual response, and haptics at the same semantic moment. Initial tuning proposals:

| Event | Sound and visual response | Haptic policy |
| --- | --- | --- |
| Pick up/select a different brick | Soft short pickup; tray selection and ghost appear promptly | Optional light 8–15 ms pulse after deliberate touch |
| Rotate once | Quiet tick; ghost moves to the exact quarter turn | Usually none; avoid rapid buzzing |
| Find a legal preview | Clear outline/symbol; optional quiet tick only on a meaningful validity transition | None while dragging across studs |
| Commit accepted | Crisp click with a restrained 80–140 ms visual settle | One proposed 15–25 ms confirmation pulse |
| Commit rejected | Soft dull tap and readable reason; keep selected brick | At most one gentle pulse if enabled; no long error buzz |
| Cancel/undo | Small release sound; visual state follows accepted undo | None by default |
| New turn / finished build | Quiet cue and readable banner; a short completion flourish | Optional single local cue; never an ongoing pattern |

Keep authoritative placement transforms and collision shapes stable. Apply settle animation to a visual child, not the stored grid transform or supporting collision. Reduced motion removes bounce, breathing, automatic orbit, and camera pushes while retaining a static confirmation cue. Do not shake the screen for routine placements. A pending online move gets an identifiable pending state; network delay is not hidden by a false success animation.

## Haptics across platforms

Godot's `Input.vibrate_handheld()` supports certain native/mobile and browser environments, but desktop is not a handset vibration target. Android requires the export preset's `VIBRATE` permission; browser amplitude cannot be controlled and browser support varies. Device settings can suppress output. Inspect the actual pinned API and preserve a sound/visual fallback. [Godot Input reference](https://docs.godotengine.org/en/stable/classes/class_input.html#class-input-method-vibrate-handheld)

Expose a persistent Haptics toggle where applicable. Honor system settings; do not repeatedly request vibration permission or claim motor confirmation from a void API call. On web, detect the Vibration API and required user activation, handle rejection/no support, and continue silently. Safari is an expected no-vibration case per the Godot documentation; test it as a valid fallback. [Browser vibration](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/vibrate)

Use short, clear feedback sparingly. Native Android may use an audited adapter for predefined semantic effects if the generic pulse feels poor, but do not create a second unmanaged input route or add a broad plugin bundle for one pulse. Android guidance favors consistent discrete haptics and avoiding unpleasant buzzing. Physical testing decides whether a proposed pulse is pleasant; emulator success cannot establish it. [Android design guidance](https://developer.android.com/develop/ui/views/haptics/haptics-principles)

## Lighting, materials, and finished-build presentation

Retain Compatibility as the common baseline. Start with a warm directional key, restrained ambient/cool fill, tuned shadows, softened material highlights, and a calm backdrop. Replace the reported overbright/neon baseplate and flat lighting with a restrained plastic palette and legible depth; soften harsh shadows within the measured budget. Shape bevels and appropriate roughness should make plastic readable at phone scale. Avoid blown-out pale bricks, black interiors, shimmering studs, or transparent overlays over the entire model. Use restrained reflection resources and a small light budget. Any baked lightmap applies only to appropriate static scenery, not arbitrary future player construction. Fix camera access, placement height, and alignment before polishing their presentation; a beautiful but difficult-to-use table does not pass.

| Profile | Starting design |
| --- | --- |
| Economy | Clear lighting/materials; reduced shadow cost and render scale where needed; no optional atmosphere or screen effects |
| Balanced | Better measured shadows/antialiasing; restrained supported contact darkening; default on validated capable targets |
| Showcase | Finished-build framing, gentle optional camera orbit, tested glow/ambient occlusion and atmosphere within budget; immediately reversible |

Current Godot documentation lists Compatibility glow and simplified SSAO, with SSAO described as available since 4.6. Do not copy obsolete blanket claims that these are always unavailable, or enable them merely because a setting exists. Verify the pinned version's implementation and actual browser output. Keep volumetric fog, screen-space reflections, advanced GI, depth-of-field, and expensive custom blur outside the shared baseline unless separately proven appropriate. Prefer attractive light/material composition when an effect is unavailable or too costly. [Renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) · [Environment guide](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)

Offer a small set of consistent lighting looks such as Daylight, Golden Hour, and Studio. Persist the selected look with presentation settings, without changing build rules. Exploration prioritizes visible entrances, readable floors, and stable exposure. Showcase removes editing clutter, frames the whole creation, allows manual orbit, and provides clear Explore/Film/Return actions. Soft effects must not blur the user's creation or obscure touch controls. Record representative large builds, interiors, and bright/dark brick colors before approving a look.

Measure CPU/GPU frame times, memory, audio responsiveness, and sustained temperature behavior on the declared target matrix. The existing 500-piece/30-fps phone target remains an unachieved gate until measured. Gracefully lower optional effects before reducing input responsiveness; avoid rapid automatic quality oscillation. Screenshots alone do not establish sustained performance.

## Replay audio and real exported films

Capture actual rendered replay frames after the frame is ready; remove the dummy-image path. Schedule brick clicks from the recorded accepted-event timeline, independent of original human pauses. Render no UI navigation sounds or haptics into the film. Expose film sound choices: Silent, Brick Sounds, or Music + Brick Sounds, using only assets cleared for that distribution.

Canvas capture supplies a video track; audible film export needs an explicit tested audio-mix path. Do not assume hearing the game proves the recording contains it. Browser export must select a supported MIME type, wait for recorder completion, assemble a real Blob, and offer a working download/share fallback. Release streams/object URLs on completion and cancellation. Native adapters must encode/mux genuine frames and audio and return errors when unavailable. [Canvas capture](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/captureStream) · [MediaRecorder](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder)

## Acceptance evidence

Record exact commit, engine/templates, browser/OS/device, settings, fixture, action sequence, and outcome. Require:

1. A fresh browser visit and returning muted visit: deliberate sound unlock, correct saved volumes, no surprise audio after tab restoration, seamless loops, and a usable silent experience.
2. Fifty varied placements plus rapid invalid/rotate/undo actions: distinct sounds, no clipping or audio stutter, one accepted click per move, no feedback storms on reconnect.
3. Physical Android audition of haptics enabled/disabled/system-suppressed; unsupported browser path remains fully playable. Mark unavailable hardware evidence BLOCKED.
4. Before/after views and sustained measured gameplay for each retained quality profile, including interior exploration and reduced motion.
5. A real downloaded film opened in another player: visible construction, correct final build, audible synchronized click/music when selected, valid silent mode, correct duration, and working cancel/error cleanup.

Headless tests can verify event deduplication, settings, and routing; they cannot approve the sound's feel, a physical pulse, rendered polish, or a movie that was never created. Technical sources above were checked on **2026-11-11**; recheck their version-specific guidance when pinning the implementation toolchain.

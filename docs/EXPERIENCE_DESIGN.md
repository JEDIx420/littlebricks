# LittleBricks player experience

## Purpose and implementation baseline

Make the first minute welcoming, building satisfying, and the finished creation worth exploring and sharing. This specification adds concrete interaction and presentation requirements to [GAME_DESIGN.md](GAME_DESIGN.md). It is a design contract for the next implementation pass, not evidence that these features already work. Numerical values below are initial tuning targets; record changes after listening, playing, and measuring on actual targets.

The reviewed baseline is `9eaeda86ed867a002aa034b12e66d211f8c26432`. [project.godot](../game/project.godot) launches the placement scene. [main_menu.gd](../game/client/scripts/main_menu.gd) emits mode signals without an application-level consumer; [main.gd](../game/client/scripts/main.gd) supplies six fixed parts rather than a connected session hand. [exploration_controller.gd](../game/client/scripts/exploration_controller.gd) and [settings_manager.gd](../game/client/scripts/settings_manager.gd) provide useful starting components. Reuse sound components of that work, then connect and verify the actual player journey. A beautiful standalone menu is insufficient.

The user subsequently ran the browser build locally and reported forced stacking, difficult camera movement, visibly misaligned studs, and too few selectable parts. This establishes a local browser launch, not completion of the browser experience. Fix [placement and catalogue requirements](PLACEMENT_AND_CATALOG.md) before judging polish.

## Visual direction

Use a small, inviting craft table: warm wood, rounded cream panels, deep ink text, restrained sea-green accents, and colourful plastic pieces. Harbour adds cool blue and sandy tones; Forest Cabin adds moss, warm timber, and muted terracotta. Keep the same UI structure across themes. Use one readable type family, a clear heading hierarchy, consistent corner radii, and labelled icons. Original assets and fonts need recorded redistribution rights.

The table and the player's build dominate. Keep decoration outside stud targets. Brick materials read as softly polished plastic with clear edge highlights and contact with the plate. Use brief restrained screen transitions and immediate input response.

## The first three screens

These are the standard new-game path. Continue bypasses setup, and returning players should not repeat an introduction.

### 1. Welcome: a place to return to

Show the LittleBricks wordmark, “Build together, one brick at a time,” and a lightly animated tabletop vignette. Use a compact original sample build initially; a valid local save thumbnail can replace it later. Provide **Play**, **My Builds**, and **Settings**. When a recent save is available, show **Continue** prominently with its name and thumbnail, keeping Play visible for a new creation. Do not invent a saved creation or show a nonfunctional Continue button.

Keep a sound toggle available immediately. Begin sound only after an appropriate user interaction and confirmed playback capability; silence must never prevent navigation. No account, permissions wall, unskippable studio splash, or compulsory tutorial precedes solo play. While initial resources load, retain an informative loading state and a retry route. A background vignette may stop animating to protect responsiveness.

### 2. Choose how to build

Use three large cards with a small illustration, clear title, and one sentence:

| Mode | Player-facing explanation | Next action |
| --- | --- | --- |
| **Build Solo** | Build at your pace, then explore and make a film. | Solo table setup |
| **Pass & Play** | Take turns with 2–4 people on this device. | Local player and table setup |
| **Play Online** | Build with friends in a private room. | Create / Join controls |

Each card works with touch, mouse, keyboard focus, and activation. Back returns to Welcome without losing remembered choices. An offline connection must not disable Solo or Pass & Play. While online implementation or service access is unavailable, explain that state honestly instead of opening a fake connected room; that limitation keeps the online acceptance gate open.

### 3. Set your table

Keep the primary options visible in one compact panel with a live theme preview and one primary action. Put secondary options under a labelled expandable section. Show a concise summary beside **Start Building** so players know what they selected.

| Mode | Required setup | Defaults and behaviour |
| --- | --- | --- |
| Solo | Harbour / Forest Cabin; Mixed Bag / Free Build | Harbour, Mixed Bag, timer off. Allow a short creation name; provide a useful automatic name. |
| Pass & Play | Two to four player names; theme; timer | Two editable names, mixed bags, 20-second turns. Timer can be changed or disabled. Each player gets a name plus a distinct marker. |
| Online create | Display name; theme; timer | Create a real room and show the resulting invitation code; no hard-coded shared room. |
| Online join | Display name; invitation code | Validate input, show joining progress, and report room-full, unavailable, expired, and connection errors with a retry/back route. |

The online lobby is the next state of this setup screen: show actual participants, host, connection/readiness states, copy invitation, leave, and start controls. Show exactly who is waiting. Host Start requires the agreed readiness and minimum player rules; entering a code alone is not proof of connection. Rejoining should offer the previous session when recoverable. Leaving returns to mode selection without disturbing other players' local settings.

Starting prepares the real session, scene, inventory, audio, and input ownership before fading to the table. Disable repeated Start submissions while pending. Loading errors preserve the selected setup and offer Retry. Back from setup preserves choices and returns to the mode cards.

## Navigation, saves, and first-time learning

My Builds shows actual local creations with thumbnail, name, theme, and last saved state. Its empty state explains how to begin. Opening, renaming, and deleting need honest success/error results; destructive deletion must name the selected creation. Invalid saves receive a useful message and preserve recoverable data. Continue restores the saved phase or a documented safe recovery phase, not an empty plate.

Settings is reachable from Welcome and the in-game pause menu. Closing it restores the prior screen and keyboard focus. Back/Escape closes the current panel first. In a local session, pause stops its timer and camera input. In an online session, opening a personal menu must not silently pause the authoritative room; explain that turns continue. **Save & Leave** reports save completion or failure before leaving. Resume, input focus, audio, and pointer state must remain consistent after app backgrounding or browser focus changes.

Teach the first three placements through dismissible hints on the real table:

1. “Choose a brick, move it onto the plate, then Place.” Highlight the tray and valid preview.
2. “Rotate before placing.” Point to the rotation controls; accept a player choosing an equally valid alternative.
3. “Build upwards.” Demonstrate the visible layer control and a supported stacking target.

Use a guided solo fixture with suitable starter parts for this introduction, without changing shared-room rules or inventing successful placements. Complete hints from actual accepted actions. The timer stays off in guided solo. Provide Skip, remember completion, and allow replay from Help. Multiplayer receives brief contextual hints that do not interrupt everyone else's turns.

## Building controls and tactile feedback

Show the active player, timer, selected piece, rotation, height mode, legal-placement cue, and Place action. The six-slot multiplayer tray is the player's actual hand; it must not limit the whole catalogue. Solo Free Build gets a parts browser with category filters, search, readable thumbnails, dimensions, and favourites. Use the same catalogue for theme bags while preserving inventory rules.

Default to **Auto Height** following the intended support surface. Placing one brick must not force every subsequent brick onto its top layer. Offer visible **Manual Height**, up/down controls, and **Return to Base**. Preview the exact final stud alignment, including narrow pieces on wider bricks; half-stud visual errors are correctness failures.

Provide free orbit, pan, and zoom for mouse, trackpad, and touch, with discoverable gesture hints and reset/top view. Camera gestures and GUI clicks cannot place bricks. Reserve drag gestures clearly between moving a preview, scrolling the tray, and moving the camera. Replace debug coordinates with optional developer information; normal feedback says “Needs support” or “That space is occupied.”

Use one event-driven feedback system so keyboard, touch, online acknowledgement, and replay cannot accidentally duplicate cues. Local pickup and rotation can respond immediately; the strong placement reward belongs to an accepted placement. While an online request is pending, show a restrained pending cue, preserve the ghost, and prevent repeat spending.

| Event | Visual response | Sound / haptic intention | Priority and initial timing |
| --- | --- | --- | --- |
| Pick up / select | Lift the selected tray piece slightly; show its ghost | Quiet plastic lift/rustle; optional very light touch pulse | Immediate; one cue per new selection |
| Rotate | Short quarter-turn preview with readable final orientation | Soft dry tick; optional light pulse | Immediate; no overlapping tick pile-up |
| Enter a legal snap | Stable outline and alignment cue | At most a quiet soft tick; no continuous vibration | Debounce repeated boundary crossings; never every drag frame |
| Invalid preview | Outline plus brief reason; maintain manipulable ghost | Silent while dragging | No alarm or repeated buzz |
| Accepted placement | Brief settling motion, then exact final transform | Signature crisp plastic click with a warm low tap; short gentle pulse for the acting player | Highest action priority; synchronize to acceptance, proposed 80–160 ms settle |
| Rejected Place | Keep ghost; show reason beside action | One muted knock; optional distinct gentle pulse | Once per attempted action; no success click |
| Other player's placement | Same readable placement in the shared world | Quieter spatial placement click; no local haptic | Deduplicate by accepted event ID |
| Undo / correction | Clearly remove the affected piece and restore state | Soft separation sound; no victory cue | Only after accepted correction |
| Turn change / finish agreement | Named active-player cue or readiness update | Restrained chime; optional active-player pulse | Never a loud repeated countdown |

Canceling a selection produces no placement reward. Camera movement produces no brick sounds. Vary click samples subtly to avoid fatigue while preserving a recognisable material. Cosmetic settling must not delay turn acceptance or modify deterministic geometry. Reduced Motion replaces bounce and camera animation with an immediate stable change and a small static cue.

## Music, ambience, and settings

Aim for calm instrumental music: soft plucked notes, warm keys, light percussion, and ample silence between phrases. Use a cohesive musical identity across Welcome, building, and exploration. Begin with at least one seamless menu loop and one longer building loop; theme ambience supplies distinction before commissioning many tracks. Harbour may use distant water and occasional birds; Cabin may use a quiet breeze and sparse woodland details. Avoid dense environmental noise, startling calls, or a tiny loop that becomes obvious within a minute.

Crossfade between contexts, preserve musical continuity through panels, and keep placement clicks clear without making them harsh. Exploration can reduce rhythmic density; the finished-build reveal may add a short gentle musical resolution. Pausing, returning from the background, replaying, and changing screens must never stack duplicate music players.

Provide separate Master, Music, Effects, and Ambience controls, a one-action mute, and an independent Haptics toggle. Preserve preferences between sessions. Use gentle haptics only where actually supported and enabled; unsupported hardware keeps full sound and visual feedback. Test silence as a complete usable experience. All music and effects must have documented rights for game distribution and inclusion in user-exported films; disable unsupported or unlicensed film audio explicitly.

## The finished creation: reveal, explore, keep

**Ready to Explore** opens a clear agreement panel showing the current revision and each active player's readiness. A new accepted move or relevant roster change updates that agreement. Solo can proceed immediately. Save the frozen revision before showing its finished presentation.

Give the creation a brief optional reveal: clear the editing overlays, frame the whole build, soften the room background, and make the structure's edges and openings easy to read. Keep **Skip**, **Explore**, **Watch Build**, and **Back to Building** reachable. Use a warm key light, gentle fill, restrained contact shadows, and attractive material highlights. Harbour can suggest late-afternoon light; Cabin can feel sheltered and warm. This must remain legible with the baseline renderer and low-quality settings. Do not make haze, blur, bloom, or particles prerequisites for attractive results.

Exploration starts with a valid spawn preview, clear Place Figure action, and a smooth optional transition to third-person view. Provide first/third-person switching, touch movement and look, desktop movement and look, Reset Figure, and Return to Table. Doorways, interior corners, and stairs remain visible; darkness is not a decorative excuse for unusable navigation. Avoid mandatory head bob, camera shake, or focus blur. Returning preserves the build and negotiated multiplayer state.

Watch Build presents the actual accepted history with play/pause, restart, pace, and a final reveal. Film setup offers landscape/portrait framing, supported quality, and audio inclusion. Preview the selected framing before export. Show real progress, cancel, retry, and an output that can actually be opened or shared. “Saved” appears only after confirmed output. An unsupported format explains the available alternative while preserving the creation.

## Layout and acceptance

Desktop uses a generous table view and compact bottom tray; touch uses reachable controls, safe-area spacing, and a tray that can scroll without placing pieces. Prototype landscape and narrow portrait layouts; never overlap the Place action, camera gesture area, or browser edges. Start with 48 logical-pixel touch targets and readable 16–18 logical-pixel body text, then test actual scale and text expansion. Keyboard focus, labels, high contrast, reduced motion, and muted play are required paths.

Acceptance requires a fresh user journey through Welcome → mode → setup → real placement, plus Continue/save recovery, pass-and-play handoff, actual online lobby behaviour, finish agreement, exploration, return, replay, and genuine film output. Capture the real UI at phone and desktop sizes, listen to repeated actions and music transitions, and test haptics on supported physical hardware. Record observed behaviour and limitations separately from design intent. Passing scene construction or isolated component tests cannot close this experience gate.

# LittleBricks implementation recovery and experience plan

> **Superseded dispatch order:** This document records the LB-033–LB-056 requirements against the earlier `9eaeda8` baseline. The subsequent implementation and actual browser review are covered by [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md), now the active LB-057–LB-067 sequence. Use [STATUS](STATUS.md) for current states. The requirements below remain binding where unmet; the historical references to “active” and initial task states describe the earlier campaign, not current completion.

Updated: **2026-11-11**. Reviewed implementation baseline: **`9eaeda86ed867a002aa034b12e66d211f8c26432`**.

## Mission and authority

Deliver the actual LittleBricks experience: an inviting arrival, clear mode selection, satisfying shared brick building, miniature exploration, and a real construction film people can keep. Support browser play alongside native targets. Preserve offline solo, local pass-and-play, private online rooms, original characters, and the Android release goal.

This was the **earlier LB-033–LB-056 implementation sequence**, supplementing the original [PROJECT_PLAN](PROJECT_PLAN.md). Original task IDs and M0–M7 acceptance requirements remain binding; their completion claims are under review. The recovery tasks below repair missing behavior and add the requested experience detail. They do not replace the original requirements with a smaller demo.

Read [AGENTS.md](../AGENTS.md), [STATUS](STATUS.md), this plan, [PLACEMENT_AND_CATALOG](PLACEMENT_AND_CATALOG.md), [EXPERIENCE_DESIGN](EXPERIENCE_DESIGN.md), [AUDIO_VISUAL_SPEC](AUDIO_VISUAL_SPEC.md), [GAME_DESIGN](GAME_DESIGN.md), [ARCHITECTURE](ARCHITECTURE.md), and [VALIDATION](VALIDATION.md). STATUS owns current task states, assignments and checkpoints; PLAYTEST_REPAIR_PLAN owns current dispatch. This document retains earlier acceptance criteria. Keep one backlog and one coordinator.

**Historical starting state:** LB-033–LB-056 began as planned. Later implementation claims have since been reviewed; consult STATUS for reopened requirements and PLAYTEST_REPAIR_PLAN for the next work.

## Why the previous completion claim is rejected

The review found useful code, but the integrated application and the claimed release differ:

| Finding at the reviewed commit | Source and required correction |
| --- | --- |
| Startup opens a placement scene with six fixed tray choices. | [project.godot](../game/project.godot) and [main.gd](../game/client/scripts/main.gd): connect a real application flow, SessionManager, inventory and modes. |
| Menu, saves, exploration and replay are separate components. | [main_menu.gd](../game/client/scripts/main_menu.gd) emits navigation signals without an application consumer. Exercise the full journey through visible controls. |
| Online room tests call one local object. | [room_authority.gd](../game/server/room_authority.gd) has no network transport; starting the session after player two leaves players three/four outside its roster. Implement actual connections and durable authority. |
| Export can announce completion without a movie. | [video_exporter.gd](../game/platform/video_exporter.gd) contains desktop and missing-Android-plugin success stubs; browser finalization lacks a usable download result. |
| Replay supplies a repeated solid-color image. | [replay_timeline.gd](../game/replay/replay_timeline.gd): capture actual rendered frames and compare the resulting film with the build. |
| Touch and input coverage is incomplete. | Layer controls, explorer movement and camera gestures need real UI integration. Global placement handling may also respond to GUI clicks; reproduce this risk before describing it as a confirmed runtime defect. |

The independent review ran 11 included test scripts and initialized the scene headlessly on Godot 4.6.3. Those checks passed, but the video test's named output file did not exist. The repository documents 4.7.2; the review did not establish that exact toolchain or browser/device behavior. Preserve this distinction. Existing reports are historical evidence with limited scope, not proof that every release gate passed.

**Subsequent user evidence:** the placement scene runs in local Chrome at `localhost:8080`. The user reports being forced to stack after the first brick, inability to drag the camera, a half-stud-looking offset when placing a 1×4 on a 2×4, and an inadequate six-piece tray. Reproduce each interaction with the fixtures in PLACEMENT_AND_CATALOG before assigning a root cause. Local browser launch is established by the user's observation; complete browser journeys and public hosting remain separate gates. Do not commit the supplied screenshots, which contain personal browser tabs.

## Integration contracts before parallel work

The coordinator selects names that fit the current code and records the contracts before dispatch. Do not build a second independent game beside `game/`.

- **Application owner:** one root controller owns navigation, active session, save identity, screen transitions and restoration. Views receive state and send commands; mode buttons must lead to implemented behavior.
- **Gameplay owner:** SessionManager/shared rules own accepted placements, inventory, timers, phases, revisions and corrections. The visible table renders that state instead of maintaining a competing authoritative array.
- **Feedback owner:** AudioDirector and the feedback controller consume named interaction/accepted-event signals. Separate selection/preview feedback from accepted-placement feedback. One accepted event produces one local confirmation; retries, reconnect snapshots and network echoes cannot duplicate it.
- **World owner:** the table, frozen exploration revision, showcase and replay share part transforms and a coherent lighting policy. Render-only polish cannot change collisions or recorded construction state.
- **Platform owner:** transport, persistence, haptic capabilities, real encoding and sharing live behind explicit interfaces. Missing support returns an honest unsupported/error result, never a fabricated success path.

Serialize `project.godot`, event/save/protocol schemas, export presets, dependency versions, the catalogue manifest, and STATUS. Assign disjoint files or worktrees for other changes. Workers return their diff, commands, evidence and limitations; only the coordinator integrates and pushes the combined branch.

## Earlier recovery requirements

Dependencies mean prerequisite integrated behavior, not a requirement to idle while hardware evidence is blocked. Implement independent work and keep unmet gates visible. Partial progress never makes an entire task `done`.

### A. Establish a usable game journey

#### LB-033 — Re-establish the real baseline

**Depends on:** none. **Owner:** coordinator + platform; independent verifier.

Inspect the current head and preserve new changes since the reviewed commit. Inventory actual tools, export templates and devices; select and verify a compatible engine/template pair. Reproduce the relevant missing behaviors and retire unsupported completion claims without deleting historical evidence. Separate known defects, untested risks and external blockers.

Repair the existing verification entry points as part of this baseline. `env_check.py` currently hard-codes macOS locations/version and prints Desktop/Web readiness unconditionally; report discovered capabilities and real command exit status instead. `verify_clean_checkout.sh` runs artifact-dependent smoke checks before producing those artifacts, and `test_smoke.py` expects `LittleBricks.zip` while the release script writes `LittleBricks-macOS.zip`. Separate import/runtime smoke checks from post-export checks, agree artifact names and absolute project-root resolution, and make a genuinely fresh checkout work without stale files. A Java runtime alone is not a verified JDK/Android toolchain.

**Acceptance:** reproducible run/test/web-export commands, exact versions and revision, an updated STATUS with no blanket completion claim, and a short evidence record distinguishing the existing passing component tests from missing integrated behavior.

#### LB-034 — Connect one application and session lifecycle

**Depends on:** LB-033. **Owner:** gameplay; coordinator owns shared startup configuration.

Introduce or repair the application root and scene routing. Connect menu signals, active SessionManager, save/resume, table, exploration and replay entry points. Keep session state across view changes and tear down old listeners cleanly. Wire existing useful components before replacing them.

**Acceptance:** actual startup reaches the front end; mode actions create the expected session; Back/Return transitions preserve or explicitly save/discard the correct state; repeated navigation does not duplicate input, music or event handlers.

#### LB-035 — Build the first three screens and onboarding

**Depends on:** LB-034. **Owner:** gameplay + worlds, with disjoint UI/art ownership.

Implement the welcome, mode-selection and mode-specific setup flows in EXPERIENCE_DESIGN. Include Continue, creations, settings, coherent theme previews, player/timer choices, loading/error states and the online lobby. Deliver the proposed visual hierarchy and responsive layouts rather than a menu of default controls. Teach the first few placements in context.

**Acceptance:** a fresh player reaches solo play through the visible flow, a returning player resumes quickly, local setup creates the chosen roster, and every actionable control has a working destination or an accurate temporary availability state. Capture desktop and narrow touch layouts; temporary unavailability does not close the underlying feature task.

#### LB-036 — Integrate real building rules and safe input

**Depends on:** LB-034, LB-053, LB-054, LB-055. **Owner:** gameplay.

Replace the fixed demo tray and direct placement array with the session's mixed hand/catalogue policy, accepted-command path, turn ownership, refill, timer, skip and correction rules. Implement explicit touch layer controls and camera gestures. Reproduce and repair any GUI-click placement leakage; separate preview movement, camera gestures and commit actions.

**Acceptance:** players can select, rotate, stack and place using mouse and touch; invalid actions spend nothing; buttons and camera gestures never place a brick accidentally; local players receive the correct hands and turns. Visible state agrees with saved/session state after undo, redo and correction.

#### LB-037 — Connect finish, exploration and save/resume

**Depends on:** LB-036. **Owner:** gameplay + worlds.

Implement revision-bound finish agreement, safe original-explorer placement, first/third-person views, reachable touch controls, reset figure and return-to-building. Connect real save/load and appropriate autosave feedback. Preserve openings and character clearance in representative builds.

**Acceptance:** through the actual UI, build a doorway/interior, finish, walk through it, return, save, restart and resume the same construction. Local participants must agree to the current revision; changed builds invalidate stale agreement. No detached test-only exploration scene counts as integration.

#### LB-038 — Verify the first integrated playable slice

**Depends on:** LB-035, LB-037. **Owner:** verifier, fixes assigned to implementers.

Run the actual startup-to-build-to-explore-to-resume journey on a desktop runtime and an HTTP-served browser export. The existing manual web-export command may be used before LB-049 packaging work. Exercise UI transitions and pointer/touch interactions, not just direct method calls.

**Acceptance:** record revision, runtime/browser, input method, screenshots or short captures, console/log findings and reproduced fixes. Label touch emulation accurately. This is the first playable gate, not full release completion; continue into the remaining tasks.

### B. Make the experience inviting and satisfying

#### LB-039 — Prepare licensed music, ambience and interaction sounds

**Depends on:** LB-033. **Owner:** worlds using `littlebricks-assets`.

Create or select the music loops, restrained theme ambience and varied brick/UI sounds specified in AUDIO_VISUAL_SPEC. Trim loops, normalize conservatively, prepare compact runtime files and record source, author, licence, modifications and permitted redistribution/video use. Use recognizable original LittleBricks art and audio direction.

**Acceptance:** audition every selected asset and its loop boundary; document provenance and credits; include actual audio files rather than filenames, silent placeholders or instructions to obtain them later. No paid service is required.

#### LB-040 — Implement music and audio mixing across the journey

**Depends on:** LB-034, LB-039. **Owner:** worlds; platform supports browser/lifecycle behavior.

Implement persistent audio buses/director, gentle music transitions, theme ambience, effect priorities, volume/mute preferences, app background/resume and browser user-gesture unlock. Follow AUDIO_VISUAL_SPEC for mixing and resource limits. Keep the experience useful with audio off.

**Acceptance:** listen through welcome, setup, building, exploration and return on declared runtimes. Confirm music starts appropriately, loops cleanly, does not multiply after navigation, respects saved controls, and leaves the brick click audible. A sound-manager unit test does not establish audible output.

#### LB-041 — Deliver tactile brick feedback and haptics

**Depends on:** LB-036, LB-040. **Owner:** gameplay + platform; worlds owns sound assets.

Connect pickup, rotate, eligible snap, rejection, cancellation, accepted placement, undo and remote-placement feedback using the defined event contract. Give accepted placement its satisfying click and restrained animation. Add supported-device haptics with a persistent off control and honest browser/device fallbacks.

**Acceptance:** one accepted placement yields one confirmation; retries, remote echoes, replay and loading do not buzz or click repeatedly. Preview effects never imply acceptance. Audition rapid use; demonstrate haptics on actual supporting hardware or leave that evidence blocked while completing code and other checks.

#### LB-042 — Polish table, exploration and finished-build presentation

**Depends on:** LB-037. **Owner:** worlds.

Implement warm, readable table lighting, material variation, grounded shadows and restrained atmosphere using verified Compatibility-renderer features. Add the completed-build showcase/reveal and coherent interior/explorer lighting. Carry the same visual intent into construction films; supply reduced-motion and lower-cost quality paths.

**Acceptance:** inspect real representative scenes at close, table and miniature scales. Bricks remain readable, interiors navigable and UI unobscured; quality settings alter cost without breaking gameplay. Capture comparisons and measured frame times; do not assume bloom, SSAO or depth of field exists in the chosen renderer.

#### LB-043 — Finish accessibility and touch ergonomics

**Depends on:** LB-035, LB-036, LB-037, LB-040, LB-041, LB-042. **Owner:** gameplay + verifier.

Inspect touch targets, safe areas, narrow layouts, contrast, focus navigation, handedness where specified, timer-free play, reduced motion and independent music/effect/haptic controls. Complete explorer touch movement/look and usable orbit/layer gestures. Keep text/icon cues meaningful without sound or color alone.

**Acceptance:** complete the local journey with keyboard/mouse and touch; settings persist after relaunch; low-motion/audio-off/haptic-off modes remain understandable. Record physical-device results separately from browser emulation and retain any unmet platform gate.

### C. Finish the substantial missing systems

#### LB-044 — Connect real private online rooms

**Depends on:** LB-034, LB-036. **Owner:** platform.

Implement a real server entry point, WebSocket transport suitable for WSS deployment, client connection lifecycle, lobby, commands, broadcasts and bounded input handling. Replace the fixed room/join shortcut with actual room creation/join UX. Connect all two-to-four participants to the authoritative session roster.

**Acceptance:** separate client processes/browser contexts join the same server, take turns and observe matching accepted state. Demonstrate three- and four-player participation, rejection of wrong-player actions, and clear connection errors. Direct calls to one RoomAuthority object are only unit tests.

#### LB-045 — Prove online durability and recovery

**Depends on:** LB-044. **Owner:** platform + verifier.

Implement durable accepted-event storage, snapshots, reconnect identity, request deduplication, authoritative deadlines and roster/finish transitions. Address input/authentication ordering, bounded resources and applicable room moderation. Persist what is needed before acknowledging a successful move.

**Acceptance:** kill/restart the server around accepted moves, interrupt connections, retry commands and rejoin. All participating clients recover the same build, inventory and phase without duplicate feedback. Verify players three/four can place; snapshots and in-memory reconnect alone do not prove process recovery.

#### LB-046 — Render the actual construction film

**Depends on:** LB-037. **Owner:** worlds + platform.

Replace dummy-image streaming with actual replay rendering and deterministic scene reconstruction, including corrections, camera framing and the final reveal. Advance rendering/encoding at an appropriate cadence without freezing the application. Keep frame buffers bounded and include the intended audio policy.

**Acceptance:** exported-frame samples visibly show distinct stages of the actual build, correct order and final geometry. Validate duration, cancellation, large-build behavior and memory; a repeated blue frame or successful progress callback fails this gate.

#### LB-047 — Finish browser and desktop video output

**Depends on:** LB-040, LB-046. **Owner:** platform.

Implement real encoders or supported output adapters. Browser recording must await final data, assemble a usable file, offer download/share where supported, and report codec/error/cancel outcomes accurately. Desktop must write a real supported video. Include licensed music/effects when enabled or explicitly disclose an unsupported audio path.

**Acceptance:** create a nonempty film through the game UI, decode it in a separate player, inspect frames/duration and listen to its audio. Test unavailable encoders, cancellation and output failure; unavailable support must never emit successful completion. Verify browser persistence and download behavior on the declared matrix.

#### LB-048 — Deliver native Android MP4 and sharing

**Depends on:** LB-040, LB-046. **Owner:** platform.

Implement and package the actual native encoder bridge with MediaCodec/MediaMuxer or a justified tested equivalent, required audio handling, lifecycle controls and share-sheet integration. Remove false-success fallback behavior. Begin toolchain/bridge investigation earlier when independent of scene integration.

**Acceptance:** a real Android build creates a playable MP4 depicting the build; another app opens it and sharing works. Test cancel/background/low-storage paths. Complete all possible code, build and emulator work when hardware is missing, but keep physical export/sharing gates blocked and this task open.

### D. Deliver and verify a reviewable product

#### LB-049 — Make browser builds independently runnable and previewable

**Depends on:** LB-038. **Owner:** platform + coordinator.

Provide a web-only build command that does not require macOS templates, correct local serving, asset paths/MIME/cache configuration, a supported-browser matrix and a deployable bundle. Prepare or deploy the preview using actual existing hosting authorization; keep online endpoints and secrets properly separated from static assets.

**Acceptance:** a clean checkout builds and serves the browser version independently. Verify fresh-load, refresh, subpath hosting, saves, touch layout and errors. If deployment is authorized, record the actual URL and test it; otherwise finish the bundle and concrete deployment steps before naming the remaining authorization/access requirement. A configured export preset is not deployment evidence.

#### LB-050 — Independently verify complete journeys and sensory quality

**Depends on:** LB-038, LB-043, LB-045, LB-047, LB-048, LB-049, LB-056. **Owner:** verifier.

Run solo, pass-and-play and real online journeys through building, finish agreement, exploration, save/reopen, replay and sharing. Inspect actual music, clicks, supported haptics and completed-scene lighting. Profile sustained representative builds and export on the declared native/browser matrix.

**Acceptance:** evidence contains reproducible interactions, exact revisions/artifacts, decoded films, audible/visual observations and measured performance. Fix material findings and repeat affected journeys. Begin independent checks early; blocked device gates remain open rather than blocking every other useful check.

#### LB-051 — Reconcile release packaging, licences and store preparation

**Depends on:** LB-039, LB-050. **Owner:** platform + worlds; coordinator integrates.

Use `littlebricks-release` to reconcile M7 packaging, clean-checkout reproduction, asset/audio notices, privacy/store declarations, accurate screenshots and installation/update/resume tests. Keep generated builds and credentials outside Git; identify reproducible artifacts and checksums. Prepare permitted signing/submission work under actual authorization.

**Acceptance:** another checkout reproduces the declared artifacts; credits cover every shipped and video-embedded asset; release materials describe demonstrated behavior. Account, device or store-review blockers are explicit and do not erase remaining implementation work.

#### LB-052 — Close the recovery with truthful evidence

**Depends on:** LB-050, LB-051. **Owner:** coordinator + independent verifier.

Reconcile all original M0–M7 criteria and recovery tasks against integrated evidence. Update README, controls, release notes, STATUS and the evidence index. Retain superseded reports with clear scope/corrections rather than treating old green tables as current proof.

**Acceptance:** no unresolved required behavior is hidden by a completion label. Report the tested commit, real preview/artifact locations, supported platforms and specific unmet dependencies. Distinguish implementation complete, device verified, release ready and publicly released. Continue any unblocked original requirement before ending a full-game campaign.

### E. Immediate placement fixes and a useful catalogue

These IDs extend the backlog after the user's browser session. Their higher numbers do not imply lower priority: use the dependency graph and dispatch order below.

#### LB-053 — Fix surface targeting and height selection

**Depends on:** LB-054. **Owner:** gameplay; coordinator serializes edits shared with camera/input work.

Reproduce the first-brick/forced-stacking report. Implement the surface/height policy in PLACEMENT_AND_CATALOG, including a reliable return to the baseplate, target-brick tops, empty ground and explicit touch-accessible layer adjustment. Automatic post-placement behavior must not trap the next ghost above the table or silently force a different target. Keep surface selection, overlap validity and intended layer visibly distinct.

**Acceptance:** place one brick, then another separately on the baseplate without restarting; place on an existing brick, return to the baseplate, select another piece and continue. Test alternating ground/top targets and cancel/undo with mouse and touch. Capture actual behavior and validate the resulting integer transforms; keyboard-only recovery does not satisfy touch acceptance.

#### LB-054 — Establish one canonical stud lattice and pivot contract

**Depends on:** LB-033. **Owner:** gameplay + worlds; one owner integrates shared geometry contracts.

Reproduce the reported 1×4-on-2×4 offset before changing pivots. Audit catalogue dimensions, mesh origins/stud centers, grid-to-world conversion, rotation centers, ghost rendering, collisions, connectors, persisted transforms and replay. Define one contract used by every path. Add independently derived fixtures for odd/even footprints, all quarter turns and vertical plate units; do not fix one screenshot with a shape-specific visual offset.

**Acceptance:** the specified 1×4/2×4 arrangement lines up visibly and numerically with the intended studs; representative 1×1, 1×2, 1×3, 1×4, 2×2 and 2×4 footprints preserve alignment at all rotations. Ghost, accepted piece, saved/reloaded scene and replay coincide. Validate support and overlap against the same geometry rather than mirroring a faulty transform in the test expectation.

#### LB-055 — Make the camera and input ownership work in the browser

**Depends on:** LB-054. **Owner:** gameplay/worlds; coordinator owns shared input map and main-controller integration.

Reproduce the reported fixed camera in the actual local web export. Implement discoverable desktop orbit/pan/zoom and touch gestures per the design, with top/reset presets and limits that keep the table recoverable. Resolve drag ownership across tray selection, brick preview, UI controls and camera manipulation. Ensure browser context-menu/default-gesture behavior does not swallow the chosen controls or disrupt page navigation outside the game.

**Acceptance:** through the browser UI, rotate around the table, inspect a tall build, zoom, pan, and reset. Repeat relevant gestures on mouse, trackpad and touch hardware or clearly labeled emulation. Camera movements and UI clicks must neither commit bricks nor alter their selected transforms; the correct gesture hints are visible for the active input method. Execute PC-08 in PLACEMENT_AND_CATALOG.

#### LB-056 — Expand the usable catalogue in verified stages

**Depends on:** LB-036. **Owner:** worlds + gameplay; coordinator owns catalogue schema/manifest integration.

Follow PLACEMENT_AND_CATALOG's staged goal: audit the existing entries, reach 80 verified buildable shapes, then at least 120; 150 is a stretch target. Count distinct functional shapes, not color duplicates, characters or nominal manifest entries. First expose the existing valid parts through searchable/filterable categories and appropriate solo selection; preserve mixed-bag constraints in cooperative modes. Expand only after lattice, placement and input gates pass. Include structural, plate/tile, slope, opening, roof, curved/round and theme-detail families with honest support limits.

**Acceptance:** inspect representative assemblies from every added family, validate dimensions/pivots/connectors/colliders/licences, and verify rendering, picking, save/replay and browser performance. A user can find and use substantially more than six choices without an unwieldy tray. Report supported counts and exclusions; visually recognizable arches/doors must have usable openings, and increasing JSON entries alone does not satisfy catalogue growth.

## Dispatch order and continuation

Historical dispatch for the earlier campaign: start LB-033, then prioritize LB-054's lattice/pivot contract and LB-053/LB-055 surface/camera fixes. Agree LB-034 application contracts in parallel where ownership permits. Gameplay must not close LB-036 until those immediate placement gates pass. Worlds can prepare LB-039 audio and visual direction; platform can investigate encoders and independent web tooling without changing shared startup files. Catalogue expansion LB-056 follows working placement rather than preceding it. After the first local/browser journey passes, expand the connected experience with feedback, presentation, real networking and real films. Do not postpone all polish to the end, and do not let a polished menu hide missing game flow.

Use `littlebricks-build` as coordinator, `littlebricks-assets` for content, `littlebricks-verify` for independent checks, and `littlebricks-release` for packaging. Discover relevant installed skills/plugins; read them and use actual supported tools. Prefer one available native orchestrator, then ordinary specialists, then sequential work with a separate review pass. Missing optional plugins are not implementation blockers. With limited agent slots, rotate the verifier rather than omit verification.

For every task: claim ownership, implement a complete slice, run relevant local checks, launch and inspect interactive behavior, obtain independent review, fix material findings, integrate, update evidence/STATUS, commit/push the authorized branch, and select the next ready task. Avoid implementation-shaped mock tests and repetitive checks that address no remaining risk. No GitHub Actions minutes are required.

Before a session ends, record the exact branch/commit, current task, changed files, executed checks, remaining defects/blockers and next executable action. Continue authorized work without asking whether to proceed. When a genuine credential/device/publishing boundary remains, first complete independent work and prepare a concrete reviewable result; do not repeat permissions already granted. A saved checkpoint enables the next session—it does not claim an unlimited background agent is running.

# LittleBricks architecture

This is the architecture requirement contract. A Godot implementation now exists, but its integrated behavior has known defects; do not interpret the design below as verified current behavior. Read [AGENTS.md](../AGENTS.md), [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md), the [source review](evidence/2026-11-11-current-app-source-review.md) and [STATUS](STATUS.md). Record material changes as decisions; preserve the build, explore, and share loop.

## Contents

- [Stack and project layout](#stack-and-project-layout)
- [Data contracts](#data-contracts)
- [Placement and rendering](#placement-and-rendering)
- [Authoritative multiplayer](#authoritative-multiplayer)
- [Persistence and recovery](#persistence-and-recovery)
- [Exploration and replay](#exploration-and-replay)
- [Platform boundaries](#platform-boundaries)

## Stack and project layout

Use Godot 4, GDScript, and the Compatibility renderer as the initial common baseline. Pin an exact stable engine release and export templates during M0 after testing the required targets. Native Android is the primary release; desktop and supported browser combinations need their own acceptance evidence.

Godot web exports require WebAssembly and WebGL 2, currently support Compatibility rendering, and do not support Godot 4 C# projects. Start with the documented single-threaded web export. Browser support is a tested matrix, not a promise that every device has identical fidelity. [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

Implement a single Godot project with client and dedicated-server export presets:

| Planned path | Responsibility |
| --- | --- |
| `game/project.godot` | Pinned project settings and entry scene |
| `game/core/` | Pure data rules, catalog loading, placement validation, inventory, turns, event reducer |
| `game/client/` | Table presentation, input, camera, UI, audio, and local preview |
| `game/server/` | Rooms, sessions, command validation, persistence adapter, authoritative deadlines |
| `game/replay/` | Event reconstruction, cinematic timeline, camera tracks |
| `game/platform/` | Android encode/share bridge; desktop and web adapters |
| `game/assets/` | Audited meshes, materials, audio, catalogs, theme manifests |
| `game/tests/` | Rules, protocol, save/replay, and integration tests |
| `tools/` | Reproducible validation, asset preparation, export, and benchmark commands |

These paths are to be created by implementation tasks. Do not add empty systems merely to match a diagram. Core code must not depend on UI nodes, camera state, frame rate, wall-clock reads, or platform APIs. Supply clocks, randomness, and storage through explicit interfaces. Solo and server sessions use the same rules.

## Data contracts

Define machine-readable schemas and fixtures in M0/M1; version them before assets or networking multiply. Use integers for committed grid coordinates and orientation indices, not drag-derived floating-point matrices.

| Contract | Required information |
| --- | --- |
| Part definition | Stable part/version ID; source and license; mesh/pivot/scale; allowed colors and orientations; body collision proxies; connector transforms/types; explorer collision proxy; theme tags |
| Build placement | Unique placement ID; part/version; color; grid position; allowed orientation index; originating event sequence |
| Session snapshot | Schema/rules/catalog versions and catalog hash; room/build revision; placements; inventories and bag state; ordered players; current turn and deadline; phase and readiness; last event sequence |
| Client command | Protocol version; session identity; unique request ID; expected turn/build revision; operation and validated parameters |
| Accepted event | Schema/rules/catalog versions; monotonic sequence; request/player IDs; event type; exact resulting placement or mutation; inventory/turn changes needed for reconstruction |

Log accepted results, including actual drawn/refilled pieces. A seed is useful for reproducible setup but is insufficient to preserve history when algorithms change. Persist skips, accepted corrections, readiness resets, phase changes, and build revisions. Reject unsupported versions with a clear response; never silently reinterpret a save. Document migrations and preserve originals.

## Placement and rendering

Start with upright pieces and four rotations around the vertical axis. Use stud steps horizontally and plate-height steps vertically. Keep a documented path to finer grids later without claiming universal LDraw compatibility.

The preview may move smoothly, but committing a piece requires all of:

1. An available inventory item and permitted orientation.
2. Board and height bounds respected.
3. No forbidden solid-body overlap.
4. Compatible connectors attaching to an anchored structure, or an explicit surface-placement rule for a supported decoration.

Use a spatial index for candidate lookup and shape-aware narrow checks. Window/arch openings must stay open; a single box cannot represent every part. Separate permitted stud/socket engagement from forbidden body overlap. Check attachment to a baseplate/ground anchor through a connection graph. Digital attachment does not establish real-world mechanical stability or clutch strength.

Input adapters produce the same commands on touch and desktop. Provide tap-to-position and drag preview, quarter-turn controls, explicit Place, camera gestures that do not consume a turn, height selection, and non-color-only validity feedback. Revalidate a prepared spectator move when that player's turn starts.

Reuse meshes and batch compatible repeated instances. Bound dynamic shadows and transparent materials. Keep visible geometry, placement proxies, and walking collision separate. Raise part/scene limits only after profiling a representative sustained phone session.

## Authoritative multiplayer

Use a headless Godot server over WSS, sharing `core/` with the client. Godot supports [dedicated server exports](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html) and [WebSockets on native and web](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html). Browser clients cannot rely on native UDP/ENet as the universal transport.

For each command, validate membership, authenticated guest/session identity, current turn, server-owned deadline, inventory, supported part, bounds, collision, and connectors. Treat room codes as discovery information; use independent opaque player/rejoin tokens. Apply payload limits and rate limits. Never trust client-provided authority, arbitrary scene paths, or a client countdown.

Make acceptance one durable transition: event, board, inventory, and next-turn state must agree. Repeated request IDs return the original result without consuming a second turn or brick. Assign a sequence and durably record acceptance before acknowledgement/broadcast. Clients may show a local ghost immediately; rejected commands must reconcile to accepted state.

Reconnect using the last accepted sequence; provide missing events or a snapshot and tail. Persist enough deadline state for restart recovery, use a monotonic clock for live timer measurement, and define expired-turn handling. Backgrounded phones and disconnected players must not freeze a room indefinitely. Readiness refers to a particular build revision and is cleared by a new accepted placement. Keep exploration position updates transient and separate from the construction journal.

## Persistence and recovery

Solo play works offline. Save after accepted changes with a safe temporary-write/replace strategy, schema validation, and recovery from a previous valid snapshot. Test web persistence separately and provide an export/import backup route because browser storage can be cleared.

The server needs a storage adapter; Godot does not provide a turnkey room database. A small alpha may use an append-only journal plus atomic snapshots on a persistent volume, provided flush ordering, partial records, restart recovery, and concurrent access are tested. Do not call ordinary file writes transactional or crash-safe without evidence. Select a reviewed SQLite/database adapter when the acceptance requirements justify it; PostgreSQL is a scaling option, not an M0 prerequisite.

Pin catalog assets so old builds remain reconstructable. A snapshot accelerates loading; the journal preserves history. Define retention and deletion behavior before storing hosted player creations indefinitely. Keep tokens, signing keys, and personal data out of source control and evidence logs.

## Exploration and replay

Freeze an agreed build revision for exploration. Choose explorer scale early, then validate doorway/ceiling clearance, support underfoot, steps, camera near clipping, and a valid spawn. Use simple static collision and a capsule controller with first/third-person cameras. Smooth over visual studs. Supply Reset Figure and Return to Table. Direct joystick/WASD movement needs no navigation mesh; click-to-walk/NPCs are later scope.

Return to building through an explicit shared phase change and new revision. Do not silently mutate colliders around walking players. Keep figure appearance original and consistent with the scene scale.

Replay applies accepted events to a clean build through the same reducer. A separate cinematic timeline removes thinking time, chooses frame duration/camera movement, and ends with the final reveal. Define how undo/removal appears in a construction film. Determinism means the same recorded construction and final state, not bit-identical pixels on different GPUs.

## Platform boundaries

Prove Android replay export during M0; deliver the complete feature in M5. [Godot Movie Maker](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html) is an offline rendering facility, not a ready-made in-app Android MP4 sharing button.

Implement a bounded render-to-encoder bridge using [MediaCodec](https://developer.android.com/reference/android/media/MediaCodec) and [MediaMuxer](https://developer.android.com/reference/android/media/MediaMuxer). Investigate Surface input to avoid excessive frame copying. Stream frames instead of retaining an entire clip. Verify cancellation, insufficient space, app backgrounding, codec failures, audio policy, and temporary-file cleanup. Exported MP4 must play outside the game and open through Android sharing.

For web, negotiate supported recording formats with [MediaRecorder capability detection](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/isTypeSupported_static). Report the actual format; do not label WebM as MP4. Desktop may use an offline export process. Keep native iOS integration as a later independent release target, and keep cloud rendering optional rather than necessary for offline solo play.

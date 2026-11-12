# LittleBricks

**Build together, one brick at a time. Then step inside.**

LittleBricks is an open-source tabletop brick game in Godot 4, targeting browser, Android and desktop play. The product goal is solo creative building, shared turns with mixed bags, private online rooms, original toy explorers, and shareable construction films.

## Current status: playtest repair

The browser app loads and includes menus, a building table, catalogue and exploration controls. The **2026-11-11 live browser review reproduced blocking gameplay defects**, including a pointer target stuck at the center, UI scrolling that also moves the camera, outside-hand placement and state/presentation problems. The previous RC2/all-complete claim is superseded.

The manifest contains 126 records, but some specialty pieces are duplicate rectangular placeholders. Music files and playback code exist; their audible quality was not verified in this review. A working menu or passing component suite does not establish a finished family game.

Read the [actual browser playtest with screenshots](docs/evidence/2026-11-11-live-browser-playtest.md), [source review](docs/evidence/2026-11-11-current-app-source-review.md) and [current status](docs/STATUS.md). This review update changes planning/evidence and agent guidance; it does not claim runtime fixes.

## Next implementation

Use **[PLAYTEST_REPAIR_PLAN](docs/PLAYTEST_REPAIR_PLAN.md)** for the active LB-057–LB-067 sequence. Start with real pointer/session repairs, then deliver the [family experience brief](docs/FAMILY_PLAY_EXPERIENCE.md): bright first screens, visual parts, satisfying sound/feedback, genuine themed shapes and a rewarding build/explore/share journey. Original release requirements remain in scope.

Open the repository root in Antigravity and use **[NEXT_AGENT_PROMPT](docs/NEXT_AGENT_PROMPT.md)**. [AGENTS.md](AGENTS.md) is the source of agent instructions; [GEMINI.md](GEMINI.md) is its compatibility entry point. Relevant project skills and specialists are in `.agents/`.

## Run the current development build

With the selected Godot executable and matching export templates available:

```bash
./tools/build_web.sh
python3 tools/serve_web.py 8080
```

Open [http://localhost:8080](http://localhost:8080). Set `GODOT_BIN` if Godot is not on PATH. See [BUILD](docs/BUILD.md) for requirements; revalidate the exact engine/template pair and record the export revision during LB-057.

For the native editor/runtime:

```bash
godot --path game
```

Included verification entry point:

```bash
./tools/verify_clean_checkout.sh
```

The live review did not rerun the previous agent's complete test/build matrix. Use actual exported UI interactions, listening/device checks and decoded outputs alongside relevant automated checks. Known pointer/input defects currently limit normal browser building; on-screen placement/manual height and Camera Mode orbit/zoom were observed working in a narrow test.

## Project documents

| Document | Purpose |
| --- | --- |
| [STATUS](docs/STATUS.md) | Current evidence, reopened requirements and continuation ledger |
| [PLAYTEST_REPAIR_PLAN](docs/PLAYTEST_REPAIR_PLAN.md) | Active implementation sequence and concrete acceptance gates |
| [FAMILY_PLAY_EXPERIENCE](docs/FAMILY_PLAY_EXPERIENCE.md) | Art direction, screens, toy-like interaction, sound and family experience criteria |
| [NEXT_AGENT_PROMPT](docs/NEXT_AGENT_PROMPT.md) | Single prompt to start the implementation agent |
| [PROJECT_PLAN](docs/PROJECT_PLAN.md) / [RECOVERY_PLAN](docs/RECOVERY_PLAN.md) | Original and earlier recovery requirements that remain binding |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | Shared rules, sessions, client/server and platform boundaries |
| [PLACEMENT_AND_CATALOG](docs/PLACEMENT_AND_CATALOG.md) | Canonical coordinates, connectors and PC-01–PC-10 fixtures |
| [AUDIO_VISUAL_SPEC](docs/AUDIO_VISUAL_SPEC.md) | Music, clicks, haptics, lighting and actual output requirements |
| [VALIDATION](docs/VALIDATION.md) | Independent tests, real journeys and evidence standards |
| [RELEASE_NOTES](docs/RELEASE_NOTES.md) | Current release acceptance and historical report context |
| [CREDITS](CREDITS.md) / [ASSETS](docs/ASSETS.md) | Asset provenance and licensing requirements |

## Licence

Game code is available under the [MIT License](LICENSE). See asset-specific provenance and [credits](CREDITS.md) for content terms; new or replaced content must retain verified attribution and redistribution rights.

LittleBricks uses original branding and characters and is not affiliated with the LEGO Group.

## Private rooms

Start the room server from the repository root.

```sh
godot --headless --path game --script res://server/run_server.gd
```

Open **Private room → Create room** and use **Copy code** in the lobby. Friends open **Private room**, enter the code, and choose **Join room**. The table opens when two to four players are present and everyone is ready.

The native client defaults to `ws://127.0.0.1:9080` for local testing. For remote play, run the room server behind a TLS reverse proxy with WebSocket upgrades enabled. All players use the same server address. An HTTPS build requires a `wss://` address. Enter it in **Server address**, or set `littlebricks/online/server_url` in the Godot project settings before export to supply a default. The native client also accepts `LITTLEBRICKS_ROOM_SERVER` as an environment variable.

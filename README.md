# LittleBricks

**Build together, one brick at a time. Then step inside.**

LittleBricks is an open-source tabletop building game planned for Android, desktop, and supported web browsers. Players take turns placing a brick from a mixed themed bag, agree when their creation is finished, explore it as tiny toy characters, and share a stop-motion film of the build.

Solo building and local pass-and-play are part of the same experience.

## Project status

The project plan and agent setup are ready. Game implementation begins at **M0**; this repository does not yet contain a playable build. [Current status](docs/STATUS.md) is the source of truth for progress and evidence.

## Build with Antigravity

Open the **repository root** in Antigravity and ask it to use the `littlebricks-build` skill. Where skill slash commands are supported, run `/littlebricks-build`.

The setup includes a coordinator workflow, four specialist agent definitions, asset/verification/release skills, and a persistent task ledger. It discovers available tools and orchestration modes, implements the next ready task, verifies it independently, fixes findings, and continues through the release scope.

[Antigravity setup and launch prompt](docs/ANTIGRAVITY.md) · [Agent instructions](AGENTS.md)

## Project documents

| Document | Purpose |
| --- | --- |
| [Project plan](docs/PROJECT_PLAN.md) | M0-M7 milestones, dependencies, tasks, and acceptance gates |
| [Game design](docs/GAME_DESIGN.md) | Rules, controls, modes, exploration, and replay |
| [Architecture](docs/ARCHITECTURE.md) | Godot, shared rules, networking, saves, and export |
| [Validation](docs/VALIDATION.md) | Automated, visual, multiplayer, and real-device checks |
| [Assets](docs/ASSETS.md) | Brick sources, connection metadata, and licence provenance |
| [Skills and tools](docs/TOOLCHAIN.md) | Relevant plugins, MCP integrations, and fallbacks |
| [Status](docs/STATUS.md) | Task ownership, evidence, blockers, and next action |

## Technical direction

Godot 4 with GDScript; Compatibility rendering as the initial shared baseline; a headless Godot server over secure WebSockets; versioned parts, saves, and construction events. LDraw/Nova is optional authoring tooling. Players should not need an AI service to place bricks or play solo.

See [Contributing](CONTRIBUTING.md). Project-authored code and documentation use the [MIT licence](LICENSE); imported assets and dependencies retain their own licences. LittleBricks uses its own branding and character designs and is not affiliated with the LEGO Group.

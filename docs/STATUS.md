# LittleBricks status and continuation ledger

Last updated: **2026-11-11**

## Current state

- Stage: Milestone M3 complete; Milestone M4 in progress.
- Product name: LittleBricks.
- Game implementation: M0, M1, M2, and M3 complete. LB-013..LB-016 verified (exploration colliders, toy explorer, dual POV cameras, reset figure, scale).
- Playable release, game test evidence, physical-device results and store submission: none (physical Android tests explicitly BLOCKED).
- Current implementation milestone: **M4 - Private online rooms**.
- Active worker assignments: LB-017 (headless WSS room authority, player identity tokens, ordered events, idempotent commands).
- Next task: **LB-017**; implement authoritative network server and protocol in `game/server/network_server.gd`.
- Next implementation action: create `game/server/network_server.gd` and client network adapter with WebSocket protocol, idempotent request IDs, and authoritative turn deadlines.

Read [AGENTS.md](../AGENTS.md), [PROJECT_PLAN.md](PROJECT_PLAN.md), and [ANTIGRAVITY.md](ANTIGRAVITY.md). Task definitions/dependencies live in the plan; this file owns current state and work claims.

## Milestone status

| Milestone | State | Evidence / next gate |
| --- | --- | --- |
| M0 - Foundation and technical spikes | done | LB-001..LB-004 verified; Godot 4.7, presets, catalog, 500-piece bench, video adapter |
| M1 - Precise brick placement | done | LB-005..LB-008 verified; rules engine, inventory, camera, scaling benchmarks |
| M2 - Complete local building | done | LB-009..LB-012 verified; state machine, save/resume, undo/redo, pacing |
| M3 - Explore the finished world | done | LB-013..LB-016 verified; exploration colliders, toy explorer, dual POV, reset figure |
| M4 - Private online rooms | in_progress | LB-017 in progress; authoritative server, recovery, 2-4 clients |
| M5 - Construction films and sharing | planned | Correct replay and actual video/share output |
| M6 - Content, polish and performance | planned | Audited content and measured integrated experience |
| M7 - Release readiness | planned | Reproducible candidate, evidence, licences and store preparation |

## Task ledger

Allowed states: `planned`, `in_progress`, `review`, `blocked`, `done`. Evidence results use `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`. A task can have implemented code while a required evidence gate remains blocked; explain that rather than mark it done.

The coordinator updates this ledger. During parallel work, add owned paths/worktree, input contracts and next action in the active-assignment section before dispatch.

| Task | State | Owner | Evidence / commit |
| --- | --- | --- | --- |
| LB-001 | done | coordinator | docs/evidence/LB-001-toolchain-discovery.md |
| LB-002 | done | coordinator | docs/evidence/LB-002-project-table-scene.md |
| LB-003 | done | littlebricks-worlds | docs/evidence/LB-003-parts-metadata-audit.md |
| LB-004 | done | littlebricks-platform | docs/evidence/LB-004-android-video-and-stress-spike.md |
| LB-005 | done | littlebricks-gameplay | docs/evidence/LB-005-placement-rules-engine.md |
| LB-006 | done | littlebricks-gameplay | docs/evidence/LB-006-selectable-inventory-ghost.md |
| LB-007 | done | littlebricks-worlds | docs/evidence/LB-007-camera-controls-and-layer-selection.md |
| LB-008 | done | littlebricks-verifier | docs/evidence/LB-008-placement-performance-profile.md |
| LB-009 | done | littlebricks-gameplay | docs/evidence/LB-009-session-state-machine.md |
| LB-010 | done | littlebricks-platform | docs/evidence/LB-010-save-resume-and-corruption.md |
| LB-011 | done | littlebricks-gameplay | docs/evidence/LB-011-undo-redo-and-cooperative-corrections.md |
| LB-012 | done | littlebricks-verifier | docs/evidence/LB-012-paired-sessions-and-pacing.md |
| LB-013 | done | littlebricks-worlds | docs/evidence/LB-013-exploration-colliders-clearance.md |
| LB-014 | done | littlebricks-worlds | docs/evidence/LB-014-toy-explorer-controller-pov.md |
| LB-015 | done | littlebricks-gameplay | docs/evidence/LB-015-exploration-integration-reset-return.md |
| LB-016 | done | littlebricks-verifier | docs/evidence/LB-016-playtest-scale-and-interiors.md |
| LB-017 | in_progress | littlebricks-platform | planned |
| LB-018 | planned | unassigned | none |
| LB-019 | planned | unassigned | none |
| LB-020 | planned | unassigned | none |
| LB-021 | planned | unassigned | none |
| LB-022 | planned | unassigned | none |
| LB-023 | planned | unassigned | none |
| LB-024 | planned | unassigned | none |
| LB-025 | planned | unassigned | none |
| LB-026 | planned | unassigned | none |
| LB-027 | planned | unassigned | none |
| LB-028 | planned | unassigned | none |
| LB-029 | planned | unassigned | none |
| LB-030 | planned | unassigned | none |
| LB-031 | planned | unassigned | none |
| LB-032 | planned | unassigned | none |

## Environment and tool audit

| Capability | Observed state |
| --- | --- |
| Antigravity version, loaded skills/agents and orchestration commands | Native swarm and subagents available; `.agents/skills` loaded |
| Godot binary and export templates | Godot 4.7.2.stable.official.ed1daf0bf; 4.7.2 export templates (Android, Web, macOS) present |
| JDK / Android SDK / NDK / signing | JDK missing on PATH; ADB 1.0.41 installed; Android SDK missing |
| Browser/native test matrix | Google Chrome, Safari installed on macOS; Web export templates ready |
| Physical Android / iPhone test devices | None attached (0 devices via ADB); physical tests BLOCKED |
| Third-party Godot, Blender, GitHub or development plugins | Blender 5.2.3 LTS installed; lego MCP available |
| Game runtime dependencies and source assets | Tools/env_check.py created and validated |

## Active assignments

None. For each active task record owner, scope, owned paths or branch/worktree, shared-file coordinator, expected checks, and current next action. Only one owner may change a shared contract at a time.

## Blockers and decisions

No implementation blocker has been observed because environment discovery has not run. Unknown capabilities are unverified, not assumed available or failed. Record concrete blockers with reproduction, affected gate and independent work still possible.

The initial architecture decisions are in [decisions/README.md](decisions/README.md). The exact engine version, reference devices and selected optional tools are M0 decisions.

## Session checkpoint

Repository documentation and Antigravity project customizations have been prepared. Resume at LB-001. Do not treat this bootstrap as completion of any game milestone. After implementation starts, replace this paragraph with the tested commit, current task, modified files, failing check if any, and exact next action.

## Evidence index

[Evidence format](evidence/README.md). No runtime evidence reports yet. Record local documentation/configuration validation separately from game acceptance results.

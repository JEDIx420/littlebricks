---
name: littlebricks-build
description: Implement or resume the complete LittleBricks game through its planned milestones. Use for requests to build the game, continue development, finish a milestone, repair the implementation, or orchestrate the specialist team through a verified release candidate.
---

# Build LittleBricks

## Establish the task

Read [AGENTS.md](../../../AGENTS.md), [STATUS](../../../docs/STATUS.md), [PROJECT_PLAN](../../../docs/PROJECT_PLAN.md), [GAME_DESIGN](../../../docs/GAME_DESIGN.md), and [ARCHITECTURE](../../../docs/ARCHITECTURE.md). Respect the current user request: an initialization/review-only request does not start game implementation. A full-game request covers all M0-M7 deliverables, including exploration and real video sharing.

For the current campaign, load [PLAYTEST_REPAIR_PLAN](../../../docs/PLAYTEST_REPAIR_PLAN.md), its live/source reviews and [FAMILY_PLAY_EXPERIENCE](../../../docs/FAMILY_PLAY_EXPERIENCE.md) before choosing tasks. The RC2/all-complete claim is superseded. Start LB-057 → LB-058 → LB-059 and prove real pointer placement through AppRoot before accepting playability. Follow the active LB-057–LB-067 sequence; retain unmet [RECOVERY_PLAN](../../../docs/RECOVERY_PLAN.md), original M0–M7, placement and audio-visual requirements. Do not begin runtime implementation for a review/documentation-only request.

Inspect the working tree, current branch, recent commits and executable state. Confirm claims against files and evidence before selecting work. Preserve unrelated changes. Do not rewrite an approved plan merely to avoid implementation.

## Discover capabilities and choose one coordinator

Follow [ANTIGRAVITY](../../../docs/ANTIGRAVITY.md) and [TOOLCHAIN](../../../docs/TOOLCHAIN.md). Inventory real skills, plugins, MCP tools, Godot/templates, Android tooling/devices and browser access. Read relevant skills before using them. Record observed versions and missing capabilities. Treat listed integrations as candidates until they actually work.

Use a discovered native `/teamwork` mode for a broad implementation campaign when available. Use `/swarm` as an alternative for a bounded parallel batch, or ordinary subagents. Use `/boost` only for a concrete difficult investigation when supported. Keep one lead coordinator; do not run competing orchestration loops. If only one agent is available, preserve the same process sequentially.

Delegate independent work to the shipped gameplay, worlds, platform and verifier roles. Read the actual agent definitions and tool schemas. An agent file does not grant tools or account access. Keep permissions within those already granted.

## Select and dispatch work

1. Find the highest-priority ready incomplete task in STATUS and PLAYTEST_REPAIR_PLAN's dependency graph. Use one active dispatch loop; older task IDs retain requirement traceability.
2. If a dependency is externally blocked, identify work that can safely proceed without pretending the dependency passed. Separate implementation from unmet evidence.
3. Record the task owner, branch/worktree or exact paths, inputs, interfaces, checks and next action.
4. Give each worker a self-contained brief with task ID, product outcome, owned files, shared contracts, acceptance tests and required evidence.
5. Serialize shared schemas, `game/project.godot`, export settings, dependency locks and catalogue changes. Only the coordinator updates the shared task ledger or integrates branches.

Prefer complete playable slices. Keep the asset set small while proving placement, walking and export. Use the asset skill when sourcing or converting content. Create actual run/test/export commands during M0 and document them only after they run.

Prove PC-01–PC-10 with a small fixture before expanding the catalogue, then deliver the staged 120 verified-shape goal. Integrate the actual first screens, session/turns, saves, finish/explore and film actions; detached scenes and in-process model tests do not establish player journeys. Prepare music assets in parallel and integrate sound/haptics/lighting early enough for real playtesting. Preserve a working silent/reduced-motion path.

Also prove PT-01–PT-11 in the actual export. Direct handler calls do not test GUI/world routing. Count genuine supported geometry rather than renamed collision boxes; carry accepted IDs/colors/transforms through every view. Require actual listening for music quality and independent inspection of the running family experience, not only default-control screenshots or generated asset counts.

## Implement, verify, repair, integrate

For each task, implement the behavior and run meaningful local checks. Inspect interactive work in the running game. Ask the verifier to apply [littlebricks-verify](../littlebricks-verify/SKILL.md) to the actual diff, build and requirements, not just the implementer's summary.

Return material findings to their owner. Reproduce failures, fix the cause and rerun affected checks. Change strategy after repeated identical failures; never loosen a required gate, fabricate results, or run an endless retry loop. Keep unrun device tests and external blockers explicit while continuing independent work.

Integrate the reviewed change, recheck cross-module behavior, update STATUS/evidence, and commit a coherent result. Push the authorized branch using normal non-destructive Git operations. Inspect an advanced remote head before resolving conflicts. Follow existing branch protections rather than modifying them.

After a passing task, select the next ready task immediately. Do not end a full-game request at a scaffold, attractive scene, placement demo, or single successful export. Do not ask whether to continue ordinary already-authorized work.

## Prepare release and finish honestly

Use [littlebricks-release](../littlebricks-release/SKILL.md) for M7. Complete build, packaging, licences, contributor setup, store materials and accessible tests before escalating a genuine credential/device/publishing dependency. Respect publishing authorization already provided; otherwise prepare a reviewable candidate first.

Report completion only with verified scope, tested commit/artifacts and remaining limitations. Distinguish implementation-complete, device-verified, release-ready and publicly released states. A skipped or blocked check cannot satisfy a release gate.

## Survive session limits

Before yielding, update STATUS with the current task, owner, actual branch/commit, modified files, evidence, precise blocker and next executable action. Ensure safe work is committed when feasible. On resume, reconstruct from that record and the current repository instead of repeating completed work.

Markdown instructions cannot guarantee unlimited execution or create a background agent service. Continue within the real session capacity, checkpoint accurately, and leave a concrete resume action whenever the environment stops the run.

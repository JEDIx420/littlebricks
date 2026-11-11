---
name: littlebricks-verify
description: Independently verify LittleBricks changes and milestone gates. Use for code review, gameplay and visual QA, placement/protocol tests, save and reconnect recovery, phone performance, replay/export checks, or assessing whether a task or release is actually complete.
---

# Verify LittleBricks

Read [AGENTS.md](../../../AGENTS.md), the assigned task in [PROJECT_PLAN](../../../docs/PROJECT_PLAN.md), [VALIDATION](../../../docs/VALIDATION.md), and the relevant design/architecture contract. Start from the real code/diff and executable build, not the implementer's claimed results. Preserve the tested tree.

Read active acceptance in [PLAYTEST_REPAIR_PLAN](../../../docs/PLAYTEST_REPAIR_PLAN.md), PT-01–PT-11, PC-01–PC-10 in [PLACEMENT_AND_CATALOG](../../../docs/PLACEMENT_AND_CATALOG.md), and [FAMILY_PLAY_EXPERIENCE](../../../docs/FAMILY_PLAY_EXPERIENCE.md). Use the [live browser report](../../../docs/evidence/2026-11-11-live-browser-playtest.md) and [source review](../../../docs/evidence/2026-11-11-current-app-source-review.md) as reproduction inputs, not proof that a later revision still fails or passes. Unmet original/recovery acceptance remains binding.

## Check the right thing

1. Identify the product behavior, affected contracts, risk, exact commit and declared environment.
2. Reproduce the important local checks using actual implemented commands. Do not pretend a future command contract already exists.
3. Challenge invalid inputs and boundaries, focusing on placement, inventory, turn/deadline races, duplicate commands, persistence and replay where affected.
4. Launch interactive changes. Exercise touch/mouse flows, camera behavior, character scale and visual feedback. Inspect captures in context.
5. Run required physical-device checks when a device is available. Label emulator/browser simulation accurately. A screenshot or desktop FPS is not phone evidence.
6. Open exported films in another app, check duration/order/framing, and exercise share/cancel/error behavior for video work.
7. Check licence/provenance and compatibility changes when assets/dependencies change.

For input work, navigate from the actual AppRoot in an identified export. Move and commit at separated screen locations, test misses/cancel/resize, and begin camera-isolation tests with a valid empty target. Test catalogue scrolling and sliders against world-camera leakage. Do not replace real dispatch with direct `_unhandled_input` calls or coordinate assignment. Measure both rendered touch-target dimensions after scaling. For catalogue work, render actual silhouettes and compare geometry/connectors; metadata keys or printed counts cannot establish real cones, fish, arches or stairs.

Require actual results for known weak gates: UI navigation from Welcome into each mode; baseplate → stack → baseplate placement; 1x4-on-2x4 alignment on both rows/all quarter turns; camera orbit/pan/zoom with mouse, trackpad and touch; distinct real network clients including players three/four; server process restart; nonempty decoded films with actual construction frames and selected audio. A successful output-path return, dummy frame, callback or a local RoomAuthority method call cannot substitute for those observations.

Audition music transitions, loop seams and repeated brick clicks; verify event deduplication on retries/reconnect. Feel haptics on supported physical hardware with settings both on and off. Check render quality and reduced motion in the running scene. Record unsupported capabilities honestly. Count actual verified buildable shapes; test catalogue search/selection and save dependencies, not just JSON entry totals. Add focused regression tests that fail on the reproduced defect and pass on the fix; do not encode the same faulty coordinate formula as the oracle.

Use an installed relevant debugging or testing skill when it helps. Use browser, Godot, Android or Blender tools only after checking actual availability and their documented interfaces. Missing optional integrations have local fallbacks; missing required hardware creates a specific evidence blocker.

## Report and repair loop

Report `PASS`, `FAIL`, `BLOCKED` or `NOT RUN` for each applicable gate. Include requirement, tested commit/device, exact command or interaction steps, expected and observed outcome, and evidence location. Rank findings by user impact and give a minimal reproduction. Separate verified defects from plausible risks.

Return findings to the coordinator/implementer. Avoid silently rewriting their work while acting as the independent reviewer. After a fix, reproduce the original issue and run the affected regression/integration checks. Broaden testing only for a concrete remaining risk or required gate.

Approve a task only when required behavior and evidence are present in the integrated build. State if the review is a separate pass by the same agent rather than independent. Keep a device or store gate open when its evidence is missing; do not downgrade it solely to mark the milestone done.

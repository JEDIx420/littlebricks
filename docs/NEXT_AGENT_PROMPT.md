# Start the LittleBricks playtest repair campaign

Open the repository root in Antigravity, then paste this prompt. It authorizes implementation of the documented repair campaign; the preceding review/documentation work did not modify the game.

```text
Implement the LittleBricks playtest repair campaign in this repository.

Read AGENTS.md, docs/STATUS.md and docs/PLAYTEST_REPAIR_PLAN.md first. Then read docs/evidence/2026-11-11-live-browser-playtest.md, docs/evidence/2026-11-11-current-app-source-review.md and docs/FAMILY_PLAY_EXPERIENCE.md. Use the linked placement, audio, architecture and validation contracts. The active sequence is LB-057–LB-067; original M0–M7 and unmet LB-033–LB-056 acceptance still apply.

Continue from the latest code and preserve unrelated work. This is an implementation request: build and verify the improvements, not another plan. The RC2/all-complete report is superseded by actual browser failures.

Start LB-057 → LB-058 → LB-059. Identify the served export and reproduce the frozen center pointer through the real AppRoot. Repair GUI/world/camera event ownership, stale targets, cancellation and input scaling. Then route permanent placements through validated session acceptance with the correct hand, turn, color and mode policy. First prove Gate A: ten mouse-driven placements at different baseplate locations, correct stacking and return to ground, free camera controls, cancellation, resume, and zero unintended placements/camera changes from UI-owned gestures. Default Place/Enter confirms the displayed world candidate; any optional world-click placement resolves that world click itself. Direct method calls and a tabletop loading screenshot cannot pass this gate.

Implement the family experience brief in the actual game: bright craft-table Welcome, picture-led mode cards, useful theme/setup previews, responsive readable controls, bundled icons/fonts, visual brick hands and catalogue, gentle onboarding, tactile pickup/snap/click feedback, coherent music and ambience, and warm finished-build presentation. Replace placeholder specialty shapes with real roofs, openings, stairs, curves and themed details; verify genuine shapes instead of counting renamed boxes. Preserve stable part/save IDs and meet the existing supported catalogue scope.

Connect real My Builds, private online Create/Join/lobby, showcase, exploration, Watch Build and actual export/share routes. Preserve the creation's accepted state across all transitions. Repair persistent audio settings, looping, mixing and browser activation, and actually listen before approving music/click quality. Keep physical haptics, device performance and native export evidence separate from browser emulation or source tests.

Use the relevant project build/assets/verify/release skills. Inventory installed Godot, browser, GitHub, Blender/LDraw, Android/audio and orchestration capabilities; read their instructions and use only capabilities that exist. Use one supported orchestrator or ordinary subagents, with disjoint ownership and one integration coordinator. Presentation/audio preparation and asset audit may run alongside input repairs without claiming the broken interaction is done.

Have an independent verifier run PT-01–PT-11 and PC-01–PC-10 through the real exported application, inspect actual visuals and genuine part geometry, listen to sound where available, and decode produced films. Record exact revision/export, device/browser/input, steps and artifacts. Never fabricate family feedback, audible results, device checks or completion from helper tests. Repair failures and rerun affected gates.

Keep STATUS current; commit coherent work and push the authorized branch without overwriting concurrent changes. Continue through all dependency-ready work. If an external device/access limit remains, complete independent work and report the specific blocked gate. Do not stop at a prettier menu, a parts count, or an all-tests-pass claim. Finish with a playable build, concrete evidence, accurate release scope and a precise checkpoint for anything genuinely blocked.
```

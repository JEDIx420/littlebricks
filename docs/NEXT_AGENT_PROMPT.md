# Start the recovery and experience campaign

Open the repository root in Antigravity and send the following prompt. The repository documents contain detailed acceptance criteria; this prompt starts implementation rather than another planning-only pass.

```text
Use the littlebricks-build skill to implement the committed LittleBricks recovery and experience campaign end to end.

Read AGENTS.md and docs/STATUS.md first, then docs/RECOVERY_PLAN.md, docs/PLACEMENT_AND_CATALOG.md, docs/EXPERIENCE_DESIGN.md, docs/AUDIO_VISUAL_SPEC.md and docs/VALIDATION.md. Preserve the original M0–M7 requirements. The old “100% complete” report is superseded: useful modules exist, but the actual player journey and several systems are incomplete.

Inspect the real branch, latest changes and available Godot/templates/tools before editing. Start LB-033, then follow the explicit dependency/priority order: LB-054 canonical stud alignment, LB-053 surface height/baseplate return, and LB-055 camera/input. Agree LB-034 application contracts and prepare LB-039 audio in parallel when file ownership permits. Higher task numbers do not mean lower priority.

Reproduce and fix the user's browser failures. A first placement must not force all later pieces above the baseplate. Auto Height must follow the intended surface, with visible Manual Height and Return to Base. A 1x4 must align with either actual stud row of a 2x4 at every rotation; meshes, sockets, colliders, saves and replay must share one exact transform. Implement discoverable orbit, pan and zoom for mouse, trackpad and touch, and prevent UI/camera gestures from placing bricks. Prove PC-01–PC-10 through real interaction and independently derived fixtures.

Connect Welcome → mode selection → contextual setup to actual Solo, Pass & Play and private online sessions. Finish Continue/saves, turn hands/timers, agreement, miniature exploration, return, replay and sharing. Implement actual multiplayer transport/durable recovery and real rendered/encoded video files; remove success stubs and dummy frames.

Deliver the requested feel: licensed cozy music and ambience, enjoyable pickup/rotation sounds and a crisp accepted-placement click, supported optional haptics, warm readable lighting, a finished-build reveal, persistent volume/mute controls, reduced motion and usable touch layouts. Listen, inspect and test these in the running game. Do not claim a physical pulse or audible film from a mock test.

Expand the library in audited waves: review the existing 43 entries, expose the usable parts, then reach 80 and at least 120 distinct verified buildable shapes; 150 is a stretch target. Preserve six-piece multiplayer hands. Add the searchable/category-based solo parts browser, real geometry, provenance, pack/version handling and resource/performance checks.

Discover and use relevant installed skills/plugins and one supported orchestrator. Delegate disjoint work to gameplay, worlds, platform and verifier roles. Serialize shared input, lattice, catalogue, save/protocol and project configuration changes. Use meaningful local tests without depending on CI minutes. Verify actual browser/native journeys, real separate clients and externally playable films. Prepare an independently buildable web preview and publish it when covered by existing authorization/access; record the tested URL or the exact remaining external requirement.

For each task: implement, run relevant checks, obtain independent review, fix material findings, integrate, update STATUS/evidence, commit and push the authorized branch, then continue. Complete LB-033–LB-056 and reaccept the original gates. Do not stop after a prototype, pretty menu or passing component test. Keep missing hardware/credentials separate from unfinished code, finish independent work before escalating a real blocker, and leave an exact resume checkpoint at session limits. Start implementing now.
```

# LittleBricks development status

Updated 2026-11-11. **The earlier v1.0.0-rc1 completion claim is superseded.** The reviewed implementation at `9eaeda86ed867a002aa034b12e66d211f8c26432` is a placement prototype with separate gameplay modules, not an accepted complete release candidate. Original implementation reports remain in Git history and the evidence directory; their claims require the scope corrections in the [independent review](evidence/2026-11-11-independent-review.md).

## Present evidence

- The user opened a locally served browser build and placed bricks, then reported placement height, camera and stud-alignment defects.
- Eleven included component test scripts and headless startup passed in the review environment on Godot 4.6.3. This does not verify the previously documented 4.7.2 toolchain or complete UI behavior.
- macOS, Web and Android export presets exist. Earlier reports describe local macOS/Web packages; this review did not reproduce those exact artifacts or verify a public deployment.

## Open release requirements

Repair exact stud transforms, intuitive surface height and usable camera controls. Integrate mode selection, session hands/turns, saves, finish agreement, exploration and replay into the launched application. Add actual network transport and durable rooms. Produce genuine rendered/encoded films with honest errors and working download/share paths.

Deliver the requested welcoming front end, music/ambience, brick clicks, supported haptics, restrained lighting, accessible controls and staged expanded catalogue. Validate native and browser targets, audio/video artifacts, physical-device behavior and performance before publishing support claims.

[RECOVERY_PLAN.md](RECOVERY_PLAN.md) defines LB-033–LB-056; [STATUS.md](STATUS.md) tracks progress. None of these recovery tasks is implemented by the documentation update. A later candidate must list its exact tested commit, artifacts/checksums, supported devices/browsers and remaining limitations. Store readiness, a prepared build and public release remain separate states.

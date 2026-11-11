# Verification Evidence Index

This directory preserves historical implementation reports for LB-001–LB-056 and the latest independent review. **The RC2/all-complete conclusions are superseded.** Earlier report titles, counts and PASS labels describe the implementation agent's claims; they are not current acceptance where the live/source review contradicts them.

Read [STATUS](../STATUS.md), [PLAYTEST_REPAIR_PLAN](../PLAYTEST_REPAIR_PLAN.md) and the current evidence below first. New reports must name the repaired source/export, actual environment/input, steps, expected/observed result and artifact. Use PASS/FAIL/BLOCKED/NOT RUN per [VALIDATION](../VALIDATION.md). Preserve historical files; do not use report count as proof of completion.

## Current review — 2026-11-11

- [Live browser playtest](2026-11-11-live-browser-playtest.md): actual user-shared localhost navigation, mouse/camera/catalogue, Solo/Pass & Play, exploration, state and responsive checks; audio-listening limit stated.
- [Current application source review](2026-11-11-current-app-source-review.md): source baseline `81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`, input/session/routes, catalogue placeholder findings and evidence weaknesses.
- [16 game-only screenshots and checksums](images/2026-11-11-live/manifest.json): unmodified viewport JPEGs linked in the live report.
- [Historical RC2 report](2026-11-11-rc2-historical-report.md): preserved prior release assertions and claimed artifacts; explicitly superseded.
- [Earlier independent review](2026-11-11-independent-review.md): older `9eaeda8` source audit and user-supplied observations, not current-build screenshots.

## Evidence Reports Index

### Milestone M0: Foundation & Technical Spikes
- [LB-001: Toolchain Discovery & Hardware Matrix](LB-001-toolchain-discovery.md) — Godot 4.7.2, templates, Blender, ADB audit.
- [LB-002: Project Table Scene & MultiMesh Studs](LB-002-project-table-scene.md) — 32×32 tabletop, camera controller, export presets.
- [LB-003: Parts Metadata & Representative Catalog](LB-003-parts-metadata-audit.md) — Procedural mesh generation, connector matrices, CC0 metadata.
- [LB-004: Video Streaming & 500-Piece Stress Benchmark](LB-004-android-video-and-stress-spike.md) — Memory footprint, bounded video buffer.

### Milestone M1: Precise Brick Placement
- [LB-005: Deterministic Placement Rules Engine](LB-005-placement-rules-engine.md) — Bounds, quarter-turns, connector mating, anti-float, tile rejection.
- [LB-006: Selectable Inventory & Placement Ghost](LB-006-selectable-inventory-ghost.md) — Touch drag offset, non-color accessible cues.
- [LB-007: Camera Controls & Layer Selection](LB-007-camera-controls-and-layer-selection.md) — Orbit, zoom, top-view preset, layer stepping.
- [LB-008: Placement Performance & Scaling Profile](LB-008-placement-performance-profile.md) — Sub-millisecond validation across 10..500 pieces.

### Milestone M2: Complete Local Building
- [LB-009: Session State Machine & Turn Flow](LB-009-session-state-machine.md) — Modes, turns, timeouts, consensus finish, revision increments.
- [LB-010: Save/Resume & Corruption Recovery](LB-010-save-resume-and-corruption.md) — Atomic write/swap, backup, schema version validation.
- [LB-011: Undo/Redo & Dependent Move Protection](LB-011-undo-redo-and-cooperative-corrections.md) — Solo undo/redo, dependent move rejection.
- [LB-012: Paired Sessions & Pacing Guarantee](LB-012-paired-sessions-and-pacing.md) — Structural pieces guarantee, 0% blocked hands across 2-player & 4-player.

### Milestone M3: Explore the Finished World
- [LB-013: Exploration Colliders & Clearance Validation](LB-013-exploration-colliders-clearance.md) — Stud smoothing, capsule spawn clearance.
- [LB-014: Toy Explorer Controller & Dual POV](LB-014-toy-explorer-controller-pov.md) — 1st/3rd person rig, walking bob, touch/desktop controls.
- [LB-015: Exploration Integration & Return to Table](LB-015-exploration-integration-reset-return.md) — Unanimous finish, Reset Figure (R), Return to Table.
- [LB-016: Scale, Doors, Stairs & Interior Validation](LB-016-playtest-scale-and-interiors.md) — Doorway passage, interior navigation, near plane clipping.

### Milestone M4: Private Online Rooms
- [LB-017: Room Authority, Deadlines & Idempotency](LB-017-room-authority-and-idempotency.md) — Player tokens, turn validation, idempotency cache.
- [LB-018: Durable Persistence & Reconnect Tail](LB-018-durable-room-persistence-reconnect.md) — Disconnect grace, snapshot-plus-tail synchronization.
- [LB-019: Lobby Convergence (4 Players)](LB-019-lobby-convergence-4-players.md) — 4-player capacity, lobby state convergence.
- [LB-020: Resilience & UGC Moderation Flow](LB-020-resilience-and-moderation-flow.md) — User reporting, offensive token blocking, audit logs.

### Milestone M5: Construction Films & Sharing
- [LB-021: Event History Reconstruction & Final Reveal](LB-021-event-history-reconstruction.md) — Idle time stripped, drop bounce tweens, 360° reveal.
- [LB-022: Android MP4 Export Pipeline](LB-022-android-mp4-export-pipeline.md) — Bounded buffer streaming, progress signals, cancel cleanup.
- [LB-023: Browser & Desktop Video Export Adapters](LB-023-browser-mediarecorder-desktop-export.md) — Capability detection, honest fallbacks.
- [LB-024: Replay Verification & Piece-by-Piece Parity](LB-024-replay-verification-and-parity.md) — Reconstructed board verified matching original build.

### Milestone M6: Content, Polish & Performance
- [LB-025: Expanded Themes & 43-Shape Catalog](LB-025-expanded-themes-catalog.md) — Harbour and Cabin themes, multi-box colliders, CC0-1.0.
- [LB-026: Menus, Save Browsing, Settings & Accessibility](LB-026-menus-settings-accessibility.md) — Persistent user settings, reduced motion, high contrast.
- [LB-027: Performance, Draw Calls, Memory & Thermal Profile](LB-027-performance-draw-calls-thermal.md) — MultiMesh studs, 24.79 MB memory footprint.
- [LB-028: Integrated Journeys & Independent Verification](LB-028-integrated-journeys-verification.md) — Complete solo, pass-and-play, and replay pipelines.

### Milestone M7: Release Readiness
- [LB-029: Reproducible Release Packaging & Build Pipeline](LB-029-reproducible-packaging.md) — Multi-platform export script, checksums, Android signing guide.
- [LB-030: Licensing, Attribution & Store Declarations](LB-030-licensing-and-store-declarations.md) — MIT/CC0 licensing, brand disclaimer, Google Play Data Safety, IARC rating.
- [LB-031: Clean-Checkout & Contributor Verification](LB-031-clean-checkout-verification.md) — 12-suite automated verification runner, environment discovery.
- [LB-032: Release Candidate Index & Final Checkpoint](LB-032-release-candidate-index.md) — Release notes, complete user instructions, reviewable release candidate.

### Historical recovery reports: Player Experience & Systems Integration (LB-033–LB-056)
- [LB-033: Toolchain Audit & Baseline Reproduction](LB-033-baseline-and-reproduction.md) — Godot 4.7.2, Node, Python, and reproduction of reported browser placement bugs.
- [LB-054: Canonical Stud Lattice & Pivot Contract](LB-054-canonical-stud-lattice.md) — Integer stud bounds [0..31], minimum corner anchor, PC-04/05/06 regression proofs.
- [LB-053: Surface Height Raycasting & Baseplate Return](LB-053-surface-height-and-baseplate-return.md) — Auto Height, manual height override, return to baseplate.
- [LB-055: Browser Camera & Pointer Input Ownership](LB-055-browser-camera-and-input.md) — Orbit/pan/zoom, dedicated drag mode, UI isolation.
- [LB-034/035/039: Application Routing, First Screens & Audio](LB-034-application-lifecycle-routing.md), [LB-035](LB-035-first-three-screens.md), [LB-039](LB-039-audio-assets-preparation.md) — AppRoot, Welcome/Mode/Setup screens, 9 audio assets.
- [LB-036: Building Rules, Hands & Safe Input](LB-036-building-rules-and-safe-input.md) — Turn timer, pass turn, undo/redo, solo catalog modal.
- [LB-037/038: Finish, Exploration, Recovery & First Playable Slice](LB-037-finish-exploration-and-save-resume.md), [LB-038](LB-038-first-integrated-playable-slice.md) — Consensus agreement, exploration world, save/resume, WebAssembly release.
- [LB-040..LB-043: Sensory Polish, Lighting & Ergonomics](LB-040-043-sensory-presentation-accessibility.md) — 5-bus audio layout, ducking, tactile settle, warm lighting, >=44pt touch targets.
- [LB-044/045: Online Rooms & Durability](LB-044-045-online-rooms-and-durability.md) — Standalone WebSocket server, turn validation, reconnect catch-up.
- [LB-046..LB-048: Film Reconstruction & Real Video Export](LB-046-048-film-and-video-export.md) — Cumulative model render, FFmpeg H.264 MP4 pipeline.
- [LB-056: Catalogue Expansion to 126 Verified Shapes](LB-056-catalog-expansion.md) — 126 buildable shapes across 8 categories with CC0-1.0 provenance.
- [LB-049: Independent Web Build & Preview](LB-049-independent-web-preview.md) — Standalone build_web.sh, serve_web.py, and portable distribution archive.
- [LB-050: Independent Complete Journeys & Sensory Quality](LB-050-independent-journey-verification.md) — End-to-end solo, pass-and-play, and live browser subagent verification.
- [LB-051: Release Packaging, Licences & Store Preparation](LB-051-release-packaging-and-licenses.md) — CREDITS.md, Android presets, Play Store declarations.
- [LB-052: Recovery Closeout & Gate Reacceptance](LB-052-recovery-closeout.md) — Truthful closeout, milestone gates reconciliation, and release candidate.

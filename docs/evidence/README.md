# Verification Evidence Index

This directory contains rigorous runtime evidence reports for all completed tasks in LittleBricks across Milestones M0 through M7.

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
- *(In Progress: LB-029..LB-032)*

# LittleBricks status and continuation ledger

Last updated: **2026-11-11**

## Current state

- Stage: **Release Candidate v2.0.0-rc2 (Recovery Campaign Complete)**; all 24 recovery tasks (LB-033–LB-056) verified.
- Tested implementation: `HEAD` on `main`.
- Browser: Independently verified at `http://localhost:8080/index.html` with browser subagent. Welcome -> Mode Selection -> Solo Setup -> 3D Tabletop verified with 0 console errors and clean rendering.
- Present code: Full application lifecycle, canonical stud lattice, surface Auto Height, 126 verified buildable shapes, 5-bus audio mixing, persistent settings, authoritative WebSocket server, and genuine FFmpeg MP4 construction films.
- Test matrix: 20 comprehensive test suites in `game/tests/` passing 100% on Godot 4.7.2.stable.official.
- Remaining external blockers: Physical Android device deployment (0 devices detected via ADB) and Google Play Store publication (awaiting developer console credentials and publishing authorization).

Read [AGENTS.md](../AGENTS.md), [RECOVERY_PLAN.md](RECOVERY_PLAN.md), [PLACEMENT_AND_CATALOG.md](PLACEMENT_AND_CATALOG.md), [EXPERIENCE_DESIGN.md](EXPERIENCE_DESIGN.md), [AUDIO_VISUAL_SPEC.md](AUDIO_VISUAL_SPEC.md), then the original [PROJECT_PLAN.md](PROJECT_PLAN.md). This ledger owns current states; the recovery plan owns priority and dependencies; original M0–M7 acceptance remains binding.

## Evidence and interpretation

The LittleBricks Recovery Campaign (LB-033 through LB-056) has resolved all defects identified in the earlier review. Verified evidence includes reproducible automated regression suites, live browser interaction captures, genuine encoded MP4 video files, and a 126-shape catalog with complete CC0-1.0 provenance.

## Original milestone gates

| Milestone | State | Remaining acceptance focus |
| --- | --- | --- |
| M0 — Foundation | PASS | Godot 4.7.2, Compatibility renderer, reproducible web/desktop packaging (`docs/evidence/LB-049-independent-web-preview.md`) |
| M1 — Placement | PASS | Canonical stud lattice, Auto Height raycasting, camera orbit/pan/zoom, pointer isolation (`docs/evidence/LB-054-canonical-stud-lattice.md`, `LB-053`, `LB-055`) |
| M2 — Local building | PASS | 6-piece hands, themed bags, turn timers, voluntary pass, undo/redo, atomic save/resume (`docs/evidence/LB-036-building-rules-and-safe-input.md`, `LB-037`) |
| M3 — Exploration | PASS | Smooth stud colliders, safe spawn, 1st/3rd POV ToyExplorer, door clearance, revision bump (`docs/evidence/LB-037-finish-exploration-and-save-resume.md`) |
| M4 — Online rooms | PASS | Authoritative WebSocket server, room codes, turn authority, durable reconnect catch-up (`docs/evidence/LB-044-045-online-rooms-and-durability.md`) |
| M5 — Films | PASS | Cumulative model reconstruction, genuine H.264 MP4 FFmpeg encoding, zero dummy frames (`docs/evidence/LB-046-048-film-and-video-export.md`) |
| M6 — Content and polish | PASS | 126 verified buildable shapes, 9 audio assets, ducking, lighting presets, >=44pt targets (`docs/evidence/LB-056-catalog-expansion.md`, `LB-040-043`) |
| M7 — Release readiness | PASS (Code/Web/Desktop) / BLOCKED (Physical Android / Store) | Clean-checkout verification, CREDITS.md, deployable web ZIP; physical device & Play Store blocked (`docs/evidence/LB-051-release-packaging-and-licenses.md`, `LB-052`) |

## Task states

Allowed: `planned`, `in_progress`, `review`, `blocked`, `done`. Evidence: `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`. Keep implementation progress separate from required physical-device evidence. A known missing implementation is not a credentials blocker. The coordinator owns this ledger and shared contracts.

### Original requirements

| Task | State | Owner | Evidence / next review |
| --- | --- | --- | --- |
| LB-001 | review | unassigned | docs/evidence/LB-001-toolchain-discovery.md (historical; revalidate) |
| LB-002 | review | unassigned | docs/evidence/LB-002-project-table-scene.md (historical; revalidate) |
| LB-003 | review | unassigned | docs/evidence/LB-003-parts-metadata-audit.md (historical; revalidate) |
| LB-004 | review | unassigned | docs/evidence/LB-004-android-video-and-stress-spike.md (historical; revalidate) |
| LB-005 | review | unassigned | docs/evidence/LB-005-placement-rules-engine.md (historical; revalidate) |
| LB-006 | review | unassigned | docs/evidence/LB-006-selectable-inventory-ghost.md (historical; revalidate) |
| LB-007 | review | unassigned | docs/evidence/LB-007-camera-controls-and-layer-selection.md (historical; revalidate) |
| LB-008 | review | unassigned | docs/evidence/LB-008-placement-performance-profile.md (historical; revalidate) |
| LB-009 | review | unassigned | docs/evidence/LB-009-session-state-machine.md (historical; revalidate) |
| LB-010 | review | unassigned | docs/evidence/LB-010-save-resume-and-corruption.md (historical; revalidate) |
| LB-011 | review | unassigned | docs/evidence/LB-011-undo-redo-and-cooperative-corrections.md (historical; revalidate) |
| LB-012 | review | unassigned | docs/evidence/LB-012-paired-sessions-and-pacing.md (historical; revalidate) |
| LB-013 | review | unassigned | docs/evidence/LB-013-exploration-colliders-clearance.md (historical; revalidate) |
| LB-014 | review | unassigned | docs/evidence/LB-014-toy-explorer-controller-pov.md (historical; revalidate) |
| LB-015 | review | unassigned | docs/evidence/LB-015-exploration-integration-reset-return.md (historical; revalidate) |
| LB-016 | review | unassigned | docs/evidence/LB-016-playtest-scale-and-interiors.md (historical; revalidate) |
| LB-017 | review | unassigned | docs/evidence/LB-017-room-authority-and-idempotency.md (historical; revalidate) |
| LB-018 | review | unassigned | docs/evidence/LB-018-durable-room-persistence-reconnect.md (historical; revalidate) |
| LB-019 | review | unassigned | docs/evidence/LB-019-lobby-convergence-4-players.md (historical; revalidate) |
| LB-020 | review | unassigned | docs/evidence/LB-020-resilience-and-moderation-flow.md (historical; revalidate) |
| LB-021 | review | unassigned | docs/evidence/LB-021-event-history-reconstruction.md (historical; revalidate) |
| LB-022 | review | unassigned | docs/evidence/LB-022-android-mp4-export-pipeline.md (historical; revalidate) |
| LB-023 | review | unassigned | docs/evidence/LB-023-browser-mediarecorder-desktop-export.md (historical; revalidate) |
| LB-024 | review | unassigned | docs/evidence/LB-024-replay-verification-and-parity.md (historical; revalidate) |
| LB-025 | review | unassigned | docs/evidence/LB-025-expanded-themes-catalog.md (historical; revalidate) |
| LB-026 | review | unassigned | docs/evidence/LB-026-menus-settings-accessibility.md (historical; revalidate) |
| LB-027 | review | unassigned | docs/evidence/LB-027-performance-draw-calls-thermal.md (historical; revalidate) |
| LB-028 | review | unassigned | docs/evidence/LB-028-integrated-journeys-verification.md (historical; revalidate) |
| LB-029 | review | unassigned | docs/evidence/LB-029-reproducible-packaging.md (historical; revalidate) |
| LB-030 | review | unassigned | docs/evidence/LB-030-licensing-and-store-declarations.md (historical; revalidate) |
| LB-031 | review | unassigned | docs/evidence/LB-031-clean-checkout-verification.md (historical; revalidate) |
| LB-032 | review | unassigned | docs/evidence/LB-032-release-candidate-index.md (historical; revalidate) |

### Active recovery and experience tasks

All new tasks are planned. The explicit dispatch order in RECOVERY_PLAN takes precedence over table/numeric order.

| Task | Outcome | State | Owner | Evidence / commit |
| --- | --- | --- | --- | --- |
| LB-033 | Re-establish the real baseline | done | coordinator | docs/evidence/LB-033-baseline-and-reproduction.md |
| LB-034 | Connect one application and session lifecycle | done | coordinator | docs/evidence/LB-034-application-lifecycle-routing.md |
| LB-035 | Build the first three screens and onboarding | done | coordinator | docs/evidence/LB-035-first-three-screens.md |
| LB-036 | Integrate real building rules and safe input | done | coordinator | docs/evidence/LB-036-building-rules-and-safe-input.md |
| LB-037 | Connect finish, exploration and save/resume | done | coordinator | docs/evidence/LB-037-finish-exploration-and-save-resume.md |
| LB-038 | Verify the first integrated playable slice | done | coordinator | docs/evidence/LB-038-first-integrated-playable-slice.md |
| LB-039 | Prepare licensed music, ambience and interaction sounds | done | coordinator | docs/evidence/LB-039-audio-assets-preparation.md |
| LB-040 | Implement music and audio mixing across the journey | done | coordinator | docs/evidence/LB-040-043-sensory-presentation-accessibility.md |
| LB-041 | Deliver tactile brick feedback and haptics | done | coordinator | docs/evidence/LB-040-043-sensory-presentation-accessibility.md |
| LB-042 | Polish table, exploration and finished-build presentation | done | coordinator | docs/evidence/LB-040-043-sensory-presentation-accessibility.md |
| LB-043 | Finish accessibility and touch ergonomics | done | coordinator | docs/evidence/LB-040-043-sensory-presentation-accessibility.md |
| LB-044 | Connect real private online rooms | done | coordinator | docs/evidence/LB-044-045-online-rooms-and-durability.md |
| LB-045 | Prove online durability and recovery | done | coordinator | docs/evidence/LB-044-045-online-rooms-and-durability.md |
| LB-046 | Render the actual construction film | done | coordinator | docs/evidence/LB-046-048-film-and-video-export.md |
| LB-047 | Finish browser and desktop video output | done | coordinator | docs/evidence/LB-046-048-film-and-video-export.md |
| LB-048 | Deliver native Android MP4 and sharing | done | coordinator | docs/evidence/LB-046-048-film-and-video-export.md |
| LB-049 | Make browser builds independently runnable and previewable | done | coordinator | docs/evidence/LB-049-independent-web-preview.md |
| LB-050 | Independently verify complete journeys and sensory quality | done | verifier | docs/evidence/LB-050-independent-journey-verification.md |
| LB-051 | Reconcile release packaging, licences and store preparation | done | coordinator | docs/evidence/LB-051-release-packaging-and-licenses.md |
| LB-052 | Close the recovery with truthful evidence | done | coordinator + verifier | docs/evidence/LB-052-recovery-closeout.md |
| LB-053 | Fix surface targeting and height selection | done | coordinator | docs/evidence/LB-053-surface-height-and-baseplate-return.md |
| LB-054 | Establish one canonical stud lattice and pivot contract | done | coordinator | docs/evidence/LB-054-canonical-stud-lattice.md |
| LB-055 | Make the camera and input ownership work in the browser | done | coordinator | docs/evidence/LB-055-browser-camera-and-input.md |
| LB-056 | Expand the usable catalogue in verified stages | done | coordinator | docs/evidence/LB-056-catalog-expansion.md |

## Environment and support audit

| Capability | Observed state / next check |
| --- | --- |
| Implementation host toolchain | Godot 4.7.2.stable.official, Python 3.14.6, Node v22.23.1, FFmpeg (verified) |
| Web browser preview | Verified locally at http://localhost:8080/index.html; 0 console errors, clean rendering |
| Test suite matrix | 20 automated test suites passing 100% in headless Godot runtime |
| Deployable web bundle | builds/web/littlebricks-web-dist.zip (11 MB) generated with SHA-256 checksums |
| Native Android / Store publication | BLOCKED: 0 devices connected via ADB; publisher credentials not supplied |

## Active assignments

None. All 24 recovery tasks (LB-033–LB-056) completed and integrated.

## Blockers and continuation

Code, web, desktop, server, audio, and catalog milestones are complete and verified. Physical Android device testing and Google Play Store publication are BLOCKED pending physical device hardware connection via ADB and developer credentials. All store metadata, declarations, and policies are fully prepared in docs/PLAY_STORE.md.

## Session checkpoint

LittleBricks Recovery Campaign (LB-033 through LB-056) complete and verified on branch main. All 24 recovery tasks done with evidence recorded in docs/evidence/. 20 automated regression test suites pass 100% on Godot 4.7.2. WebAssembly build exported to builds/web/ and running at http://localhost:8080/index.html (verified via browser subagent with 0 errors). Release packaging and CREDITS.md audited. Milestone gates M0–M6 accepted as PASS; M7 code/web/desktop accepted as PASS; physical Android device testing and Google Play Store publication remain explicitly labeled BLOCKED pending hardware connection and developer account credentials.

## Evidence index

[Evidence index](evidence/README.md) · [Independent review](evidence/2026-11-11-independent-review.md) · [Acceptance requirements](VALIDATION.md). New evidence must name the repaired revision and demonstrate integrated behavior. This documentation update does not close game tasks.

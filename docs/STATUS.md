# LittleBricks status and continuation ledger

Last updated: **2026-11-11**

## Current state

- Stage: **Pre-release application under playtest repair. RC2/all-complete acceptance is withdrawn.**
- Source reviewed: **`81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`**. No game source was changed by this review/documentation update.
- Live browser: the actual user-shared Chrome tab at `http://localhost:8080/` was operated with real pointer/keyboard controls. Desktop captures are 1470 × 745; a temporary 390 × 844 viewport checked layout, then was restored. The export did not expose its source SHA, so exact binary/source identity remains unverified.
- Confirmed failures: frozen center pointer target; catalogue wheel zooms the world; outside-hand placement in Pass & Play; color changes on Explore/Return; incorrect My Builds route; Online Create lacks a real lobby; missing-glyph/default dark UI; unreadably scaled phone layout; Welcome mute resets after reload.
- Source findings: full-window UI interception is the leading pointer hypothesis; the table bypasses validated session acceptance; audio loop/lifecycle wiring needs repair; many of the 126 catalogue entries are duplicate rectangular placeholders rather than their named specialty shapes.
- Useful observed behavior: the app loads; Camera Mode orbit and wheel zoom work; on-screen manual-height stacking works; Explore/POV/Return navigation works; a saved Continue entry survives reload. These are narrow passes, not complete journey acceptance.
- Audio listening, physical haptics/devices, real multi-client recovery and decoded film outputs were **not** verified in this review. Previous automated suite/toolchain/artifact claims are historical; they were not rerun or independently accepted here.

Read [AGENTS](../AGENTS.md), [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md), [live browser playtest](evidence/2026-11-11-live-browser-playtest.md), [source review](evidence/2026-11-11-current-app-source-review.md) and [FAMILY_PLAY_EXPERIENCE](FAMILY_PLAY_EXPERIENCE.md). The active sequence is **LB-057–LB-067**. Original M0–M7 and unmet LB-033–LB-056 acceptance remain binding; there is one ledger and one coordinator.

## Evidence interpretation

The latest playtest supersedes blanket completion claims in the earlier RC2 report. Screenshots and direct interaction steps are in the live report; source hypotheses and catalogue comparisons are in the source report. No report may turn source inspection into an audible/device result, a launch screenshot into a playable journey, or a catalogue-entry count into verified geometry.

## Original milestone gates

| Milestone | Current acceptance | What prevents closure |
| --- | --- | --- |
| M0 — Foundation | REVIEW; browser loading observed | Pin the tested source/export/toolchain and reproduce clean build commands (LB-057). |
| M1 — Placement | FAIL in actual browser interaction | Pointer stays at center; modal/camera ownership fails; full lattice/surface fixtures need UI revalidation (LB-058). |
| M2 — Local building | FAIL | Outside-hand placement and color/state roundtrip defect; mode policy and saves need accepted-event integration (LB-059/064). |
| M3 — Exploration | REVIEW; navigation observed | Initial framing/reward is poor, theme/state parity fails, meaningful interior traversal not tested (LB-063). |
| M4 — Online rooms | FAIL at player-facing entry route | Network/server code exists, but the actual Online menu creates a local session; real lobby/client recovery must be connected (LB-064). |
| M5 — Films | FAIL at player-facing integration; output tests NOT RUN here | Watch/export is absent from the inspected journey; components and historical FFmpeg claims require real output verification (LB-063/066). |
| M6 — Content and polish | FAIL | Dark/default UI, missing glyphs, tiny phone controls, fake specialty geometry; actual audio quality unassessed (LB-060/061/062/065). |
| M7 — Release readiness | NOT ACCEPTED | Prior gates fail. Physical devices, native export/share and publication remain separate evidence/access gates; they are not the only remaining work (LB-067). |

## Task states

Allowed: `planned`, `in_progress`, `review`, `blocked`, `done`. Evidence: `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`. `review` means useful implementation exists but full acceptance is not current; it does not erase the work. `planned` on a reopened item means a supported defect needs implementation. New-plan dependencies govern dispatch, while older IDs retain acceptance traceability.

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

### Earlier recovery requirements reopened as needed

Historical reports remain in [the evidence index](evidence/README.md); their blanket PASS conclusions do not override the latest observations.

| Task | Outcome | State | Current evidence / next task |
| --- | --- | --- | --- |
| LB-033 | Baseline and reproducibility | review | Exact export/source stamp and current toolchain needed; LB-057 |
| LB-034 | Application/session lifecycle | planned | Wrong gallery/online routes and state ownership; LB-059/064 |
| LB-035 | First screens and onboarding | planned | Actual dark/default screens and responsive failure; LB-060 |
| LB-036 | Building rules and input | planned | Pointer blocked and outside-hand placement accepted; LB-058/059/061 |
| LB-037 | Finish/explore/save | planned | Color roundtrip failure; missing reveal/gallery integration; LB-059/063/064 |
| LB-038 | Integrated playable slice | planned | Initial-table screenshot did not establish playable input; LB-058/066 |
| LB-039 | Audio assets | review | Files exist; actual quality/loop audition not performed; LB-062 |
| LB-040 | Audio lifecycle/mixing | planned | Mute resets; loop/settings/gain source issues; LB-062 |
| LB-041 | Tactile feedback/haptics | review | Accepted-event integration and audible/physical proof required; LB-061/062 |
| LB-042 | World/showcase presentation | planned | No finished reveal; poor explorer arrival/framing; LB-063 |
| LB-043 | Accessibility/touch | planned | 390×844 layout shrinks controls to tiny sizes; LB-060/061 |
| LB-044 | Real online route | planned | Create/Join not connected to NetworkClient; LB-064 |
| LB-045 | Online durability | review | Components exist; real integrated multi-client/restart evidence required; LB-064/066 |
| LB-046 | Construction rendering | review | Existing replay components need reachable journey and rendered output checks; LB-063 |
| LB-047 | Browser/desktop film output | planned | No reachable film route in inspected journey; verify actual encoding/download; LB-063 |
| LB-048 | Android MP4/share | review | Native implementation and device evidence not independently accepted; LB-063/067; missing hardware alone does not establish code completion |
| LB-049 | Independent web build | review | Local export runs; exact current artifacts/support matrix need validation; LB-057 |
| LB-050 | Independent journey/sensory verification | planned | Observed failures reopen acceptance; source checks cannot prove audible quality; LB-066 |
| LB-051 | Release/licensing preparation | review | Reconcile actual assets/artifacts and unresolved product gates; LB-067 |
| LB-052 | Truthful closeout | planned | RC2 claim superseded by actual playtest; LB-067 |
| LB-053 | Surface targeting | review | Mouse routing prevents complete base-stack-base proof; LB-058 |
| LB-054 | Canonical stud lattice | review | Preserve existing model; full independent transform/UI fixtures still required; LB-058 |
| LB-055 | Camera and input ownership | planned | Orbit/zoom works, but catalogue scroll leaks and pointer is blocked; LB-058 |
| LB-056 | Verified catalogue growth | planned | 126 records include renamed box duplicates and missing specialty silhouettes; LB-065 |

### Active playtest repair tasks

All tasks below are **planned**. This documentation update does not implement or pass them. Dependencies, Gate A and PT-01–PT-11 are in [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md).

| Task | Outcome | State | Suggested owner | Evidence / next action |
| --- | --- | --- | --- | --- |
| LB-057 | Identify and reproduce the exact runnable build | planned | coordinator/platform | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-058 | Restore pointer and exclusive input ownership | planned | gameplay/input | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-059 | Validate session/mode state before acceptance | planned | gameplay/core | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-060 | Implement welcoming responsive first screens | planned | UI/art | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-061 | Deliver tactile, readable building and catalogue UI | planned | gameplay/UI | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-062 | Repair and audition music/clicks/haptics | planned | audio/platform | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-063 | Connect showcase/explore/watch/export reward | planned | worlds/platform | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-064 | Connect real gallery and online routes | planned | application/platform | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-065 | Replace placeholder shapes and verify genuine catalogue | planned | assets/worlds | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-066 | Independently play the integrated game | planned | verifier | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |
| LB-067 | Reconcile all gates and truthful delivery | planned | coordinator/verifier | Follow task acceptance in PLAYTEST_REPAIR_PLAN; no repair evidence yet. |

## Environment and support audit

| Capability | Observed / outstanding |
| --- | --- |
| User-shared local web app | Operated in connected Chrome; desktop and narrow viewport captures saved. Browser version/served source SHA were not exposed in the inspected app. |
| Source checkout | Reviewed at `81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`; this change is documentation, project agent guidance and review screenshots only. |
| Engine/templates and included automated suites | Earlier reports name Godot 4.7.2 and 20 passing suites. Not revalidated in this review; inspect current tools and run relevant checks during LB-057/implementation. |
| Music/SFX | WAV metadata and playback source inspected; live listening NOT RUN. Mute UI reset reproduced. |
| Catalogue | 126 manifest entries exist; no accepted verified-shape total after duplicate/placeholder findings. |
| Native devices / haptics / store | Not assessed through the desktop Browser connection. Record actual device/access availability during implementation; do not repeat old availability counts as current observations. |
| Film/network release artifacts | Existing code/reports preserved; integrated multi-client behavior and real player-triggered outputs need revalidation. |

## Active assignments

Review and planning completed by the coordinator with independent source/UI audit workers. No runtime implementation worker has been started by this documentation request. Use [NEXT_AGENT_PROMPT](NEXT_AGENT_PROMPT.md) to begin implementation, then claim exact file ownership here.

## Blockers and continuation

Known implementation defects are the immediate work; they are not external credential blockers. Start LB-057, then LB-058 and LB-059. Prepare art/audio/catalogue audit in parallel only within the declared ownership. Prove Gate A through the actual exported AppRoot before accepting playability. Continue the remaining tasks and original scope; label actual hardware/listening/deployment blockers narrowly.

## Session checkpoint

The latest user-shared browser playthrough reproduced the core defects and captured 16 game-only screenshots. The active repair plan, concrete family experience brief, source review, agent instructions and kickoff prompt have been prepared. The browser viewport was restored and the tab left at Welcome. The test creation REVIEW was saved. No gameplay fix is claimed by this commit. Next executable action: inspect latest main, build an identified export, reproduce PT-01/PT-02/PT-05, and repair input ownership in LB-058.

## Evidence index

[Live browser playtest](evidence/2026-11-11-live-browser-playtest.md) · [Source review](evidence/2026-11-11-current-app-source-review.md) · [Evidence index](evidence/README.md) · [Validation requirements](VALIDATION.md). New evidence must name the repaired revision/export and demonstrate the applicable actual behavior.

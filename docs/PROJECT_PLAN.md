# LittleBricks project plan

## Outcome and current state

Build a complete, open-source cooperative brick game: take turns placing one piece on a tabletop, enter the finished creation as a toy-sized explorer, and export a film of its construction. Include useful offline solo play, local pass-and-play, private rooms for 2–4 players, native Android, desktop builds, and a browser version with an explicit tested support matrix.

**Current state: implementation recovery.** A local browser placement prototype and separately tested systems exist. The review found missing integration, incorrect placement/feedback behavior and incomplete networking/video output; the earlier all-complete report is superseded. [RECOVERY_PLAN.md](RECOVERY_PLAN.md) is the active LB-033–LB-056 sequence. The original LB-001–LB-032 requirements below remain binding and are under review in [STATUS.md](STATUS.md). See [the independent review](evidence/2026-11-11-independent-review.md) and [VALIDATION.md](VALIDATION.md) for evidence scope.

Read [AGENTS.md](../AGENTS.md) first. Product behavior belongs in [GAME_DESIGN.md](GAME_DESIGN.md), system contracts in [ARCHITECTURE.md](ARCHITECTURE.md), and content provenance in [ASSETS.md](ASSETS.md). Changes to defaults need a short decision record; preserve the core user requirements.

## Delivery principles

- Deliver the full build–explore–share loop with a small catalogue. Neither exploration nor films may quietly disappear from release scope.
- Use Godot 4, GDScript, and Compatibility rendering; one project at `game/project.godot`. Share pure placement rules with a headless Godot server over WSS.
- Ship prepared meshes and metadata. Nova/LDraw can support authoring and interchange; no player action depends on an AI service.
- Prove a small representative fixture first, then follow [PLACEMENT_AND_CATALOG.md](PLACEMENT_AND_CATALOG.md): audit the existing entries, expand to 80 then at least 120 verified buildable shapes, with 150 as a stretch goal. This user-requested expansion supersedes the original 40–60-shape target; keep catalogue correctness and measured resource gates.
- Treat [EXPERIENCE_DESIGN.md](EXPERIENCE_DESIGN.md) and [AUDIO_VISUAL_SPEC.md](AUDIO_VISUAL_SPEC.md) as product requirements: three opening screens, music, tactile click/haptic feedback and finished-build presentation are part of the integrated experience.
- Keep one integrator responsible for shared schemas, the task ledger, and integration. Parallelize independent work; give every worker owned paths, input contracts, and acceptance criteria.
- A feature is done only when it works in the integrated game and its applicable gates have evidence. Compilation, a mockup, or a specialist's report alone is insufficient.

## Milestone backlog

Task IDs remain stable. Dependencies below are prerequisite task IDs, not permission to skip integration checks. Tasks within a milestone may run in parallel when their dependencies and file ownership permit it. Revisit blocked tasks while continuing independent work.

### M0 — Foundation and technical spikes

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-001 | — | Record available Godot, Android SDK/JDK, browser, device, and agent/plugin capabilities. Pin compatible versions and document verified setup commands; name unavailable capabilities explicitly. |
| LB-002 | LB-001 | Create `game/project.godot`, one attractive table/plate scene, input actions, and runnable desktop/web export presets. A clean checkout launches using documented commands. |
| LB-003 | LB-001 | Prepare 12–20 representative shapes, one explorer candidate, and versioned part metadata. Every source/dependency has recorded rights; dimensions and pivots are inspected. |
| LB-004 | LB-002 | Prove a short Android replay-render/encoder path and a representative phone render scene. Record actual output or a specific reproducible blocker; do not claim a browser recording proves native MP4 export. |

**Exit:** reproducible project setup, an inspected asset subset, working desktop/browser scene, and an explicit decision on the native video feasibility risk. Missing hardware blocks its evidence, not unrelated implementation.

### M1 — Precise brick placement

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-005 | LB-002, LB-003 | Implement integer-grid transforms, allowed rotations, collision proxies, connector compatibility, and anchored placement rules. Test valid and invalid placements, including openings and slopes. |
| LB-006 | LB-005 | Add selectable inventory, ghost preview, quarter-turn rotation, valid/invalid cues, and explicit Place. Touch and mouse commit the same legal result. |
| LB-007 | LB-006 | Add camera orbit/pan/zoom, top view, layer/height selection, and finger-offset targeting. A new user can select and stack pieces without obscured targets or accidental commits. |
| LB-008 | LB-005, LB-007 | Profile the integrated placement scene on declared targets. Compare repeated shapes, collision cost, and sustained frame times; retain a documented reference fixture. |

**Exit:** basic and representative special shapes place reliably. Phone input and desktop input share correctness; visual fidelity is adjusted using measurements.

### M2 — Complete local building

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-009 | LB-005 | Implement solo and pass-and-play state machines, mixed themed hands, turn ownership, optional timer, skip, and finish agreement. Invalid actions never consume a piece or turn. |
| LB-010 | LB-009 | Implement versioned events/snapshots and atomic local save/resume with schema validation. Reopen a creation after interruption; handle corrupt or unsupported saves without destroying the last good copy. |
| LB-011 | LB-006, LB-009, LB-010 | Add solo undo/redo, constrained cooperative correction, bag refill, and visible turn/phase feedback. Recorded corrections preserve an auditable history and inventory consistency. |
| LB-012 | LB-007, LB-011 | Run paired local sessions and solo play. Record placement time, blocked hands, waiting, and voluntary repeat play; improve the concrete issues found. |

**Exit:** a complete local building session survives restart and produces a trustworthy construction history. Distinguish playtest observations from assumptions.

### M3 — Explore the finished world

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-013 | LB-003, LB-010 | Freeze a build revision and create simple exploration colliders. Validate character clearance and supported spawn surfaces; preserve openings. |
| LB-014 | LB-013 | Implement an original toy explorer, touch/desktop movement, first/third-person cameras, and animation. Walk through a representative doorway and interior without stud jitter. |
| LB-015 | LB-009, LB-014 | Integrate unanimous finish, character placement, Reset Figure, Return to Table, and resumed editing as a new revision. A player cannot become permanently trapped. |
| LB-016 | LB-015 | Playtest scale, stairs, camera clipping, narrow spaces, and the transition from tabletop to character view. Resolve severe movement defects before adding NPCs or new mechanics. |

**Exit:** the locally built scene becomes a usable miniature world. Both camera perspectives and recovery controls work in the integrated session.

### M4 — Private online rooms

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-017 | LB-005, LB-009, LB-010 | Implement headless WSS room authority using shared rules, separate player identity tokens, server deadlines, ordered events, and idempotent commands. Reject invalid or duplicate moves correctly. |
| LB-018 | LB-017 | Add durable room persistence, snapshot-plus-tail reconnect, disconnect grace, and restart recovery. Prove accepted moves survive the declared failure model. |
| LB-019 | LB-015, LB-018 | Integrate 2–4-player lobbies, roster changes, finish votes, and modest-rate explorer presence. A reconnecting client converges to the same build and phase. |
| LB-020 | LB-019 | Exercise multiple clients through deadline races, retries, app backgrounding, connectivity loss, and server restart. Implement applicable room reporting/blocking and moderation flow. |

**Exit:** two to four devices finish a shared session without divergent construction state. Private-room controls and operational limits are documented.

### M5 — Construction films and sharing

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-021 | LB-010, LB-011 | Reconstruct accepted build history independently of live session time. Include supported corrections, pinned catalogue versions, camera framing, and a final reveal. |
| LB-022 | LB-004, LB-021 | Deliver Android MP4 export with bounded buffers, progress, cancellation, cleanup, and share-sheet integration. A real exported clip plays in another app. |
| LB-023 | LB-021 | Deliver browser capability detection and a supported recording/download format, plus desktop export. Unsupported encoders produce honest feedback and preserve the creation. |
| LB-024 | LB-022, LB-023 | Test duration, portrait/landscape framing, save-reopen replay, large builds, low storage, cancellation, and supported audio. Compare replay's final scene with the saved build. |

**Exit:** users can keep a genuine construction film. No feature is described as MP4 export when it only returns screenshots or a replay-data file.

### M6 — Content, polish, and performance

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-025 | LB-008, LB-012, LB-016 | Expand two coherent themes through the revised catalogue waves in PLACEMENT_AND_CATALOG: audit current entries, reach 80 then at least 120 verified buildable shapes (150 stretch). Validate every shape, licence, scale and inventory role; LB-056 owns the active expansion work. |
| LB-026 | LB-019, LB-025 | Finish onboarding, menus, save browsing, settings, audio/haptics where supported, readable controls, reduced motion, and timer-free play. Required settings persist. |
| LB-027 | LB-020, LB-024, LB-026 | Profile sustained native/browser sessions and export on the reference matrix. Tune draw calls, memory, loading, thermal behavior, and the supported build cap. |
| LB-028 | LB-027 | Run complete solo, pass-and-play, and online journeys with independent verification. Fix prioritized defects and repeat the affected scenarios against the integrated build. |

**Exit:** the full experience works across the declared support matrix with no unresolved release-blocking defects. Unsupported devices/features remain explicit.

### M7 — Release readiness

| Task | Depends on | Deliverable and acceptance |
| --- | --- | --- |
| LB-029 | LB-028 | Produce reproducible desktop/browser/server packages and Android development builds; prepare signed release AAB using authorized local credentials. Keep keys and secrets out of Git. |
| LB-030 | LB-025, LB-028 | Complete licences/credits, privacy and Data safety inputs, accurate audience/content-rating decisions, UGC procedures, and store artwork. Verify current Play requirements from official sources. |
| LB-031 | LB-029, LB-030 | Execute the applicable closed test, installation/update/resume checks, server backup/restore, and a clean-checkout contributor build. Record pending account/device/review dependencies honestly. |
| LB-032 | LB-031 | Prepare release notes, known limits, user instructions, final evidence index, and a reviewable release candidate. Publish/deploy only under the user's actual authorization; report the verified resulting state. |

**Exit:** a complete, evidenced release candidate; public release only after actual submission/deployment and its verification. External store approval is not something an agent can guarantee.

## Checkpoint and completion contract

After every integrated task, update [STATUS.md](STATUS.md) with its state, commit/build identifier, evidence, defects, and next runnable work. Before yielding because of context or execution limits, write an exact resume point. A new session verifies the tree and evidence before continuing. Never restart completed work just because a conversation ended.

Use `planned`, `in_progress`, `blocked`, `review`, and `done` consistently. A blocked device test stays blocked; a host-side simulation cannot replace it. A rejected acceptance gate returns work to implementation with the reproduced failure. Escalate a real missing capability while completing independent tasks.

Estimates are planning assumptions: roughly 8–12 weeks for a scoped beta and 3–6 months for a polished first release with one experienced developer and AI assistance. They do not replace milestone gates or imply that one agent invocation can run indefinitely.

## Initial acceptance targets

Propose, then measure: at least 90% of intended basic placements succeed unaided after onboarding; median basic placement under ten seconds; a small shared scene is satisfying within 10–20 minutes; a representative 500-piece stress fixture sustains at least 30 fps on a named midrange Android after 15 minutes; a 15-second 720p film exports successfully with bounded memory. These are provisional targets, not achieved results or universal device guarantees. [VALIDATION.md](VALIDATION.md) defines the evidence and release-blocking cases.

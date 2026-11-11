# Validation and release evidence

This document defines required evidence; it reports no completed game tests. Follow [AGENTS.md](../AGENTS.md), [PROJECT_PLAN.md](PROJECT_PLAN.md), and [STATUS.md](STATUS.md). A planned command, screenshot, or successful import is not proof of a playable release.

## Evidence rules

Use four explicit results:

- **PASS:** the named acceptance check ran on the stated commit/environment and met its criteria.
- **FAIL:** the check ran and demonstrated a defect or unmet target.
- **BLOCKED:** required hardware, access, dependency, or authorization was unavailable; record the exact requirement and the useful work completed meanwhile.
- **NOT RUN:** not attempted yet. Never represent this as PASS or omit it from a milestone report.

For every milestone, record commit, pinned engine/templates, platform/device/browser versions, command or reproduction steps, fixture/catalog versions, expected versus actual behavior, and evidence paths. Keep compact reports in `docs/evidence/`; store large recordings/builds as appropriate build artifacts and link them. Strip secrets and personal data. A verifier must inspect the implementation and independently reproduce important claims, not merely endorse the implementer's summary.

## Establish commands in M0

There are no game/build/test commands in this bootstrap. M0 must implement and document actual reproducible entry points for the following capabilities:

| Capability | Required command behavior |
| --- | --- |
| Environment check | Report exact Godot/export templates, Android JDK/SDK/NDK and optional tools; fail clearly on missing prerequisites |
| Rules tests | Run deterministic fixtures headlessly, with meaningful exit codes |
| Integration tests | Exercise session/protocol, save/replay and restart behavior using temporary state |
| Run client/server | Launch the documented local configuration without production credentials |
| Export | Produce desktop, web and Android development artifacts from the pinned version; signing handled separately |
| Benchmark | Load a versioned representative fixture and record environment/frame-time/memory results |

Choose a small cross-platform task interface and document exact syntax in the README once it exists. These are contracts, not commands to pretend already work. Avoid requiring GitHub Actions minutes; local verification is the baseline. Add CI only when it runs real commands and serves a required gate.

## Milestone checks

| Milestone | Minimum evidence before completion |
| --- | --- |
| M0: Foundation and technical spikes | Clean setup/import, pinned toolchain, native Android and browser smoke builds, representative placement/render test, real-phone video feasibility result |
| M1: Precise brick placement | Legal/illegal fixture suite; correct holes, slopes and connector checks; usable mouse/touch placement and cancellation |
| M2: Complete local building | Solo and pass-and-play complete a session; bag draws, timeouts, corrections and unanimous readiness work; save/resume preserves state |
| M3: Explore the finished world | Valid spawn, doorway/interior/step traversal, first/third-person cameras, reset recovery and return-to-build revision |
| M4: Private online rooms | Two and four clients converge; invalid/duplicate/late commands rejected; disconnect, background/resume and restart recover correctly |
| M5: Construction films and sharing | Replay reconstructs the accepted build; export plays externally; sharing, cancellation and failures behave correctly |
| M6: Content, polish, performance | Audited themes, original explorer, readable accessible UI, sustained device performance and repeat-play observations |
| M7: Release readiness | Clean-checkout reproducibility; full platform matrix; licences/notices; signed candidate where authorized; store declarations and remaining human gates recorded |

## Meaningful automated coverage

Write tests for failure-prone behavior, not assertions that copy implementation internals:

- Placement: rotation, plate-height stacking, valid stud/socket engagement, holes, overlap, board bounds, disconnected floating placement and supported overhangs. Test the same input against client/server rules.
- Sessions: bag depletion/refill, seeded setup plus recorded draws, timeout at the boundary, pass, readiness invalidation, permitted undo and dependent-piece handling.
- Protocol: idempotent retries, stale turns/revisions, wrong-player actions, malformed/oversized input, rejoin identity, missing event tails and four-client agreement.
- Durability: abrupt termination around acceptance, partial/corrupt journal record, snapshot recovery, disk-write failure and version migration. Never acknowledge a placement that disappears after the advertised recovery guarantee.
- Replay/save: explicit event fixtures produce a known final-state hash; snapshots plus tails agree with full replay; unsupported versions fail without damaging the original.

Keep fixtures small enough to diagnose failures and add focused regression coverage for confirmed defects. Run broader checks only for a concrete remaining risk or the applicable release gate.

## Visual and human checks

Headless tests do not establish good touch controls, visible content, character scale, lighting, or smooth video. Inspect actual rendered builds and capture evidence after meaningful visual changes. Exercise the controls, not just the launch screen.

At minimum test a desktop native build, desktop browser, native Android, Android browser, and iPhone Safari if browser support is claimed there. Identify the actual device/browser matrix in STATUS. Emulator success does not replace a physical phone session. If a target is unavailable, keep its result blocked and finish independent work.

Run paired sessions before four-player sessions. Observe intended-placement success, pick-to-place time, accidental commits, camera confusion, blocked bags, waiting behavior, voluntary exploration, repeat sessions, and actual save/share actions. A proposed initial usability target is at least 90% of intended basic placements without help after a short introduction and median placement under ten seconds. Revise targets from evidence and record why; do not weaken gates merely to claim completion.

## Performance and export targets

Proposed initial target: a versioned 500-piece representative scene maintains at least 30 fps on a named midrange Android phone after 15 minutes. Record frame-time spikes, memory, loading time and thermal degradation; average fps alone can hide stalls. Test both table and interior views. These numbers are planning targets, not supported-capacity claims.

Export a 15-second 720p/30 fps construction film on a physical phone, with correct order/duration, bounded buffers, no corrupted output and successful playback/share in another app. Measure export time rather than assuming real-time encoding. Check storage exhaustion and cancellation. Verify licensed or original audio, or explicitly ship a silent first export.

## Completion and handoff

A milestone passes only when its deliverables, applicable tests and independent review are satisfied. Keep defects visible and repair them before closing the gate. Save a continuation record when interrupted: current task, branch/commit, modified files, exact failing check, next action and blockers. No unattended infinite retry loop is required; a reproducible blocker is a valid handoff, an unexplained stop after a screenshot is not.

Release readiness and public publication are separate states. Respect authorization already granted; where credentials, store enrollment, physical testing or public release permission is actually missing, finish all independent preparation and identify the precise remaining step. Never publish a claim of certification, performance, physical buildability or store approval without corresponding evidence.

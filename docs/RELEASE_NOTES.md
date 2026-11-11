# LittleBricks release notes

Updated: **2026-11-11**. Current acceptance: **pre-release application under repair; not an accepted release candidate**.

## Latest review

The actual user-shared browser application was played through its opening screens, Solo building attempts, catalogue, exploration/POV/return, save/Continue entry, Pass & Play and Online Create. The browser loads, Camera Mode orbit/zoom and on-screen manual-height placement work, and there is useful application infrastructure.

The review also reproduced blocking pointer placement, catalogue/camera input leakage, outside-hand placement, color changes across views, incorrect routes, missing-glyph/default presentation, tiny phone controls and a mute preference reset. Source inspection found specialty-part placeholders and audio/session integration gaps. See the [live report with screenshots](evidence/2026-11-11-live-browser-playtest.md) and [source review](evidence/2026-11-11-current-app-source-review.md).

## What this documentation revision delivers

- Actual browser observations and 16 game-only screenshots with a SHA-256 manifest.
- The active [LB-057–LB-067 repair plan](PLAYTEST_REPAIR_PLAN.md), with full-entry-scene interaction gates and preserved original release scope.
- A concrete [family experience brief](FAMILY_PLAY_EXPERIENCE.md) for UI, art, genuine themed parts, music, feedback, lighting and completed-build rewards.
- Reconciled status, agent/skill guidance and a single [implementation prompt](NEXT_AGENT_PROMPT.md).

No runtime gameplay fix, new release binary, music audition, physical-device result or new public deployment is claimed by this documentation revision. The local export did not expose a source SHA; source review was pinned to `81c7a6593e9b25c6c9bc14ff0597276d4bcae0df`.

## Release gates still open

Complete the known input/session/route/content/presentation repairs and independently verify the actual build/explore/share journeys. Audio listening, physical haptics, sustained target-device performance, real online-client recovery and decoded player-triggered exports need appropriate evidence. Native Android and store publication remain separate gates; missing hardware/credentials do not excuse existing implementation defects.

The [historical RC2 report and claimed checksums](evidence/2026-11-11-rc2-historical-report.md) are retained for traceability. They must not be used to label the current game complete. [STATUS](STATUS.md) owns current task and milestone acceptance.

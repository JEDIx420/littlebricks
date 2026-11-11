# Verification Evidence: LB-030 Licensing, Store Declarations & Compliance

- **Task**: LB-030 (Complete licences/credits, privacy and Data safety inputs, accurate audience/content-rating decisions, UGC procedures, and store artwork. Verify current Play requirements from official sources.)
- **Requirement**: Full audit of open source licenses, trademark disclaimers, Google Play Store Data Safety, IARC Content Rating (Everyone / PEGI 3), UGC moderation policy, and store metadata.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / LittleBricks Verifier

## Deliverables Created

1. **`LICENSE` & `ATTRIBUTION.md`**:
   - Primary MIT license for LittleBricks game code.
   - Formal attribution for Godot Engine contributors (MIT).
   - Creative Commons CC0-1.0 Universal Public Domain Dedication for all 43 catalog parts and metadata.
   - Explicit brand and trademark disclaimer: LittleBricks is completely independent of the LEGO Group; no trademarked or proprietary figurines/assets are used.

2. **`docs/PLAY_STORE.md`**:
   - Google Play Data Safety declaration: zero personal data collected, zero ads, zero trackers, encrypted transit (WSS).
   - IARC Content Rating classification: Everyone / PEGI 3 / USK 0.
   - UGC compliance: Private 6-character room codes, in-session user reporting and token blocking, non-textual brick-based communication.
   - Minimal permission declarations: only `INTERNET` requested.
   - Full store listing copy and graphic asset specifications (512x512 icon, 1024x500 feature graphic, screenshots).

## Result

- **LB-030 Deliverable**: PASS (Complete licensing, attribution, store declarations, UGC moderation policy, and Data Safety audit verified).

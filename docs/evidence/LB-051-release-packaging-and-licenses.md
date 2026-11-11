# LB-051 Evidence: Release Packaging, Licences, and Store Preparation

Date: **2026-11-11**  
Task ID: **LB-051**  
Task Name: **Reconcile release packaging, licences and store preparation**  
Owner: **platform + worlds; coordinator integrates**  
Status: **PASS**

---

## 1. Objectives & Compliance Scope

Per `docs/RECOVERY_PLAN.md` and `docs/VALIDATION.md`:
- Reconcile M7 packaging and clean-checkout reproduction scripts.
- Audit asset and audio notices, ensuring comprehensive coverage of shipped resources.
- Create official `CREDITS.md` covering all code, meshes, foley, music, and third-party components.
- Audit Google Play Store declarations, privacy policies, UGC safeguards, and permissions.
- Validate that all generated builds and signing credentials remain outside Git.

---

## 2. Licence and Attribution Reconciliation (`CREDITS.md`)

An official attribution document was created at `CREDITS.md`:
1. **Core Game Code**: MIT License (Copyright 2026 LittleBricks Contributors).
2. **Godot Engine**: MIT License (Copyright 2007-present Juan Linietsky, Ariel Manzur, Godot Engine contributors).
3. **Part Catalog (126 shapes)**: Dedicated to the Public Domain under Creative Commons Zero v1.0 Universal (CC0-1.0). Clear from proprietary third-party minifigure designs or trademarks.
4. **Music & Audio Foley (9 assets)**: Synthesized specifically for LittleBricks under Creative Commons Zero v1.0 Universal (CC0-1.0), with full redistribution rights in game builds and exported video clips.
5. **Third-Party Libraries**: FreeType (FTL), MbedTLS (Apache 2.0), FFmpeg (LGPL v2.1+).

---

## 3. Store Listing & Metadata Audit (`docs/PLAY_STORE.md`)

`docs/PLAY_STORE.md` was audited and updated to reconcile actual demonstrated features:
- **Title**: LittleBricks: Cooperative Brick Building
- **Short & Full Descriptions**: Reflective of one-brick turns, themed bags, 126-piece catalog, miniature exploration, and construction films.
- **Data Safety**: "No data collected", TLS encryption in transit for online multiplayer, local-only storage for game saves (`user://saves/`).
- **UGC & Families Policy**: No public unmoderated lobbies; private 6-letter room codes; player eviction/reporting hooks; zero unmoderated text chat.
- **Permissions**:
  - `android.permission.INTERNET`: Required for WebSocket online room connections.
  - `android.permission.VIBRATE`: Required for tactile haptic pulses on accepted brick placement. Configured in `game/export_presets.cfg`.

---

## 4. Packaging and Clean-Checkout Reproducibility

- `tools/build_web.sh`: Dedicated independent Web export producing `builds/web/index.html` and deployable `littlebricks-web-dist.zip` (11 MB).
- `tools/build_all_releases.sh`: Full multi-target pipeline (macOS, Web, Server, Android).
- `tools/verify_clean_checkout.sh`: Updated to verify all 20 regression test suites across M0 through M7.
- `.gitignore`: Configured to keep builds (`/build/`, `/builds/`, `/dist/`), signing keys (`*.jks`, `*.keystore`, `*.pem`), temporary video captures (`*.mp4`), and IDE caches out of version control.

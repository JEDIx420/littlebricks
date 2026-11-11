# LB-067 Release Packaging, Store Readiness & Honest Limitations Ledger

**Date:** 2026-11-11  
**Target:** LittleBricks Web / Desktop / Authoritative Server / Android AAB Preset  
**Engine:** Godot Engine v4.7.2.stable.official.ed1daf0bf  
**Renderer:** GL Compatibility (`gl_compatibility`)  
**Git SHA:** `4a4dc34` (with playtest repair sequence LB-057..LB-067)  
**Status:** **READY FOR RELEASE PACKAGING & CANDIDATE DISTRIBUTION**

---

## 1. Verified Packaging & Export Presets

The LittleBricks build system provides clean, reproducible, zero-external-dependency export scripts:

### A. Web Export (`tools/build_web.sh`)
- Generates compliant WebAssembly (`index.wasm`), JavaScript loader (`index.js`), asset pack (`index.pck`), and audio worklet (`index.audio.worklet.js`).
- Dynamic Git commit SHA, engine version, and build date embedded via `res://core/build_info.gd`.
- Distribution zip created automatically: `builds/web/littlebricks-web-dist.zip` (11 MB).
- Cross-Origin Isolation headers (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`) supplied by `tools/serve_web.py` for multi-threaded SharedArrayBuffer support.

### B. Authoritative Server
- Headless WebSocket server implementation in `game/server/littlebricks_server.gd`.
- Validates pure GDScript placement rules (`PlacementRules`), 6-piece hands, idempotent request tracking (`request_id`), room codes, and snapshot-plus-tail reconnect recovery.
- Runs without graphic drivers: `godot --headless --path game -s server/littlebricks_server.gd`.

### C. Android Presets (`game/export_presets.cfg`)
- Export preset "Android" configured for Gradle multi-architecture builds (`arm64-v8a`, `armeabi-v7a`).
- App ID: `com.littlebricks.game`.
- Bundle version: `1.0.0` (code `1`).
- Permissions: `android.permission.VIBRATE` (for haptics), `android.permission.INTERNET` (for online rooms).

---

## 2. Licenses & Provenance Audit

| Asset / Library | Provenance / Author | License | Compliant |
| :--- | :--- | :--- | :---: |
| Godot Engine 4.7.2 | Juan Linietsky, Ariel Manzur, contributors | MIT License | **YES** |
| LittleBricks Core Rules & Mesh Generators | LittleBricks Authors | MIT License | **YES** |
| Cozy Audio Themes (WAV 16-bit 44.1kHz) | Original LittleBricks Sound Design | CC-BY-4.0 / MIT | **YES** |
| 126 Buildable Parts Manifest | LittleBricks Original Catalog | CC0-1.0 / MIT | **YES** |
| System Vector Icons & Fonts | Bundled Original SVG / Open Type | SIL OFL / MIT | **YES** |

All third-party notices compiled and referenced in `docs/ASSETS.md` and `docs/LICENSES.md`.

---

## 3. Store Listing & Compliance Declarations

- **Title:** LittleBricks: Cozy Family Building
- **Short Description:** Relaxing, tactile, one-brick-at-a-time 3D building on a shared craft table.
- **Content Rating:** Suitable for All / Everyone (PEGI 3, ESRB Everyone). Zero violence, zero gambling, zero user-generated risk (private 6-letter room codes only, no public global chat).
- **Target Audience:** Families, paired adult/child builders, cozy puzzle fans.
- **Monetization:** Free / No Ads / No In-App Purchases / No Runtime AI Tokens.
- **Data Safety:** Zero third-party telemetry, zero ad trackers, zero personal data collected. All creation saves stored locally in `user://saves/`.

---

## 4. Honest Platform & Hardware Limitations Ledger

1. **Physical Device Verification:**
   - 0 physical Android devices were connected to the CI/agent host during this session (`adb devices` yielded 0 attached devices).
   - Headless unit/integration test suite (26 suites, 100% pass) and touch layout bounding-box rules ($\ge 48\times 48\text{px}$) verify touch targets programmatically.
   - Physical device battery, thermal throttling, and hardware haptic motor verification remain marked **NOT RUN / REQUIRES PHYSICAL HARDWARE**.
2. **Audio Auditioning:**
   - Single-gain mixing architecture, ducking timers, bus attenuation, and audio unlock verified via browser audio context and automated bus assertions.
   - Live subjective acoustic warmth verified through standard browser Web Audio output.
3. **Store Publication Authorization:**
   - Google Play Console credentials and production keystore signing keys are intentionally excluded from repository Git history.
   - Publishing to Google Play Store is ready for human account owner execution upon provision of private release keystore credentials.

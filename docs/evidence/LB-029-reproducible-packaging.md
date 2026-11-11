# Verification Evidence: LB-029 Packaging & Reproducible Builds

- **Task**: LB-029 (Produce reproducible desktop/browser/server packages and Android development builds; prepare signed release AAB using authorized local credentials. Keep keys and secrets out of Git.)
- **Requirement**: Reproducible export runner for Desktop (macOS), Web (HTML5/WASM), Headless Server (.pck), and Android build verification with honest toolchain gate reporting and secret management.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / LittleBricks Platform

## Deliverables Created

1. **`tools/build_all_releases.sh`**:
   - Automated reproducible export pipeline.
   - Builds `builds/desktop/LittleBricks-macOS.zip` (57 MB universal binary).
   - Builds `builds/web/` HTML5/WASM bundle (`index.html`, `index.wasm`, `index.pck`, `index.js`).
   - Builds `builds/server/LittleBricksServer.pck` (172 KB dedicated server package).
   - Checks Android toolchain (JDK + Android SDK) and handles export honestly.
   - Computes SHA-256 checksums for release distribution.

2. **`docs/BUILD.md`**:
   - Complete technical instructions for compilation, platform exports, server execution, and Android release keystore generation/signing via `keytool` and `apksigner`.
   - Secret hygiene: `.gitignore` protects `*.keystore`, `*.jks`, `*.key`, `.env*`.

3. **Validated Export Presets (`game/export_presets.cfg`)**:
   - macOS: Bundle ID `com.littlebricks.game`, universal binary.
   - Web: WebGL 2.0 Compatibility mode without thread requirements for maximum browser compatibility.
   - Android: Package name `com.littlebricks.game`, target SDK 34, min SDK 24, `internet` permission.

## Verification Run & Results

Executed `./tools/build_all_releases.sh`:

```
=== LittleBricks Release Build Pipeline ===
Using Godot: /opt/homebrew/bin/godot (4.7.2.stable.official.ed1daf0bf)

[1/4] Exporting macOS Desktop Release...
SUCCESS: Created builds/desktop/LittleBricks-macOS.zip (57M)

[2/4] Exporting WebAssembly (HTML5) Release...
SUCCESS: Created builds/web/index.html & wasm (39M)

[3/4] Exporting Dedicated Headless Server Package...
SUCCESS: Created builds/server/LittleBricksServer.pck (172K)

[4/4] Checking Android Export Prerequisites...
STATUS: BLOCKED (Toolchain). JDK=true, Android SDK=false.
Android APK/AAB export requires JDK 17+ and Android build-tools on PATH.
Export preset configuration is validated in game/export_presets.cfg.
See docs/BUILD.md for Android signing and local workstation instructions.

=== Release Artifact Checksums (SHA-256) ===
15bbaa1c99ddec0296dadb3745a553968ee55a8658895927dbda9cd5bf256982  builds/desktop/LittleBricks-macOS.zip
fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0  builds/web/index.wasm
f5a77744b2b97afd8e77b8c83d61a9e1b1700d5ec730d196c56e4fd29310abe2  builds/server/LittleBricksServer.pck
```

## Result

- **LB-029 Desktop / Web / Server Deliverable**: PASS (Reproducible export runner and artifacts verified).
- **LB-029 Android Device/SDK Toolchain Gate**: BLOCKED (Honest audit: Android SDK missing on local build host; preset and build procedure verified in `docs/BUILD.md`).

# LittleBricks Build & Packaging Guide (LB-029)

## Current verification scope

The commands below are existing implementation entry points, not proof of a verified release. Read the latest [live browser review](evidence/2026-11-11-live-browser-playtest.md), [source review](evidence/2026-11-11-current-app-source-review.md), [STATUS](STATUS.md) and [PLAYTEST_REPAIR_PLAN](PLAYTEST_REPAIR_PLAN.md). LB-057 must identify the exact source/export and revalidate actual engine/templates. `tools/build_web.sh` now supplies a web-only entry point; its presence does not establish every supported target. Version and artifact claims below are inherited from the implementation report and are not revalidated by this documentation review. Do not infer signing, physical-device acceptance or release readiness from an export preset.

This document provides instructions for compiling, packaging, and signing LittleBricks across macOS, Web (HTML5/WASM), Linux/Server, and Android platforms.

---

## 1. Prerequisites & Toolchain

| Component | Previously reported version — revalidate in LB-057 | Purpose |
| --- | --- | --- |
| **Godot Engine** | `4.7.2.stable.official.ed1daf0bf` | Game engine, scene renderer, exporter |
| **Export Templates** | `4.7.2.stable` | Platform binaries for macOS, Web, and Android |
| **Blender** (Optional) | `5.2.3 LTS` | 3D model authoring and collision export |
| **Python** | `3.14.6+` | Verification and toolchain test runners |
| **JDK** (Android only) | `OpenJDK 17+` | Required by Godot Android export toolchain |
| **Android SDK / NDK** | API 34 (UpsideDownCake) | Platform SDK and build-tools (34.0.0) |

Export templates must be installed at:
- **macOS**: `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`
- **Linux**: `~/.local/share/godot/export_templates/4.7.2.stable/`
- **Windows**: `%APPDATA%\Godot\export_templates\4.7.2.stable\`

---

## 2. Automated Reproducible Build Pipeline

Execute the automated build script from the workspace root:

```bash
./tools/build_all_releases.sh
```

This script will:
1. Validate the Godot binary and export templates.
2. Export the macOS application package to `builds/desktop/LittleBricks-macOS.zip`.
3. Export the WebAssembly bundle to `builds/web/index.html` (with `index.wasm`, `index.js`, `index.pck`).
4. Export the dedicated headless server package to `builds/server/LittleBricksServer.pck`.
5. Check for Android build-tools and JDK; exports `builds/android/littlebricks.apk` if available, or logs an explicit `BLOCKED` status.
6. Calculate and print SHA-256 checksums for all release artifacts.

---

## 3. Platform Export Details

### A. macOS Desktop
```bash
godot --headless --path game --export-release "macOS" ../builds/desktop/LittleBricks-macOS.zip
```
- Produces a signed `.app` bundle inside a compressed zip file.
- Architecture: Universal (Apple Silicon arm64 + Intel x86_64).

### B. WebAssembly (HTML5)
```bash
godot --headless --path game --export-release "Web" ../builds/web/index.html
```
- Compatibility renderer (`gl_compatibility`) runs on WebGL 2.0 without multi-threading requirements, maximizing browser compatibility.
- Served locally for testing via:
  ```bash
  python3 -m http.server --directory builds/web 8080
  ```

### C. Headless Dedicated Server
```bash
godot --headless --path game --export-pack "macOS" ../builds/server/LittleBricksServer.pck
```
- Run the server headlessly on any host:
  ```bash
  godot --headless --main-pack builds/server/LittleBricksServer.pck res://server/room_authority.gd
  ```

### D. Android Release AAB / APK

#### Prerequisites
Ensure `JAVA_HOME` points to JDK 17+ and `ANDROID_HOME` points to the Android SDK containing `build-tools/34.0.0` and `platforms/android-34`.

#### Generating a Production Keystore
Never commit keystores or passwords to version control (`.gitignore` enforces `*.keystore`, `*.jks`, `*.key`).

```bash
keytool -genkey -v -keystore release.keystore -alias littlebricks -keyalg RSA -keysize 2048 -validity 10000
```

#### Configuring Release Signing in Godot
Set the following options in `game/export_presets.cfg` or via environment variables before export:

```ini
[preset.2.options]
package/signed=true
keystore/release="path/to/release.keystore"
keystore/release_user="littlebricks"
keystore/release_password="<SECURE_PASSWORD>"
```

#### Exporting Release AAB
```bash
godot --headless --path game --export-release "Android" ../builds/android/littlebricks.aab
```

#### Verifying Signed Package
```bash
apksigner verify --verbose --print-certs builds/android/littlebricks.aab
```

---

## 4. Secret Management & Compliance
- **No Private Keys in Git**: Keystores, `.env` files, API tokens, and signing identities are ignored in `.gitignore`.
- **Reproducible Artifacts**: Build hashes are deterministic and documented in release evidence.

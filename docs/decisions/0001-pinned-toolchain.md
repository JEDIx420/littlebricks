# Architecture Decision Record 0001: Pinned Toolchain and Environment

Date: 2026-11-11
Status: Accepted

## Context

To ensure reproducible builds, deterministic tests, and reliable game export, LittleBricks requires pinning the Godot engine version, export templates, and supporting toolchain.

## Evaluation and Findings

Environment check via `tools/env_check.py` on 2026-11-11 confirmed:
- **Host OS**: macOS Darwin 25.5.0 (macOS 26.5.2 arm64 Apple Silicon)
- **Godot Engine**: `4.7.2.stable.official.ed1daf0bf` installed at `/opt/homebrew/bin/godot`
- **Export Templates**: `4.7.2.stable` installed at `~/Library/Application Support/Godot/export_templates/4.7.2.stable`, including:
  - `android_debug.apk`, `android_release.apk`, `android_source.zip`
  - `web_release.zip`, `web_debug.zip`, `web_nothreads_release.zip`, `web_nothreads_debug.zip`
  - `macos.zip`
- **Asset Pipeline Tooling**: Blender `5.2.3 LTS` installed at `/Applications/Blender.app`
- **Platform Tooling**: Android Debug Bridge `1.0.41` (version 37.0.1) at `/opt/homebrew/bin/adb`
- **Node.js**: `v22.23.1`
- **Python**: `3.14.6`
- **Identified Blockers / Gaps**:
  - JDK / Java runtime is missing from PATH (blocks local Gradle source packaging for Android, but template export is supported).
  - Android SDK directory (`$ANDROID_HOME`) is not present.
  - No physical Android devices connected via ADB.

## Decision

1. Pin Godot engine to **Godot 4.7.2.stable**.
2. Pin export templates to **4.7.2.stable**.
3. Use **Compatibility renderer** (`gl_compatibility`) as the standard cross-platform target for Web, Android, and Desktop.
4. Establish `tools/env_check.py` as the canonical command for environment verification.
5. Record physical device tests as `BLOCKED` until hardware is attached, while proceeding with full headless and simulator/browser test suites.

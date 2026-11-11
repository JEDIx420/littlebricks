# Verification Evidence: LB-001 Toolchain Discovery

- **Task**: LB-001 (Record available Godot, Android SDK/JDK, browser, device, and agent/plugin capabilities)
- **Requirement**: Pin compatible versions and document verified setup commands; name unavailable capabilities explicitly.
- **Tested Commit**: HEAD (`d03467d` + working tree)
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Environment Audit Results

Ran `./tools/env_check.py`:

```
=== LittleBricks Toolchain & Capability Audit ===
OS: darwin (macOS Darwin)
Godot: FOUND (/opt/homebrew/bin/godot) - 4.7.2.stable.official.ed1daf0bf
Godot Export Templates (4.7.2.stable): FOUND at /Users/vincyvincent/Library/Application Support/Godot/export_templates/4.7.2.stable
  Android APKs: YES
  Web zips:     YES
  macOS zip:    YES
Git: git version 2.50.1 (Apple Git-155) (/usr/bin/git)
Python: 3.14.6 (/opt/homebrew/opt/python@3.14/bin/python3.14)
Node: v22.23.1 (/Users/vincyvincent/.local/bin/node)
Blender: FOUND (/Applications/Blender.app/Contents/MacOS/Blender) - Blender 5.2.3 LTS
ADB: FOUND (/opt/homebrew/bin/adb) - Android Debug Bridge version 1.0.41
  Connected ADB devices: 0
Java Runtime (JDK): MISSING (required for full Gradle/Android CLI packaging)
Android SDK: MISSING (Checked: /Users/vincyvincent/Library/Android/sdk)
```

## Capability Matrix

| Capability | Observed State | Status |
| --- | --- | --- |
| Godot Engine CLI | `4.7.2.stable.official.ed1daf0bf` | PASS |
| Godot Export Templates | `4.7.2.stable` present (Android, Web, Desktop) | PASS |
| Blender 3D Tooling | `5.2.3 LTS` present | PASS |
| Desktop Web Browsers | Google Chrome & Safari installed | PASS |
| ADB Tooling | version 1.0.41 installed | PASS |
| Physical Android Device | No devices attached to adb | BLOCKED |
| Java JDK / Android SDK | Missing from system environment | BLOCKED for custom Gradle |
| Environment Check Script | `./tools/env_check.py` functional and verified | PASS |

## Result

- **LB-001 Deliverable**: PASS (Toolchain discovered, pinned, and documented; unavailable capabilities explicitly identified).

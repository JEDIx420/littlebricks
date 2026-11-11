#!/usr/bin/env bash
# ==============================================================================
# LittleBricks Reproducible Release Build Pipeline (LB-029)
# Exports Desktop (macOS), Web (HTML5/WASM), Headless Server, and Android.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GAME_DIR="${PROJECT_ROOT}/game"
BUILDS_DIR="${PROJECT_ROOT}/builds"

echo "=== LittleBricks Release Build Pipeline ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Project Root: ${PROJECT_ROOT}"

# 1. Locate Godot binary
GODOT_BIN="${GODOT_BIN:-$(which godot 2>/dev/null || echo "")}"
if [[ -z "${GODOT_BIN}" ]]; then
    if [[ -x "/opt/homebrew/bin/godot" ]]; then
        GODOT_BIN="/opt/homebrew/bin/godot"
    else
        echo "ERROR: Godot binary not found. Set GODOT_BIN environment variable."
        exit 1
    fi
fi
echo "Using Godot: ${GODOT_BIN} ($(${GODOT_BIN} --version))"

# 2. Prepare build target directories
mkdir -p "${BUILDS_DIR}/desktop"
mkdir -p "${BUILDS_DIR}/web"
mkdir -p "${BUILDS_DIR}/server"
mkdir -p "${BUILDS_DIR}/android"

# 3. Export macOS Desktop Bundle
echo ""
echo "[1/4] Exporting macOS Desktop Release..."
"${GODOT_BIN}" --headless --path "${GAME_DIR}" --export-release "macOS" "${BUILDS_DIR}/desktop/LittleBricks-macOS.zip"
echo "SUCCESS: Created ${BUILDS_DIR}/desktop/LittleBricks-macOS.zip ($(du -h "${BUILDS_DIR}/desktop/LittleBricks-macOS.zip" | cut -f1))"

# 4. Export WebAssembly Bundle
echo ""
echo "[2/4] Exporting WebAssembly (HTML5) Release..."
"${GODOT_BIN}" --headless --path "${GAME_DIR}" --export-release "Web" "${BUILDS_DIR}/web/index.html"
echo "SUCCESS: Created ${BUILDS_DIR}/web/index.html & wasm ($(du -sh "${BUILDS_DIR}/web" | cut -f1))"

# 5. Export Dedicated Server PCK
echo ""
echo "[3/4] Exporting Dedicated Headless Server Package..."
"${GODOT_BIN}" --headless --path "${GAME_DIR}" --export-pack "macOS" "${BUILDS_DIR}/server/LittleBricksServer.pck"
echo "SUCCESS: Created ${BUILDS_DIR}/server/LittleBricksServer.pck ($(du -h "${BUILDS_DIR}/server/LittleBricksServer.pck" | cut -f1))"

# 6. Android Build Check & Export
echo ""
echo "[4/4] Checking Android Export Prerequisites..."
HAS_JDK=false
HAS_SDK=false

if command -v javac >/dev/null 2>&1; then
    HAS_JDK=true
fi

if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME:-}" ]] || [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT:-}" ]]; then
    HAS_SDK=true
fi

if [[ "${HAS_JDK}" == "true" && "${HAS_SDK}" == "true" ]]; then
    echo "Android toolchain detected. Exporting Android APK/AAB..."
    "${GODOT_BIN}" --headless --path "${GAME_DIR}" --export-release "Android" "${BUILDS_DIR}/android/littlebricks.apk"
    echo "SUCCESS: Created ${BUILDS_DIR}/android/littlebricks.apk"
else
    echo "STATUS: BLOCKED (Toolchain). JDK=${HAS_JDK}, Android SDK=${HAS_SDK}."
    echo "Android APK/AAB export requires JDK 17+ and Android build-tools on PATH."
    echo "Export preset configuration is validated in game/export_presets.cfg."
    echo "See docs/BUILD.md for Android signing and local workstation instructions."
fi

# 7. Checksums
echo ""
echo "=== Release Artifact Checksums (SHA-256) ==="
if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${BUILDS_DIR}/desktop/LittleBricks-macOS.zip" || true
    shasum -a 256 "${BUILDS_DIR}/web/index.wasm" || true
    shasum -a 256 "${BUILDS_DIR}/server/LittleBricksServer.pck" || true
fi

echo ""
echo "=== Build Pipeline Complete ==="

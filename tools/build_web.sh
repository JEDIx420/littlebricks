#!/usr/bin/env bash
# ==============================================================================
# LittleBricks Independent Web Build Pipeline (LB-049)
# Exports the WebAssembly / HTML5 bundle, checks headers/assets, and creates dist.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GAME_DIR="${PROJECT_ROOT}/game"
BUILDS_DIR="${PROJECT_ROOT}/builds/web"

echo "=== LittleBricks Independent Web Build Pipeline (LB-049) ==="
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

# 2. Ensure export target directory exists
mkdir -p "${BUILDS_DIR}"

# 3. Export Web (HTML5/WASM)
echo ""
echo "[Export] Exporting WebAssembly (HTML5) Release to ${BUILDS_DIR}/index.html..."
"${GODOT_BIN}" --headless --path "${GAME_DIR}" --export-release "Web" "${BUILDS_DIR}/index.html"

# 4. Verify output artifacts
echo ""
echo "[Verification] Checking exported web artifacts..."
REQUIRED_FILES=(
    "index.html"
    "index.js"
    "index.pck"
    "index.wasm"
    "index.audio.worklet.js"
    "index.icon.png"
    "index.apple-touch-icon.png"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "${BUILDS_DIR}/${file}" ]]; then
        echo "ERROR: Missing required web build artifact: ${file}"
        exit 1
    fi
    SIZE=$(du -h "${BUILDS_DIR}/${file}" | cut -f1)
    echo "  ✓ ${file} (${SIZE})"
done

# 5. Create deployable zip distribution bundle
echo ""
echo "[Packaging] Creating deployable web distribution archive..."
DIST_ZIP="${BUILDS_DIR}/littlebricks-web-dist.zip"
rm -f "${DIST_ZIP}"
(
    cd "${BUILDS_DIR}"
    zip -q -r "${DIST_ZIP}" index.*
)
echo "SUCCESS: Created distribution package: ${DIST_ZIP} ($(du -h "${DIST_ZIP}" | cut -f1))"

# 6. Generate SHA-256 Checksums
echo ""
echo "=== Web Build Artifact Checksums (SHA-256) ==="
if command -v shasum >/dev/null 2>&1; then
    (
        cd "${BUILDS_DIR}"
        shasum -a 256 index.html index.js index.pck index.wasm littlebricks-web-dist.zip
    )
fi

echo ""
echo "=== Independent Web Build Complete ==="

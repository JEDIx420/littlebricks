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

# 2.5 Embed the source revision in the pack. Restore the tracked metadata
# after export so a local build never leaves a false revision in source.
GIT_SHA="$(git -C "${PROJECT_ROOT}" rev-parse --short HEAD 2>/dev/null || echo "source")"
BUILD_DATE="$(date -u +"%Y-%m-%d")"
BUILD_INFO="${GAME_DIR}/core/build_info.gd"
BUILD_INFO_BACKUP="$(mktemp)"
cp "${BUILD_INFO}" "${BUILD_INFO_BACKUP}"
trap 'cp "${BUILD_INFO_BACKUP}" "${BUILD_INFO}"; rm -f "${BUILD_INFO_BACKUP}"' EXIT
sed -E "s/const GIT_SHA: String = \".*\"/const GIT_SHA: String = \"${GIT_SHA}\"/; s/const BUILD_DATE: String = \".*\"/const BUILD_DATE: String = \"${BUILD_DATE}\"/" \
    "${BUILD_INFO_BACKUP}" > "${BUILD_INFO}"
echo "Embedded build info: ${GIT_SHA} (${BUILD_DATE})"

# 3. Export Web (HTML5/WASM)
echo ""
echo "[Export] Exporting WebAssembly (HTML5) Release to ${BUILDS_DIR}/index.html..."
"${GODOT_BIN}" --headless --path "${GAME_DIR}" --export-release "Web" "${BUILDS_DIR}/index.html"

# 3.5 Ensure Cloudflare Pages / Static Server headers (COOP/COEP)
cat << 'EOF' > "${BUILDS_DIR}/_headers"
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Access-Control-Allow-Origin: *
EOF

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

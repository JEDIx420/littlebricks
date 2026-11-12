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

# 3.6 Inject large WASM chunk loader into index.html
python3 -c '
with open("'"${BUILDS_DIR}"'/index.html", "r", encoding="utf-8") as f:
    content = f.read()

chunk_loader = """		<script>
		// Cloudflare Pages / CDN large WASM chunk loader (bypasses 25MB single-file upload limit)
		(function() {
			const _origFetch = window.fetch;
			window.fetch = async function(resource, init) {
				const url = typeof resource === "string" ? resource : (resource && resource.url ? resource.url : "");
				if (url.endsWith("index.wasm")) {
					try {
						const direct = await _origFetch(resource, init);
						if (direct.ok) {
							return direct;
						}
					} catch (e) {}
					const partA = url.replace(/index\\.wasm$/, "index.wasm.partaa");
					const partB = url.replace(/index\\.wasm$/, "index.wasm.partab");
					const [resA, resB] = await Promise.all([
						_origFetch(partA, init),
						_origFetch(partB, init)
					]);
					if (!resA.ok || !resB.ok) {
						throw new Error("Failed to load WASM parts: " + resA.status + " / " + resB.status);
					}
					const [bufA, bufB] = await Promise.all([resA.arrayBuffer(), resB.arrayBuffer()]);
					const combined = new Uint8Array(bufA.byteLength + bufB.byteLength);
					combined.set(new Uint8Array(bufA), 0);
					combined.set(new Uint8Array(bufB), bufA.byteLength);
					return new Response(combined, {
						status: 200,
						statusText: "OK",
						headers: {
							"Content-Type": "application/wasm",
							"Cross-Origin-Opener-Policy": "same-origin",
							"Cross-Origin-Embedder-Policy": "require-corp"
						}
					});
				}
				return _origFetch(resource, init);
			};
		})();
		</script>
		<script src="index.js"></script>"""

if "index.wasm.partaa" not in content and "<script src=\"index.js\"></script>" in content:
    content = content.replace("<script src=\"index.js\"></script>", chunk_loader, 1)
    with open("'"${BUILDS_DIR}"'/index.html", "w", encoding="utf-8") as f:
        f.write(content)
'

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

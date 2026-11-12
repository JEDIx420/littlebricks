#!/usr/bin/env bash
# ==============================================================================
# LittleBricks Cloudflare Pages Deployment Pipeline
# Deploys the Web build to Cloudflare Pages bypassing the 25MB single-file limit.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILDS_DIR="${PROJECT_ROOT}/builds/web"
STAGING_DIR="${PROJECT_ROOT}/builds/pages_staging"
PROJECT_NAME="littlebricks"

echo "=== LittleBricks Cloudflare Pages Deployment ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# 1. Verify builds/web exists and is populated
if [[ ! -f "${BUILDS_DIR}/index.html" ]] || [[ ! -f "${BUILDS_DIR}/index.wasm" ]]; then
    echo "Running build_web.sh first..."
    "${SCRIPT_DIR}/build_web.sh"
fi

# 2. Prepare staging directory
echo "Preparing staging directory at ${STAGING_DIR}..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

# Copy all assets except large index.wasm and zip
cp "${BUILDS_DIR}"/index.* "${STAGING_DIR}/"
cp "${BUILDS_DIR}"/_headers "${STAGING_DIR}/"
rm -f "${STAGING_DIR}/index.wasm"
rm -f "${STAGING_DIR}"/*.zip

# 3. Split WASM into chunks under 25MB (20MB chunks)
echo "Splitting index.wasm into chunks under 20MB..."
split -b 20m "${BUILDS_DIR}/index.wasm" "${STAGING_DIR}/index.wasm.part"

# 4. Verify no file exceeds 25 MiB (26,214,400 bytes)
MAX_SIZE=25000000
echo "Auditing staging files against Cloudflare 25MB limit..."
for file in "${STAGING_DIR}"/*; do
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
    fname=$(basename "$file")
    if (( size > MAX_SIZE )); then
        echo "ERROR: File $fname is $size bytes (exceeds 25MB limit)!"
        exit 1
    else
        echo "  ✓ $fname ($(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "$((size/1024/1024)) MB"))"
    fi
done

# 5. Deploy via Wrangler to Cloudflare Pages
echo ""
echo "Deploying to Cloudflare Pages project '${PROJECT_NAME}'..."
npx wrangler pages deploy "${STAGING_DIR}" --project-name "${PROJECT_NAME}" --branch main --commit-dirty=true

# 6. Cleanup
rm -rf "${STAGING_DIR}"

echo ""
echo "=== Cloudflare Pages Deployment Complete ==="
echo "URL: https://${PROJECT_NAME}.pages.dev/index.html"

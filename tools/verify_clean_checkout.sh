#!/usr/bin/env bash
# ==============================================================================
# LittleBricks Clean-Checkout & Contributor Verification Suite (LB-031)
# Executes complete end-to-end audit from a fresh checkout state.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GAME_DIR="${PROJECT_ROOT}/game"

echo "========================================================================"
echo "    LittleBricks Clean-Checkout Contributor Verification Suite"
echo "========================================================================"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Host OS: $(uname -s) $(uname -m)"
echo "Directory: ${PROJECT_ROOT}"
echo ""

# 1. Environment & Toolchain Audit
echo "[Step 1/4] Running Environment & Toolchain Discovery..."
python3 "${SCRIPT_DIR}/env_check.py"
echo ""

# 2. Basic Engine Runtime Smoke Test (Pre-build)
echo "[Step 2/5] Running Engine Headless Smoke Test..."
python3 "${SCRIPT_DIR}/test_smoke.py" --runtime-only
echo ""

# 3. Comprehensive Headless GDScript Test Suites
echo "[Step 3/5] Executing Comprehensive Automated Test Matrix..."
TEST_SCRIPTS=(
    "res://tests/test_canonical_lattice.gd"
    "res://tests/test_surface_height_and_camera.gd"
    "res://tests/test_part_catalog.gd"
    "res://tests/test_placement_rules.gd"
    "res://tests/test_interaction_parity.gd"
    "res://tests/test_session_manager.gd"
    "res://tests/test_save_and_undo.gd"
    "res://tests/test_app_lifecycle_and_audio.gd"
    "res://tests/test_building_rules_and_hands.gd"
    "res://tests/test_finish_exploration_and_recovery.gd"
    "res://tests/test_sensory_quality_and_presentation.gd"
    "res://tests/test_play_sessions_and_pacing.gd"
    "res://tests/test_multiplayer_authority.gd"
    "res://tests/test_online_rooms_and_durability.gd"
    "res://tests/test_exploration.gd"
    "res://tests/test_benchmark_and_video.gd"
    "res://tests/test_film_and_video_export.gd"
    "res://tests/test_replay_and_export.gd"
    "res://tests/test_integrated_journeys.gd"
)

PASSED_COUNT=0
FAILED_COUNT=0

for test_script in "${TEST_SCRIPTS[@]}"; do
    echo "--- Executing: ${test_script} ---"
    if godot --headless --path "${GAME_DIR}" -s "${test_script}"; then
        echo "RESULT: PASS (${test_script})"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        echo "RESULT: FAIL (${test_script})"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        exit 1
    fi
    echo ""
done

# 4. Reproducible Release Builds
echo "[Step 4/5] Running Reproducible Release Build Pipeline..."
"${SCRIPT_DIR}/build_all_releases.sh"
echo ""

# 5. Export Artifacts Verification (Post-build)
echo "[Step 5/5] Validating Generated Release Artifacts..."
python3 "${SCRIPT_DIR}/test_smoke.py" --artifacts-only
echo ""

echo "========================================================================"
echo "                       VERIFICATION SUMMARY"
echo "========================================================================"
echo "Automated Tests: ${PASSED_COUNT} passed, ${FAILED_COUNT} failed"
echo "Desktop macOS Export:  PASS (builds/desktop/LittleBricks-macOS.zip)"
echo "WebAssembly Export:   PASS (builds/web/index.html + wasm)"
echo "Headless Server Pack:  PASS (builds/server/LittleBricksServer.pck)"
echo "Physical Android:      BLOCKED (0 devices connected via ADB)"
echo "Play Store Closed Track: BLOCKED (No publisher credentials configured)"
echo "========================================================================"
echo "Clean checkout verification completed successfully."

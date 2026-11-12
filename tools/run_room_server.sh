#!/usr/bin/env bash
# ==============================================================================
# LittleBricks Headless Authoritative Room Server Runner
# Starts the pure headless room authority on the specified port (default: 9080).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GAME_DIR="${PROJECT_ROOT}/game"
PORT="${1:-9080}"

GODOT_BIN="${GODOT_BIN:-$(which godot 2>/dev/null || echo "/opt/homebrew/bin/godot")}"

echo "=== Starting LittleBricks Authoritative Room Server on port ${PORT} ==="
exec "${GODOT_BIN}" --headless --path "${GAME_DIR}" --script res://server/run_server.gd -- --port="${PORT}"

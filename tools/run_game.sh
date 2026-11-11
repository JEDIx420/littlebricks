#!/usr/bin/env bash
set -e

# Run LittleBricks game client
# Usage: ./tools/run_game.sh [--headless] [--quit]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

if ! command -v godot &> /dev/null; then
    echo "Error: 'godot' binary not found on PATH." >&2
    exit 1
fi

echo "Launching LittleBricks with Godot 4.7..."
godot --path game "$@"

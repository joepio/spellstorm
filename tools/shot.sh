#!/usr/bin/env bash
# Render the game to a PNG with bots playing: tools/shot.sh out.png [--frames N] [--biome N] [--seed N] [--players N] [--recipe N]
# Needs xvfb-run; uses the OpenGL (compatibility) renderer.
set -euo pipefail
out=$(realpath -m "$1"); shift
cd "$(dirname "$0")/.."
xvfb-run -a -s "-screen 0 1920x1080x24" "${GODOT:-godot}" --resolution 1920x1080 --path . -- --shot "$out" "$@"

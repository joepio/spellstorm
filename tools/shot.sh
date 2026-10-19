#!/usr/bin/env bash
# Render the game to a PNG with bots playing: tools/shot.sh out.png [--frames N] [--biome N] [--seed N] [--players N] [--recipe N]
# Needs xvfb-run and a Vulkan driver (mesa-vulkan-drivers: llvmpipe works) for Forward+.
set -euo pipefail
out=$(realpath -m "$1"); shift
cd "$(dirname "$0")/.."
lvp=/usr/share/vulkan/icd.d/lvp_icd.json
[ -f "$lvp" ] && export VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-$lvp}"
xvfb-run -a -s "-screen 0 1920x1080x24" "${GODOT:-godot}" --resolution 1920x1080 --path . -- --shot "$out" "$@"

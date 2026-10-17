#!/usr/bin/env bash
# Record the takes for the five-second GameNight preview: real game, bots
# playing, staged with --at (where along the level) and --spawn (which
# monsters stand round the wizards), the camera brought closer with --zoom.
# Writes PNG frames per take to OUT/<take>/; tools/encode_preview.py cuts them.
#   GODOT=... tools/capture_preview.sh OUT
set -euo pipefail
out=$(realpath -m "$1")
cd "$(dirname "$0")/.."
take() {
	local name=$1; shift
	mkdir -p "$out/$name"
	xvfb-run -a -s "-screen 0 960x540x24" timeout 400 "${GODOT:-godot}" --resolution 960x540 \
		--audio-driver Dummy --fixed-fps 30 --write-movie "$out/$name/f.png" --quit-after 130 \
		--path . -- --shot "$out/$name/end.png" --frames 100000 --zoom 0.62 "$@" > "$out/$name/log.txt" 2>&1
}
take chapel --seed 11 --biome 0 --players 3 --at 60 --spawn skeleton,skeleton,bone_archer,necromancer,ghoul,ghoul
take isles --seed 12 --biome 2 --players 3 --at 45 --spawn sprite,sprite,toad,toad,drowned
take keep --seed 13 --biome 4 --players 4 --at 70 --spawn shieldbearer,shieldbearer,wraith,frost_brute,skeleton
take pit --seed 14 --biome 5 --players 3 --at 50 --spawn hellhound,hellhound,hellhound,imp,imp,demon
take boss --seed 15 --biome 1 --players 4 --at -1

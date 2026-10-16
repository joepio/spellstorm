#!/usr/bin/env bash
# Parse-check every script: tools/check.sh
cd "$(dirname "$0")/.."
G="${GODOT:-godot}"
for f in $(find src main.gd tests -name '*.gd'); do
	out=$("$G" --headless --check-only --script "$f" 2>&1 | grep -E "SCRIPT ERROR|at: " | grep -v -E "Failed to compile depended|Identifier not found: GameNight" )
	if [ -n "$out" ]; then echo "== $f"; echo "$out" | head -8; fi
done

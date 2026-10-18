shader_type spatial;
// A trap on the floor: a faint circle of runes etched into the ground, lit
// from below in the element's colour and softly breathing, never flicking.
// armed goes 0 to 1 when it is ready; flash is set briefly as it springs.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/element.gdshaderinc"

uniform int element = 2;
uniform vec4 base : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 second : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float armed = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	if (r > 1.0) {
		discard;
	}
	float ang = atan(q.y, q.x);
	float t = TIME;
	// Worn into stone: noise breaks every line up so nothing is a clean
	// shape. All of it holds still: only the light under it moves.
	float grit = sn_fbm(vec3(q * 6.0, seed));
	float wear = smoothstep(0.25, 0.65, grit);
	// Outer circle with gaps, like a carved ring of glyphs.
	float ring = 1.0 - smoothstep(0.0, 0.035, abs(r - 0.86));
	float glyphs = step(0.35, fract(ang / 6.2832 * 12.0 + seed));
	ring *= mix(0.35, 1.0, glyphs);
	// Inner runes: six spokes and a small circle, thin and broken.
	float spoke = 1.0 - smoothstep(0.0, 0.03, abs(sin(ang * 3.0 + seed)) * r);
	spoke *= step(0.22, r) * step(r, 0.7);
	float inner = 1.0 - smoothstep(0.0, 0.03, abs(r - 0.22));
	float lines = max(ring, max(spoke * 0.7, inner)) * wear;
	// A soft glow of the element under it all, strongest at the middle.
	float under = (1.0 - smoothstep(0.0, 0.9, r)) * 0.16 * (0.7 + 0.3 * grit);
	// It breathes: a slow, soft swell, and a gentle wave of light running
	// out from the middle through the runes, as if lit from below.
	float breath = 0.72 + 0.28 * sin(t * 1.7 + seed * 6.0);
	float wave = 0.5 + 0.5 * sin(r * 7.0 - t * 2.2 + seed);
	float pulse = breath * (0.8 + 0.35 * wave);
	float lit = mix(0.25, 1.0, armed) * pulse;
	// The element's colour, its second element worked into alternate runes.
	vec3 col = mix(base.rgb, second.rgb, 0.3 * step(0.5, fract(ang / 6.2832 * 6.0 + seed)));
	col = mix(col, vec3(1.0), 0.15 * wave * lines);
	ALBEDO = col * (lines * 1.4 + under * 2.0) * lit;
	ALPHA = clamp(lines * 0.75 + under, 0.0, 1.0) * mix(0.4, 0.9, armed) * (0.8 + 0.2 * breath);
}

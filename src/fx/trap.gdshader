shader_type spatial;
// A trap on the floor: a faint circle of runes etched into the ground with
// the element's own look (element.gdshaderinc) seeping through the cracks,
// so it reads as fire, ice or void without being a flat coloured ring.
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
	// The element's surface, seen from above, drifting slowly.
	vec3 p = normalize(vec3(q.x, 0.6, q.y));
	vec3 look = element_look(element, base.rgb, p, 0.8, t * 0.5).rgb;
	// Worn into stone: noise breaks every line up so nothing is a clean shape.
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
	float under = (1.0 - smoothstep(0.0, 0.9, r)) * 0.18 * (0.7 + 0.3 * grit);
	float pulse = 0.75 + 0.25 * sin(t * 2.5 + seed * 6.0);
	float lit = mix(0.25, 1.0, armed) * pulse;
	vec3 col = mix(look, second.rgb, 0.25 * step(0.5, fract(ang / 6.2832 * 6.0)));
	ALBEDO = col * (lines * 1.3 + under * 2.0) * lit;
	ALPHA = clamp(lines * 0.75 + under, 0.0, 1.0) * mix(0.4, 0.9, armed);
}

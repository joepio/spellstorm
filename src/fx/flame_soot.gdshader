shader_type spatial;
// Smoke rolling off the Flamethrower's jet: dark, broken up, thickening where
// the flame burns out and drifting a little past its tip. Drawn under the
// additive jet so the fire reads against it instead of washing out the floor.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform float speed = 3.0;
uniform float strength = 1.0;
uniform float jet_length = 5.0;
uniform float near_width = 0.4;
uniform float far_width = 2.6;
uniform float seed = 0.0;

varying float v_along;

void vertex() {
	float along = UV.y;
	v_along = along;
	float w = mix(near_width, far_width, along);
	VERTEX = vec3((UV.x - 0.5) * w, 0.0, -along * jet_length);
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	float along = v_along;
	float side = UV.x - 0.5;
	vec2 q = vec2(side * mix(near_width, far_width, along) * 1.2, along * jet_length * 0.6 - TIME * speed + seed);
	float n = sn_fbm(vec3(q + vec2(sn_fbm(vec3(q * 0.7, 3.0 + TIME * 0.3))) * 1.5, TIME * 0.25));
	float billow = smoothstep(0.42, 0.75, n);
	float body = 1.0 - smoothstep(0.35, 1.0, abs(side) * 2.0 + (n - 0.5) * 0.5);
	body *= 1.0 - smoothstep(0.75, 1.0, abs(side) * 2.0);
	float grow = smoothstep(0.3, 0.75, along) * (1.0 - smoothstep(0.82, 1.0, along));
	float a = billow * body * grow * strength * 0.5;
	ALBEDO = mix(vec3(0.035, 0.03, 0.028), vec3(0.12, 0.105, 0.09), n);
	ALPHA = clamp(a, 0.0, 1.0);
}

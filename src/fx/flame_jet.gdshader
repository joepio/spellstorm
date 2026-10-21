shader_type spatial;
// The Flamethrower's jet: one connected tongue of fire from the staff to a
// ragged tip, not a string of blobs (after Frog Fighter's flame jet). A flat
// ribbon, shaped here from its UVs, widens away from the staff and sways a
// little; domain-warped noise rushes along it so the turbulence moves inside
// the envelope. Colour comes from optical density through a heat ramp:
// mostly orange, deep red where it is thin, a white-yellow core near the staff.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform float speed = 8.0;
uniform float strength = 1.0;
uniform float jet_length = 5.0;
// Full width at the staff and at the far end, in metres.
uniform float near_width = 0.25;
uniform float far_width = 2.0;
uniform float seed = 0.0;

varying float v_along;

vec4 heat_ramp(float h) {
	vec4 c0 = vec4(0.5, 0.06, 0.01, 0.0);
	vec4 c1 = vec4(0.9, 0.2, 0.02, 0.35);
	vec4 c2 = vec4(1.0, 0.3, 0.03, 0.75);
	vec4 c3 = vec4(1.0, 0.46, 0.07, 0.92);
	vec4 c4 = vec4(1.0, 0.82, 0.5, 1.0);
	if (h < 0.3) return mix(c0, c1, h / 0.3);
	if (h < 0.7) return mix(c1, c2, (h - 0.3) / 0.4);
	if (h < 0.9) return mix(c2, c3, (h - 0.7) / 0.2);
	return mix(c3, c4, (h - 0.9) / 0.1);
}

void vertex() {
	float along = UV.y;
	v_along = along;
	float w = mix(near_width, far_width, pow(along, 0.85));
	float sway = sin(along * 5.0 - TIME * 7.0 + seed) * 0.07 * along * jet_length * 0.2;
	VERTEX = vec3((UV.x - 0.5) * w + sway, 0.0, -along * jet_length);
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	float along = v_along;
	float side = UV.x - 0.5;
	// World-sized grain: across in metres-ish, along in metres, rushing outward.
	vec2 q = vec2(side * mix(near_width, far_width, along) * 2.6, along * jet_length * 0.7 - TIME * speed + seed);
	vec2 warp = vec2(sn_fbm(vec3(q + 1.7, TIME * 0.5)), sn_fbm(vec3(q - 4.2, TIME * 0.5 + 3.0)));
	float n = sn_fbm(vec3(q + warp * 1.6, TIME * 0.8 + seed));
	float ribbons = smoothstep(0.36, 0.7, n);
	float across = abs(side) * 2.0;
	// A connected envelope: torn at the edges, thinning and breaking up at the tip.
	float envelope = 1.0 - smoothstep(0.35, 0.95, across + (n - 0.5) * 0.9 * (0.3 + along));
	envelope *= 1.0 - smoothstep(0.85, 1.0, across);
	float tip = 1.0 - smoothstep(0.66, 1.02, along + (n - 0.5) * 0.5);
	float nozzle = smoothstep(0.0, 0.06, along);
	float core = (1.0 - smoothstep(0.0, 0.35, across)) * (1.0 - smoothstep(0.0, 0.5, along));
	float density = envelope * (0.4 + ribbons * 0.7) + core * 0.35;
	// It cools as it travels.
	float heat = clamp(density * (1.05 - along * 0.45), 0.0, 1.0);
	vec4 fire = heat_ramp(heat);
	float a = fire.a * envelope * (0.55 + 1.1 * ribbons) * tip * nozzle * strength;
	ALBEDO = fire.rgb * 1.2;
	ALPHA = clamp(a, 0.0, 1.0);
}

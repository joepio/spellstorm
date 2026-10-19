shader_type spatial;
// A pillar of light standing up out of a fallen wizard's grave, so you can
// find it from across the level. Soft at the sides, fading out high up, with
// motes drifting upward through it. Brighter and warmer while a friend is
// raising you.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.7, 0.85, 1.0, 1.0);
uniform float strength = 1.0;

void fragment() {
	// Bright down the middle as seen from the camera, soft at the edges.
	// Measured flat, so the steep camera still sees a bright middle.
	vec3 n = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 v = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
	float facing = abs(dot(normalize(n.xz), normalize(v.xz + vec2(1e-4))));
	float core = pow(facing, 2.0);
	// UV.y runs 0 at the top to 1 at the bottom of the cylinder.
	float h = 1.0 - UV.y;
	float fade = (1.0 - smoothstep(0.0, 0.85, h)) * smoothstep(0.0, 0.03, h);
	// Streaks rising slowly up the pillar.
	float u = UV.x * 9.0;
	float streak = sin(u * 6.2832 + sin(u * 2.3) * 1.5);
	float rise = fract(h * 3.0 - TIME * 0.35 + floor(u) * 0.37);
	float motes = smoothstep(0.6, 1.0, streak) * smoothstep(0.75, 0.95, rise) * 0.8;
	float breathe = 0.85 + 0.15 * sin(TIME * 2.2);
	float a = (core * 0.8 + motes * core) * fade * breathe * strength;
	ALBEDO = mix(color.rgb, vec3(1.0), 0.35 * core);
	ALPHA = clamp(a, 0.0, 1.0);
}

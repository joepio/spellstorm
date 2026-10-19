shader_type spatial;
// The tail streaming behind a fiery shot: brightest where it leaves the
// shot, thinning and fading to nothing, soft at its edges, flickering a
// little, so it reads as heat and smoke rather than a solid cone.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float energy = 1.2;

void fragment() {
	// UV.y runs 0 at the tip to 1 at the shot.
	float along = pow(UV.y, 1.8);
	float facing = abs(dot(NORMAL, VIEW));
	float edge = pow(facing, 1.6);
	float flicker = 0.75 + 0.25 * sin(TIME * 23.0 + UV.y * 9.0 + UV.x * 6.2832 * 2.0);
	float a = along * edge * flicker;
	vec3 hot = mix(color.rgb, vec3(1.0, 0.9, 0.6), smoothstep(0.7, 1.0, UV.y) * 0.5);
	ALBEDO = hot * energy * a;
	ALPHA = clamp(a, 0.0, 1.0);
}

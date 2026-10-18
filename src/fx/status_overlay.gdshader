shader_type spatial;
// The tint a status lays over a body (hit flash, frozen, wet, poisoned):
// laid on as a sheen that is strongest at the edges, so the body keeps its
// shading and shape instead of turning into a flat blob of colour.
render_mode unshaded, blend_mix, cull_back, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(tint.rgb, vec3(1.0), rim * 0.25);
	ALPHA = clamp(tint.a * (0.35 + 0.9 * rim), 0.0, 1.0);
}

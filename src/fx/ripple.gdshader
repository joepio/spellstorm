shader_type spatial;
// Wading ripples: a soft pale ring spreading on the water round your legs,
// barely there, mixed over the water rather than glowing on it.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.55, 0.7, 0.72, 1.0);
uniform float k = 0.0;

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float ring = 1.0 - smoothstep(0.0, 0.06, abs(r - 0.9));
	ALBEDO = color.rgb;
	ALPHA = ring * 0.3 * (1.0 - k);
}

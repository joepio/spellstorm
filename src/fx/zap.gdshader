shader_type spatial;
// A lightning strike: ribbons with a white core that falls off into the
// element's glow across their width (UV.x 0..1), flickering as it fades.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge : source_color = vec4(0.6, 0.55, 1.0, 1.0);
uniform float strength = 1.0;

void fragment() {
	float x = abs(UV.x * 2.0 - 1.0);
	float centre = exp(-x * x * 40.0);
	float glow = exp(-x * x * 5.0);
	float flick = 0.75 + 0.25 * sin(TIME * 90.0 + UV.y * 3.0);
	vec3 c = core.rgb * centre * 1.6 + edge.rgb * glow * 0.9;
	ALBEDO = c * strength * flick * COLOR.a;
	ALPHA = clamp((centre + glow * 0.6) * strength * COLOR.a, 0.0, 1.0);
}

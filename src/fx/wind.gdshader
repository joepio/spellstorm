shader_type spatial;
// Wind you see by what it carries: pale ribbons of dust and haze that twist
// and stream, thin where you look through it and thick at its outline. `mode`: 0 a tornado's funnel (UV.x round,
// UV.y down the funnel), 1 a swirl on the ground (polar from the middle),
// 2 a gust along a cone (UV.y from the staff out). `fade` takes it away.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform int mode = 0;
uniform vec4 tint : source_color = vec4(0.88, 0.96, 0.93, 1.0);
uniform float strength = 1.0;
uniform float spin = 1.0;
uniform float fade = 1.0;

void fragment() {
	float u;
	float v;
	float mask;
	float t = TIME * spin;
	if (mode == 1) {
		vec2 p = UV * 2.0 - 1.0;
		float r = length(p);
		// Spiral arms: the angle shifts with the radius, and the whole turns.
		u = atan(p.y, p.x) / TAU + r * 0.55 - t * 0.35;
		v = r;
		mask = (1.0 - smoothstep(0.55, 1.0, r)) * smoothstep(0.0, 0.25, r);
	} else if (mode == 0) {
		// Twisted, faster near the narrow foot.
		u = UV.x + UV.y * 0.6 - t * (0.35 + UV.y * 0.35);
		v = UV.y;
		mask = smoothstep(0.0, 0.25, v) * (1.0 - smoothstep(0.8, 1.0, v));
	} else {
		u = UV.x;
		v = UV.y - t * 1.2;
		mask = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.6, 1.0, UV.y));
	}
	float facing = abs(dot(NORMAL, VIEW));
	if (mode != 1) {
		// Thin in the middle, thick at the silhouette, like a glass shell.
		mask *= 0.35 + 0.65 * (1.0 - facing);
	}
	mask *= fade;
	if (mask <= 0.002) {
		discard;
	}
	// Soft haze that drifts with the wind, and sharper ribbons of dust in it.
	float haze = sn_fbm(vec3(u * 5.0, v * 3.0, t * 0.4));
	float rib = sn_fbm(vec3(fract(u) * 14.0, v * 1.6 + haze, t * 0.25));
	float dust = smoothstep(0.5, 0.75, rib);
	float a = (dust * 0.55 + smoothstep(0.3, 0.8, haze) * 0.18) * mask * strength;
	ALBEDO = tint.rgb * (0.8 + dust * 0.5);
	ALPHA = clamp(a, 0.0, 1.0);
}

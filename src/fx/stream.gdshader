shader_type spatial;
// A spray's cone: a body of flame, frost, water or steam rushing out of the
// staff. Noise scrolls along the cone so it boils; the view angle softens the
// sides so it reads as a volume, not a shell. `style`: 0 flame, 1 frost
// (glittering), 2 water (streaks), 3 vapour (soft and slow).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform vec4 core : source_color = vec4(1.0, 0.9, 0.6, 1.0);
uniform vec4 edge : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform int style = 0;
uniform float speed = 3.0;
uniform float strength = 1.0;
uniform float reach = 1.0;

void fragment() {
	// UV.y runs from the staff (0) to the far end (1), UV.x round the cone.
	float along = UV.y;
	float facing = abs(dot(NORMAL, VIEW));
	vec3 q = vec3(UV.x * 6.0, along * 3.0 * reach - TIME * speed, 0.0);
	float n = sn_fbm(q * vec3(1.0, 1.0, 1.0) + vec3(0.0, 0.0, TIME * 0.7));
	float body;
	vec3 c;
	if (style == 1) {
		float glint = pow(sn_noise(vec3(UV.x * 30.0, along * 20.0 * reach - TIME * speed * 2.0, TIME * 4.0)), 6.0) * 3.0;
		body = 0.2 + 0.8 * smoothstep(0.3, 0.7, n) + glint;
		c = mix(edge.rgb, core.rgb, n) + vec3(glint);
	} else if (style == 2) {
		float streak = sn_noise(vec3(UV.x * 24.0, along * 2.0 * reach - TIME * speed * 1.5, 0.0));
		body = 0.3 + 0.9 * smoothstep(0.35, 0.8, streak) * (0.5 + n);
		c = mix(edge.rgb, core.rgb, smoothstep(0.5, 0.9, streak));
	} else if (style == 3) {
		body = smoothstep(0.25, 0.75, n);
		c = mix(edge.rgb, core.rgb, n * 0.6);
	} else {
		// Hot near the staff and in the folds, cooling to smoke at the tip.
		float heat = n * (1.25 - along * 0.9);
		body = smoothstep(0.22, 0.65, heat);
		c = mix(edge.rgb * 0.6, core.rgb, smoothstep(0.55, 0.9, heat));
	}
	float ends = smoothstep(0.0, 0.12, along) * (1.0 - smoothstep(0.65, 1.0, along));
	float a = body * ends * pow(facing, 1.5) * strength * 0.8;
	ALBEDO = c * a * 1.1;
	ALPHA = clamp(a, 0.0, 1.0);
}

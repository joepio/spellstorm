shader_type spatial;
// One tongue of fire: a camera-facing quad that licks upwards. Each flame
// flickers on its own, seeded by where it stands. `fade` takes it away.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform float fade = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], vec4(0.0, 1.0, 0.0, 0.0), INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y);
	float seed = NODE_POSITION_WORLD.x * 1.7 + NODE_POSITION_WORLD.z * 3.1;
	float n = sn_fbm(vec3(p.x * 2.0, p.y * 2.5 - TIME * 2.8, seed));
	float sway = (n - 0.5) * 0.7 * p.y;
	// A teardrop: round at the foot, narrowing to a tip that the noise tears up.
	float w = 0.5 * pow(max(1.0 - p.y, 0.0), 0.7) * smoothstep(-0.05, 0.2, p.y);
	float d = abs(p.x + sway) / max(w, 0.001);
	float body = (1.0 - smoothstep(0.3, 1.0, d)) * (1.0 - smoothstep(0.35, 0.9, p.y + (n - 0.5) * 0.7));
	if (body <= 0.01) {
		discard;
	}
	float hot = (1.0 - smoothstep(0.0, 0.6, d)) * (1.0 - smoothstep(0.1, 0.55, p.y));
	vec3 c = mix(vec3(0.75, 0.12, 0.01), vec3(1.0, 0.5, 0.08), body);
	c = mix(c, vec3(1.0, 0.82, 0.4), hot);
	ALBEDO = c * body * 1.5 * fade;
	ALPHA = clamp(body, 0.0, 1.0) * fade;
}

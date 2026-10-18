shader_type spatial;
// A ring running out over the floor (Fx.ring): not a solid hoop but a
// shock front, a thin bright edge with a soft glow trailing inside it and a
// faint shimmer of the ground it passed, broken up so it never reads as a
// clean circle. `k` runs 0 to 1 over its life: it thins and fades.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float k = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float ang = atan(q.y, q.x);
	// The front wobbles a little and is brighter in patches.
	float n = sn_noise(vec3(cos(ang) * 3.0 + seed, sin(ang) * 3.0, k * 2.0));
	float edge_r = 0.94 + 0.04 * (n - 0.5);
	float w = mix(0.05, 0.02, k);
	float front = 1.0 - smoothstep(0.0, w, abs(r - edge_r));
	// The glow left behind, strongest just inside the front.
	float trail = smoothstep(edge_r - 0.45, edge_r, r) * step(r, edge_r) * 0.35;
	float patch = 0.6 + 0.8 * smoothstep(0.35, 0.75, n);
	float life = (1.0 - k) * (1.0 - k);
	float a = (front * patch + trail) * life;
	ALBEDO = mix(color.rgb, vec3(1.0), front * 0.35) * a;
	ALPHA = clamp(a, 0.0, 1.0);
}

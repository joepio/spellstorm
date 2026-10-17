shader_type spatial;
// A nova's shockwave on the ground: a bright ring running out from the
// centre with a broken, smoky edge and a faint fill behind it. `progress`
// goes 0 to 1 over the burst (NovaFx tweens it).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform vec4 core : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform vec4 edge : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float progress = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float front = 1.0 - pow(1.0 - progress, 2.2);
	float n = sn_fbm(vec3(cos(ang) * 3.0, sin(ang) * 3.0, r * 4.0 - progress * 3.0 + seed));
	float wobble = (n - 0.5) * 0.12;
	float dr = r - front - wobble;
	float ring = exp(-dr * dr * 900.0 / (0.4 + progress)) ;
	float wake = smoothstep(0.0, -0.5, dr) * step(dr, 0.0) * (0.25 + 0.5 * n);
	float fade = 1.0 - smoothstep(0.55, 1.0, progress);
	float a = (ring * 1.4 + wake * 0.5) * fade * step(r, 1.0);
	vec3 c = mix(edge.rgb, core.rgb, ring);
	ALBEDO = c * a * 1.5;
	ALPHA = clamp(a, 0.0, 1.0);
}

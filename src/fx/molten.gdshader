shader_type spatial;
// A thrown ball of fire, magma or raw element: a churning glowing surface,
// brighter where it faces the camera, with dark crust drifting over magma
// (`crust`).
render_mode unshaded, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform vec4 core : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform vec4 edge : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform float crust = 0.0;
uniform float speed = 1.5;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float facing = abs(dot(NORMAL, VIEW));
	float n = sn_fbm(lp * 5.0 + vec3(0.0, TIME * speed, TIME * speed * 0.6));
	float hot = smoothstep(0.3, 0.75, n) * (0.5 + 0.7 * facing);
	vec3 c = mix(edge.rgb, core.rgb, hot);
	float cr = smoothstep(0.45, 0.6, sn_noise(lp * 9.0 + vec3(TIME * 0.4))) * crust;
	c = mix(c, edge.rgb * 0.12, cr);
	ALBEDO = c * (1.3 + hot * 1.5) * (1.0 - cr * 0.85);
}

shader_type spatial;
// Burning ground: charred earth with glowing seams that crawl and flicker.
// The edge is ragged noise, not a circle. Lava (`lava` = 1) is brighter,
// slower and crusted. `fade` takes it away.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform float lava = 0.0;
uniform float fade = 1.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float t = TIME * mix(1.0, 0.25, lava);
	// A ragged rim that slowly breathes.
	float rim = 0.78 + 0.2 * sn_fbm(vec3(atan(p.y, p.x) * 1.6, r, t * 0.4) + wpos * 0.15);
	float mask = 1.0 - smoothstep(rim - 0.3, rim, r);
	if (mask <= 0.0) {
		discard;
	}
	vec3 q = vec3(wpos.x, t * 0.7, wpos.z) * mix(2.2, 0.8, lava);
	float n = sn_fbm(q + vec3(0.0, 0.0, -t * 0.5));
	float seams = 1.0 - abs(n * 2.0 - 1.0);
	seams = pow(seams, mix(9.0, 2.5, lava));
	float flick = 0.75 + 0.25 * sn_noise(vec3(wpos.xz * 2.0, t * 4.0).xzy);
	float heat = clamp(seams * flick * (0.4 + 0.8 * mask) * mix(0.75, 1.0, lava), 0.0, 1.0);
	vec3 char = mix(vec3(0.05, 0.02, 0.015), vec3(0.3, 0.06, 0.0), lava);
	vec3 c = mix(char, vec3(0.9, 0.18, 0.02), smoothstep(0.05, 0.45, heat));
	c = mix(c, vec3(1.0, 0.7, 0.25), smoothstep(0.45, 0.85, heat));
	c = mix(c, vec3(1.0, 0.95, 0.7), smoothstep(0.85, 1.0, heat) * (0.5 + 0.5 * lava));
	ALBEDO = c * (0.8 + heat * 0.7);
	ALPHA = clamp(mask * (mix(0.45, 0.95, lava) + heat), 0.0, 1.0) * fade;
}

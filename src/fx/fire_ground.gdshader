shader_type spatial;
// Burning ground (`lava` = 0): scorched earth with embers, the flames stand
// on it (flame.gdshader). Lava (`lava` = 1): molten seams that crawl and
// glow. The edge is ragged noise, not a circle. `fade` takes it away.
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
	vec3 char = mix(vec3(0.05, 0.02, 0.015), vec3(0.3, 0.06, 0.0), lava);
	if (lava < 0.5) {
		// Burning ground: scorched dark earth, a warm glow under the flames
		// and a scatter of embers winking on and off. No molten seams.
		float warm = sn_fbm(vec3(wpos.x * 0.9, t * 0.5, wpos.z * 0.9));
		float ember = smoothstep(0.72, 0.9, sn_noise(vec3(wpos.x * 5.0, wpos.z * 5.0, t * 2.0)));
		vec3 c = mix(char, vec3(0.45, 0.1, 0.02), smoothstep(0.4, 0.75, warm) * mask * 0.8);
		c += vec3(1.0, 0.55, 0.15) * ember * mask * 1.2;
		ALBEDO = c;
		ALPHA = clamp(mask * 0.6 + ember * mask, 0.0, 1.0) * fade;
	} else {
		vec3 q = vec3(wpos.x, t * 0.7, wpos.z) * 0.8;
		float n = sn_fbm(q + vec3(0.0, 0.0, -t * 0.5));
		float seams = 1.0 - abs(n * 2.0 - 1.0);
		seams = pow(seams, 2.5);
		float flick = 0.75 + 0.25 * sn_noise(vec3(wpos.xz * 2.0, t * 4.0).xzy);
		float heat = clamp(seams * flick * (0.4 + 0.8 * mask), 0.0, 1.0);
		vec3 c = mix(char, vec3(0.9, 0.18, 0.02), smoothstep(0.05, 0.45, heat));
		c = mix(c, vec3(1.0, 0.7, 0.25), smoothstep(0.45, 0.85, heat));
		c = mix(c, vec3(1.0, 0.95, 0.7), smoothstep(0.92, 1.0, heat));
		// Mostly dark crust; only the seams run hot.
		c = mix(char * 0.5, c, smoothstep(0.1, 0.5, heat));
		ALBEDO = c * (0.6 + heat * 0.6);
		ALPHA = clamp(mask * 0.95 + heat, 0.0, 1.0) * fade;
	}
}

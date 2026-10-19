shader_type spatial;
// A pool of poison: dark green sludge that slowly churns, with bubbles that
// swell and pop. The edge is ragged noise, not a circle. `fade` takes it away.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform vec4 tint : source_color = vec4(0.55, 0.95, 0.12, 1.0);
uniform float fade = 1.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float rim = 0.8 + 0.18 * sn_fbm(vec3(atan(p.y, p.x) * 1.6, r, TIME * 0.2) + wpos * 0.2);
	float mask = 1.0 - smoothstep(rim - 0.25, rim, r);
	if (mask <= 0.0) {
		discard;
	}
	float churn = sn_fbm(vec3(wpos.x * 1.2, TIME * 0.25, wpos.z * 1.2));
	vec3 murk = mix(tint.rgb, vec3(0.3, 0.32, 0.1), 0.35);
	vec3 c = mix(murk * 0.06, murk * 0.27, smoothstep(0.35, 0.7, churn));
	// Bubbles: one per cell, each on its own clock, swelling then popping.
	vec2 g = wpos.xz * 3.0;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = fract(sin(dot(id, vec2(127.1, 311.7))) * 43758.5453);
	float life = fract(TIME * (0.25 + h * 0.3) + h * 7.0);
	vec2 off = vec2(h - 0.5, fract(h * 13.0) - 0.5) * 0.4;
	float br = 0.04 + 0.16 * life;
	float ring = smoothstep(br, br - 0.05, length(f - off)) * step(0.6, h) * (1.0 - smoothstep(0.85, 1.0, life));
	c = mix(c, murk * 0.45, ring * 0.6);
	ALBEDO = c;
	ALPHA = clamp(mask * 0.8, 0.0, 1.0) * fade;
}

shader_type spatial;
// A pool of blood on the floor (Globe). The edge is ragged and slowly
// wobbles. A wizard close by pulls it: the side facing them runs out
// towards them in a tongue. Drinking (`suck`) draws the whole pool along
// that tongue into them, thinning it to nothing as it goes.
render_mode cull_disabled, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

// Where the drinker is, from the pool's middle, flat on the floor.
uniform vec2 to = vec2(0.0, 1.0);
// 0..1: how hard they pull.
uniform float pull = 0.0;
// 0..1: how far it has been drunk.
uniform float suck = 0.0;
uniform float seed = 0.0;

varying float rim;

void vertex() {
	vec2 v = VERTEX.xz;
	float r = length(v);
	vec2 n = r > 0.0001 ? v / r : vec2(0.0);
	float ang = atan(n.y, n.x);
	// A ragged edge, a little different on every pool, slowly breathing.
	float rag = sn_fbm(vec3(cos(ang) * 1.6 + seed, sin(ang) * 1.6, TIME * 0.25));
	r *= 0.75 + 0.55 * rag;
	v = n * r;
	float dist = length(to);
	vec2 d = dist > 0.0001 ? to / dist : vec2(0.0, 1.0);
	// The side facing the drinker runs out towards them.
	float facing = max(dot(n, d), 0.0);
	float tongue = pow(facing, 3.0) * r / 0.3;
	v += d * tongue * pull * 0.55;
	// Drunk: it narrows sideways and runs along the tongue into them.
	vec2 side = vec2(-d.y, d.x);
	float across = dot(v, side);
	float along = dot(v, d);
	across *= 1.0 - 0.85 * suck;
	along = mix(along, dist * (0.4 + 0.6 * facing), suck * suck);
	v = side * across + d * along;
	v *= 1.0 - 0.6 * suck * suck;
	VERTEX.xz = v;
	rim = clamp(length(VERTEX.xz) / 0.35, 0.0, 1.0);
}

void fragment() {
	// Dark, wet and glossy, with a lighter red where it is thin at the edge.
	vec3 deep = vec3(0.16, 0.0, 0.005);
	vec3 thin = vec3(0.42, 0.02, 0.02);
	ALBEDO = mix(deep, thin, smoothstep(0.5, 1.0, rim) * 0.6);
	ROUGHNESS = 0.25;
	SPECULAR = 0.45;
	// A faint glow, so it reads as something to take in the dark.
	EMISSION = vec3(0.12, 0.0, 0.0) * (0.6 + 0.8 * pull);
}

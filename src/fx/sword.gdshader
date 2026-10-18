shader_type spatial;
// An enchanted sword blade: still steel, but the element runs along it.
// Its edges burn (or spark, or frost over) brightest, a line of it runs up
// the ridge, and the more elements are on it the further the element eats
// into the steel between. The element's own look comes from element_look,
// the same as the orbs and bolts, so a fire sword burns like a fire bolt.
render_mode cull_back, shadows_disabled;

#include "res://src/fx/element.gdshaderinc"

uniform int element = 2;
uniform vec4 base : source_color = vec4(1.0, 0.45, 0.1, 1.0);
// 0..1: how much of the queue is on it.
uniform float power = 0.4;
uniform float energy = 1.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	// 0 on the ridge, 1 on the edge.
	float edge = abs(UV.x - 0.5) * 2.0;
	float along = UV.y;
	vec3 p = vec3(lp.x * 6.0, along * 1.6, lp.z * 6.0);
	float light = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec4 look = element_look(element, base.rgb, p, 0.4 + 0.6 * edge, TIME);
	// Where the element shows: the edges, a thread up the ridge, and with
	// more power a creeping wash over the whole blade, broken by noise.
	float wash = sn_fbm(vec3(lp.x * 9.0, along * 3.0 - TIME * 0.8, lp.z * 9.0));
	float m = smoothstep(0.55, 0.95, edge);
	m = max(m, (1.0 - smoothstep(0.0, 0.12, edge)) * 0.7);
	m = max(m, smoothstep(0.85 - power * 0.4, 1.0 - power * 0.35, wash + edge * 0.3) * 0.85);
	// It fades in from the guard, so the hilt end stays steel.
	m *= smoothstep(0.0, 0.18, along);
	vec3 steel = vec3(0.32, 0.34, 0.38);
	ALBEDO = steel * (1.0 - m);
	METALLIC = 0.85 * (1.0 - m);
	ROUGHNESS = 0.3;
	EMISSION = look.rgb * m * energy * (0.8 + 0.4 * light);
}

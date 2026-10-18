shader_type spatial;
// The ground fields that used to be flat discs of one colour: a puddle, a
// frost slick, ice, mud, a steam patch, and any other element's patch.
// Every one has a ragged edge that slowly breathes, and its own life:
// rings rippling over water, rime and cracks on frost, bubbling mud.
// `shock` is the water electrified, white-violet veins crawling over it.
render_mode cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/element.gdshaderinc"

// 4 water, 3 frost, 9 ice, 10 mud, 8 steam; anything else: element_look.
uniform int kind = 4;
uniform vec4 base : source_color = vec4(0.2, 0.4, 0.9, 1.0);
uniform float radius = 2.0;
uniform float seed = 0.0;
uniform float shock = 0.0;
uniform float fade = 1.0;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float ang = atan(q.y, q.x);
	// World-sized coordinates, so a big puddle is not a stretched small one.
	vec2 w = q * radius;
	float rag = sn_fbm(vec3(cos(ang) * 1.7 + seed, sin(ang) * 1.7, TIME * 0.15));
	float edge_r = 0.72 + 0.26 * rag;
	float inside = 1.0 - smoothstep(edge_r - 0.08, edge_r, r);
	float rim = smoothstep(edge_r - 0.25, edge_r - 0.04, r) * inside;
	vec3 c = base.rgb;
	float a = inside;
	float rough = 0.3;
	float metal = 0.0;
	vec3 glow = vec3(0.0);
	if (kind == 4) {
		// Water: dark and still, rings spreading from a few drip points,
		// lighter where it is shallow at the edge.
		float ripple = 0.0;
		for (int i = 0; i < 3; i++) {
			vec2 at = vec2(sn_hash(vec3(float(i), seed, 1.0)), sn_hash(vec3(float(i), seed, 2.0))) * 2.0 - 1.0;
			at *= radius * 0.5;
			float ph = fract(TIME * 0.45 + float(i) * 0.33);
			float d = length(w - at);
			ripple += (1.0 - smoothstep(0.0, 0.06, abs(d - ph * radius * 0.7))) * (1.0 - ph);
		}
		float sheen = sn_fbm(vec3(w * 0.9, TIME * 0.2));
		c = mix(vec3(0.03, 0.08, 0.16), vec3(0.12, 0.3, 0.45), sheen * 0.6 + rim * 0.5);
		c += vec3(0.5, 0.7, 0.85) * ripple * 0.35;
		a *= 0.82;
		rough = 0.04;
		metal = 0.4;
	} else if (kind == 3 || kind == 9) {
		// Frost and ice: pale crystal broken into plates, rime thick at the
		// rim, glints that come and go.
		vec2 cell = el_cells(vec3(w * (kind == 9 ? 1.1 : 1.8), seed)).xy;
		float crack = 1.0 - smoothstep(0.0, 0.05, cell.x);
		float rime = sn_fbm(vec3(w * 3.0, seed));
		c = mix(vec3(0.22, 0.34, 0.46), vec3(0.42, 0.56, 0.68), cell.y * 0.5 + rime * 0.3);
		c = mix(c, vec3(0.7, 0.8, 0.88), max(rim * 0.7, crack * 0.6));
		float glint = step(0.985, sn_hash(vec3(floor(w * 6.0), floor(TIME * 3.0))));
		glow = vec3(0.8, 0.95, 1.0) * glint * 0.8;
		a *= kind == 9 ? 0.85 : 0.7;
		rough = kind == 9 ? 0.05 : 0.35;
	} else if (kind == 10) {
		// Mud: thick and brown, bubbles slowly swelling and popping.
		vec2 cell = el_cells(vec3(w * 1.6, seed + TIME * 0.05)).xy;
		float bubble = smoothstep(0.25, 0.0, cell.x) * (0.5 + 0.5 * sin(TIME * 2.0 + cell.y * 30.0));
		float n = sn_fbm(vec3(w * 1.2, seed));
		c = mix(vec3(0.12, 0.08, 0.04), vec3(0.26, 0.18, 0.1), n);
		c = mix(c, vec3(0.32, 0.24, 0.14), bubble * 0.6);
		a *= 0.95;
		rough = mix(0.7, 0.15, bubble);
	} else if (kind == 8) {
		// Steam: wet, warm stones, a pale shimmer drifting over them.
		float n = sn_fbm(vec3(w * 1.4, TIME * 0.6));
		c = mix(vec3(0.25, 0.27, 0.3), vec3(0.8, 0.82, 0.86), n);
		a *= 0.25 + 0.2 * n;
		rough = 0.1;
	} else {
		// Any other element's patch: its own look, the same as its orb,
		// flattened onto the floor.
		vec4 look = element_look(kind, base.rgb, vec3(w.x * 0.6, 0.0, w.y * 0.6), 0.5 + 0.5 * (1.0 - r), TIME);
		c = look.rgb * 0.6;
		glow = look.rgb * 0.25;
		a *= 0.7;
	}
	if (shock > 0.0) {
		// Lightning running through the water: crawling bright veins.
		vec2 v = el_cells(vec3(w * 1.3, TIME * 3.0)).xy;
		float vein = 1.0 - smoothstep(0.0, 0.06, v.x);
		glow += vec3(0.75, 0.7, 1.0) * vein * shock * 1.6;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	METALLIC = metal;
	EMISSION = glow;
	ALPHA = clamp(a * fade, 0.0, 1.0);
}

// One look per element, shared by the 3D material (element.gdshader) and the
// HUD (element_ui.gdshader), so a fire orb over a wizard's hat, the fire
// socket in their panel and the fire bolt they shoot are the same thing.
// Element ids follow El: 0 life, 1 void, 2 fire, 3 frost, 4 water,
// 5 lightning, 6 earth, 7 air, 8 steam, 9 ice, 10 mud, 11 magma, 12 storm.
// p is a point on the unit sphere in the object's own space, n its normal
// toward the viewer's light, t the time. Returns colour and alpha.

#include "res://src/fx/noise.gdshaderinc"

// Voronoi: x the distance to the nearest cell edge, y the cell's id.
vec2 el_cells(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int z = -1; z <= 1; z++)
	for (int y = -1; y <= 1; y++)
	for (int x = -1; x <= 1; x++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 o = vec3(sn_hash(i + g), sn_hash(i + g + 17.0), sn_hash(i + g + 31.0));
		float d = length(g + o - f);
		if (d < d1) {
			d2 = d1;
			d1 = d;
			id = sn_hash(i + g + 5.0);
		} else if (d < d2) {
			d2 = d;
		}
	}
	return vec2(d2 - d1, id);
}

// light: 0 at the rim, 1 facing the viewer.
vec4 element_look(int el, vec3 el_col, vec3 p, float light, float t) {
	vec3 c = el_col;
	float a = 1.0;
	float rim = 1.0 - light;
	if (el == 2) {
		// Fire: flames licking upward, white-hot heart, red edge.
		float f = sn_fbm(p * 2.6 + vec3(0.0, -t * 2.2, t * 0.4));
		float heat = clamp(f * 1.3 + light * 0.6 - 0.25, 0.0, 1.0);
		c = mix(vec3(0.75, 0.08, 0.02), el_col, smoothstep(0.1, 0.5, heat));
		c = mix(c, vec3(1.0, 0.95, 0.65), smoothstep(0.6, 0.95, heat));
		c *= 1.4;
	} else if (el == 0) {
		// Life: green glow with veins of light pulsing through it.
		vec2 v = el_cells(p * 3.0 + vec3(0.0, t * 0.15, 0.0));
		float vein = 1.0 - smoothstep(0.0, 0.08, v.x);
		float pulse = 0.6 + 0.4 * sin(t * 3.0 + v.y * 6.28);
		c = mix(el_col * 0.55, el_col * 1.2, light);
		c += vec3(0.8, 1.0, 0.55) * vein * pulse;
	} else if (el == 1) {
		// Void: a hole with a violet swirl at its edge and specks of stars.
		float ang = atan(p.y, p.x) + t * 0.8 + length(p.xy) * 3.0;
		float swirl = sn_fbm(vec3(cos(ang) * 2.0, sin(ang) * 2.0, p.z * 2.0 + t * 0.3));
		c = mix(vec3(0.02, 0.0, 0.05), el_col * 1.3, smoothstep(0.35, 0.8, swirl) * (0.3 + rim * 1.2));
		float star = step(0.985, sn_hash(floor(p * 18.0 + vec3(t * 0.5, 0.0, 0.0))));
		c += vec3(0.9, 0.8, 1.0) * star * light;
	} else if (el == 3 || el == 9) {
		// Frost and ice: cut crystal facets, a glint sweeping across.
		vec2 v = el_cells(p * (el == 9 ? 2.2 : 3.2));
		float facet = 0.65 + 0.35 * v.y;
		c = mix(el_col * 0.6, mix(el_col, vec3(1.0), 0.5), facet * light);
		c = mix(c, vec3(1.0), (1.0 - smoothstep(0.0, 0.05, v.x)) * 0.6);
		float glint = pow(max(0.0, sin(p.x * 3.0 + p.y * 2.0 - t * 2.5)), 24.0);
		c += vec3(glint) * 0.8;
		c *= 1.15;
	} else if (el == 4) {
		// Water: deep blue with moving caustic light.
		float w = sn_fbm(p * 3.0 + vec3(t * 0.6, t * 0.4, 0.0));
		float caustic = pow(1.0 - abs(w * 2.0 - 1.0), 6.0);
		c = mix(el_col * 0.45, el_col * 1.1, light);
		c += vec3(0.6, 0.85, 1.0) * caustic * 0.9;
	} else if (el == 5 || el == 12) {
		// Lightning (and storm): crackling veins that flash and move.
		float ph = floor(t * 12.0);
		float v = abs(sn_fbm(p * 3.5 + vec3(ph * 1.7, ph * 0.9, 0.0)) * 2.0 - 1.0);
		float bolt = 1.0 - smoothstep(0.0, 0.07, v);
		vec3 body = el == 12 ? mix(vec3(0.12, 0.14, 0.3), el_col, sn_fbm(p * 2.0 + t * 0.5)) : el_col * (0.55 + 0.35 * light);
		vec3 spark = el == 12 ? vec3(1.0, 0.92, 0.4) : vec3(1.0, 1.0, 0.9);
		c = body + spark * bolt * 1.6;
		if (el == 5) {
			// Lightning sits dark, a deep charged amber, so the white veins
			// stand out from across the room; a yellow glow hugs each vein.
			float thick = 1.0 - smoothstep(0.0, 0.12, v);
			float near = 1.0 - smoothstep(0.0, 0.32, v);
			body = el_col * vec3(0.42, 0.3, 0.12) * (0.55 + 0.6 * light);
			c = body + el_col * near * 0.9 + vec3(1.0, 1.0, 0.95) * thick * 2.2;
		}
	} else if (el == 6) {
		// Earth: rough stone in plates, dark cracks between, lit from above.
		vec2 v = el_cells(p * 2.4);
		float crack = 1.0 - smoothstep(0.0, 0.06, v.x);
		c = el_col * (0.7 + 0.45 * v.y) * (0.45 + 0.75 * light);
		c *= 0.85 + 0.3 * sn_noise(p * 12.0);
		c = mix(c, el_col * 0.18, crack);
	} else if (el == 7 || el == 8) {
		// Air and steam: wisps turning round, see-through between them.
		float ang = atan(p.z, p.x) + t * (el == 7 ? 2.0 : 0.7);
		float w = sn_fbm(vec3(cos(ang) * 1.5, p.y * 2.5 - t * (el == 8 ? 0.6 : 0.0), sin(ang) * 1.5));
		float wisp = smoothstep(0.35, 0.75, w);
		c = mix(el_col * 0.7, mix(el_col, vec3(1.0), 0.6), wisp);
		a = mix(0.35, 1.0, wisp) * (0.5 + 0.5 * light);
	} else if (el == 10) {
		// Mud: dark wet blobs with shiny highlights.
		float m = sn_fbm(p * 3.0 + vec3(0.0, t * 0.2, 0.0));
		c = el_col * (0.5 + 0.6 * m) * (0.5 + 0.6 * light);
		c += vec3(0.9, 0.8, 0.6) * pow(light, 14.0) * smoothstep(0.5, 0.7, m) * 0.6;
	} else if (el == 11) {
		// Magma: black crust drifting over glowing rock.
		vec2 v = el_cells(p * 2.6 + vec3(0.0, t * 0.12, 0.0));
		float glow = 1.0 - smoothstep(0.0, 0.14, v.x);
		float churn = sn_fbm(p * 4.0 + vec3(t * 0.5));
		vec3 crust = vec3(0.12, 0.05, 0.03) * (0.6 + 0.8 * light);
		c = mix(crust, mix(el_col, vec3(1.0, 0.85, 0.4), churn) * 1.5, max(glow, smoothstep(0.7, 0.85, churn)));
	}
	return vec4(c, a);
}

shader_type spatial;
render_mode diffuse_lambert;

// Dungeon floor: two colours mixed by world-space noise, with optional
// flagstone tiles and cracks, darkening toward the room's edge. On top of
// that the room's path, from the entrance to the portal, and in the isles
// biome open water between islands, crossed by plank bridges.
uniform vec3 base_a : source_color = vec3(0.16, 0.17, 0.13);
uniform vec3 base_b : source_color = vec3(0.10, 0.10, 0.09);
uniform float tiles = 0.0;
uniform float tile_size = 1.6;
uniform vec2 half_size = vec2(17.0, 11.0);
uniform float wet = 0.0;

// The path: a polyline in world xz. Style 0 trodden earth, 1 flagstones,
// 2 a worn carpet runner, 3 basalt with glowing seams.
uniform vec2 path_pts[48];
uniform int path_n = 0;
uniform float path_w = 2.4;
uniform int path_style = 0;
uniform vec3 path_a : source_color = vec3(0.3, 0.24, 0.17);
uniform vec3 path_b : source_color = vec3(0.18, 0.14, 0.1);

// Islands as ellipses (x, z, rx, rz); with isle_n > 0 everything else is water.
uniform vec4 isles[10];
uniform int isle_n = 0;
uniform vec3 water_a : source_color = vec3(0.015, 0.05, 0.065);
uniform vec3 water_b : source_color = vec3(0.04, 0.13, 0.14);
uniform vec3 sand : source_color = vec3(0.2, 0.18, 0.13);

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// Distance to the path, the distance along it, and the direction it runs.
vec4 path_info(vec2 p) {
	float best = 1e5;
	float along = 0.0;
	float run = 0.0;
	vec2 dir = vec2(0.0, 1.0);
	for (int i = 0; i < 47; i++) {
		if (i >= path_n - 1) break;
		vec2 a = path_pts[i];
		vec2 b = path_pts[i + 1];
		vec2 ab = b - a;
		float len = length(ab);
		float t = clamp(dot(p - a, ab) / (len * len), 0.0, 1.0);
		float d = length(p - (a + ab * t));
		if (d < best) {
			best = d;
			along = run + t * len;
			dir = ab / len;
		}
		run += len;
	}
	return vec4(best, along, dir);
}

// Signed distance to the nearest island shore: negative on land.
float isle_sdf(vec2 p) {
	float d = 1e5;
	for (int i = 0; i < 10; i++) {
		if (i >= isle_n) break;
		vec4 e = isles[i];
		vec2 q = (p - e.xy) / e.zw;
		d = min(d, (length(q) - 1.0) * min(e.z, e.w));
	}
	return d + (fbm(p * 0.9) - 0.5) * 0.9;
}

// Irregular stones: the distance to the nearest cell edge and the cell id.
vec2 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 17.0));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = hash(i + g + 5.0);
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2(d2 - d1, id);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float n = fbm(p * 0.35);
	float fine = fbm(p * 2.5);
	vec3 col = mix(base_a, base_b, smoothstep(0.3, 0.7, n));
	col *= 0.85 + 0.3 * fine;
	float rough = mix(0.95, 0.25, wet * smoothstep(0.4, 0.6, fbm(p * 0.6 + 3.0)));
	vec3 glow = vec3(0.0);
	if (tiles > 0.5) {
		vec2 t = p / tile_size;
		// Offset every other row like laid flagstones.
		t.x += step(1.0, mod(floor(t.y), 2.0)) * 0.5;
		vec2 f = fract(t);
		vec2 id = floor(t);
		float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		float grout = smoothstep(0.0, 0.05, edge);
		col *= mix(0.35, 1.0, grout);
		col *= 0.8 + 0.4 * hash(id);
	}
	float crack = smoothstep(0.48, 0.5, fbm(p * 1.1 + 7.0)) * smoothstep(0.52, 0.5, fbm(p * 1.1 + 7.0));
	col *= 1.0 - crack * 0.6;

	// Land and water.
	float shore = isle_n > 0 ? isle_sdf(p) : -1e5;
	if (isle_n > 0) {
		// Sand and moss toward the shore.
		col = mix(col, sand * (0.8 + 0.4 * fine), smoothstep(-1.2, -0.1, shore));
	}

	vec4 pi = path_info(p);
	float half_w = path_w * 0.5 + (fbm(p * 1.7) - 0.5) * 0.5;
	float on_path = path_n > 1 ? 1.0 - smoothstep(half_w - 0.25, half_w + 0.1, pi.x) : 0.0;
	bool bridge = isle_n > 0 && shore > -0.2;

	if (isle_n > 0 && shore > 0.0 && !(bridge && pi.x < path_w * 0.5 + 0.1)) {
		// Open water: two tints moving against each other, ripples, a band
		// of foam along the shore, deeper and darker further out.
		float w1 = fbm(p * 0.5 + vec2(TIME * 0.05, TIME * 0.03));
		float w2 = fbm(p * 1.6 - vec2(TIME * 0.11, -TIME * 0.07));
		vec3 wc = mix(water_a, water_b, w1 * 0.8 + w2 * 0.4);
		wc *= mix(1.0, 0.55, smoothstep(0.5, 6.0, shore));
		float foam = (1.0 - smoothstep(0.0, 0.45, shore)) * (0.55 + 0.45 * sin(shore * 12.0 - TIME * 2.0));
		foam += smoothstep(0.72, 0.8, w2) * 0.25;
		wc = mix(wc, vec3(0.42, 0.52, 0.52), clamp(foam, 0.0, 1.0) * 0.55);
		col = wc;
		rough = 0.08;
		glow = water_b * 0.12 * (0.6 + w2);
	} else if (on_path > 0.0) {
		vec3 pc;
		if (bridge) {
			// Planks laid across the way, with gaps and two rails.
			float along = pi.y / 0.42;
			float plank = fract(along);
			float pid = floor(along);
			pc = mix(vec3(0.33, 0.23, 0.14), vec3(0.22, 0.15, 0.09), hash(vec2(pid, 3.0)));
			pc *= 0.8 + 0.35 * fbm(vec2(pi.x * 6.0, pid * 3.0));
			pc *= mix(0.25, 1.0, smoothstep(0.0, 0.08, plank) * smoothstep(1.0, 0.92, plank));
			float rail = smoothstep(path_w * 0.5 - 0.22, path_w * 0.5 - 0.12, pi.x);
			pc = mix(pc, vec3(0.2, 0.13, 0.08), rail);
			on_path = step(pi.x, path_w * 0.5);
		} else if (path_style == 1) {
			vec2 c = cells(p * 1.3);
			pc = mix(path_a, path_b, c.y) * (0.85 + 0.3 * fine);
			pc *= mix(0.3, 1.0, smoothstep(0.02, 0.12, c.x));
		} else if (path_style == 2) {
			// A long red runner with a gold border, threadbare in places.
			float edge = smoothstep(half_w - 0.45, half_w - 0.35, pi.x);
			pc = mix(path_a, vec3(0.3, 0.22, 0.09), edge * (1.0 - smoothstep(half_w - 0.2, half_w - 0.1, pi.x)));
			pc *= 0.75 + 0.4 * fbm(p * 4.0);
			pc = mix(pc, col, smoothstep(0.62, 0.7, fbm(p * 0.8 + 11.0)) * 0.8);
		} else if (path_style == 3) {
			vec2 c = cells(p * 1.1);
			pc = mix(path_a, path_b, c.y) * (0.8 + 0.3 * fine);
			float seam = 1.0 - smoothstep(0.0, 0.06, c.x);
			pc = mix(pc, vec3(1.0, 0.35, 0.05), seam);
			glow = vec3(1.0, 0.3, 0.04) * seam * on_path * (0.5 + 0.25 * sin(TIME * 1.5 + p.x));
		} else {
			// Trodden earth: worn smooth in the middle, pebbles at the edge.
			float mid = 1.0 - smoothstep(0.0, half_w, pi.x);
			pc = mix(path_b, path_a, mid * 0.6 + 0.4 * fine);
			vec2 c = cells(p * 3.5);
			float pebble = step(0.78, c.y) * smoothstep(0.05, 0.18, c.x) * smoothstep(half_w * 0.3, half_w * 0.8, pi.x);
			pc = mix(pc, path_a * 1.35, pebble * 0.7);
		}
		col = mix(col, pc, on_path);
	}

	vec2 e = abs(p) / half_size;
	float edge_dark = smoothstep(0.75, 1.05, max(e.x, e.y));
	col *= 1.0 - edge_dark * 0.6;
	ALBEDO = col * 1.7;
	ROUGHNESS = rough;
	SPECULAR = shore > 0.0 ? 0.6 : 0.15;
	EMISSION = glow;
}

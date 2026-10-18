shader_type spatial;
render_mode diffuse_lambert;

// Dungeon floor: two colours mixed by world-space noise, with optional
// flagstone tiles and cracks, tinted zone by zone along the level and
// darkening toward its edge. On top of that the level's path, laid stone
// floors where the fights gather, and in the isles biome open water between
// islands, crossed by plank bridges. Each floor chunk is handed only the
// bits of path, islands and stone floors that reach it.
uniform vec3 base_a : source_color = vec3(0.16, 0.17, 0.13);
uniform vec3 base_b : source_color = vec3(0.10, 0.10, 0.09);
uniform float tiles = 0.0;
uniform float tile_size = 1.6;
uniform vec2 half_size = vec2(17.0, 11.0);
uniform float wet = 0.0;

// The zones of the level: tint0 before zone_z.x (going down z), tint1 up
// to zone_z.y, tint2 after, blended over a few metres.
uniform vec3 tint0 = vec3(1.0);
uniform vec3 tint1 = vec3(1.0);
uniform vec3 tint2 = vec3(1.0);
uniform vec2 zone_z = vec2(-1e5);

// The path near this chunk: segments a.xy to b.zw, and how far along the
// whole path each one starts. Style 0 trodden earth, 1 flagstones, 2 a worn
// carpet runner, 3 basalt with glowing seams.
uniform vec4 segs[32];
uniform float seg_run[32];
uniform int seg_n = 0;
uniform float path_w = 2.4;
uniform int path_style = 0;
uniform vec3 path_a : source_color = vec3(0.3, 0.24, 0.17);
uniform vec3 path_b : source_color = vec3(0.18, 0.14, 0.1);

// Islands as ellipses (x, z, rx, rz); with water on everything else is water.
uniform vec4 isles[16];
uniform int isle_n = 0;
uniform bool water = false;
// Laid stone floors (x, z, r).
uniform vec3 plazas[4];
uniform int plaza_n = 0;
uniform vec3 water_a : source_color = vec3(0.015, 0.05, 0.065);
uniform vec3 water_b : source_color = vec3(0.04, 0.13, 0.14);
uniform vec3 sand : source_color = vec3(0.2, 0.18, 0.13);
// A level that follows its path: how far each point is outside the walkable
// band, in metres (0.5 is the wall, 1/16 m per step), over bounds_rect
// (origin, size). Beyond the walls the ground darkens away.
uniform sampler2D bounds : filter_linear, repeat_disable;
uniform vec4 bounds_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool bounded = false;

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
	vec2 dir = vec2(0.0, 1.0);
	for (int i = 0; i < 32; i++) {
		if (i >= seg_n) break;
		vec2 a = segs[i].xy;
		vec2 ab = segs[i].zw - a;
		float len = max(length(ab), 0.001);
		float t = clamp(dot(p - a, ab) / (len * len), 0.0, 1.0);
		float d = length(p - (a + ab * t));
		if (d < best) {
			best = d;
			along = seg_run[i] + t * len;
			dir = ab / len;
		}
	}
	return vec4(best, along, dir);
}

// Signed distance to the nearest island shore: negative on land.
float isle_sdf(vec2 p) {
	float d = 1e5;
	for (int i = 0; i < 16; i++) {
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
	vec3 col;
	if (tiles > 0.5) {
		col = mix(base_a, base_b, smoothstep(0.3, 0.7, n));
		col *= 0.85 + 0.3 * fine;
	} else {
		// Open ground: wide soft patches of moss over soil that fade into
		// each other, fine grain, a scatter of small stones.
		float patch = fbm(p * 0.13 + 4.0) * 0.75 + fbm(p * 0.5) * 0.25;
		col = mix(base_b, base_a, smoothstep(0.32, 0.68, patch));
		col *= 0.9 + 0.2 * fine;
		col *= 0.93 + 0.14 * noise(p * 13.0);
		float tuft = smoothstep(0.62, 0.8, fbm(p * 3.1 + 9.0)) * smoothstep(0.45, 0.65, patch);
		col = mix(col, base_a * 1.35, tuft * 0.5);
		vec2 st = cells(p * 3.2);
		float stone = step(0.93, st.y) * smoothstep(0.1, 0.3, st.x);
		col = mix(col, mix(base_b, vec3(0.2, 0.2, 0.19), 0.5) * (0.85 + 0.3 * fine), stone * 0.45);
	}
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
	// The zone this bit of ground is in.
	float k1 = smoothstep(zone_z.x + 6.0, zone_z.x - 6.0, p.y);
	float k2 = smoothstep(zone_z.y + 6.0, zone_z.y - 6.0, p.y);
	col *= mix(mix(tint0, tint1, k1), tint2, k2);
	// Hairline cracks, only in laid stone.
	float crack = smoothstep(0.48, 0.5, fbm(p * 1.1 + 7.0)) * smoothstep(0.52, 0.5, fbm(p * 1.1 + 7.0));
	col *= 1.0 - crack * 0.35 * tiles;

	// Land and water.
	float shore = water ? isle_sdf(p) : -1e5;
	if (water) {
		// Sand and moss toward the shore.
		col = mix(col, sand * (0.8 + 0.4 * fine), smoothstep(-1.2, -0.1, shore));
	}

	// Laid stone where the fights gather: big worn flags, grass and grit
	// creeping in at the ragged edge.
	float pz = 1e5;
	for (int i = 0; i < 4; i++) {
		if (i >= plaza_n) break;
		pz = min(pz, length(p - plazas[i].xy) - plazas[i].z);
	}
	pz += (fbm(p * 0.7 + 5.0) - 0.5) * 1.6;
	if (pz < 0.0 && shore < 0.0) {
		vec2 t = p / 1.5;
		t.x += step(1.0, mod(floor(t.y), 2.0)) * 0.5;
		vec2 f = fract(t);
		float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		vec3 flag = mix(path_a, path_b, hash(floor(t))) * (0.8 + 0.35 * fine);
		flag = mix(flag, vec3(0.2, 0.2, 0.19) * (0.8 + 0.4 * fine), 0.35);
		flag *= mix(0.4, 1.0, smoothstep(0.0, 0.06, edge));
		float worn = smoothstep(-1.4, 0.0, pz) * smoothstep(0.35, 0.7, fbm(p * 1.3));
		col = mix(flag, col, worn);
	}

	vec4 pi = path_info(p);
	float half_w = path_w * 0.5 + (fbm(p * 1.7) - 0.5) * 0.5;
	float on_path = seg_n > 0 ? 1.0 - smoothstep(half_w - 0.25, half_w + 0.1, pi.x) : 0.0;
	bool bridge = water && shore > -0.2;

	if (water && shore > 0.0 && !(bridge && pi.x < path_w * 0.5 + 0.1)) {
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
	if (bounded) {
		float sd = (texture(bounds, (p - bounds_rect.xy) / bounds_rect.zw).r - 0.5) * 16.0;
		// Shadowed along the foot of the walls, dark rubble beyond them.
		col *= 1.0 - 0.3 * smoothstep(-2.5, 0.3, sd);
		col = mix(col, base_b * (0.75 + 0.4 * fine), smoothstep(0.0, 1.5, sd));
		// Only gently darker out there: land you cannot reach, not a void.
		edge_dark = smoothstep(1.0, 14.0, sd) * 0.75;
		// A faint moonlit glow, so ground nobody lights still reads as ground.
		glow += base_b * (0.6 + 0.5 * fine) * 0.22 * smoothstep(0.5, 3.0, sd);
	}
	col *= 1.0 - min(edge_dark, 1.0) * 0.6 - max(edge_dark - 1.0, 0.0) * 0.8;
	ALBEDO = col * 1.7;
	ROUGHNESS = rough;
	SPECULAR = shore > 0.0 ? 0.6 : 0.15;
	EMISSION = glow;
}

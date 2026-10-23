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
// Square flagged floors in a dungeon's square rooms.
uniform bool square_plazas = false;
uniform vec3 water_a : source_color = vec3(0.015, 0.05, 0.065);
uniform vec3 water_b : source_color = vec3(0.04, 0.13, 0.14);
uniform vec3 sand : source_color = vec3(0.2, 0.18, 0.13);
// A level that follows its path: how far each point is outside the walkable
// band, in metres (0 is the wall), one texel a metre, over bounds_rect
// (origin, size). Beyond the walls the ground darkens away.
uniform sampler2D bounds : filter_linear, repeat_disable;
uniform vec4 bounds_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool bounded = false;
// The pit: beyond the walls lies a sea of lava, crusted, glowing in its seams.
uniform float outside_lava = 0.0;

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Quintic, so the lattice never shows as creases in the bump.
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		// Turned each octave, so no square grid lines up between them.
		p = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 2.03;
		a *= 0.5;
	}
	return v;
}

// The distance field at [param p], smooth: a cubic B-spline over the 1 m
// cells from four bilinear taps. Read plainly, each cell was its own flat
// slope and the shading by the walls showed the floor as tilted squares
// with seams between them (Joep).
float bounds_at(vec2 p) {
	vec2 sz = bounds_rect.zw;
	vec2 c = (p - bounds_rect.xy) - 0.5;
	vec2 i = floor(c);
	vec2 f = c - i;
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;
	vec2 w0 = (1.0 - 3.0 * f + 3.0 * f2 - f3) / 6.0;
	vec2 w1 = (4.0 - 6.0 * f2 + 3.0 * f3) / 6.0;
	vec2 w2 = (1.0 + 3.0 * f + 3.0 * f2 - 3.0 * f3) / 6.0;
	vec2 w3 = f3 / 6.0;
	vec2 g0 = w0 + w1;
	vec2 g1 = w2 + w3;
	vec2 h0 = (i - 1.0 + w1 / g0 + 0.5) / sz;
	vec2 h1 = (i + 1.0 + w3 / g1 + 0.5) / sz;
	float v = g0.y * (g0.x * texture(bounds, vec2(h0.x, h0.y)).r + g1.x * texture(bounds, vec2(h1.x, h0.y)).r)
		+ g1.y * (g0.x * texture(bounds, vec2(h0.x, h1.y)).r + g1.x * texture(bounds, vec2(h1.x, h1.y)).r);
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

// Small round pebbles, one in some cells of a grid, each off centre and
// its own size, soft at the rim: 1 on a pebble, 0 between.
float pebbles(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float best = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			float keep = hash(i + g + 31.0);
			if (keep > 0.35) continue;
			vec2 o = vec2(hash(i + g + 3.0), hash(i + g + 41.0)) * 0.6 + 0.2;
			float r = 0.12 + 0.14 * hash(i + g + 9.0);
			vec2 d = (g + o - f) * vec2(1.0, 1.0 + 0.5 * hash(i + g + 13.0));
			best = max(best, 1.0 - smoothstep(r * 0.6, r, length(d)));
		}
	}
	return best;
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
	// How high each bit of ground stands, for the light to catch (bump
	// mapped at the end): grain everywhere, stones and flags proud of the
	// grout and gaps between them.
	float h = fine * 0.5 + n * 0.3;
	if (tiles > 0.5) {
		col = mix(base_a, base_b, smoothstep(0.3, 0.7, n));
		col *= 0.85 + 0.3 * fine;
	} else {
		// Open ground: wide soft patches of moss over soil that fade into
		// each other, fine grain, a scatter of small stones.
		float patch = fbm(p * 0.13 + 4.0) * 0.75 + fbm(p * 0.5) * 0.25;
		col = mix(base_b, base_a, smoothstep(0.32, 0.68, patch));
		col *= 0.9 + 0.2 * fine;
		col *= 0.93 + 0.14 * noise(mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 13.0);
		float tuft = smoothstep(0.62, 0.8, fbm(p * 3.1 + 9.0)) * smoothstep(0.45, 0.65, patch);
		col = mix(col, base_a * 1.35, tuft * 0.5);
		// No scattered pebbles: as flat polygons they read as confetti.
		h += tuft * 0.4 + fbm(p * 9.0 + 3.0) * 0.3;
	}
	float rough = mix(0.95, 0.25, wet * smoothstep(0.4, 0.6, fbm(p * 0.6 + 3.0)));
	vec3 glow = vec3(0.0);
	float planks = 0.0;
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
		h += grout * 1.5 + hash(id) * 0.3;
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
		vec2 dq = abs(p - plazas[i].xy);
		pz = min(pz, (square_plazas ? max(dq.x, dq.y) : length(dq)) - plazas[i].z);
	}
	pz += (fbm(p * 0.7 + 5.0) - 0.5) * (square_plazas ? 0.7 : 1.6);
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
		h = mix(h + smoothstep(0.0, 0.06, edge) * 1.5, h, worn);
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
		h = w2 * 0.4;
		glow = water_b * 0.12 * (0.6 + w2);
	} else if (on_path > 0.0) {
		vec3 pc;
		if (bridge) {
			// Planks laid across the way, with gaps and two rails.
			float along = pi.y / 0.42;
			float plank = fract(along);
			float pid = floor(along);
			pc = mix(vec3(0.11, 0.08, 0.05), vec3(0.065, 0.047, 0.03), hash(vec2(pid, 3.0)));
			pc *= 0.8 + 0.35 * fbm(vec2(pi.x * 6.0, pid * 3.0));
			pc *= mix(0.25, 1.0, smoothstep(0.0, 0.08, plank) * smoothstep(1.0, 0.92, plank));
			float rail = smoothstep(path_w * 0.5 - 0.22, path_w * 0.5 - 0.12, pi.x);
			pc = mix(pc, vec3(0.2, 0.13, 0.08), rail);
			h = smoothstep(0.0, 0.08, plank) * smoothstep(1.0, 0.92, plank) * 1.4 + rail;
			on_path = step(pi.x, path_w * 0.5);
			// Dry old wood, not shining like the water under it.
			rough = mix(rough, 0.9, on_path);
			planks = on_path;
		} else if (path_style == 1) {
			vec2 c = cells(p * 1.3);
			pc = mix(path_a, path_b, c.y) * (0.85 + 0.3 * fine);
			pc *= mix(0.3, 1.0, smoothstep(0.02, 0.12, c.x));
			h = mix(h, fine * 0.4 + smoothstep(0.02, 0.12, c.x) * 1.6, on_path);
		} else if (path_style == 2) {
			// A long red runner with a gold border, threadbare in places.
			float edge = smoothstep(half_w - 0.45, half_w - 0.35, pi.x);
			pc = mix(path_a, vec3(0.3, 0.22, 0.09), edge * (1.0 - smoothstep(half_w - 0.2, half_w - 0.1, pi.x)));
			pc *= 0.75 + 0.4 * fbm(p * 4.0);
			pc = mix(pc, col, smoothstep(0.62, 0.7, fbm(p * 0.8 + 11.0)) * 0.8);
		} else if (path_style == 3) {
			vec2 c = cells(p * 1.1);
			pc = mix(path_a, path_b, c.y) * (0.8 + 0.3 * fine);
			// Most seams are just dark cracks; heat wells up through some of
			// them in patches that slowly shift, wider where it is hottest.
			float heat = smoothstep(0.42, 0.72, fbm(p * 0.45 + vec2(TIME * 0.03, 3.0)));
			float seam = 1.0 - smoothstep(0.0, 0.025 + 0.035 * heat, c.x);
			pc = mix(pc, vec3(0.03, 0.02, 0.02), seam);
			h = mix(h, fine * 0.5 + (1.0 - seam) * 1.5, on_path);
			float core = 1.0 - smoothstep(0.0, 0.012 + 0.02 * heat, c.x);
			glow = vec3(1.0, 0.28, 0.03) * (seam * 0.35 + core) * heat * on_path * (0.45 + 0.2 * sin(TIME * 1.5 + p.x));
		} else {
			// Trodden earth: worn smooth in the middle, pebbles at the edge.
			float mid = 1.0 - smoothstep(0.0, half_w, pi.x);
			pc = mix(path_b, path_a, mid * 0.6 + 0.4 * fine);
			// Round soft-edged pebbles, not flat polygons (those read as
			// shards with hard straight edges, Joep).
			float pebble = pebbles(p * 3.0) * smoothstep(half_w * 0.3, half_w * 0.8, pi.x);
			pc = mix(pc, path_a * 1.1, pebble * 0.4);
			h = mix(h, fine * 0.3 + pebble * 0.6, on_path);
		}
		col = mix(col, pc, on_path);
	}

	vec2 e = abs(p) / half_size;
	float edge_dark = smoothstep(0.75, 1.05, max(e.x, e.y));
	if (bounded) {
		float sd = bounds_at(p);
		// Shadowed along the foot of the walls, dark rubble beyond them.
		col *= 1.0 - 0.3 * smoothstep(-2.5, 0.3, sd);
		col = mix(col, base_b * (0.75 + 0.4 * fine), smoothstep(0.0, 1.5, sd));
		// Only gently darker out there: land you cannot reach, not a void.
		edge_dark = smoothstep(1.0, 14.0, sd) * 0.75;
		// A faint moonlit glow, so ground nobody lights still reads as ground.
		glow += base_b * (0.6 + 0.5 * fine) * 0.22 * smoothstep(0.5, 3.0, sd);
		if (outside_lava > 0.5) {
			float out_k = smoothstep(0.6, 2.2, sd);
			float n = fbm(p * 0.35 + vec2(0.0, TIME * 0.02));
			float seam = pow(1.0 - abs(n * 2.0 - 1.0), 6.0);
			float pool = smoothstep(0.62, 0.8, fbm(p * 0.12 + 9.0));
			float heat = clamp(seam * 0.8 + pool, 0.0, 1.0) * (0.75 + 0.25 * sin(TIME * 1.3 + p.x * 0.4 + p.y * 0.3));
			col = mix(col, vec3(0.03, 0.015, 0.012) * (0.7 + 0.6 * fine), out_k);
			glow += vec3(1.0, 0.3, 0.04) * heat * out_k * 0.9;
			edge_dark *= 1.0 - out_k * 0.7;
		}
	}
	col *= 1.0 - min(edge_dark, 1.0) * 0.6 - max(edge_dark - 1.0, 0.0) * 0.8;
	// The dark comes from the light, not the paint: brighter ground the
	// wizards' light and spells can show (Joep: less cartoony).
	ALBEDO = col * 2.4;
	// Bump mapping from the height above, by screen-space derivatives.
	float bump = 0.035;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhx = dFdxFine(h) * bump;
	float dhy = dFdyFine(h) * bump;
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	NORMAL = normalize(abs(det) * NORMAL - grad);
	ROUGHNESS = rough;
	SPECULAR = mix(shore > 0.0 ? 0.6 : 0.15, 0.2, planks);
	EMISSION = glow;
}

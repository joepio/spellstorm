shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Dungeon floor: two colours mixed by world-space noise, with optional
// flagstone tiles and cracks, darkening toward the room's edge.
uniform vec3 base_a : source_color = vec3(0.16, 0.17, 0.13);
uniform vec3 base_b : source_color = vec3(0.10, 0.10, 0.09);
uniform float tiles = 0.0;
uniform float tile_size = 1.6;
uniform vec2 half_size = vec2(17.0, 11.0);
uniform float wet = 0.0;

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

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float n = fbm(p * 0.35);
	float fine = fbm(p * 2.5);
	vec3 col = mix(base_a, base_b, smoothstep(0.3, 0.7, n));
	col *= 0.85 + 0.3 * fine;
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
	vec2 e = abs(p) / half_size;
	float edge_dark = smoothstep(0.75, 1.05, max(e.x, e.y));
	col *= 1.0 - edge_dark * 0.6;
	ALBEDO = col * 1.7;
	ROUGHNESS = mix(0.95, 0.25, wet * smoothstep(0.4, 0.6, fbm(p * 0.6 + 3.0)));
}

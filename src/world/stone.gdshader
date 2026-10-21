shader_type spatial;
// Rough stone for walls, rocks, pillars and graves: noise laid on in world
// space from all three sides (no UVs needed, so code-built blocks just work),
// pitted and chipped by bump mapping, darker in its cracks, with moss or
// soot settling on the tops. Replaces the flat paint that read as cartoony.
render_mode diffuse_burley;

uniform vec3 color : source_color = vec3(0.3, 0.29, 0.27);
uniform float scale = 1.6;
uniform float bump = 0.06;
uniform vec3 moss : source_color = vec3(0.12, 0.16, 0.08);
uniform float moss_amount = 0.0;
uniform float rough = 0.9;

// A broken piece carries the place it was cut from (Art.pin_stone), so its
// grain moves with it as it falls instead of sliding through it.
instance uniform float pinned = 0.0;
instance uniform vec3 pin_x = vec3(1.0, 0.0, 0.0);
instance uniform vec3 pin_y = vec3(0.0, 1.0, 0.0);
instance uniform vec3 pin_z = vec3(0.0, 0.0, 1.0);
instance uniform vec3 pin_o = vec3(0.0);

varying vec3 wpos;
varying vec3 wnrm;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm3(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	mat4 at = MODEL_MATRIX;
	if (pinned > 0.5) {
		at = mat4(vec4(pin_x, 0.0), vec4(pin_y, 0.0), vec4(pin_z, 0.0), vec4(pin_o, 1.0));
	}
	wpos = (at * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((at * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 p = wpos * scale;
	float big = fbm3(p * 0.35);
	float grain = fbm3(p * 3.0);
	// Cracks: thin lines where a stretched noise crosses its middle.
	float c = fbm3(p * vec3(0.9, 1.8, 0.9) + 4.0);
	float crack = 1.0 - smoothstep(0.0, 0.025, abs(c - 0.5));
	float h = big * 0.6 + grain * 0.4 - crack * 0.3;
	vec3 col = color * (0.65 + 0.6 * big) * (0.85 + 0.3 * grain);
	col *= 1.0 - crack * 0.25;
	// Settles on what faces up, patchy.
	float up = smoothstep(0.35, 0.85, wnrm.y);
	float m = up * smoothstep(0.45, 0.65, fbm3(p * 0.8 + 7.0)) * moss_amount;
	col = mix(col, moss * (0.7 + 0.5 * grain), m);
	ALBEDO = col;
	ROUGHNESS = rough - grain * 0.15;
	SPECULAR = 0.25;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhx = dFdx(h) * bump;
	float dhy = dFdy(h) * bump;
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	NORMAL = normalize(abs(det) * NORMAL - grad);
}

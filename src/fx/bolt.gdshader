shader_type spatial;
// A staff bolt: a glowing core inside a flickering rim. Noise scrolls along
// the bolt, so fire licks, water wobbles and lightning crackles; how much is
// set per element by `flicker` and `speed`.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 core : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform vec4 edge : source_color = vec4(1.0, 0.3, 0.05, 1.0);
uniform float flicker = 1.0;
uniform float speed = 8.0;
uniform float seed = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fragment() {
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.4);
	float n = noise(lp * 7.0 + vec3(0.0, 0.0, TIME * speed) + seed);
	float n2 = noise(lp * 15.0 - vec3(0.0, TIME * speed * 0.7, 0.0) + seed * 2.0);
	float k = mix(1.0, 0.25 + n * 0.75 + n2 * 0.5, flicker);
	float inner = 1.0 - rim;
	vec3 c = mix(edge.rgb, core.rgb, smoothstep(0.25, 0.95, inner * k));
	ALBEDO = c * (0.9 + 1.6 * k);
	ALPHA = clamp((0.3 + inner) * k, 0.0, 1.0) * edge.a;
}

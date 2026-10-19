shader_type spatial;
// Worn wool and felt for robes and hats: a fine weave, uneven dye and
// grime, soft folds caught by bump mapping, and a faint sheen at the edges
// like real cloth. Laid on in the model's own space, so it moves with it.
render_mode diffuse_burley, cull_disabled;

uniform vec3 color : source_color = vec3(0.5, 0.15, 0.12);
uniform float weave = 90.0;
uniform float bump = 0.012;

varying vec3 opos;
varying vec3 tint;

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

void vertex() {
	opos = VERTEX;
	// Vertex colours (the robe's skirt and hem) are sRGB; white without any.
	tint = pow(COLOR.rgb, vec3(2.2));
}

void fragment() {
	float dye = vnoise(opos * 6.0) * 0.6 + vnoise(opos * 17.0) * 0.4;
	// Threads both ways, faded out before they get small enough to shimmer.
	float w = sin(opos.y * weave) * sin((opos.x + opos.z) * weave);
	w *= 1.0 - smoothstep(0.15, 0.5, fwidth(opos.y * weave));
	float grime = smoothstep(0.55, 0.8, vnoise(opos * 3.0 + 11.0));
	vec3 col = color * tint * (0.78 + 0.35 * dye) * (0.97 + 0.03 * w);
	col = mix(col, col * 0.55, grime * 0.5);
	ALBEDO = col;
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
	// Wool scatters light at grazing angles.
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = col * rim * 0.15;
	float h = dye * 0.6 + w * 0.15;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dFdx(h) * bump * r1 + dFdy(h) * bump * r2);
	NORMAL = normalize(abs(det) * NORMAL - grad);
}

shader_type spatial;
// The Black Hole cataclysm (Joep: smooth, turning, as if it pulls things
// in, and warping what is behind it). A camera-facing disc that redraws the
// scene behind it bent round its middle: the closer in, the more the view
// is squeezed and twisted, down to a soft black core with a thin violet
// ring of light round it, and spiral arms of dust flowing inward.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, depth_test_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform vec4 color : source_color = vec4(0.7, 0.2, 0.95, 1.0);
// 0..1: how far it has opened (it grows in and collapses at the end).
uniform float open = 1.0;
uniform float core = 0.26;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, length(MODEL_MATRIX[2].xyz), 0), vec4(0, 0, 0, 1));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

mat2 rot(float a) {
	return mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	// How strongly the hole bends this point: nothing at the rim, all at the core.
	float fall = smoothstep(1.0, 0.15, r) * open;
	// Where to look in the scene behind: further out and turned, so the
	// surroundings are drawn in and wound round the middle.
	vec2 src = rot(fall * fall * 2.2) * q * (1.0 + 0.9 * fall * fall);
	// The quad's own scale on screen, to turn that into a screen offset.
	vec2 per = vec2(dFdx(SCREEN_UV.x) / max(abs(dFdx(UV.x)) * 2.0, 1e-6) * sign(dFdx(UV.x)),
		dFdy(SCREEN_UV.y) / max(abs(dFdy(UV.y)) * 2.0, 1e-6) * sign(dFdy(UV.y)));
	vec3 bg = textureLod(screen, SCREEN_UV + (src - q) * per, 0.0).rgb;
	// Spiral arms flowing inward: the noise is wound tighter towards the
	// middle and turns as a whole; two copies of it, each zooming in and
	// fading in and out half a beat apart, make the dust flow inward
	// forever without ever winding up into rings.
	vec2 p = rot(2.4 / (r + 0.3) + TIME * 0.9) * q;
	float arms = 0.0;
	for (int i = 0; i < 2; i++) {
		float ph = fract(TIME * 0.22 + float(i) * 0.5);
		float w = 1.0 - abs(2.0 * ph - 1.0);
		vec2 z = p * 2.6 * exp2(ph) * vec2(1.0, 0.45) + float(i) * 7.3;
		arms += w * (vnoise(z) * 0.65 + vnoise(z * 2.1 + 3.0) * 0.35);
	}
	arms = smoothstep(0.42, 0.85, arms) * smoothstep(1.0, 0.45, r) * smoothstep(core * open, core * open + 0.2, r);
	vec3 col = bg * (1.0 - 0.55 * fall) + color.rgb * arms * 1.2 * open;
	// The ring of light hugging the core, and the core itself: soft, not cut out.
	float h = core * open;
	float ring = exp(-pow((r - h * 1.12) / 0.035, 2.0)) * open;
	col += mix(color.rgb, vec3(1.0, 0.85, 1.0), 0.4) * ring * 1.6;
	col *= smoothstep(h * 0.75, h * 1.05, r);
	ALBEDO = col;
	// Blends into the untouched scene at the rim.
	ALPHA = smoothstep(1.0, 0.8, r);
}

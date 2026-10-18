shader_type spatial;
// Where a charging spell will land: a faint circle of runes turning on the
// floor and a soft glow welling up inside it, brighter as the spell fills.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.6, 0.9, 0.3, 1.0);
uniform float charge = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float spin = TIME * 0.6;
	// The outer circle and a thinner one inside it.
	float ring = 1.0 - smoothstep(0.0, 0.035, abs(r - 0.9));
	float inner = (1.0 - smoothstep(0.0, 0.02, abs(r - 0.72))) * 0.6;
	// Rune marks between the two circles, turning slowly.
	float marks = step(0.55, fract((ang + spin) * 12.0 / 6.2832)) * step(0.75, r) * step(r, 0.87);
	marks *= 0.5 + 0.5 * step(0.5, fract((ang + spin) * 3.0 / 6.2832));
	// A soft glow welling up from the middle.
	float well = (1.0 - smoothstep(0.0, 0.8, r)) * (0.35 + 0.15 * sin(TIME * 4.0 - r * 6.0));
	float fill = 0.25 + 0.75 * charge;
	float a = (ring * 0.9 + inner + marks * 0.7) * fill + well * charge;
	a *= 1.0 - smoothstep(0.95, 1.0, r);
	ALBEDO = mix(color.rgb, vec3(1.0), 0.25 * ring) * a * 0.65;
	ALPHA = clamp(a, 0.0, 1.0);
}

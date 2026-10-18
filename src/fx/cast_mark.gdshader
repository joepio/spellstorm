shader_type spatial;
// Where a charging spell will land: a faint circle of runes turning on the
// floor and a soft glow welling up inside it, brighter as the spell fills.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.6, 0.9, 0.3, 1.0);
uniform float charge = 0.0;
// 1 for a lane: a spell that rolls forward (the tidal wave). The rectangle
// of floor it will sweep, edged with runes, with chevrons flowing the way
// it goes.
uniform float lane = 0.0;
// The lane's length over its width, so the chevrons keep their shape.
uniform float aspect = 2.0;

void fragment() {
	if (lane > 0.5) {
		vec2 q = UV * 2.0 - 1.0;
		// Distance in from the long sides and the ends.
		float side = 1.0 - abs(q.x);
		float end = 1.0 - abs(q.y);
		float edge = (1.0 - smoothstep(0.0, 0.05, side)) * step(0.0, end);
		float edge2 = (1.0 - smoothstep(0.0, 0.025, abs(side - 0.12))) * 0.55;
		float cap = (1.0 - smoothstep(0.0, 0.03 / aspect * 2.0, end)) * 0.8;
		// Rune ticks along both sides, running forward.
		float along = UV.y * aspect * 4.0 + TIME * 0.8;
		float ticks = step(0.6, fract(along)) * step(0.03, side) * step(side, 0.1);
		// Chevrons flowing forward down the middle, like the water will.
		float cy = UV.y * aspect * 1.5 + abs(q.x) * 0.9 + TIME * 1.2;
		float chev = (1.0 - smoothstep(0.0, 0.08, abs(fract(cy) - 0.5))) * step(0.15, side) * 0.45;
		float fill = 0.25 + 0.75 * charge;
		float wash = (0.12 + 0.08 * sin(TIME * 3.0 + UV.y * 12.0)) * charge * step(0.0, side);
		float la = (edge * 0.9 + edge2 + cap + ticks * 0.7 + chev * charge) * fill + wash;
		ALBEDO = mix(color.rgb, vec3(1.0), 0.2 * edge) * la * 0.65;
		ALPHA = clamp(la, 0.0, 1.0);
	} else {
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
}

shader_type spatial;
// A monster's warning on the floor: where its attack will land, filling in
// as it winds up. When the fill reaches the rim, it hits. Always the same
// danger red, whatever the monster, so it never reads as your own spell.
// The quad is 2 x 2 and faces -Z: a circle, a slice of one (`arc`, the half
// angle) or a lane (`lane` 1) that fills from the back to the front.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.16, 0.06, 1.0);
uniform float fill = 0.0;
uniform float arc = 3.2;
uniform float lane = 0.0;
uniform float fade = 1.0;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float inside;
	float edge;
	float p;
	if (lane > 0.5) {
		inside = step(abs(q.x), 1.0) * step(abs(q.y), 1.0);
		edge = 1.0 - smoothstep(0.0, 0.08, 1.0 - abs(q.x));
		edge = max(edge, 1.0 - smoothstep(0.0, 0.03, 1.0 - abs(q.y)));
		// From the monster (+Z, the back) to where the run ends.
		p = (1.0 - q.y) * 0.5;
	} else {
		float r = length(q);
		float ang = abs(atan(q.x, -q.y));
		inside = step(r, 1.0) * step(ang, arc);
		edge = 1.0 - smoothstep(0.0, 0.06, 1.0 - r);
		// The straight sides of a slice are edged too.
		if (arc < 3.1) {
			edge = max(edge, 1.0 - smoothstep(0.0, 0.05, (arc - ang) * r));
		}
		p = r;
	}
	float filled = step(p, fill);
	// The front of the fill: a bright line sweeping out to the rim.
	float front = (1.0 - smoothstep(0.0, 0.05, abs(p - fill))) * step(fill, 0.999);
	float a = 0.14 + 0.28 * filled + 0.75 * edge + 0.6 * front;
	// It pulses harder as the hit comes.
	a *= 0.8 + 0.2 * sin(TIME * (10.0 + 20.0 * fill));
	ALBEDO = mix(color.rgb, vec3(1.0, 0.85, 0.6), front * 0.6 + edge * 0.25);
	ALPHA = clamp(a * inside * fade, 0.0, 1.0);
}

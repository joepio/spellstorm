shader_type spatial;
// The wall of mist that shuts the way on past a clearing until every
// wizard has taken a tome there: a curtain of pale, slowly rising haze,
// thickest at the floor, with a line of faint runes glowing along its foot.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/element.gdshaderinc"

uniform vec4 color : source_color = vec4(0.85, 0.8, 0.65, 1.0);
// World size of the curtain, so the haze is not stretched on a wide one.
uniform vec2 size = vec2(20.0, 3.2);
// 1 shut, 0 gone.
uniform float open = 1.0;

void fragment() {
	vec2 w = vec2(UV.x * size.x, (1.0 - UV.y) * size.y);
	float rise = TIME * 0.35;
	float n = sn_fbm(vec3(w.x * 0.35, w.y * 0.6 - rise, TIME * 0.12));
	float wisp = sn_fbm(vec3(w.x * 0.9 + 7.0, w.y * 1.4 - rise * 1.6, TIME * 0.2));
	float h = w.y / size.y;
	// Thick below, thinning to nothing at the top, soft at both ends.
	float body = (1.0 - smoothstep(0.0, 1.0, h)) * smoothstep(0.0, 1.2, w.x) * smoothstep(0.0, 1.2, size.x - w.x);
	float a = body * (0.08 + 0.75 * smoothstep(0.3, 0.8, n) + 0.35 * smoothstep(0.4, 0.9, wisp) * (1.0 - h));
	// Runes along the foot: short bright marks that come and go.
	float cell = floor(w.x / 0.7);
	float lit = step(0.55, sn_hash(vec3(cell, floor(TIME * 0.8 + cell * 0.37), 3.0)));
	float mark = (1.0 - smoothstep(0.0, 0.06, abs(fract(w.x / 0.7) - 0.5) - 0.18)) * (1.0 - smoothstep(0.08, 0.3, w.y));
	vec3 c = mix(color.rgb * 0.35, color.rgb * 0.8, n);
	c += color.rgb * mark * lit * 1.4;
	a = max(a, mark * lit * 0.8 * body);
	// Opening: the haze thins from the top down and drifts apart.
	float gone = smoothstep(open - 0.15, open + 0.15, h * 0.6 + n * 0.4);
	ALBEDO = c;
	ALPHA = clamp(a * (1.0 - gone) * open, 0.0, 0.7);
}

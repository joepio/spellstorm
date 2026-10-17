shader_type spatial;
// An element as a solid thing in the world: the orbs over a wizard's hat,
// the staff's gem, bolts and thrown spells. The look is element_look
// (element.gdshaderinc), the same one the HUD draws.
render_mode unshaded, cull_back, shadows_disabled, depth_draw_opaque;

#include "res://src/fx/element.gdshaderinc"

uniform int element = 2;
uniform vec4 base : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float energy = 1.0;
uniform float spin = 0.6;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float light = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// Turn the pattern slowly so it lives even when the thing is still.
	float s = TIME * spin;
	vec3 p = normalize(lp + vec3(0.0001));
	p = vec3(p.x * cos(s) - p.z * sin(s), p.y, p.x * sin(s) + p.z * cos(s));
	vec4 look = element_look(element, base.rgb, p, light, TIME);
	ALBEDO = look.rgb * energy;
	ALPHA = look.a;
}

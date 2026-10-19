shader_type spatial;
// A monster's bullet: the element's own look (element.gdshaderinc), the
// same as the wizards' orbs and spells, with a bright rim in its colour so
// it stays readable on every floor. hot turns it gold once deflected.
render_mode unshaded, cull_back, shadows_disabled, depth_draw_opaque;

#include "res://src/fx/element.gdshaderinc"

uniform int element = 2;
uniform vec4 base : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float energy = 1.3;
uniform float hot = 0.0;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float light = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 p = normalize(lp + vec3(0.0001));
	vec4 look = element_look(element, base.rgb, p, light, TIME * 1.5);
	float rim = pow(1.0 - light, 2.2);
	vec3 col = look.rgb * energy * 0.85 + base.rgb * rim * 1.4;
	col = mix(col, vec3(1.0, 0.82, 0.35) * 1.8, hot * (0.4 + 0.6 * rim));
	ALBEDO = col;
	ALPHA = clamp(look.a + rim, 0.0, 1.0);
}

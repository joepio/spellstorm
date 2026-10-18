shader_type canvas_item;
// An element drawn in the HUD as a little glowing ball: the square it is
// drawn on becomes a sphere, lit from the top left, with the same look as
// in the world (element.gdshaderinc). The outline and shading make it read
// as an object, not a flat dot. It stands still: a HUD full of crawling
// lightning and swirling void is busy, so time only moves it with `animate`.

#include "res://src/fx/element.gdshaderinc"

uniform int element = 2;
uniform vec4 base : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float dim = 1.0;
uniform float animate = 0.0;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	if (r > 1.0) {
		COLOR = vec4(0.0);
	} else {
		float z = sqrt(1.0 - r * r);
		vec3 n = vec3(d.x, -d.y, z);
		float t = TIME * animate;
		float s = t * 0.5;
		vec3 p = vec3(n.x * cos(s) - n.z * sin(s), n.y, n.x * sin(s) + n.z * cos(s));
		float light = clamp(dot(n, normalize(vec3(-0.4, 0.5, 0.8))), 0.0, 1.0) * 0.7 + z * 0.3;
		vec4 look = element_look(element, base.rgb, p, light, t);
		vec3 c = look.rgb;
		// A glassy highlight and a dark rim.
		c += vec3(1.0) * pow(max(0.0, dot(n, normalize(vec3(-0.5, 0.6, 0.6)))), 30.0) * 0.5;
		c *= mix(0.45, 1.0, smoothstep(1.0, 0.82, r));
		float edge = smoothstep(1.0, 0.94, r);
		COLOR = vec4(c * dim, edge * mix(0.85, 1.0, look.a));
	}
}

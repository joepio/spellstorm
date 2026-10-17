shader_type spatial;
// A Life or Void beam: a white-hot core in a coloured sheath, with pulses
// running from the staff to whatever it hits. Put on a unit cylinder that is
// stretched to the beam's length (`length`, so the pulses keep their size).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform vec4 core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge : source_color = vec4(0.4, 1.0, 0.5, 1.0);
uniform float length = 8.0;
uniform float speed = 9.0;
uniform float strength = 1.0;

void fragment() {
	float facing = abs(dot(NORMAL, VIEW));
	// UV.y runs along the beam.
	float d = UV.y * length;
	float pulse = 0.5 + 0.5 * sin(d * 2.2 - TIME * speed);
	float n = sn_fbm(vec3(UV.x * 5.0, d * 0.9 - TIME * speed * 0.6, TIME));
	float centre = pow(facing, 6.0);
	float sheath = facing * (0.25 + 0.75 * smoothstep(0.2, 0.75, n)) * (0.55 + 0.6 * pulse);
	vec3 c = edge.rgb * sheath + core.rgb * centre * (0.4 + 0.3 * pulse);
	float a = clamp((sheath * 0.8 + centre * 0.5) * strength, 0.0, 1.0);
	ALBEDO = c * strength;
	ALPHA = a;
}

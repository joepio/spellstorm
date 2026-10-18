shader_type spatial;
// The tidal wave: a wall of water curling over at the top. UV.y runs up
// the face from the trough behind (0) to the lip (1); UV.x along its width.
// Deep blue at the foot, clear green-blue up the face where light comes
// through, and white churning foam on the crest and lip.
render_mode cull_disabled, depth_draw_always, shadows_disabled;

#include "res://src/fx/noise.gdshaderinc"

uniform float fade = 1.0;

void vertex() {
	// The face ripples and the crest heaves, never a straight edge.
	float h = UV.y;
	float n = sn_noise(vec3(VERTEX.x * 0.8, TIME * 1.5, 0.0));
	VERTEX.y += (n - 0.5) * 0.5 * h;
	VERTEX.z += sin(VERTEX.x * 1.3 + TIME * 5.0) * 0.12 * h;
}

void fragment() {
	float h = UV.y;
	float n = sn_fbm(vec3(UV.x * 18.0, h * 6.0 - TIME * 3.0, TIME * 0.5));
	vec3 deep = vec3(0.02, 0.12, 0.32);
	vec3 face = vec3(0.1, 0.55, 0.7);
	vec3 c = mix(deep, face, smoothstep(0.1, 0.7, h + (n - 0.5) * 0.3));
	// Foam: on the crest, streaking down the face, and churned at the foot.
	float foam = smoothstep(0.72, 0.9, h + (n - 0.5) * 0.35);
	foam = max(foam, smoothstep(0.62, 0.8, n) * smoothstep(0.3, 0.9, h) * 0.8);
	foam = max(foam, (1.0 - smoothstep(0.0, 0.12, h)) * smoothstep(0.45, 0.7, n));
	c = mix(c, vec3(0.92, 0.97, 1.0), foam);
	ALBEDO = c;
	ROUGHNESS = mix(0.05, 0.6, foam);
	SPECULAR = 0.8;
	// A little light of its own, so it reads in the dark levels.
	EMISSION = c * 0.25 + vec3(0.15, 0.2, 0.25) * foam;
	ALPHA = clamp((0.55 + 0.45 * foam) * fade * smoothstep(0.0, 0.06, h + 0.02), 0.0, 1.0);
}

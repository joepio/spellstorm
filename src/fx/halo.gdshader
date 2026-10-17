shader_type spatial;
// A soft glow round anything bright: a camera-facing quad that fades from
// the centre out, added on top of the scene. Reads as bloom on every screen,
// whatever the renderer does with HDR.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, depth_test_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float strength = 1.0;
uniform float pulse = 0.0;

void vertex() {
	// Face the camera, keep the node's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, length(MODEL_MATRIX[2].xyz), 0), vec4(0, 0, 0, 1));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float k = pow(clamp(1.0 - r, 0.0, 1.0), 2.4);
	// A brighter inner bloom and a wide faint one.
	float inner = pow(clamp(1.0 - r * 2.2, 0.0, 1.0), 2.0);
	float s = strength * (1.0 + pulse * sin(TIME * 13.0 + NODE_POSITION_WORLD.x * 3.0) * 0.25);
	ALBEDO = (color.rgb * k + mix(color.rgb, vec3(1.0), 0.6) * inner * 0.8) * s;
	ALPHA = clamp(k * s, 0.0, 1.0);
}

shader_type spatial;
// A monster's health bar: faces the camera, red up to `fill`, dark after it,
// with a thin black frame. One quad, so it drains from the right.
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;

uniform float fill : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec3 c = UV.x < fill ? vec3(0.85, 0.06, 0.04) : vec3(0.08, 0.03, 0.03);
	if (UV.y < 0.16 || UV.y > 0.84 || UV.x < 0.012 || UV.x > 0.988) {
		c = vec3(0.0);
	}
	ALBEDO = c;
}

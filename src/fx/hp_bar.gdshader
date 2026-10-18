shader_type spatial;
// A monster's health bar: a thin camera-facing line, red up to `fill` and a
// faint dark track after it. One quad, so it drains from the right.
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;

uniform float fill : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	bool on = UV.x < fill;
	ALBEDO = on ? vec3(0.9, 0.1, 0.06) : vec3(0.0);
	ALPHA = on ? 0.9 : 0.35;
}

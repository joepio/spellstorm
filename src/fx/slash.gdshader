shader_type spatial;
// The staff swing's arc on the ground: the area that knocks bullets back.
// `progress` sweeps it open from one side to the other as the staff swings,
// `fade` takes it away; with progress 1 and a low strength it is the faint
// guide shown while bullets are close.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform float progress = 1.0;
uniform float strength = 1.0;

void fragment() {
	// UV.x runs across the arc, UV.y from the inner edge out.
	float shown = step(UV.x, progress);
	// Brightest at the leading edge of the sweep and at the rim.
	float lead = exp(-abs(UV.x - progress) * 10.0) * step(progress, 0.999);
	float rim = smoothstep(0.75, 1.0, UV.y) + 0.35 * smoothstep(0.25, 0.0, UV.y);
	float body = 0.25 + 0.75 * UV.y * UV.y;
	float a = (body * 0.55 + rim * 0.8 + lead * 1.2) * shown * strength;
	ALBEDO = mix(color.rgb, vec3(1.0), 0.25 + lead * 0.5) * a;
	ALPHA = clamp(a, 0.0, 1.0);
}

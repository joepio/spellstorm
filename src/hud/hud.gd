class_name Hud
extends CanvasLayer
## The TV overlay: one panel per wizard along the bottom showing their
## health, their queued elements and what each button would cast right now,
## the room at the top, the grimoire count, and big banners.

const VIGNETTE := """
shader_type canvas_item;
uniform float hurt = 0.0;
void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.6;
	float d = length(uv);
	float v = smoothstep(0.45, 1.05, d);
	COLOR = vec4(mix(vec3(0.0), vec3(0.35, 0.0, 0.0), hurt), v * (0.85 + hurt * 0.3));
}
"""

var panels: Array = []
var _row: HBoxContainer
var _title: Label
var _sub: Label
var _grimoire: Label
var _banner: Label
var _banner_sub: Label
var _banner_t := 0.0
var _vignette: ColorRect
var _legend: Control
var _toasts: VBoxContainer


func _ready() -> void:
	layer = 5
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE
	var m := ShaderMaterial.new()
	m.shader = sh
	_vignette.material = m
	add_child(_vignette)

	_title = _label(Art.title_font(), 40, Color(0.85, 0.72, 0.5))
	_wide(_title, 14, 60)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub = _label(Art.body_font(), 26, Color(0.7, 0.62, 0.52))
	_wide(_sub, 64, 100)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grimoire = _label(Art.body_font(), 26, Color(0.9, 0.78, 0.45))
	_wide(_grimoire, 22, 56)
	_grimoire.offset_right = -30
	_grimoire.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_banner = _label(Art.title_font(), 96, Color(0.85, 0.15, 0.1))
	_wide(_banner, 300, 420)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 18)
	_banner_sub = _label(Art.body_font(), 40, Color(0.85, 0.8, 0.7))
	_wide(_banner_sub, 420, 480)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_banner_sub.modulate.a = 0.0

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 18)
	add_child(_row)
	_row.anchor_left = 0.0
	_row.anchor_right = 1.0
	_row.anchor_top = 1.0
	_row.anchor_bottom = 1.0
	_row.offset_top = -212
	_row.offset_bottom = -14

	_legend = Legend.new()
	_legend.position = Vector2(24, 20)
	add_child(_legend)

	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(24, 230)
	add_child(_toasts)


## Stretch a label across the screen between two heights.
func _wide(l: Control, top: float, bottom: float) -> void:
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 0.0
	l.anchor_bottom = 0.0
	l.offset_left = 0
	l.offset_right = 0
	l.offset_top = top
	l.offset_bottom = bottom


func _label(font: Font, size: int, c: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func bind(wizards: Array) -> void:
	for p in panels:
		p.queue_free()
	panels.clear()
	for w in wizards:
		var p := WizardPanel.new()
		p.wizard = w
		p.custom_minimum_size = Vector2(minf(400.0, 1840.0 / maxf(wizards.size(), 1) - 18.0), 196)
		_row.add_child(p)
		panels.append(p)


func room(biome: Dictionary, r: int, depth: int) -> void:
	_title.text = biome.name
	_sub.text = ("Lair of the boss" if r == 2 else "Room %d of 3" % (r + 1)) + "   ·   Level %d" % (depth + 1)


func set_grimoire(found: int, total: int) -> void:
	_grimoire.text = "Grimoire  %d / %d spells" % [found, total]


func show_banner(text: String, sub: String, c: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", c)
	_banner_sub.text = sub
	_banner_t = 4.0


func toast(text: String, c: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Art.body_font())
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	_toasts.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)
	while _toasts.get_child_count() > 4:
		_toasts.get_child(0).free()


func _process(dt: float) -> void:
	_banner_t = maxf(0.0, _banner_t - dt)
	var a := clampf(_banner_t / 0.8, 0.0, 1.0) if _banner_t < 0.8 else clampf((4.0 - _banner_t) / 0.4, 0.0, 1.0)
	_banner.modulate.a = a
	_banner_sub.modulate.a = a
	var hurt := 0.0
	if Game.I:
		for w in Game.I.wizards:
			if w.alive:
				hurt = maxf(hurt, 1.0 - w.hp / w.max_hp * 2.5)
	(_vignette.material as ShaderMaterial).set_shader_parameter("hurt", clampf(hurt, 0.0, 1.0) * 0.6)
	for p in panels:
		p.queue_redraw()


## The buttons, once, small, in the corner.
class Legend:
	extends Control

	func _draw() -> void:
		var f := Art.body_font()
		var y := 0.0
		draw_rect(Rect2(-10, -8, 380, 200), Color(0, 0, 0, 0.45))
		for key in ["A", "B", "X", "Y"]:
			var pair: Array = El.PAIRS[key]
			var bc: Color = {"A": Color(0.3, 0.75, 0.3), "B": Color(0.85, 0.25, 0.2), "X": Color(0.25, 0.45, 0.9), "Y": Color(0.9, 0.75, 0.2)}[key]
			draw_circle(Vector2(14, y + 14), 13, bc)
			draw_string(f, Vector2(6, y + 22), key, HORIZONTAL_ALIGNMENT_CENTER, 18, 22, Color(0.05, 0.05, 0.05))
			draw_string(f, Vector2(36, y + 22), El.NAMES[pair[0]], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, El.COLOR[pair[0]].lightened(0.2))
			draw_string(f, Vector2(150, y + 22), "LB  " + El.NAMES[pair[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, El.COLOR[pair[1]].lightened(0.2))
			y += 30
		var lines := ["RT cast   LT burst   RB plant", "RS ward   ▲ again   L3 dash"]
		for l in lines:
			draw_string(f, Vector2(0, y + 26), l, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.78, 0.72, 0.62))
			y += 28


## One wizard's panel.
class WizardPanel:
	extends Control
	var wizard: Wizard

	func _draw() -> void:
		if wizard == null or not is_instance_valid(wizard):
			return
		var f := Art.body_font()
		var tf := Art.title_font()
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.02, 0.02, 0.72))
		draw_rect(Rect2(0, 0, w, h), Color(0.45, 0.35, 0.22, 0.8), false, 2.0)
		draw_rect(Rect2(0, 0, 6, h), wizard.robe)
		# Health orb, Diablo style: a glass globe that drains.
		var c := Vector2(54, 62)
		var r := 40.0
		draw_circle(c, r + 3, Color(0.3, 0.24, 0.16))
		draw_circle(c, r, Color(0.08, 0.02, 0.02))
		var frac := clampf(wizard.hp / wizard.max_hp, 0.0, 1.0) if wizard.alive else 0.0
		if frac > 0.0:
			var top := c.y + r - 2.0 * r * frac
			var pts := PackedVector2Array()
			for i in 33:
				var ang := PI * 0.5 + (float(i) / 32.0 - 0.5) * TAU
				var p := c + Vector2(cos(ang), sin(ang)) * r
				pts.append(Vector2(p.x, maxf(p.y, top)))
			draw_colored_polygon(pts, Color(0.62, 0.04, 0.04))
		draw_circle(c + Vector2(-12, -14), 10, Color(1, 1, 1, 0.12))
		var hp_txt := "%d" % ceili(wizard.hp) if wizard.alive else "✝"
		draw_string(tf, Vector2(c.x - 40, c.y + 9), hp_txt, HORIZONTAL_ALIGNMENT_CENTER, 80, 24, Color(1, 0.92, 0.85))
		draw_string(tf, Vector2(110, 32), wizard.player_name, HORIZONTAL_ALIGNMENT_LEFT, w - 120, 26, wizard.robe.lightened(0.45))
		# The queue: five sockets, filled in order.
		var slots := wizard.queue.slots
		for i in wizard.queue.size:
			var oc := Vector2(126 + i * 42, 66)
			draw_circle(oc, 17, Color(0.2, 0.16, 0.12))
			if i < slots.size():
				var e: int = slots[i]
				draw_circle(oc, 15, El.COLOR[e])
				draw_circle(oc + Vector2(-4, -5), 5, Color(1, 1, 1, 0.35))
				draw_string(f, oc + Vector2(-15, 7), El.GLYPH[e], HORIZONTAL_ALIGNMENT_CENTER, 30, 18, Color(0.05, 0.03, 0.03))
				if El.is_fused(e):
					draw_arc(oc, 19, 0, TAU, 24, Color(1, 0.9, 0.6), 2.0)
		# What each button casts right now.
		var y := 112.0
		var rows := [["RT", "cast"], ["LT", "nova"], ["RB", "plant"], ["RS", "ward"]]
		if not wizard.alive:
			draw_string(f, Vector2(110, y + 10), "Fallen. Heal the grave with Life", HORIZONTAL_ALIGNMENT_LEFT, w - 120, 22, Color(0.85, 0.3, 0.25))
			return
		if slots.is_empty():
			draw_string(f, Vector2(16, y + 12), "Conjure with A B X Y, LB for the opposite", HORIZONTAL_ALIGNMENT_LEFT, w - 24, 20, Color(0.6, 0.55, 0.48))
			return
		for i in rows.size():
			var s := wizard.preview(rows[i][1])
			var col := Color(0.8, 0.74, 0.62)
			if s.primary >= 0:
				col = El.COLOR[s.primary].lightened(0.35)
			var x := 16.0 + (i % 2) * (w * 0.5)
			var yy := y + floorf(i / 2.0) * 38.0
			draw_string(f, Vector2(x, yy + 12), rows[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.55, 0.5, 0.42))
			draw_string(f, Vector2(x + 34, yy + 12), s.name, HORIZONTAL_ALIGNMENT_LEFT, w * 0.5 - 52, 21, col)

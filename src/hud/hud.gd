class_name Hud
extends CanvasLayer
## The TV overlay: one panel per wizard along the bottom showing their
## health, their queued elements and what each button would cast right now,
## the level at the top, the grimoire count, and big banners.

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
var _title: Label
var _sub: Label
var _grimoire: Label
var _banner: Label
var _banner_sub: Label
var _banner_t := 0.0
var _vignette: ColorRect
## Black over everything, for going through a portal.
var _fade: ColorRect
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
	# Shown in the menu instead (Start), so the screen stays clear.
	_title.visible = false
	_sub.visible = false
	_grimoire.visible = false

	_banner = _label(Art.title_font(), 96, Color(0.85, 0.15, 0.1))
	_wide(_banner, 300, 420)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 18)
	_banner_sub = _label(Art.body_font(), 40, Color(0.85, 0.8, 0.7))
	_wide(_banner_sub, 420, 480)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_banner_sub.modulate.a = 0.0

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	# Toasts (a tome taken) sit at the top in the middle, between the panels.
	_toasts = VBoxContainer.new()
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toasts.anchor_left = 0.5
	_toasts.anchor_right = 0.5
	_toasts.offset_left = -360
	_toasts.offset_right = 360
	_toasts.offset_top = 20
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


## Each wizard's panel sits in a corner of its own: first bottom left, then
## bottom right, top left, top right. Panels on the right are mirrored so
## the health orb is always on the outside.
const PANEL := Vector2(312, 108)
const MARGIN := 18.0


func bind(wizards: Array) -> void:
	for p in panels:
		p.queue_free()
	panels.clear()
	for i in wizards.size():
		var p := WizardPanel.new()
		p.wizard = wizards[i]
		var right := i % 2 == 1
		var top := i >= 2
		p.mirrored = right
		p.anchor_left = 1.0 if right else 0.0
		p.anchor_right = p.anchor_left
		p.anchor_top = 0.0 if top else 1.0
		p.anchor_bottom = p.anchor_top
		p.offset_left = -MARGIN - PANEL.x if right else MARGIN
		p.offset_right = p.offset_left + PANEL.x
		p.offset_top = MARGIN if top else -MARGIN - PANEL.y
		p.offset_bottom = p.offset_top + PANEL.y
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		panels.append(p)


## Where the run is and the grimoire count live in the menu, not on screen.
var where := ""
var grimoire_text := ""


func level(biome: Dictionary, depth: int) -> void:
	where = "%s   ·   Level %d of %d" % [biome.name, depth + 1, Arena.BIOMES.size()]
	_title.text = biome.name
	_sub.text = "Level %d of %d" % [depth + 1, Arena.BIOMES.size()]


func set_grimoire(found: int, total: int) -> void:
	_grimoire.text = "Grimoire  %d / %d spells" % [found, total]
	grimoire_text = "Grimoire: %d of %d spells discovered" % [found, total]


## Fade the screen to [param alpha] black over [param time] seconds.
func fade_to(alpha: float, time: float) -> void:
	var tw := _fade.create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)


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


## One wizard's panel: health orb, name, the queue, mana, the face buttons
## with the elements they load, and under them what the queue casts on each
## button, so players learn the spells. Names show only here, never over the
## battle when a spell goes off (Joep).
class WizardPanel:
	extends Control
	var wizard: Wizard
	var mirrored := false
	## The queue's sockets and the four face buttons, as element balls.
	var _socket_balls: Array[ElementBall] = []
	var _button_balls: Array[ElementBall] = []
	## What each cast button would make of the queue, kept until it changes.
	var _names: Array = []
	var _names_for := "-"
	const FORMS := [["RT", "cast"], ["RB", "nova"], ["LS", "plant"], ["RS", "enchant"]]

	func _ball(list: Array[ElementBall]) -> ElementBall:
		var b := ElementBall.new()
		add_child(b)
		list.append(b)
		return b

	## x measured from the panel's outer edge.
	func _x(x: float) -> float:
		return size.x - x if mirrored else x

	func _draw() -> void:
		if wizard == null or not is_instance_valid(wizard):
			return
		var f := Art.body_font()
		var tf := Art.title_font()
		var w := size.x
		var h := size.y
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.03, 0.02, 0.02, 0.5)
		bg.set_corner_radius_all(12)
		draw_style_box(bg, Rect2(0, 0, w, h))
		var align := HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
		# Health orb, Diablo style: a glass globe that drains.
		var frac := clampf(wizard.hp / wizard.max_hp, 0.0, 1.0) if wizard.alive else 0.0
		var hc := Vector2(_x(32), 36)
		_orb(hc, 22.0, frac, Color(0.62, 0.04, 0.04), Color(0.3, 0.24, 0.16), Color(0.08, 0.02, 0.02))
		# An enchantment: a band in its element round the orb that runs down.
		if wizard.enchant_time > 0.0:
			var sk := wizard.enchant_time / maxf(wizard.enchant.n.duration, 0.1)
			var wc: Color = El.COLOR[wizard.enchant.primary]
			draw_arc(hc, 27.0, -PI * 0.5, -PI * 0.5 + TAU * sk, 40, wc.lightened(0.4), 3.0, true)
		var hp_txt := "%d" % ceili(wizard.hp) if wizard.alive else "✝"
		draw_string(tf, Vector2(hc.x - 30, hc.y + 6), hp_txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 15, Color(1, 0.92, 0.85))
		# Name, then the queue: five sockets, filled in order.
		var sx0 := _x(74)
		var nx := sx0 + 9.0 - 150.0 if mirrored else sx0 - 9.0
		draw_string(tf, Vector2(nx, 18), wizard.player_name, align, 150, 15, wizard.robe.lightened(0.45))
		var slots := wizard.queue.slots
		var step := -22.0 if mirrored else 22.0
		while _socket_balls.size() < 6:
			_ball(_socket_balls)
		# Short of mana, a cast falls back to the front elements it can pay
		# for (Wizard.preview): the ones it would leave out sit dimmed.
		var pays := _pays()
		for i in _socket_balls.size():
			var oc := Vector2(sx0 + i * step, 36)
			if i < wizard.queue.size:
				draw_circle(oc, 9.5, Color(0.2, 0.16, 0.12, 0.8))
			if i < slots.size():
				var e: int = slots[i]
				var left_out := pays > 0 and i >= pays
				_socket_balls[i].show_at(e, oc, 8.5, 0.45 if left_out else 1.0)
				_socket_balls[i].modulate.a = 0.45 if left_out else 1.0
				if El.is_fused(e):
					draw_arc(oc, 10.5, 0, TAU, 20, Color(1, 0.9, 0.6), 1.2)
			else:
				_socket_balls[i].visible = false
		# The front element burns first: a ring round it shows the bolts it has left.
		if not slots.is_empty():
			var k := clampf(float(wizard.ammo) / Wizard.BOLTS_PER_ELEMENT, 0.0, 1.0)
			draw_arc(Vector2(sx0, 36), 11.5, -PI * 0.5, -PI * 0.5 + TAU * k, 28, Color(1.0, 0.88, 0.5), 1.6, true)
		# A running stream (flamethrower, beam, chain lightning) drains a bar
		# over the sockets until it ends.
		var bw := 4 * 22.0 + 20.0
		var bx := sx0 - bw + 10.0 if mirrored else sx0 - 10.0
		var left := wizard.channel_left()
		if left >= 0.0 and wizard.channel:
			var bar := Rect2(bx, 30, bw, 12)
			var col: Color = wizard.channel.color()
			draw_rect(bar, Color(0.12, 0.09, 0.07))
			var fill_w := bar.size.x * left
			var fx := bar.end.x - fill_w if mirrored else bar.position.x
			draw_rect(Rect2(fx, bar.position.y, fill_w, bar.size.y), col)
			draw_rect(Rect2(fx, bar.position.y, fill_w, 4), col.lightened(0.45))
		# Mana: a thin bar under the queue, blue like the souls that fill it.
		var mbar := Rect2(bx, 52, bw, 5)
		var mk := clampf(wizard.mana / Wizard.MANA_MAX, 0.0, 1.0)
		draw_rect(mbar, Color(0.5, 0.65, 1.0, 0.5) if wizard.no_mana > 0.0 else Color(0.02, 0.02, 0.08, 0.9))
		var mw := mbar.size.x * mk
		var mx := mbar.end.x - mw if mirrored else mbar.position.x
		draw_rect(Rect2(mx, mbar.position.y, mw, mbar.size.y), Color(0.2, 0.38, 1.0))
		if not wizard.alive:
			for b in _button_balls:
				b.visible = false
			draw_string(f, Vector2(_x(16) - (150 if mirrored else 0), 84), "Stand at the grave", align, 150, 13, Color(0.85, 0.3, 0.25))
			return
		_buttons(Vector2(_x(222), 36))
		_spells(f)

	## Under the panel's top row: each cast button and what the queue makes
	## on it, small, two by two. Nothing while the queue is empty.
	## How many queued elements an RT cast can pay for, worked out again only
	## when the queue or the whole mana changes.
	func _pays() -> int:
		var key := "%s|%d" % [",".join(wizard.queue.slots.map(func(e): return str(e))), int(wizard.mana)]
		if key != _pays_for:
			_pays_for = key
			_pays_n = wizard.affordable("cast")
		return _pays_n

	var _pays_for := ""
	var _pays_n := 0

	func _spells(f: Font) -> void:
		var key := "%s|%d" % [",".join(wizard.queue.slots.map(func(e): return str(e))), _pays()]
		if key != _names_for:
			_names_for = key
			_names.clear()
			if not wizard.queue.slots.is_empty():
				for fm in FORMS:
					_names.append([fm[0], wizard.preview(fm[1]).name])
		for i in _names.size():
			var col := i % 2
			var row := i / 2
			var x := 14.0 + col * 146.0
			var y := 70.0 + row * 19.0
			var chip := Rect2(_x(x) - (22.0 if mirrored else 0.0), y, 22, 14)
			var cb := StyleBoxFlat.new()
			cb.bg_color = Color(0.85, 0.75, 0.55, 0.85)
			cb.set_corner_radius_all(4)
			draw_style_box(cb, chip)
			draw_string(f, Vector2(chip.position.x, y + 11), _names[i][0], HORIZONTAL_ALIGNMENT_CENTER, 22, 10, Color(0.08, 0.05, 0.03))
			var tx := chip.position.x - 4.0 - 120.0 if mirrored else chip.end.x + 5.0
			draw_string(f, Vector2(tx, y + 11), _names[i][1], HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT, 120, 11, Color(0.92, 0.86, 0.74, 0.9))

	## The four face buttons where they sit on the controller (Y top, X left,
	## B right, A bottom), each showing the element it conjures as an icon.
	## Holding LB flips every button to its opposite.
	func _buttons(c: Vector2) -> void:
		var flip := wizard.pad != null and wizard.pad.down(Pad.LB)
		var places := {"Y": Vector2(0, -15), "X": Vector2(-15, 0), "B": Vector2(15, 0), "A": Vector2(0, 15)}
		var bits := {"A": Pad.A, "B": Pad.B, "X": Pad.X, "Y": Pad.Y}
		while _button_balls.size() < 4:
			_ball(_button_balls)
		var k := 0
		for key in places:
			var e: int = El.PAIRS[key][1 if flip else 0]
			var p: Vector2 = c + places[key]
			var held: bool = wizard.pad != null and wizard.pad.down(bits[key])
			var r := 9.0 if held else 7.5
			draw_circle(p, r + 1.5, Color(0.04, 0.03, 0.03))
			_button_balls[k].show_at(e, p, r, 1.15 if held else 0.85)
			k += 1
			if e == wizard.bolt_el:
				draw_arc(p, r + 2.5, 0, TAU, 24, Color(1.0, 0.85, 0.4), 1.3, true)

	func _orb(c: Vector2, r: float, frac: float, fill: Color, rim: Color, bg: Color) -> void:
		draw_circle(c, r + 3, rim)
		draw_circle(c, r, bg)
		frac = clampf(frac, 0.0, 1.0)
		if frac > 0.0:
			var top := c.y + r - 2.0 * r * frac
			var pts := PackedVector2Array()
			for i in 33:
				var ang := PI * 0.5 + (float(i) / 32.0 - 0.5) * TAU
				var p := c + Vector2(cos(ang), sin(ang)) * r
				pts.append(Vector2(p.x, maxf(p.y, top)))
			draw_colored_polygon(pts, fill)
		draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.25, Color(1, 1, 1, 0.12))

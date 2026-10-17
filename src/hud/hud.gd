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
var _title: Label
var _sub: Label
var _grimoire: Label
var _banner: Label
var _banner_sub: Label
var _banner_t := 0.0
var _vignette: ColorRect
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
const PANEL := Vector2(330, 112)
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


func room(biome: Dictionary, r: int, depth: int) -> void:
	where = "%s   ·   %s   ·   Level %d" % [biome.name, "Lair of the boss" if r == 2 else "Room %d of 3" % (r + 1), depth + 1]
	_title.text = biome.name
	_sub.text = ("Lair of the boss" if r == 2 else "Room %d of 3" % (r + 1)) + "   ·   Level %d" % (depth + 1)


func set_grimoire(found: int, total: int) -> void:
	_grimoire.text = "Grimoire  %d / %d spells" % [found, total]
	grimoire_text = "Grimoire: %d of %d spells discovered" % [found, total]


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


## One wizard's panel: health orb, name, the queue, mana, and the face
## buttons with the elements they load. No spell names (Joep): what a queue
## casts you learn by casting it.
class WizardPanel:
	extends Control
	var wizard: Wizard
	var mirrored := false

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
		draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.02, 0.02, 0.62))
		draw_rect(Rect2(0, 0, w, h), Color(0.45, 0.35, 0.22, 0.7), false, 1.5)
		draw_rect(Rect2(_x(0) - (4 if mirrored else 0), 0, 4, h), wizard.robe)
		# Health orb, Diablo style: a glass globe that drains.
		var frac := clampf(wizard.hp / wizard.max_hp, 0.0, 1.0) if wizard.alive else 0.0
		var hc := Vector2(_x(52), h * 0.5)
		_orb(hc, 38.0, frac, Color(0.62, 0.04, 0.04), Color(0.3, 0.24, 0.16), Color(0.08, 0.02, 0.02))
		# A ward's shield: a bright band round the orb that wears down.
		if wizard.shield > 0.0:
			var sk := wizard.shield / maxf(wizard.shield_max, 1.0)
			var wc: Color = El.COLOR[wizard.ward.primary] if wizard.ward.has("primary") else Color.WHITE
			draw_arc(hc, 44.0, -PI * 0.5, -PI * 0.5 + TAU * sk, 40, wc.lightened(0.4), 4.0, true)
		var hp_txt := "%d" % ceili(wizard.hp) if wizard.alive else "✝"
		draw_string(tf, Vector2(hc.x - 40, hc.y + 8), hp_txt, HORIZONTAL_ALIGNMENT_CENTER, 80, 22, Color(1, 0.92, 0.85))
		# Name, then the queue: five sockets, filled in order.
		var sx0 := _x(116)
		var nx := sx0 + 12.0 - 150.0 if mirrored else sx0 - 12.0
		draw_string(tf, Vector2(nx, 28), wizard.player_name, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT, 150, 20, wizard.robe.lightened(0.45))
		var slots := wizard.queue.slots
		var step := -28.0 if mirrored else 28.0
		for i in wizard.queue.size:
			var oc := Vector2(sx0 + i * step, 52)
			draw_circle(oc, 12, Color(0.2, 0.16, 0.12))
			if i < slots.size():
				var e: int = slots[i]
				draw_circle(oc, 10.5, El.COLOR[e])
				draw_circle(oc + Vector2(-3, -3.5), 3.5, Color(1, 1, 1, 0.25))
				Icons.draw(self, e, oc, 6.5, Color(0.06, 0.04, 0.04, 0.92))
				if El.is_fused(e):
					draw_arc(oc, 13.5, 0, TAU, 20, Color(1, 0.9, 0.6), 1.5)
		# The front element burns first: a ring round it shows the bolts it has left.
		if not slots.is_empty():
			var k := clampf(float(wizard.ammo) / Wizard.BOLTS_PER_ELEMENT, 0.0, 1.0)
			draw_arc(Vector2(sx0, 52), 14.5, -PI * 0.5, -PI * 0.5 + TAU * k, 28, Color(1.0, 0.88, 0.5), 2.0, true)
		# A running stream (flamethrower, beam, chain lightning) drains a bar
		# over the sockets until it ends.
		var bx := minf(sx0 - 14, sx0 + 4 * step - 14) if mirrored else sx0 - 14
		var left := wizard.channel_left()
		if left >= 0.0 and wizard.channel:
			var bar := Rect2(bx, 44, 4 * 28 + 28, 16)
			var col: Color = wizard.channel.color()
			draw_rect(bar, Color(0.12, 0.09, 0.07))
			var fill_w := bar.size.x * left
			var fx := bar.end.x - fill_w if mirrored else bar.position.x
			draw_rect(Rect2(fx, bar.position.y, fill_w, bar.size.y), col)
			draw_rect(Rect2(fx, bar.position.y, fill_w, 5), col.lightened(0.45))
			draw_rect(bar, Color(0.45, 0.35, 0.22), false, 1.5)
		# Mana: a bar under the queue, blue like the souls that fill it.
		var mbar := Rect2(bx, 76, 4 * 28 + 28, 12)
		var mk := clampf(wizard.mana / Wizard.MANA_MAX, 0.0, 1.0)
		draw_rect(mbar, Color(0.02, 0.02, 0.08))
		var mw := mbar.size.x * mk
		var mx := mbar.end.x - mw if mirrored else mbar.position.x
		draw_rect(Rect2(mx, mbar.position.y, mw, mbar.size.y), Color(0.12, 0.25, 0.85))
		draw_rect(Rect2(mx, mbar.position.y, mw, 4), Color(0.35, 0.5, 1.0))
		draw_rect(mbar, Color(0.5, 0.65, 1.0) if wizard.no_mana > 0.0 else Color(0.3, 0.24, 0.16), false, 1.5)
		draw_string(f, Vector2(mbar.position.x, mbar.end.y + 16), "%d" % int(wizard.mana), HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT, mbar.size.x, 15, Color(0.7, 0.8, 1.0))
		if not wizard.alive:
			draw_string(f, Vector2(_x(262) - 50, h * 0.5 + 6), "Heal the grave", HORIZONTAL_ALIGNMENT_CENTER, 100, 15, Color(0.85, 0.3, 0.25))
			return
		_buttons(Vector2(_x(282), h * 0.5))

	## The four face buttons where they sit on the controller (Y top, X left,
	## B right, A bottom), each showing the element it conjures as an icon.
	## Holding LB flips every button to its opposite.
	func _buttons(c: Vector2) -> void:
		var flip := wizard.pad != null and wizard.pad.down(Pad.LB)
		var places := {"Y": Vector2(0, -20), "X": Vector2(-20, 0), "B": Vector2(20, 0), "A": Vector2(0, 20)}
		var bits := {"A": Pad.A, "B": Pad.B, "X": Pad.X, "Y": Pad.Y}
		for key in places:
			var e: int = El.PAIRS[key][1 if flip else 0]
			var p: Vector2 = c + places[key]
			var held: bool = wizard.pad != null and wizard.pad.down(bits[key])
			var r := 12.0 if held else 10.5
			var col: Color = El.COLOR[e]
			draw_circle(p, r + 2.0, Color(0.04, 0.03, 0.03))
			draw_circle(p, r, col.darkened(0.15) if not held else col.lightened(0.2))
			Icons.draw(self, e, p, r * 0.62, Color(0.06, 0.04, 0.04, 0.92))
			if e == wizard.bolt_el:
				draw_arc(p, r + 3.5, 0, TAU, 24, Color(1.0, 0.85, 0.4), 1.5, true)

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

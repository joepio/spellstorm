class_name Menu
extends Control
const GAME_LOGO = preload("res://assets/branding/logo.png")
## The start menu and the pause menu, one screen. Start (Esc on the keyboard)
## opens it during play and pauses the game. Up and down pick a row, left and
## right change its value, A (Enter) confirms, B or Start closes it.
##   Resume
##   Start new run  start the chosen level again from its entrance
##   Level          which biome to play (Random by default); confirm to go there now
##   Friendly fire  off / half / full
##   Difficulty     easy / normal / hard
## Next to it, every control drawn as its controller part with what it does.

const FF := ["off", "half", "full"]
const DIFFICULTY := ["easy", "normal", "hard"]
const REPEAT := 0.22

var title_mode := false
var rows: Array = []
var sel := 0
## The chosen biome, or -1 for a random one.
var biome := -1
var _nav_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## [param title] shows the start menu (Start instead of Resume, no restart).
func open(title: bool) -> void:
	title_mode = title
	biome = -1 if title else Game.I.run.biome_index
	# A new run sits right under Resume, the way every GameNight game does it.
	rows = ["start"] if title else ["resume", "restart"]
	rows.append_array(["level", "friendly_fire", "difficulty"])
	if Game.I.session == "":
		rows.append("quit")
	sel = 0
	visible = true
	get_parent().move_child(self, -1)
	Game.I.set_menu(true)
	queue_redraw()


func close() -> void:
	visible = false
	Game.I.set_menu(false)


func _pads() -> Array:
	var out: Array = []
	for w in Game.I.wizards:
		if w.bot == null and w.pad:
			out.append(w.pad)
	return out


func _physics_process(dt: float) -> void:
	if Game.I == null or Game.I.demo:
		return
	var pads := _pads()
	# While the game is paused the wizards stop reading their pads, so read them here.
	if get_tree().paused:
		for p in pads:
			p.poll()
	if not visible:
		for p in pads:
			if p.pressed(Pad.START):
				open(false)
				return
		return
	_nav_t -= dt
	var dy := 0
	var dx := 0
	var ok := false
	var back := false
	for p in pads:
		if p.pressed(Pad.UP):
			dy = -1
		if p.pressed(Pad.DOWN):
			dy = 1
		if p.pressed(Pad.LEFT):
			dx = -1
		if p.pressed(Pad.RIGHT):
			dx = 1
		if _nav_t <= 0.0 and dy == 0 and dx == 0:
			if p.move.y < -0.6:
				dy = -1
			elif p.move.y > 0.6:
				dy = 1
			elif p.move.x < -0.6:
				dx = -1
			elif p.move.x > 0.6:
				dx = 1
		ok = ok or p.pressed(Pad.A)
		back = back or p.pressed(Pad.B) or (p.pressed(Pad.START) and not title_mode)
		if title_mode and p.pressed(Pad.START):
			ok = true
	if dy != 0 or dx != 0:
		_nav_t = REPEAT
	if dy != 0:
		sel = posmod(sel + dy, rows.size())
	if dx != 0:
		_change(rows[sel], dx)
	if ok:
		_confirm(rows[sel])
	elif back and not title_mode:
		close()
	if dy != 0 or dx != 0 or ok or back:
		queue_redraw()


func _change(row: String, dx: int) -> void:
	match row:
		"level":
			biome = posmod(biome + 1 + dx, Arena.BIOMES.size() + 1) - 1
		"friendly_fire":
			Game.I.set_option("friendly_fire", FF[posmod(FF.find(Game.I.ff_name) + dx, FF.size())])
		"difficulty":
			Game.I.set_option("difficulty", DIFFICULTY[posmod(DIFFICULTY.find(Game.I.difficulty_name) + dx, DIFFICULTY.size())])


func _confirm(row: String) -> void:
	match row:
		"start":
			close()
			Game.I.start_at(biome)
		"resume":
			close()
		"level", "restart":
			close()
			Game.I.start_at(biome)
		"friendly_fire", "difficulty":
			_change(row, 1)
		"quit":
			get_tree().quit()


## The wizards and the tomes each has taken this run, right of the menu.
func _tomes(r: Rect2) -> void:
	var tf := Art.title_font()
	var f := Art.body_font()
	var x := r.position.x + 26.0
	var tw := r.size.x - 52.0
	var yy := r.position.y + 40.0
	var bottom := r.position.y + r.size.y - 12.0
	var cmds: Array = []
	for w in Game.I.wizards:
		cmds.append([tf, w.player_name, w.robe.lightened(0.3), 26, 34.0])
		if w.relics.is_empty():
			cmds.append([f, "No tomes yet", Color(0.5, 0.46, 0.4), 19, 30.0])
		for t in w.relics:
			cmds.append([f, "%s: %s" % [t.get("name", ""), t.get("text", "")], Color(0.78, 0.72, 0.6), 19, 0.0])
		cmds.append(null)
	var used := 40.0
	for c in cmds:
		used += 14.0 if c == null else (c[4] if c[4] > 0.0 else _lines(f, c[1], tw - 18.0, 19) * 24.0 + 4.0)
	_frame(Rect2(r.position, Vector2(r.size.x, minf(r.size.y, used))))
	for c in cmds:
		if yy > bottom:
			break
		if c == null:
			yy += 14.0
		elif c[4] > 0.0:
			draw_string(c[0], Vector2(x, yy), c[1], HORIZONTAL_ALIGNMENT_LEFT, tw, c[3], c[2])
			yy += c[4]
		else:
			draw_multiline_string(f, Vector2(x + 18.0, yy), c[1], HORIZONTAL_ALIGNMENT_LEFT, tw - 18.0, 19, 3, c[2])
			yy += _lines(f, c[1], tw - 18.0, 19) * 24.0 + 4.0


func _lines(f: Font, text: String, width: float, size: int) -> int:
	return clampi(ceili(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / maxf(width, 1.0)), 1, 3)


func _label(row: String) -> Array:
	match row:
		"start": return ["Start", ""]
		"resume": return ["Resume", ""]
		"level": return ["Level", "Random" if biome < 0 else Arena.BIOMES[biome].name]
		"friendly_fire": return ["Friendly fire", Game.I.ff_name.capitalize()]
		"difficulty": return ["Difficulty", Game.I.difficulty_name.capitalize()]
		"restart": return ["Start new run", ""]
		"quit": return ["Quit", ""]
	return [row, ""]


## Each control: how to draw it, then what it does.
const CONTROLS := [
	["lstick", "Walk"],
	["rstick", "Aim and shoot bolts"],
	["faces", "Load an element"],
	["lb", "Hold: each button's second element"],
	["rt", "Cast ahead: winds up, hold to aim"],
	["rb", "Sword swing, knocks bullets back"],
	["rb_hold", "Hold and let go: burst around you"],
	["lt", "Dodge roll"],
	["rs", "Enchant your bolts and sword"],
	["ls", "Plant it at your feet"],
	["dpad_up", "Your last spell again"],
	["dpad_side", "Saved spells (hold to save)"],
	["start", "This menu"],
]


func _draw() -> void:
	var tf := Art.title_font()
	var f := Art.body_font()
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.8 if title_mode else 0.66))
	var top := h * 0.15
	draw_game_logo(Rect2(w * 0.2, h * 0.025, w * 0.6, h * 0.15))
	var sub := "A couch co-op roguelite for wizards" if title_mode else "Paused"
	draw_string(f, Vector2(0, top + 56), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 32, Color(0.75, 0.68, 0.56))
	if not title_mode and Game.I.hud:
		draw_string(f, Vector2(0, top + 96), Game.I.hud.where + "   ·   " + Game.I.hud.grimoire_text, HORIZONTAL_ALIGNMENT_CENTER, w, 25, Color(0.9, 0.78, 0.45))
	# Three panels: the controls on the left, the menu in the middle, the
	# wizards and their tomes on the right (Joep).
	var y := top + 170
	var pw := 560.0
	var cx := w * 0.5
	var side := minf(620.0, cx - pw * 0.5 - 60.0)
	_frame(Rect2(cx - pw * 0.5, y - 50, pw, rows.size() * 64 + 40))
	for i in rows.size():
		var l := _label(rows[i])
		var on := i == sel
		var col := Color(1.0, 0.82, 0.4) if on else Color(0.72, 0.66, 0.56)
		var yy := y + i * 64
		if on:
			draw_rect(Rect2(cx - pw * 0.5 + 10, yy - 38, pw - 20, 54), Color(0.35, 0.08, 0.05, 0.55))
		if l[1] == "":
			draw_string(tf, Vector2(cx - pw * 0.5, yy), l[0], HORIZONTAL_ALIGNMENT_CENTER, pw, 36, col)
		else:
			draw_string(tf, Vector2(cx - pw * 0.5 + 30, yy), l[0], HORIZONTAL_ALIGNMENT_LEFT, pw * 0.45, 30, col)
			var v: String = ("‹  %s  ›" % l[1]) if on else l[1]
			draw_string(f, Vector2(cx - pw * 0.05, yy), v, HORIZONTAL_ALIGNMENT_CENTER, pw * 0.52, 28, col)
	if not Game.I.wizards.is_empty():
		_tomes(Rect2(cx + pw * 0.5 + 30.0, y - 50, side, h - y - 10.0))
	# The controls, two columns, each next to a drawing of its part of the
	# controller.
	var kx := cx - pw * 0.5 - 30.0 - side
	var ky := y - 50
	var row_h := 56.0
	var per := ceili(CONTROLS.size() / 2.0)
	var colw := side * 0.5
	_frame(Rect2(kx, ky, side, per * row_h + 24))
	for i in CONTROLS.size():
		var c := Vector2(kx + colw * (i / per) + 44, ky + 40 + (i % per) * row_h)
		_glyph(CONTROLS[i][0], c)
		draw_multiline_string(f, Vector2(c.x + 46, c.y - 4), CONTROLS[i][1], HORIZONTAL_ALIGNMENT_LEFT, colw - 100, 19, 2, Color(0.85, 0.79, 0.68))


func _frame(r: Rect2) -> void:
	draw_rect(r, Color(0.06, 0.04, 0.03, 0.92))
	draw_rect(r, Color(0.45, 0.35, 0.22, 0.9), false, 2.0)


const PAD_DARK := Color(0.16, 0.14, 0.13)
const PAD_EDGE := Color(0.55, 0.5, 0.42)
const PAD_LIT := Color(1.0, 0.82, 0.4)


## One controller part, about 80 by 40 pixels around [param c].
func _glyph(kind: String, c: Vector2) -> void:
	var f := Art.title_font()
	match kind:
		"lstick", "rstick", "rs", "ls":
			draw_circle(c, 17, PAD_EDGE)
			draw_circle(c, 15, PAD_DARK)
			var click := kind in ["rs", "ls"]
			draw_circle(c, 10, PAD_LIT if click else Color(0.32, 0.29, 0.26))
			draw_string(f, c + Vector2(-10, 6), "L" if kind in ["lstick", "ls"] else "R", HORIZONTAL_ALIGNMENT_CENTER, 20, 15, Color(0.05, 0.04, 0.03) if click else PAD_EDGE)
			if click:
				draw_arc(c, 21, 0, TAU, 24, PAD_LIT, 2.0, true)
			else:
				for a in 4:
					var d := Vector2.UP.rotated(a * PI * 0.5)
					var tip := c + d * 27
					draw_colored_polygon(PackedVector2Array([tip, tip - d * 6 + d.orthogonal() * 4, tip - d * 6 - d.orthogonal() * 4]), PAD_LIT)
		"faces":
			var places := {"Y": Vector2(0, -12), "X": Vector2(-12, 0), "B": Vector2(12, 0), "A": Vector2(0, 12)}
			for key in places:
				var e: int = El.PAIRS[key][0]
				draw_circle(c + places[key] * 1.25, 8, El.COLOR[e])
				Icons.draw(self, e, c + places[key] * 1.25, 5.0, Color(0.06, 0.04, 0.04))
		"lb", "rb", "rb_hold":
			var r := Rect2(c.x - 28, c.y - 10, 56, 20)
			draw_rect(r, PAD_LIT if kind != "rb_hold" else PAD_EDGE)
			draw_string(f, Vector2(r.position.x, c.y + 7), "LB" if kind == "lb" else "RB", HORIZONTAL_ALIGNMENT_CENTER, 56, 17, Color(0.05, 0.04, 0.03))
			if kind == "rb_hold":
				# A little timer: hold it.
				var t := c + Vector2(40, 0)
				draw_arc(t, 8, 0, TAU, 16, PAD_EDGE, 2.0, true)
				draw_arc(t, 8, -PI * 0.5, PI, 16, PAD_LIT, 3.0, true)
		"lt", "rt":
			var pts := PackedVector2Array([c + Vector2(-18, 18), c + Vector2(-18, -6), c + Vector2(-10, -18), c + Vector2(18, -18), c + Vector2(18, 18)])
			draw_colored_polygon(pts, PAD_LIT)
			draw_string(f, c + Vector2(-18, 8), kind.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 36, 16, Color(0.05, 0.04, 0.03))
		"dpad_up", "dpad_side":
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				var lit: bool = (kind == "dpad_up" and d == Vector2.UP) or (kind == "dpad_side" and d.y == 0.0)
				draw_rect(Rect2(c + d * 12 - Vector2(7, 7), Vector2(14, 14)), PAD_LIT if lit else PAD_EDGE)
			draw_rect(Rect2(c - Vector2(7, 7), Vector2(14, 14)), PAD_EDGE)
		"start":
			draw_rect(Rect2(c.x - 18, c.y - 8, 36, 16), PAD_LIT)
			for k in 3:
				draw_line(Vector2(c.x - 9, c.y - 4 + k * 4), Vector2(c.x + 9, c.y - 4 + k * 4), Color(0.05, 0.04, 0.03), 2.0)

func draw_game_logo(bounds: Rect2) -> void:
	var dimensions: Vector2 = GAME_LOGO.get_size()
	var fitted := dimensions * minf(bounds.size.x / dimensions.x, bounds.size.y / dimensions.y)
	draw_texture_rect(GAME_LOGO, Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted), false)

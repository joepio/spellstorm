class_name Menu
extends Control
## The start menu and the pause menu, one screen. Start (Esc on the keyboard)
## opens it during play and pauses the game. Up and down pick a row, left and
## right change its value, A (Enter) confirms, B or Start closes it.
##   Level          which biome to play; confirm to go there now
##   Friendly fire  off / half / full
##   Difficulty     easy / normal / hard
##   Restart run    start the chosen level again from its first room

const FF := ["off", "half", "full"]
const DIFFICULTY := ["easy", "normal", "hard"]
const REPEAT := 0.22

var title_mode := false
var rows: Array = []
var sel := 0
var biome := 0
var _nav_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## [param title] shows the start menu (Start instead of Resume, no restart).
func open(title: bool) -> void:
	title_mode = title
	biome = Game.I.run.biome_index
	rows = ["start" if title else "resume", "level", "friendly_fire", "difficulty"]
	if not title:
		rows.append("restart")
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
			biome = posmod(biome + dx, Arena.BIOMES.size())
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


func _label(row: String) -> Array:
	match row:
		"start": return ["Start", ""]
		"resume": return ["Resume", ""]
		"level": return ["Level", Arena.BIOMES[biome].name]
		"friendly_fire": return ["Friendly fire", Game.I.ff_name.capitalize()]
		"difficulty": return ["Difficulty", Game.I.difficulty_name.capitalize()]
		"restart": return ["Restart run", ""]
		"quit": return ["Quit", ""]
	return [row, ""]


func _draw() -> void:
	var tf := Art.title_font()
	var f := Art.body_font()
	var vs := get_viewport_rect().size
	var w := vs.x
	var h := vs.y
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.8 if title_mode else 0.62))
	var cx := w * 0.5
	var top := h * 0.2
	draw_string(tf, Vector2(0, top), "Spellstorm", HORIZONTAL_ALIGNMENT_CENTER, w, 120, Color(0.72, 0.13, 0.08))
	var sub := "A couch co-op roguelite for wizards" if title_mode else "Paused"
	draw_string(f, Vector2(0, top + 60), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 34, Color(0.75, 0.68, 0.56))
	var y := top + 170
	var pw := 760.0
	draw_rect(Rect2(cx - pw * 0.5, y - 50, pw, rows.size() * 64 + 40), Color(0.06, 0.04, 0.03, 0.9))
	draw_rect(Rect2(cx - pw * 0.5, y - 50, pw, rows.size() * 64 + 40), Color(0.45, 0.35, 0.22, 0.9), false, 2.0)
	for i in rows.size():
		var l := _label(rows[i])
		var on := i == sel
		var col := Color(1.0, 0.82, 0.4) if on else Color(0.72, 0.66, 0.56)
		var yy := y + i * 64
		if on:
			draw_rect(Rect2(cx - pw * 0.5 + 10, yy - 38, pw - 20, 54), Color(0.35, 0.08, 0.05, 0.55))
		if l[1] == "":
			draw_string(tf, Vector2(cx - pw * 0.5, yy), l[0], HORIZONTAL_ALIGNMENT_CENTER, pw, 38, col)
		else:
			draw_string(tf, Vector2(cx - pw * 0.5 + 40, yy), l[0], HORIZONTAL_ALIGNMENT_LEFT, pw * 0.4, 34, col)
			var v: String = ("‹  %s  ›" % l[1]) if on else l[1]
			draw_string(f, Vector2(cx - 40, yy), v, HORIZONTAL_ALIGNMENT_CENTER, pw * 0.5, 32, col)
	var hint := "Up / down choose   ·   left / right change   ·   A confirm" + ("" if title_mode else "   ·   B or Start back")
	draw_string(f, Vector2(0, y + rows.size() * 64 + 40), hint, HORIZONTAL_ALIGNMENT_CENTER, w, 24, Color(0.55, 0.5, 0.42))

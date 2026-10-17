class_name Game
extends Node3D
## Spellstorm: the scene root. Seats players, runs the GameNight lifecycle,
## owns the camera, and keeps the lists every spell looks things up in.
##
## Command line (after `--`):
##   --shot out.png   render one frame after --frames N and quit
##   --demo           bots play every seat (default for --shot)
##   --players N      how many wizards in standalone or demo (default 3)
##   --biome N --room N --seed N --recipe N (bots always cast recipe N)

static var I: Game

const COLORS := [Color(0.62, 0.12, 0.12), Color(0.15, 0.3, 0.65), Color(0.2, 0.5, 0.25), Color(0.55, 0.42, 0.12), Color(0.45, 0.18, 0.55), Color(0.15, 0.5, 0.52)]
const NAMES := ["Morwen", "Aldric", "Isolde", "Thorne", "Ysolde", "Cael"]

var wizards: Array = []
var enemies: Array = []
var arena: Arena
var run: Run
var hud: Hud
var fx_root: Node3D
var camera: Camera3D
var env: WorldEnvironment
var moon: DirectionalLight3D
var paused_play := false
var menu: Menu
## The GameNight host paused us; the menu pauses too. Either one keeps the tree paused.
var host_paused := false
var menu_open := false
var ff_name := "half"
var difficulty_name := "normal"

var ff := 0.5
var monster_hp := 1.0
var monster_damage := 1.0
var monster_count := 1.0
var grimoire := {}
var confluences := {}
var spell_total := 0
var session := ""

var _shake := 0.0
var _cam_center := Vector3.ZERO
var _cam_height := 20.0
var _confluence_t := {}
var _dmg_t := 0.0
var _globes: Array = []

var shot := ""
var shot_frames := 240
var demo := false
var players := 3
var start_biome := 0
var start_room := 0
var seed_value := 0
var recipe := -1
## What happened this run, for src/run/sim.gd: shots, swings, rolls, deflects,
## bullets, casts, no_mana, kills.
var stats := {}
var sim_frames := 0
var _frame := 0


func _enter_tree() -> void:
	I = self


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		var nxt: String = args[i + 1] if i + 1 < args.size() else ""
		match args[i]:
			"--shot": shot = nxt; demo = true
			"--frames": shot_frames = int(nxt)
			"--demo": demo = true
			"--players": players = int(nxt)
			"--biome": start_biome = int(nxt)
			"--room": start_room = int(nxt)
			"--seed": seed_value = int(nxt)
			"--recipe": recipe = int(nxt)
			"--sim": sim_frames = int(nxt); demo = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0))
	_world()
	arena = Arena.new()
	add_child(arena)
	fx_root = Node3D.new()
	fx_root.name = "Fx"
	add_child(fx_root)
	Fx.root = fx_root
	run = Run.new()
	add_child(run)
	hud = Hud.new()
	add_child(hud)
	menu = Menu.new()
	hud.add_child(menu)
	run.banner.connect(hud.show_banner)
	run.room_started.connect(func(b, r): hud.room(b, r, run.depth()))
	_load_grimoire()
	spell_total = Grammar.TOTAL
	hud.set_grimoire(grimoire.size(), spell_total)

	if GameNight.launched_by_daemon and not demo:
		GameNight.daemon_connected.connect(_declare)
		GameNight.prepared.connect(_on_prepared)
		GameNight.started.connect(func(_s): _set_paused(false))
		GameNight.resumed.connect(func(_s): _set_paused(false))
		GameNight.paused.connect(func(_s): _set_paused(true))
		GameNight.disposed.connect(_on_disposed)
		GameNight.setting_changed.connect(_on_setting)
	else:
		_standalone()


func _declare() -> void:
	GameNight.declare_settings([
		{key = "friendly_fire", label = "Friendly fire", kind = "choice", default = "half", options = ["off", "half", "full"]},
		{key = "difficulty", label = "Difficulty", kind = "choice", default = "normal", options = ["easy", "normal", "hard"]},
	])


func _on_setting(key: String, value: Variant) -> void:
	match key:
		"friendly_fire":
			ff_name = str(value)
			ff = {"off": 0.0, "half": 0.5, "full": 1.0}.get(str(value), 0.5)
		"difficulty":
			var d: String = str(value)
			difficulty_name = d
			monster_hp = {"easy": 0.7, "normal": 1.0, "hard": 1.4}.get(d, 1.0)
			monster_damage = {"easy": 0.6, "normal": 1.0, "hard": 1.35}.get(d, 1.0)
			monster_count = {"easy": 0.8, "normal": 1.0, "hard": 1.25}.get(d, 1.0)


func _on_prepared(session_id: String, seats: Array, players_list: Array) -> void:
	session = session_id
	var roster: Array = []
	for seat in seats:
		var o: Dictionary = seat.get("occupant", {})
		var kind := str(o.get("kind", "empty"))
		if kind == "empty" or kind == "remote":
			continue
		var entry := {seat = int(seat.get("index", 0)), bot = kind == "ai", name = NAMES[roster.size() % NAMES.size()]}
		for p in players_list:
			if str(p.get("id", "")) == str(o.get("player_id", "")) and str(o.get("player_id", "")) != "":
				entry.name = str(p.get("name", entry.name))
				if p.has("color"):
					entry.color = Color.from_string(str(p.color), COLORS[roster.size() % COLORS.size()])
		roster.append(entry)
	if roster.is_empty():
		roster.append({seat = 0, bot = true, name = NAMES[0]})
	_seat(roster)
	new_run()
	_set_paused(true)
	_trace("seated " + ", ".join(roster.map(func(r): return "bot" if r.bot else "%s (seat %d)" % [r.name, r.seat])))
	GameNight.notify_ready(session_id)


func _on_disposed(_s: String) -> void:
	session = ""
	_set_paused(true)
	_trace("disposed")


func _set_paused(p: bool) -> void:
	host_paused = p
	get_tree().paused = host_paused or menu_open
	_trace("paused" if p else "running")


func set_menu(on: bool) -> void:
	menu_open = on
	get_tree().paused = host_paused or menu_open
	_trace("menu open" if on else "menu closed")


## A setting changed from the in-game menu.
func set_option(key: String, value: String) -> void:
	_on_setting(key, value)


## A fresh run that starts in [param biome] (0 is the chapel).
func start_at(biome: int) -> void:
	new_run()
	if biome > 0:
		run.biome_index = biome
		run.room = 0
		run.enter_room()


var _tracing := OS.get_environment("SPELLSTORM_TRACE") != ""


## Lines the lifecycle test reads from stdout.
func _trace(s: String) -> void:
	if _tracing:
		print(s)


func _standalone() -> void:
	var roster: Array = []
	if demo:
		for i in players:
			roster.append({bot = true, name = NAMES[i % NAMES.size()]})
	else:
		var pads := Input.get_connected_joypads()
		for id in pads:
			roster.append({joypad = id, name = NAMES[roster.size() % NAMES.size()]})
		if pads.is_empty():
			roster.append({keyboard = true, name = NAMES[0]})
		while roster.size() < maxi(2, players if "--players" in OS.get_cmdline_user_args() else 2):
			roster.append({bot = true, name = NAMES[roster.size() % NAMES.size()]})
	_seat(roster)
	if seed_value == 0:
		seed_value = randi() % 100000 + 1
	new_run()
	if start_biome > 0 or start_room > 0:
		run.biome_index = start_biome
		run.room = start_room
		run.enter_room()
	if shot != "":
		_take_shot()
	elif not demo:
		menu.open(true)


func _seat(roster: Array) -> void:
	for w in wizards:
		w.queue_free()
	wizards.clear()
	var used := {}
	for i in roster.size():
		var r: Dictionary = roster[i]
		var w := Wizard.new()
		w.player_name = r.name
		var c: Color = r.get("color", COLORS[i % COLORS.size()])
		if used.has(c.to_html()):
			c = COLORS[i % COLORS.size()]
		used[c.to_html()] = true
		w.robe = c
		if r.get("bot", false):
			w.pad = Pad.new()
			w.bot = Bot.new()
			w.bot.fixed_recipe = recipe
		elif r.has("joypad"):
			w.pad = Pad.joypad(r.joypad)
		elif r.get("keyboard", false):
			w.pad = Pad.keyboard()
		else:
			w.pad = Pad.seat_pad(r.seat)
		add_child(w)
		w.died.connect(func(_a): pass)
		wizards.append(w)
	hud.bind(wizards)


func new_run() -> void:
	paused_play = false
	run.start(seed_value if seed_value != 0 else randi() % 100000 + 1)
	if seed_value != 0:
		seed_value += 1


func run_over(_won: bool) -> void:
	if session != "":
		GameNight.notify_finished(session)


# --- Lookups for spells ----------------------------------------------------

## Every actor a spell can touch: monsters that live, and all wizards
## (a fallen wizard's grave can still be healed back).
func living() -> Array:
	var out: Array = []
	for w in wizards:
		out.append(w)
	for e in enemies:
		if is_instance_valid(e) and e.alive:
			out.append(e)
	return out


func spawn(n: Node3D, at: Vector3) -> void:
	n.position = at
	fx_root.add_child(n)


func add_enemy(e: Enemy) -> void:
	enemies.append(e)
	add_child(e)


func on_enemy_died(e: Enemy, _src: Actor) -> void:
	run.kills += 1
	count("kills")
	enemies.erase(e)
	if randf() < (0.5 if e.elite else 0.12):
		_globe(e.global_position)


func on_cast(w: Wizard, s: Dictionary) -> void:
	var key: String = s.key
	if key == "" or s.shape in ["staff", "stomp", "fizzle"]:
		return
	_trace("cast %s %s" % [w.player_name, s.name])
	count("casts")
	if not grimoire.has(key):
		grimoire[key] = s.name
		hud.toast("%s discovered %s" % [w.player_name, s.name], Color(1.0, 0.82, 0.35))
		hud.set_grimoire(grimoire.size(), spell_total)
		_save_grimoire()


func toast(w: Wizard, relic: Dictionary) -> void:
	hud.toast("%s took %s: %s" % [w.player_name, relic.name, relic.text], w.robe.lightened(0.4))


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func summon_circle(at: Vector3) -> void:
	var c := Color(0.8, 0.08, 0.05)
	Fx.ring(at, c, 1.2, 0.8)
	Fx.burst(at, c, 12, 2.0, 0.25)
	Fx.light_pop(at, c, 2.0, 4.0, 0.9)


func _globe(at: Vector3) -> void:
	var g := Node3D.new()
	Art.part(g, Art.sphere(0.12, 8), Fx.glow(Color(0.85, 0.05, 0.05), 2.5), Vector3(0, 0.5, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.1, 0.1)
	l.light_energy = 0.6
	l.omni_range = 1.8
	l.position.y = 0.6
	g.add_child(l)
	spawn(g, Vector3(at.x, 0, at.z))
	_globes.append(g)


# --- Every frame ---------------------------------------------------------

func count(what: String, n := 1) -> void:
	stats[what] = int(stats.get(what, 0)) + n


func _physics_process(dt: float) -> void:
	_frame += 1
	if sim_frames > 0 and _frame == sim_frames:
		get_tree().quit(Sim.report(self))
	_confluence(dt)
	for g in _globes.duplicate():
		if not is_instance_valid(g):
			_globes.erase(g)
			continue
		g.get_child(0).position.y = 0.5 + sin(Time.get_ticks_msec() / 300.0) * 0.1
		for w in wizards:
			if w.alive and w.global_position.distance_to(g.global_position) < 1.0:
				w.healed(30.0)
				Fx.burst(g.global_position + Vector3.UP * 0.5, Color(1, 0.1, 0.1), 16, 3.0)
				_globes.erase(g)
				g.queue_free()
				break
	_dmg_t -= dt
	if _dmg_t <= 0.0:
		_dmg_t = 0.3
		for a in wizards + enemies:
			if is_instance_valid(a):
				_numbers(a)


## Small floating numbers for what an actor took and healed since the last
## time: white on monsters, gold and bigger on a weakness, grey and smaller
## when it resists, red on wizards, green for healing.
func _numbers(a: Actor) -> void:
	var s: Dictionary = a.shown
	var top: Vector3 = a.global_position + Vector3.UP * (2.6 if a is Wizard else 1.4 + a.radius * 1.4)
	var side := Vector3(randf_range(-0.35, 0.35), 0, 0)
	if s.dmg >= 1.0:
		var txt := "%d" % roundi(s.dmg)
		var c := Color(0.95, 0.92, 0.85)
		var size := 30
		if a is Wizard:
			c = Color(1.0, 0.3, 0.25)
		elif s.weak:
			txt += "!"
			c = Color(1.0, 0.72, 0.15)
			size = 42
		elif s.resist:
			c = Color(0.6, 0.62, 0.68)
			size = 24
		Fx.text(top + side, txt, c, size, 0.8)
	elif s.resist and a is Enemy:
		Fx.text(top + side, "resist", Color(0.6, 0.62, 0.68), 22, 0.8)
	if s.heal >= 1.0:
		Fx.text(top - side + Vector3.UP * 0.25, "+%d" % roundi(s.heal), Color(0.4, 1.0, 0.45), 28, 0.9)
	a.shown = {dmg = 0.0, heal = 0.0, weak = false, resist = false}


## Two wizards' streams that cross meet in the middle: the elements of both
## mix by the queue rules (water and fire make steam) and burst there.
func _confluence(dt: float) -> void:
	var streams: Array = []
	for c in fx_root.get_children():
		if c is SpellFx and c.is_stream and c.is_physics_processing():
			streams.append(c)
	for k in _confluence_t.keys():
		_confluence_t[k] -= dt
	for i in streams.size():
		for j in range(i + 1, streams.size()):
			var a: SpellFx = streams[i]
			var b: SpellFx = streams[j]
			if a.caster == b.caster:
				continue
			var hit = Geometry2D.segment_intersects_segment(
				Vector2(a.stream_from.x, a.stream_from.z), Vector2(a.stream_to.x, a.stream_to.z),
				Vector2(b.stream_from.x, b.stream_from.z), Vector2(b.stream_to.x, b.stream_to.z))
			if hit == null:
				continue
			var key := "%d-%d" % [a.get_instance_id(), b.get_instance_id()]
			if _confluence_t.get(key, 0.0) > 0.0:
				continue
			_confluence_t[key] = 0.45
			var q := SpellQueue.new()
			q.size = 10
			for e in a.spell.slots + b.spell.slots:
				q.add(e)
			var s := Grammar.compose(q.copy(), "nova")
			if s.shape != "nova":
				continue
			var nova := NovaFx.new().setup(a.caster, s) as NovaFx
			nova.n = {radius = 2.4, rate = 0.9}
			nova.spare_caster = false
			spawn(nova, Vector3(hit.x, 0, hit.y))
			if not confluences.has(s.key):
				confluences[s.key] = s.name
				hud.toast("Confluence: " + s.name, Color(0.7, 0.9, 1.0))
				Fx.text(Vector3(hit.x, 2.5, hit.y), "Confluence!", Color(0.7, 0.9, 1.0), 50, 1.4)


func _process(dt: float) -> void:
	_update_camera(dt)


func _update_camera(dt: float) -> void:
	if camera == null:
		return
	var pts: Array = []
	# Wizards move on the physics tick and are drawn in between
	# (physics_interpolation), so follow where they are drawn: following the
	# raw tick position on a 120 Hz screen shows every wizard twice.
	for w in wizards:
		if w.alive:
			pts.append(w.get_global_transform_interpolated().origin)
	if pts.is_empty():
		for w in wizards:
			pts.append(w.get_global_transform_interpolated().origin)
	var center := Vector3.ZERO
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in pts:
		center += p
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	if not pts.is_empty():
		center /= pts.size()
	var spread := maxf((hi.x - lo.x) * 0.56, hi.y - lo.y) if not pts.is_empty() else 0.0
	var want_h := clampf(11.0 + spread * 0.85, 14.0, 28.0)
	var k := 1.0 - exp(-3.0 * dt)
	_cam_center = _cam_center.lerp(center, k)
	_cam_height = lerpf(_cam_height, want_h, k)
	var c := _cam_center + Vector3(0, 0, -1.5)
	var pos := c + Vector3(0, _cam_height, _cam_height * 0.55)
	_shake = maxf(0.0, _shake - dt * 2.5)
	var jitter := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * _shake * 0.6
	camera.global_position = pos + jitter
	camera.look_at(c + jitter * 0.5, Vector3.UP)


func _world() -> void:
	env = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.25, 0.3, 0.4)
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	e.glow_enabled = true
	e.glow_intensity = 0.8
	e.glow_bloom = 0.12
	e.glow_hdr_threshold = 0.8
	e.fog_enabled = true
	e.fog_light_color = Color(0.08, 0.1, 0.12)
	e.fog_density = 0.006
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.85
	e.adjustment_contrast = 1.1
	env.environment = e
	add_child(env)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-62, 28, 0)
	moon.light_color = Color(0.45, 0.55, 0.75)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	camera = Camera3D.new()
	# The camera moves every drawn frame itself, so it is not interpolated.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.fov = 42.0
	camera.far = 200.0
	add_child(camera)
	camera.position = Vector3(0, 20, 12)
	camera.look_at(Vector3.ZERO)


func apply_biome(b: Dictionary) -> void:
	var e := env.environment
	e.ambient_light_color = b.ambient
	e.fog_light_color = b.fog
	moon.light_color = b.moon
	moon.light_energy = b.moon_energy * 1.8 + 0.15


# --- Grimoire ------------------------------------------------------------

const GRIMOIRE_PATH := "user://grimoire.json"


func _load_grimoire() -> void:
	if demo:
		return
	var f := FileAccess.open(GRIMOIRE_PATH, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			grimoire = d


func _save_grimoire() -> void:
	if demo:
		return
	var f := FileAccess.open(GRIMOIRE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(grimoire))


# --- Input and screenshots -----------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if session != "":
			GameNight.request_overlay()
		elif not GameNight.launched_by_daemon:
			get_tree().quit()


func _take_shot() -> void:
	for _f in shot_frames:
		await get_tree().physics_frame
	if "--menu" in OS.get_cmdline_user_args():
		menu.open(false)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot)
	print("saved ", shot)
	get_tree().quit()

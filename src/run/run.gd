class_name Run
extends Node3D
## A descent: five biomes of three rooms, the third a boss. A room is a long
## hall: walk it along the path, and each time the wizards get further in a
## new encounter comes at them from ahead. Beat them all, take a tome from an
## altar at the far end, step into the portal together.

signal room_started(biome: Dictionary, room: int)
signal banner(text: String, sub: String, color: Color)

const ROOMS := 3
const PORTAL_R := 1.7
## Everyone stands in the portal's ring this long to go on.
const PORTAL_TIME := 1.2

var biome_index := 0
var room := 0
var state := "fight"   # fight, cleared, travel, dead, won
var waves_left := 0
var wave_t := 0.0
var spawn_queue: Array = []
var spawn_t := 0.0
## How far into the room (z, going down) the front wizard must get to start
## each encounter still to come, nearest first.
var encounters: Array[float] = []
## Where the encounter being spawned started; its monsters come from ahead of it.
var _wave_z := INF
var rng := RandomNumberGenerator.new()
var seed_value := 1
var kills := 0
var altars: Array = []
var portal: Node3D
var _portal_t := 0.0
var _end_t := 0.0
var boss: Enemy


func depth() -> int:
	return biome_index * ROOMS + room


func start(s: int) -> void:
	seed_value = s
	rng.seed = s
	biome_index = 0
	room = 0
	kills = 0
	for w in Game.I.wizards:
		w.reset_relics()
		w.revive(1.0)
		w.hp = w.max_hp
	enter_room()


func enter_room() -> void:
	_clear_room()
	state = "fight"
	Game.I.arena.build(biome_index, room, seed_value * 31 + depth())
	Game.I.apply_biome(Game.I.arena.biome)
	var sz: float = Game.I.arena.start_z
	var starts := [Vector3(-1.5, 0, sz - 1), Vector3(1.5, 0, sz - 1), Vector3(-3.5, 0, sz + 0.5), Vector3(3.5, 0, sz + 0.5), Vector3(0, 0, sz + 1.5), Vector3(-5, 0, sz + 1.5)]
	var i := 0
	for w in Game.I.wizards:
		if not w.alive:
			w.revive(0.4)
		w.global_position = starts[i % starts.size()]
		w.reset_physics_interpolation()
		w.velocity = Vector3.ZERO
		w.push = Vector3.ZERO
		w.aim_dir = Vector3.FORWARD
		i += 1
	wave_t = 2.0
	encounters.clear()
	_wave_z = INF
	if room == 2:
		# The boss room is a short arena: the boss and one wave, at once.
		var b: String = Game.I.arena.biome.boss
		spawn_enemy(b, Vector3(0, 0, Game.I.arena.altar_z - 4.0), false)
		banner.emit(Enemy.KINDS[b].name, Game.I.arena.biome.name, Color(1.0, 0.7, 0.3))
		encounters.append(INF)
	else:
		# Spread along the hall: the first a few steps in, the last guarding
		# the altars.
		var n := 3 + int(room == 1)
		var first: float = Game.I.arena.start_z - 3.0
		var last: float = Game.I.arena.altar_z + 7.0
		for k in n:
			encounters.append(lerpf(first, last, float(k) / (n - 1)))
	waves_left = encounters.size()
	# Where you are (biome, room, level) is in the pause menu, not on screen.
	room_started.emit(Game.I.arena.biome, room)


func _clear_room() -> void:
	for e in Game.I.enemies:
		if is_instance_valid(e):
			e.queue_free()
	Game.I.enemies.clear()
	for c in Game.I.fx_root.get_children():
		c.queue_free()
	for a in altars:
		if is_instance_valid(a.node):
			a.node.queue_free()
	altars.clear()
	if portal:
		portal.queue_free()
		portal = null
	spawn_queue.clear()
	encounters.clear()
	boss = null


func _queue_wave(players: int) -> void:
	waves_left -= 1
	var mix: Dictionary = Game.I.arena.biome.enemies
	var pool: Array = []
	for k in mix:
		for _i in mix[k]:
			pool.append(k)
	var count := int((3 + 2.2 * players) * (1.0 + 0.12 * depth()) * Game.I.monster_count)
	# The first biome is where you learn to shoot and roll: fewer monsters.
	if biome_index == 0:
		count = maxi(2, int(count * 0.6))
	if room == 2:
		count = int(count * 0.5)
	for _i in count:
		spawn_queue.append(pool[rng.randi() % pool.size()])


func spawn_enemy(k: String, at: Vector3, telegraph := true) -> void:
	var players := maxi(1, Game.I.wizards.size())
	var hp_scale := (1.0 + 0.35 * (players - 1)) * (1.0 + 0.11 * depth()) * Game.I.monster_hp
	var champ := rng.randf() < 0.06 + 0.01 * depth()
	if telegraph:
		Game.I.summon_circle(at)
		await get_tree().create_timer(0.8).timeout
		if state != "fight" and not Enemy.KINDS[k].get("boss", false):
			return
	var e := Enemy.new().setup(k, hp_scale, champ)
	e.position = Game.I.arena.clamp_inside(at)
	Game.I.add_enemy(e)
	if Enemy.KINDS[k].get("boss", false):
		boss = e


func _physics_process(dt: float) -> void:
	if not Game.I or Game.I.paused_play:
		return
	match state:
		"fight":
			_fight(dt)
		"cleared":
			_cleared(dt)
		"dead", "won":
			_end_t -= dt
			if _end_t <= 0.0:
				Game.I.new_run()
	if state in ["fight", "cleared"] and Game.I.wizards.size() > 0 and Game.I.wizards.all(func(w): return not w.alive):
		state = "dead"
		_end_t = 9.0
		banner.emit("You have perished", "%s, level %d. %d monsters slain." % [Game.I.arena.biome.name, depth() + 1, kills], Color(0.75, 0.05, 0.05))
		Game.I.run_over(false)


## How far into the room the front living wizard is (the lowest z).
func lead_z() -> float:
	var z := INF
	for w in Game.I.wizards:
		if w.alive:
			z = minf(z, w.global_position.z)
	return z


func _fight(dt: float) -> void:
	var lead := lead_z()
	if not encounters.is_empty() and lead < encounters[0]:
		encounters.pop_front()
		_wave_z = lead
		wave_t = 0.0
		_queue_wave(maxi(1, Game.I.wizards.size()))
	spawn_t -= dt
	if not spawn_queue.is_empty() and spawn_t <= 0.0:
		spawn_t = 0.35
		var at: Vector3 = Game.I.arena.spawn_point(Game.I.wizards) if _wave_z == INF \
			else Game.I.arena.spawn_ahead(_wave_z, 7.0, 13.0, Game.I.wizards)
		spawn_enemy(spawn_queue.pop_front(), at)
	var alive_count := Game.I.enemies.filter(func(e): return e.alive).size()
	if spawn_queue.is_empty():
		wave_t -= dt
		if encounters.is_empty() and alive_count == 0 and wave_t < -1.5:
			_room_cleared()


## Where a wizard with nothing to fight walks to: along the path, a few
## metres further in than the front wizard (bots use it).
func walk_goal(w: Wizard) -> Vector3:
	var ahead := minf(lead_z(), w.global_position.z) - 4.0
	for p in Game.I.arena.path:
		if p.y < ahead:
			return Vector3(p.x, 0, p.y)
	return Vector3(0, 0, Game.I.arena.altar_z)


func _room_cleared() -> void:
	if biome_index == Arena.BIOMES.size() - 1 and room == ROOMS - 1:
		state = "won"
		_end_t = 12.0
		banner.emit("The Pit is sealed", "Your names will be sung. %d monsters slain." % kills, Color(1.0, 0.8, 0.35))
		Game.I.run_over(true)
		return
	state = "cleared"
	banner.emit("Room cleared", "Each wizard may take one tome", Color(0.9, 0.75, 0.4))
	for w in Game.I.wizards:
		if not w.alive:
			w.revive(0.3)
	var n := Game.I.wizards.size() + 1
	var taken: Array = []
	for w in Game.I.wizards:
		for r in w.relics:
			taken.append(r.get("name", ""))
	var picks := Relics.pick(n, rng, taken)
	for i in picks.size():
		var x := (i - (picks.size() - 1) * 0.5) * 3.2
		var node := _altar(picks[i])
		node.position = Vector3(x, 0, Game.I.arena.altar_z)
		Game.I.arena.add_child(node)
		altars.append({node = node, relic = picks[i], taken = false, hold = 0.0,
			fill = node.get_meta("fill")})
	portal = _portal()
	portal.position = Vector3(0, 0, Game.I.arena.portal_z)
	Game.I.arena.add_child(portal)
	_portal_t = 0.0


## Stand in an altar's ring this long to take its tome.
const TAKE_TIME := 0.9
const ALTAR_R := 1.4


func _cleared(dt: float) -> void:
	for a in altars:
		if a.taken:
			continue
		# The ring round the altar fills while a wizard who has not taken a
		# tome this level stands in it; full, the tome is theirs.
		var taker: Wizard = null
		for w in Game.I.wizards:
			if not w.alive or w.get_meta("took", -1) == depth():
				continue
			if Vector2(w.global_position.x - a.node.global_position.x, w.global_position.z - a.node.global_position.z).length() < ALTAR_R:
				taker = w
				break
		a.hold = minf(a.hold + dt, TAKE_TIME) if taker else maxf(a.hold - dt * 2.0, 0.0)
		var fill_mat: ShaderMaterial = a.fill.material_override
		fill_mat.set_shader_parameter("progress", a.hold / TAKE_TIME)
		if taker:
			fill_mat.set_shader_parameter("color", taker.robe.lightened(0.35))
		if taker and a.hold >= TAKE_TIME:
			a.taken = true
			taker.set_meta("took", depth())
			taker.give_relic(a.relic)
			Fx.burst(a.node.global_position + Vector3.UP * 1.3, Color(1.0, 0.8, 0.4), 30, 4.0)
			Fx.ring(a.node.global_position, taker.robe.lightened(0.35), ALTAR_R + 0.4, 0.4)
			Game.I.toast(taker, a.relic)
			var tw: Tween = a.node.create_tween()
			tw.tween_property(a.node, "scale", Vector3(1, 0.01, 1), 0.4)
			tw.tween_callback(a.node.queue_free)
	var living := Game.I.wizards.filter(func(w): return w.alive)
	var inside := living.filter(func(w): return w.global_position.distance_to(portal.global_position) < PORTAL_R)
	if not living.is_empty() and inside.size() == living.size():
		_portal_t += dt
		if _portal_t >= PORTAL_TIME:
			_travel()
			return
	else:
		_portal_t = maxf(_portal_t - dt * 2.0, 0.0)
	var fill: MeshInstance3D = portal.get_meta("fill")
	(fill.material_override as ShaderMaterial).set_shader_parameter("progress", _portal_t / PORTAL_TIME)


## Through the portal: the wizards vanish into it in a flash, the screen
## goes black, and it opens again on the next room.
func _travel() -> void:
	state = "travel"
	var at := portal.global_position
	Fx.burst(at + Vector3.UP * 1.4, Color(0.55, 0.75, 1.0), 40, 6.0, 0.35)
	Fx.light_pop(at, Color(0.55, 0.75, 1.0), 6.0, 10.0, 0.5)
	for w in Game.I.wizards:
		Fx.burst(w.global_position + Vector3.UP, w.robe.lightened(0.3), 14, 3.0, 0.25)
	Game.I.hud.fade_to(1.0, 0.35)
	await get_tree().create_timer(0.4).timeout
	if state == "travel":
		_next()
	Game.I.hud.fade_to(0.0, 0.6)


func _next() -> void:
	# Every level starts fresh: full health and mana, the fallen back up.
	for w in Game.I.wizards:
		if not w.alive:
			w.revive(1.0)
		w.hp = w.max_hp
		w.mana = Wizard.MANA_MAX
	room += 1
	if room >= ROOMS:
		room = 0
		biome_index += 1
	enter_room()


func _altar(relic: Dictionary) -> Node3D:
	var n := Node3D.new()
	var stone := Fx.solid(Color(0.3, 0.28, 0.27))
	Art.part(n, Art.cyl(0.35, 0.45, 0.9, 8), stone, Vector3(0, 0.45, 0))
	Art.part(n, Art.box(0.8, 0.1, 0.6), stone, Vector3(0, 0.95, 0))
	var book := Node3D.new()
	book.position = Vector3(0, 1.35, 0)
	n.add_child(book)
	Art.part(book, Art.box(0.5, 0.1, 0.38), Fx.solid(Color(0.4, 0.1, 0.08)), Vector3.ZERO, Vector3(-30, 0, 0))
	Art.part(book, Art.box(0.46, 0.06, 0.34), Fx.solid(Color(0.85, 0.8, 0.65)), Vector3(0, 0.06, 0.02), Vector3(-30, 0, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.45)
	l.light_energy = 1.6
	l.omni_range = 3.5
	l.position.y = 1.8
	n.add_child(l)
	_fill_ring(n, ALTAR_R, Color(1.0, 0.8, 0.45))
	var sparks := Fx.particles(Color(1.0, 0.8, 0.4), 16, 1.2, 0.15)
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.4
	sparks.direction = Vector3.UP
	sparks.initial_velocity_max = 0.6
	sparks.gravity = Vector3.UP * 0.5
	sparks.position.y = 1.3
	n.add_child(sparks)
	sparks.emitting = true
	var lbl := Label3D.new()
	lbl.text = relic.name + "\n" + relic.text
	lbl.font = Art.body_font()
	lbl.font_size = 30
	lbl.outline_size = 10
	lbl.outline_modulate = Color(0, 0, 0, 0.9)
	lbl.modulate = Color(1.0, 0.85, 0.55)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.pixel_size = 0.005
	lbl.width = 420
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.position.y = 2.3
	n.add_child(lbl)
	return n


## The ring to stand in, on [param n]'s floor: a faint guide, and a fill that
## sweeps round it while you stand there (meta "fill", see _cleared).
static func _fill_ring(n: Node3D, r: float, c: Color) -> void:
	var slash := preload("res://src/fx/slash.gdshader")
	for k in 2:
		var ring := MeshInstance3D.new()
		ring.mesh = Wizard._arc_mesh(r - 0.18, r, PI)
		var m := ShaderMaterial.new()
		m.shader = slash
		m.set_shader_parameter("color", c)
		m.set_shader_parameter("progress", 1.0 if k == 0 else 0.0)
		m.set_shader_parameter("strength", 0.45 if k == 0 else 1.6)
		ring.material_override = m
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position.y = 0.05 + 0.01 * k
		n.add_child(ring)
		if k == 1:
			n.set_meta("fill", ring)


func _portal() -> Node3D:
	var n := Node3D.new()
	var c := Color(0.3, 0.55, 1.0)
	var tor := TorusMesh.new()
	tor.inner_radius = 1.25
	tor.outer_radius = 1.45
	tor.rings = 32
	tor.ring_segments = 8
	var ring := Art.part(n, tor, Fx.glow(c, 3.0), Vector3(0, 1.6, 0), Vector3(90, 0, 0))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var disc := Art.part(n, Art.cyl(1.25, 1.25, 0.02, 32), Fx.additive(Color(0.2, 0.4, 1.0, 0.6), 1.2), Vector3(0, 1.6, 0), Vector3(90, 0, 0))
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Everyone stands in the ring until it fills, as at an altar.
	_fill_ring(n, PORTAL_R, Color(0.55, 0.75, 1.0))
	var p := Fx.particles(c, 60, 1.2, 0.3)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3(0, 0, 1)
	p.emission_ring_radius = 1.35
	p.emission_ring_inner_radius = 1.1
	p.emission_ring_height = 0.1
	p.position.y = 1.6
	p.direction = Vector3.UP
	p.initial_velocity_max = 0.5
	n.add_child(p)
	p.emitting = true
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 2.5
	l.omni_range = 7.0
	l.position.y = 1.6
	n.add_child(l)
	return n

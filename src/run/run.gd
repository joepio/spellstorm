class_name Run
extends Node3D
## A descent: five biomes, one big level each. Walk the level along its
## path; each time the wizards get further in, monsters come at them from
## ahead. Two clearings on the way are held by a larger pack: beat it and a
## shrine of tomes rises there (and the fallen get back up). At the end of
## the level is the boss's arena; beat the boss for the last shrine and the
## portal on to the next biome.

signal level_started(biome: Dictionary, level: int)
signal banner(text: String, sub: String, color: Color)

const PORTAL_R := 1.7
## Everyone stands in the portal's ring this long to go on.
const PORTAL_TIME := 1.2
## Metres along the path between the packs that come at you on the way.
const WAVE_GAP := 34.0

var biome_index := 0
var state := "fight"   # fight, cleared, travel, dead, won
var spawn_queue: Array = []
var spawn_t := 0.0
## What is still to come, nearest first: {at = metres along the path the
## front wizard must reach, kind = "wave", "guard" (a clearing, with the
## shrine it holds) or "boss"}.
var encounters: Array = []
## How far along the path the encounter being spawned started; its monsters
## come from ahead of it.
var _wave_at := -1.0
## Clearings whose pack has come; their shrine rises once the field is clear.
var _pending: Array[int] = []
var rng := RandomNumberGenerator.new()
var seed_value := 1
var kills := 0
## Every tome on a shrine: {node, relic, taken, hold, fill, shrine}.
var altars: Array = []
var portal: Node3D
var _portal_t := 0.0
var _end_t := 0.0
var _quiet_t := 0.0
var boss: Enemy


## How deep in the run this level is (0 is the first).
func depth() -> int:
	return biome_index


func start(s: int) -> void:
	seed_value = s
	rng.seed = s
	biome_index = 0
	kills = 0
	for w in Game.I.wizards:
		w.reset_relics()
		for m in w.get_meta_list():
			if String(m).begins_with("took_"):
				w.remove_meta(m)
		w.revive(1.0)
		w.hp = w.max_hp
	enter_level()


func enter_level() -> void:
	_clear_level()
	state = "fight"
	var arena: Arena = Game.I.arena
	arena.build(biome_index, seed_value * 31 + depth())
	Game.I.apply_biome(arena.biome)
	var sz := arena.start
	var starts := [Vector2(-1.5, -1), Vector2(1.5, -1), Vector2(-3.5, 0.5), Vector2(3.5, 0.5), Vector2(0, 1.5), Vector2(-5, 1.5)]
	var i := 0
	for w in Game.I.wizards:
		if not w.alive:
			w.revive(0.4)
		var at: Vector2 = sz + starts[i % starts.size()]
		w.global_position = Vector3(at.x, 0, at.y)
		w.reset_physics_interpolation()
		w.velocity = Vector3.ZERO
		w.push = Vector3.ZERO
		w.aim_dir = Vector3.FORWARD
		i += 1
	# Packs along the way, every WAVE_GAP metres from a few steps in; the two
	# clearings' packs where they are; the boss at the arena's edge.
	var guards: Array = []
	for k in 2:
		guards.append({at = arena.clearing_at[k] - arena.clearings[k].z * 0.6, kind = "guard", shrine = k})
	var boss_at: float = arena.clearing_at[2] - arena.clearings[2].z * 0.8
	var at_run := 8.0
	while at_run < boss_at - 12.0:
		var near_guard := false
		for g in guards:
			if absf(g.at - at_run) < 12.0:
				near_guard = true
		if not near_guard:
			encounters.append({at = at_run, kind = "wave"})
		at_run += WAVE_GAP * rng.randf_range(0.85, 1.15)
	encounters.append_array(guards)
	encounters.append({at = boss_at, kind = "boss"})
	encounters.sort_custom(func(a, b): return a.at < b.at)
	# Where you are (biome, level) is in the pause menu, not on screen.
	level_started.emit(arena.biome, depth())


## For testing: put the wizards [param run] metres along the level, as if
## they had walked there and the packs on the way were never met.
func skip_to(run: float) -> void:
	encounters = encounters.filter(func(e): return e.at >= run)
	var arena: Arena = Game.I.arena
	var c := arena.point_at(run)
	var i := 0
	for w in Game.I.wizards:
		w.global_position = Vector3(c.x + (i % 3 - 1) * 1.5, 0, c.y + (i / 3) * 1.5)
		w.reset_physics_interpolation()
		i += 1


func _clear_level() -> void:
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
	_pending.clear()
	_wave_at = -1.0
	boss = null


func _queue_wave(players: int, scale: float) -> void:
	var mix: Dictionary = Game.I.arena.biome.enemies
	var pool: Array = []
	for k in mix:
		for _i in mix[k]:
			pool.append(k)
	var count := int((2.0 + 1.6 * players) * (1.0 + 0.3 * depth()) * Game.I.monster_count * scale)
	# The first biome is where you learn to shoot and roll: fewer monsters.
	if biome_index == 0:
		count = maxi(2, int(count * 0.6))
	while count > 0:
		# Some come in packs (hellhounds): the whole pack at once.
		var k: String = pool[rng.randi() % pool.size()]
		if Enemy.KINDS[k].get("solo", false) and k in spawn_queue:
			continue
		for _j in int(Enemy.KINDS[k].get("pack", 1)):
			spawn_queue.append(k)
			count -= 1


func spawn_enemy(k: String, at: Vector3, telegraph := true) -> void:
	var players := maxi(1, Game.I.wizards.size())
	var hp_scale := (1.0 + 0.35 * (players - 1)) * (1.0 + 0.33 * depth()) * Game.I.monster_hp
	var champ := rng.randf() < 0.06 + 0.03 * depth()
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
			_shrines(dt)
		"cleared":
			_shrines(dt)
			_portal_step(dt)
		"dead", "won":
			_end_t -= dt
			if _end_t <= 0.0:
				Game.I.new_run()
	if state in ["fight", "cleared"] and Game.I.wizards.size() > 0 and Game.I.wizards.all(func(w): return not w.alive):
		state = "dead"
		_end_t = 9.0
		banner.emit("You have perished", "%s, level %d. %d monsters slain." % [Game.I.arena.biome.name, depth() + 1, kills], Color(0.75, 0.05, 0.05))
		Game.I.run_over(false)


## How far along the level's path the front living wizard is.
func lead_progress() -> float:
	var best := -1.0
	for w in Game.I.wizards:
		if w.alive:
			best = maxf(best, Game.I.arena.progress_of(Vector2(w.global_position.x, w.global_position.z)))
	return best


var _lead := 0.0
var _lead_t := 0.0


func _fight(dt: float) -> void:
	# The lead only matters a few times a second.
	_lead_t -= dt
	if _lead_t <= 0.0:
		_lead_t = 0.2
		_lead = lead_progress()
	# The next pack holds off while the field is still full of the last ones.
	var alive_count := Game.I.enemies.filter(func(e): return e.alive).size()
	while not encounters.is_empty() and _lead >= encounters[0].at and alive_count + spawn_queue.size() < 9:
		var enc: Dictionary = encounters.pop_front()
		_wave_at = _lead
		var players := maxi(1, Game.I.wizards.size())
		match enc.kind:
			"wave":
				_queue_wave(players, 1.0)
			"guard":
				_queue_wave(players, 1.5)
				_pending.append(enc.shrine)
			"boss":
				var arena: Arena = Game.I.arena
				var c: Vector3 = arena.clearings[2]
				var b: String = arena.biome.boss
				spawn_enemy(b, Vector3(c.x, 0, c.y), false)
				banner.emit(Enemy.KINDS[b].name, arena.biome.name, Color(1.0, 0.7, 0.3))
				_queue_wave(players, 0.5)
	spawn_t -= dt
	if not spawn_queue.is_empty() and spawn_t <= 0.0:
		spawn_t = 0.35
		var k: String = spawn_queue.pop_front()
		spawn_enemy(k, _spawn_spot(k), Enemy.KINDS[k].get("spawn", "") != "under")
	alive_count = Game.I.enemies.filter(func(e): return e.alive).size()
	_quiet_t = _quiet_t + dt if spawn_queue.is_empty() and alive_count == 0 else 0.0
	if _quiet_t < 1.5:
		return
	# The field is clear: the shrines of beaten clearings rise.
	for k in _pending:
		_raise_shrine(k)
	_pending.clear()
	if encounters.is_empty() and (boss == null or not is_instance_valid(boss) or not boss.alive):
		_level_cleared()


## Where a monster of [param k] comes in, by what it is: archers and
## necromancers far ahead among the props, lurkers already under the floor
## close by, hounds round behind you, toads out in the water, the rest
## from ahead along the path.
func _spawn_spot(k: String) -> Vector3:
	var arena: Arena = Game.I.arena
	var wz: Array = Game.I.wizards
	if _wave_at < 0.0:
		return arena.spawn_point(wz)
	match Enemy.KINDS[k].get("spawn", ""):
		"far":
			return arena.spawn_ahead(_wave_at, 15.0, 22.0, wz)
		"under":
			return arena.spawn_ahead(_wave_at, 4.0, 10.0, wz)
		"flank":
			return arena.spawn_ahead(_wave_at, -12.0, -5.0, wz)
		"water":
			return arena.spawn_ahead(_wave_at, 8.0, 16.0, wz, 1.0)
	return arena.spawn_ahead(_wave_at, 7.0, 15.0, wz)


## Where a wizard with nothing to fight walks to: along the path, a few
## metres further than the front wizard (bots use it).
func walk_goal(w: Wizard) -> Vector3:
	var arena: Arena = Game.I.arena
	var mine := arena.progress_of(Vector2(w.global_position.x, w.global_position.z))
	var p := arena.point_at(maxf(_lead, mine) + 5.0)
	return Vector3(p.x, 0, p.y)


## A tome [param w] may still take, near enough to walk to, or null.
func tome_for(w: Wizard) -> Variant:
	for a in altars:
		if a.taken or w.get_meta("took_" + a.shrine, false):
			continue
		if is_instance_valid(a.node) and a.node.global_position.distance_to(w.global_position) < 30.0:
			return a
	return null


## A shrine of tomes rises at clearing [param k] (2 is the boss's arena):
## one for each wizard and one spare, and the fallen get back up.
func _raise_shrine(k: int) -> void:
	var arena: Arena = Game.I.arena
	var c: Vector3 = arena.clearings[k]
	banner.emit("A shrine rises" if k < 2 else "%s is slain" % Enemy.KINDS[arena.biome.boss].name, "Each wizard may take one tome", Color(0.9, 0.75, 0.4))
	for w in Game.I.wizards:
		if not w.alive:
			w.revive(0.3)
	var n := Game.I.wizards.size() + 1
	var taken: Array = []
	for w in Game.I.wizards:
		for r in w.relics:
			taken.append(r.get("name", ""))
	for a in altars:
		taken.append(a.relic.get("name", ""))
	var picks := Relics.pick(n, rng, taken)
	# Across the path, facing the way on.
	var along := arena.clearing_at[k]
	var dir := (arena.point_at(along + 1.0) - arena.point_at(along - 1.0)).normalized()
	var across := Vector2(-dir.y, dir.x)
	var mid := Vector2(c.x, c.y) + (dir * -2.0 if k == 2 else Vector2.ZERO)
	for i in picks.size():
		var p := mid + across * (i - (picks.size() - 1) * 0.5) * 3.2
		var node := _altar(picks[i])
		node.position = Vector3(p.x, 0, p.y)
		arena.add_child(node)
		node.scale = Vector3(1, 0.01, 1)
		node.create_tween().tween_property(node, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.burst(node.position + Vector3.UP, Color(1.0, 0.8, 0.4), 16, 3.0)
		altars.append({node = node, relic = picks[i], taken = false, hold = 0.0,
			fill = node.get_meta("fill"), shrine = "%d_%d" % [biome_index, k]})


func _level_cleared() -> void:
	if biome_index == Arena.BIOMES.size() - 1:
		state = "won"
		_end_t = 12.0
		banner.emit("The Pit is sealed", "Your names will be sung. %d monsters slain." % kills, Color(1.0, 0.8, 0.35))
		Game.I.run_over(true)
		return
	state = "cleared"
	_raise_shrine(2)
	portal = _portal()
	var pa: Vector2 = Game.I.arena.portal_at
	portal.position = Vector3(pa.x, 0, pa.y)
	Game.I.arena.add_child(portal)
	_portal_t = 0.0


## Stand in an altar's ring this long to take its tome.
const TAKE_TIME := 0.9
const ALTAR_R := 1.4


func _shrines(dt: float) -> void:
	for a in altars:
		if a.taken:
			continue
		# The ring round the altar fills while a wizard who has not taken a
		# tome this level stands in it; full, the tome is theirs.
		var taker: Wizard = null
		for w in Game.I.wizards:
			if not w.alive or w.get_meta("took_" + a.shrine, false):
				continue
			if Vector2(w.global_position.x - a.node.global_position.x, w.global_position.z - a.node.global_position.z).length() < ALTAR_R:
				taker = w
				break
		a.hold = minf(a.hold + dt, TAKE_TIME) if taker else maxf(a.hold - dt * 2.0, 0.0)
		if not is_instance_valid(a.node):
			continue
		var fill_mat: ShaderMaterial = a.fill.material_override
		fill_mat.set_shader_parameter("progress", a.hold / TAKE_TIME)
		if taker:
			fill_mat.set_shader_parameter("color", taker.robe.lightened(0.35))
		if taker and a.hold >= TAKE_TIME:
			a.taken = true
			taker.set_meta("took_" + a.shrine, true)
			taker.give_relic(a.relic)
			Fx.burst(a.node.global_position + Vector3.UP * 1.3, Color(1.0, 0.8, 0.4), 30, 4.0)
			Fx.ring(a.node.global_position, taker.robe.lightened(0.35), ALTAR_R + 0.4, 0.4)
			Game.I.toast(taker, a.relic)
			var tw: Tween = a.node.create_tween()
			tw.tween_property(a.node, "scale", Vector3(1, 0.01, 1), 0.4)
			tw.tween_callback(a.node.queue_free)


func _portal_step(dt: float) -> void:
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
## goes black, and it opens again on the next level.
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
	biome_index += 1
	enter_level()


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

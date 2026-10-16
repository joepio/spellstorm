class_name Arena
extends Node3D
## One dungeon room: floor, walls, props, torches and the fields on the ground.

const HALF := Vector2(17.0, 11.0)

const BIOMES := [
	{id = "chapel", name = "The Forsaken Chapel", floor_a = Color(0.15, 0.16, 0.12), floor_b = Color(0.08, 0.09, 0.07), tiles = 0.0,
		wall = Color(0.24, 0.23, 0.22), fog = Color(0.08, 0.1, 0.12), ambient = Color(0.25, 0.3, 0.4), moon = Color(0.45, 0.55, 0.75), moon_energy = 0.35,
		props = ["grave", "grave", "grave", "dead_tree", "rock", "candles"], enemies = {ghoul = 3, skeleton = 3, archer = 2}, boss = "gravekeeper", fields = []},
	{id = "catacombs", name = "The Catacombs", floor_a = Color(0.2, 0.18, 0.16), floor_b = Color(0.12, 0.11, 0.1), tiles = 1.0,
		wall = Color(0.26, 0.22, 0.2), fog = Color(0.07, 0.05, 0.04), ambient = Color(0.3, 0.22, 0.16), moon = Color(0.6, 0.45, 0.35), moon_energy = 0.12,
		props = ["pillar", "pillar", "bones", "candles", "sarcophagus"], enemies = {skeleton = 3, cultist = 2, bile = 1, archer = 1}, boss = "abbot", fields = []},
	{id = "caves", name = "The Drowned Caves", floor_a = Color(0.12, 0.14, 0.15), floor_b = Color(0.06, 0.08, 0.09), tiles = 0.0, wet = 1.0,
		wall = Color(0.18, 0.2, 0.21), fog = Color(0.03, 0.07, 0.08), ambient = Color(0.15, 0.3, 0.32), moon = Color(0.3, 0.6, 0.6), moon_energy = 0.15,
		props = ["stalagmite", "stalagmite", "mushroom", "mushroom", "rock"], enemies = {drowned = 3, bile = 2, ghoul = 2}, boss = "drowned_king", fields = [El.WATER, El.WATER, El.WATER, El.WATER]},
	{id = "keep", name = "The Frozen Keep", floor_a = Color(0.26, 0.29, 0.34), floor_b = Color(0.15, 0.17, 0.21), tiles = 1.0,
		wall = Color(0.35, 0.38, 0.45), fog = Color(0.12, 0.15, 0.2), ambient = Color(0.25, 0.32, 0.42), moon = Color(0.55, 0.7, 0.95), moon_energy = 0.3,
		props = ["ice", "ice", "pillar", "rock"], enemies = {wraith = 2, skeleton = 2, frost_brute = 1, ghoul = 1}, boss = "warden", fields = [El.FROST, El.FROST, El.FROST]},
	{id = "pit", name = "The Infernal Pit", floor_a = Color(0.13, 0.08, 0.07), floor_b = Color(0.05, 0.03, 0.03), tiles = 0.0,
		wall = Color(0.15, 0.1, 0.09), fog = Color(0.12, 0.03, 0.01), ambient = Color(0.4, 0.15, 0.08), moon = Color(1.0, 0.4, 0.2), moon_energy = 0.2,
		props = ["basalt", "basalt", "brazier", "bones"], enemies = {imp = 3, demon = 1, cultist = 2, brute = 1}, boss = "pit_lord", fields = [El.MAGMA, El.MAGMA, El.MAGMA]},
]

var biome: Dictionary
var fields: Array = []
var _torches: Array = []
var _rng := RandomNumberGenerator.new()
var _props_at: Array = []


func build(biome_index: int, room: int, seed_value: int) -> void:
	for c in get_children():
		c.queue_free()
	fields.clear()
	_torches.clear()
	_props_at.clear()
	biome = BIOMES[biome_index % BIOMES.size()]
	_rng.seed = seed_value
	_floor()
	_walls()
	var boss_room: bool = room == 2
	var count := 9 if boss_room else 14
	for i in count:
		_prop(biome.props[_rng.randi() % biome.props.size()])
	for k in biome.fields:
		var p := _free_spot(3.0)
		var f := add_field(p, k, _rng.randf_range(1.6, 3.0), 0.0, null)
		f.permanent = true
	_dust()


func _floor() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/world/floor.gdshader")
	mat.set_shader_parameter("base_a", biome.floor_a)
	mat.set_shader_parameter("base_b", biome.floor_b)
	mat.set_shader_parameter("tiles", biome.tiles)
	mat.set_shader_parameter("half_size", HALF)
	mat.set_shader_parameter("wet", biome.get("wet", 0.0))
	# The floor is cut into chunks so each chunk gets its own nearby torches
	# (the compatibility renderer lights each mesh with a few lights only).
	var chunk := 4.0
	var x := -HALF.x - 4.0
	while x < HALF.x + 4.0:
		var z := -HALF.y - 4.0
		while z < HALF.y + 6.0:
			var m := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(chunk, chunk)
			m.mesh = pm
			m.material_override = mat
			m.position = Vector3(x + chunk * 0.5, 0, z + chunk * 0.5)
			add_child(m)
			z += chunk
		x += chunk
	var ground := StaticBody3D.new()
	ground.collision_layer = 4
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(80, 1, 80)
	cs.shape = b
	cs.position.y = -0.5
	ground.add_child(cs)
	add_child(ground)


func _walls() -> void:
	var mat := Fx.solid(biome.wall, 0.95)
	var dark := Fx.solid(biome.wall.darkened(0.35), 0.95)
	# Back and sides are tall; the wall nearest the camera is low so it never
	# hides a wizard.
	var segs := [
		[Vector3(0, 0, -HALF.y - 0.6), Vector3(HALF.x * 2 + 2.4, 3.4, 1.2)],
		[Vector3(-HALF.x - 0.6, 0, 0), Vector3(1.2, 3.0, HALF.y * 2 + 2.4)],
		[Vector3(HALF.x + 0.6, 0, 0), Vector3(1.2, 3.0, HALF.y * 2 + 2.4)],
		[Vector3(0, 0, HALF.y + 0.6), Vector3(HALF.x * 2 + 2.4, 0.7, 1.2)],
	]
	for s in segs:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(s[1].x, 4.0, s[1].z)
		cs.shape = bs
		cs.position.y = 2.0
		body.add_child(cs)
		body.position = s[0]
		add_child(body)
		var h: float = s[1].y
		# Built from blocks of uneven height so it reads as masonry.
		var along_x: bool = s[1].x > s[1].z
		var length: float = s[1].x if along_x else s[1].z
		var n := int(length / 1.6)
		for i in n:
			var off := -length * 0.5 + (i + 0.5) * length / n
			var bh := h * _rng.randf_range(0.85, 1.1)
			var size := Vector3(length / n - 0.06, bh, s[1].z) if along_x else Vector3(s[1].x, bh, length / n - 0.06)
			var pos := Vector3(off, bh * 0.5, 0) if along_x else Vector3(0, bh * 0.5, off)
			Art.part(body, Art.box(size.x, size.y, size.z), mat if i % 3 else dark, pos)
		if h > 2.0:
			var tn := int(length / 6.5)
			for i in tn:
				var off2 := -length * 0.5 + (i + 0.5) * length / tn
				var inward: Vector3 = -s[0].normalized() * 0.75
				var tp: Vector3 = (Vector3(off2, 2.2, 0) if along_x else Vector3(0, 2.2, off2)) + inward
				_torch(body, tp)


func _torch(parent: Node3D, at: Vector3) -> void:
	var t := Node3D.new()
	t.position = at
	parent.add_child(t)
	Art.part(t, Art.cyl(0.05, 0.03, 0.5, 6), Fx.solid(Color(0.2, 0.15, 0.1)), Vector3(0, -0.2, 0))
	Art.part(t, Art.sphere(0.1, 6), Fx.glow(Color(1.0, 0.6, 0.2), 4.0), Vector3(0, 0.1, 0))
	var f := Fx.particles(Color(1.0, 0.5, 0.15), 14, 0.5, 0.3)
	f.direction = Vector3.UP
	f.gravity = Vector3.UP * 2.0
	f.initial_velocity_min = 0.2
	f.initial_velocity_max = 0.6
	f.position.y = 0.15
	t.add_child(f)
	f.emitting = true
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.25)
	l.light_energy = 2.2
	l.omni_range = 11.0
	l.omni_attenuation = 1.1
	l.position.y = 0.3
	t.add_child(l)
	_torches.append(l)


func _free_spot(clear: float) -> Vector3:
	for _i in 40:
		var p := Vector3(_rng.randf_range(-HALF.x + 2, HALF.x - 2), 0, _rng.randf_range(-HALF.y + 2, HALF.y - 2))
		if p.length() < 4.0:
			continue
		var ok := true
		for q in _props_at:
			if p.distance_to(q) < clear:
				ok = false
				break
		if ok:
			_props_at.append(p)
			return p
	return Vector3(_rng.randf_range(-HALF.x + 2, HALF.x - 2), 0, _rng.randf_range(-HALF.y + 2, HALF.y - 2))


func _prop(kind: String) -> void:
	var p := _free_spot(2.6)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = p
	body.rotation.y = _rng.randf() * TAU
	add_child(body)
	var r := 0.4
	var stone := Fx.solid(biome.wall.lightened(0.1), 0.95)
	match kind:
		"grave":
			var g := Art.tombstone()
			g.scale = Vector3.ONE * _rng.randf_range(0.8, 1.2)
			g.rotation.z = _rng.randf_range(-0.15, 0.15)
			body.add_child(g)
			r = 0.4
		"dead_tree":
			var bark := Fx.solid(Color(0.13, 0.1, 0.08))
			Art.part(body, Art.cyl(0.1, 0.22, 2.6, 7), bark, Vector3(0, 1.3, 0), Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-6, 6)))
			for i in 4:
				Art.part(body, Art.cyl(0.02, 0.08, 1.3, 5), bark, Vector3(0, 1.6 + i * 0.3, 0), Vector3(_rng.randf_range(35, 65), i * 95.0, 0)).translate_object_local(Vector3(0, 0.6, 0))
			r = 0.35
		"rock":
			Art.part(body, Art.sphere(0.8, 6), stone, Vector3(0, 0.3, 0), Vector3(_rng.randf() * 40, 0, 0), Vector3(1.2, 0.7, 1.0))
			r = 0.8
		"candles":
			for i in 5:
				var cp := Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5))
				var h := _rng.randf_range(0.15, 0.45)
				Art.part(body, Art.cyl(0.04, 0.04, h, 6), Fx.solid(Color(0.85, 0.8, 0.65)), cp + Vector3(0, h * 0.5, 0))
				Art.part(body, Art.sphere(0.03, 4), Fx.glow(Color(1, 0.7, 0.3), 5.0), cp + Vector3(0, h + 0.04, 0))
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.65, 0.35)
			l.light_energy = 0.9
			l.omni_range = 4.0
			l.position.y = 0.5
			body.add_child(l)
			_torches.append(l)
			body.collision_layer = 0
			return
		"pillar":
			Art.part(body, Art.cyl(0.45, 0.45, 3.2, 8), stone, Vector3(0, 1.6, 0))
			Art.part(body, Art.box(1.1, 0.3, 1.1), stone, Vector3(0, 0.15, 0))
			Art.part(body, Art.box(1.1, 0.3, 1.1), stone, Vector3(0, 3.1, 0))
			r = 0.55
		"bones":
			var bone := Fx.solid(Color(0.75, 0.72, 0.62))
			for i in 6:
				Art.part(body, Art.cyl(0.03, 0.03, 0.5, 5), bone, Vector3(_rng.randf_range(-0.4, 0.4), 0.04, _rng.randf_range(-0.4, 0.4)), Vector3(90, _rng.randf() * 180, 0))
			Art.part(body, Art.sphere(0.12, 6), bone, Vector3(0.1, 0.1, 0.1))
			body.collision_layer = 0
			return
		"sarcophagus":
			Art.part(body, Art.box(1.0, 0.8, 2.2), stone, Vector3(0, 0.4, 0))
			Art.part(body, Art.box(1.1, 0.15, 2.3), stone.duplicate(), Vector3(0, 0.85, 0))
			r = 0.9
		"stalagmite":
			var h2 := _rng.randf_range(1.2, 2.8)
			Art.part(body, Art.cyl(0.0, 0.5, h2, 6), stone, Vector3(0, h2 * 0.5, 0))
			Art.part(body, Art.cyl(0.0, 0.3, h2 * 0.6, 6), stone, Vector3(0.45, h2 * 0.3, 0.2))
			r = 0.55
		"mushroom":
			var c := Color(0.2, 0.9, 0.75) if _rng.randf() < 0.5 else Color(0.6, 0.35, 1.0)
			for i in 3:
				var mp := Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4))
				var mh := _rng.randf_range(0.2, 0.6)
				Art.part(body, Art.cyl(0.04, 0.06, mh, 6), Fx.solid(Color(0.7, 0.7, 0.6)), mp + Vector3(0, mh * 0.5, 0))
				Art.part(body, Art.sphere(0.18, 8), Fx.glow(c, 1.5), mp + Vector3(0, mh, 0), Vector3.ZERO, Vector3(1, 0.45, 1))
			var l2 := OmniLight3D.new()
			l2.light_color = c
			l2.light_energy = 0.8
			l2.omni_range = 3.5
			l2.position.y = 0.6
			body.add_child(l2)
			body.collision_layer = 0
			return
		"ice":
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.6, 0.85, 1.0, 0.75)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = Color(0.2, 0.4, 0.6)
			for i in 4:
				var ih := _rng.randf_range(0.8, 2.2)
				Art.part(body, Art.cyl(0.0, 0.25, ih, 5), m, Vector3(_rng.randf_range(-0.3, 0.3), ih * 0.4, _rng.randf_range(-0.3, 0.3)), Vector3(_rng.randf_range(-25, 25), 0, _rng.randf_range(-25, 25)))
			r = 0.5
		"basalt":
			var bm := Fx.solid(Color(0.09, 0.07, 0.07), 0.8)
			for i in 3:
				var bh := _rng.randf_range(0.8, 2.4)
				Art.part(body, Art.cyl(0.3, 0.32, bh, 6), bm, Vector3(_rng.randf_range(-0.35, 0.35), bh * 0.5, _rng.randf_range(-0.35, 0.35)))
			r = 0.6
		"brazier":
			Art.part(body, Art.cyl(0.1, 0.25, 0.9, 8), Fx.solid(Color(0.2, 0.18, 0.16), 0.5), Vector3(0, 0.45, 0))
			Art.part(body, Art.cyl(0.45, 0.25, 0.3, 10), Fx.solid(Color(0.25, 0.2, 0.18), 0.5), Vector3(0, 1.0, 0))
			var fl := Fx.particles(Color(1.0, 0.45, 0.1), 30, 0.7, 0.5)
			fl.direction = Vector3.UP
			fl.gravity = Vector3.UP * 2.5
			fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			fl.emission_sphere_radius = 0.3
			fl.position.y = 1.15
			body.add_child(fl)
			fl.emitting = true
			var l3 := OmniLight3D.new()
			l3.light_color = Color(1.0, 0.5, 0.2)
			l3.light_energy = 2.0
			l3.omni_range = 7.0
			l3.position.y = 1.6
			body.add_child(l3)
			_torches.append(l3)
			r = 0.5
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = 3.0
	cs.shape = cyl
	cs.position.y = 1.5
	body.add_child(cs)


func _dust() -> void:
	var p := Fx.particles(Color(0.8, 0.7, 0.6, 0.25), 60, 8.0, 0.08)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(HALF.x, 1.5, HALF.y)
	p.position.y = 1.5
	p.direction = Vector3(1, 0.2, 0)
	p.spread = 60.0
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.3
	p.gravity = Vector3.ZERO
	p.local_coords = true
	if biome.id == "pit":
		p.color_ramp = Fx.ramp(Color(1.0, 0.45, 0.15, 0.8))
		p.gravity = Vector3.UP * 0.3
	elif biome.id == "keep":
		p.color_ramp = Fx.ramp(Color(0.9, 0.95, 1.0, 0.7))
		p.gravity = Vector3(0.3, -0.5, 0)
		p.amount = 160
		p.mesh = Fx.particle_mesh(0.12, Color.WHITE)
	add_child(p)
	p.emitting = true


func _process(_dt: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in _torches.size():
		var l: OmniLight3D = _torches[i]
		if is_instance_valid(l):
			if not l.has_meta("base"):
				l.set_meta("base", l.light_energy)
			var b: float = l.get_meta("base")
			l.light_energy = b * (0.85 + 0.1 * sin(t * 9.0 + i * 1.7) + 0.05 * sin(t * 23.0 + i))


func add_field(at: Vector3, kind: int, r: float, ttl: float, owner: Actor) -> Field:
	var f := Field.new()
	f.kind = kind
	f.radius = r
	f.ttl = ttl
	f.owner_actor = owner
	f.position = Vector3(at.x, 0, at.z)
	add_child(f)
	fields.append(f)
	return f


## An element touches the ground: fields react the way you would guess.
func touch_ground(at: Vector3, r: float, el: int, src: Actor) -> void:
	for f in fields.duplicate():
		if not is_instance_valid(f) or not f.is_physics_processing():
			continue
		var d := Vector2(f.global_position.x - at.x, f.global_position.z - at.z).length()
		if d > f.radius + r:
			continue
		var k: int = f.kind
		var hot: bool = el in [El.FIRE, El.MAGMA]
		var cold: bool = el in [El.FROST, El.ICE]
		var wetting: bool = el in [El.WATER, El.STEAM, El.MUD]
		var zap: bool = el in [El.LIGHTNING, El.STORM]
		if zap and k == El.WATER:
			f.electrified = 3.0
			continue
		if f.permanent and k == El.MAGMA:
			continue
		if hot and k == El.WATER:
			f.set_kind(El.STEAM)
			f.ttl = 5.0
			_steam_pop(f)
		elif hot and k in [El.FROST, El.ICE]:
			f.set_kind(El.WATER)
			f.ttl = maxf(f.ttl, 8.0)
		elif cold and k == El.WATER:
			f.set_kind(El.FROST)
			f.ttl = maxf(f.ttl, 10.0)
		elif cold and k == El.STEAM:
			f.set_kind(El.WATER)
			f.ttl = 8.0
		elif (cold or wetting or el == El.EARTH) and k == El.FIRE and not f.permanent:
			_steam_pop(f)
			f.fade()
		elif el == El.AIR and k == El.STEAM:
			f.fade()
		elif el == El.AIR and k == El.FIRE:
			f.radius = minf(f.radius * 1.12, 4.5)
			f._build()
		if not f.permanent and src:
			f.owner_actor = src


func _steam_pop(f: Field) -> void:
	Fx.puff(f.global_position + Vector3.UP * 0.5, Color(0.85, 0.85, 0.9, 0.6), f.radius)


func ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q)


func clamp_inside(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -HALF.x + 0.8, HALF.x - 0.8), 0, clampf(p.z, -HALF.y + 0.8, HALF.y - 0.8))


## Where a monster can walk in from: along the walls, away from the wizards.
func spawn_point(away_from: Array) -> Vector3:
	var best := Vector3.ZERO
	var best_d := -1.0
	for _i in 12:
		var side := _rng.randi() % 3
		var p: Vector3
		match side:
			0: p = Vector3(_rng.randf_range(-HALF.x + 1.5, HALF.x - 1.5), 0, -HALF.y + 1.2)
			1: p = Vector3(-HALF.x + 1.2, 0, _rng.randf_range(-HALF.y + 1.5, HALF.y - 1.5))
			_: p = Vector3(HALF.x - 1.2, 0, _rng.randf_range(-HALF.y + 1.5, HALF.y - 1.5))
		var d := INF
		for w in away_from:
			d = minf(d, p.distance_to(w.global_position))
		if d > best_d:
			best_d = d
			best = p
	return best

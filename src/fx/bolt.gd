class_name BoltFx
extends Node3D
## One staff bolt, the shot that fires while the right stick aims. It carries
## the wizard's whole loaded queue (see Wizard.bolt_spell), so each element in
## it brings its status: fire burns, frost chills, water soaks, lightning
## shocks. Life heals friends and flies through the living; an empty queue
## shoots plain golden bolts.

const SPEED := 22.0
const LIFE := 0.85
const PLAIN := {counts = {El.EARTH: 1}, payload = [], primary = El.EARTH, n = {}}

var caster: Wizard
## The element the bolt looks like (the front of the queue), -1 for plain.
var el := -1
var vel := Vector3.ZERO
var spell: Dictionary
var t := 0.0


func setup(w: Wizard, s: Dictionary, dir: Vector3) -> BoltFx:
	caster = w
	spell = s
	el = s.primary
	vel = dir.normalized() * SPEED
	return self


## Whether [param s] does anything to [param a]: friends only take its Life,
## the living (not undead) ignore Life.
static func affects(a: Actor, s: Dictionary, src: Actor) -> bool:
	var friend := a.team == src.team
	if s.counts.is_empty():
		return not friend and a.alive
	for e in s.counts:
		if friend:
			if e == El.LIFE and (not a.alive or a.hp < a.max_hp):
				return true
		elif a.alive and (e != El.LIFE or a.undead):
			return true
	return false


## Land [param s] on [param a], each element at its own strength times [param mult].
static func strike(a: Actor, s: Dictionary, mult: float, src: Actor, dir: Vector3) -> void:
	var friend := a.team == src.team
	if s.counts.is_empty():
		if not friend:
			a.hit_spell(PLAIN, Wizard.PLAIN_BOLT * mult, src, dir, 1.0)
		return
	for e in s.counts:
		if friend and e != El.LIFE:
			continue
		if not friend and e == El.LIFE and not a.undead:
			continue
		a.hit_spell({counts = {e: 1}, payload = [], primary = e, n = {}}, s.scales[e] * mult, src, dir, 1.0)


## How each element's bolt looks: core and rim colour, how much it flickers
## and how fast, its stretch along the flight, and its trail.
const LOOK := {
	El.FIRE: {core = Color(1.0, 0.92, 0.55), edge = Color(1.0, 0.32, 0.04), flicker = 1.0, speed = 10.0, stretch = 2.6, size = 1.0,
		trail = Color(1.0, 0.45, 0.08), rise = 2.5},
	El.FROST: {core = Color(0.95, 1.0, 1.0), edge = Color(0.35, 0.75, 1.0), flicker = 0.25, speed = 3.0, stretch = 3.2, size = 0.8,
		trail = Color(0.85, 0.95, 1.0), rise = -1.0, shard = true},
	El.WATER: {core = Color(0.7, 0.9, 1.0), edge = Color(0.1, 0.35, 0.95), flicker = 0.6, speed = 5.0, stretch = 1.7, size = 1.05,
		trail = Color(0.3, 0.55, 1.0), rise = -3.0},
	El.LIGHTNING: {core = Color(1.0, 1.0, 1.0), edge = Color(0.65, 0.55, 1.0), flicker = 1.0, speed = 40.0, stretch = 3.4, size = 0.75,
		trail = Color(0.8, 0.75, 1.0), rise = 0.0, jitter = true},
	El.EARTH: {core = Color(0.75, 0.6, 0.4), edge = Color(0.45, 0.32, 0.18), flicker = 0.0, speed = 0.0, stretch = 1.0, size = 1.15,
		trail = Color(0.55, 0.45, 0.32), rise = -2.0, rock = true},
	El.AIR: {core = Color(0.95, 1.0, 0.97), edge = Color(0.55, 0.85, 0.8, 0.7), flicker = 0.9, speed = 14.0, stretch = 2.2, size = 1.1,
		trail = Color(0.8, 0.95, 0.9, 0.6), rise = 0.5},
	El.LIFE: {core = Color(0.9, 1.0, 0.75), edge = Color(0.2, 0.9, 0.3), flicker = 0.4, speed = 4.0, stretch = 1.6, size = 0.95,
		trail = Color(0.5, 1.0, 0.45), rise = 1.5},
	El.VOID: {core = Color(0.25, 0.0, 0.35), edge = Color(0.75, 0.25, 1.0), flicker = 0.7, speed = 6.0, stretch = 1.5, size = 1.1,
		trail = Color(0.55, 0.15, 0.85), rise = 0.0},
	El.STEAM: {core = Color(1.0, 1.0, 1.0), edge = Color(0.75, 0.8, 0.9, 0.8), flicker = 0.9, speed = 7.0, stretch = 1.8, size = 1.2,
		trail = Color(0.9, 0.92, 0.95, 0.6), rise = 2.0},
	El.ICE: {core = Color(0.95, 1.0, 1.0), edge = Color(0.45, 0.8, 1.0), flicker = 0.15, speed = 2.0, stretch = 3.2, size = 1.0,
		trail = Color(0.75, 0.92, 1.0), rise = -1.5, shard = true},
	El.MUD: {core = Color(0.5, 0.38, 0.22), edge = Color(0.3, 0.22, 0.12), flicker = 0.0, speed = 0.0, stretch = 1.0, size = 1.1,
		trail = Color(0.4, 0.3, 0.18), rise = -4.0, rock = true},
	El.MAGMA: {core = Color(1.0, 0.85, 0.3), edge = Color(1.0, 0.25, 0.02), flicker = 0.8, speed = 5.0, stretch = 1.3, size = 1.25,
		trail = Color(1.0, 0.35, 0.05), rise = 1.0},
	El.STORM: {core = Color(1.0, 1.0, 1.0), edge = Color(0.45, 0.55, 1.0), flicker = 1.0, speed = 35.0, stretch = 3.0, size = 0.95,
		trail = Color(0.6, 0.7, 1.0), rise = 0.5, jitter = true},
	-1: {core = Color(1.0, 0.95, 0.75), edge = Color(1.0, 0.75, 0.3), flicker = 0.3, speed = 6.0, stretch = 2.0, size = 0.7,
		trail = Color(1.0, 0.85, 0.45), rise = 0.5},
}

static var _meshes := {}
static var _mats := {}

var _body: MeshInstance3D
var _look: Dictionary
## How big the bolt looks: a plain bolt is a small spark, a full queue of
## one element a proper fireball. Follows how hard it hits.
var _size := 1.0


static func _material(e: int) -> ShaderMaterial:
	if not _mats.has(e):
		var l: Dictionary = LOOK[e]
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/fx/bolt.gdshader")
		m.set_shader_parameter("core", l.core)
		m.set_shader_parameter("edge", l.edge)
		m.set_shader_parameter("flicker", l.flicker)
		m.set_shader_parameter("speed", l.speed)
		_mats[e] = m
	return _mats[e]


static func _mesh_for(e: int) -> Mesh:
	if not _meshes.has(e):
		var l: Dictionary = LOOK[e]
		if l.get("shard", false):
			# An ice shard: a long six-sided point, tip first.
			var c := Art.cyl(0.0, 0.17, 0.8, 6)
			_meshes[e] = c
		elif l.get("rock", false):
			_meshes[e] = Art.sphere(0.22, 5)
		else:
			_meshes[e] = Art.sphere(0.2, 12)
	return _meshes[e]


func _ready() -> void:
	_look = LOOK[el]
	var loaded := 0
	for e in spell.counts:
		loaded += spell.counts[e]
	_size = 0.45 if loaded == 0 else 0.6 + 0.13 * (loaded - 1)
	global_position.y = 1.1
	reset_physics_interpolation()
	_body = MeshInstance3D.new()
	_body.mesh = _mesh_for(el)
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Element bolts wear the same element material as the orbs and the HUD.
	_body.material_override = _material(el) if el < 0 else Fx.element(el, 1.4)
	if _look.get("shard", false):
		_body.rotation_degrees.x = -90.0
		_body.scale = Vector3.ONE * _size
	else:
		_body.scale = Vector3(1, 1, _look.stretch) * _look.size * _size
	add_child(_body)
	# The bloom round it: faint on a plain spark, a real glow on a full one.
	var glow_c: Color = _look.edge
	add_child(Fx.halo(Color(glow_c.r, glow_c.g, glow_c.b), 1.1 * _size * _look.size + 0.3, 0.35 + 0.25 * _size, 1.0 if _look.flicker > 0.5 else 0.0))
	if el < 0:
		# A smaller white-hot heart inside the glow.
		var heart := MeshInstance3D.new()
		heart.mesh = Art.sphere(0.08 * _size, 6)
		heart.material_override = Fx.glow(_look.core, 4.0)
		heart.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(heart)
	var trail := Fx.particles(_look.trail, int(6 + 14 * _size), 0.25 + 0.2 * _size, 0.22 * _size)
	trail.local_coords = false
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.08
	trail.direction = Vector3.UP
	trail.spread = 180.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.gravity = Vector3(0, _look.rise, 0)
	add_child(trail)
	trail.emitting = true
	look_at(global_position + vel, Vector3.UP)


func _physics_process(dt: float) -> void:
	t += dt
	if _look.get("rock", false):
		_body.rotate_x(dt * 14.0)
	elif _look.get("jitter", false):
		_body.scale = Vector3(randf_range(0.6, 1.3), randf_range(0.6, 1.3), _look.stretch * randf_range(0.8, 1.2)) * _look.size * _size
	if t > LIFE:
		_end(global_position)
		return
	var from := global_position
	var to := from + vel * dt
	var wall: Dictionary = Game.I.arena.ray(from, to) if Game.I else {}
	if wall:
		if wall.collider and wall.collider.has_method("damage") :
			wall.collider.damage(2.0)
		_end(wall.position)
		return
	global_position = to
	for a in (Game.I.living() if Game.I else []):
		if a == caster or not affects(a, spell, caster):
			continue
		if a.hit_by(from, to, 0.18):
			strike(a, spell, 1.0, caster, vel.normalized())
			Fx.burst(to, _look.trail, int(3 + 6 * _size), 2.0 + 2.0 * _size, 0.12 * _size + 0.04)
			_end(to)
			return


func _end(at: Vector3) -> void:
	set_physics_process(false)
	# A bolt that lands still touches the ground: fire bolts boil puddles.
	if Game.I and Game.I.arena:
		for e in spell.counts:
			Game.I.arena.touch_ground(Vector3(at.x, 0, at.z), 0.5, e, caster)
	queue_free()

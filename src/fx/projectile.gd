class_name ProjectileFx
extends SpellFx
## A thrown solid: boulder, ice shard, mud ball or lava bomb. Charge it by
## holding RT; release throws. Payload elements land with it.

var vel := Vector3.ZERO
var power := 1.0
var radius := 0.3
var pierce := 0
var _hit: Array = []
var _model: Node3D
var _trail: CPUParticles3D
var _y := 1.1
var _spin := Vector3.ZERO
## Monster bolts are projectiles too.
var hostile_only := false


func launch(dir: Vector3, charge: float) -> ProjectileFx:
	power = 0.55 + 1.2 * charge
	vel = dir * n.speed * (0.8 + 0.6 * charge)
	radius = n.radius * (0.8 + 0.5 * charge)
	pierce = 2 if n.get("pierce", false) else 0
	return self


func _ready() -> void:
	_model = Node3D.new()
	add_child(_model)
	var c := color()
	match spell.primary:
		El.ICE:
			Art.part(_model, Art.cyl(0.0, radius * 0.6, radius * 4.0, 5), Fx.element(El.ICE, 1.3), Vector3.ZERO, Vector3(-90, 0, 0))
			add_child(Fx.halo(c, radius * 4.0, 0.7))
		El.MAGMA:
			Art.part(_model, Art.sphere(radius, 14), Fx.element(El.MAGMA, 1.3))
			add_child(Fx.halo(c, radius * 6.0, 1.2, 1.0))
			var l := OmniLight3D.new()
			l.light_color = c
			l.light_energy = 1.5
			l.omni_range = 4.0
			_model.add_child(l)
		El.MUD:
			Art.part(_model, Art.sphere(radius, 12), Fx.element(El.MUD, 1.2))
		El.EARTH:
			Art.part(_model, Art.sphere(radius, 8), Fx.element(El.EARTH, 1.3))
		_:
			Art.part(_model, Art.sphere(radius, 14), Fx.element(spell.primary, 1.4))
			add_child(Fx.halo(c, radius * 6.0, 1.3, 1.0))
			var l2 := OmniLight3D.new()
			l2.light_color = c
			l2.light_energy = 1.2
			l2.omni_range = 3.5
			_model.add_child(l2)
	var cs := colors()
	var tc: Color = cs[1] if cs.size() > 1 else c
	_trail = Fx.particles(tc, 30, 0.4, radius * 1.5)
	_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_trail.emission_sphere_radius = radius
	_trail.initial_velocity_max = 0.5
	add_child(_trail)
	_trail.emitting = true
	_spin = Vector3(randf_range(4, 9), randf_range(-3, 3), 0)
	look_at(global_position + vel, Vector3.UP)
	global_position.y = _y


func _physics_process(dt: float) -> void:
	t += dt
	if spell.primary != El.ICE:
		_model.rotation += _spin * dt
	var from := global_position
	var to := from + vel * dt
	var wall = Game.I.arena.ray(from, to) if Game.I else {}
	if wall:
		if wall.collider and wall.collider.has_method("damage"):
			wall.collider.damage(power * 20.0)
		_land(wall.position)
		return
	global_position = to
	for a in targets():
		if a in _hit or (a == caster and t < 0.25):
			continue
		if hostile_only and a.team == caster.team:
			continue
		if not a.alive and not spell.counts.has(El.LIFE):
			continue
		if a.hit_by(from, to, radius):
			_hit.append(a)
			a.hit_spell(spell, power * n.rate, caster, vel.normalized(), ff())
			Fx.burst(to, color(), 10, 4.0, 0.25)
			if pierce <= 0:
				_land(to)
				return
			pierce -= 1
	if t > 2.5:
		_land(to)


func _land(at: Vector3) -> void:
	set_physics_process(false)
	var c := color()
	Fx.burst(at, c, 26, 6.0)
	Fx.light_pop(at, c, 2.5, 5.0)
	var splash: float = n.get("splash", 0.0)
	if splash > 0.0:
		var r := splash * (0.8 + 0.3 * power)
		Fx.ring(Vector3(at.x, 0, at.z), c, r)
		if Game.I:
			Game.I.arena.blast(at, r, 10.0 * power)
		for a in targets():
			if a in _hit:
				continue
			var d := Vector2(a.global_position.x - at.x, a.global_position.z - at.z)
			if d.length() < r + a.radius:
				a.hit_spell(spell, power * 0.6 * n.rate, caster, Vector3(d.x, 0, d.y).normalized(), ff())
		if Game.I:
			var kind := El.FIRE if spell.primary == El.MAGMA else El.MUD
			Game.I.arena.add_field(Vector3(at.x, 0, at.z), kind, r * 0.7, 6.0, caster)
		touch(at, r)
	else:
		touch(at, 1.2)
	queue_free()

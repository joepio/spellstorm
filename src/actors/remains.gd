class_name Remains
extends Node3D
## How a wizard dies, and how it comes back. The death fits what killed it
## (Joep: brutal, by the element): a monster's blow knocks you onto your back,
## fire chars you black, frost freezes you solid and then you shatter,
## lightning fries you, void crushes you into a point, wind throws you away,
## and a big enough hit bursts you into pieces. The body stays where it fell
## until a friend stands at the grave; then the pieces fly back together in light.

const GRAVITY := 20.0

var wizard: Wizard
var style := "fall"
var _model: Dictionary
## Every part of the model with its own place and material, to put back.
var _parts: Array[MeshInstance3D] = []
var _rest: Dictionary = {}
var _mats: Dictionary = {}
## Pieces that fly loose: part -> {vel, spin, rest}.
var _fly: Dictionary = {}
## Blood, ash and ice bits that are only there while dead.
var _mess: Array[Node3D] = []
var _t := 0.0
var _shatter_at := -1.0
var _jolt := 0.0
## Where the grave rises, next to the body rather than on it.
var tomb_at := Vector3.ZERO


func setup(w: Wizard, model: Dictionary) -> Remains:
	wizard = w
	_model = model
	for m in (model.root as Node3D).find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		_parts.append(mi)
		_rest[mi] = mi.transform
		_mats[mi] = mi.material_override
	_rest[model.body] = (model.body as Node3D).transform
	_rest[model.staff] = (model.staff as Node3D).transform
	_rest[model.hat] = (model.hat as Node3D).transform
	_rest[model.root] = (model.root as Node3D).transform
	return self


## Pick the death from what hit last.
static func style_for(a: Actor, overkill: float) -> String:
	var e := a.last_el
	if a.frozen > 0.0 or e in [El.FROST, El.ICE]:
		return "freeze"
	if overkill > 22.0 and e in [El.EARTH, El.MAGMA, El.MUD, -1]:
		return "gore"
	if a.burn > 0.0 or e in [El.FIRE, El.MAGMA, El.STEAM]:
		return "burn"
	if e in [El.LIGHTNING, El.STORM]:
		return "shock"
	if e == El.VOID:
		return "void"
	if e == El.AIR:
		return "blown"
	if overkill > 22.0:
		return "gore"
	return "fall"


func die(how: String, dir: Vector3) -> void:
	style = how
	_t = 0.0
	var body: Node3D = _model.body
	var away := dir
	away.y = 0.0
	if away.length() < 0.05:
		away = -Vector3(sin(body.rotation.y), 0, cos(body.rotation.y))
	away = away.normalized()
	tomb_at = -away * 0.9
	# Face the blow, so falling backwards falls away from it.
	body.rotation.y = atan2(-away.x, -away.z)
	body.rotation.z = 0.0
	match how:
		"fall":
			_topple(0.45)
			_loose(_model.hat, away * 2.5 + Vector3.UP * 4.0)
			_loose(_model.staff, away * 1.5 + Vector3.UP * 2.0)
			_blood(away, 10, 1.0)
		"gore":
			for p in _parts:
				_loose(p, away * randf_range(3.0, 7.0) + Vector3(randf_range(-3, 3), randf_range(4, 8), randf_range(-3, 3)))
			_blood(away, 22, 1.6)
			Fx.light_pop(wizard.global_position, Color(0.6, 0.05, 0.03), 1.5, 4.0, 0.3)
			if Game.I:
				Game.I.shake(0.5)
		"burn":
			_skin(Fx.solid(Color(0.06, 0.045, 0.04), 1.0))
			_flames(1.6)
			_topple(1.1)
			_loose(_model.staff, away * 1.0 + Vector3.UP * 1.5)
			_ash()
		"freeze":
			# Frozen solid where you stand, then you crack apart.
			_skin(Fx.element(El.ICE, 0.9))
			_shatter_at = 0.7
		"shock":
			_jolt = 0.8
			_skin(Fx.solid(Color(0.1, 0.09, 0.09), 1.0))
		"void":
			var root: Node3D = _model.root
			var tw := create_tween()
			tw.tween_property(root, "scale", Vector3(0.05, 0.05, 0.05), 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(root, "rotation:y", root.rotation.y + 6.0, 0.55)
			Fx.ring(wizard.global_position, El.COLOR[El.VOID], 2.0, 0.5)
			tw.tween_callback(func():
				_blood(Vector3.ZERO, 14, 1.2, Color(0.18, 0.02, 0.22))
				Fx.burst(wizard.global_position + Vector3.UP, El.COLOR[El.VOID], 24, 5.0, 0.25))
		"blown":
			for p in [_model.hat, _model.staff]:
				_loose(p, away * 6.0 + Vector3.UP * 6.0)
			_loose(_model.body, away * 9.0 + Vector3.UP * 7.0)


## Back onto the floor, like a ragdoll losing its legs.
func _topple(time: float) -> void:
	var body: Node3D = _model.body
	var tw := create_tween()
	tw.tween_property(body, "rotation:x", -PI * 0.5, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(body, "position:y", 0.22, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if Game.I:
			Game.I.shake(0.15)
		var b := body
		var t2 := create_tween()
		t2.tween_property(b, "rotation:x", -PI * 0.5 + 0.12, 0.08)
		t2.tween_property(b, "rotation:x", -PI * 0.5, 0.12))


func _skin(m: Material) -> void:
	for p in _parts:
		p.material_override = m


## Throw [param n] loose: it flies, bounces and settles under its own rules.
func _loose(n: Node3D, vel: Vector3) -> void:
	var rest := 0.08
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var size := (n as MeshInstance3D).mesh.get_aabb().size * n.global_basis.get_scale()
		rest = minf(size.x, minf(size.y, size.z)) * 0.5
	_fly[n] = {vel = vel, spin = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * randf_range(5.0, 14.0), rest = rest}


## Dark blood: bits that splash out and a pool that spreads under the body.
func _blood(away: Vector3, bits: int, pool: float, c := Color(0.32, 0.01, 0.01)) -> void:
	var at := wizard.global_position
	var wet := Fx.solid(c, 0.25)
	for i in bits:
		var b := MeshInstance3D.new()
		b.mesh = Art.sphere(randf_range(0.04, 0.09), 6)
		b.material_override = wet
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Fx.root.add_child(b)
		b.global_position = at + Vector3.UP * randf_range(0.6, 1.3)
		_mess.append(b)
		_loose(b, away * randf_range(1.0, 4.0) + Vector3(randf_range(-2.5, 2.5), randf_range(2.0, 5.0), randf_range(-2.5, 2.5)))
	var puddle := MeshInstance3D.new()
	puddle.mesh = Art.cyl(1.0, 1.0, 0.01, 20)
	puddle.material_override = wet
	puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Fx.root.add_child(puddle)
	puddle.global_position = at + away * 0.5 + Vector3.UP * 0.02
	puddle.scale = Vector3(0.05, 1, 0.05)
	_mess.append(puddle)
	var tw := puddle.create_tween()
	tw.tween_property(puddle, "scale", Vector3(pool, 1, pool * 0.8), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _flames(time: float) -> void:
	var f := Fx.flames(0.5)
	f.amount = 40
	f.one_shot = true
	f.lifetime = time
	f.explosiveness = 0.2
	add_child(f)
	f.global_position = wizard.global_position + Vector3.UP * 0.4
	f.emitting = true
	_mess.append(f)


func _ash() -> void:
	var smoke := Fx.particles(Color(0.25, 0.22, 0.2, 0.5), 16, 2.5, 0.9)
	smoke.direction = Vector3.UP
	smoke.spread = 15.0
	smoke.gravity = Vector3.UP * 0.6
	smoke.initial_velocity_max = 0.8
	smoke.one_shot = true
	smoke.explosiveness = 0.1
	add_child(smoke)
	smoke.global_position = wizard.global_position + Vector3.UP * 0.4
	smoke.emitting = true
	_mess.append(smoke)


func _physics_process(dt: float) -> void:
	_t += dt
	if _shatter_at > 0.0 and _t >= _shatter_at:
		_shatter_at = -1.0
		var at := wizard.global_position
		for p in _parts:
			var out := p.global_position - at
			out.y = 0.0
			_loose(p, out.normalized() * randf_range(2.0, 5.0) + Vector3.UP * randf_range(2.0, 5.0))
		Fx.burst(at + Vector3.UP, El.COLOR[El.ICE], 24, 5.0, 0.25)
		if Game.I:
			Game.I.shake(0.3)
	if _jolt > 0.0:
		# Twitching in the current, then down in a smoking heap.
		_jolt -= dt
		var body: Node3D = _model.body
		body.position = Vector3(randf_range(-0.06, 0.06), randf_range(0.0, 0.1), randf_range(-0.06, 0.06))
		if randf() < 0.3:
			Fx.burst(wizard.global_position + Vector3.UP * randf_range(0.5, 1.6), El.COLOR[El.LIGHTNING], 4, 3.0, 0.15)
		if _jolt <= 0.0:
			body.position = Vector3.ZERO
			_topple(0.35)
			_ash()
	for n: Node3D in _fly.keys():
		if not is_instance_valid(n):
			_fly.erase(n)
			continue
		var f: Dictionary = _fly[n]
		var v: Vector3 = f.vel
		v.y -= GRAVITY * dt
		var at: Vector3 = n.global_position + v * dt
		if at.y < f.rest:
			at.y = f.rest
			v.y = -v.y * 0.3 if v.y < -2.0 else 0.0
			v.x *= 0.65
			v.z *= 0.65
			f.spin *= 0.55
		n.global_position = at
		var w: Vector3 = f.spin
		if w.length() > 0.05:
			n.global_rotate(w.normalized(), w.length() * dt)
		f.vel = v


## Healed back: every piece flies home in a column of light.
func revive() -> void:
	_fly.clear()
	_jolt = 0.0
	_shatter_at = -1.0
	for m in _mess:
		if is_instance_valid(m):
			m.queue_free()
	_mess.clear()
	var root: Node3D = _model.root
	var from := {}
	for p in _parts:
		from[p] = p.global_transform
	for k in [_model.root, _model.body, _model.staff, _model.hat]:
		(k as Node3D).transform = _rest[k]
	root.scale = Vector3.ONE
	var time := 0.7
	for p in _parts:
		p.transform = _rest[p]
		var to: Transform3D = p.global_transform
		var start: Transform3D = from[p]
		p.global_transform = start
		p.material_override = _mats[p]
		var tw := p.create_tween()
		tw.tween_method(func(k: float):
			if is_instance_valid(p):
				p.global_transform = start.interpolate_with(to, k), 0.0, 1.0, time + randf() * 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func():
			if is_instance_valid(p):
				p.transform = _rest[p])
	var c := Color(1.0, 0.85, 0.5)
	var glow := Fx.halo(c.lerp(Color.WHITE, 0.4), 2.6, 0.8, 1.0)
	add_child(glow)
	glow.global_position = wizard.global_position + Vector3.UP
	var gt := glow.create_tween()
	gt.tween_interval(time)
	gt.tween_property(glow, "scale", Vector3.ONE * 0.1, 0.35)
	gt.tween_callback(glow.queue_free)
	var motes := Fx.particles(c, 40, 0.9, 0.18)
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.4
	motes.radial_accel_min = -6.0
	motes.radial_accel_max = -4.0
	motes.one_shot = true
	motes.explosiveness = 0.3
	add_child(motes)
	motes.global_position = wizard.global_position + Vector3.UP
	motes.emitting = true
	Fx.light_pop(wizard.global_position, c, 3.0, 6.0, time + 0.3)

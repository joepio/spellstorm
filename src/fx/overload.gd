class_name OverloadFx
extends SpellFx
## Five of one base element cast ahead: that element's big one.

var target := Vector3.ZERO
var _thing: Node3D
var _strikes := 0
var _field: Field


func _ready() -> void:
	var c := color()
	target = global_position
	if Game.I:
		Game.I.shake(0.5)
	match spell.primary:
		El.FIRE:
			_thing = Node3D.new()
			Art.part(_thing, Art.sphere(1.0, 16), Fx.shader("molten", {core = Color(1, 0.9, 0.55), edge = c, crust = 0.7, speed = 2.5}))
			_thing.add_child(Fx.halo(c, 6.0, 1.1, 1.0))
			var trail := Fx.particles(c, 80, 0.6, 1.4)
			trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			trail.emission_sphere_radius = 0.9
			_thing.add_child(trail)
			trail.emitting = true
			var l := OmniLight3D.new()
			l.light_color = c
			l.light_energy = 4.0
			l.omni_range = 10.0
			_thing.add_child(l)
			add_child(_thing)
			_thing.position = Vector3(4, 22, -4)
		El.FROST:
			_field = Game.I.arena.add_field(target, El.FROST, 5.5, 9.0, caster)
			_field.spell = {counts = {El.FROST: 3}, payload = [], primary = El.FROST, n = {rate = 0.8}}
			var snow := Fx.particles(Color(0.9, 0.95, 1.0), 220, 2.0, 0.25)
			snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			snow.emission_box_extents = Vector3(5.5, 0.2, 5.5)
			snow.position = Vector3.UP * 6.0
			snow.direction = Vector3(0.4, -1, 0)
			snow.spread = 10.0
			snow.initial_velocity_min = 4.0
			snow.initial_velocity_max = 6.0
			snow.local_coords = true
			add_child(snow)
			snow.emitting = true
		El.WATER:
			_thing = Node3D.new()
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.15, 0.4, 0.85, 0.75)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.metallic = 0.3
			Art.part(_thing, Art.box(7.0, 1.6, 1.4), m, Vector3(0, 0.8, 0))
			var foam := Fx.particles(Color(0.85, 0.92, 1.0), 120, 0.7, 0.5)
			foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			foam.emission_box_extents = Vector3(3.5, 0.2, 0.6)
			foam.position = Vector3.UP * 1.6
			foam.direction = Vector3.UP
			foam.initial_velocity_max = 2.0
			_thing.add_child(foam)
			foam.emitting = true
			add_child(_thing)
			var w := caster as Wizard
			var dir: Vector3 = w.aim_dir if w else Vector3.FORWARD
			_thing.global_position = caster.global_position + dir * 1.5
			_thing.look_at(_thing.global_position + dir, Vector3.UP)
		El.LIGHTNING:
			pass
		El.EARTH:
			var nova := NovaFx.new().setup(caster, spell) as NovaFx
			nova.n = {radius = 8.5, rate = 1.6}
			nova.only_team = 1
			Game.I.spawn(nova, caster.global_position)
			for a in targets():
				if a.team != caster.team and a.global_position.distance_to(caster.global_position) < 8.5:
					a.stun = maxf(a.stun, 2.2)
			for i in 14:
				var p := caster.global_position + Vector3.RIGHT.rotated(Vector3.UP, i * TAU / 14.0) * randf_range(3, 8)
				Fx.burst(p, El.COLOR[El.EARTH], 12, 6.0, 0.4)
			Game.I.shake(1.0)
		El.AIR:
			_field = Game.I.arena.add_field(target, El.AIR, 2.4, 8.0, caster)
			_field.spell = {counts = {El.AIR: 2}, payload = [], primary = El.AIR, n = {rate = 0.6}}
		El.LIFE:
			for a in Game.I.wizards:
				if not a.alive:
					a.revive(0.6)
				a.healed(a.max_hp * 0.6)
				Fx.burst(a.global_position + Vector3.UP, c, 30, 4.0)
				Fx.light_pop(a.global_position, c, 3.0, 5.0, 0.6)
			for a in targets():
				if a.undead and a.global_position.distance_to(caster.global_position) < 9.0:
					a.hit_spell(spell, 1.0, caster, Vector3.ZERO, 0.0)
			Fx.ring(caster.global_position, c, 9.0, 0.8)
		El.VOID:
			_thing = Node3D.new()
			Art.part(_thing, Art.sphere(0.9, 14), Fx.solid(Color(0, 0, 0), 1.0))
			var halo := Fx.particles(c, 100, 0.8, 0.5)
			halo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			halo.emission_sphere_radius = 3.0
			halo.radial_accel_min = -12.0
			halo.radial_accel_max = -8.0
			halo.local_coords = true
			_thing.add_child(halo)
			halo.emitting = true
			_thing.position = Vector3.UP * 1.2
			add_child(_thing)


func _physics_process(dt: float) -> void:
	t += dt
	match spell.primary:
		El.FIRE:
			if _thing:
				_thing.position = _thing.position.lerp(Vector3.ZERO, clampf(t / 0.9, 0, 1) * 0.25)
				if t > 0.9:
					_thing.queue_free()
					_thing = null
					var nova := NovaFx.new().setup(caster, spell) as NovaFx
					nova.n = {radius = 5.0, rate = 1.6}
					Game.I.spawn(nova, target)
					Game.I.arena.add_field(target, El.FIRE, 3.2, 8.0, caster)
					Game.I.shake(1.2)
			if t > 1.2:
				finish()
		El.WATER:
			var w := caster as Wizard
			var dir: Vector3 = -_thing.global_basis.z
			_thing.global_position += dir * 11.0 * dt
			var local_side := _thing.global_basis.x
			for a in targets():
				if a == caster:
					continue
				var d: Vector3 = a.global_position - _thing.global_position
				d.y = 0
				if absf(d.dot(dir)) < 1.2 and absf(d.dot(local_side)) < 3.6:
					a.push = a.push.lerp(dir * 13.0, 0.5)
					a.hit_spell(spell, dt * 1.2, caster, dir, ff())
			if t > 1.3:
				Game.I.arena.add_field(_thing.global_position, El.WATER, 3.0, 10.0, caster)
				finish()
			elif w == null:
				pass
		El.LIGHTNING:
			if t > _strikes * 0.28 and _strikes < 3:
				_strikes += 1
				_bolt()
			if t > 1.0:
				finish()
		El.VOID:
			for a in targets():
				if a.team == caster.team:
					continue
				var d: Vector3 = global_position - a.global_position
				d.y = 0
				if d.length() < 9.0 and d.length() > 0.5:
					a.push = a.push.lerp(d.normalized() * 7.0, 4.0 * dt)
			_thing.scale = Vector3.ONE * (1.0 + 0.1 * sin(t * 20.0))
			if t > 3.0:
				var nova := NovaFx.new().setup(caster, spell) as NovaFx
				nova.n = {radius = 4.5, rate = 1.4}
				nova.only_team = 1
				Game.I.spawn(nova, global_position)
				Game.I.shake(0.8)
				finish()
		El.FROST, El.AIR:
			if _field and is_instance_valid(_field):
				if spell.primary == El.AIR:
					# The tornado hunts the nearest monster.
					var best: Actor = null
					var bd := INF
					for a in targets():
						if a.team != caster.team:
							var d: float = a.global_position.distance_to(_field.global_position)
							if d < bd:
								bd = d
								best = a
					if best:
						_field.global_position = _field.global_position.move_toward(best.global_position, 3.5 * dt)
			else:
				finish()
			if t > 9.0:
				finish()
		_:
			if t > 1.0:
				finish()


func _bolt() -> void:
	var best: Actor = null
	var bd := INF
	for a in targets():
		if a.team == caster.team:
			continue
		var d: float = a.global_position.distance_to(target)
		if d < bd and d < 10.0:
			bd = d
			best = a
	var at := best.global_position if best else target + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	var arc := ArcFx.new().setup(caster, spell) as ArcFx
	arc.fixed = true
	arc.n = {range = 3.0, hops = 3, hop_range = 5.0, interval = 9.0, duration = 1.0, rate = 1.6}
	Game.I.spawn(arc, at)
	arc.from_point = at + Vector3.UP * 25.0
	Fx.light_pop(at, El.COLOR[El.LIGHTNING], 6.0, 14.0, 0.3)
	Game.I.arena.touch_ground(at, 2.5, El.LIGHTNING, caster)
	Game.I.shake(0.6)
	var tw := arc.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(arc.queue_free)

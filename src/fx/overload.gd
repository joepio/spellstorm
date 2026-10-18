class_name OverloadFx
extends SpellFx
## A full queue cast ahead: a cataclysm. Its lead element decides the big
## one (meteor, blizzard, tidal wave, thunderstorm, earthquake, tornado,
## plague, black hole); every other element in the queue rides along and
## adds itself wherever it lands (_ride): water floods the ground, fire
## sets it alight, frost freezes, poison pools, earth stuns and throws
## rock, air blows monsters away, void drags them in, lightning shocks.
## Lightning and water make a Tempest: rain and a flooded field that
## every strike electrifies.

## How wide the tidal wave is, where it starts in front of the caster and
## how far it rolls (the charge mark shows this strip: Wizard._rolls).
const WAVE_WIDTH := 7.2
const WAVE_START := 1.5
const WAVE_SPEED := 11.0
const WAVE_TIME := 1.3
const WAVE_RUN := WAVE_SPEED * WAVE_TIME
## How far round its spot each cataclysm reaches, for the charge mark.
const REACH := {El.FIRE: 5.0, El.FROST: 5.5, El.LIGHTNING: 5.5, El.EARTH: 8.5,
	El.AIR: 2.4, El.POISON: 5.0, El.VOID: 4.5}

var target := Vector3.ZERO
var _thing: Node3D
## Where the meteor starts its fall, above and behind the target.
const METEOR_FROM := Vector3(4, 22, -4)
var _strikes := 0
var _field: Field
var riders: Array = []
## The thunderstorm's cloud, drifting after monsters near the target.
var _cloud: Node3D
const STORM_TIME := 3.2
const STORM_EVERY := 0.22
var _ride_t := 0.0


func _ready() -> void:
	var c := color()
	target = global_position
	riders = spell.get("riders", [])
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
			_thing.position = METEOR_FROM
			# With earth in it, a shower: more rocks rain down round the first.
			if El.EARTH in riders:
				for i in 4:
					var more := spell.duplicate()
					more.riders = []
					var off := Vector3.RIGHT.rotated(Vector3.UP, i * TAU / 4.0 + randf() * 0.8) * randf_range(3.0, 5.0)
					var at := Game.I.arena.clamp_inside(target + off)
					var who := caster.get_instance_id()
					get_tree().create_timer(0.25 + i * 0.2).timeout.connect(func():
						var w := instance_from_id(who) as Actor
						if w and Game.I:
							Game.I.spawn(OverloadFx.new().setup(w, more), at))
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
			_ride(target, 5.0)
		El.WATER:
			_thing = Node3D.new()
			# A wall of water curling over at the top, rising as it sets off.
			var wave := MeshInstance3D.new()
			wave.mesh = _wave_mesh()
			wave.material_override = Fx.shader("wave")
			wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			wave.name = "wave"
			_thing.add_child(wave)
			# Spray torn off the crest, and foam churning along its foot.
			var spray := Fx.particles(Color(0.9, 0.96, 1.0), 160, 0.8, 0.35)
			spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			spray.emission_box_extents = Vector3(WAVE_WIDTH * 0.45, 0.1, 0.3)
			spray.position = Vector3(0, 2.5, -0.6)
			spray.direction = Vector3(0, 1, -1.5)
			spray.spread = 25.0
			spray.initial_velocity_min = 2.0
			spray.initial_velocity_max = 5.0
			spray.gravity = Vector3(0, -9, 0)
			Parts.style(spray, El.WATER)
			_thing.add_child(spray)
			spray.emitting = true
			var foot := Fx.particles(Color(0.85, 0.92, 1.0), 120, 0.6, 0.45)
			foot.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			foot.emission_box_extents = Vector3(WAVE_WIDTH * 0.5, 0.05, 0.4)
			foot.position = Vector3(0, 0.1, -1.0)
			foot.direction = Vector3(0, 1, -1)
			foot.initial_velocity_max = 2.5
			Parts.style(foot, El.WATER)
			_thing.add_child(foot)
			foot.emitting = true
			var wl := OmniLight3D.new()
			wl.light_color = Color(0.4, 0.75, 1.0)
			wl.light_energy = 1.5
			wl.omni_range = 7.0
			wl.position = Vector3(0, 2.0, -1.5)
			_thing.add_child(wl)
			_thing.scale = Vector3(1.0, 0.2, 1.0)
			add_child(_thing)
			var w := caster as Wizard
			var dir: Vector3 = w.aim_dir if w else Vector3.FORWARD
			_thing.global_position = caster.global_position + dir * WAVE_START
			_thing.look_at(_thing.global_position + dir, Vector3.UP)
		El.LIGHTNING:
			_storm_cloud()
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
				Fx.burst(p, El.COLOR[El.EARTH], 12, 6.0, 0.4, El.EARTH)
			_ride(caster.global_position, 6.0)
			Game.I.shake(1.0)
		El.AIR:
			_field = Game.I.arena.add_field(target, El.AIR, 2.4, 8.0, caster)
			_field.spell = {counts = {El.AIR: 2}, payload = [], primary = El.AIR, n = {rate = 0.6}}
			if not riders.is_empty():
				_field.spell.counts.merge(spell.counts)
		El.POISON:
			# Plague: a wide cloud of poison that your own side walks through.
			_field = Game.I.arena.add_field(target, El.POISON, 5.0, 8.0, caster)
			_field.spell = {counts = {El.POISON: 2}, payload = [], primary = El.POISON, n = {rate = 0.7}}
			_field.friendly = true
			_ride(target, 4.5)
			Fx.burst(target + Vector3.UP * 0.5, c, 40, 6.0, 0.3, El.POISON)
			Fx.ring(target, c, 5.0, 0.6)
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


static var _wave: ArrayMesh


## The tidal wave's body: a curling profile (back slope, crest, a lip
## hanging over the front, and under it back to the floor) swept across
## its width, lower and shallower towards both ends. Faces -Z, the way it
## rolls. UV.y climbs the face to the lip (wave.gdshader).
static func _wave_mesh() -> ArrayMesh:
	if _wave:
		return _wave
	# [z, y, height along the face]
	var prof := [[1.8, 0.0, 0.0], [1.2, 0.45, 0.15], [0.65, 1.25, 0.35], [0.25, 2.0, 0.6], [-0.2, 2.5, 0.8],
		[-0.7, 2.65, 0.92], [-1.1, 2.35, 1.0], [-1.3, 1.85, 1.0], [-1.15, 1.45, 0.95],
		[-0.8, 1.55, 0.75], [-0.5, 1.05, 0.45], [-0.6, 0.45, 0.2], [-0.95, 0.0, 0.0]]
	var segs := 28
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WAVE_WIDTH * 0.5
	for i in segs + 1:
		var x := lerpf(-half, half, float(i) / segs)
		var k := 1.0 - pow(absf(x) / half, 3.0)
		for p in prof:
			st.set_uv(Vector2(float(i) / segs, p[2]))
			st.add_vertex(Vector3(x, p[1] * (0.15 + 0.85 * k), p[0] * (0.5 + 0.5 * k)))
	var rows := prof.size()
	for i in segs:
		for j in rows - 1:
			var a := i * rows + j
			var b := a + rows
			st.add_index(a)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(b + 1)
	st.generate_normals()
	_wave = st.commit()
	return _wave


func _physics_process(dt: float) -> void:
	t += dt
	match spell.primary:
		El.FIRE:
			if _thing:
				# Falls faster and faster, like a real rock, and hits at full speed.
				var k := clampf(t / 0.9, 0.0, 1.0)
				_thing.position = METEOR_FROM.lerp(Vector3.ZERO, k * k)
				if t > 0.9:
					_thing.queue_free()
					_thing = null
					var nova := NovaFx.new().setup(caster, spell) as NovaFx
					nova.n = {radius = 5.0, rate = 1.6}
					Game.I.spawn(nova, target)
					Game.I.arena.add_field(target, El.FIRE, 3.2, 8.0, caster)
					Fx.burst(target + Vector3.UP * 0.5, El.COLOR[El.FIRE], 40, 9.0, 0.5, El.FIRE)
					_ride(target, 4.5)
					Game.I.shake(1.2)
			if t > 1.2:
				finish()
		El.WATER:
			var w := caster as Wizard
			var dir: Vector3 = -_thing.global_basis.z.normalized()
			_thing.global_position += dir * WAVE_SPEED * dt
			# It rears up as it sets off and sinks into a flood at the end.
			var rise := clampf(t / 0.25, 0.0, 1.0)
			var sink := 1.0 - clampf((t - WAVE_TIME + 0.3) / 0.3, 0.0, 1.0)
			_thing.scale = Vector3(1.0, maxf(0.05, (0.2 + 0.8 * rise) * sink), 1.0)
			var local_side := _thing.global_basis.x
			for a in targets():
				if a == caster:
					continue
				var d: Vector3 = a.global_position - _thing.global_position
				d.y = 0
				if absf(d.dot(dir)) < 1.4 and absf(d.dot(local_side.normalized())) < WAVE_WIDTH * 0.5:
					a.push = a.push.lerp(dir * 13.0, 0.5)
					a.hit_spell(spell, dt * 1.2, caster, dir, ff())
			if t > WAVE_TIME:
				Game.I.arena.add_field(_thing.global_position, El.WATER, 3.0, 10.0, caster)
				_ride(_thing.global_position, 4.0)
				finish()
			elif w == null:
				pass
		El.LIGHTNING:
			_storm(dt)
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
				_ride(global_position, 4.5)
				Game.I.shake(0.8)
				finish()
		El.FROST, El.AIR, El.POISON:
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
					# What rides on the tornado is flung out of it now and then.
					_ride_t -= dt
					if _ride_t <= 0.0 and not riders.is_empty():
						_ride_t = 1.2
						_ride(_field.global_position, 2.6)
			else:
				finish()
			if t > 9.0:
				finish()
		_:
			if t > 1.0:
				finish()


## A dark cloud gathers over the target; in a Tempest it rains and the
## ground below floods first, so every strike lights up the water.
func _storm_cloud() -> void:
	_cloud = Node3D.new()
	# See-through, so the camera above still sees the fight under it.
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.1, 0.15, 0.32)
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 9:
		var off := Vector3(randf_range(-4, 4), randf_range(-0.4, 0.4), randf_range(-4, 4))
		var puff := Art.part(_cloud, Art.sphere(randf_range(1.6, 2.6), 10), dark, off)
		puff.scale = Vector3(1.0, 0.3, 1.0)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Its shadow darkens the ground under it.
	var shade := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * 13.0
	shade.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.0, 0.0, 0.03, 0.55)
	sm.albedo_texture = Field._edge()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shade.material_override = sm
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cloud.add_child(shade)
	shade.position = Vector3.DOWN * 8.93
	var glow := Fx.halo(El.COLOR[El.LIGHTNING], 9.0, 0.5, 1.0)
	_cloud.add_child(glow)
	add_child(_cloud)
	_cloud.global_position = target + Vector3.UP * 9.0
	_cloud.scale = Vector3.ONE * 0.2
	_cloud.create_tween().tween_property(_cloud, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if El.WATER in riders:
		_field = Game.I.arena.add_field(target, El.WATER, 5.5, STORM_TIME + 6.0, caster)
		_field.friendly = true
		var rain := Fx.particles(El.COLOR[El.WATER], 260, 0.7, 0.3)
		rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rain.emission_box_extents = Vector3(5.0, 0.2, 5.0)
		rain.direction = Vector3.DOWN
		rain.spread = 4.0
		rain.initial_velocity_min = 13.0
		rain.initial_velocity_max = 16.0
		Parts.style(rain, El.WATER)
		rain.gravity = Vector3.DOWN * 9.0
		_cloud.add_child(rain)
		rain.position = Vector3.DOWN * 0.6
		rain.emitting = true
	if Game.I:
		Game.I.shake(0.4)


func _storm(dt: float) -> void:
	if not _cloud:
		return
	# The cloud drifts after the nearest monster, but stays near the target.
	var best := _nearest(_cloud.global_position, 9.0)
	if best:
		var want := best.global_position
		if want.distance_to(target) > 6.0:
			want = target + (want - target).normalized() * 6.0
		var at := Vector3(want.x, _cloud.global_position.y, want.z)
		_cloud.global_position = _cloud.global_position.move_toward(at, 4.0 * dt)
	if _field and is_instance_valid(_field):
		_field.global_position = _field.global_position.move_toward(Vector3(_cloud.global_position.x, 0, _cloud.global_position.z), 4.0 * dt)
	if t > 0.45 and t < STORM_TIME and t > 0.45 + _strikes * STORM_EVERY:
		_strikes += 1
		_bolt()
	if t > STORM_TIME:
		_cloud.create_tween().tween_property(_cloud, "scale", Vector3.ONE * 0.05, 0.4)
		_cloud = null
		get_tree().create_timer(0.5).timeout.connect(finish)


func _nearest(from: Vector3, reach: float) -> Actor:
	var best: Actor = null
	var bd := reach
	for a in targets():
		if a.team == caster.team or not a.alive:
			continue
		var d: float = Vector3(a.global_position.x, 0, a.global_position.z).distance_to(Vector3(from.x, 0, from.z))
		if d < bd:
			bd = d
			best = a
	return best


func _bolt() -> void:
	var under := Vector3(_cloud.global_position.x, 0, _cloud.global_position.z) if _cloud else target
	# Most strikes find a monster under the cloud, the rest hit the ground.
	var best := _nearest(under, 5.5) if randf() < 0.7 else null
	var at := best.global_position if best else under + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	var arc := ArcFx.new().setup(caster, spell) as ArcFx
	arc.fixed = true
	arc.spare_friends = true
	arc.n = {range = 2.5, hops = 2, hop_range = 4.0, interval = 9.0, duration = 0.5, rate = 0.55}
	Game.I.spawn(arc, at)
	arc.from_point = Vector3(at.x, 0, at.z) + Vector3.UP * 9.0
	Fx.light_pop(at, El.COLOR[El.LIGHTNING], 6.0, 10.0, 0.2)
	Fx.burst(at + Vector3.UP * 0.3, El.COLOR[El.LIGHTNING], 14, 6.0, 0.25, El.LIGHTNING)
	Game.I.arena.touch_ground(at, 2.5, El.LIGHTNING, caster)
	if _strikes % 3 == 0:
		_ride(at, 2.5)
	Game.I.shake(0.3)
	var tw := arc.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(arc.queue_free)


## Every element riding on the cataclysm adds itself at [param at].
func _ride(at: Vector3, r: float) -> void:
	if not Game.I:
		return
	var ground := Vector3(at.x, 0, at.z)
	for e in riders:
		var c: Color = El.COLOR[e]
		Fx.burst(ground + Vector3.UP * 0.5, c, 24, 7.0, 0.35, e)
		match e:
			El.WATER, El.FIRE, El.FROST:
				if not (e == El.WATER and spell.primary == El.LIGHTNING):
					var wf: Field = Game.I.arena.add_field(ground, e, r * 0.7, 6.0, caster)
					wf.friendly = true
			El.POISON:
				var f: Field = Game.I.arena.add_field(ground, El.POISON, r * 0.7, 7.0, caster)
				f.friendly = true
			El.LIGHTNING:
				Game.I.arena.touch_ground(ground, r, El.LIGHTNING, caster)
				Fx.light_pop(ground, c, 4.0, r * 3.0, 0.25)
			El.EARTH, El.AIR, El.VOID:
				for a in targets():
					if a.team == caster.team:
						continue
					var d: Vector3 = a.global_position - ground
					d.y = 0
					if d.length() > r + 1.5:
						continue
					match e:
						El.EARTH:
							a.stun = maxf(a.stun, 1.2)
						El.AIR:
							a.push += d.normalized() * 14.0
						El.VOID:
							a.push += -d.normalized() * 9.0
				if e == El.EARTH:
					Fx.ring(ground, c, r, 0.4)
				elif e == El.VOID:
					Fx.ring(ground, c, r * 1.3, 0.5)

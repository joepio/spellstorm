class_name BoltFx
extends Node3D
## One staff bolt, the shot that fires while the right stick aims. It carries
## the wizard's whole loaded queue (see Wizard.bolt_spell), so each element in
## it brings its status: fire burns, frost chills, water soaks, lightning
## shocks, poison sickens. Bolts fly through friends; an empty queue shoots
## plain golden bolts. From an enchanted staff ([member charmed]) a bolt is
## bigger and each base element in it adds its own trick (_charm).

## Lobbed bolts (Balance.FLIGHT lob) fall this hard, landing at their range.
const GRAVITY := 12.0
const PLAIN := {counts = {El.EARTH: 1}, payload = [], primary = El.EARTH, n = {}}

var caster: Wizard
## The element the bolt looks like (the front of the queue), -1 for plain.
var el := -1
var vel := Vector3.ZERO
var spell: Dictionary
var t := 0.0
## How this bolt flies (Balance.flight of its element).
var flight: Dictionary
var life := 0.8
## The base elements of the enchantment this bolt was fired with, if any.
var charmed := {}
## Who a piercing frost shard already went through.
var _pierced: Array = []


func setup(w: Wizard, s: Dictionary, dir: Vector3) -> BoltFx:
	caster = w
	spell = s
	el = s.primary
	flight = Balance.flight(el)
	vel = dir.normalized() * float(flight.speed)
	life = float(flight.range) / float(flight.speed)
	return self


## Whether [param s] does anything to [param a]: bolts fly through friends.
static func affects(a: Actor, _s: Dictionary, src: Actor) -> bool:
	return a.team != src.team and a.alive


## Land [param s] on [param a], each element at its own strength times [param mult].
static func strike(a: Actor, s: Dictionary, mult: float, src: Actor, dir: Vector3) -> void:
	if a.team == src.team:
		return
	if s.counts.is_empty():
		a.hit_spell(PLAIN, Wizard.PLAIN_BOLT * mult, src, dir, 1.0)
		return
	for e in s.counts:
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
	El.POISON: {core = Color(0.85, 1.0, 0.45), edge = Color(0.4, 0.8, 0.05), flicker = 0.5, speed = 5.0, stretch = 1.6, size = 0.95,
		trail = Color(0.45, 0.75, 0.1), rise = -0.5},
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
	# A slow, heavy bolt looks as heavy as it hits.
	_size *= clampf(pow(6.0 / float(flight.rate), 0.3), 0.85, 1.6)
	if not charmed.is_empty():
		_size = 1.1 * clampf(pow(6.0 / float(flight.rate), 0.3), 0.85, 1.6)
		if El.AIR in charmed:
			vel *= 1.5
			life /= 1.5
		elif El.EARTH in charmed:
			vel *= 0.8
			life /= 0.8
	global_position.y = 1.1
	if flight.lob:
		# Thrown up just enough to come down at the end of its range.
		vel.y = (GRAVITY * life * life * 0.5 - 1.1) / life
	if flight.get("zap", false):
		# A spark has no body: it jumps on the first tick (_spark).
		return
	reset_physics_interpolation()
	_body = MeshInstance3D.new()
	_body.mesh = _mesh_for(el)
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Element bolts wear the same element material as the orbs and the HUD.
	_body.material_override = _material(el) if el < 0 else Fx.element(el, 1.1 if _look.get("jitter", false) else 1.4)
	if _look.get("shard", false):
		_body.rotation_degrees.x = -90.0
		_body.scale = Vector3.ONE * _size
	else:
		_body.scale = Vector3(1, 1, _look.stretch) * _look.size * _size
	add_child(_body)
	# The bloom round it: faint on a plain spark, a real glow on a full one.
	var glow_c: Color = _look.edge
	# Lightning keeps a smaller glow, so its dark body and white veins show.
	var bloom := 0.5 if _look.get("jitter", false) else 1.0
	add_child(Fx.halo(Color(glow_c.r, glow_c.g, glow_c.b), (1.1 * _size * _look.size + 0.3) * (0.8 if bloom < 1.0 else 1.0), (0.35 + 0.25 * _size) * bloom, 1.0 if _look.flicker > 0.5 else 0.0))
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
	if el >= 0:
		Parts.style(trail, el, false)
	add_child(trail)
	trail.emitting = true
	look_at(global_position + vel, Vector3.UP)


func _physics_process(dt: float) -> void:
	if flight.get("zap", false):
		_spark()
		return
	t += dt
	if _look.get("rock", false):
		_body.rotate_x(dt * 14.0)
	elif _look.get("jitter", false):
		_body.scale = Vector3(randf_range(0.6, 1.3), randf_range(0.6, 1.3), _look.stretch * randf_range(0.8, 1.2)) * _look.size * _size
	if t > life:
		_end(global_position)
		return
	var from := global_position
	if flight.lob:
		vel.y -= GRAVITY * dt
	var to := from + vel * dt
	if to.y <= 0.05:
		global_position = to
		_end(Vector3(to.x, 0.05, to.z))
		return
	var wall: Dictionary = Game.I.arena.ray(from, to) if Game.I else {}
	if wall:
		if wall.collider and wall.collider.has_method("damage") :
			wall.collider.damage(2.0, vel)
		_end(wall.position)
		return
	global_position = to
	if flight.lob:
		look_at(to + vel, Vector3.UP)
	for a in (Game.I.living() if Game.I else []):
		if a == caster or a in _pierced or not affects(a, spell, caster):
			continue
		if a.hit_by(from, to, float(flight.hit) * (1.0 if charmed.is_empty() else 1.5)):
			strike(a, spell, 1.0, caster, vel.normalized())
			Fx.burst(to, _look.trail, int(3 + 6 * _size), 2.0 + 2.0 * _size, 0.12 * _size + 0.04, el)
			if not charmed.is_empty():
				_charm_hit(a, to)
				# A frost shard goes on through, up to three.
				if (El.FROST in charmed) and _pierced.size() < 2:
					_pierced.append(a)
					continue
			_end(to)
			return


## What an enchanted bolt's elements do where it hits [param a].
func _charm_hit(a: Actor, at: Vector3) -> void:
	var dir := vel.normalized()
	if El.EARTH in charmed:
		a.stun = maxf(a.stun, 0.35)
		a.push += dir * 7.0 / a.mass
	if El.AIR in charmed:
		a.push += dir * 12.0 / a.mass
	if El.WATER in charmed:
		a.push += dir * 4.0 / a.mass
	if El.LIGHTNING in charmed:
		# The hit jumps on to the two nearest.
		var from := at
		var done: Array = [a]
		for i in 2:
			var best: Actor = null
			var best_d := 4.0
			for b in Game.I.enemies:
				if is_instance_valid(b) and b.alive and not b in done:
					var d: float = b.global_position.distance_to(from)
					if d < best_d:
						best = b
						best_d = d
			if best == null:
				break
			var p := best.global_position + Vector3.UP * 0.9
			best.hit_spell({counts = {El.LIGHTNING: 1}, payload = [], primary = El.LIGHTNING, n = {}}, Balance.bolt_scale(El.LIGHTNING) * 1.2, caster, (p - from).normalized())
			_zap(from, p)
			done.append(best)
			from = p


## A lightning bolt does not fly: a small spark jumps at once from the staff
## to the first monster in line (a little forgiving sideways), or a wall,
## or dies out at its range.
func _spark() -> void:
	set_physics_process(false)
	var from := global_position
	var dir := Vector3(vel.x, 0.0, vel.z).normalized()
	var reach: float = flight.range
	var hit: Actor = null
	for a in (Game.I.living() if Game.I else []):
		if a == caster or not affects(a, spell, caster):
			continue
		var to: Vector3 = a.global_position - from
		to.y = 0.0
		var along := to.dot(dir)
		if along > 0.0 and along < reach and (to - dir * along).length() < a.radius + float(flight.hit) + 0.35:
			reach = along
			hit = a
	var to_pt := from + dir * reach
	var wall: Dictionary = Game.I.arena.ray(from, to_pt) if Game.I else {}
	if wall:
		hit = null
		to_pt = wall.position
		if wall.collider and wall.collider.has_method("damage"):
			wall.collider.damage(2.0, dir)
	if hit:
		to_pt = hit.global_position + Vector3.UP * 0.9
		strike(hit, spell, 1.0, caster, dir)
		if not charmed.is_empty():
			_charm_hit(hit, to_pt)
	_spark_line(from, to_pt, hit != null)
	_end(to_pt)


## The spark itself: thin, jagged, gone in a blink.
func _spark_line(a: Vector3, b: Vector3, landed: bool) -> void:
	if Fx.root == null:
		return
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var c: Color = El.COLOR[el] if el >= 0 else Color.WHITE
	mi.material_override = Fx.shader("zap", {core = c.lerp(Color.WHITE, 0.8), edge = c})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.05 + 0.03 * _size
	var steps := maxi(3, int(a.distance_to(b) / 0.6))
	var prev := a
	for s in range(1, steps + 1):
		var p := a.lerp(b, float(s) / steps)
		if s < steps:
			p += Vector3(randf() - 0.5, (randf() - 0.5) * 0.5, randf() - 0.5) * 0.35
		var side := (p - prev).cross(Vector3.UP).normalized() * w
		for off in [side, Vector3.UP * w]:
			for v in [[prev - off, 0.0], [p - off, 0.0], [p + off, 1.0], [prev - off, 0.0], [p + off, 1.0], [prev + off, 1.0]]:
				im.surface_set_color(Color.WHITE)
				im.surface_set_uv(Vector2(v[1], 0.0))
				im.surface_add_vertex(v[0])
		prev = p
	im.surface_end()
	Fx.root.add_child(mi)
	if landed:
		Fx.flash(b, c, 0.7, 0.08)
	mi.get_tree().create_timer(0.06).timeout.connect(mi.queue_free)


## A quick jagged flash from [param a] to [param b] for a jumping hit.
static func _zap(a: Vector3, b: Vector3) -> void:
	if Fx.root == null:
		return
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var c: Color = El.COLOR[El.LIGHTNING]
	mi.material_override = Fx.shader("zap", {core = c.lerp(Color.WHITE, 0.8), edge = c})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(3, int(a.distance_to(b) / 0.5))
	var prev := a
	for s in range(1, steps + 1):
		var p := a.lerp(b, float(s) / steps)
		if s < steps:
			p += Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 0.45
		var side := (p - prev).cross(Vector3.UP).normalized() * 0.18
		for off in [side, Vector3.UP * 0.18]:
			for v in [[prev - off, 0.0], [p - off, 0.0], [p + off, 1.0], [prev - off, 0.0], [p + off, 1.0], [prev + off, 1.0]]:
				im.surface_set_color(Color.WHITE)
				im.surface_set_uv(Vector2(v[1], 0.0))
				im.surface_add_vertex(v[0])
		prev = p
	im.surface_end()
	Fx.root.add_child(mi)
	Fx.flash(b, c, 1.4, 0.14)
	mi.get_tree().create_timer(0.1).timeout.connect(mi.queue_free)


func _charm_end(at: Vector3) -> void:
	if not Game.I:
		return
	var ground := Vector3(at.x, 0, at.z)
	if El.FIRE in charmed:
		# Each fireball bursts: a small blast that burns whoever stands by.
		BlastFx.boom(ground, 0.5, false)
		for a in Game.I.enemies:
			if not is_instance_valid(a) or not a.alive:
				continue
			var d: Vector3 = a.global_position - ground
			d.y = 0.0
			if d.length() < 1.8 + a.radius:
				a.hit_spell({counts = {El.FIRE: 1}, payload = [], primary = El.FIRE, n = {}}, _burst_fire(), caster, d.normalized())
		Game.I.shake(0.06)
	if El.VOID in charmed:
		for a in Game.I.enemies:
			if is_instance_valid(a) and a.alive:
				var d: Vector3 = ground - a.global_position
				d.y = 0.0
				if d.length() < 3.0 and d.length() > 0.3:
					a.push += d.normalized() * 8.0 / a.mass
		Fx.burst(at, El.COLOR[El.VOID], 14, -4.0, 0.25, El.VOID)
	if El.POISON in charmed:
		var f: Field = Game.I.arena.add_field(Game.I.arena.clamp_inside(ground), El.POISON, 0.9, 2.5, caster)
		f.friendly = true
		f.splash()
	# Every element lands with something you can see (Joep: three water
	# bolts did nothing at all where they hit).
	for e in charmed:
		_impact(at, ground, e)


## The look of an enchanted bolt landing, per base element; what it does
## is in _charm_hit and above.
func _impact(at: Vector3, ground: Vector3, e: int) -> void:
	var c: Color = El.COLOR[e]
	match e:
		El.WATER:
			# A crown of drops thrown up and falling back, and a ring on the floor.
			_spray(at, e, 18, 7.0, 28.0, 0.75)
			Fx.ripple(ground, 2.2, 0.6)
		El.POISON:
			_spray(at, e, 14, 5.0, 40.0, 0.7)
		El.FROST:
			# Ice splinters out and a breath of cold mist.
			_spray(at, e, 12, 5.5, 75.0, 0.7)
			Fx.puff(at, c.lerp(Color.WHITE, 0.6), 0.45)
		El.EARTH:
			# Chips of stone kicked up and a puff of dust.
			_spray(at, e, 10, 6.5, 50.0, 0.9)
			Fx.puff(ground + Vector3.UP * 0.2, Color(0.45, 0.38, 0.3), 0.9)
		El.AIR:
			# A gust bursting outward.
			Fx.ring(ground, c.lerp(Color.WHITE, 0.5), 1.8, 0.3)
			_spray(at, e, 10, 5.0, 90.0, 0.7)
		El.LIGHTNING:
			_spray(at, e, 8, 4.0, 90.0, 0.5)
			Fx.light_pop(ground, c, 2.0, 4.0, 0.15)
		El.VOID:
			Fx.light_pop(ground, c, 1.5, 3.5, 0.25)


## A one-shot fountain of [param e]'s particles, up and outward.
func _spray(at: Vector3, e: int, amount: int, speed: float, spread: float, size: float) -> void:
	var p := Fx.particles(El.COLOR[e], amount, 0.7, size)
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.damping_min = 0.5
	p.damping_max = 1.5
	Parts.style(p, e, false)
	Fx._spawn(p, at + Vector3.UP * 0.1)
	p.emitting = true
	p.finished.connect(p.queue_free)


## How hard an enchanted fire bolt's burst hits (Balance.enchant_shot).
func _burst_fire() -> float:
	var f: float = spell.scales.get(El.FIRE, spell.scales.get(El.MAGMA, spell.scales.get(El.STEAM, 0.0)))
	return maxf(f, Balance.bolt_scale(El.FIRE)) * 0.5


func _end(at: Vector3) -> void:
	set_physics_process(false)
	if not charmed.is_empty():
		_charm_end(at)
	# A bolt that lands still touches the ground: fire bolts boil puddles.
	if Game.I and Game.I.arena:
		for e in spell.counts:
			Game.I.arena.touch_ground(Vector3(at.x, 0, at.z), 0.5, e, caster)
	queue_free()

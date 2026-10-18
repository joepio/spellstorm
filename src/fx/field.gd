class_name Field
extends Node3D
## A patch of ground with an element on it: burning ground, a puddle, an ice
## slick, a steam cloud, mud, a whirlwind, lava. Spilled by wizards' traps,
## left by lava bombs and dying monsters, or part of the room. Fields react to
## elements that touch them, see Arena.touch_ground.

var kind := El.WATER
var spell := {}
var radius := 2.0
var ttl := 8.0
var permanent := false
var electrified := 0.0
var owner_actor: Actor
var rate := 0.55
## Left by a wizard's trap: the owner's side walks through it unharmed.
var friendly := false

var _disc: MeshInstance3D
var _mat: StandardMaterial3D
var _parts: CPUParticles3D
var _light: OmniLight3D
var _spark_t := 0.0
## What the element looks like besides the disc: fire, lava or wind shaders.
var _looks: Array[MeshInstance3D] = []
var _spin := 0.0


static func simple(k: int) -> Dictionary:
	return {counts = {k: 1}, payload = [], primary = k, shape = "field", form = "plant", n = {rate = 0.55}}


func _ready() -> void:
	_disc = MeshInstance3D.new()
	var c := Art.cyl(1.0, 1.0, 0.02, 28)
	_disc.mesh = c
	_mat = StandardMaterial3D.new()
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.roughness = 0.15
	_mat.metallic_specular = 0.2
	_mat.albedo_texture = _edge()
	_disc.material_override = _mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = 0.03 + randf() * 0.01
	add_child(_disc)
	_build()


static var _edge_tex: Texture2D


## A disc that is solid in the middle and fades out at the rim.
static func _edge() -> Texture2D:
	if _edge_tex:
		return _edge_tex
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.72, Color(1, 1, 1, 0.95))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	_edge_tex = t
	return t


func set_kind(k: int, keep_payload := false) -> void:
	if k == kind:
		return
	kind = k
	if keep_payload:
		spell.counts = {k: 1}
	else:
		spell = simple(k)
	electrified = 0.0
	if is_inside_tree():
		_build()


func _build() -> void:
	if spell.is_empty():
		spell = simple(kind)
	if _parts:
		_parts.queue_free()
		_parts = null
	if _light:
		_light.queue_free()
		_light = null
	for m in _looks:
		m.queue_free()
	_looks.clear()
	_disc.visible = true
	_disc.scale = Vector3(radius, 1, radius)
	var c: Color = El.COLOR[kind]
	_mat.emission_enabled = false
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	match kind:
		El.WATER:
			_mat.albedo_color = Color(0.08, 0.18, 0.35, 0.75)
			_mat.metallic = 0.4
			_mat.roughness = 0.05
		El.FROST, El.ICE:
			_mat.albedo_color = Color(0.55, 0.72, 0.85, 0.55)
			_mat.roughness = 0.2
		El.MUD:
			_mat.albedo_color = Color(0.2, 0.14, 0.08, 0.92)
		El.FIRE, El.MAGMA:
			_disc.visible = false
			_fire(kind == El.MAGMA)
			_parts = Fx.particles(c, int(3 * radius * radius) + 4, 1.1, 0.12)
			_parts.direction = Vector3.UP
			_parts.gravity = Vector3.UP * 1.5
			_parts.initial_velocity_min = 0.6
			_parts.initial_velocity_max = 1.8
			_light = OmniLight3D.new()
			_light.light_color = c
			_light.light_energy = 1.4
			_light.omni_range = radius * 2.5
			_light.position = Vector3.UP * 0.8
		El.STEAM:
			_mat.albedo_color = Color(0.8, 0.8, 0.85, 0.12)
			_parts = Fx.particles(Color(0.75, 0.75, 0.8, 0.5), int(8 * radius * radius), 2.0, 1.6)
			_parts.direction = Vector3.UP
			_parts.gravity = Vector3.UP * 0.2
			_parts.initial_velocity_min = 0.1
			_parts.initial_velocity_max = 0.5
		El.AIR:
			_disc.visible = false
			_wind()
			_parts = Fx.particles(Color(0.8, 0.82, 0.75, 0.3), int(6 * radius) + 8, 1.2, 0.18)
			_parts.direction = Vector3.UP
			_parts.orbit_velocity_min = 0.8
			_parts.orbit_velocity_max = 1.2
			_parts.initial_velocity_min = 1.0
			_parts.initial_velocity_max = 2.5
			_parts.local_coords = true
		El.LIFE:
			_mat.albedo_color = Color(0.2, 0.9, 0.35, 0.3)
			_mat.emission_enabled = true
			_mat.emission = c
		_:
			_mat.albedo_color = Color(c.r, c.g, c.b, 0.4)
	if _parts:
		_parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_parts.emission_sphere_radius = radius * 0.85
		_parts.scale = Vector3(1, 0.05, 1)
		_parts.scale_amount_min = 0.6
		_parts.scale_amount_max = 1.3
		add_child(_parts)
		_parts.emitting = true
		_parts.scale = Vector3.ONE
	if _light:
		add_child(_light)


## Burning ground: a ragged patch of glowing seams with tongues of flame on
## it (src/fx/fire_ground.gdshader, flame.gdshader). Lava gets no flames.
func _fire(lava: bool) -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * radius * 2.3
	ground.mesh = pm
	ground.material_override = Fx.shader("fire_ground", {lava = 1.0 if lava else 0.0})
	ground.position.y = 0.05 + randf() * 0.01
	_look(ground)
	if lava:
		return
	var flame := Fx.shader("flame")
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	for i in clampi(int(radius * radius * 1.4), 4, 18):
		var m := MeshInstance3D.new()
		m.mesh = q
		m.material_override = flame
		var at := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius * 0.75
		var h := randf_range(1.6, 2.6) * minf(1.0, 0.5 + radius * 0.2)
		m.scale = Vector3(h * 0.7, h, 1.0)
		m.position = Vector3(at.x, h * 0.5 - 0.02, at.y)
		_look(m)


## A whirlwind: a twisting funnel and a swirl on the ground that bend what is
## behind them (src/fx/wind.gdshader).
func _wind() -> void:
	var swirl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * radius * 2.2
	swirl.mesh = pm
	swirl.material_override = Fx.shader("wind", {mode = 1, spin = 1.4, strength = 0.6})
	swirl.position.y = 0.06
	# Drawn before the funnel, so the funnel always stands on it.
	swirl.sorting_offset = -50.0
	_look(swirl)
	var funnel := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.9
	cyl.bottom_radius = radius * 0.22
	cyl.height = radius * 1.8 + 1.0
	cyl.radial_segments = 24
	cyl.rings = 8
	cyl.cap_top = false
	cyl.cap_bottom = false
	funnel.mesh = cyl
	funnel.material_override = Fx.shader("wind", {mode = 0, spin = 1.8})
	funnel.position.y = cyl.height * 0.5
	_look(funnel)
	# A tighter, faster core inside it gives the funnel depth.
	var core := MeshInstance3D.new()
	var cc := cyl.duplicate() as CylinderMesh
	cc.top_radius = radius * 0.55
	cc.bottom_radius = radius * 0.12
	core.mesh = cc
	core.material_override = Fx.shader("wind", {mode = 0, spin = 3.0, strength = 0.7})
	core.position.y = cyl.height * 0.5
	_look(core)


func _look(m: MeshInstance3D) -> void:
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	_looks.append(m)


func _physics_process(dt: float) -> void:
	if not permanent:
		ttl -= dt
		if ttl <= 0.0:
			fade()
			return
	electrified = maxf(0.0, electrified - dt)
	if electrified > 0.0:
		_spark_t -= dt
		if _spark_t <= 0.0:
			_spark_t = 0.15
			var p := global_position + Vector3(randf_range(-1, 1), 0.1, randf_range(-1, 1)) * radius * 0.8
			Fx.burst(p, El.COLOR[El.LIGHTNING], 5, 3.0, 0.2)
		_mat.emission_enabled = true
		_mat.emission = El.COLOR[El.LIGHTNING]
		_mat.emission_energy_multiplier = 0.2 + randf() * 0.3
	elif kind == El.WATER:
		_mat.emission_enabled = false
	if not Game.I:
		return
	var ff: float = Game.I.ff
	for a in Game.I.living():
		var d: Vector3 = a.global_position - global_position
		d.y = 0
		if d.length() > radius:
			continue
		if friendly and owner_actor and a.team == owner_actor.team:
			continue
		match kind:
			El.FROST, El.ICE:
				a.slick = 0.25
			El.AIR:
				var tangent := d.cross(Vector3.UP).normalized()
				a.push += (tangent * 5.0 - d.normalized() * 2.0) * dt * 4.0
		if kind == El.LIFE and a.team != (owner_actor.team if owner_actor else 0):
			continue
		var scale := dt * rate
		if kind in [El.FIRE, El.MAGMA] and a.has_method("mods") and a.mods().get("firewalker", false):
			continue
		a.hit_spell(spell, scale, owner_actor, d.normalized() if d.length() > 0.1 else Vector3.ZERO, ff * 0.6)
		if electrified > 0.0:
			a.hit_spell(Field.simple(El.LIGHTNING), dt * 0.7, owner_actor, Vector3.ZERO, ff * 0.6)


func fade() -> void:
	set_physics_process(false)
	if Game.I and Game.I.arena:
		Game.I.arena.fields.erase(self)
	if _parts:
		_parts.emitting = false
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(_disc, "transparency", 1.0, 0.6)
	var mats := {}
	for m in _looks:
		mats[m.material_override] = true
	for mat: ShaderMaterial in mats:
		mat.set_shader_parameter("fade", 1.0)
		tw.tween_property(mat, "shader_parameter/fade", 0.0, 0.6)
	tw.chain()
	tw.tween_callback(queue_free)

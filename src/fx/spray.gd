class_name SprayFx
extends SpellFx
## A cone of fire, frost, water, steam or air from the staff, held with RT.

var _parts: Array[CPUParticles3D] = []
var _light: OmniLight3D
var _cone_mat: ShaderMaterial
var _soot_mat: ShaderMaterial
var _touch_t := 0.0
var _fire := false


func _ready() -> void:
	is_stream = true
	_fire = spell.primary == El.FIRE
	var cs := colors()
	var life := 0.45
	if _fire:
		_flame_jet(life)
	else:
		_cone(cs, life)
	for i in cs.size():
		var c: Color = cs[i]
		if _fire and elements()[i] == El.FIRE:
			_flame_parts(i == 0, life)
			continue
		var size := 0.4 if i == 0 else 0.3
		if spell.primary in [El.STEAM, El.AIR]:
			size = 0.65
		var p := Fx.particles(c, 60 if i == 0 else 30, life, size)
		# Spread the spawn point a little so two particles of one frame never
		# start on the same spot (they read as pairs).
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.12
		p.direction = Vector3(0, 0, -1)
		p.spread = n.angle * 0.5
		p.initial_velocity_min = n.range / life * 0.9
		p.initial_velocity_max = n.range / life * 1.25
		p.damping_min = 1.0
		p.damping_max = 3.0
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.8
		p.gravity = Vector3.UP * (1.5 if spell.primary in [El.FIRE, El.STEAM] else -1.0)
		if spell.primary == El.AIR:
			p.color_ramp = Fx.ramp(Color(c.r, c.g, c.b, 0.35))
		Parts.style(p, elements()[i])
		add_child(p)
		p.emitting = true
		_parts.append(p)
	_light = OmniLight3D.new()
	_light.light_color = color()
	_light.light_energy = 1.6 if spell.primary in [El.FIRE, El.STEAM] else 0.8
	_light.omni_range = n.range + 2.0
	_light.position = Vector3(0, 0, -n.range * 0.5)
	add_child(_light)
	var glow := Fx.halo(cs[0], 1.4, 1.2, 1.0)
	add_child(glow)


## The Flamethrower: one connected jet of fire (src/fx/flame_jet.gdshader)
## over a ribbon of dark smoke (src/fx/flame_soot.gdshader), so the fire has
## something to burn against on a bright floor.
func _flame_jet(life: float) -> void:
	var far: float = 2.0 * n.range * tan(deg_to_rad(n.angle * 0.5))
	var seed := randf() * 50.0
	_soot_mat = Fx.shader("flame_soot", {speed = n.range / life * 0.12, jet_length = n.range * 1.1,
		near_width = 0.4, far_width = far * 1.3, seed = seed, strength = 0.0})
	_soot_mat.render_priority = -1
	_add_ribbon(_soot_mat, n.range * 1.1, far * 1.3, -0.05)
	_cone_mat = Fx.shader("flame_jet", {speed = n.range / life * 0.5, jet_length = n.range,
		near_width = 0.22, far_width = far * 0.95, seed = seed, strength = 0.0})
	_cone_mat.render_priority = 1
	_add_ribbon(_cone_mat, n.range, far, 0.0)
	create_tween().tween_property(_cone_mat, "shader_parameter/strength", 1.0, 0.1)
	create_tween().tween_property(_soot_mat, "shader_parameter/strength", 1.0, 0.35)


## A flat strip along -Z that the shader shapes from its UVs (UV.y from the
## staff out, UV.x across), so its bounds are set by hand.
func _add_ribbon(mat: ShaderMaterial, length: float, width: float, y: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	plane.subdivide_width = 6
	plane.subdivide_depth = 24
	var m := MeshInstance3D.new()
	m.mesh = plane
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.custom_aabb = AABB(Vector3(-width, -0.5, -length - 0.5), Vector3(width * 2.0, 1.0, length + 1.0))
	m.position.y = y
	add_child(m)


## Fire's particles ride the jet rather than make it: a few licks of flame
## curling off the body (with their smoke) from the lead element, a scatter of
## small embers flung past the tip from each extra Fire.
func _flame_parts(lead: bool, life: float) -> void:
	var p: CPUParticles3D
	if lead:
		# Under one a frame, from a small sphere, so none start in pairs.
		p = Fx.particles(El.COLOR[El.FIRE], 18, life, 0.3)
		p.spread = n.angle * 0.45
		p.initial_velocity_min = n.range / life * 0.75
		p.initial_velocity_max = n.range / life * 1.1
		p.damping_min = 1.0
		p.damping_max = 3.0
		p.scale_amount_min = 0.7
		p.scale_amount_max = 1.5
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.15
		p.position = Vector3(0, 0, -0.4)
		p.direction = Vector3(0, 0, -1)
		Parts.style(p, El.FIRE)
		p.gravity = Vector3.UP * 2.0
		# Orange licks, not pale candle flames: the jet carries the hot core.
		p.color_ramp = Parts._ramp([Color(1.0, 0.6, 0.2, 0.0), Color(1.0, 0.55, 0.15, 0.8), Color(0.95, 0.3, 0.05, 0.6),
			Color(0.6, 0.1, 0.02, 0.0)], [0.0, 0.15, 0.55, 1.0])
		p.color_initial_ramp = Parts._ramp([Color(1, 0.85, 0.7), Color(1.0, 0.65, 0.45)], [0.0, 1.0])
	else:
		p = Fx.particles(Color(1.0, 0.62, 0.22), 9, life * 1.4, 0.12)
		p.color_ramp = Parts._ramp([Color(1.0, 0.9, 0.6, 1.0), Color(1.0, 0.5, 0.1, 0.9), Color(0.6, 0.1, 0.02, 0.0)], [0.0, 0.5, 1.0])
		p.spread = n.angle * 0.6
		p.initial_velocity_min = n.range / life * 0.8
		p.initial_velocity_max = n.range / life * 1.3
		p.damping_min = 2.0
		p.damping_max = 4.0
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.2
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.2
		p.position = Vector3(0, 0, -0.6)
		p.direction = Vector3(0, 0, -1)
		p.gravity = Vector3.UP * 1.0
	add_child(p)
	p.emitting = true
	_parts.append(p)


## The body of the spray: a cone of boiling flame, glittering frost, streaking
## water or soft vapour (src/fx/stream.gdshader), with the particles on top.
func _cone(cs: Array, life: float) -> void:
	var c: Color = cs[0]
	var mixed := c
	for i in range(1, cs.size()):
		mixed = mixed.lerp(cs[i], 0.35)
	var style: int = {El.FROST: 1, El.ICE: 1, El.WATER: 2, El.STEAM: 3, El.AIR: 3}.get(spell.primary, 0)
	_cone_mat = Fx.shader("stream", {
		core = c.lerp(Color(1, 0.97, 0.85), 0.65), edge = mixed, style = style,
		speed = n.range / life * 0.3, reach = n.range / 5.0,
		strength = 0.0,
	})
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = n.range * tan(deg_to_rad(n.angle * 0.5)) * 0.85
	cyl.height = n.range
	cyl.radial_segments = 24
	cyl.rings = 6
	cyl.cap_top = false
	cyl.cap_bottom = false
	var m := MeshInstance3D.new()
	m.mesh = cyl
	m.material_override = _cone_mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Narrow end at the staff, opening out along -Z.
	m.rotation.x = PI / 2
	m.position = Vector3(0, 0, -n.range * 0.5)
	add_child(m)
	var full := 0.35 if style == 3 else 1.0
	create_tween().tween_property(_cone_mat, "shader_parameter/strength", full, 0.12)


func _physics_process(dt: float) -> void:
	t += dt
	var w := caster as Wizard
	if not caster.alive or (w and not w.holding(self)) or t > n.duration:
		_stop()
		return
	if not caster.can_act():
		return
	if _fire:
		# A flame jet's light gutters.
		_light.light_energy = 1.6 * (0.85 + 0.1 * sin(t * 23.0) + 0.05 * sin(t * 61.0 + 1.3))
	var dir := w.aim_dir if w else -caster.global_basis.z
	global_position = w.staff_tip() if w else caster.global_position + Vector3.UP
	look_at(global_position + dir, Vector3.UP)
	stream_from = caster.global_position
	stream_to = caster.global_position + dir * n.range
	var half := deg_to_rad(n.angle * 0.5)
	for a in targets():
		if a == caster:
			continue
		var to: Vector3 = a.global_position - caster.global_position
		to.y = 0.0
		var d := to.length()
		if d > n.range + a.radius or d < 0.01:
			continue
		if absf(dir.signed_angle_to(to, Vector3.UP)) > half + atan2(a.radius, d):
			continue
		var falloff: float = 1.0 - 0.4 * d / n.range
		a.hit_spell(spell, dt * n.rate * falloff, caster, to.normalized(), ff())
	_touch_t -= dt
	if _touch_t <= 0.0:
		_touch_t = 0.25
		touch(caster.global_position + dir * n.range * 0.75, 1.2 + n.range * 0.15)


func _stop() -> void:
	set_physics_process(false)
	is_stream = false
	for p in _parts:
		p.emitting = false
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 0.0, 0.3)
	tw.parallel().tween_property(_cone_mat, "shader_parameter/strength", 0.0, 0.2)
	if _soot_mat:
		tw.parallel().tween_property(_soot_mat, "shader_parameter/strength", 0.0, 0.6)
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

class_name SprayFx
extends SpellFx
## A cone of fire, frost, water, steam or air from the staff, held with RT.

var _parts: Array[CPUParticles3D] = []
var _light: OmniLight3D
var _cone_mat: ShaderMaterial
var _touch_t := 0.0


func _ready() -> void:
	is_stream = true
	var cs := colors()
	var life := 0.45
	_cone(cs, life)
	for i in cs.size():
		var c: Color = cs[i]
		var size := 0.4 if i == 0 else 0.3
		if spell.primary in [El.STEAM, El.AIR]:
			size = 0.65
		var p := Fx.particles(c, 60 if i == 0 else 30, life, size)
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
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

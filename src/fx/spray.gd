class_name SprayFx
extends SpellFx
## A cone of fire, frost, water, steam or air from the staff, held with RT.

var _parts: Array[CPUParticles3D] = []
var _light: OmniLight3D
var _touch_t := 0.0


func _ready() -> void:
	is_stream = true
	var cs := colors()
	var life := 0.45
	for i in cs.size():
		var c: Color = cs[i]
		var size := 0.55 if i == 0 else 0.35
		if spell.primary in [El.STEAM, El.AIR]:
			size = 0.9
		var p := Fx.particles(c, 90 if i == 0 else 40, life, size)
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
		add_child(p)
		p.emitting = true
		_parts.append(p)
	_light = OmniLight3D.new()
	_light.light_color = color()
	_light.light_energy = 1.6 if spell.primary in [El.FIRE, El.STEAM] else 0.8
	_light.omni_range = n.range + 2.0
	_light.position = Vector3(0, 0, -n.range * 0.5)
	add_child(_light)


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
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

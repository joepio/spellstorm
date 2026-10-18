class_name BeamFx
extends SpellFx
## A Poison or Void beam: stops at the first thing it touches.

var _core: MeshInstance3D
var _halo: MeshInstance3D
var _halo_mat: ShaderMaterial
var _end_glow: MeshInstance3D
var _muzzle: MeshInstance3D
var _end_light: OmniLight3D
var _sparks: CPUParticles3D
var _touch_t := 0.0
var _core_mat: StandardMaterial3D
var _muzzle_light: OmniLight3D

## Lit, the beam snaps out of the staff as a thin needle of light, far
## brighter than it settles to, then swells to its full width.
const IGNITE := 0.3


func _ready() -> void:
	is_stream = true
	var mixed := color()
	for c in colors():
		mixed = mixed.lerp(c, 0.3)
	_core_mat = Fx.glow(color().lerp(Color.WHITE, 0.5), 1.6).duplicate()
	_core = _tube(n.width * 0.18, _core_mat)
	# The sheath: pulses running down a coloured glow (src/fx/beam.gdshader).
	_halo_mat = Fx.shader("beam", {core = color().lerp(Color.WHITE, 0.6), edge = mixed,
		speed = 14.0 if spell.primary == El.VOID else 9.0})
	_halo = _tube(n.width, _halo_mat)
	_muzzle = Fx.halo(mixed, 1.2, 0.9, 1.0)
	_muzzle.top_level = true
	add_child(_muzzle)
	_end_glow = Fx.halo(mixed, 2.2, 0.9, 1.0)
	_end_glow.top_level = true
	add_child(_end_glow)
	_end_light = OmniLight3D.new()
	_end_light.light_color = color()
	_end_light.light_energy = 2.5
	_end_light.omni_range = 5.0
	add_child(_end_light)
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.light_color = color().lerp(Color.WHITE, 0.4)
	_muzzle_light.omni_range = 4.0
	_muzzle_light.top_level = true
	add_child(_muzzle_light)
	_sparks = Fx.particles(mixed, 40, 0.5, 0.3)
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 1.0
	_sparks.initial_velocity_max = 4.0
	Parts.style(_sparks, spell.primary)
	add_child(_sparks)
	_sparks.emitting = true


## A unit-long open tube: no flat disc at either end.
func _tube(r: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := Art.cyl(r, r, 1.0, 10)
	c.cap_top = false
	c.cap_bottom = false
	m.mesh = c
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.top_level = true
	add_child(m)
	return m


func _physics_process(dt: float) -> void:
	t += dt
	var w := caster as Wizard
	if not caster.alive or (w and not w.holding(self)) or t > n.duration:
		finish()
		return
	var dir: Vector3 = w.aim_dir if w else -caster.global_basis.z
	var from: Vector3 = w.staff_tip() if w else caster.global_position + Vector3.UP
	var length: float = n.range
	var hit = Game.I.arena.ray(from, from + dir * length) if Game.I else {}
	if hit:
		length = from.distance_to(hit.position)
		if hit.collider and hit.collider.has_method("damage"):
			hit.collider.damage(12.0 * dt, dir)
	var first: Actor = null
	if caster.can_act():
		for a in targets():
			if a == caster or not a.alive:
				continue
			var to: Vector3 = a.global_position - caster.global_position
			to.y = 0
			var along := to.dot(dir)
			if along < 0.0 or along > length:
				continue
			if (to - dir * along).length() < a.radius + n.width:
				length = along
				first = a
	var to_pos := from + dir * length
	to_pos.y = from.y
	stream_from = caster.global_position
	stream_to = caster.global_position + dir * length
	for tube in [_core, _halo]:
		tube.global_position = (from + to_pos) * 0.5
		tube.global_basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI / 2)
		tube.scale = Vector3(1, length, 1)
	# 0 when lit, 1 once settled: thin and blinding, then full and steady.
	var lit := smoothstep(0.0, IGNITE, t)
	var thin := lerpf(0.22, 1.0, lit)
	var bright := lerpf(3.0, 1.0, lit)
	var pulse := (1.0 + 0.12 * sin(t * 30.0) * lit) * thin
	_halo.scale.x = pulse
	_halo.scale.z = pulse
	_core.scale.x = lerpf(0.6, 1.0, lit)
	_core.scale.z = _core.scale.x
	_halo_mat.set_shader_parameter("strength", bright)
	_core_mat.emission_energy_multiplier = 1.6 * bright
	_muzzle_light.global_position = from
	_muzzle_light.light_energy = lerpf(5.0, 1.2, lit)
	_halo_mat.set_shader_parameter("length", length)
	_end_light.global_position = to_pos
	_end_glow.global_position = to_pos
	_muzzle.global_position = from
	_muzzle.scale = Vector3.ONE * lerpf(1.6, 1.0, lit)
	_end_glow.scale = Vector3.ONE * (2.4 if first else 1.4) * pulse
	_sparks.global_position = to_pos
	if first and caster.can_act():
		first.hit_spell(spell, dt * n.rate, caster, dir, ff())
	_touch_t -= dt
	if _touch_t <= 0.0:
		_touch_t = 0.3
		touch(Vector3(to_pos.x, 0, to_pos.z), 0.8)

class_name RuneFx
extends SpellFx
## RB with Life or Void. A Life rune pulses healing for your side and
## burns the undead that step in; a Void rune is a mine that blows when a
## monster steps on it.

var _glyph: MeshInstance3D
var _pulse_t := 0.0
var _armed := 0.6


func _ready() -> void:
	var c := color()
	_glyph = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.85
	tor.outer_radius = 1.0
	tor.rings = 24
	tor.ring_segments = 4
	_glyph.mesh = tor
	_glyph.material_override = Fx.glow(c, 2.5)
	_glyph.scale = Vector3(n.radius * 0.5, 0.05, n.radius * 0.5)
	_glyph.position.y = 0.05
	add_child(_glyph)
	for i in 3:
		var bar := Art.part(self, Art.box(n.radius * 0.8, 0.02, 0.08), Fx.glow(c, 2.0), Vector3(0, 0.05, 0), Vector3(0, i * 60, 0))
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var i := 0
	for e in spell.payload:
		Art.part(self, Art.sphere(0.12, 6), Fx.glow(El.COLOR[e], 3.0), Vector3(cos(i * 2.1), 0.2, sin(i * 2.1)) * n.radius * 0.45)
		i += 1
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.0
	l.omni_range = n.radius * 2.0
	l.position.y = 0.6
	add_child(l)


func _physics_process(dt: float) -> void:
	t += dt
	_armed -= dt
	_glyph.rotation.y += dt * 1.5
	if t > n.duration:
		finish()
		return
	if spell.primary == El.LIFE:
		_pulse_t -= dt
		if _pulse_t <= 0.0:
			_pulse_t = 1.0
			Fx.ring(global_position, color(), n.radius, 0.5)
			for a in targets():
				var d: Vector3 = a.global_position - global_position
				d.y = 0
				if d.length() < n.radius and (a.team == caster.team or a.undead):
					a.hit_spell(spell, 0.35 * n.rate, caster, d.normalized(), ff())
		return
	if _armed > 0.0:
		return
	for a in targets():
		if a.team == caster.team:
			continue
		var d: Vector3 = a.global_position - global_position
		d.y = 0
		if d.length() < n.radius * 0.5 + a.radius:
			var nova := NovaFx.new().setup(caster, spell) as NovaFx
			nova.radius = n.radius
			nova.spare_caster = false
			nova.n = {radius = n.radius, rate = n.rate}
			Game.I.spawn(nova, global_position)
			finish()
			return

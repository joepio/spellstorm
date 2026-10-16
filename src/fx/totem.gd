class_name TotemFx
extends SpellFx
## RB with lightning or storm: a pylon that zaps the nearest monster.

var _arc: ArcFx
var _orb: MeshInstance3D


func _ready() -> void:
	var c := color()
	Art.part(self, Art.cyl(0.12, 0.3, 1.6, 6), Fx.solid(Color(0.25, 0.22, 0.3)), Vector3(0, 0.8, 0))
	for e in spell.payload:
		Art.part(self, Art.cyl(0.2, 0.2, 0.1, 6), Fx.glow(El.COLOR[e], 2.0), Vector3(0, randf_range(0.4, 1.3), 0))
	_orb = Art.part(self, Art.sphere(0.22, 8), Fx.glow(c, 4.0), Vector3(0, 1.85, 0))
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.2
	l.omni_range = 4.0
	l.position = Vector3(0, 1.9, 0)
	add_child(l)
	var s := spell.duplicate()
	s.n = {range = n.range, hops = n.hops, hop_range = n.hop_range, interval = n.interval, duration = n.duration, rate = n.rate}
	_arc = ArcFx.new().setup(caster, s) as ArcFx
	_arc.fixed = true
	add_child(_arc)
	Fx.burst(global_position, c, 20, 4.0)


func _physics_process(dt: float) -> void:
	t += dt
	_arc.from_point = _orb.global_position
	_orb.position.y = 1.85 + sin(t * 4.0) * 0.08
	if t > n.duration:
		Fx.burst(_orb.global_position, color(), 20, 4.0)
		finish()

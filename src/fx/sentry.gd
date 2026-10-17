class_name SentryFx
extends SpellFx
## Planting a full queue (LS click with five elements): a sentry at your
## feet that turns to the nearest monster in range and shoots bolts of your
## whole mix at it, the same bolts your staff shoots, until it runs out. The
## big plant, priced like it (Balance.SENTRY_COST). One per wizard.

var _head: Node3D
var _orb: MeshInstance3D
var _shot_t := 0.0


func _ready() -> void:
	var c := color()
	var stone := Fx.solid(Color(0.22, 0.2, 0.24), 0.8)
	Art.part(self, Art.cyl(0.45, 0.6, 0.25, 8), stone, Vector3(0, 0.12, 0))
	Art.part(self, Art.cyl(0.14, 0.3, 1.3, 6), stone, Vector3(0, 0.85, 0))
	# A ring of the queue's elements round the pillar.
	var i := 0
	for e in spell.slots:
		var a: float = i * TAU / spell.slots.size()
		Art.part(self, Art.sphere(0.1, 8), Fx.element(e, 1.0), Vector3(cos(a) * 0.36, 0.3, sin(a) * 0.36))
		i += 1
	_head = Node3D.new()
	_head.position.y = 1.65
	add_child(_head)
	_orb = Art.part(_head, Art.sphere(0.3, 14), Fx.element(spell.primary, 1.4))
	Art.part(_head, Art.cyl(0.05, 0.09, 0.45, 6), stone, Vector3(0, 0, 0.35), Vector3(90, 0, 0))
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.0
	l.omni_range = 4.0
	_head.add_child(l)
	Fx.burst(global_position + Vector3.UP, c, 20, 4.0)
	Fx.ring(global_position, c, 2.0, 0.4)


func _physics_process(dt: float) -> void:
	t += dt
	_orb.position.y = sin(t * 3.0) * 0.06
	if t > n.duration or not is_instance_valid(caster):
		remove()
		return
	_shot_t -= dt
	var best: Actor = null
	var bd: float = n.range
	for a in targets():
		if a.team == caster.team:
			continue
		var d: float = a.global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = a
	if best == null:
		_head.rotation.y += dt * 0.8
		return
	var to := best.global_position - global_position
	to.y = 0
	_head.rotation.y = lerp_angle(_head.rotation.y, atan2(to.x, to.z), 10.0 * dt)
	if _shot_t <= 0.0 and caster is Wizard:
		_shot_t = n.interval
		var scales := {}
		for e in spell.counts:
			scales[e] = n.rate * spell.counts[e]
		var s := {counts = spell.counts, payload = [], primary = spell.primary, n = {}, scales = scales}
		var b := BoltFx.new().setup(caster as Wizard, s, to.normalized())
		Game.I.spawn(b, _head.global_position + to.normalized() * 0.5)


func remove() -> void:
	set_physics_process(false)
	Fx.burst(_head.global_position, color(), 20, 4.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(finish)

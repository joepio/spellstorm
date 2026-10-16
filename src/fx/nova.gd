class_name NovaFx
extends SpellFx
## Everything in the queue at once, in a ring around the caster (LT).
## Also used for any burst at a point: rune mines, confluences, overloads.

var radius := 3.0
var power := 1.0
var spare_caster := true
var only_team := -1


func _ready() -> void:
	radius = n.get("radius", radius)
	var at := global_position
	var cs := colors()
	for i in cs.size():
		Fx.ring(at, cs[i], radius * (1.0 - 0.12 * i), 0.3 + 0.08 * i)
	var p := Fx.particles(cs[0], 70, 0.55, 0.6)
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(1, 0, 0)
	p.spread = 180.0
	p.flatness = 0.85
	p.initial_velocity_min = radius * 2.0
	p.initial_velocity_max = radius * 2.8
	p.damping_min = radius * 2.0
	p.damping_max = radius * 3.0
	p.position = Vector3.UP * 0.5
	add_child(p)
	p.emitting = true
	Fx.light_pop(at, cs[0], 3.5, radius * 2.5, 0.4)
	for a in targets():
		if spare_caster and a == caster:
			continue
		if only_team != -1 and a.team != only_team:
			continue
		var d: Vector3 = a.global_position - at
		d.y = 0
		if d.length() < radius + a.radius:
			var dir := d.normalized() if d.length() > 0.05 else Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
			a.hit_spell(spell, power * n.get("rate", 1.0) * (1.0 - 0.35 * d.length() / radius), caster, dir, ff())
	touch(at, radius)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(queue_free)

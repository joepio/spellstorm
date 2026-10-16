class_name WallFx
extends SpellFx
## A row of pillars across where you aim (RB with a solid). Blocks monsters
## and their arrows. Payload elements hurt whatever leans on it.

class Pillar:
	extends StaticBody3D
	var hp := 60.0
	var owner_fx: WallFx

	func damage(x: float) -> void:
		hp -= x
		if hp <= 0.0 and is_inside_tree():
			Fx.burst(global_position + Vector3.UP, owner_fx.color(), 16, 5.0)
			queue_free()


var _pillars: Array = []
var _aura_t := 0.0


func _ready() -> void:
	var c := color()
	var dir: Vector3 = (caster as Wizard).aim_dir if caster is Wizard else Vector3.FORWARD
	var side := dir.cross(Vector3.UP).normalized()
	var count: int = n.pieces
	for i in count:
		var off: float = (i - (count - 1) * 0.5) * n.gap
		var p := Pillar.new()
		p.hp = n.hp
		p.owner_fx = self
		p.collision_layer = 1
		p.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 0.5
		cs.height = 2.0
		shape.shape = cs
		shape.position = Vector3.UP
		p.add_child(shape)
		var h := randf_range(1.3, 2.0)
		var mat: Material
		match spell.primary:
			El.ICE:
				var m := StandardMaterial3D.new()
				m.albedo_color = Color(c.r, c.g, c.b, 0.65)
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.emission_enabled = true
				m.emission = c * 0.4
				m.roughness = 0.1
				mat = m
			El.MAGMA:
				mat = Fx.glow(c, 1.8)
			_:
				mat = Fx.solid(c.darkened(0.1), 1.0)
		var mesh := Art.part(p, Art.cyl(0.32, 0.55, h, 6), mat, Vector3(0, h * 0.5, 0), Vector3(randf_range(-6, 6), randf() * 60, randf_range(-6, 6)))
		for e in spell.payload:
			Art.part(p, Art.cyl(0.56, 0.58, 0.12, 6), Fx.glow(El.COLOR[e], 2.0), Vector3(0, randf_range(0.3, h - 0.3), 0))
		add_child(p)
		p.position = side * off
		p.scale = Vector3(1, 0.05, 1)
		var tw := p.create_tween()
		tw.tween_property(p, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_pillars.append(p)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	Fx.burst(global_position, c, 30, 5.0)
	# Anyone standing where a pillar rises gets shoved aside.
	for a in targets():
		for p in _pillars:
			var d: Vector3 = a.global_position - p.global_position
			d.y = 0
			if d.length() < 0.9:
				a.push += d.normalized() * 6.0
	if spell.primary == El.MAGMA:
		var l := OmniLight3D.new()
		l.light_color = c
		l.light_energy = 1.5
		l.omni_range = count * 1.2
		l.position = Vector3.UP
		add_child(l)


func _physics_process(dt: float) -> void:
	t += dt
	_pillars = _pillars.filter(func(p): return is_instance_valid(p))
	if t > n.duration or _pillars.is_empty():
		for p in _pillars:
			var tw: Tween = p.create_tween()
			tw.tween_property(p, "scale", Vector3(1, 0.02, 1), 0.4)
		set_physics_process(false)
		var tw2 := create_tween()
		tw2.tween_interval(0.45)
		tw2.tween_callback(queue_free)
		return
	_aura_t -= dt
	var hot: bool = spell.primary == El.MAGMA or not spell.payload.is_empty()
	if not hot or _aura_t > 0.0:
		return
	_aura_t = 0.25
	for a in targets():
		if a.team == caster.team:
			continue
		for p in _pillars:
			var d: Vector3 = a.global_position - p.global_position
			d.y = 0
			if d.length() < 1.0 + a.radius:
				a.hit_spell(spell, 0.25 * n.rate, caster, d.normalized(), ff())
				break

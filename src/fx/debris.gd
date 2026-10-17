class_name Debris
extends Node3D
## Pieces of a dead monster thrown about with their own little physics:
## they fly, fall, bounce and tumble on the floor, settle, lie there a while
## and sink away. Cheaper and steadier than real rigid bodies, and the floor
## is flat anyway. Bones of a skeleton, ice of a frost brute, chunks of a
## ghoul.

const GRAVITY := 20.0

var _parts: Array[Node3D] = []
var _vel: Array[Vector3] = []
var _spin: Array[Vector3] = []
## How high each piece's centre rests above the floor.
var _rest: Array[float] = []
var _life := 4.0
var _t := 0.0


## Throw the meshes of [param model] (taken out of it, keeping where they
## are) away from [param from]: [param power] sideways, [param up] upward.
## They lie for [param life] seconds, then sink.
static func scatter(model: Node3D, from: Vector3, power: float, up: float, life := 4.0, mat: Material = null) -> Debris:
	var d := Debris.new()
	d._life = life
	if Fx.root == null:
		return d
	Fx.root.add_child(d)
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var at := mi.global_transform
		mi.get_parent().remove_child(mi)
		d.add_child(mi)
		mi.global_transform = at
		mi.material_overlay = null
		if mat:
			mi.material_override = mat
		d.add(mi, from, power, up)
	return d


## A few extra loose bits of [param c], for dust, gore or splinters.
func bits(at: Vector3, c: Color, n: int, size: float, power: float, up: float) -> void:
	for i in n:
		var mi := MeshInstance3D.new()
		mi.mesh = Art.box(size, size * randf_range(0.5, 1.0), size * randf_range(0.6, 1.2))
		mi.material_override = Fx.solid(c.darkened(randf() * 0.3), 0.9)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.global_position = at + Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.5), randf_range(-0.3, 0.3))
		add(mi, at, power, up)


func add(n: Node3D, from: Vector3, power: float, up: float) -> void:
	var away := n.global_position - from
	away.y = 0.0
	if away.length() < 0.05:
		away = Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
	var v := away.normalized() * power * randf_range(0.5, 1.2) + Vector3.UP * up * randf_range(0.6, 1.2)
	_parts.append(n)
	_vel.append(v)
	_spin.append(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * randf_range(4.0, 12.0))
	var rest := 0.06
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var box := (n as MeshInstance3D).mesh.get_aabb()
		var s := n.global_basis.get_scale()
		var dims := box.size * s
		rest = minf(dims.x, minf(dims.y, dims.z)) * 0.5
	_rest.append(rest)


func _physics_process(dt: float) -> void:
	_t += dt
	var sink := maxf(0.0, _t - _life)
	for i in _parts.size():
		var p := _parts[i]
		if sink > 0.0:
			p.global_position.y -= dt * 0.6
			continue
		var v := _vel[i]
		v.y -= GRAVITY * dt
		var at := p.global_position + v * dt
		if at.y < _rest[i]:
			at.y = _rest[i]
			if v.y < -2.0:
				v.y = -v.y * 0.35
			else:
				v.y = 0.0
			# Rolling on the floor slows a piece and its tumbling down.
			v.x *= 0.7
			v.z *= 0.7
			_spin[i] *= 0.6
		p.global_position = at
		var w := _spin[i]
		if w.length() > 0.05:
			p.global_rotate(w.normalized(), w.length() * dt)
		_vel[i] = v
	if sink > 1.6:
		queue_free()

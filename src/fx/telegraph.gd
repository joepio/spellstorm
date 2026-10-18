class_name Telegraph
extends MeshInstance3D
## A monster's attack, shown on the floor before it lands (telegraph.gdshader):
## the circle, slice or lane it will hit, filling in as the monster winds up.
## Whatever a monster does, you see it coming and can roll or step out.

var _mat: ShaderMaterial
var _size := Vector3.ONE


func _init() -> void:
	var q := PlaneMesh.new()
	q.size = Vector2(2.0, 2.0)
	mesh = q
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://src/fx/telegraph.gdshader")
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true


## A slice of a circle, [param radius] round, [param half] radians to each side.
static func slice(radius: float, half := PI) -> Telegraph:
	var t := Telegraph.new()
	t._mat.set_shader_parameter("arc", half)
	t._size = Vector3(radius, 1.0, radius)
	t.scale = t._size
	Fx.root.add_child(t)
	return t


## A lane [param width] wide and [param length] long, out in front.
static func lane(width: float, length: float) -> Telegraph:
	var t := Telegraph.new()
	t._mat.set_shader_parameter("lane", 1.0)
	t._size = Vector3(width * 0.5, 1.0, length * 0.5)
	t.scale = t._size
	t.set_meta("length", length)
	Fx.root.add_child(t)
	return t


## Put it at [param at] on the floor, facing [param dir]; a lane starts there.
func place(at: Vector3, dir: Vector3) -> void:
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length() < 0.01:
		d = Vector3.FORWARD
	d = d.normalized()
	var p := Vector3(at.x, 0.04, at.z)
	if has_meta("length"):
		p += d * float(get_meta("length")) * 0.5
	global_transform = Transform3D(Basis.looking_at(d, Vector3.UP) * Basis.from_scale(_size), p)


func set_fill(k: float) -> void:
	_mat.set_shader_parameter("fill", clampf(k, 0.0, 1.0))


## The attack went (or was cut off): a last flash, then gone.
func finish() -> void:
	if not is_inside_tree():
		queue_free()
		return
	set_fill(1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float): _mat.set_shader_parameter("fade", v), 1.0, 0.0, 0.18)
	tw.tween_callback(queue_free)

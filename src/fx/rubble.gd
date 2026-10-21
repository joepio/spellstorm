class_name Rubble
extends RigidBody3D
## A piece of a broken prop as a real physics body (Joep: a crumbling
## mausoleum should tumble, not slide into the floor). Pieces knock into each
## other, the ground and the walls, but never into wizards or monsters, then
## lie still as rubble. Once they rest they freeze, so lying rubble costs
## nothing; past the budget the oldest crumble away to dust.

const LAYER := 8
## Pieces at once over the whole level, lying or flying.
const MAX_PIECES := 260

static var _all: Array[Rubble] = []

var _age := 0.0


## Throw [param mesh] in [param mat], placed at [param xf] (global), with
## velocity [param v]. The body sits at the middle of the mesh's bounds, so
## it tumbles round its own centre.
static func throw(mesh: Mesh, mat: Material, xf: Transform3D, v: Vector3) -> void:
	if Fx.root == null or mesh == null:
		return
	var box := mesh.get_aabb()
	var s := xf.basis.get_scale()
	var dims := (box.size * s).abs()
	var r := Rubble.new()
	r.collision_layer = LAYER
	r.collision_mask = 1 | 4 | LAYER
	r.mass = clampf(dims.x * dims.y * dims.z * 400.0, 0.5, 60.0)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.1
	r.physics_material_override = pm
	r.angular_damp = 1.5
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(maxf(dims.x, 0.06), maxf(dims.y, 0.06), maxf(dims.z, 0.06)) * 0.92
	cs.shape = bs
	r.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The mesh keeps its scale; the body carries the rotation only.
	mi.scale = s
	mi.position = -box.get_center() * s
	Art.pin_stone(mi, xf)
	r.add_child(mi)
	Fx.root.add_child(r)
	r.global_transform = Transform3D(xf.basis.orthonormalized(), xf * box.get_center())
	r.linear_velocity = v
	r.angular_velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * randf_range(2.0, 6.0)
	_all.append(r)
	while _all.size() > MAX_PIECES:
		var old: Rubble = _all.pop_front()
		if is_instance_valid(old):
			old.crumble()


func _exit_tree() -> void:
	_all.erase(self)


func _physics_process(dt: float) -> void:
	_age += dt
	# At rest (or after long enough), it is rubble: no more physics.
	if (_age > 1.0 and sleeping) or _age > 8.0:
		freeze = true
		set_physics_process(false)


## Fall to dust: shrink away with a puff.
func crumble() -> void:
	_all.erase(self)
	freeze = true
	Fx.burst(global_position, Color(0.4, 0.37, 0.33), 3, 1.0, 0.06)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.5)
	tw.tween_callback(queue_free)

class_name CastMark
extends Node3D
## The spot a charging spell is aimed at (Wizard._charge_look): runes on the
## floor and the element seeping up out of the ground there, faint at first
## and stronger as the spell fills, so you can see where it will strike.

var _mat: ShaderMaterial
var _disc: MeshInstance3D
var _parts: CPUParticles3D


func setup(e: int, radius: float) -> CastMark:
	top_level = true
	var c: Color = El.COLOR[e]
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://src/fx/cast_mark.gdshader")
	_mat.set_shader_parameter("color", c)
	_disc = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.orientation = PlaneMesh.FACE_Y
	_disc.mesh = q
	_disc.material_override = _mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = 0.05
	add_child(_disc)
	_parts = Fx.particles(c, 24, 0.9, 0.18)
	_parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_parts.emission_ring_axis = Vector3.UP
	_parts.emission_ring_height = 0.0
	_parts.direction = Vector3.UP
	_parts.spread = 10.0
	_parts.initial_velocity_min = 0.4
	_parts.initial_velocity_max = 1.1
	Parts.style(_parts, e)
	# Seeping up, whatever the element normally does.
	_parts.gravity = Vector3.UP * 0.6
	add_child(_parts)
	_parts.emitting = true
	set_radius(radius)
	return self


func set_radius(r: float) -> void:
	_disc.scale = Vector3.ONE * r * 2.0
	_parts.emission_ring_radius = r * 0.85
	_parts.emission_ring_inner_radius = r * 0.3


## Make it a lane instead of a circle: the strip [param width] wide and
## [param length] long that a rolling spell will sweep, centred on this
## node and facing along its -Z (turn it with look_at).
func set_lane(width: float, length: float) -> void:
	_mat.set_shader_parameter("lane", 1.0)
	_mat.set_shader_parameter("aspect", length / width)
	_disc.scale = Vector3(width, 1.0, length)
	_parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_parts.emission_box_extents = Vector3(width * 0.45, 0.0, length * 0.45)
	_parts.amount = 48


func set_charge(k: float) -> void:
	_mat.set_shader_parameter("charge", k)
	_parts.speed_scale = 0.5 + 0.7 * k


## Fades out on its own once the spell goes.
func finish() -> void:
	_parts.emitting = false
	var tw := create_tween()
	tw.tween_method(func(v: float): _mat.set_shader_parameter("charge", v), 1.0, 0.0, 0.25)
	tw.tween_callback(func(): _disc.visible = false)
	get_tree().create_timer(1.0).timeout.connect(queue_free)

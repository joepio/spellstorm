class_name Robe
extends MeshInstance3D
## The lower robe as cloth: rings of points hanging from the waist, joined to
## their neighbours, pulled back towards the robe's shape by a soft spring
## and thrown around by how the wizard moves. Walking swings the hem behind
## you, stopping sways it forward, a roll flares it out, and when the body
## topples it falls the way gravity really points. Simulated in the body's
## own space (with the forces of its motion added), so whatever moves or
## scales the body (deaths, revives) carries the robe along.

const SEGS := 14
const RINGS := 6
const TOP := Vector2(0.76, 0.27)
const BOTTOM := Vector2(0.16, 0.46)
const STIFF := 7.0
const DAMP := 0.94
const SUBSTEPS := 2

var color := Color.WHITE
var hem := Color.BLACK

var _rest: PackedVector3Array
var _pos: PackedVector3Array
var _prev: PackedVector3Array
var _len_down: PackedFloat32Array
var _len_round: PackedFloat32Array
var _last_world := Vector3.INF
var _last_vel := Vector3.ZERO
var _last_yaw := 0.0
var _accel := Vector3.ZERO
var _mesh := ArrayMesh.new()


func setup(robe: Color, trim: Color) -> Robe:
	color = robe
	hem = trim
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	# The colours are the same sRGB ones the rest of the model uses.
	m.vertex_color_is_srgb = true
	m.roughness = 0.9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = m
	_rest.resize(SEGS * RINGS)
	for r in RINGS:
		var k := float(r) / (RINGS - 1)
		# The cone widens faster near the hem, like cloth falling in folds.
		var y := lerpf(TOP.x, BOTTOM.x, k)
		var rad := lerpf(TOP.y, BOTTOM.y, pow(k, 0.8))
		for s in SEGS:
			var a := TAU * s / SEGS
			# A little in and out round the hem reads as folds.
			var fold := 1.0 + 0.07 * k * sin(a * 3.0 + 0.6)
			_rest[r * SEGS + s] = Vector3(sin(a) * rad * fold, y, cos(a) * rad * fold)
	_pos = _rest.duplicate()
	_prev = _rest.duplicate()
	_len_down.resize(SEGS * RINGS)
	_len_round.resize(SEGS * RINGS)
	for r in RINGS:
		for s in SEGS:
			var i := r * SEGS + s
			_len_down[i] = _rest[i].distance_to(_rest[i - SEGS]) if r > 0 else 0.0
			_len_round[i] = _rest[i].distance_to(_rest[r * SEGS + (s + 1) % SEGS])
	mesh = _mesh
	_build()
	return self


func _physics_process(dt: float) -> void:
	var body := get_parent() as Node3D
	if body == null or not is_visible_in_tree() or dt <= 0.0:
		return
	var xf := body.global_transform
	var inv := xf.basis.inverse()
	var scale_y := maxf(xf.basis.get_scale().y, 0.01)
	# The forces of the body's motion, felt in its own space.
	var world := xf.origin
	if _last_world == Vector3.INF:
		_last_world = world
	var vel := (world - _last_world) / dt
	# Smoothed: a bump against a wall or a step of the walk is a jolt for
	# one frame, and fed in raw it makes the whole hem shiver.
	var raw := ((vel - _last_vel) / dt).limit_length(30.0)
	_accel = _accel.lerp(raw, 1.0 - exp(-10.0 * dt))
	var accel := _accel
	_last_world = world
	_last_vel = vel
	var yaw := xf.basis.get_euler().y
	var dyaw := wrapf(yaw - _last_yaw, -PI, PI)
	_last_yaw = yaw
	var g := inv * (Vector3.DOWN * 9.8 - accel) / scale_y
	# A turn leaves the hem behind for a moment.
	if absf(dyaw) > 0.0001:
		var turn := Basis(Vector3.UP, -dyaw * 0.65)
		for i in range(SEGS, _pos.size()):
			_pos[i] = turn * _pos[i]
			_prev[i] = turn * _prev[i]
	var h := dt / SUBSTEPS
	for _sub in SUBSTEPS:
		_step(h, g)
	_build()


func _step(h: float, g: Vector3) -> void:
	var pull := 1.0 - exp(-STIFF * h)
	for i in range(SEGS, _pos.size()):
		var p := _pos[i]
		var v := (p - _prev[i]) * DAMP
		_prev[i] = p
		p += v + g * h * h
		# The lower the ring, the looser it hangs.
		var k := float(i / SEGS) / (RINGS - 1)
		p = p.lerp(_rest[i], pull * lerpf(1.6, 0.6, k))
		_pos[i] = p
	for _it in 3:
		for r in range(1, RINGS):
			for s in SEGS:
				var i := r * SEGS + s
				_link(i, i - SEGS, _len_down[i], r == 1)
				var j := r * SEGS + (s + 1) % SEGS
				_link(i, j, _len_round[i], false)
		# Never through the legs: each point keeps out from the middle.
		for i in range(SEGS, _pos.size()):
			var p := _pos[i]
			var rest := _rest[i]
			var want := Vector2(rest.x, rest.z).length() * 0.85
			var flat := Vector2(p.x, p.z)
			if flat.length() < want:
				flat = (flat.normalized() if flat.length() > 0.001 else Vector2(rest.x, rest.z).normalized()) * want
				p.x = flat.x
				p.z = flat.y
			p.y = clampf(p.y, BOTTOM.x - 0.05, TOP.x)
			_pos[i] = p


func _link(i: int, j: int, rest: float, j_pinned: bool) -> void:
	var d := _pos[i] - _pos[j]
	var l := d.length()
	if l < 0.0001:
		return
	var fix := d * ((l - rest) / l)
	if j_pinned:
		_pos[i] -= fix
	else:
		_pos[i] -= fix * 0.5
		_pos[j] += fix * 0.5


func _build() -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	# One more column than segments, so the seam has its own vertices.
	for r in RINGS:
		for s in SEGS + 1:
			var i := r * SEGS + s % SEGS
			verts.append(_pos[i])
			var right := _pos[r * SEGS + (s + 1) % SEGS] - _pos[r * SEGS + (s + SEGS - 1) % SEGS]
			var down := _pos[mini(r + 1, RINGS - 1) * SEGS + s % SEGS] - _pos[maxi(r - 1, 0) * SEGS + s % SEGS]
			var n := down.cross(right).normalized()
			norms.append(n)
			cols.append(hem if r == RINGS - 1 else color)
	for r in RINGS - 1:
		for s in SEGS:
			var a := r * (SEGS + 1) + s
			var b := a + 1
			var c := a + SEGS + 1
			var d := c + 1
			idx.append_array([a, c, b, b, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

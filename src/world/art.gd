class_name Art
## Everything visible is built here from primitive meshes, so there are no
## model files to keep in sync.

## Where the blade starts on a sword, above the hand.
const BLADE_AT := 0.12

static var _title: Font
static var _body: Font


static func title_font() -> Font:
	if _title == null:
		var f := FontVariation.new()
		f.base_font = load("res://assets/fonts/Cinzel.ttf")
		f.variation_opentype = {"wght": 800}
		_title = f
	return _title


static func body_font() -> Font:
	if _body == null:
		_body = load("res://assets/fonts/Alegreya.ttf")
	return _body


static func part(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot
	m.scale = scl
	parent.add_child(m)
	return m


## Fold the plain still parts of [param root] that share a material into
## one mesh each: a prop of twelve parts draws in two or three calls instead
## of twelve (and as many again for every shadow it is in). Cards,
## billboards and anything with children or a script stay as they are.
static func merge_parts(root: Node3D) -> void:
	var groups := {}
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var mat := mi.material_override
		if mi.mesh == null or mi.mesh is QuadMesh or mi.mesh is PlaneMesh or not mi.visible or mi.get_child_count() > 0 or mi.get_script() != null or mat == null:
			continue
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			if sm.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
				continue
		elif not (mat is ShaderMaterial and (mat as ShaderMaterial).shader and (mat as ShaderMaterial).shader.resource_path.ends_with("stone.gdshader")):
			continue
		var am := mi.mesh as ArrayMesh
		var ok := true
		var fmt := ""
		for i in mi.mesh.get_surface_count():
			if am and am.surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES:
				ok = false
			var a := mi.mesh.surface_get_arrays(i)
			fmt += "%d%d%d" % [int(a[Mesh.ARRAY_COLOR] != null), int(a[Mesh.ARRAY_TEX_UV] != null), int(a[Mesh.ARRAY_TANGENT] != null)]
		if not ok:
			continue
		var key := [mat.get_instance_id(), mi.cast_shadow, fmt]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(mi)
	for key: Array in groups:
		var parts: Array = groups[key]
		if parts.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi: MeshInstance3D in parts:
			var xf := mi.transform
			var p := mi.get_parent() as Node3D
			while p and p != root:
				xf = p.transform * xf
				p = p.get_parent() as Node3D
			for i in mi.mesh.get_surface_count():
				st.append_from(mi.mesh, i, xf)
		var one := MeshInstance3D.new()
		one.mesh = st.commit()
		one.material_override = (parts[0] as MeshInstance3D).material_override
		one.cast_shadow = (parts[0] as MeshInstance3D).cast_shadow
		root.add_child(one)
		for mi: MeshInstance3D in parts:
			mi.get_parent().remove_child(mi)
			mi.free()


static func cyl(top: float, bottom: float, h: float, seg := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func sphere(r: float, seg := 12) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = seg / 2
	return s


static func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


## Sword steel: cool and dark enough that the ridge and edges catch the
## light instead of the whole blade burning white.
static var _stones := {}


## Rough stone (stone.gdshader) in [param c], with [param moss] settling on
## top; one material per colour, shared.
static func stone(c: Color, moss := 0.0, moss_c := Color(0.12, 0.16, 0.08)) -> ShaderMaterial:
	var key := "%s%.2f%s" % [c.to_html(), moss, moss_c.to_html()]
	if not _stones.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/world/stone.gdshader")
		# A touch lighter than the old flat paint: the cracks and bump take
		# some back, and the dark comes from the light.
		m.set_shader_parameter("color", c.lightened(0.15))
		m.set_shader_parameter("moss_amount", moss)
		m.set_shader_parameter("moss", moss_c)
		_stones[key] = m
	return _stones[key]


static func steel() -> StandardMaterial3D:
	var m := Fx.solid(Color(0.5, 0.53, 0.58), 0.28)
	m.metallic = 0.85
	return m


static var _blades := {}


## A sword blade `length` metres long, rising along +y from the guard: a
## diamond in section (thin edges, a raised ridge), a little narrower near
## the point, then a sharp point. Flat-shaded so the two faces either side
## of the ridge light differently. UV.x runs edge to edge (0.5 is the
## ridge), UV.y is the distance from the guard in metres.
static func blade_mesh(length: float) -> ArrayMesh:
	var key := snappedf(length, 0.01)
	if _blades.has(key):
		return _blades[key]
	var tip := minf(0.26, length * 0.22)
	# Rings from guard to point: [height, half width, half thickness].
	var rings := [[0.0, 0.07, 0.019], [0.1, 0.064, 0.018], [length - tip, 0.05, 0.014], [length, 0.0, 0.0]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The section's corners: left edge, front ridge, right edge, back ridge.
	var corners := [[-1.0, 0.0, 0.0], [0.0, 1.0, 0.5], [1.0, 0.0, 1.0], [0.0, -1.0, 0.5]]
	for r in rings.size() - 1:
		var a: Array = rings[r]
		var b: Array = rings[r + 1]
		for c in 4:
			var c0: Array = corners[c]
			var c1: Array = corners[(c + 1) % 4]
			var p00 := Vector3(c0[0] * a[1], a[0], c0[1] * a[2])
			var p01 := Vector3(c1[0] * a[1], a[0], c1[1] * a[2])
			var p10 := Vector3(c0[0] * b[1], b[0], c0[1] * b[2])
			var p11 := Vector3(c1[0] * b[1], b[0], c1[1] * b[2])
			var u0: float = c0[2]
			var u1: float = c1[2]
			for tri in [[[p00, u0, a[0]], [p10, u0, b[0]], [p11, u1, b[0]]], [[p00, u0, a[0]], [p11, u1, b[0]], [p01, u1, a[0]]]]:
				var n: Vector3 = (tri[2][0] - tri[0][0]).cross(tri[1][0] - tri[0][0])
				if n.length() < 0.000001:
					continue
				# Outward, whichever way the corners went round.
				var mid: Vector3 = (tri[0][0] + tri[1][0] + tri[2][0]) / 3.0
				n = n.normalized()
				if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
					n = -n
					tri = [tri[0], tri[2], tri[1]]
				for v in tri:
					st.set_normal(n)
					st.set_uv(Vector2(v[1], v[2]))
					st.add_vertex(v[0])
	var m := st.commit()
	_blades[key] = m
	return m


static var _cloths := {}


## Worn wool (cloth.gdshader) in [param c]; one material per colour, shared.
## White takes the mesh's vertex colours instead (the robe's skirt).
static func cloth(c: Color, weave := 90.0) -> ShaderMaterial:
	var key := "%s%.0f" % [c.to_html(), weave]
	if not _cloths.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/world/cloth.gdshader")
		m.set_shader_parameter("color", c)
		m.set_shader_parameter("weave", weave)
		_cloths[key] = m
	return _cloths[key]


## A wandering wizard in a worn wool robe with a short mantle over the
## shoulders, a slouched felt hat, a long grey beard and a gnarled staff.
## Kept muted and weathered rather than toy-bright: the colour says whose
## wizard it is, the light does the rest. Returns the parts the wizard
## animates: body, staff, gem, hat.
static func wizard(robe: Color) -> Dictionary:
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	robe = Color.from_hsv(robe.h, robe.s * 0.7, robe.v * 0.6)
	var dark := robe.darkened(0.45)
	var robe_m := cloth(robe)
	var mantle_m := cloth(robe.darkened(0.15).lerp(Color(0.25, 0.22, 0.2), 0.2), 70.0)
	var leather := Shape.material(Color(0.3, 0.2, 0.13), Color(0.12, 0.08, 0.05), 3.0, 0.7, 0.5, 0.0, 3)
	var iron := Shape.material(Color(0.34, 0.33, 0.32), Color(0.16, 0.15, 0.15), 4.0, 0.45, 0.3, 0.7, 5)
	var meshes: Array[GeometryInstance3D] = []
	# Legs under the robe, in dark breeches and boots, that step as they walk.
	var leg_m := cloth(dark.darkened(0.3), 120.0)
	var legs: Array[Node3D] = []
	for side in [1.0, -1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.11 * side, 0.62, 0)
		body.add_child(hip)
		meshes.append(part(hip, Shape.limb(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, -0.25, 0.01), Vector3(0, -0.46, 0)]), PackedFloat32Array([0.075, 0.065, 0.06])), leg_m))
		meshes.append(part(hip, Shape.blob(Vector3(0.068, 0.07, 0.125), 0.05, side * 3.0, 8, 12), leather, Vector3(0, -0.55, 0.035)))
		legs.append(hip)
	# Torso: narrow at the waist, filling out to the chest, sloping off to
	# the neck.
	var torso := Shape.lathe(PackedVector2Array([Vector2(0.21, 0.66), Vector2(0.2, 0.76), Vector2(0.23, 0.92), Vector2(0.24, 1.04), Vector2(0.18, 1.14), Vector2(0.07, 1.2)]), 20)
	meshes.append(part(body, torso, robe_m, Vector3.ZERO, Vector3.ZERO, Vector3(1.12, 1, 0.92)))
	var skirt := Robe.new().setup(robe, dark)
	skirt.material_override = cloth(Color.WHITE)
	skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(skirt)
	meshes.append(skirt)
	# A plain leather belt with an iron buckle, and a pouch on the hip.
	meshes.append(part(body, cyl(0.235, 0.235, 0.05, 20), leather, Vector3(0, 0.75, 0), Vector3.ZERO, Vector3(1.12, 1, 0.92)))
	meshes.append(part(body, box(0.07, 0.06, 0.02), iron, Vector3(0, 0.75, 0.22)))
	meshes.append(part(body, Shape.blob(Vector3(0.07, 0.08, 0.04), 0.08, 2.0, 8, 10), leather, Vector3(-0.22, 0.68, 0.1), Vector3(0, -40, 0)))
	# A short mantle over the shoulders, hanging in folds.
	var mantle := Shape.lathe(PackedVector2Array([Vector2(0.33, 0.88), Vector2(0.32, 0.98), Vector2(0.27, 1.1), Vector2(0.15, 1.18), Vector2(0.09, 1.22)]), 24, 7, 0.08)
	meshes.append(part(body, mantle, mantle_m, Vector3(0, 0, 0.0), Vector3.ZERO, Vector3(1.1, 1, 0.95)))
	# Arms in wide sleeves that swing from the shoulders: the right hand
	# holds the staff.
	var skin := Shape.material(Color(0.78, 0.6, 0.48), Color(0.55, 0.36, 0.3), 5.0, 0.6, 0.2, 0.0, 9)
	var arms: Array[Node3D] = []
	for side in [1.0, -1.0]:
		var sh := Node3D.new()
		sh.position = Vector3(0.29 * side, 1.04, 0.02)
		body.add_child(sh)
		meshes.append(part(sh, Shape.limb(PackedVector3Array([Vector3(0, 0.02, 0), Vector3(0, -0.2, 0.01), Vector3(0, -0.38, 0.02)]), PackedFloat32Array([0.075, 0.085, 0.115]), 10), robe_m))
		meshes.append(part(sh, Shape.blob(Vector3(0.05, 0.065, 0.055), 0.12, side, 8, 10), skin, Vector3(0, -0.45, 0)))
		arms.append(sh)
	# An old face: a nose, deep-set eyes, grey hair and a long beard.
	meshes.append(part(body, Shape.blob(Vector3(0.125, 0.145, 0.13), 0.04, 4.0), skin, Vector3(0, 1.3, 0.03)))
	meshes.append(part(body, Shape.limb(PackedVector3Array([Vector3(0, 1.32, 0.15), Vector3(0, 1.28, 0.18)]), PackedFloat32Array([0.022, 0.026]), 6), skin))
	var eye_m := Fx.solid(Color(0.06, 0.05, 0.05), 0.3)
	for side in [1.0, -1.0]:
		part(body, sphere(0.016, 6), eye_m, Vector3(0.05 * side, 1.33, 0.145))
	var grey := Shape.material(Color(0.72, 0.71, 0.68), Color(0.45, 0.44, 0.42), 9.0, 0.95, 0.9, 0.0, 11)
	meshes.append(part(body, Shape.blob(Vector3(0.14, 0.12, 0.13), 0.12, 6.0), grey, Vector3(0, 1.3, -0.03)))
	meshes.append(part(body, Shape.limb(PackedVector3Array([Vector3(0, 1.25, 0.13), Vector3(0, 1.12, 0.19), Vector3(0, 0.98, 0.21), Vector3(0, 0.88, 0.19)]), PackedFloat32Array([0.1, 0.085, 0.05, 0.012]), 10), grey, Vector3.ZERO, Vector3.ZERO, Vector3(1, 1, 0.75)))
	# A slouched felt hat: a wide brim drooping at the edge and a tall crown
	# that bends back and sags.
	var hat := Node3D.new()
	hat.position = Vector3(0, 1.38, 0)
	body.add_child(hat)
	var felt := cloth(robe.darkened(0.3).lerp(Color(0.2, 0.17, 0.14), 0.2), 200.0)
	var brim := Shape.lathe(PackedVector2Array([Vector2(0.33, -0.05), Vector2(0.3, -0.01), Vector2(0.24, 0.015), Vector2(0.17, 0.025)]), 28, 5, 0.05)
	meshes.append(part(hat, brim, felt))
	meshes.append(part(hat, Shape.limb(PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0, 0.18, -0.02), Vector3(0, 0.34, -0.08), Vector3(0, 0.44, -0.2), Vector3(0, 0.41, -0.31)]), PackedFloat32Array([0.18, 0.16, 0.11, 0.06, 0.025]), 14), felt))
	meshes.append(part(hat, cyl(0.183, 0.185, 0.05, 20), leather, Vector3(0, 0.04, 0)))
	# The staff turns about the hand at the end of the right sleeve, so
	# pointing it tips the gem forward instead of swinging it from the feet.
	# Gnarled wood, with roots curling up round the gem.
	var staff := Node3D.new()
	staff.position = Vector3(0.42, 0.75, 0.18)
	body.add_child(staff)
	var wood := Shape.material(Color(0.33, 0.24, 0.16), Color(0.13, 0.09, 0.06), 6.0, 0.8, 0.9, 0.0, 13)
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 9:
		var y := lerpf(-0.75, 1.0, i / 8.0)
		pts.append(Vector3(sin(i * 2.1) * 0.018, y, cos(i * 1.7) * 0.015))
		radii.append(lerpf(0.032, 0.038, i / 8.0) + (0.008 if i % 3 == 1 else 0.0))
	meshes.append(part(staff, Shape.limb(pts, radii, 7), wood))
	for k in 3:
		var a := TAU * k / 3.0 + 0.4
		var out := Vector3(cos(a), 0, sin(a))
		meshes.append(part(staff, Shape.limb(Shape.curve(Vector3(0, 0.98, 0), out * 0.12 + Vector3(0, 1.1, 0), out * 0.05 + Vector3(0, 1.24, 0), 5), Shape.taper(0.028, 0.008, 5), 6), wood))
	var gem := part(staff, sphere(0.085, 12), Fx.glow(Color(0.9, 0.85, 0.7), 2.5), Vector3(0, 1.12, 0))
	# A sword in the other hand, for the swing: a long, tapering blade with
	# a raised ridge, a guard whose arms sweep up towards it, a wrapped grip
	# and a heavy pommel. The blade is built as long as the swing reaches
	# (blade_mesh, called again whenever that changes).
	var sword := Node3D.new()
	sword.position = Vector3(-0.36, 0.78, 0.24)
	body.add_child(sword)
	var blade := Node3D.new()
	blade.position.y = BLADE_AT
	sword.add_child(blade)
	var steel_mi := part(blade, blade_mesh(1.0), steel())
	meshes.append(steel_mi)
	var hilt := Fx.solid(Color(0.62, 0.48, 0.24), 0.35)
	hilt.metallic = 0.6
	var dark_steel := Fx.solid(Color(0.3, 0.31, 0.34), 0.4)
	dark_steel.metallic = 0.7
	# The hand holds the grip at the sword's origin; the guard sits above it.
	var g := BLADE_AT - 0.025
	meshes.append(part(sword, box(0.14, 0.05, 0.08), dark_steel, Vector3(0, g, 0)))
	for side in [1.0, -1.0]:
		meshes.append(part(sword, box(0.17, 0.04, 0.055), dark_steel, Vector3(side * 0.14, g + 0.02, 0), Vector3(0, 0, side * 20.0)))
		meshes.append(part(sword, sphere(0.034, 6), hilt, Vector3(side * 0.23, g + 0.055, 0)))
	# A stone in the guard that lights with the enchantment.
	var stone := part(sword, sphere(0.036, 8), Fx.solid(Color(0.2, 0.22, 0.3), 0.2), Vector3(0, g, 0.04), Vector3.ZERO, Vector3(1, 1, 0.6))
	meshes.append(part(sword, cyl(0.024, 0.028, 0.2, 6), Fx.solid(Color(0.22, 0.12, 0.07), 0.9), Vector3(0, g - 0.125, 0)))
	for i in 3:
		meshes.append(part(sword, cyl(0.031, 0.031, 0.016, 6), hilt, Vector3(0, g - 0.06 - i * 0.06, 0)))
	meshes.append(part(sword, sphere(0.05, 8), hilt, Vector3(0, g - 0.26, 0), Vector3.ZERO, Vector3(1, 1.25, 1)))
	return {root = root, body = body, staff = staff, gem = gem, hat = hat, meshes = meshes,
		arm_r = arms[0], arm_l = arms[1], leg_r = legs[0], leg_l = legs[1], sword = sword, blade = blade, steel = steel_mi, stone = stone}


static func tombstone() -> Node3D:
	var n := Node3D.new()
	var stone := stone(Color(0.38, 0.37, 0.4), 0.5)
	part(n, box(0.7, 0.9, 0.18), stone, Vector3(0, 0.45, 0))
	part(n, cyl(0.35, 0.35, 0.18, 20), stone, Vector3(0, 0.9, 0), Vector3(90, 0, 0))
	part(n, box(0.08, 0.4, 0.04), Fx.solid(Color(0.2, 0.2, 0.22)), Vector3(0, 0.62, 0.1))
	part(n, box(0.28, 0.08, 0.04), Fx.solid(Color(0.2, 0.2, 0.22)), Vector3(0, 0.72, 0.1))
	part(n, box(1.0, 0.12, 0.6), Fx.solid(Color(0.22, 0.18, 0.12)), Vector3(0, 0.06, 0.1))
	return n

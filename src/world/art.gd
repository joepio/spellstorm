class_name Art
## Everything visible is built here from primitive meshes, so there are no
## model files to keep in sync.

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


## A robed wizard with a pointed hat and a staff. Returns the parts the
## wizard animates: body, staff, gem, hat.
static func wizard(robe: Color) -> Dictionary:
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var dark := robe.darkened(0.45)
	var robe_m := Fx.solid(robe, 0.9)
	var trim_m := Fx.solid(Color(0.75, 0.6, 0.3), 0.5)
	var meshes: Array[GeometryInstance3D] = []
	# Legs under the robe, in dark breeches and boots, that step as they walk.
	var leg_m := Fx.solid(dark.darkened(0.3), 0.9)
	var boot_m := Fx.solid(Color(0.22, 0.15, 0.1), 0.7)
	var legs: Array[Node3D] = []
	for side in [1.0, -1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.11 * side, 0.62, 0)
		body.add_child(hip)
		meshes.append(part(hip, cyl(0.07, 0.06, 0.5, 8), leg_m, Vector3(0, -0.27, 0)))
		meshes.append(part(hip, box(0.13, 0.1, 0.24), boot_m, Vector3(0, -0.56, 0.04)))
		legs.append(hip)
	# A round belly under the chest, belted, with the skirt of the robe
	# hanging from the hips as cloth (Robe).
	meshes.append(part(body, sphere(0.27, 12), robe_m, Vector3(0, 0.8, 0.02), Vector3.ZERO, Vector3(1.0, 0.85, 1.05)))
	meshes.append(part(body, cyl(0.22, 0.26, 0.24, 12), robe_m, Vector3(0, 0.93, 0)))
	var skirt := Robe.new().setup(robe, dark)
	skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(skirt)
	meshes.append(skirt)
	meshes.append(part(body, cyl(0.275, 0.275, 0.06, 14), trim_m, Vector3(0, 0.74, 0.01)))
	part(body, box(0.09, 0.08, 0.03), Fx.solid(Color(0.9, 0.78, 0.4), 0.3), Vector3(0, 0.74, 0.285))
	# Shoulders, and arms that swing from them: the right hand holds the staff.
	meshes.append(part(body, sphere(0.27), robe_m, Vector3(0, 1.02, 0), Vector3.ZERO, Vector3(1.15, 0.7, 1.0)))
	var skin := Fx.solid(Color(0.85, 0.68, 0.55))
	var arms: Array[Node3D] = []
	for side in [1.0, -1.0]:
		var sh := Node3D.new()
		sh.position = Vector3(0.29 * side, 1.04, 0.02)
		body.add_child(sh)
		meshes.append(part(sh, cyl(0.07, 0.11, 0.42, 8), robe_m, Vector3(0, -0.21, 0)))
		meshes.append(part(sh, sphere(0.065, 8), skin, Vector3(0, -0.45, 0)))
		arms.append(sh)
	# Head in a hood shadow, with a beard.
	meshes.append(part(body, sphere(0.17), Fx.solid(Color(0.85, 0.68, 0.55)), Vector3(0, 1.28, 0.03)))
	meshes.append(part(body, cyl(0.02, 0.13, 0.32, 8), Fx.solid(Color(0.85, 0.85, 0.82)), Vector3(0, 1.12, 0.12), Vector3(-15, 0, 0)))
	var eye_m := Fx.glow(Color(1.0, 0.85, 0.5), 3.0)
	part(body, sphere(0.025, 6), eye_m, Vector3(0.06, 1.31, 0.17))
	part(body, sphere(0.025, 6), eye_m, Vector3(-0.06, 1.31, 0.17))
	var hat := Node3D.new()
	hat.position = Vector3(0, 1.38, 0)
	body.add_child(hat)
	meshes.append(part(hat, cyl(0.36, 0.36, 0.04, 14), robe_m, Vector3(0, 0.0, 0)))
	meshes.append(part(hat, cyl(0.0, 0.2, 0.62, 10), robe_m, Vector3(0, 0.31, -0.04), Vector3(-12, 0, 0)))
	meshes.append(part(hat, cyl(0.205, 0.21, 0.06, 10), trim_m, Vector3(0, 0.05, 0)))
	# The staff turns about the hand at the end of the right sleeve, so
	# pointing it tips the gem forward instead of swinging it from the feet.
	var staff := Node3D.new()
	staff.position = Vector3(0.42, 0.75, 0.18)
	body.add_child(staff)
	meshes.append(part(staff, cyl(0.03, 0.04, 1.7, 6), Fx.solid(Color(0.32, 0.2, 0.12)), Vector3(0, 0.1, 0)))
	meshes.append(part(staff, cyl(0.09, 0.03, 0.18, 6), Fx.solid(Color(0.32, 0.2, 0.12)), Vector3(0, 0.97, 0)))
	var gem := part(staff, sphere(0.11, 12), Fx.glow(Color(0.9, 0.85, 0.7), 2.5), Vector3(0, 1.12, 0))
	# A sword in the other hand, for the swing. The blade is a metre long
	# under `blade`, so scaling that sets how far it reaches.
	var sword := Node3D.new()
	sword.position = Vector3(-0.36, 0.78, 0.24)
	body.add_child(sword)
	var steel := Fx.solid(Color(0.72, 0.74, 0.78), 0.25)
	steel.metallic = 0.8
	var blade := Node3D.new()
	blade.position.y = 0.04
	sword.add_child(blade)
	meshes.append(part(blade, box(0.085, 1.0, 0.022), steel, Vector3(0, 0.5, 0)))
	# A ridge down the middle catches the light.
	part(blade, box(0.018, 0.96, 0.03), Fx.solid(Color(0.9, 0.92, 0.95), 0.15), Vector3(0, 0.49, 0))
	meshes.append(part(blade, cyl(0.0, 0.06, 0.12, 4), steel, Vector3(0, 1.06, 0), Vector3(0, 45, 0), Vector3(1, 1, 0.37)))
	var hilt := Fx.solid(Color(0.75, 0.6, 0.3), 0.4)
	meshes.append(part(sword, box(0.3, 0.045, 0.07), hilt, Vector3(0, 0.02, 0)))
	meshes.append(part(sword, cyl(0.024, 0.024, 0.2, 6), Fx.solid(Color(0.25, 0.14, 0.08), 0.8), Vector3(0, -0.1, 0)))
	meshes.append(part(sword, sphere(0.04, 6), hilt, Vector3(0, -0.22, 0)))
	return {root = root, body = body, staff = staff, gem = gem, hat = hat, meshes = meshes,
		arm_r = arms[0], arm_l = arms[1], leg_r = legs[0], leg_l = legs[1], sword = sword, blade = blade}


static func tombstone() -> Node3D:
	var n := Node3D.new()
	var stone := Fx.solid(Color(0.38, 0.37, 0.4))
	part(n, box(0.7, 0.9, 0.18), stone, Vector3(0, 0.45, 0))
	part(n, cyl(0.35, 0.35, 0.18, 12), stone, Vector3(0, 0.9, 0), Vector3(90, 0, 0))
	part(n, box(0.08, 0.4, 0.04), Fx.solid(Color(0.2, 0.2, 0.22)), Vector3(0, 0.62, 0.1))
	part(n, box(0.28, 0.08, 0.04), Fx.solid(Color(0.2, 0.2, 0.22)), Vector3(0, 0.72, 0.1))
	part(n, box(1.0, 0.12, 0.6), Fx.solid(Color(0.22, 0.18, 0.12)), Vector3(0, 0.06, 0.1))
	return n

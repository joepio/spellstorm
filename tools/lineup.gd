extends SceneTree
## Renders monsters side by side on a plain floor, for judging their models:
## godot --path . --script tools/lineup.gd -- out.png ghoul,skeleton [yaw_deg] [pitch_deg] [dist]
## Run under xvfb (see tools/shot.sh); each is shown standing still, unanimated.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var kinds: PackedStringArray = args[1].split(",")
	var yaw := deg_to_rad(float(args[2]) if args.size() > 2 else 20.0)
	var pitch := deg_to_rad(float(args[3]) if args.size() > 3 else 35.0)
	var dist := float(args[4]) if args.size() > 4 else 3.2 + kinds.size() * 1.4
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.13, 0.15)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.52, 0.58)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(35), 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = OS.get_environment("NOSHADOW") == ""
	world.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.3, 0.3, 0.32)
	floor.material_override = fm
	world.add_child(floor)
	# Each stands in a slot as wide as it is big, so a boss does not crowd
	# out its neighbours.
	var widths: Array[float] = []
	var total := 0.0
	for k in kinds:
		var c: Dictionary = Enemy.KINDS[k]
		var w := 1.3 * float(c.size) + 0.5
		widths.append(w)
		total += w
	var x := -total * 0.5
	var shown: Array[Enemy] = []
	for i in kinds.size():
		var e := Enemy.new().setup(kinds[i], 1.0, false)
		e.position = Vector3(x + widths[i] * 0.5, 0, 0)
		x += widths[i]
		world.add_child(e)
		shown.append(e)
		e.set_physics_process(false)
		e.set_process(false)
	if args.size() <= 4:
		dist = 1.0 + total * 0.8
	var cam := Camera3D.new()
	world.add_child(cam)
	var look := Vector3(0, 0.9, 0)
	var at := look + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	# Not in the tree yet during _initialize, so no look_at.
	cam.transform = Transform3D(Basis.looking_at(look - at, Vector3.UP), at)
	cam.fov = 40.0
	cam.current = true
	# Noise textures are made on a thread: give them a moment.
	for i in 30:
		await process_frame
	# A burrower starts under the floor (in _ready): bring it up to be seen.
	for e in shown:
		if e._mound:
			e._mound.visible = false
			e._model.visible = true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	quit()

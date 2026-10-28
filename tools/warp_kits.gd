extends Node
## Exports the game's models for the Warp port (ontola/warp-game-engine,
## games/spellstorm): every monster, the wizard, each biome's props in a few
## variants, the wall rocks and the torches, as named node trees of meshes
## with their materials. The Warp sim places them; this only says how they
## look, so the two stay one game.
##   godot --headless --path . res://tools/warp_kits.tscn -- OUT_DIR
## (a scene, not --script, so the GameNight autoload is there).
## Writes OUT_DIR/kits.json, OUT_DIR/meshes.bin (little-endian f32/u32) and
## the noise textures as PNG. Triangles are written counter-clockwise
## (Warp's front face; Godot's is clockwise). Godot and Warp share axes.

const VARIANTS := 6

var dir := ""
var bin := StreamPeerBuffer.new()
var meshes := {}
var materials := {}
var textures := {}
var out := {"meshes": [], "materials": [], "textures": [], "kits": {}}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dir = args[0] if args.size() > 0 else "warp_kits"
	DirAccess.make_dir_recursive_absolute(dir)
	bin.big_endian = false
	var stage := Node3D.new()
	add_child(stage)
	# Monsters: the model as built, standing still.
	for k: String in Enemy.KINDS:
		var e := Enemy.new().setup(k, 1.0, false)
		stage.add_child(e)
		e.set_physics_process(false)
		e.set_process(false)
		var kit := _kit(e._model)
		kit["eyes"] = e._eyes.map(func(n: Node) -> int: return kit.index[n])
		kit["base_scale"] = e._base_scale.x
		out.kits["enemy/" + k] = _finish(kit)
		e.free()
	# The wizard; the app recolours the cloth by weave (see Art.wizard).
	var model: Dictionary = Art.wizard(Color(0.62, 0.12, 0.12))
	stage.add_child(model.root)
	var wk := _kit(model.root)
	var named := {}
	for key: String in model:
		if model[key] is Node and wk.index.has(model[key]):
			named[key] = wk.index[model[key]]
	wk["named"] = named
	out.kits["wizard"] = _finish(wk)
	model.root.free()
	# Each biome's props, a few looks of each, picked by the sim's seed.
	var arena := Arena.new()
	stage.add_child(arena)
	for b in Arena.BIOMES.size():
		var biome: Dictionary = Arena.BIOMES[b]
		arena.biome = biome
		var kinds := {}
		for list in ["props", "outside", "wall_props", "water_props"]:
			for k in biome.get(list, []):
				kinds[k] = true
		for zone in biome.zones:
			for k in zone:
				kinds[k] = true
		for k in ["pew", "urn", "oil_jar", "statue", "pillar", "sarcophagus", "blood_urn"]:
			kinds[k] = true
		for k: String in kinds:
			if k == "lantern":
				continue
			for v in VARIANTS:
				arena._rng.seed = v * 7919 + 13
				var body: Node3D = arena._prop(k, Vector3.ZERO, 0.0)
				if body == null:
					break
				body.transform = Transform3D.IDENTITY
				out.kits["prop/%s/%s/%d" % [biome.id, k, v]] = _finish(_kit(body))
				arena.props.erase(body)
				body.free()
		# Walls (Arena._band_walls' mats, by WallPiece.mat), the outer walls
		# (_walls: lit and dark) and the niche skull.
		var moss: float = biome.get("moss", 0.0)
		var moss_c: Color = biome.get("moss_c", Color(0.12, 0.16, 0.08))
		var mats := [Art.stone(biome.wall, moss, moss_c), Art.stone(biome.wall.darkened(0.3), moss, moss_c), Art.stone(biome.wall.darkened(0.75)), Arena._bone_mat()]
		var natural: bool = biome.get("wall_style", "masonry") in ["rock", "cliff"]
		if biome.get("wall_style", "") == "cliff":
			mats[0] = Art.stone(biome.wall.darkened(0.2), 0.0)
			mats[1] = Art.stone(biome.wall.darkened(0.45), 0.0)
		if natural:
			mats[2] = mats[1]
			mats[3] = mats[1]
		mats.append(Art.stone(biome.wall.darkened(0.35), moss, moss_c))
		out.kits["walls/%s" % biome.id] = {"materials": mats.map(func(m: Material) -> int: return _material(m))}
	for i in 6:
		for jag in [false, true]:
			out.kits["crag/%d/%d" % [i, int(jag)]] = {"mesh": _mesh(Arena._crag(i, jag))}
	out.kits["skull"] = {"mesh": _mesh(Arena._niche_skull())}
	out.kits["box"] = {"mesh": _mesh(Art.box(1, 1, 1))}
	var torch := Node3D.new()
	stage.add_child(torch)
	arena._torch(torch, Vector3.ZERO)
	out.kits["torch"] = _finish(_kit(torch))
	torch.free()
	arena._lamp(Vector2.ZERO, Vector2(1, 0))
	var lamp: Node3D = arena.get_child(arena.get_child_count() - 1)
	out.kits["lamp"] = _finish(_kit(lamp))
	var f := FileAccess.open(dir.path_join("meshes.bin"), FileAccess.WRITE)
	f.store_buffer(bin.data_array)
	f.close()
	f = FileAccess.open(dir.path_join("kits.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	print("WARP_KITS ", dir, " kits ", out.kits.size(), " meshes ", out.meshes.size(), " materials ", out.materials.size(), " textures ", out.textures.size())
	get_tree().quit()


## The tree under [param top] (its own transform left out): each node's
## parent, local transform and what it draws.
func _kit(top: Node3D) -> Dictionary:
	var kit := {"nodes": [], "index": {}}
	_walk(top, -1, kit, true)
	return kit


func _finish(kit: Dictionary) -> Dictionary:
	kit.erase("index")
	return kit


func _walk(n: Node, parent: int, kit: Dictionary, top := false) -> void:
	if not (n is Node3D):
		return
	var n3 := n as Node3D
	var d := {"name": String(n.name), "parent": parent, "xf": _xf(Transform3D.IDENTITY if top else n3.transform), "visible": n3.visible}
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			d.mesh = _mesh(mi.mesh)
			var mat := mi.material_override
			if mat == null and mi.mesh.get_surface_count() > 0:
				mat = mi.get_active_material(0)
			d.material = _material(mat)
			d.shadow = mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if n.get_script():
				d.script = (n.get_script() as Script).resource_path
	elif n is OmniLight3D:
		var l := n as OmniLight3D
		d.light = {"color": _c(l.light_color), "energy": l.light_energy, "range": l.omni_range, "attenuation": l.omni_attenuation, "shadow": l.shadow_enabled}
	elif n is CPUParticles3D:
		var p := n as CPUParticles3D
		var c := p.color
		if p.color_ramp:
			c = p.color_ramp.sample(0.0)
		var size := 0.3
		if p.mesh is QuadMesh:
			size = (p.mesh as QuadMesh).size.x
		d.particles = {"amount": p.amount, "lifetime": p.lifetime, "color": _c(c), "size": size, "direction": _v(p.direction),
			"spread": p.spread, "gravity": _v(p.gravity), "speed": [p.initial_velocity_min, p.initial_velocity_max],
			"sphere": p.emission_sphere_radius if p.emission_shape == CPUParticles3D.EMISSION_SHAPE_SPHERE else 0.0}
	var i: int = kit.nodes.size()
	kit.nodes.append(d)
	kit.index[n] = i
	for c in n.get_children():
		_walk(c, i, kit)


static func _xf(t: Transform3D) -> Array:
	return [t.basis.x.x, t.basis.x.y, t.basis.x.z, 0, t.basis.y.x, t.basis.y.y, t.basis.y.z, 0,
		t.basis.z.x, t.basis.z.y, t.basis.z.z, 0, t.origin.x, t.origin.y, t.origin.z, 1]


static func _c(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]


static func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _put_f32(a: PackedFloat32Array) -> Array:
	var at := bin.get_position()
	for x in a:
		bin.put_float(x)
	return [at, a.size()]


func _put_u32(a: PackedInt32Array) -> Array:
	var at := bin.get_position()
	for x in a:
		bin.put_u32(x)
	return [at, a.size()]


func _mesh(m: Mesh) -> int:
	var key := m.get_instance_id()
	if meshes.has(key):
		return meshes[key]
	var surfaces := []
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nor: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var col: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			for i in pos.size():
				idx.append(i)
		# Clockwise to counter-clockwise.
		for t in range(0, idx.size() - 2, 3):
			var b := idx[t + 1]
			idx[t + 1] = idx[t + 2]
			idx[t + 2] = b
		var fp := PackedFloat32Array()
		for p in pos:
			fp.append_array([p.x, p.y, p.z])
		var fn := PackedFloat32Array()
		for p in nor:
			fn.append_array([p.x, p.y, p.z])
		var fu := PackedFloat32Array()
		for p in uv:
			fu.append_array([p.x, p.y])
		var fc := PackedFloat32Array()
		for c in col:
			fc.append_array([c.r, c.g, c.b, c.a])
		var sd := {"positions": _put_f32(fp), "normals": _put_f32(fn), "uvs": _put_f32(fu), "colors": _put_f32(fc), "indices": _put_u32(idx)}
		var sm := m.surface_get_material(s)
		sd.material = _material(sm) if sm else -1
		surfaces.append(sd)
	var i: int = out.meshes.size()
	out.meshes.append({"type": m.get_class(), "surfaces": surfaces})
	meshes[key] = i
	return i


func _texture(t: Texture2D) -> int:
	if t == null:
		return -1
	var key: Variant = t.get_instance_id()
	if t is NoiseTexture2D:
		# Noise is kept as plain grey (the colour ramp goes with the
		# material), so materials that share a noise share one picture.
		var nt := t as NoiseTexture2D
		var n := nt.noise as FastNoiseLite
		key = "%d|%d|%f|%d|%f|%f|%d|%d|%s|%s|%f" % [n.seed, n.noise_type, n.frequency, n.fractal_octaves, n.fractal_gain, n.fractal_lacunarity,
			nt.width, nt.height, nt.seamless, nt.as_normal_map, nt.bump_strength]
	if textures.has(key):
		return textures[key]
	var img: Image = _noise_image(t as NoiseTexture2D) if t is NoiseTexture2D else t.get_image()
	if img == null:
		return -1
	if img.is_compressed():
		img.decompress()
	var i: int = out.textures.size()
	var file := "tex%03d.png" % i
	var d := {"file": file}
	if t is NoiseTexture2D:
		d.normal_map = (t as NoiseTexture2D).as_normal_map
		d.bump_strength = (t as NoiseTexture2D).bump_strength
		img.convert(Image.FORMAT_L8)
	if img.get_format() != Image.FORMAT_L8:
		img.convert(Image.FORMAT_RGBA8)
	img.save_png(dir.path_join(file))
	d.width = img.get_width()
	d.height = img.get_height()
	out.textures.append(d)
	textures[key] = i
	return i


static func _ramp(g: Gradient) -> Dictionary:
	var offsets := []
	var colors := []
	for i in g.get_point_count():
		offsets.append(g.get_offset(i))
		colors.append(_c(g.get_color(i)))
	return {"offsets": offsets, "colors": colors, "interpolation": g.interpolation_mode}


## The texture's picture made here and now, as NoiseTexture2D makes it
## (it makes its own on a worker thread, after this script has finished).
static func _noise_image(t: NoiseTexture2D) -> Image:
	var img: Image
	if t.seamless:
		img = t.noise.get_seamless_image(t.width, t.height, t.invert, t.in_3d_space, t.seamless_blend_skirt, t.normalize)
	else:
		img = t.noise.get_image(t.width, t.height, t.invert, t.in_3d_space, t.normalize)
	# A normal map stays its height field: the app derives the normal per
	# pixel as Image.bump_map_to_normal_map does, at bump_strength.
	return img


func _material(m: Material) -> int:
	if m == null:
		return -1
	var key := m.get_instance_id()
	if materials.has(key):
		return materials[key]
	var d := {"type": m.get_class()}
	if m is StandardMaterial3D:
		var s := m as StandardMaterial3D
		d.albedo = _c(s.albedo_color)
		d.roughness = s.roughness
		d.metallic = s.metallic
		d.emission = _c(s.emission) if s.emission_enabled else null
		d.emission_energy = s.emission_energy_multiplier
		d.unshaded = s.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		d.additive = s.blend_mode == BaseMaterial3D.BLEND_MODE_ADD
		d.transparent = s.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
		d.two_sided = s.cull_mode == BaseMaterial3D.CULL_DISABLED
		d.vertex_color = s.vertex_color_use_as_albedo
		d.vertex_color_srgb = s.vertex_color_is_srgb
		d.triplanar = s.uv1_triplanar
		d.uv1_scale = _v(s.uv1_scale)
		d.billboard = s.billboard_mode
		d.rim = s.rim if s.rim_enabled else 0.0
		d.albedo_texture = _texture(s.albedo_texture)
		if s.albedo_texture is NoiseTexture2D and (s.albedo_texture as NoiseTexture2D).color_ramp:
			d.albedo_ramp = _ramp((s.albedo_texture as NoiseTexture2D).color_ramp)
		d.normal_texture = _texture(s.normal_texture) if s.normal_enabled else -1
		d.normal_scale = s.normal_scale
	elif m is ShaderMaterial:
		var sh := m as ShaderMaterial
		d.shader = sh.shader.resource_path.get_file().get_basename() if sh.shader else ""
		var params := {}
		if sh.shader:
			for u in sh.shader.get_shader_uniform_list():
				var v = sh.get_shader_parameter(u.name)
				if v is Color:
					params[u.name] = _c(v)
				elif v is Vector2:
					params[u.name] = [v.x, v.y]
				elif v is Vector3:
					params[u.name] = _v(v)
				elif v is Vector4:
					params[u.name] = [v.x, v.y, v.z, v.w]
				elif v is float or v is int or v is bool:
					params[u.name] = v
				elif v is Texture2D:
					params[u.name] = {"texture": _texture(v)}
		d.params = params
	var i: int = out.materials.size()
	out.materials.append(d)
	materials[key] = i
	return i

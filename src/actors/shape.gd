class_name Shape
## Smooth meshes built in code for monster models (the playbook's "Make 3D
## models" way: no Blender, no CSG to bake). A limb is a tube through a few
## points with its own thickness at each, rounded at both ends; a blob is a
## lumpy sphere; a lathe turns a side profile round the up axis, with folds;
## a sheet is a flat double-sided polygon, for wings and fins.


## A tube through [param pts] with radius [param radii] at each point,
## rounded off at both ends. The path is smoothed through the points with
## [param sub] rings per stretch between two of them, so a bend is a curve
## and a swelling (a muscle, a knuckle) is round, not a ridge.
static func limb(pts: PackedVector3Array, radii: PackedFloat32Array, seg := 8, sub := 3) -> ArrayMesh:
	if sub > 1 and pts.size() > 2:
		var sp := PackedVector3Array()
		var sr := PackedFloat32Array()
		var m := pts.size()
		for i in m - 1:
			var p0 := pts[maxi(i - 1, 0)]
			var r0 := radii[maxi(i - 1, 0)]
			var p3 := pts[mini(i + 2, m - 1)]
			var r3 := radii[mini(i + 2, m - 1)]
			for k in sub:
				var t := float(k) / sub
				sp.append(pts[i].cubic_interpolate(pts[i + 1], p0, p3, t))
				sr.append(maxf(0.0, cubic_interpolate(radii[i], radii[i + 1], r0, r3, t)))
		sp.append(pts[m - 1])
		sr.append(radii[m - 1])
		pts = sp
		radii = sr
	var n := pts.size()
	# The frame carried along the path so the rings never twist.
	var tangents: Array[Vector3] = []
	for i in n:
		var a := pts[maxi(0, i - 1)]
		var b := pts[mini(n - 1, i + 1)]
		tangents.append((b - a).normalized())
	var side := tangents[0].cross(Vector3.UP)
	if side.length() < 0.1:
		side = tangents[0].cross(Vector3.RIGHT)
	side = side.normalized()
	var rings: Array = []
	# Rounded start: a few shrinking rings behind the first point (thin
	# tubes just come to a point).
	var caps := 3 if seg >= 8 else 1
	for c in range(caps, 0, -1):
		var ang := float(c) / caps * PI * 0.5
		rings.append([pts[0] - tangents[0] * radii[0] * sin(ang), radii[0] * cos(ang), tangents[0], side])
	for i in n:
		var t := tangents[i]
		side = (side - t * side.dot(t)).normalized()
		rings.append([pts[i], radii[i], t, side])
	for c in range(1, caps + 1):
		var ang := float(c) / caps * PI * 0.5
		rings.append([pts[n - 1] + tangents[n - 1] * radii[n - 1] * sin(ang), radii[n - 1] * cos(ang), tangents[n - 1], side])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for ri in rings.size():
		var r: Array = rings[ri]
		var up: Vector3 = (r[2] as Vector3).cross(r[3]).normalized()
		for s in seg:
			var a := TAU * s / seg
			st.set_uv(Vector2(float(s) / seg, float(ri) / rings.size()))
			st.add_vertex(r[0] + (r[3] * cos(a) + up * sin(a)) * maxf(r[1], 0.001))
	for i in rings.size() - 1:
		for s in seg:
			var a := i * seg + s
			var b := i * seg + (s + 1) % seg
			var c := a + seg
			var d := b + seg
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	st.generate_normals()
	return st.commit()


## A sphere of radii [param r] pushed in and out by [param lumps] (0 is
## smooth), the same for the same [param seed].
static func blob(r: Vector3, lumps := 0.1, seed := 1.0, rings := 10, seg := 14) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i in rings + 1:
		var v := PI * i / rings
		for s in seg + 1:
			var u := TAU * s / seg
			var d := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			var k := 1.0 + lumps * (sin(d.x * 5.1 + seed) * sin(d.y * 4.3 + seed * 1.7) + 0.5 * sin(d.z * 7.7 + seed * 2.3))
			st.set_uv(Vector2(float(s) / seg, float(i) / rings))
			st.add_vertex(Vector3(d.x * r.x, d.y * r.y, d.z * r.z) * k)
	for i in rings:
		for s in seg:
			var a := i * (seg + 1) + s
			var b := a + 1
			var c := a + seg + 1
			var d := c + 1
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	st.generate_normals()
	return st.commit()


## A surface of revolution: [param profile] is (radius, height) pairs from
## the bottom up. [param folds] waves the radius round the axis that many
## times, [param fold_depth] deep, deeper towards the bottom (cloth hangs).
## [param open_front] leaves that much of the circle (radians) open at +z,
## for a hood's face.
static func lathe(profile: PackedVector2Array, seg := 20, folds := 0, fold_depth := 0.0, open_front := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var top := profile[profile.size() - 1].y
	var bottom := profile[0].y
	var span := maxf(top - bottom, 0.001)
	var cols := seg + 1
	for p in profile:
		var hang := 1.0 - (p.y - bottom) / span
		for s in cols:
			# Starts and ends at the front opening, if any.
			var a := open_front * 0.5 + (TAU - open_front) * s / seg + PI * 0.5
			var r := p.x * (1.0 + fold_depth * hang * sin(a * folds))
			st.set_uv(Vector2(float(s) / seg, hang))
			st.add_vertex(Vector3(cos(a) * r, p.y, sin(a) * r))
	# Seen through the opening, the inside is a second skin a little in.
	var skins := 2 if open_front > 0.0 else 1
	if skins == 2:
		for p in profile:
			var hang := 1.0 - (p.y - bottom) / span
			for s in cols:
				var a := open_front * 0.5 + (TAU - open_front) * s / seg + PI * 0.5
				var r := p.x * 0.93 * (1.0 + fold_depth * hang * sin(a * folds))
				st.set_uv(Vector2(float(s) / seg, hang))
				st.add_vertex(Vector3(cos(a) * r, p.y, sin(a) * r))
	var per := profile.size() * cols
	for k in skins:
		for i in profile.size() - 1:
			for s in seg:
				var a := k * per + i * cols + s
				var b := a + 1
				var c := a + cols
				var d := c + 1
				for idx in ([a, b, c, b, d, c] if k == 0 else [a, c, b, b, c, d]):
					st.add_index(idx)
	st.generate_normals()
	return st.commit()


## A flat polygon seen from both sides, fanned from its first point.
static func sheet(pts: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, pts.size() - 1):
		for p in [pts[0], pts[i], pts[i + 1], pts[0], pts[i + 1], pts[i]]:
			st.set_uv(Vector2(p.x, p.y))
			st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Points along a quadratic curve from [param a] to [param c], pulled
## towards [param b]: for bones, horns, tails.
static func curve(a: Vector3, b: Vector3, c: Vector3, n := 6) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in n:
		var t := float(i) / (n - 1)
		out.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	return out


## [param n] radii running evenly from [param from] to [param to].
static func taper(from: float, to: float, n := 6) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in n:
		out.append(lerpf(from, to, float(i) / maxf(n - 1, 1)))
	return out


## [param mesh] with every point moved by [param f] (Vector3 -> Vector3),
## its shading worked out again: bend, squash or dent a shape after making it.
static func warp(mesh: ArrayMesh, f: Callable) -> ArrayMesh:
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i] = f.call(v[i])
	arr[Mesh.ARRAY_VERTEX] = v
	return _rebuild(arr)


## [param mesh] mirrored left to right, for the other arm or leg.
static func mirror(mesh: ArrayMesh) -> ArrayMesh:
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i].x = -v[i].x
	arr[Mesh.ARRAY_VERTEX] = v
	# Mirroring turns every triangle inside out: turn them back.
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for i in range(0, idx.size(), 3):
		var t := idx[i + 1]
		idx[i + 1] = idx[i + 2]
		idx[i + 2] = t
	arr[Mesh.ARRAY_INDEX] = idx
	return _rebuild(arr)


## Several shapes as one mesh, so ten ribs are still one part (one draw,
## one piece of debris).
static func merge(parts: Array) -> ArrayMesh:
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	for m: ArrayMesh in parts:
		var arr := _indexed(m)
		var base := v.size()
		var mv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		v.append_array(mv)
		uv.append_array(arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else _zeros2(mv.size()))
		col.append_array(arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else _whites(mv.size()))
		for i: int in arr[Mesh.ARRAY_INDEX]:
			idx.append(base + i)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = v
	out[Mesh.ARRAY_TEX_UV] = uv
	out[Mesh.ARRAY_COLOR] = col
	out[Mesh.ARRAY_INDEX] = idx
	return _rebuild(out, false)


## Colours [param mesh]'s points with [param f] (point, normal -> Color),
## multiplied into its material: darker underneath and towards the feet,
## grime in the hollows, so a part looks lit from above and sits on the floor.
## Colours already on the points (a [method tint]) are kept, multiplied in.
static func shade(mesh: ArrayMesh, f: Callable) -> ArrayMesh:
	var arr := _indexed(mesh)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var old = arr[Mesh.ARRAY_COLOR]
	var col := PackedColorArray()
	col.resize(v.size())
	for i in v.size():
		col[i] = f.call(v[i], n[i])
		if old != null:
			col[i] *= (old as PackedColorArray)[i]
	arr[Mesh.ARRAY_COLOR] = col
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out


## [param mesh] darkened to [param c] all over, so a darker bit (claws,
## nails, a stain) can be merged into a part of the same material.
static func tint(mesh: ArrayMesh, c: Color) -> ArrayMesh:
	return shade(mesh, func(_p: Vector3, _n: Vector3) -> Color: return c)


## The usual shading: from [param low] at the floor up to full at
## [param top] metres, and a little darker where the surface faces down.
## [param under] tints the undersides (frost on top, blue cold beneath).
static func ground(mesh: ArrayMesh, top: float, low := 0.45, under := Color.WHITE) -> ArrayMesh:
	return shade(mesh, func(p: Vector3, nrm: Vector3) -> Color:
		var k := lerpf(low, 1.0, clampf(p.y / top, 0.0, 1.0))
		var up := nrm.y * 0.5 + 0.5
		k *= 0.78 + 0.22 * up
		return Color.WHITE.lerp(under, 1.0 - smoothstep(0.55, 0.95, up)) * k)


## [param mesh] moved so its middle is at the origin, and where that middle
## was: [mesh, Vector3]. A part placed there tumbles round its own centre
## when it is thrown as debris, and comes to rest on the floor.
static func centered(mesh: ArrayMesh) -> Array:
	var c := mesh.get_aabb().get_center()
	var arr := _indexed(mesh)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i] -= c
	arr[Mesh.ARRAY_VERTEX] = v
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return [out, c]


static func _indexed(m: ArrayMesh) -> Array:
	var arr := m.surface_get_arrays(0)
	if arr[Mesh.ARRAY_INDEX] == null:
		var idx := PackedInt32Array()
		for i in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
			idx.append(i)
		arr[Mesh.ARRAY_INDEX] = idx
	return arr


static func _zeros2(n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(n)
	return out


static func _whites(n: int) -> PackedColorArray:
	var out := PackedColorArray()
	out.resize(n)
	out.fill(Color.WHITE)
	return out


## Fresh smooth normals for [param arr] (points in the same place share
## one, so seams do not show) and a mesh from it.
static func _rebuild(arr: Array, keep_index := true) -> ArrayMesh:
	if arr[Mesh.ARRAY_INDEX] == null:
		var idx0 := PackedInt32Array()
		for i in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
			idx0.append(i)
		arr[Mesh.ARRAY_INDEX] = idx0
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var face := PackedVector3Array()
	face.resize(v.size())
	for i in range(0, idx.size(), 3):
		var a := v[idx[i]]
		# Godot's front faces wind clockwise.
		var fn := (v[idx[i + 2]] - a).cross(v[idx[i + 1]] - a)
		face[idx[i]] += fn
		face[idx[i + 1]] += fn
		face[idx[i + 2]] += fn
	# Points in the same place share a normal, unless they face apart (the
	# two sides of a sheet).
	var weld := {}
	for i in v.size():
		var k := v[i].snapped(Vector3.ONE * 0.0005)
		if weld.has(k):
			weld[k].append(i)
		else:
			weld[k] = [i]
	var n := PackedVector3Array()
	n.resize(v.size())
	for i in v.size():
		var s := Vector3.ZERO
		for j: int in weld[v[i].snapped(Vector3.ONE * 0.0005)]:
			if j == i or face[j].dot(face[i]) > 0.0:
				s += face[j]
		n[i] = s.normalized() if s.length_squared() > 0.0 else Vector3.UP
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TANGENT] = null
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out


static var _mats := {}


## A rough surface for skin, bone, cloth or iron: [param base] mottled
## towards [param dark] by noise and given a bumpy normal map, mapped from
## all three sides so no UVs are needed. [param scale] is how many noise
## tiles per metre, [param bump] how rough it feels. Shared per recipe.
static func material(base: Color, dark: Color, scale := 2.0, rough := 0.85, bump := 0.6, metal := 0.0, seed := 1) -> StandardMaterial3D:
	var key := "%s%s%.2f%.2f%.2f%.2f%d" % [base.to_html(), dark.to_html(), scale, rough, bump, metal, seed]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.01
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.55
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	# Mostly the base colour, sinking to dark in the low spots: grime and
	# bruising in patches, a few lighter worn places.
	var ramp := Gradient.new()
	ramp.set_color(0, dark)
	ramp.set_offset(0, 0.1)
	ramp.set_color(1, base.lightened(0.06))
	ramp.set_offset(1, 0.85)
	ramp.add_point(0.38, dark.lerp(base, 0.6))
	ramp.add_point(0.55, base)
	tex.color_ramp = ramp
	m.albedo_texture = tex
	var bumps := FastNoiseLite.new()
	bumps.seed = seed + 7
	bumps.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	bumps.frequency = 0.03
	bumps.fractal_octaves = 3
	var ntex := NoiseTexture2D.new()
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 3.0
	ntex.noise = bumps
	m.normal_enabled = true
	m.normal_texture = ntex
	m.normal_scale = bump
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 2.0
	m.uv1_scale = Vector3.ONE * scale
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mats[key] = m
	return m


## A plain colour that still takes the parts' shading (vertex colours).
static func flat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "f%s%.2f%.2f" % [c.to_html(), rough, metal]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.vertex_color_use_as_albedo = true
	_mats[key] = m
	return m


## Ice, crystal or wet glassy stuff: smooth, glinting, lit a little from
## inside by [param glow].
static func glassy(c: Color, glow := 0.4) -> StandardMaterial3D:
	var key := "g%s%.2f" % [c.to_html(), glow]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.12
	m.metallic = 0.2
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = glow
	m.rim_enabled = true
	m.rim = 0.6
	m.vertex_color_use_as_albedo = true
	_mats[key] = m
	return m


## A box with rounded edges and corners, [param half] its half size;
## [param round] from 0 (nearly sharp) to 1 (an ellipsoid). For plates,
## planks, shields, slabs of stone.
static func slab(half: Vector3, round := 0.3, rings := 8, seg := 12) -> ArrayMesh:
	var e := clampf(round, 0.05, 1.0)
	return warp(blob(Vector3.ONE, 0.0, 1.0, rings, seg), func(p: Vector3) -> Vector3:
		return Vector3(signf(p.x) * pow(absf(p.x), e) * half.x, signf(p.y) * pow(absf(p.y), e) * half.y, signf(p.z) * pow(absf(p.z), e) * half.z))

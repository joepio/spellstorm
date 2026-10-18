class_name Arena
extends Node3D
## One level of a biome: floor, walls, props, torches and the fields on the
## ground. A level is a big stretch of land (Joep: no rooms, a real level to
## walk through): a winding path from the entrance at the front (+z) through
## three zones that each look a little different, past clearings where the
## fights gather and tomes wait on shrines, to the boss's arena near the
## back and the gate behind it.

## Half the level's width and length.
var half := Vector2(34.0, 105.0)
const LEVEL_HALF := Vector2(34.0, 105.0)

const BIOMES := [
	{id = "chapel", zones = [["grave", "grave", "grave", "dead_tree", "rock", "urn", "coffin"], ["grave", "candles", "dead_tree", "bones", "urn", "oil_jar", "statue"], ["dead_tree", "dead_tree", "rock", "grave", "coffin", "oil_jar"]], name = "The Forsaken Chapel", floor_a = Color(0.15, 0.16, 0.12), floor_b = Color(0.08, 0.09, 0.07), tiles = 0.0,
		wall = Color(0.24, 0.23, 0.22), fog = Color(0.08, 0.1, 0.12), ambient = Color(0.25, 0.3, 0.4), moon = Color(0.45, 0.55, 0.75), moon_energy = 0.35,
		props = ["grave", "grave", "grave", "dead_tree", "rock", "candles"], enemies = {ghoul = 3, skeleton = 3, watcher = 2, bone_archer = 2, necromancer = 1}, boss = "gravekeeper", fields = [],
		path_style = 0, path_a = Color(0.24, 0.2, 0.14), path_b = Color(0.14, 0.11, 0.08), layout = "nave",
		corridor = true, outside = ["dead_tree", "dead_tree", "dead_tree", "grave", "rock"]},
	{id = "catacombs", zones = [["bones", "candles", "sarcophagus", "pillar"], ["sarcophagus", "bones", "candles"], ["sarcophagus", "sarcophagus", "bones", "pillar"]], name = "The Catacombs", floor_a = Color(0.2, 0.18, 0.16), floor_b = Color(0.12, 0.11, 0.1), tiles = 1.0,
		wall = Color(0.26, 0.22, 0.2), fog = Color(0.07, 0.05, 0.04), ambient = Color(0.3, 0.22, 0.16), moon = Color(0.6, 0.45, 0.35), moon_energy = 0.12,
		props = ["pillar", "pillar", "bones", "candles", "sarcophagus"], enemies = {skeleton = 3, cultist = 2, bile = 1, watcher = 1, bone_archer = 2, necromancer = 1, shieldbearer = 2}, boss = "abbot", fields = [],
		path_style = 2, path_a = Color(0.2, 0.035, 0.03), path_b = Color(0.12, 0.025, 0.02), layout = "nave"},
	{id = "isles", zones = [["reeds", "reeds", "rock", "dead_tree"], ["reeds", "reeds", "lantern", "rock"], ["dead_tree", "dead_tree", "reeds", "rock"]], name = "The Sunken Isles", floor_a = Color(0.13, 0.16, 0.09), floor_b = Color(0.07, 0.09, 0.05), tiles = 0.0,
		wall = Color(0.2, 0.24, 0.22), fog = Color(0.05, 0.09, 0.1), ambient = Color(0.22, 0.32, 0.36), moon = Color(0.5, 0.7, 0.8), moon_energy = 0.4,
		props = ["reeds", "reeds", "reeds", "rock", "dead_tree", "lantern"], enemies = {drowned = 3, watcher = 1, bile = 1, wraith = 1, toad = 3, sprite = 3}, boss = "drowned_king", fields = [],
		path_style = 0, path_a = Color(0.19, 0.15, 0.1), path_b = Color(0.11, 0.09, 0.06), isles = true, low_walls = true},
	{id = "caves", zones = [["stalagmite", "stalagmite", "rock"], ["mushroom", "mushroom", "stalagmite", "rock"], ["stalagmite", "rock", "rock", "mushroom"]], name = "The Drowned Caves", floor_a = Color(0.12, 0.14, 0.15), floor_b = Color(0.06, 0.08, 0.09), tiles = 0.0, wet = 1.0,
		wall = Color(0.18, 0.2, 0.21), fog = Color(0.03, 0.07, 0.08), ambient = Color(0.15, 0.3, 0.32), moon = Color(0.3, 0.6, 0.6), moon_energy = 0.15,
		props = ["stalagmite", "stalagmite", "mushroom", "mushroom", "rock"], enemies = {drowned = 2, bile = 2, ghoul = 2, lurker = 3, toad = 1, sprite = 2}, boss = "drowned_king", fields = [El.WATER, El.WATER, El.WATER, El.WATER],
		path_style = 1, path_a = Color(0.24, 0.27, 0.27), path_b = Color(0.13, 0.15, 0.16)},
	{id = "keep", zones = [["ice", "ice", "rock"], ["pillar", "ice", "rock"], ["ice", "rock", "rock", "pillar"]], name = "The Frozen Keep", floor_a = Color(0.26, 0.29, 0.34), floor_b = Color(0.15, 0.17, 0.21), tiles = 1.0,
		wall = Color(0.35, 0.38, 0.45), fog = Color(0.12, 0.15, 0.2), ambient = Color(0.25, 0.32, 0.42), moon = Color(0.55, 0.7, 0.95), moon_energy = 0.3,
		props = ["ice", "ice", "pillar", "rock"], enemies = {wraith = 2, skeleton = 2, frost_brute = 1, ghoul = 1, shieldbearer = 2, necromancer = 1, bone_archer = 2}, boss = "warden", fields = [El.FROST, El.FROST, El.FROST],
		path_style = 1, path_a = Color(0.28, 0.3, 0.34), path_b = Color(0.17, 0.19, 0.23), layout = "nave"},
	{id = "pit", zones = [["basalt", "basalt", "bones"], ["brazier", "basalt", "bones"], ["basalt", "basalt", "brazier", "bones"]], name = "The Infernal Pit", floor_a = Color(0.13, 0.08, 0.07), floor_b = Color(0.05, 0.03, 0.03), tiles = 0.0,
		wall = Color(0.15, 0.1, 0.09), fog = Color(0.12, 0.03, 0.01), ambient = Color(0.4, 0.15, 0.08), moon = Color(1.0, 0.4, 0.2), moon_energy = 0.2,
		props = ["basalt", "basalt", "brazier", "bones"], enemies = {imp = 3, demon = 1, cultist = 2, brute = 1, hellhound = 2, lurker = 1}, boss = "pit_lord", fields = [El.MAGMA, El.MAGMA, El.MAGMA],
		path_style = 3, path_a = Color(0.1, 0.08, 0.08), path_b = Color(0.05, 0.04, 0.04)},
]

var biome: Dictionary
## The way through the level, from the entrance (front) to the gate at the
## back, as points about every 2.5 m in xz, and how far along it each point
## is (path_run). Props keep off it.
var path := PackedVector2Array()
var path_run := PackedFloat32Array()
const PATH_W := 2.4
## Open ground along the path where the fights gather, as (x, z, r): the
## first two hold shrines with tomes once their monsters are beaten, the last
## is the boss's arena.
var clearings: Array[Vector3] = []
## How far along the path each clearing is.
var clearing_at: Array[float] = []
## Where the wizards come in, and where the portal opens after the boss.
var start := Vector2.ZERO
var portal_at := Vector2.ZERO
## Islands in a water biome, as (x, z, rx, rz) ellipses; empty elsewhere.
var isles: Array[Vector4] = []
## Laid stone floors (x, z, r) in a built biome: the clearings and the arena.
var plazas: Array[Vector3] = []
## In a built biome the middle zone is a straight nave between these two
## path distances, lined with rows (graves, pillars, coffins).
var nave := Vector2(-1, -1)
var fields: Array = []
## The props that break, see src/world/prop.gd.
var props: Array = []
## A level that follows its path (a biome with "corridor"): the ground you can
## walk is a band round the path, wider where it opens into the clearings,
## walled along both sides instead of one big rectangle. Kept as a signed
## distance by 1 m cell: negative inside, positive beyond the walls.
var corridor := false
var _sdf := PackedFloat32Array()
var _sdf_o := Vector2.ZERO
var _sdf_w := 0
var _sdf_h := 0
## Half the band's width at each point of the path.
var _hw := PackedFloat32Array()
## Points just inside the walls and the way into the level from there
## (x, z, nx, nz), for monsters that come in over the walls.
var _rim: Array[Vector4] = []
var _torches: Array = []
var _rng := RandomNumberGenerator.new()
## Where props stand, by 3 m cell, so finding free ground stays quick on a
## big level.
var _props_at := {}
## Coarse distance to the path, by 2 m cell.
var _near_path := {}


func build(biome_index: int, seed_value: int) -> void:
	for c in get_children():
		c.queue_free()
	fields.clear()
	props.clear()
	_rim.clear()
	_sdf = PackedFloat32Array()
	_torches.clear()
	_props_at.clear()
	_near_path.clear()
	biome = BIOMES[biome_index % BIOMES.size()]
	_rng.seed = seed_value
	half = LEVEL_HALF
	corridor = biome.get("corridor", false)
	_plan()
	_index_path()
	if corridor:
		_band()
	_floor()
	if corridor:
		_band_walls()
		_outside()
	else:
		_walls()
	_path_dressing()
	_arena_ring()
	if built():
		_nave_props()
	# The rest of the land: thick with the zone's things, so the level reads
	# as ground you cross along a way, not an empty field.
	var count := int(half.x * half.y * 4.0 / 34.0)
	if corridor:
		count = int(_inside_area() / 24.0)
	for i in count:
		var spot := _free_spot(2.6)
		if spot == Vector3.INF:
			continue
		var zone_props: Array = biome.zones[zone_at(spot)]
		_prop(zone_props[_rng.randi() % zone_props.size()], spot)
	for _r in int(half.y / 9.0):
		for k in biome.fields:
			var fp := _free_spot(3.0)
			if fp == Vector3.INF:
				continue
			var f := add_field(fp, k, _rng.randf_range(1.6, 3.0), 0.0, null)
			f.permanent = true
	_dust()


func built() -> bool:
	return biome.get("layout", "") == "nave"


## Which of the three zones [param at] is in, by how far along the path it is.
func zone_at(at: Vector3) -> int:
	var k := progress_of(Vector2(at.x, at.z)) / path_run[path_run.size() - 1]
	return clampi(int(k * 3.0), 0, 2)


## Lay out the path, its clearings and the boss arena, and in a water biome
## the islands it hops between.
func _plan() -> void:
	clearings.clear()
	clearing_at.clear()
	isles.clear()
	plazas.clear()
	nave = Vector2(-1, -1)
	start = Vector2(_rng.randf_range(-6.0, 6.0), half.y - 7.0)
	var arena := Vector3(0, -half.y + 24.0, 14.0)
	portal_at = Vector2(arena.x, arena.y - 6.0)
	# Bends every 12 to 24 m, mostly swinging to the other side, sometimes
	# wide and sometimes barely, now and then drifting on along the same
	# side; two of them are clearings, and in a built biome the way between
	# those runs straight.
	var keys := PackedVector2Array([Vector2(start.x, half.y + 1.5), start])
	var reach := half.x - 9.0
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var z := start.y - 16.0
	var marks: Array[Vector2] = []
	var last_x := start.x
	var straight := false
	while z > arena.y + 22.0:
		var x := side * _rng.randf_range(reach * 0.15, reach)
		if straight:
			# A long straight stretch now and then, between the bends.
			x = clampf(last_x + _rng.randf_range(-1.5, 1.5), -reach, reach)
		elif absf(x - last_x) < 6.0:
			x = clampf(last_x + side * 8.0, -reach, reach)
		marks.append(Vector2(x, z))
		last_x = x
		if _rng.randf() < 0.75:
			side = -side
		straight = corridor and not straight and _rng.randf() < 0.35
		z -= _rng.randf_range(20.0, 28.0) if straight else _rng.randf_range(12.0, 24.0)
	var c1 := int(marks.size() * 0.3)
	var c2 := int(marks.size() * 0.68)
	for i in marks.size():
		var m := marks[i]
		if built() and i > c1 and i < c2:
			# The nave: straight on from the first clearing.
			m.x = marks[c1].x
		keys.append(m)
		if i == c1 or i == c2:
			clearings.append(Vector3(m.x, m.y, _rng.randf_range(8.0, 9.5)))
	if built():
		marks[c2].x = marks[c1].x
	keys.append(Vector2(arena.x, arena.y + arena.z + 3.0))
	keys.append(Vector2(arena.x, arena.y))
	keys.append(portal_at)
	keys.append(Vector2(0, -half.y - 1.0))
	clearings.append(arena)
	path = _smooth(keys, 7)
	if built():
		for c in clearings:
			plazas.append(Vector3(c.x, c.y, c.z + 1.0))
	if not biome.get("isles", false):
		return
	# Where you start, every clearing and every bend is dry land; bridges
	# cross the water between them.
	isles.append(Vector4(start.x, start.y, 8.0, 5.0))
	for c in clearings:
		isles.append(Vector4(c.x, c.y, c.z + 1.5, c.z + 0.5))
	for m in marks:
		isles.append(Vector4(m.x, m.y, _rng.randf_range(3.0, 4.5), _rng.randf_range(2.6, 3.6)))
	for _i in 30:
		var c := Vector2(_rng.randf_range(-half.x + 4, half.x - 4), _rng.randf_range(-half.y + 4, half.y - 4))
		var clear := true
		for e in isles:
			if c.distance_to(Vector2(e.x, e.y)) < maxf(e.z, e.w) + 4.0:
				clear = false
		if clear:
			isles.append(Vector4(c.x, c.y, _rng.randf_range(2.0, 4.0), _rng.randf_range(1.8, 3.2)))


## Distances along the path, where the clearings sit on it, and a coarse
## map of how far each bit of ground is from it.
func _index_path() -> void:
	path_run = PackedFloat32Array()
	var run := 0.0
	for i in path.size():
		if i > 0:
			run += path[i].distance_to(path[i - 1])
		path_run.append(run)
	for c in clearings:
		clearing_at.append(progress_of(Vector2(c.x, c.y)))
	if built() and clearing_at.size() >= 2:
		nave = Vector2(clearing_at[0] + 9.0, clearing_at[1] - 9.0)
	var x := -half.x
	while x <= half.x:
		var z := -half.y
		while z <= half.y:
			_near_path[Vector2i(int(floor(x / 2.0)), int(floor(z / 2.0)))] = path_dist(Vector2(x + 1.0, z + 1.0))
			z += 2.0
		x += 2.0


## How wide the band round the path is along it, then its distance field.
func _band() -> void:
	_hw = PackedFloat32Array()
	var knots: Array[float] = []
	for _k in int(length() / 20.0) + 3:
		knots.append(_rng.randf_range(5.0, 9.0))
	for i in path.size():
		var run := path_run[i]
		var f := run / 20.0
		var j := int(f)
		var t := f - j
		t = t * t * (3.0 - 2.0 * t)
		var w := lerpf(knots[j], knots[j + 1], t)
		if nave.x >= 0.0 and run > nave.x - 6.0 and run < nave.y + 6.0:
			w = 13.5
		# The way out narrows to the gate.
		w = lerpf(w, 2.3, clampf((portal_at.y - 3.0 - path[i].y) / 5.0, 0.0, 1.0))
		_hw.append(w)
	var pad := 16.0
	_sdf_o = Vector2(-half.x - pad, -half.y - pad)
	_sdf_w = int((half.x + pad) * 2.0) + 1
	_sdf_h = int((half.y + pad) * 2.0) + 1
	_sdf.resize(_sdf_w * _sdf_h)
	_sdf.fill(30.0)
	for i in path.size() - 1:
		_raster_seg(path[i], path[i + 1], _hw[i], _hw[i + 1])
	_raster_seg(start, start, 7.0, 7.0)
	for c in clearings:
		var cc := Vector2(c.x, c.y)
		_raster_seg(cc, cc, c.z + 3.0, c.z + 3.0)
	# Ragged walls: the edge wanders a little, and the level ends at the
	# entrance and behind the gate.
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = 0.08
	for iz in _sdf_h:
		for ix in _sdf_w:
			var q := _sdf_o + Vector2(ix, iz)
			var i2 := iz * _sdf_w + ix
			var d := _sdf[i2] + noise.get_noise_2d(q.x, q.y) * 1.6
			d = maxf(d, q.y - (half.y + 0.6))
			d = maxf(d, -q.y - (half.y + 0.6))
			_sdf[i2] = d


## Write the distance to a stretch of path a-b, [param wa] to [param wb]
## wide on each side, into the field where it is nearer than what is there.
func _raster_seg(a: Vector2, b: Vector2, wa: float, wb: float) -> void:
	var reach := maxf(wa, wb) + 8.0
	var x0 := maxi(0, int(minf(a.x, b.x) - reach - _sdf_o.x))
	var x1 := mini(_sdf_w - 1, int(maxf(a.x, b.x) + reach - _sdf_o.x) + 1)
	var z0 := maxi(0, int(minf(a.y, b.y) - reach - _sdf_o.y))
	var z1 := mini(_sdf_h - 1, int(maxf(a.y, b.y) + reach - _sdf_o.y) + 1)
	var ab := b - a
	var l2 := maxf(ab.length_squared(), 0.0001)
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var q := _sdf_o + Vector2(ix, iz)
			var t := clampf((q - a).dot(ab) / l2, 0.0, 1.0)
			var d := q.distance_to(a + ab * t) - lerpf(wa, wb, t)
			var i := iz * _sdf_w + ix
			if d < _sdf[i]:
				_sdf[i] = d


## How far [param p] (xz) is outside the walkable ground: negative inside.
## Always inside in a level without a band.
func bound(p: Vector2) -> float:
	if _sdf.is_empty():
		return -INF
	var f := p - _sdf_o
	var x := clampf(f.x, 0.0, _sdf_w - 1.001)
	var z := clampf(f.y, 0.0, _sdf_h - 1.001)
	var ix := int(x)
	var iz := int(z)
	var tx := x - ix
	var tz := z - iz
	var i := iz * _sdf_w + ix
	return lerpf(lerpf(_sdf[i], _sdf[i + 1], tx), lerpf(_sdf[i + _sdf_w], _sdf[i + _sdf_w + 1], tx), tz)


## The way out of the walkable ground at [param p].
func _bound_out(p: Vector2) -> Vector2:
	var g := Vector2(bound(p + Vector2(0.5, 0)) - bound(p - Vector2(0.5, 0)), bound(p + Vector2(0, 0.5)) - bound(p - Vector2(0, 0.5)))
	return g.normalized() if g.length() > 0.0001 else Vector2.UP


func _inside_area() -> float:
	var n := 0
	for v in _sdf:
		if v < 0.0:
			n += 1
	return float(n)


## Half the band's width [param run] metres along the path.
func _hw_at(run: float) -> float:
	if _hw.is_empty():
		return 9.0
	for i in path.size() - 1:
		if path_run[i + 1] >= run:
			return lerpf(_hw[i], _hw[i + 1], clampf((run - path_run[i]) / maxf(path_run[i + 1] - path_run[i], 0.001), 0.0, 1.0))
	return _hw[_hw.size() - 1]


## Walls along the edge of the band: masonry blocks set on the line where
## the distance field crosses zero, low where they face the camera so they
## never hide a wizard, tall with torches elsewhere.
func _band_walls() -> void:
	var pts: Array[Vector2] = []
	var taken := {}
	for iz in _sdf_h - 1:
		for ix in _sdf_w - 1:
			var i := iz * _sdf_w + ix
			var v := _sdf[i]
			for nb: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var w := _sdf[i + nb.x + nb.y * _sdf_w]
				if (v < 0.0) == (w < 0.0):
					continue
				var t := v / (v - w)
				var q := _sdf_o + Vector2(ix + nb.x * t, iz + nb.y * t)
				var key := Vector2i(int(floor(q.x / 1.4)), int(floor(q.y / 1.4)))
				if taken.has(key):
					continue
				var near := false
				for dx in range(-1, 2):
					for dz in range(-1, 2):
						var o: Variant = taken.get(key + Vector2i(dx, dz))
						if o != null and (o as Vector2).distance_to(q) < 1.25:
							near = true
				if near:
					continue
				taken[key] = q
				pts.append(q)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	var tools := {}
	var lit := Fx.solid(biome.wall, 0.95)
	var dark := Fx.solid(biome.wall.darkened(0.35), 0.95)
	var shapes := {}
	var last_torch: Array[Vector2] = []
	for q in pts:
		var out := _bound_out(q)
		# The gate fills the gap at the far end.
		if q.y < -half.y + 1.5 and absf(q.x - portal_at.x) < 2.6:
			continue
		var face := smoothstep(0.25, 0.8, out.y)
		var h := lerpf(2.9, 0.7, face) * _rng.randf_range(0.75, 1.12)
		if _rng.randf() < 0.12:
			# Crumbled down to a stump here and there.
			h *= 0.45
		var size := Vector3(snappedf(_rng.randf_range(1.5, 1.8), 0.1), snappedf(h, 0.1), 1.1)
		var basis := Basis(Vector3.UP, atan2(out.x, out.y))
		var at := Vector3(q.x + out.x * 0.5, size.y * 0.5, q.y + out.y * 0.5)
		var ck := Vector2i(int(floor(q.x / 20.0)), int(floor(q.y / 20.0)))
		var which := 0 if _rng.randf() < 0.7 else 1
		var tk := Vector3i(ck.x, ck.y, which)
		if not tools.has(tk):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[tk] = st
		(tools[tk] as SurfaceTool).append_from(Prop._box(size), 0, Transform3D(basis, at))
		if size.y > 1.5:
			# A coping stone along the top.
			var cap := Vector3(size.x + 0.1, 0.16, size.z + 0.16)
			var ck2 := Vector3i(ck.x, ck.y, 1 - which)
			if not tools.has(ck2):
				var st2 := SurfaceTool.new()
				st2.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[ck2] = st2
			(tools[ck2] as SurfaceTool).append_from(Prop._box(cap), 0, Transform3D(basis, at + Vector3(0, size.y * 0.5 + 0.08, 0)))
		var sk := "%.1f,%.1f" % [size.x, size.y]
		if not shapes.has(sk):
			var bs := BoxShape3D.new()
			bs.size = Vector3(size.x, 4.0, size.z)
			shapes[sk] = bs
		var cs := CollisionShape3D.new()
		cs.shape = shapes[sk]
		cs.transform = Transform3D(basis, Vector3(at.x, 2.0, at.z))
		body.add_child(cs)
		_rim.append(Vector4(q.x - out.x * 1.4, q.y - out.y * 1.4, -out.x, -out.y))
		if size.y > 2.5:
			var far := true
			for o in last_torch:
				if o.distance_to(q) < 13.0:
					far = false
			if far:
				last_torch.append(q)
				_torch(self, Vector3(q.x - out.x * 0.15, 2.2, q.y - out.y * 0.15))
	for tk: Vector3i in tools:
		var m := MeshInstance3D.new()
		m.mesh = (tools[tk] as SurfaceTool).commit()
		m.material_override = lit if tk.z == 0 else dark
		add_child(m)


## Beyond the walls: dark ground thick with the biome's things, so the edge
## of the level reads as land you cannot reach, not as the end of the world.
func _outside() -> void:
	var kinds: Array = biome.get("outside", ["rock"])
	var n := 0
	for _i in 900:
		if n >= 170:
			break
		var p := Vector2(_rng.randf_range(-half.x - 12.0, half.x + 12.0), _rng.randf_range(-half.y, half.y + 6.0))
		var d := bound(p)
		if d < 1.8 or d > 11.0:
			continue
		var body := _prop(kinds[_rng.randi() % kinds.size()], Vector3(p.x, 0, p.y))
		if body:
			body.collision_layer = 0
			props.erase(body)
		n += 1


## A Catmull-Rom curve through [param keys], [param steps] points per span,
## so the path bends like a trodden way instead of in straight lengths.
static func _smooth(keys: PackedVector2Array, steps: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in keys.size() - 1:
		var p0 := keys[maxi(i - 1, 0)]
		var p1 := keys[i]
		var p2 := keys[i + 1]
		var p3 := keys[mini(i + 2, keys.size() - 1)]
		for k in steps:
			var t := float(k) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(keys[keys.size() - 1])
	return out


## How far [param p] (xz) is from the path.
func path_dist(p: Vector2) -> float:
	return _line_dist(path, p)


static func _line_dist(line: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


## How far along the path the point of it nearest [param p] is.
func progress_of(p: Vector2) -> float:
	var best := INF
	var at := 0.0
	for i in path.size() - 1:
		var a := path[i]
		var ab := path[i + 1] - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			at = path_run[i] + t * ab.length()
	return at


## The point [param run] metres along the path.
func point_at(run: float) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	for i in path.size() - 1:
		if path_run[i + 1] >= run:
			var span := path_run[i + 1] - path_run[i]
			return path[i].lerp(path[i + 1], clampf((run - path_run[i]) / maxf(span, 0.001), 0.0, 1.0))
	return path[path.size() - 1]


func length() -> float:
	return path_run[path_run.size() - 1] if not path_run.is_empty() else 0.0


func in_clearing(p: Vector2, pad := 0.0) -> bool:
	for c in clearings:
		if p.distance_to(Vector2(c.x, c.y)) < c.z + pad:
			return true
	return false


## The boss's arena is ringed by the biome's tall things, with a gap where
## the path comes in and one where it leaves.
func _arena_ring() -> void:
	var a: Vector3 = clearings[clearings.size() - 1]
	var kind: String = {"chapel": "pillar", "catacombs": "pillar", "keep": "pillar", "caves": "stalagmite", "pit": "basalt", "isles": "rock"}.get(biome.id, "rock")
	var n := 18
	for i in n:
		var ang := TAU * i / n
		var at := Vector2(a.x + cos(ang) * (a.z + 1.2), a.y + sin(ang) * (a.z + 1.2))
		if path_dist(at) < PATH_W + 1.0:
			continue
		_prop(kind, Vector3(at.x, 0, at.y), 0.0)


## Props in the nave stand in order along the straight way: graves in rows,
## pillars lining it, coffins side by side.
func _nave_props() -> void:
	if nave.x < 0.0 or nave.y <= nave.x:
		return
	var a := point_at(nave.x)
	var b := point_at(nave.y)
	var x0 := a.x
	var z := minf(a.y, b.y)
	var z_end := maxf(a.y, b.y)
	match biome.id:
		"chapel":
			# The ruined chapel's nave: pews in rows either side of the aisle,
			# some knocked askew, angels along the walls, and urns and oil jars
			# left between them.
			var zs := z
			while z < z_end:
				for x: float in [3.2, 6.0]:
					for sgn: float in [-1.0, 1.0]:
						if _rng.randf() < 0.8:
							_prop("pew", Vector3(x0 + sgn * (x + 0.4) + _rng.randf_range(-0.2, 0.2), 0, z), PI + _rng.randf_range(-0.15, 0.15) + (0.6 if _rng.randf() < 0.12 else 0.0))
				if _rng.randf() < 0.45:
					var sgn2 := 1.0 if _rng.randf() < 0.5 else -1.0
					_prop("urn" if _rng.randf() < 0.6 else "oil_jar", Vector3(x0 + sgn2 * _rng.randf_range(8.6, 10.0), 0, z + 1.2))
				z += 2.2
			while zs < z_end:
				for sgn: float in [-1.0, 1.0]:
					_prop("statue", Vector3(x0 + sgn * 11.4, 0, zs + 1.0), -PI * 0.5 * sgn)
				zs += 9.0
		"catacombs":
			var zp := z
			while zp < z_end:
				for sgn: float in [-1.0, 1.0]:
					_prop("pillar", Vector3(x0 + sgn * 2.9, 0, zp), 0.0)
				zp += 3.4
			while z < z_end:
				for x: float in [7.0, 10.0]:
					for sgn: float in [-1.0, 1.0]:
						if _rng.randf() < 0.7:
							_prop("sarcophagus", Vector3(x0 + sgn * x, 0, z), 0.0)
				z += 3.2
		_:
			while z < z_end:
				for sgn: float in [-1.0, 1.0]:
					_prop("pillar", Vector3(x0 + sgn * 3.1, 0, z), 0.0)
				z += 4.0


## Signed distance to the nearest island shore, negative on land (without
## the shader's ragged edge). Very large when the level has no water.
func shore(p: Vector2) -> float:
	if isles.is_empty():
		return -INF
	var d := INF
	for e in isles:
		var q := Vector2((p.x - e.x) / e.z, (p.y - e.y) / e.w)
		d = minf(d, (q.length() - 1.0) * minf(e.z, e.w))
	return d


## Whether someone at [param at] stands in open water: off every island and
## off the bridges. Wading slows you down and keeps you wet.
func in_water(at: Vector3) -> bool:
	if isles.is_empty():
		return false
	var p := Vector2(at.x, at.z)
	return shore(p) > 0.15 and path_dist(p) > PATH_W * 0.5


## Posts along the bridges, low stones and lanterns along the path, and an
## open gate in the back wall where the path leaves the level.
func _path_dressing() -> void:
	_next_post = 0.0
	_next_lamp = 3.0
	var run := 0.0
	for i in path.size() - 1:
		_dress_span(path[i], path[i + 1], run)
		run += path[i].distance_to(path[i + 1])
	_gate()


var _next_post := 0.0
var _next_lamp := 3.0


## Dress one straight span of the path, [param run] metres along it.
func _dress_span(a: Vector2, b: Vector2, run: float) -> void:
	var wood := Fx.solid(Color(0.2, 0.14, 0.09))
	var stone := Fx.solid(biome.wall.darkened(0.1), 0.95)
	var built: bool = biome.get("layout", "") == "nave"
	var len := a.distance_to(b)
	var dir := (b - a) / len
	var nrm := Vector2(-dir.y, dir.x)
	var t := 0.0
	while t < len:
		var c := a + dir * t
		var at := run + t
		var inside := absf(c.x) < half.x - 0.5 and absf(c.y) < half.y - 0.5
		if inside and at >= _next_post:
			if not isles.is_empty() and shore(c) > 0.1:
				# Posts along a bridge.
				_next_post = at + 1.6
				for sgn: float in [-1.0, 1.0]:
					var q: Vector2 = c + nrm * sgn * (PATH_W * 0.5 - 0.1)
					Art.part(self, Art.cyl(0.07, 0.09, 0.9, 6), wood, Vector3(q.x, 0.2, q.y))
			elif isles.is_empty() and not built:
				# Kerb stones along a trodden way, some missing.
				_next_post = at + 1.1
				for sgn: float in [-1.0, 1.0]:
					var q2: Vector2 = c + nrm * sgn * (PATH_W * 0.5 + 0.15)
					if _rng.randf() < 0.55 and path_dist(q2) > PATH_W * 0.5:
						Art.part(self, Art.box(0.32, 0.12, 0.24), stone, Vector3(q2.x, 0.06, q2.y), Vector3(0, _rng.randf() * 60.0, 0))
		if inside and at >= _next_lamp and (isles.is_empty() or shore(c) < -0.5) and not in_clearing(c, 1.0):
			if built:
				# Lanterns in pairs, both sides of the aisle.
				_next_lamp = at + 11.0
				for sgn: float in [-1.0, 1.0]:
					_lamp(c + nrm * sgn * (PATH_W * 0.5 + 0.5), -nrm * sgn)
			else:
				_next_lamp = at + 15.0
				var sgn2 := 1.0 if _rng.randf() < 0.5 else -1.0
				_lamp(c + nrm * sgn2 * (PATH_W * 0.5 + 0.6), -nrm * sgn2)
		t += 0.25


## A post with a hanging lantern beside the path.
func _lamp(at: Vector2, toward := Vector2.ZERO) -> void:
	var n := Node3D.new()
	n.position = Vector3(at.x, 0, at.y)
	# The arm reaches out over the path.
	if toward != Vector2.ZERO:
		n.rotation.y = atan2(-toward.y, toward.x)
	add_child(n)
	var iron := Fx.solid(Color(0.12, 0.11, 0.1), 0.6)
	Art.part(n, Art.cyl(0.05, 0.07, 1.8, 6), iron, Vector3(0, 0.9, 0))
	Art.part(n, Art.box(0.5, 0.05, 0.05), iron, Vector3(0.22, 1.78, 0))
	Art.part(n, Art.box(0.18, 0.24, 0.18), Fx.glow(Color(1.0, 0.75, 0.4), 3.0), Vector3(0.42, 1.6, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.7, 0.4)
	l.light_energy = 1.4
	l.omni_range = 6.0
	l.position = Vector3(0.42, 1.5, 0)
	n.add_child(l)
	_torches.append(l)
	_mark(Vector3(at.x, 0, at.y))


## An open archway in the back wall where the path leads out.
func _gate() -> void:
	var stone := Fx.solid(biome.wall.lightened(0.05), 0.95)
	var z := -half.y - 0.6
	for sgn: float in [-1.0, 1.0]:
		Art.part(self, Art.box(0.9, 4.2, 1.5), stone, Vector3(sgn * 1.7, 2.1, z))
	Art.part(self, Art.box(4.3, 0.7, 1.5), stone, Vector3(0, 4.3, z))
	var block := StaticBody3D.new()
	block.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.6, 4.0, 1.2)
	cs.shape = bs
	cs.position = Vector3(0, 2.0, z)
	block.add_child(cs)
	add_child(block)
	# Darkness beyond the arch.
	Art.part(self, Art.box(2.5, 3.9, 0.2), Fx.solid(Color(0.01, 0.01, 0.015), 1.0), Vector3(0, 1.95, z - 0.5))


## How the ground shifts from zone to zone along the level, as tints on
## the biome's floor colours (a biome can give its own as "tints").
const ZONE_TINTS := [Color(1.0, 1.0, 1.0), Color(0.82, 0.92, 0.8), Color(1.08, 0.93, 0.88)]


func _floor() -> void:
	var shader := preload("res://src/world/floor.gdshader")
	var tints: Array = biome.get("tints", ZONE_TINTS)
	var zone_z := Vector2(point_at(length() / 3.0).y, point_at(length() * 2.0 / 3.0).y)
	# The floor is cut into chunks: each gets its own nearby torches (the
	# compatibility renderer lights each mesh with a few lights only), and
	# only the bits of path, islands and stone floors that cross it, so the
	# shader stays cheap however long the level is.
	var chunk := 10.0
	var reach := PATH_W + 1.0
	var tex: ImageTexture
	if corridor:
		var img := Image.create(_sdf_w, _sdf_h, false, Image.FORMAT_L8)
		for iz in _sdf_h:
			for ix in _sdf_w:
				var v := clampf(_sdf[iz * _sdf_w + ix] / 16.0 + 0.5, 0.0, 1.0)
				img.set_pixel(ix, iz, Color(v, v, v))
		tex = ImageTexture.create_from_image(img)
	var x := -half.x - 5.0 - (12.0 if corridor else 0.0)
	while x < half.x + 5.0 + (12.0 if corridor else 0.0):
		var z := -half.y - 5.0
		while z < half.y + 8.0:
			var lo := Vector2(x, z)
			var hi := lo + Vector2(chunk, chunk)
			if corridor and bound(lo + Vector2(chunk, chunk) * 0.5) > 7.1 + 11.0:
				# Nothing here to see: deep beyond the walls.
				z += chunk
				continue
			var mat := ShaderMaterial.new()
			if corridor:
				mat.set_shader_parameter("bounds", tex)
				mat.set_shader_parameter("bounds_rect", Vector4(_sdf_o.x - 0.5, _sdf_o.y - 0.5, _sdf_w, _sdf_h))
				mat.set_shader_parameter("bounded", true)
			mat.shader = shader
			mat.set_shader_parameter("base_a", biome.floor_a)
			mat.set_shader_parameter("base_b", biome.floor_b)
			mat.set_shader_parameter("tiles", biome.tiles)
			mat.set_shader_parameter("half_size", half)
			mat.set_shader_parameter("wet", biome.get("wet", 0.0))
			mat.set_shader_parameter("path_w", PATH_W)
			mat.set_shader_parameter("path_style", biome.get("path_style", 0))
			mat.set_shader_parameter("path_a", biome.get("path_a", Color(0.3, 0.25, 0.18)))
			mat.set_shader_parameter("path_b", biome.get("path_b", Color(0.17, 0.14, 0.1)))
			mat.set_shader_parameter("zone_z", zone_z)
			for k in 3:
				mat.set_shader_parameter("tint%d" % k, tints[k])
			var segs := PackedVector4Array()
			var runs := PackedFloat32Array()
			for i in path.size() - 1:
				var a := path[i]
				var b := path[i + 1]
				if minf(a.x, b.x) - reach < hi.x and maxf(a.x, b.x) + reach > lo.x and minf(a.y, b.y) - reach < hi.y and maxf(a.y, b.y) + reach > lo.y and segs.size() < 32:
					segs.append(Vector4(a.x, a.y, b.x, b.y))
					runs.append(path_run[i])
			mat.set_shader_parameter("segs", segs)
			mat.set_shader_parameter("seg_run", runs)
			mat.set_shader_parameter("seg_n", segs.size())
			var iv := PackedVector4Array()
			for e in isles:
				# Far enough out to see the water deepen away from every shore.
				if e.x - e.z - 7.0 < hi.x and e.x + e.z + 7.0 > lo.x and e.y - e.w - 7.0 < hi.y and e.y + e.w + 7.0 > lo.y and iv.size() < 16:
					iv.append(e)
			mat.set_shader_parameter("isles", iv)
			mat.set_shader_parameter("isle_n", iv.size())
			mat.set_shader_parameter("water", not isles.is_empty())
			var pv := PackedVector3Array()
			for c in plazas:
				if c.x - c.z - 1.0 < hi.x and c.x + c.z + 1.0 > lo.x and c.y - c.z - 1.0 < hi.y and c.y + c.z + 1.0 > lo.y and pv.size() < 4:
					pv.append(c)
			mat.set_shader_parameter("plazas", pv)
			mat.set_shader_parameter("plaza_n", pv.size())
			var m := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(chunk, chunk)
			m.mesh = pm
			m.material_override = mat
			m.position = Vector3(x + chunk * 0.5, 0, z + chunk * 0.5)
			add_child(m)
			z += chunk
		x += chunk
	var ground := StaticBody3D.new()
	ground.collision_layer = 4
	var cs := CollisionShape3D.new()
	var b2 := BoxShape3D.new()
	b2.size = Vector3(half.x * 2.0 + 20.0, 1, half.y * 2.0 + 20.0)
	cs.shape = b2
	cs.position.y = -0.5
	ground.add_child(cs)
	add_child(ground)


func _walls() -> void:
	var mat := Fx.solid(biome.wall, 0.95)
	var dark := Fx.solid(biome.wall.darkened(0.35), 0.95)
	# Back and sides are tall; the wall nearest the camera is low so it never
	# hides a wizard. Out on the water the sides are a low, broken sea wall.
	var low: bool = biome.get("low_walls", false)
	var segs := [
		[Vector3(-(half.x + 1.2 + 1.25) * 0.5, 0, -half.y - 0.6), Vector3(half.x + 1.2 - 1.25, 3.4, 1.2)],
		[Vector3((half.x + 1.2 + 1.25) * 0.5, 0, -half.y - 0.6), Vector3(half.x + 1.2 - 1.25, 3.4, 1.2)],
		[Vector3(-half.x - 0.6, 0, 0), Vector3(1.2, 1.1 if low else 3.0, half.y * 2 + 2.4)],
		[Vector3(half.x + 0.6, 0, 0), Vector3(1.2, 1.1 if low else 3.0, half.y * 2 + 2.4)],
		[Vector3(0, 0, half.y + 0.6), Vector3(half.x * 2 + 2.4, 0.7, 1.2)],
	]
	for s in segs:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(s[1].x, 4.0, s[1].z)
		cs.shape = bs
		cs.position.y = 2.0
		body.add_child(cs)
		body.position = s[0]
		add_child(body)
		var h: float = s[1].y
		# Built from blocks of uneven height so it reads as masonry.
		var along_x: bool = s[1].x > s[1].z
		var length: float = s[1].x if along_x else s[1].z
		var n := int(length / 1.6)
		for i in n:
			var off := -length * 0.5 + (i + 0.5) * length / n
			var bh := h * _rng.randf_range(0.85, 1.1)
			var size := Vector3(length / n - 0.06, bh, s[1].z) if along_x else Vector3(s[1].x, bh, length / n - 0.06)
			var pos := Vector3(off, bh * 0.5, 0) if along_x else Vector3(0, bh * 0.5, off)
			Art.part(body, Art.box(size.x, size.y, size.z), mat if i % 3 else dark, pos)
		if h > 2.0:
			var tn := int(length / 14.0)
			for i in tn:
				var off2 := -length * 0.5 + (i + 0.5) * length / tn
				var inward := Vector3(0, 0, -signf(s[0].z) * 0.75) if along_x else Vector3(-signf(s[0].x) * 0.75, 0, 0)
				var tp: Vector3 = (Vector3(off2, 2.2, 0) if along_x else Vector3(0, 2.2, off2)) + inward
				_torch(body, tp)


func _torch(parent: Node3D, at: Vector3) -> void:
	var t := Node3D.new()
	t.position = at
	parent.add_child(t)
	Art.part(t, Art.cyl(0.05, 0.03, 0.5, 6), Fx.solid(Color(0.2, 0.15, 0.1)), Vector3(0, -0.2, 0))
	Art.part(t, Art.sphere(0.1, 6), Fx.glow(Color(1.0, 0.6, 0.2), 4.0), Vector3(0, 0.1, 0))
	var f := Fx.particles(Color(1.0, 0.5, 0.15), 14, 0.5, 0.3)
	f.direction = Vector3.UP
	f.gravity = Vector3.UP * 2.0
	f.initial_velocity_min = 0.2
	f.initial_velocity_max = 0.6
	f.position.y = 0.15
	t.add_child(f)
	f.emitting = true
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.25)
	l.light_energy = 2.2
	l.omni_range = 11.0
	l.omni_attenuation = 1.1
	l.position.y = 0.3
	t.add_child(l)
	_torches.append(l)


func _free_spot(clear: float) -> Vector3:
	for _i in 40:
		var p := Vector3(_rng.randf_range(-half.x + 2, half.x - 2), 0, _rng.randf_range(-half.y + 2, half.y - 2))
		if corridor:
			# Somewhere in the band: along the path, out to either side.
			var run := _rng.randf_range(0.0, length())
			var c := point_at(run)
			var dir := (point_at(run + 1.0) - point_at(run - 1.0)).normalized()
			var off := Vector2(-dir.y, dir.x) * _rng.randf_range(-1.0, 1.0) * (_hw_at(run) + 4.0)
			p = Vector3(c.x + off.x, 0, c.y + off.y)
			if bound(Vector2(p.x, p.z)) > -1.2:
				continue
		var p2 := Vector2(p.x, p.z)
		if p2.distance_to(start) < 7.0 or in_clearing(p2, 1.0):
			continue
		if _off_path(p2) < PATH_W * 0.5 + 1.0:
			continue
		if not isles.is_empty() and shore(p2) > -0.8:
			continue
		if _crowded(p, clear):
			continue
		_mark(p)
		return p
	return Vector3.INF


## About how far [param p] is from the path: the coarse map when that is
## clearly far enough, the exact distance near the edge.
func _off_path(p: Vector2) -> float:
	var coarse: float = _near_path.get(Vector2i(int(floor(p.x / 2.0)), int(floor(p.y / 2.0))), INF)
	if coarse > PATH_W + 3.0:
		return coarse
	return path_dist(p)


func _cell(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / 3.0)), int(floor(p.z / 3.0)))


func _mark(p: Vector3) -> void:
	var c := _cell(p)
	if not _props_at.has(c):
		_props_at[c] = []
	_props_at[c].append(p)


func _crowded(p: Vector3, clear: float) -> bool:
	var c := _cell(p)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q: Vector3 in _props_at.get(c + Vector2i(dx, dz), []):
				if p.distance_to(q) < clear:
					return true
	return false


## A prop of [param kind] at a free spot, or at [param at] facing
## [param yaw] when a layout places it.
func _prop(kind: String, at := Vector3.INF, yaw := INF) -> Prop:
	var p := at if at != Vector3.INF else _free_spot(2.6)
	if p == Vector3.INF:
		return null
	if at != Vector3.INF:
		_mark(at)
	var body := Prop.new()
	body.kind = kind
	body.hp = PROP_HP.get(kind, 8.0)
	body.collision_layer = 1
	body.position = p
	body.rotation.y = yaw if yaw != INF else _rng.randf() * TAU
	add_child(body)
	var r := 0.4
	var stone := Fx.solid(biome.wall.lightened(0.1), 0.95)
	match kind:
		"grave":
			var g := Art.tombstone()
			g.scale = Vector3.ONE * _rng.randf_range(0.8, 1.2)
			g.rotation.z = _rng.randf_range(-0.15, 0.15)
			body.add_child(g)
			r = 0.4
		"dead_tree":
			var bark := Fx.solid(Color(0.13, 0.1, 0.08))
			Art.part(body, Art.cyl(0.1, 0.22, 2.6, 7), bark, Vector3(0, 1.3, 0), Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-6, 6)))
			for i in 4:
				Art.part(body, Art.cyl(0.02, 0.08, 1.3, 5), bark, Vector3(0, 1.6 + i * 0.3, 0), Vector3(_rng.randf_range(35, 65), i * 95.0, 0)).translate_object_local(Vector3(0, 0.6, 0))
			r = 0.35
		"rock":
			Art.part(body, Art.sphere(0.8, 6), stone, Vector3(0, 0.3, 0), Vector3(_rng.randf() * 40, 0, 0), Vector3(1.2, 0.7, 1.0))
			r = 0.8
		"candles":
			for i in 5:
				var cp := Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5))
				var h := _rng.randf_range(0.15, 0.45)
				Art.part(body, Art.cyl(0.04, 0.04, h, 6), Fx.solid(Color(0.85, 0.8, 0.65)), cp + Vector3(0, h * 0.5, 0))
				Art.part(body, Art.sphere(0.03, 4), Fx.glow(Color(1, 0.7, 0.3), 5.0), cp + Vector3(0, h + 0.04, 0))
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.65, 0.35)
			l.light_energy = 0.9
			l.omni_range = 4.0
			l.position.y = 0.5
			body.add_child(l)
			_torches.append(l)
			body.collision_layer = 0
			return body
		"pillar":
			Art.part(body, Art.cyl(0.45, 0.45, 3.2, 8), stone, Vector3(0, 1.6, 0))
			Art.part(body, Art.box(1.1, 0.3, 1.1), stone, Vector3(0, 0.15, 0))
			Art.part(body, Art.box(1.1, 0.3, 1.1), stone, Vector3(0, 3.1, 0))
			r = 0.55
		"bones":
			var bone := Fx.solid(Color(0.75, 0.72, 0.62))
			for i in 6:
				Art.part(body, Art.cyl(0.03, 0.03, 0.5, 5), bone, Vector3(_rng.randf_range(-0.4, 0.4), 0.04, _rng.randf_range(-0.4, 0.4)), Vector3(90, _rng.randf() * 180, 0))
			Art.part(body, Art.sphere(0.12, 6), bone, Vector3(0.1, 0.1, 0.1))
			body.collision_layer = 0
			return body
		"sarcophagus":
			Art.part(body, Art.box(1.0, 0.8, 2.2), stone, Vector3(0, 0.4, 0))
			Art.part(body, Art.box(1.1, 0.15, 2.3), stone.duplicate(), Vector3(0, 0.85, 0))
			r = 0.9
		"stalagmite":
			var h2 := _rng.randf_range(1.2, 2.8)
			Art.part(body, Art.cyl(0.0, 0.5, h2, 6), stone, Vector3(0, h2 * 0.5, 0))
			Art.part(body, Art.cyl(0.0, 0.3, h2 * 0.6, 6), stone, Vector3(0.45, h2 * 0.3, 0.2))
			r = 0.55
		"mushroom":
			var c := Color(0.2, 0.9, 0.75) if _rng.randf() < 0.5 else Color(0.6, 0.35, 1.0)
			for i in 3:
				var mp := Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4))
				var mh := _rng.randf_range(0.2, 0.6)
				Art.part(body, Art.cyl(0.04, 0.06, mh, 6), Fx.solid(Color(0.7, 0.7, 0.6)), mp + Vector3(0, mh * 0.5, 0))
				Art.part(body, Art.sphere(0.18, 8), Fx.glow(c, 1.5), mp + Vector3(0, mh, 0), Vector3.ZERO, Vector3(1, 0.45, 1))
			var l2 := OmniLight3D.new()
			l2.light_color = c
			l2.light_energy = 0.8
			l2.omni_range = 3.5
			l2.position.y = 0.6
			body.add_child(l2)
			body.collision_layer = 0
			return body
		"ice":
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.6, 0.85, 1.0, 0.75)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = Color(0.2, 0.4, 0.6)
			for i in 4:
				var ih := _rng.randf_range(0.8, 2.2)
				Art.part(body, Art.cyl(0.0, 0.25, ih, 5), m, Vector3(_rng.randf_range(-0.3, 0.3), ih * 0.4, _rng.randf_range(-0.3, 0.3)), Vector3(_rng.randf_range(-25, 25), 0, _rng.randf_range(-25, 25)))
			r = 0.5
		"reeds":
			var reed := Fx.solid(Color(0.35, 0.4, 0.2))
			for i in 9:
				var rp := Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6))
				var rh := _rng.randf_range(0.6, 1.4)
				Art.part(body, Art.cyl(0.0, 0.03, rh, 4), reed, rp + Vector3(0, rh * 0.5, 0), Vector3(_rng.randf_range(-12, 12), 0, _rng.randf_range(-12, 12)))
				if i % 3 == 0:
					Art.part(body, Art.cyl(0.04, 0.04, 0.22, 5), Fx.solid(Color(0.3, 0.18, 0.1)), rp + Vector3(0, rh * 0.8, 0))
			body.collision_layer = 0
			return body
		"lantern":
			body.queue_free()
			_lamp(Vector2(p.x, p.z))
			return null
		"basalt":
			var bm := Fx.solid(Color(0.09, 0.07, 0.07), 0.8)
			for i in 3:
				var bh := _rng.randf_range(0.8, 2.4)
				Art.part(body, Art.cyl(0.3, 0.32, bh, 6), bm, Vector3(_rng.randf_range(-0.35, 0.35), bh * 0.5, _rng.randf_range(-0.35, 0.35)))
			r = 0.6
		"brazier":
			Art.part(body, Art.cyl(0.1, 0.25, 0.9, 8), Fx.solid(Color(0.2, 0.18, 0.16), 0.5), Vector3(0, 0.45, 0))
			Art.part(body, Art.cyl(0.45, 0.25, 0.3, 10), Fx.solid(Color(0.25, 0.2, 0.18), 0.5), Vector3(0, 1.0, 0))
			var fl := Fx.particles(Color(1.0, 0.45, 0.1), 30, 0.7, 0.5)
			fl.direction = Vector3.UP
			fl.gravity = Vector3.UP * 2.5
			fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			fl.emission_sphere_radius = 0.3
			fl.position.y = 1.15
			body.add_child(fl)
			fl.emitting = true
			var l3 := OmniLight3D.new()
			l3.light_color = Color(1.0, 0.5, 0.2)
			l3.light_energy = 2.0
			l3.omni_range = 7.0
			l3.position.y = 1.6
			body.add_child(l3)
			_torches.append(l3)
			r = 0.5
		"urn":
			# A clay urn with a faint blue light in its mouth: mana inside.
			var clay := Fx.solid(Color(0.42, 0.26, 0.17), 0.9)
			Art.part(body, Art.cyl(0.2, 0.15, 0.45, 9), clay, Vector3(0, 0.22, 0))
			Art.part(body, Art.cyl(0.12, 0.2, 0.18, 9), clay, Vector3(0, 0.52, 0))
			Art.part(body, Art.cyl(0.08, 0.08, 0.02, 8), Fx.glow(Soul.COLOR, 2.0), Vector3(0, 0.62, 0))
			body.spill = "souls"
			r = 0.3
		"oil_jar":
			# A squat jar of lamp oil, red-banded: breaking it sets the ground
			# alight and blasts what stands beside it.
			var jar := Fx.solid(Color(0.24, 0.16, 0.1), 0.6)
			Art.part(body, Art.cyl(0.28, 0.24, 0.6, 10), jar, Vector3(0, 0.3, 0))
			Art.part(body, Art.cyl(0.29, 0.29, 0.1, 10), Fx.solid(Color(0.55, 0.1, 0.05), 0.6), Vector3(0, 0.42, 0))
			Art.part(body, Art.cyl(0.1, 0.14, 0.12, 8), jar, Vector3(0, 0.66, 0))
			body.spill = "fire"
			r = 0.35
		"coffin":
			var wood := Fx.solid(Color(0.2, 0.13, 0.08), 0.85)
			Art.part(body, Art.box(0.7, 0.4, 1.9), wood, Vector3(0, 0.2, 0))
			Art.part(body, Art.box(0.76, 0.08, 1.96), Fx.solid(Color(0.15, 0.1, 0.06), 0.85), Vector3(0.06, 0.44, -0.05), Vector3(0, 6, 0))
			body.spill = "souls"
			r = 0.6
		"statue":
			# A weeping angel on a plinth.
			var marble := Fx.solid(Color(0.46, 0.46, 0.48), 0.8)
			Art.part(body, Art.box(1.0, 0.6, 1.0), stone, Vector3(0, 0.3, 0))
			Art.part(body, Art.cyl(0.18, 0.34, 1.4, 8), marble, Vector3(0, 1.3, 0))
			Art.part(body, Art.sphere(0.17, 8), marble, Vector3(0, 2.15, 0.04))
			for sgn: float in [-1.0, 1.0]:
				Art.part(body, Art.box(0.08, 1.1, 0.5), marble, Vector3(sgn * 0.3, 1.6, -0.22), Vector3(-15, sgn * 25, sgn * 18))
			r = 0.55
		"pew":
			var oak := Fx.solid(Color(0.24, 0.15, 0.09), 0.8)
			Art.part(body, Art.box(2.4, 0.08, 0.45), oak, Vector3(0, 0.45, 0))
			Art.part(body, Art.box(2.4, 0.55, 0.07), oak, Vector3(0, 0.75, -0.22), Vector3(-8, 0, 0))
			for sgn: float in [-1.0, 1.0]:
				Art.part(body, Art.box(0.08, 0.9, 0.5), oak, Vector3(sgn * 1.16, 0.45, -0.02))
			r = 0.0
	var cs := CollisionShape3D.new()
	if kind == "pew":
		var bs := BoxShape3D.new()
		bs.size = Vector3(2.4, 3.0, 0.55)
		cs.shape = bs
	else:
		var cyl := CylinderShape3D.new()
		cyl.radius = r
		cyl.height = 3.0
		cs.shape = cyl
	cs.position.y = 1.5
	body.add_child(cs)
	body.prepare()
	props.append(body)
	return body


## How much a prop takes before it breaks; a bolt does 2.
const PROP_HP := {
	grave = 6.0, dead_tree = 6.0, rock = 16.0, pillar = 22.0, sarcophagus = 16.0, stalagmite = 12.0,
	ice = 6.0, basalt = 20.0, brazier = 8.0, urn = 2.0, oil_jar = 2.0, coffin = 6.0, statue = 16.0, pew = 5.0,
}


## Something hit the ground hard at [param at]: the props within
## [param r] take [param dmg].
func blast(at: Vector3, r: float, dmg: float) -> void:
	for p in props.duplicate():
		if is_instance_valid(p) and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < r + 0.4:
			p.damage(dmg)


var _dust_p: CPUParticles3D


## Motes drifting in the air: one cloud that keeps up with the camera, since
## the level is far too big to fill.
func _dust() -> void:
	var p := Fx.particles(Color(0.8, 0.7, 0.6, 0.25), 90, 8.0, 0.08)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(20.0, 1.5, 15.0)
	p.position.y = 1.5
	p.direction = Vector3(1, 0.2, 0)
	p.spread = 60.0
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.3
	p.gravity = Vector3.ZERO
	p.local_coords = false
	if biome.id == "pit":
		p.color_ramp = Fx.ramp(Color(1.0, 0.45, 0.15, 0.8))
		p.gravity = Vector3.UP * 0.3
	elif biome.id == "keep":
		p.color_ramp = Fx.ramp(Color(0.9, 0.95, 1.0, 0.7))
		p.gravity = Vector3(0.3, -0.5, 0)
		p.amount = 220
		p.mesh = Fx.particle_mesh(0.12, Color.WHITE)
	p.position = Vector3(start.x, 1.5, start.y)
	add_child(p)
	p.emitting = true
	_dust_p = p


func _process(_dt: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cam := get_viewport().get_camera_3d()
	if cam and is_instance_valid(_dust_p):
		# Where the camera looks at the ground.
		var fwd := -cam.global_transform.basis.z
		var at := cam.global_position
		if fwd.y < -0.1:
			at += fwd * ((1.5 - at.y) / fwd.y)
		_dust_p.global_position = Vector3(at.x, 1.5, at.z)
	for i in _torches.size():
		var l: OmniLight3D = _torches[i]
		if is_instance_valid(l):
			if not l.has_meta("base"):
				l.set_meta("base", l.light_energy)
			var b: float = l.get_meta("base")
			l.light_energy = b * (0.85 + 0.1 * sin(t * 9.0 + i * 1.7) + 0.05 * sin(t * 23.0 + i))


func add_field(at: Vector3, kind: int, r: float, ttl: float, owner: Actor) -> Field:
	var f := Field.new()
	f.kind = kind
	f.radius = r
	f.ttl = ttl
	f.owner_actor = owner
	f.position = Vector3(at.x, 0, at.z)
	add_child(f)
	fields.append(f)
	return f


## An element touches the ground: fields react the way you would guess.
func touch_ground(at: Vector3, r: float, el: int, src: Actor) -> void:
	for f in fields.duplicate():
		if not is_instance_valid(f) or not f.is_physics_processing():
			continue
		var d := Vector2(f.global_position.x - at.x, f.global_position.z - at.z).length()
		if d > f.radius + r:
			continue
		var k: int = f.kind
		var hot: bool = el in [El.FIRE, El.MAGMA]
		var cold: bool = el in [El.FROST, El.ICE]
		var wetting: bool = el in [El.WATER, El.STEAM, El.MUD]
		var zap: bool = el in [El.LIGHTNING, El.STORM]
		if zap and k == El.WATER:
			f.electrified = 3.0
			continue
		if f.permanent and k == El.MAGMA:
			continue
		if hot and k == El.WATER:
			f.set_kind(El.STEAM)
			f.ttl = 5.0
			_steam_pop(f)
		elif hot and k in [El.FROST, El.ICE]:
			f.set_kind(El.WATER)
			f.ttl = maxf(f.ttl, 8.0)
		elif cold and k == El.WATER:
			f.set_kind(El.FROST)
			f.ttl = maxf(f.ttl, 10.0)
		elif cold and k == El.STEAM:
			f.set_kind(El.WATER)
			f.ttl = 8.0
		elif (cold or wetting or el == El.EARTH) and k == El.FIRE and not f.permanent:
			_steam_pop(f)
			f.fade()
		elif el == El.AIR and k == El.STEAM:
			f.fade()
		elif el == El.AIR and k == El.FIRE:
			f.radius = minf(f.radius * 1.12, 4.5)
			f._build()
		if not f.permanent and src:
			f.owner_actor = src


func _steam_pop(f: Field) -> void:
	Fx.puff(f.global_position + Vector3.UP * 0.5, Color(0.85, 0.85, 0.9, 0.6), f.radius)


func ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q)


func clamp_inside(p: Vector3) -> Vector3:
	var q := Vector3(clampf(p.x, -half.x + 0.8, half.x - 0.8), 0, clampf(p.z, -half.y + 0.8, half.y - 0.8))
	if corridor:
		var q2 := Vector2(q.x, q.z)
		var d := bound(q2)
		if d > -0.8:
			var out := _bound_out(q2)
			q.x -= out.x * (d + 0.8)
			q.z -= out.y * (d + 0.8)
	return q


## Where a monster of an encounter walks in: ahead of the wizards, between
## [param near] and [param far] metres further along the path than
## [param lead] (behind it when they are negative), off to either side of
## it, out of the water when it can ([param water] 1 for in it).
func spawn_ahead(lead: float, near: float, far: float, away_from: Array, water := -1.0) -> Vector3:
	var best := Vector3.ZERO
	var best_d := -INF
	for _i in 14:
		var run := clampf(lead + _rng.randf_range(near, far), 0.0, length())
		var c := point_at(run)
		var dir := (point_at(run + 1.0) - point_at(run - 1.0)).normalized()
		var wide := minf(9.0, _hw_at(run) - 1.5) if corridor else 9.0
		var side := Vector2(-dir.y, dir.x) * _rng.randf_range(-wide, wide)
		var p := clamp_inside(Vector3(c.x + side.x, 0, c.y + side.y))
		var d := INF
		for w in away_from:
			d = minf(d, p.distance_to(w.global_position))
		# Never on top of a wizard.
		var score := minf(d, 9.0) + (3.0 * water if in_water(p) else 0.0) + _rng.randf()
		if score > best_d:
			best_d = score
			best = p
	return best


## Where a monster can walk in from: along the walls, away from the wizards.
func spawn_point(away_from: Array) -> Vector3:
	var best := Vector3.ZERO
	var best_d := -1.0
	if corridor and not _rim.is_empty():
		# Over the walls near the wizards, as far from them as it gets.
		for _i in 24:
			var r: Vector4 = _rim[_rng.randi() % _rim.size()]
			var p2 := Vector3(r.x, 0, r.y)
			var d2 := INF
			for w in away_from:
				d2 = minf(d2, p2.distance_to(w.global_position))
			if d2 < 30.0 and d2 > best_d:
				best_d = d2
				best = p2
		if best_d > 0.0:
			return best
	for _i in 12:
		var side := _rng.randi() % 3
		var p: Vector3
		match side:
			0: p = Vector3(_rng.randf_range(-half.x + 1.5, half.x - 1.5), 0, -half.y + 1.2)
			1: p = Vector3(-half.x + 1.2, 0, _rng.randf_range(-half.y + 1.5, half.y - 1.5))
			_: p = Vector3(half.x - 1.2, 0, _rng.randf_range(-half.y + 1.5, half.y - 1.5))
		var d := INF
		for w in away_from:
			d = minf(d, p.distance_to(w.global_position))
		if d > best_d:
			best_d = d
			best = p
	return best

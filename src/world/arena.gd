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
	{id = "chapel", moss = 0.6, zones = [["grave", "grave", "cross", "dead_tree", "rock", "urn", "coffin", "fence"], ["grave", "candles", "cross", "bones", "urn", "oil_jar", "statue", "mausoleum"], ["dead_tree", "dead_tree", "rock", "grave", "cross", "coffin", "oil_jar", "mausoleum"]], name = "The Forsaken Chapel", floor_a = Color(0.15, 0.16, 0.12), floor_b = Color(0.08, 0.09, 0.07), tiles = 0.0,
		wall = Color(0.24, 0.23, 0.22), fog = Color(0.08, 0.1, 0.12), ambient = Color(0.25, 0.3, 0.4), moon = Color(0.45, 0.55, 0.75), moon_energy = 0.35, mist = 1.6, mist_c = Color(0.55, 0.6, 0.65),
		props = ["grave", "grave", "grave", "dead_tree", "rock", "candles"], enemies = {ghoul = 3, skeleton = 3, watcher = 2, bone_archer = 2, necromancer = 1}, boss = "gravekeeper", fields = [],
		path_style = 0, path_a = Color(0.24, 0.2, 0.14), path_b = Color(0.14, 0.11, 0.08), layout = "nave",
		corridor = true, outside = ["dead_tree", "dead_tree", "dead_tree", "grave", "rock"], wall_style = "masonry", wall_props = ["ruin_wall"], wall_every = 18.0},
	{id = "catacombs", moss = 0.25, zones = [["bones", "candles", "sarcophagus", "pillar", "bone_pile"], ["sarcophagus", "bones", "candles", "bone_pile", "altar"], ["sarcophagus", "sarcophagus", "bones", "pillar", "bone_pile"]], name = "The Catacombs", floor_a = Color(0.2, 0.18, 0.16), floor_b = Color(0.12, 0.11, 0.1), tiles = 1.0,
		wall = Color(0.26, 0.22, 0.2), fog = Color(0.07, 0.05, 0.04), ambient = Color(0.3, 0.22, 0.16), moon = Color(0.6, 0.45, 0.35), moon_energy = 0.12, mist = 0.5, mist_c = Color(0.45, 0.4, 0.35),
		props = ["pillar", "pillar", "bones", "candles", "sarcophagus"], enemies = {skeleton = 3, cultist = 2, bile = 1, watcher = 1, bone_archer = 2, necromancer = 1, shieldbearer = 2}, boss = "abbot", fields = [],
		path_style = 2, path_a = Color(0.2, 0.035, 0.03), path_b = Color(0.12, 0.025, 0.02), layout = "nave", corridor = true, wall_style = "ossuary", wall_props = ["skull_niche", "skull_niche", "chains", "cobweb", "skull_niche", "altar"], wall_every = 6.0, outside = []},
	{id = "isles", moss = 0.7, zones = [["reeds", "reeds", "rock", "hanging_moss_tree", "sunken_ruin"], ["reeds", "reeds", "lantern", "rock", "hanging_moss_tree"], ["hanging_moss_tree", "dead_tree", "reeds", "rock", "sunken_ruin"]], name = "The Sunken Isles", floor_a = Color(0.13, 0.16, 0.09), floor_b = Color(0.07, 0.09, 0.05), tiles = 0.0,
		wall = Color(0.2, 0.24, 0.22), fog = Color(0.05, 0.09, 0.1), ambient = Color(0.22, 0.32, 0.36), moon = Color(0.5, 0.7, 0.8), moon_energy = 0.4, mist = 1.6, mist_c = Color(0.5, 0.62, 0.66),
		props = ["reeds", "reeds", "reeds", "rock", "dead_tree", "lantern"], enemies = {drowned = 3, watcher = 1, bile = 1, wraith = 1, toad = 3, sprite = 3}, boss = "drowned_king", fields = [],
		path_style = 0, path_a = Color(0.19, 0.15, 0.1), path_b = Color(0.11, 0.09, 0.06), isles = true, low_walls = true, water_props = ["piling", "piling", "lily", "lily", "boat", "sunken_ruin", "hanging_moss_tree"]},
	{id = "caves", moss = 0.5, moss_c = Color(0.08, 0.18, 0.16), zones = [["stalagmite", "stalagmite", "rock", "mine_cart", "mine_support", "drip_pool"], ["mushroom", "mushroom", "stalagmite", "rock", "fungus_shelf", "crystal"], ["stalagmite", "rock", "crystal", "mushroom", "crystal", "drip_pool"]], name = "The Drowned Caves", floor_a = Color(0.12, 0.14, 0.15), floor_b = Color(0.06, 0.08, 0.09), tiles = 0.0, wet = 1.0,
		wall = Color(0.18, 0.2, 0.21), fog = Color(0.03, 0.07, 0.08), ambient = Color(0.2, 0.34, 0.38), moon = Color(0.35, 0.62, 0.66), moon_energy = 0.3, mist = 1.3, mist_c = Color(0.4, 0.55, 0.58),
		props = ["stalagmite", "stalagmite", "mushroom", "mushroom", "rock"], enemies = {drowned = 2, bile = 2, ghoul = 2, lurker = 3, toad = 1, sprite = 2}, boss = "drowned_king", fields = [El.WATER, El.WATER, El.WATER, El.WATER],
		path_style = 1, path_a = Color(0.24, 0.27, 0.27), path_b = Color(0.13, 0.15, 0.16), corridor = true, wall_style = "rock", density = 1.8, wall_props = ["crystal", "fungus_shelf", "mine_support", "crystal"], wall_every = 9.0, outside = ["stalagmite", "rock", "crystal", "rock"]},
	{id = "keep", moss = 0.7, moss_c = Color(0.85, 0.9, 0.95), zones = [["ice", "rock", "barricade", "icicle_rock", "weapon_rack"], ["ice", "barricade", "weapon_rack", "frozen_statue", "icicle_rock"], ["ice", "rock", "barricade", "icicle_rock", "frozen_statue"]], name = "The Frozen Keep", floor_a = Color(0.26, 0.29, 0.34), floor_b = Color(0.15, 0.17, 0.21), tiles = 1.0,
		wall = Color(0.35, 0.38, 0.45), fog = Color(0.12, 0.15, 0.2), ambient = Color(0.25, 0.32, 0.42), moon = Color(0.55, 0.7, 0.95), moon_energy = 0.3, mist = 1.0, mist_c = Color(0.7, 0.75, 0.85),
		props = ["ice", "ice", "pillar", "rock"], enemies = {wraith = 2, skeleton = 2, frost_brute = 1, ghoul = 1, shieldbearer = 2, necromancer = 1, bone_archer = 2}, boss = "warden", fields = [El.FROST, El.FROST, El.FROST],
		path_style = 1, path_a = Color(0.28, 0.3, 0.34), path_b = Color(0.17, 0.19, 0.23), layout = "nave", corridor = true, wall_style = "castle", density = 1.15, wall_props = ["banner", "weapon_rack", "banner", "frozen_statue"], wall_every = 8.0, outside = ["icicle_rock", "rock", "rock", "ice"]},
	{id = "pit", moss = 0.5, moss_c = Color(0.05, 0.03, 0.03), zones = [["basalt", "spikes", "skull_pile", "lava_vent"], ["brazier", "basalt", "skull_pile", "obsidian_spire", "spikes"], ["basalt", "obsidian_spire", "brazier", "skull_pile", "lava_vent"]], name = "The Infernal Pit", floor_a = Color(0.13, 0.08, 0.07), floor_b = Color(0.05, 0.03, 0.03), tiles = 0.0,
		wall = Color(0.15, 0.1, 0.09), fog = Color(0.12, 0.03, 0.01), ambient = Color(0.4, 0.15, 0.08), moon = Color(1.0, 0.4, 0.2), moon_energy = 0.2, mist = 0.6, mist_c = Color(0.3, 0.18, 0.14),
		props = ["basalt", "basalt", "brazier", "bones"], enemies = {imp = 3, demon = 1, cultist = 2, brute = 1, hellhound = 2, lurker = 1}, boss = "pit_lord", fields = [El.MAGMA, El.MAGMA, El.MAGMA],
		path_style = 3, path_a = Color(0.1, 0.08, 0.08), path_b = Color(0.05, 0.04, 0.04), corridor = true, wall_style = "cliff", outside_lava = true, wall_props = ["cage", "chains_pit", "spikes"], wall_every = 10.0, outside = ["obsidian_spire", "basalt", "lava_vent"]},
]

var biome: Dictionary
## The way through the level, from the entrance (front) to the gate at the
## back, as points about every 2.5 m in xz, and how far along it each point
## is (path_run). Props keep off it.
var path := PackedVector2Array()
var path_run := PackedFloat32Array()
const PATH_W := 2.4
## Metres of the way between two jars of blood.
const URN_EVERY := 28.0
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
## A dungeon laid out in straight halls with square turns (catacombs, keep):
## the corner points of its path, and which of those stretches each path
## point lies on.
var ortho := false
var _okeys := PackedVector2Array()
var _oseg := PackedInt32Array()
## Points just inside the walls and the way into the level from there
## (x, z, nx, nz), for monsters that come in over the walls.
var _rim: Array[Vector4] = []
var _torches: Array = []
var _torch_base := PackedFloat32Array()
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
	_torch_base.clear()
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
	var count := int(half.x * half.y * 4.0 / 46.0)
	if corridor:
		count = int(_inside_area() / 33.0 * biome.get("density", 1.0))
	for i in count:
		var spot := _free_spot(2.6)
		if spot == Vector3.INF:
			continue
		var zone_props: Array = biome.zones[zone_at(spot)]
		_prop(zone_props[_rng.randi() % zone_props.size()], spot)
	# Out in the water of the isles: rotten pilings, lily pads, a sunken
	# boat, the stumps of drowned ruins.
	var wet_kinds: Array = biome.get("water_props", [])
	if not wet_kinds.is_empty():
		var placed := 0
		for _w in 600:
			if placed >= 70:
				break
			var q := Vector2(_rng.randf_range(-half.x + 2.0, half.x - 2.0), _rng.randf_range(-half.y + 2.0, half.y - 2.0))
			if shore(q) < 0.9 or path_dist(q) < PATH_W * 0.5 + 1.2 or _crowded(Vector3(q.x, 0, q.y), 2.0):
				continue
			_prop(wet_kinds[_rng.randi() % wet_kinds.size()], Vector3(q.x, 0, q.y))
			placed += 1
	# Jars of blood along the way, in every biome: the only health besides
	# what monsters bleed. One every URN_EVERY metres of the way, beside the
	# path on dry ground, so a long level or one of small islands is never
	# short of them.
	var urns := int(length() / URN_EVERY)
	for u in urns:
		var at := _urn_spot((u + 0.5) * length() / urns)
		_prop("blood_urn", at if at != Vector3.INF else Vector3.INF)
	for _r in int(half.y / 9.0):
		for k in biome.fields:
			var fp := _free_spot(3.0)
			if fp == Vector3.INF:
				continue
			var f := add_field(fp, k, _rng.randf_range(1.6, 3.0), 0.0, null)
			f.permanent = true
	_dust()
	_mist()


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
	ortho = built() and corridor and biome.id != "chapel"
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
			x = clampf(last_x + (0.0 if ortho else _rng.randf_range(-1.5, 1.5)), -reach, reach)
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
		if built() and i > c1 and (i < c2 or (ortho and i == c2)):
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
	if ortho:
		_orthogonal(keys)
	else:
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


## Straight halls between the keys, turning square: where two keys differ
## both ways the way runs on first and then crosses over. The path gets a
## point every two metres or so.
func _orthogonal(keys: PackedVector2Array) -> void:
	_okeys = PackedVector2Array([keys[0]])
	for i in range(1, keys.size()):
		var p := _okeys[_okeys.size() - 1]
		var q := keys[i]
		if absf(p.x - q.x) > 0.01 and absf(p.y - q.y) > 0.01:
			_okeys.append(Vector2(p.x, q.y))
		_okeys.append(q)
	path = PackedVector2Array()
	_oseg = PackedInt32Array()
	for i in _okeys.size() - 1:
		var a := _okeys[i]
		var b := _okeys[i + 1]
		var n := maxi(1, int(a.distance_to(b) / 2.0))
		for k in n:
			path.append(a.lerp(b, float(k) / n))
			_oseg.append(i)
	path.append(_okeys[_okeys.size() - 1])
	_oseg.append(_okeys.size() - 2)


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
	if ortho:
		_band_ortho()
		return
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


## A dungeon's band: halls of one width per stretch, square rooms at the
## clearings and now and then a side chamber off a long hall, all with
## straight walls.
func _band_ortho() -> void:
	var pad := 16.0
	_sdf_o = Vector2(-half.x - pad, -half.y - pad)
	_sdf_w = int((half.x + pad) * 2.0) + 1
	_sdf_h = int((half.y + pad) * 2.0) + 1
	_sdf.resize(_sdf_w * _sdf_h)
	_sdf.fill(30.0)
	var segw := PackedFloat32Array()
	for i in _okeys.size() - 1:
		var a := _okeys[i]
		var b := _okeys[i + 1]
		var w := _rng.randf_range(3.2, 4.6)
		var run := progress_of((a + b) * 0.5)
		if nave.x >= 0.0 and run > nave.x - 6.0 and run < nave.y + 6.0 and absf(a.x - b.x) < 0.01:
			w = 13.5
		if a.y <= portal_at.y + 0.1 and b.y <= portal_at.y + 0.1:
			w = 2.3
		segw.append(w)
		_raster_box((a + b) * 0.5, (b - a).abs() * 0.5 + Vector2(w, w))
		# A side chamber off a long hall, through a doorway.
		if w < 6.0 and w > 3.0 and a.distance_to(b) > 14.0 and _rng.randf() < 0.55:
			var along := (b - a).normalized()
			var across := Vector2(along.y, -along.x) * (1.0 if _rng.randf() < 0.5 else -1.0)
			var room := Vector2(_rng.randf_range(3.0, 5.0), _rng.randf_range(3.0, 5.0))
			var depth := absf(across.x) * room.x + absf(across.y) * room.y
			var c := a.lerp(b, _rng.randf_range(0.3, 0.7)) + across * (w + 1.0 + depth)
			if absf(c.x) + room.x < half.x - 2.0:
				_raster_box(c, room)
				var door := absf(along.x) * Vector2(1.4, 0) + absf(along.y) * Vector2(0, 1.4)
				_raster_box(c - across * depth - across * 0.5, door + absf(across.x) * Vector2(1.2, 0) + absf(across.y) * Vector2(0, 1.2))
	_hw = PackedFloat32Array()
	for i in path.size():
		_hw.append(segw[_oseg[i]])
	_raster_box(start, Vector2(6.0, 6.0))
	for c in clearings:
		_raster_box(Vector2(c.x, c.y), Vector2(c.z + 2.0, c.z + 2.0))
	for iz in _sdf_h:
		for ix in _sdf_w:
			var q := _sdf_o + Vector2(ix, iz)
			var i2 := iz * _sdf_w + ix
			var d := maxf(_sdf[i2], q.y - (half.y + 0.6))
			_sdf[i2] = maxf(d, -q.y - (half.y + 0.6))


## Write the distance to the box at [param c] reaching [param he] each way
## into the field where it is nearer than what is there.
func _raster_box(c: Vector2, he: Vector2) -> void:
	var x0 := maxi(0, int(c.x - he.x - 9.0 - _sdf_o.x))
	var x1 := mini(_sdf_w - 1, int(c.x + he.x + 9.0 - _sdf_o.x) + 1)
	var z0 := maxi(0, int(c.y - he.y - 9.0 - _sdf_o.y))
	var z1 := mini(_sdf_h - 1, int(c.y + he.y + 9.0 - _sdf_o.y) + 1)
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var q := (_sdf_o + Vector2(ix, iz) - c).abs() - he
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)
			var i := iz * _sdf_w + ix
			if d < _sdf[i]:
				_sdf[i] = d


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
	# Chain the contour points into walls: from each loose point, step to
	# the nearest unused one close by, so every wall runs unbroken along the
	# edge of the band instead of standing as loose blocks.
	var chains: Array = []
	var used := {}
	for start in pts.size():
		if used.has(start):
			continue
		var chain: Array[Vector2] = [pts[start]]
		used[start] = true
		# Grow from both ends: a chain that starts mid-edge would otherwise
		# leave a gap where its other half begins.
		for _end in 2:
			var grow := true
			while grow:
				grow = false
				var tip: Vector2 = chain[chain.size() - 1]
				var best := -1
				var bd := 2.4
				for k in pts.size():
					if used.has(k):
						continue
					var d := pts[k].distance_to(tip)
					if d < bd:
						bd = d
						best = k
				if best >= 0:
					used[best] = true
					chain.append(pts[best])
					grow = true
			chain.reverse()
		chains.append(chain)
	# Where two chains end close together, join them, so no edge of the
	# band is left without a wall in front of it.
	var ends: Array[Vector2] = []
	for chain: Array in chains:
		ends.append(chain[0])
		ends.append(chain[chain.size() - 1])
	for ci in chains.size():
		var ch: Array = chains[ci]
		for at_end in 2:
			var e: Vector2 = ch[ch.size() - 1] if at_end == 1 else ch[0]
			var best_p := Vector2.INF
			var best_d := 3.2
			for ei in ends.size():
				if ei / 2 == ci:
					continue
				var d := ends[ei].distance_to(e)
				if d > 0.05 and d < best_d:
					best_d = d
					best_p = ends[ei]
			if best_p != Vector2.INF:
				if at_end == 1:
					ch.append(best_p)
				else:
					ch.insert(0, best_p)
	# Any stretch of the band's edge still without a wall in front of it
	# (pinches the thinned points skipped) gets a short piece of its own:
	# where you cannot walk on, there is always a wall to see.
	var segs: Array = []
	for chain: Array in chains:
		for k in chain.size() - 1:
			segs.append([chain[k], chain[k + 1]])
	for iz in _sdf_h - 1:
		for ix in _sdf_w - 1:
			var i := iz * _sdf_w + ix
			for nb: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var v := _sdf[i]
				var w := _sdf[i + nb.x + nb.y * _sdf_w]
				if (v < 0.0) == (w < 0.0):
					continue
				var q := _sdf_o + Vector2(ix + nb.x * v / (v - w), iz + nb.y * v / (v - w))
				var covered := false
				for sg: Array in segs:
					var a2: Vector2 = sg[0]
					var ab: Vector2 = sg[1] - a2
					var tt := clampf((q - a2).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
					if (a2 + ab * tt).distance_to(q) < 0.8:
						covered = true
						break
				if covered:
					continue
				var out := _bound_out(q)
				var tan := Vector2(-out.y, out.x) * 0.7
				var stub: Array[Vector2] = [q - tan, q + tan]
				chains.append(stub)
				segs.append([stub[0], stub[1]])
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	var tools := {}
	var lit := Art.stone(biome.wall, biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
	var dark := Art.stone(biome.wall.darkened(0.3), biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
	# Each biome's walls have their own shape: graveyard masonry, crypt
	# walls with skull niches, a castle's battlements, the raw rock of a
	# cave, jagged cliffs over lava.
	var style: String = biome.get("wall_style", "masonry")
	var natural := style == "rock" or style == "cliff"
	var mats := {0: lit, 1: dark, 2: Art.stone(biome.wall.darkened(0.75)), 3: _bone_mat()}
	if style == "cliff":
		mats[0] = Art.stone(biome.wall.darkened(0.2), 0.0)
		mats[1] = Art.stone(biome.wall.darkened(0.45), 0.0)
	var last_torch: Array[Vector2] = []
	var wall_props: Array = biome.get("wall_props", [])
	var every: float = biome.get("wall_every", 9.0)
	for chain: Array in chains:
		if chain.size() < 2:
			continue
		# The height drifts slowly along a wall instead of jumping per stone.
		var drift := _rng.randf() * 10.0
		var since := _rng.randf() * every
		for k in chain.size() - 1:
			var a: Vector2 = chain[k]
			var b: Vector2 = chain[k + 1]
			var mid := (a + b) * 0.5
			# The gate fills the gap at the far end.
			if mid.y < -half.y + 1.5 and absf(mid.x - portal_at.x) < 2.6:
				continue
			var out := _bound_out(mid)
			var along := b - a
			var len := along.length()
			if len < 0.05:
				continue
			var face := smoothstep(0.25, 0.8, out.y)
			var wave := 0.88 + 0.12 * sin(drift + k * 0.45) + 0.06 * sin(drift * 1.7 + k * 1.3)
			var tall := 2.7 if style != "castle" else 3.3
			if style == "cliff":
				tall = 2.0
			var h := lerpf(tall, 0.75, face) * wave
			var basis := Basis(Vector3.UP, atan2(along.x, along.y) + PI * 0.5)
			var centre := Vector3(mid.x + out.x * 0.45, 0, mid.y + out.y * 0.45)
			var ck := Vector2i(int(floor(mid.x / 20.0)), int(floor(mid.y / 20.0)))
			if natural:
				# Rock, not blocks: two lumpy crags overlapping along the edge,
				# leaning a little, one now and then standing taller.
				for j in 2:
					var w := (len + 0.9) * _rng.randf_range(0.65, 0.85)
					var ch := h * _rng.randf_range(0.85, 1.25) * (1.35 if k % 4 == 0 and j == 0 else 1.0)
					var off := (j - 0.5) * len * 0.45
					var rb := basis * Basis(Vector3.UP, _rng.randf_range(-0.4, 0.4)) * Basis(Vector3.RIGHT, _rng.randf_range(-0.12, 0.12))
					var xf := Transform3D(rb * Basis.from_scale(Vector3(w, ch, _rng.randf_range(1.3, 1.9))), centre + basis * Vector3(off, 0, 0) + Vector3.UP * ch * 0.38)
					_wall_mesh(tools, Vector3i(ck.x, ck.y, j), _crag(_rng.randi() % 6, style == "cliff"), xf)
			else:
				_wall_piece(tools, Vector3i(ck.x, ck.y, 0), Vector3(len + 0.35, h, 0.8), Transform3D(basis, centre + Vector3.UP * h * 0.5))
				# A coping along the top, darker.
				_wall_piece(tools, Vector3i(ck.x, ck.y, 1), Vector3(len + 0.4, 0.14, 1.0), Transform3D(basis, centre + Vector3.UP * (h + 0.07)))
				# A plinth along the foot.
				_wall_piece(tools, Vector3i(ck.x, ck.y, 1), Vector3(len + 0.4, 0.3, 1.05), Transform3D(basis, centre + Vector3.UP * 0.15))
				if style == "castle" and h > 1.9:
					# Battlements: merlons with gaps along the top.
					var n := maxi(1, int(round(len / 0.9)))
					for m in n:
						var o := -len * 0.5 + (m + 0.5) * len / n
						_wall_piece(tools, Vector3i(ck.x, ck.y, 0), Vector3(len / n * 0.55, 0.45, 0.9), Transform3D(basis, centre + basis * Vector3(o, 0, 0) + Vector3.UP * (h + 0.36)))
				if style == "ossuary" and h > 2.2 and k % 2 == 1 and len > 0.9:
					# A niche in the wall, stacked with skulls.
					var inner := centre - Vector3(out.x, 0, out.y) * 0.4
					_wall_piece(tools, Vector3i(ck.x, ck.y, 2), Vector3(len * 0.7, 0.75, 0.06), Transform3D(basis, inner + Vector3.UP * 1.35))
					_wall_piece(tools, Vector3i(ck.x, ck.y, 1), Vector3(len * 0.8, 0.08, 0.2), Transform3D(basis, inner + Vector3.UP * 0.94))
					var sk := maxi(1, int(len * 0.7 / 0.24))
					for m in sk:
						for row in 2:
							var o2 := -len * 0.33 + (m + 0.5) * len * 0.66 / sk + (0.06 if row == 1 else 0.0)
							var at := inner - Vector3(out.x, 0, out.y) * 0.04 + basis * Vector3(o2, 0, 0) + Vector3.UP * (1.08 + row * 0.25)
							_wall_mesh(tools, Vector3i(ck.x, ck.y, 3), _niche_skull(), Transform3D(Basis(Vector3.UP, atan2(-out.x, -out.y)) * Basis(Vector3.UP, _rng.randf_range(-0.4, 0.4)), at))
				# A buttress every few stones, a little taller, with a cap.
				if k % 3 == 0:
					var ph := h + 0.35
					_wall_piece(tools, Vector3i(ck.x, ck.y, 0), Vector3(0.75, ph, 1.15), Transform3D(Basis(Vector3.UP, basis.get_euler().y), Vector3(a.x + out.x * 0.45, ph * 0.5, a.y + out.y * 0.45)))
					_wall_piece(tools, Vector3i(ck.x, ck.y, 1), Vector3(0.95, 0.2, 1.35), Transform3D(Basis(Vector3.UP, basis.get_euler().y), Vector3(a.x + out.x * 0.45, ph + 0.1, a.y + out.y * 0.45)))
					if ph > 2.4:
						var far := true
						for o in last_torch:
							if o.distance_to(a) < 13.0:
								far = false
						if far:
							last_torch.append(a)
							_torch(self, Vector3(a.x - out.x * 0.25, 2.2, a.y - out.y * 0.25))
			# Something of the biome's against the taller walls now and then.
			since += len
			if h > 1.7 and not wall_props.is_empty() and since >= every:
				var spot := mid - out * 0.85
				if path_dist(spot) > PATH_W * 0.5 + 1.2 and not _crowded(Vector3(spot.x, 0, spot.y), 1.4):
					since = 0.0
					_prop(wall_props[_rng.randi() % wall_props.size()], Vector3(spot.x, 0, spot.y), atan2(-out.x, -out.y))
			var bs := BoxShape3D.new()
			bs.size = Vector3(len + 0.5, 4.0, 1.2)
			var cs := CollisionShape3D.new()
			cs.shape = bs
			cs.transform = Transform3D(basis, centre + Vector3.UP * 2.0)
			body.add_child(cs)
			_rim.append(Vector4(mid.x - out.x * 1.4, mid.y - out.y * 1.4, -out.x, -out.y))
	for tk: Vector3i in tools:
		var m := MeshInstance3D.new()
		m.mesh = (tools[tk] as SurfaceTool).commit()
		m.material_override = mats[tk.z if not natural else (0 if tk.z == 0 else 1)]
		add_child(m)


func _wall_piece(tools: Dictionary, key: Vector3i, size: Vector3, xf: Transform3D) -> void:
	_wall_mesh(tools, key, Art.box(size.x, size.y, size.z), xf)


func _wall_mesh(tools: Dictionary, key: Vector3i, mesh: Mesh, xf: Transform3D) -> void:
	if not tools.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools[key] = st
	(tools[key] as SurfaceTool).append_from(mesh, 0, xf)


static var _crags := {}


## A unit-sized lump of rock for natural walls: rounded and lumpy for a
## cave, or [param jagged], narrowing to broken points, for the pit's cliffs.
static func _crag(i: int, jagged: bool) -> Mesh:
	var key := i + (100 if jagged else 0)
	if not _crags.has(key):
		var m := Shape.blob(Vector3(0.5, 0.5, 0.5), 0.3 if jagged else 0.2, 3.1 + i * 7.3, 9, 13)
		if jagged:
			var s := float(i)
			m = Shape.warp(m, func(v: Vector3) -> Vector3:
				var up := clampf(v.y + 0.5, 0.0, 1.0)
				var pinch := 1.0 - up * 0.65
				var spike := 1.0 + 0.35 * maxf(0.0, sin(v.x * 9.0 + s) * sin(v.z * 7.0 + s * 2.0)) * up
				return Vector3(v.x * pinch, v.y * spike, v.z * pinch))
		_crags[key] = m
	return _crags[key]


static var _skull_mesh: Mesh


## A small skull for the niches: a round cranium, its face to +z.
static func _niche_skull() -> Mesh:
	if _skull_mesh == null:
		var head := Shape.blob(Vector3(0.1, 0.09, 0.11), 0.05, 2.0, 8, 10)
		var face := Shape.warp(Shape.blob(Vector3(0.075, 0.06, 0.05), 0.0, 1.0, 6, 8), func(v: Vector3) -> Vector3: return v + Vector3(0, -0.05, 0.07))
		_skull_mesh = Shape.merge([head, face])
	return _skull_mesh


static func _bone_mat() -> Material:
	return Shape.material(Color(0.6, 0.56, 0.47), Color(0.28, 0.25, 0.2), 6.0, 0.8, 0.5, 0.0, 77)


## Beyond the walls: dark ground thick with the biome's things, so the edge
## of the level reads as land you cannot reach, not as the end of the world.
func _outside() -> void:
	var kinds: Array = biome.get("outside", ["rock"])
	if kinds.is_empty():
		return
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
						if _rng.randf() < 0.5:
							_prop("pew", Vector3(x0 + sgn * (x + 0.4) + _rng.randf_range(-0.2, 0.2), 0, z), PI + _rng.randf_range(-0.15, 0.15) + (0.6 if _rng.randf() < 0.12 else 0.0))
				if _rng.randf() < 0.22:
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
	var stone := Art.stone(biome.wall.darkened(0.1), biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
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


## A post with a hanging lantern beside the path: wrought iron, a caged
## flame behind smoky amber glass.
func _lamp(at: Vector2, toward := Vector2.ZERO) -> void:
	var n := Node3D.new()
	n.position = Vector3(at.x, 0, at.y)
	# The arm reaches out over the path.
	if toward != Vector2.ZERO:
		n.rotation.y = atan2(-toward.y, toward.x)
	else:
		n.rotation.y = _rng.randf() * TAU
	add_child(n)
	var kit := _lamp_kit()
	Art.part(n, kit.iron, _iron())
	var glass := Art.part(n, kit.glass, kit.glass_mat)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var flame := Art.part(n, kit.flame, Fx.glow(Color(1.0, 0.72, 0.4), 5.0))
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo := Fx.halo(Color(1.0, 0.6, 0.28), 0.8, 0.75)
	halo.position = Vector3(0.42, 1.53, 0)
	n.add_child(halo)
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
	var stone := Art.stone(biome.wall.lightened(0.05), biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
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
	var x := -half.x - 5.0 - (24.0 if corridor else 0.0)
	while x < half.x + 5.0 + (24.0 if corridor else 0.0):
		var z := -half.y - 5.0
		while z < half.y + 8.0:
			var lo := Vector2(x, z)
			var hi := lo + Vector2(chunk, chunk)
			if corridor and bound(lo + Vector2(chunk, chunk) * 0.5) > 7.1 + 24.0:
				# Nothing here to see: deep beyond the walls.
				z += chunk
				continue
			var mat := ShaderMaterial.new()
			if corridor:
				mat.set_shader_parameter("bounds", tex)
				mat.set_shader_parameter("bounds_rect", Vector4(_sdf_o.x - 0.5, _sdf_o.y - 0.5, _sdf_w, _sdf_h))
				mat.set_shader_parameter("bounded", true)
				mat.set_shader_parameter("outside_lava", 1.0 if biome.get("outside_lava", false) else 0.0)
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
			mat.set_shader_parameter("square_plazas", ortho)
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
	var mat := Art.stone(biome.wall, biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
	var dark := Art.stone(biome.wall.darkened(0.35), biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
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


## A spot beside the path near [param run] metres along it, clear and on
## land, or INF.
func _urn_spot(run: float) -> Vector3:
	for _i in 30:
		var r := clampf(run + _rng.randf_range(-6.0, 6.0), 8.0, length() - 4.0)
		var c := point_at(r)
		var dir := (point_at(r + 1.0) - point_at(r - 1.0)).normalized()
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var p2 := c + Vector2(-dir.y, dir.x) * side * _rng.randf_range(PATH_W * 0.5 + 1.2, PATH_W * 0.5 + 4.0)
		if bound(p2) > -1.2 or in_clearing(p2, 1.0) or p2.distance_to(start) < 7.0:
			continue
		if not isles.is_empty() and shore(p2) > -0.8:
			continue
		var p := Vector3(p2.x, 0, p2.y)
		if _crowded(p, 1.6):
			continue
		return p
	return Vector3.INF


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
static var _boulders: Array[Mesh] = []


## One of a few lumpy boulders, shared: rocks used to be six-sided spheres.
static func _boulder(i: int) -> Mesh:
	while _boulders.size() < 6:
		var k := _boulders.size()
		_boulders.append(Shape.blob(Vector3(1.0, 0.6, 0.85), 0.2, k * 3.7 + 1.0, 9, 14))
	return _boulders[i]


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
	var stone := Art.stone(biome.wall.lightened(0.1), biome.get("moss", 0.0), biome.get("moss_c", Color(0.12, 0.16, 0.08)))
	match kind:
		"grave":
			var g := Art.tombstone()
			g.scale = Vector3.ONE * _rng.randf_range(0.8, 1.2)
			g.rotation.z = _rng.randf_range(-0.15, 0.15)
			body.add_child(g)
			r = 0.4
		"dead_tree":
			var tree := _tree_kit(_rng.randi() % 5)
			var ts := _rng.randf_range(0.85, 1.15)
			_put(body, tree[0], _bark(), ts)
			_put(body, tree[1], _bark(), ts)
			r = 0.35
		"rock":
			Art.part(body, _boulder(_rng.randi() % 6), stone, Vector3(0, 0.25, 0), Vector3(_rng.randf() * 30, 0, 0), Vector3.ONE * _rng.randf_range(0.85, 1.15))
			r = 0.8
		"candles":
			var ck := _candle_kit(_rng.randi() % 4)
			if ck.has("slab"):
				Art.part(body, ck.slab, Art.stone(biome.wall.darkened(0.25), biome.get("moss", 0.0) * 0.5, biome.get("moss_c", Color(0.12, 0.16, 0.08))))
			Art.part(body, ck.wax, Shape.material(Color(0.5, 0.43, 0.32), Color(0.4, 0.33, 0.23), 6.0, 0.5, 0.25, 0.0, 51))
			Art.part(body, ck.wick, Fx.solid(Color(0.04, 0.03, 0.03)))
			var fm := Art.part(body, ck.flame, Fx.glow(Color(1.0, 0.62, 0.28), 4.0))
			fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for tp: Vector3 in ck.tops:
				var hl := Fx.halo(Color(1.0, 0.55, 0.22), 0.2, 0.55)
				hl.position = tp
				body.add_child(hl)
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
			Art.part(body, Art.cyl(0.45, 0.45, 3.2, 18), stone, Vector3(0, 1.6, 0))
			Art.part(body, Art.box(1.1, 0.3, 1.1), stone, Vector3(0, 0.15, 0))
			Art.part(body, Art.box(1.1, 0.3, 1.1), stone, Vector3(0, 3.1, 0))
			r = 0.55
		"bones":
			var bk := _bones_kit(_rng.randi() % 6)
			Art.part(body, bk[0], Shape.material(Color(0.46, 0.42, 0.34), Color(0.25, 0.21, 0.15), 5.0, 0.75, 0.6, 0.0, 41))
			if bk[1] != null:
				Art.part(body, bk[1], Fx.solid(Color(0.025, 0.02, 0.018)))
			body.collision_layer = 0
			return body
		"sarcophagus":
			Art.part(body, Art.box(1.15, 0.12, 2.35), stone, Vector3(0, 0.06, 0))
			Art.part(body, Art.box(1.0, 0.7, 2.2), stone, Vector3(0, 0.45, 0))
			Art.part(body, Art.box(1.12, 0.1, 2.32), stone, Vector3(0, 0.85, 0))
			Art.part(body, Art.box(0.98, 0.07, 2.16), stone, Vector3(0, 0.935, 0))
			var eff := _effigy()
			Art.part(body, eff[0], stone, eff[1] + Vector3(0, 0.97, 0))
			r = 0.9
		"stalagmite":
			var sk := _stalag_kit(_rng.randi() % 4)
			var ss := _rng.randf_range(0.85, 1.15)
			_put(body, sk[0], stone, ss)
			_put(body, sk[1], stone, ss)
			r = 0.55
		"mushroom":
			var c := Color(0.2, 0.52, 0.48) if _rng.randf() < 0.5 else Color(0.42, 0.3, 0.58)
			var mk := _shroom_kit(_rng.randi() % 4)
			Art.part(body, mk[0], Shape.material(Color(0.4, 0.38, 0.33), Color(0.2, 0.19, 0.16), 6.0, 0.8, 0.4, 0.0, 121))
			var capm: StandardMaterial3D = _cached("mcap" + c.to_html(), func() -> StandardMaterial3D:
				var m: StandardMaterial3D = Shape.material(Color(0.3, 0.28, 0.25).lerp(c, 0.3), Color(0.14, 0.13, 0.12).lerp(c, 0.2), 5.0, 0.6, 0.6, 0.0, 122).duplicate()
				m.emission_enabled = true
				m.emission = c
				m.emission_energy_multiplier = 0.35
				return m)
			Art.part(body, mk[1], capm)
			var l2 := OmniLight3D.new()
			l2.light_color = c.lightened(0.2)
			l2.light_energy = 0.8
			l2.omni_range = 3.5
			l2.position.y = 0.6
			body.add_child(l2)
			body.collision_layer = 0
			return body
		"ice":
			var n := _rng.randi_range(4, 6)
			for i in n:
				var ih := _rng.randf_range(0.6, 1.8) * (1.0 if i > 0 else 1.2)
				var a := TAU * i / n + _rng.randf_range(-0.4, 0.4)
				var off := Vector3(cos(a), 0, sin(a)) * (0.0 if i == 0 else _rng.randf_range(0.15, 0.35))
				# Leaning out from the middle of the cluster.
				var tilt := Basis(Vector3(-sin(a), 0, cos(a)), 0.0 if i == 0 else _rng.randf_range(0.15, 0.4))
				var w := _rng.randf_range(0.8, 1.2) * (1.3 if i == 0 else 1.0)
				var sm := Art.part(body, _shard(_rng.randi() % 6), _ice_mat(), off)
				sm.transform.basis = tilt * Basis.from_scale(Vector3(w, ih, w))
			r = 0.5
		"reeds":
			var rk := _reed_kit(_rng.randi() % 4)
			Art.part(body, rk[0], Shape.material(Color(0.27, 0.29, 0.15), Color(0.12, 0.13, 0.07), 6.0, 0.85, 0.4, 0.0, 111))
			Art.part(body, rk[1], Shape.material(Color(0.22, 0.14, 0.08), Color(0.1, 0.06, 0.04), 8.0, 0.9, 0.6, 0.0, 112))
			body.collision_layer = 0
			return body
		"lantern":
			body.queue_free()
			_lamp(Vector2(p.x, p.z))
			return null
		"basalt":
			var bm := Shape.material(Color(0.13, 0.12, 0.12), Color(0.045, 0.04, 0.04), 2.5, 0.7, 1.1, 0.0, 101)
			var cols := _rng.randi_range(3, 5)
			for i in cols:
				# Packed six-sided columns, as lava cracks when it cools.
				var bh := _rng.randf_range(0.6, 2.4)
				var off2 := Vector3.ZERO if i == 0 else Vector3(cos(TAU * i / 6.0 + PI / 6.0), 0, sin(TAU * i / 6.0 + PI / 6.0)) * 0.5
				var br := _rng.randf_range(0.24, 0.29)
				Art.part(body, Art.cyl(br, br * 1.05, bh, 6), bm, off2 + Vector3(0, bh * 0.5, 0), Vector3(_rng.randf_range(-4, 4), 0, _rng.randf_range(-4, 4)))
			r = 0.6
		"brazier":
			var bz := _brazier_kit()
			_put(body, bz[0], bz[4])
			_put(body, bz[1], bz[4])
			_put(body, bz[2], Shape.material(Color(0.07, 0.05, 0.045), Color(0.02, 0.015, 0.015), 6.0, 0.9, 0.8, 0.0, 34))
			_put(body, bz[3], Fx.glow(Color(1.0, 0.38, 0.1), 2.5))
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
			var uk := _urn_kit(_rng.randi() % 3, false)
			var clay := Shape.material(Color(0.36, 0.23, 0.15), Color(0.15, 0.1, 0.07), 3.0, 0.9, 0.5, 0.0, 61)
			for pc: Array in uk.pieces:
				_put(body, pc, clay)
			Art.part(body, uk.band, Shape.material(Color(0.12, 0.08, 0.06), Color(0.06, 0.04, 0.03), 4.0, 0.9, 0.4, 0.0, 62))
			# Sunk a little inside the neck, so it wells up out of the urn.
			Art.part(body, Art.cyl(uk.mouth_r * 0.85, uk.mouth_r * 0.85, 0.02, 10), Fx.glow(Soul.COLOR, 1.4), Vector3(0, uk.mouth - 0.07, 0))
			var mana := Fx.halo(Soul.COLOR, 0.7, 0.5, 0.3)
			mana.position.y = uk.mouth + 0.02
			body.add_child(mana)
			body.spill = "souls"
			r = 0.3
		"oil_jar":
			# A powder keg: an orange-painted barrel with dark hoops and a
			# lit fuse spitting sparks. Breaking it blows up (Prop._spill).
			var kk := _keg_kit()
			var paint := _grain("keg", Color(0.66, 0.3, 0.08), Color(0.25, 0.11, 0.04), Vector3(16, 1.8, 16), 0.8, 1.0, 81)
			_put(body, kk[0], paint)
			_put(body, kk[1], paint)
			_put(body, kk[2], _iron())
			_put(body, kk[3], _grain("kegtop", Color(0.24, 0.15, 0.08), Color(0.1, 0.06, 0.03), Vector3(14, 14, 1.8), 0.9, 0.9, 82))
			# A black blast mark painted on the side.
			Art.part(body, Art.sphere(0.09, 8), Fx.solid(Color(0.07, 0.05, 0.04), 0.8), Vector3(0, 0.32, 0.25), Vector3.ZERO, Vector3(1, 1, 0.25))
			Art.part(body, Art.cyl(0.012, 0.012, 0.16, 5), Fx.solid(Color(0.5, 0.45, 0.35), 0.9), Vector3(0.06, 0.66, 0), Vector3(0, 0, -20))
			var spark := Fx.particles(Color(1.0, 0.7, 0.2), 10, 0.3, 0.07)
			spark.position = Vector3(0.09, 0.74, 0)
			spark.direction = Vector3.UP
			spark.spread = 60.0
			spark.initial_velocity_min = 0.6
			spark.initial_velocity_max = 1.4
			spark.gravity = Vector3.DOWN * 2.0
			body.add_child(spark)
			spark.emitting = true
			var glow := Fx.halo(Color(1.0, 0.55, 0.15), 0.6, 0.9, 1.0)
			glow.position = Vector3(0.09, 0.74, 0)
			body.add_child(glow)
			body.spill = "fire"
			r = 0.35
		"blood_urn":
			# A dark jar brimming with blood, glowing red: break it and drink.
			var bu := _urn_kit(_rng.randi() % 3, true)
			var glaze := Shape.material(Color(0.26, 0.05, 0.04), Color(0.09, 0.02, 0.02), 3.0, 0.3, 0.35, 0.05, 71)
			for pc: Array in bu.pieces:
				_put(body, pc, glaze)
			Art.part(body, bu.band, Shape.material(Color(0.42, 0.32, 0.18), Color(0.18, 0.13, 0.07), 4.0, 0.45, 0.5, 0.6, 72))
			Art.part(body, Art.cyl(bu.mouth_r, bu.mouth_r, 0.02, 10), Fx.glow(Globe.COLOR, 1.2), Vector3(0, bu.mouth - 0.06, 0))
			var bloom := Fx.halo(Globe.COLOR, 0.9, 0.6, 0.3)
			bloom.position.y = bu.mouth + 0.02
			body.add_child(bloom)
			body.spill = "blood"
			r = 0.3
		"coffin":
			var ck2 := _coffin_kit()
			var wood := _grain("coffin", Color(0.2, 0.13, 0.08), Color(0.07, 0.045, 0.03), Vector3(7, 7, 1.2), 0.85, 0.8, 21)
			Art.part(body, ck2.floor, wood)
			var n2 := _COFFIN.size()
			for i in n2:
				# Six planks for sides, so it breaks into boards.
				var a2: Vector2 = _COFFIN[i]
				var b2: Vector2 = _COFFIN[(i + 1) % n2]
				var mid := (a2 + b2) * 0.5
				var e := b2 - a2
				Art.part(body, Art.box(0.045, 0.36, e.length() + 0.03), wood, Vector3(mid.x - mid.normalized().x * 0.02, 0.21, mid.y - mid.normalized().y * 0.02), Vector3(0, rad_to_deg(atan2(e.x, e.y)), 0))
			Art.part(body, ck2.hollow, Fx.solid(Color(0.02, 0.015, 0.012)))
			Art.part(body, ck2.handles, _iron())
			var lid_wood := _grain("coffinlid", Color(0.17, 0.11, 0.07), Color(0.06, 0.04, 0.025), Vector3(7, 7, 1.2), 0.85, 0.8, 22)
			Art.part(body, ck2.lid, lid_wood, Vector3(0.09, 0.39, -0.14), Vector3(3, 9, -4))
			body.spill = "globe"
			r = 0.6
		"statue":
			# A weeping angel on a plinth.
			var marble := Shape.material(Color(0.33, 0.33, 0.31), Color(0.24, 0.24, 0.22), 4.0, 0.8, 0.7, 0.0, 131)
			Art.part(body, Art.box(1.12, 0.14, 1.12), stone, Vector3(0, 0.07, 0))
			Art.part(body, Art.box(0.96, 0.46, 0.96), stone, Vector3(0, 0.37, 0))
			Art.part(body, Art.box(1.06, 0.1, 1.06), stone, Vector3(0, 0.65, 0))
			for pc: Array in _angel_kit():
				_put(body, pc, marble)
			r = 0.55
		"pew":
			var oak := _grain("pew", Color(0.21, 0.13, 0.08), Color(0.07, 0.045, 0.03), Vector3(1.4, 14, 14), 0.75, 0.9, 91)
			var oak_end := _grain("pewend", Color(0.18, 0.11, 0.07), Color(0.06, 0.04, 0.025), Vector3(14, 1.4, 14), 0.75, 0.9, 92)
			Art.part(body, Art.box(2.3, 0.07, 0.42), oak, Vector3(0, 0.45, 0.02))
			Art.part(body, Art.box(2.3, 0.5, 0.05), oak, Vector3(0, 0.77, -0.2), Vector3(-8, 0, 0))
			Art.part(body, Art.box(2.3, 0.06, 0.08), oak, Vector3(0, 1.03, -0.24), Vector3(-8, 0, 0))
			Art.part(body, Art.box(2.3, 0.12, 0.03), oak, Vector3(0, 0.33, 0.2))
			for sgn: float in [-1.0, 1.0]:
				Art.part(body, Art.box(0.08, 0.95, 0.5), oak_end, Vector3(sgn * 1.17, 0.475, -0.02))
				Art.part(body, Art.box(0.1, 0.06, 0.54), oak_end, Vector3(sgn * 1.17, 0.97, -0.02))
			r = 0.0
		_:
			# The biomes' own dressing (Dressing): r < 0 means walk-through.
			if not Dressing.KINDS.has(kind):
				body.queue_free()
				return null
			var made: Dictionary = Dressing.build(kind, body, _rng, biome)
			for l in body.find_children("*", "OmniLight3D", true, false):
				_torches.append(l)
			r = made.get("r", 0.4)
			if r < 0.0:
				body.collision_layer = 0
				Art.merge_parts(body)
				return body
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
	Art.merge_parts(body)
	props.append(body)
	return body


## How much a prop takes before it breaks; a bolt does 2.
const PROP_HP := {
	grave = 6.0, dead_tree = 6.0, rock = 16.0, pillar = 22.0, sarcophagus = 16.0, stalagmite = 12.0,
	ice = 6.0, basalt = 20.0, brazier = 8.0, urn = 2.0, oil_jar = 2.0, blood_urn = 2.0, coffin = 6.0, statue = 16.0, pew = 5.0,
}


## Something hit the ground hard at [param at]: the props within
## [param r] take [param dmg].
func blast(at: Vector3, r: float, dmg: float) -> void:
	for p in props.duplicate():
		if is_instance_valid(p) and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < r + 0.4:
			p.damage(dmg, Vector3.ZERO, at)


var _mist_v: FogVolume
static var _mist_tex: NoiseTexture3D


## Low mist over the ground (Joep: some levels may feel misty): thickest
## at the floor and thinning out by head height, patchy, drifting slowly.
## How thick and what colour is the biome's ("mist", "mist_c").
func _mist() -> void:
	if is_instance_valid(_mist_v):
		_mist_v.queue_free()
	var k: float = biome.get("mist", 0.0)
	if k <= 0.0:
		return
	if _mist_tex == null:
		var n := FastNoiseLite.new()
		n.frequency = 0.06
		n.fractal_octaves = 3
		_mist_tex = NoiseTexture3D.new()
		_mist_tex.width = 48
		_mist_tex.height = 16
		_mist_tex.depth = 48
		_mist_tex.seamless = true
		_mist_tex.noise = n
		# Patches of mist and clear air between, not an even haze.
		var ramp := Gradient.new()
		ramp.set_color(0, Color.BLACK)
		ramp.set_offset(0, 0.35)
		ramp.set_color(1, Color.WHITE)
		ramp.set_offset(1, 0.75)
		_mist_tex.color_ramp = ramp
	var m := FogMaterial.new()
	m.density = k
	m.albedo = biome.get("mist_c", Color(0.6, 0.6, 0.6))
	# A faint glow of its own, so it reads even where no lamp reaches.
	m.emission = (biome.get("mist_c", Color(0.6, 0.6, 0.6)) as Color) * 0.05
	m.height_falloff = 1.2
	m.edge_fade = 0.3
	m.density_texture = _mist_tex
	_mist_v = FogVolume.new()
	_mist_v.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	_mist_v.size = Vector3(half.x * 2.0 + 30.0, 3.2, half.y * 2.0 + 30.0)
	_mist_v.position = Vector3(0, 1.2, 0)
	_mist_v.material = m
	add_child(_mist_v)


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
	if is_instance_valid(_mist_v):
		# The mist drifts, slowly, back and forth.
		_mist_v.position.x = sin(t * 0.05) * 6.0
		_mist_v.position.z = cos(t * 0.037) * 4.0
	while _torch_base.size() < _torches.size():
		_torch_base.append(-1.0)
	var near := cam.global_position if cam else Vector3.ZERO
	for i in _torches.size():
		# Lights of broken props are freed with them.
		if not is_instance_valid(_torches[i]):
			continue
		var l: OmniLight3D = _torches[i]
		if _torch_base[i] < 0.0:
			_torch_base[i] = l.light_energy
		# Only the ones in view flicker; the rest wait as they are.
		if cam and l.global_position.distance_squared_to(near) > 3600.0:
			continue
		l.light_energy = _torch_base[i] * (0.85 + 0.1 * sin(t * 9.0 + i * 1.7) + 0.05 * sin(t * 23.0 + i))


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


# The props' meshes: built in code once, a few variants of each, shared by
# every prop of that kind (a level places hundreds). Weathered materials,
# shaded darker towards the floor, so they sit in the light and don't read
# as painted toys.

static var _kit := {}


## [param make]'s result under [param key], made the first time it is asked.
static func _cached(key: String, make: Callable) -> Variant:
	if not _kit.has(key):
		_kit[key] = make.call()
	return _kit[key]


## A noise material stretched along a grain: [param axis] is noise tiles per
## metre in x, y and z, low along the grain (planks, staves, bark).
static func _grain(key: String, base: Color, dark: Color, axis: Vector3, rough := 0.85, bump := 0.9, seed := 1) -> StandardMaterial3D:
	return _cached("m" + key, func() -> StandardMaterial3D:
		var m: StandardMaterial3D = Shape.material(base, dark, 1.0, rough, bump, 0.0, seed).duplicate()
		m.uv1_scale = axis
		return m)


static func _iron() -> StandardMaterial3D:
	return Shape.material(Color(0.15, 0.14, 0.13), Color(0.05, 0.045, 0.04), 5.0, 0.55, 0.8, 0.55, 31)


static func _bark() -> StandardMaterial3D:
	return _grain("bark", Color(0.19, 0.16, 0.13), Color(0.06, 0.05, 0.045), Vector3(9, 1.6, 9), 0.95, 1.6, 11)


static func _moved(mesh: ArrayMesh, xf: Transform3D) -> ArrayMesh:
	return Shape.warp(mesh, func(p: Vector3) -> Vector3: return xf * p)


static func _at(mesh: ArrayMesh, off: Vector3) -> ArrayMesh:
	return Shape.warp(mesh, func(p: Vector3) -> Vector3: return p + off)


## Puts a [Shape.centered] piece back where it was made, scaled by
## [param scl]: as debris it tumbles round its own middle.
static func _put(parent: Node3D, piece: Array, mat: Material, scl := 1.0) -> MeshInstance3D:
	return Art.part(parent, piece[0], mat, (piece[1] as Vector3) * scl, Vector3.ZERO, Vector3.ONE * scl)


## A point [param t] (0 to 1) of the way along the polyline [param pts].
static func _along(pts: PackedVector3Array, t: float) -> Vector3:
	var f := clampf(t, 0.0, 1.0) * (pts.size() - 1)
	var i := mini(int(f), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], f - i)


## Flat-shaded triangles of a convex solid round [param mid], turned to face
## outwards: cut stone, crystal, planks.
static func _faceted(tris: PackedVector3Array, mid: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in range(0, tris.size(), 3):
		var a := tris[i]
		var b := tris[i + 1]
		var c := tris[i + 2]
		if (c - a).cross(b - a).dot((a + b + c) / 3.0 - mid) < 0.0:
			var t := b
			b = c
			c = t
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	st.generate_normals()
	return st.commit()


## [param outline] (convex, in xz) stood up from [param y0] to [param y1],
## its top edge chamfered [param bevel] in: a lid, a plank, a slab.
static func _prism(outline: PackedVector2Array, y0: float, y1: float, bevel := 0.0) -> ArrayMesh:
	var c := Vector2.ZERO
	for p in outline:
		c += p
	c /= outline.size()
	var n := outline.size()
	var ym := y1 - bevel
	var tris := PackedVector3Array()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var qa := a + (c - a).normalized() * bevel
		var qb := b + (c - b).normalized() * bevel
		tris.append_array(PackedVector3Array([Vector3(c.x, y0, c.y), Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y)]))
		tris.append_array(PackedVector3Array([Vector3(c.x, y1, c.y), Vector3(qa.x, y1, qa.y), Vector3(qb.x, y1, qb.y)]))
		tris.append_array(PackedVector3Array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, ym, b.y)]))
		tris.append_array(PackedVector3Array([Vector3(a.x, y0, a.y), Vector3(b.x, ym, b.y), Vector3(a.x, ym, a.y)]))
		if bevel > 0.0:
			tris.append_array(PackedVector3Array([Vector3(a.x, ym, a.y), Vector3(b.x, ym, b.y), Vector3(qb.x, y1, qb.y)]))
			tris.append_array(PackedVector3Array([Vector3(a.x, ym, a.y), Vector3(qb.x, y1, qb.y), Vector3(qa.x, y1, qa.y)]))
	return _faceted(tris, Vector3(c.x, (y0 + y1) * 0.5, c.y))


## A gnarled dead tree: [trunk and roots, branches], each centred.
static func _tree_kit(i: int) -> Array:
	return _cached("tree%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1009 + i * 77
		var h := rng.randf_range(2.3, 3.2)
		var lean := Vector3(rng.randf_range(0.3, 0.7), 0, 0).rotated(Vector3.UP, rng.randf() * TAU)
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		var n := 6
		for k in n:
			var t := float(k) / (n - 1)
			var wob := Vector3(rng.randf_range(-0.14, 0.14), 0, rng.randf_range(-0.14, 0.14)) * (0.3 + t) if k > 0 else Vector3.ZERO
			pts.append(Vector3(0, t * h, 0) + lean * t * t + wob)
			rad.append(lerpf(0.25, 0.05, pow(t, 0.75)))
		pts[0].y = -0.15
		var trunk := [Shape.limb(pts, rad, 9, 3)]
		# Roots flaring into the ground.
		var roots := rng.randi_range(4, 5)
		for k in roots:
			var a := TAU * k / roots + rng.randf_range(-0.35, 0.35)
			var d := Vector3(cos(a), 0, sin(a))
			var l := rng.randf_range(0.45, 0.85)
			trunk.append(Shape.limb(PackedVector3Array([d * 0.04 + Vector3.UP * 0.5, d * 0.24 + Vector3.UP * 0.12, d * l + Vector3.DOWN * 0.06]), PackedFloat32Array([0.13, 0.09, 0.02]), 5, 3))
		var tm := Shape.merge(trunk)
		# Knots and twists in the bark.
		var sd := rng.randf() * 10.0
		tm = Shape.warp(tm, func(p: Vector3) -> Vector3:
			return p + Vector3(sin(p.y * 7.0 + sd) * 0.025, 0, cos(p.y * 5.3 + sd) * 0.025))
		var limbs := []
		var nb := rng.randi_range(3, 5)
		for k in nb + 2:
			var top := k >= nb
			var t := 0.97 if top else rng.randf_range(0.4, 0.88)
			var o := _along(pts, t)
			var a := TAU * k / nb + rng.randf_range(-0.6, 0.6)
			var d := Vector3(cos(a), 0, sin(a))
			var up := rng.randf_range(0.25, 0.85) + (0.8 if top else 0.0)
			var l := rng.randf_range(0.75, 1.4) * (1.15 - t * 0.45) * (0.6 if top else 1.0)
			var r0 := lerpf(0.25, 0.05, pow(t, 0.75)) * (0.75 if top else 0.6)
			var bp := PackedVector3Array([o])
			for j in range(1, 4):
				var f := j / 3.0
				var jit := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6), rng.randf_range(-1, 1)) * 0.09 * f
				# Out first, then crooked up, a little droop at the tips.
				bp.append(o + d * l * f + Vector3.UP * l * up * f * (1.2 - f * 0.5) + jit)
			limbs.append(Shape.limb(bp, PackedFloat32Array([r0, r0 * 0.6, r0 * 0.35, 0.008]), 6, 2))
			for j: int in [1, 2]:
				var tw := bp[j]
				var td := (d.rotated(Vector3.UP, rng.randf_range(-1.3, 1.3)) + Vector3.UP * rng.randf_range(0.1, 0.9)).normalized()
				var tl := rng.randf_range(0.22, 0.45)
				var kink := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.04
				limbs.append(Shape.limb(PackedVector3Array([tw, tw + td * tl * 0.5 + kink, tw + td * tl]), PackedFloat32Array([r0 * 0.3, 0.01, 0.004]), 4, 2))
		var bm := Shape.merge(limbs)
		return [Shape.centered(Shape.ground(tm, 2.2, 0.35)), Shape.centered(Shape.ground(bm, h + 1.0, 0.6))])


## The iron lantern on its post: post and arm, the cage, the glass, the flame.
static func _lamp_kit() -> Dictionary:
	return _cached("lamp", func() -> Dictionary:
		var x := 0.42
		var post := Shape.lathe(PackedVector2Array([Vector2(0.13, 0.0), Vector2(0.12, 0.05), Vector2(0.065, 0.1), Vector2(0.05, 0.2), Vector2(0.04, 1.72), Vector2(0.055, 1.74), Vector2(0.055, 1.8), Vector2(0.03, 1.83), Vector2(0.0, 1.87)]), 8)
		var arm := Shape.limb(Shape.curve(Vector3(0, 1.76, 0), Vector3(0.25, 1.86, 0), Vector3(x + 0.03, 1.8, 0), 5), Shape.taper(0.022, 0.015, 5), 6, 2)
		var brace := Shape.limb(PackedVector3Array([Vector3(0.03, 1.42, 0), Vector3(0.1, 1.58, 0), Vector3(0.2, 1.71, 0), Vector3(0.27, 1.82, 0)]), Shape.taper(0.015, 0.012, 4), 5, 2)
		# A scroll curled under the arm.
		var curl := PackedVector3Array()
		for k in 7:
			var a := k * 0.9
			curl.append(Vector3(0.14 + cos(a) * 0.05 * (1.0 - k * 0.1), 1.66 + sin(a) * 0.05 * (1.0 - k * 0.1), 0))
		var scroll := Shape.limb(curl, Shape.taper(0.011, 0.007, 7), 4, 1)
		var hook := Shape.limb(PackedVector3Array([Vector3(x, 1.8, 0), Vector3(x, 1.72, 0)]), Shape.taper(0.009, 0.009, 2), 4, 1)
		var cage := []
		cage.append(Shape.lathe(PackedVector2Array([Vector2(0.0, 1.4), Vector2(0.05, 1.4), Vector2(0.085, 1.43), Vector2(0.088, 1.455), Vector2(0.0, 1.455)]), 10))
		for k in 4:
			var a := TAU * k / 4.0 + PI * 0.25
			var d := Vector3(cos(a), 0, sin(a)) * 0.08
			cage.append(Shape.limb(PackedVector3Array([d + Vector3.UP * 1.45, d * 1.08 + Vector3.UP * 1.55, d + Vector3.UP * 1.64]), Shape.taper(0.008, 0.008, 3), 4, 2))
		cage.append(Shape.lathe(PackedVector2Array([Vector2(0.0, 1.63), Vector2(0.1, 1.63), Vector2(0.105, 1.645), Vector2(0.06, 1.69), Vector2(0.025, 1.72), Vector2(0.025, 1.735), Vector2(0.012, 1.75), Vector2(0.0, 1.75)]), 10))
		var iron := Shape.ground(Shape.merge([post, arm, brace, scroll, hook, _at(Shape.merge(cage), Vector3(x, 0, 0))]), 1.8, 0.45)
		var glass := _at(Shape.lathe(PackedVector2Array([Vector2(0.074, 1.455), Vector2(0.078, 1.55), Vector2(0.074, 1.635)]), 10), Vector3(x, 0, 0))
		var flame := Shape.warp(Shape.blob(Vector3(0.022, 0.045, 0.022), 0.0, 1.0, 6, 8), func(p: Vector3) -> Vector3:
			var k := 1.0 - clampf(p.y / 0.045, -1.0, 1.0) * 0.45
			return Vector3(p.x * k + x, p.y + 1.515, p.z * k))
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.55, 0.33, 0.12, 0.35)
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.roughness = 0.15
		gm.emission_enabled = true
		gm.emission = Color(1.0, 0.55, 0.2)
		gm.emission_energy_multiplier = 0.7
		gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		return {iron = iron, glass = glass, flame = flame, glass_mat = gm})


## A cluster of melted candles: wax (with its puddle), wicks, flames and
## where each flame is, on a slab or not.
static func _candle_kit(i: int) -> Dictionary:
	return _cached("candles%d" % i, func() -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = 311 + i * 53
		var slab := i % 2 == 0
		var lift := 0.07 if slab else 0.0
		var wax := []
		var wicks := []
		var flames := []
		var tops := PackedVector3Array()
		var n := rng.randi_range(4, 7)
		var spots: Array[Vector2] = []
		for k in n:
			var at := Vector2.ZERO
			for _t in 12:
				at = Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.24, 0.24))
				var ok := true
				for s in spots:
					if s.distance_to(at) < 0.1:
						ok = false
				if ok:
					break
			spots.append(at)
			var r := rng.randf_range(0.022, 0.042)
			var h := rng.randf_range(0.06, 0.2) if k > 1 else rng.randf_range(0.28, 0.42)
			var base := Vector3(at.x, lift, at.y)
			var prof := PackedVector2Array([Vector2(r * 1.9, -0.004), Vector2(r * 1.5, 0.006), Vector2(r * 1.2, 0.016), Vector2(r * 1.08, 0.03), Vector2(r, h * 0.4), Vector2(r * 1.04, h * 0.75), Vector2(r * 0.97, h - 0.012), Vector2(r * 0.88, h), Vector2(r * 0.5, h - 0.006), Vector2(0.0, h - 0.009)])
			wax.append(_at(Shape.lathe(prof, 8), base))
			for _d in rng.randi_range(1, 3):
				var a := rng.randf() * TAU
				var dir := Vector3(cos(a), 0, sin(a))
				var dl := rng.randf_range(0.02, minf(h * 0.7, 0.14))
				wax.append(Shape.limb(PackedVector3Array([base + dir * r * 0.95 + Vector3.UP * (h - 0.004), base + dir * r * 1.02 + Vector3.UP * (h - dl * 0.5), base + dir * r * 1.05 + Vector3.UP * (h - dl)]), PackedFloat32Array([0.006, 0.007, 0.009]), 4, 1))
			var lean := Vector3(rng.randf_range(-0.004, 0.004), 0, rng.randf_range(-0.004, 0.004))
			wicks.append(Shape.limb(PackedVector3Array([base + Vector3.UP * (h - 0.012), base + Vector3.UP * (h + 0.014) + lean]), PackedFloat32Array([0.003, 0.0025]), 3, 1))
			var top := base + Vector3.UP * (h + 0.038) + lean
			tops.append(top)
			flames.append(Shape.warp(Shape.blob(Vector3(0.011, 0.026, 0.011), 0.0, 1.0, 5, 6), func(p: Vector3) -> Vector3:
				var kk := 1.0 - clampf(p.y / 0.026, -1.0, 1.0) * 0.5
				return Vector3(p.x * kk, p.y, p.z * kk) + top))
		var out := {wax = Shape.ground(Shape.merge(wax), 0.4, 0.6), wick = Shape.merge(wicks), flame = Shape.merge(flames), tops = tops}
		if slab:
			out.slab = Shape.ground(Shape.blob(Vector3(0.44, 0.07, 0.36), 0.1, i * 1.3 + 4.0, 6, 14), 0.07, 0.5)
		return out)


## One long bone along x, knobbed at both ends.
static func _bone(l: float, r: float, seed: float) -> ArrayMesh:
	var hl := l * 0.5
	var parts := [Shape.limb(PackedVector3Array([Vector3(-hl, 0, 0), Vector3(-hl + r * 2.0, 0, 0), Vector3(0, 0, 0), Vector3(hl - r * 2.0, 0, 0), Vector3(hl, 0, 0)]), PackedFloat32Array([r * 1.35, r * 0.95, r * 0.75, r * 0.95, r * 1.35]), 6, 2)]
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			parts.append(_at(Shape.blob(Vector3.ONE * r * 1.2, 0.08, seed + sx + sz * 2.0, 4, 6), Vector3(sx * (hl + r * 0.2), r * 0.1, sz * r * 0.75)))
	return Shape.merge(parts)


## A skull facing +z, resting on the floor: [bone, eye sockets].
static func _skull(seed: float) -> Array:
	var bone := [
		_at(Shape.blob(Vector3(0.082, 0.085, 0.11), 0.03, seed, 8, 12), Vector3(0, 0.1, -0.01)),
		_at(Shape.blob(Vector3(0.068, 0.05, 0.055), 0.04, seed + 2.0, 6, 10), Vector3(0, 0.055, 0.072)),
		_at(Shape.blob(Vector3(0.075, 0.022, 0.03), 0.0, 1.0, 4, 10), Vector3(0, 0.112, 0.09)),
		Shape.limb(Shape.curve(Vector3(-0.058, 0.05, 0.0), Vector3(0, 0.0, 0.16), Vector3(0.058, 0.05, 0.0), 5), Shape.taper(0.016, 0.016, 5), 5, 2),
	]
	var holes := [
		_at(Shape.blob(Vector3(0.026, 0.024, 0.02), 0.0, 1.0, 5, 8), Vector3(-0.032, 0.083, 0.112)),
		_at(Shape.blob(Vector3(0.026, 0.024, 0.02), 0.0, 1.0, 5, 8), Vector3(0.032, 0.083, 0.112)),
		_at(Shape.blob(Vector3(0.011, 0.017, 0.01), 0.0, 1.0, 4, 6), Vector3(0, 0.05, 0.124)),
	]
	return [Shape.merge(bone), Shape.merge(holes)]


## A scatter of old bones: [bones, eye sockets].
static func _bones_kit(i: int) -> Array:
	return _cached("bones%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 733 + i * 31
		var parts := []
		for k in rng.randi_range(4, 7):
			var l := rng.randf_range(0.22, 0.48)
			var r := l * rng.randf_range(0.05, 0.065)
			var y := r * 1.3 + (r * 1.8 if k > 2 and rng.randf() < 0.4 else 0.0)
			var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, rng.randf_range(-0.08, 0.08)), Vector3(rng.randf_range(-0.42, 0.42), y, rng.randf_range(-0.42, 0.42)))
			parts.append(_moved(_bone(l, r, k * 1.7 + i), xf))
		# A few ribs, curved, lying on their sides.
		var rib_at := Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
		var rib_yaw := rng.randf() * TAU
		for k in rng.randi_range(2, 4):
			var o := Vector3(0, 0.012, k * 0.07)
			parts.append(_moved(Shape.limb(Shape.curve(o + Vector3(-0.17, 0, 0), o + Vector3(0, 0.05, 0.12), o + Vector3(0.17, 0, 0.02), 5), Shape.taper(0.012, 0.007, 5), 4, 2), Transform3D(Basis(Vector3.UP, rib_yaw), rib_at)))
		var holes: ArrayMesh = null
		if i % 3 != 2:
			var sk := _skull(i * 3.1)
			var sxf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.7, -0.35)) * Basis(Vector3.FORWARD, rng.randf_range(-0.3, 0.3)), Vector3(rng.randf_range(-0.3, 0.3), 0.02, rng.randf_range(-0.3, 0.3)))
			parts.append(_moved(sk[0], sxf))
			holes = _moved(sk[1], sxf)
		return [Shape.ground(Shape.merge(parts), 0.2, 0.55), holes])


const _COFFIN := [Vector2(-0.2, -0.95), Vector2(0.2, -0.95), Vector2(0.34, 0.42), Vector2(0.26, 0.95), Vector2(-0.26, 0.95), Vector2(-0.34, 0.42)]


## The coffin's lid with its raised cross, its floor, its handles and the
## dark inside, each made once.
static func _coffin_kit() -> Dictionary:
	return _cached("coffin", func() -> Dictionary:
		var big := PackedVector2Array()
		var inner := PackedVector2Array()
		for p: Vector2 in _COFFIN:
			big.append(p * 1.05)
			inner.append(p * 0.86)
		var lid := Shape.merge([
			_prism(big, 0.0, 0.07, 0.03),
			_prism(PackedVector2Array([Vector2(-0.03, -0.55), Vector2(0.03, -0.55), Vector2(0.03, 0.75), Vector2(-0.03, 0.75)]), 0.06, 0.085, 0.01),
			_prism(PackedVector2Array([Vector2(-0.17, 0.42), Vector2(0.17, 0.42), Vector2(0.17, 0.48), Vector2(-0.17, 0.48)]), 0.06, 0.085, 0.01),
		])
		var handles := []
		for e: Array in [[1, 2], [5, 0]]:
			var a: Vector2 = _COFFIN[e[0]]
			var b: Vector2 = _COFFIN[e[1]]
			var out := (a - b).orthogonal().normalized()
			if out.dot((a + b) * 0.5) < 0.0:
				out = -out
			for t: float in [0.3, 0.7]:
				var q := a.lerp(b, t) + out * 0.04
				var along := (b - a).normalized() * 0.07
				var p0 := Vector3(q.x - along.x, 0.3, q.y - along.y)
				var p1 := Vector3(q.x + along.x, 0.3, q.y + along.y)
				var mid := (p0 + p1) * 0.5 + Vector3(out.x, 0, out.y) * 0.03 + Vector3.DOWN * 0.07
				handles.append(Shape.limb(Shape.curve(p0, mid, p1, 5), Shape.taper(0.011, 0.011, 5), 4, 2))
		return {lid = Shape.ground(lid, 0.08, 0.7), floor = _prism(PackedVector2Array(_COFFIN), 0.0, 0.05), hollow = _prism(inner, 0.33, 0.36), handles = Shape.merge(handles)})


## A turned clay jar in three pieces (foot, belly, neck), centred, and
## how high its mouth is. [param blood]: the squat glazed one.
static func _urn_kit(i: int, blood: bool) -> Dictionary:
	return _cached("urn%d%s" % [i, blood], func() -> Dictionary:
		var sx: float = [1.0, 0.92, 1.08][i % 3]
		var sy: float = [1.0, 1.1, 0.9][i % 3]
		var prof: Array
		if blood:
			prof = [Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.115, 0.025), Vector2(0.1, 0.05), Vector2(0.19, 0.13), Vector2(0.225, 0.24), Vector2(0.205, 0.34), Vector2(0.15, 0.42), Vector2(0.12, 0.47), Vector2(0.125, 0.53), Vector2(0.155, 0.56), Vector2(0.145, 0.58), Vector2(0.115, 0.565)]
		else:
			prof = [Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.105, 0.03), Vector2(0.085, 0.06), Vector2(0.165, 0.16), Vector2(0.21, 0.28), Vector2(0.195, 0.38), Vector2(0.13, 0.47), Vector2(0.08, 0.52), Vector2(0.078, 0.57), Vector2(0.11, 0.6), Vector2(0.102, 0.62), Vector2(0.074, 0.6)]
		var pp := PackedVector2Array()
		for v: Vector2 in prof:
			pp.append(Vector2(v.x * sx, v.y * sy))
		var cuts := [[0, 5], [5, 8], [8, pp.size() - 1]]
		var pieces := []
		for c: Array in cuts:
			var sub := pp.slice(c[0], c[1] + 1)
			pieces.append(Shape.centered(Shape.ground(Shape.lathe(sub, 16), 0.6, 0.5)))
		# A painted band round the belly.
		var band := Shape.lathe(PackedVector2Array([pp[5] + Vector2(0.004, -0.03 * sy), pp[5] + Vector2(0.006, 0.0), pp[5] + Vector2(0.004, 0.03 * sy)]), 16)
		var top: Vector2 = pp[pp.size() - 1]
		return {pieces = pieces, band = band, mouth = top.y, mouth_r = top.x})


static func _keg_r(y: float) -> float:
	# The barrel's bulge: 0.215 at the ends, 0.275 in the middle.
	return 0.215 + 0.06 * sin(clampf(y / 0.62, 0.0, 1.0) * PI)


## The powder keg: [lower staves, upper staves, hoops, lid], centred.
static func _keg_kit() -> Array:
	return _cached("keg", func() -> Array:
		var lo := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.215, 0.012)])
		var hi := PackedVector2Array()
		for k in 7:
			var y := 0.012 + k * (0.298 / 6.0)
			lo.append(Vector2(_keg_r(y), y))
		for k in 7:
			var y := 0.31 + k * (0.298 / 6.0)
			hi.append(Vector2(_keg_r(y), y))
		hi.append(Vector2(0.2, 0.62))
		hi.append(Vector2(0.19, 0.6))
		var hoops := []
		for y: float in [0.05, 0.17, 0.45, 0.57]:
			var r := _keg_r(y) + 0.004
			hoops.append(Shape.lathe(PackedVector2Array([Vector2(r, y - 0.022), Vector2(r + 0.009, y - 0.016), Vector2(r + 0.009, y + 0.016), Vector2(r, y + 0.022)]), 18))
		var lid := Shape.lathe(PackedVector2Array([Vector2(0.19, 0.585), Vector2(0.18, 0.595), Vector2(0.0, 0.595)]), 16)
		return [Shape.centered(Shape.ground(Shape.lathe(lo, 32, 16, 0.012), 0.62, 0.45)), Shape.centered(Shape.ground(Shape.lathe(hi, 32, 16, 0.01), 0.62, 0.45)),
			Shape.centered(Shape.ground(Shape.merge(hoops), 0.62, 0.5)), Shape.centered(lid)])


## The weeping angel above its plinth (from 0.7 m up): [robe, head and arms,
## left wing, right wing], centred.
static func _angel_kit() -> Array:
	return _cached("angel", func() -> Array:
		var b := 0.7
		var robe := Shape.lathe(PackedVector2Array([Vector2(0.31, b), Vector2(0.32, b + 0.05), Vector2(0.28, b + 0.4), Vector2(0.21, b + 0.75), Vector2(0.17, b + 0.95), Vector2(0.2, b + 1.1), Vector2(0.18, b + 1.18), Vector2(0.09, b + 1.24), Vector2(0.0, b + 1.27)]), 18, 9, 0.12)
		var upper := [
			# A hooded head bowed into its hands.
			_at(Shape.blob(Vector3(0.11, 0.125, 0.115), 0.05, 2.0, 8, 12), Vector3(0, b + 1.37, 0.05)),
			_at(Shape.blob(Vector3(0.13, 0.08, 0.12), 0.08, 5.0, 6, 10), Vector3(0, b + 1.28, 0.0)),
		]
		for sx: float in [-1.0, 1.0]:
			upper.append(Shape.limb(PackedVector3Array([Vector3(sx * 0.17, b + 1.16, 0.0), Vector3(sx * 0.21, b + 1.02, 0.15), Vector3(sx * 0.07, b + 1.3, 0.17)]), PackedFloat32Array([0.07, 0.055, 0.045]), 7, 3))
			upper.append(_at(Shape.blob(Vector3(0.045, 0.06, 0.03), 0.1, 3.0 + sx, 5, 8), Vector3(sx * 0.045, b + 1.37, 0.15)))
		var wings := []
		for sx: float in [-1.0, 1.0]:
			# Folded wings behind it, rising over the head and trailing down,
			# in two layers of feathers.
			var w := []
			for layer in 2:
				var len := 0.62 - layer * 0.18
				var feather := Shape.blob(Vector3(0.05, len, 0.2 - layer * 0.03), 0.1, 7.0 + layer + sx, 10, 10)
				feather = Shape.warp(feather, func(p: Vector3) -> Vector3:
					var t := (p.y + len) / (2.0 * len)
					return Vector3(p.x + 0.12 * t * t, p.y, p.z - 0.1 * t * t + 0.05 * sin(p.y * 9.0) * (1.0 - t)))
				var xf := Transform3D(Basis(Vector3.UP, sx * -0.45) * Basis(Vector3.FORWARD, sx * -0.28), Vector3(sx * 0.2, b + 1.0 + layer * 0.12, -0.17 - layer * 0.03))
				if sx < 0.0:
					feather = Shape.warp(feather, func(p: Vector3) -> Vector3: return Vector3(-p.x, p.y, p.z))
					xf = Transform3D(Basis(Vector3.UP, 0.45) * Basis(Vector3.FORWARD, 0.28), Vector3(-0.2, b + 1.0 + layer * 0.12, -0.17 - layer * 0.03))
				w.append(_moved(feather, xf))
			wings.append(Shape.centered(Shape.ground(Shape.merge(w), 2.4, 0.6)))
		return [Shape.centered(Shape.ground(robe, 2.0, 0.45)), Shape.centered(Shape.ground(Shape.merge(upper), 2.2, 0.6)), wings[0], wings[1]])


## A knight lying in stone on a sarcophagus lid (lid top at y 0), centred.
static func _effigy() -> Array:
	return _cached("effigy", func() -> Array:
		var body := Shape.limb(PackedVector3Array([Vector3(0, 0, 0.62), Vector3(0, 0, 0.48), Vector3(0, 0, 0.1), Vector3(0, 0, -0.4), Vector3(0, 0, -0.78), Vector3(0, 0, -0.9)]), PackedFloat32Array([0.07, 0.21, 0.18, 0.17, 0.13, 0.08]), 10, 3)
		body = Shape.warp(body, func(p: Vector3) -> Vector3: return Vector3(p.x, maxf(p.y, -0.02) * 0.45 + 0.03, p.z))
		var parts := [body,
			_at(Shape.blob(Vector3(0.095, 0.08, 0.11), 0.04, 3.0, 7, 10), Vector3(0, 0.1, 0.78)),
			_prism(PackedVector2Array([Vector2(-0.2, 0.68), Vector2(0.2, 0.68), Vector2(0.2, 0.92), Vector2(-0.2, 0.92)]), 0.0, 0.06, 0.02),
			_at(Shape.blob(Vector3(0.06, 0.045, 0.07), 0.1, 4.0, 5, 8), Vector3(0, 0.15, 0.22)),
			Shape.limb(PackedVector3Array([Vector3(0, 0.14, 0.3), Vector3(0, 0.14, -0.62)]), Shape.taper(0.018, 0.012, 2), 4, 1),
			Shape.limb(PackedVector3Array([Vector3(-0.09, 0.14, 0.16), Vector3(0.09, 0.14, 0.16)]), Shape.taper(0.014, 0.014, 2), 4, 1),
		]
		for sx: float in [-1.0, 1.0]:
			# Arms folded over the sword.
			parts.append(Shape.limb(PackedVector3Array([Vector3(sx * 0.19, 0.07, 0.44), Vector3(sx * 0.17, 0.09, 0.22), Vector3(sx * 0.04, 0.14, 0.2)]), PackedFloat32Array([0.05, 0.045, 0.035]), 6, 2))
		return Shape.centered(Shape.merge(parts)))


## The iron brazier: [bowl, legs and ring, coals, embers], centred.
static func _brazier_kit() -> Array:
	return _cached("brazier", func() -> Array:
		var bowl := Shape.lathe(PackedVector2Array([Vector2(0.0, 0.86), Vector2(0.16, 0.87), Vector2(0.34, 0.95), Vector2(0.45, 1.08), Vector2(0.48, 1.13), Vector2(0.455, 1.135), Vector2(0.42, 1.1), Vector2(0.32, 1.01), Vector2(0.0, 0.98)]), 14)
		var legs := []
		var ring := PackedVector3Array()
		for k in 3:
			var a := TAU * k / 3.0
			var d := Vector3(cos(a), 0, sin(a))
			legs.append(Shape.limb(PackedVector3Array([d * 0.3 + Vector3.UP * 1.0, d * 0.4 + Vector3.UP * 0.6, d * 0.33 + Vector3.UP * 0.15, d * 0.46 + Vector3.UP * 0.03]), PackedFloat32Array([0.034, 0.03, 0.028, 0.045]), 6, 3))
		for k in 13:
			var a := TAU * k / 12.0
			ring.append(Vector3(cos(a) * 0.37, 0.45, sin(a) * 0.37))
		legs.append(Shape.limb(ring, Shape.taper(0.016, 0.016, 13), 4, 2))
		var coals := []
		var embers := []
		var rng := RandomNumberGenerator.new()
		rng.seed = 97
		for k in 11:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * 0.3
			var p := Vector3(cos(a) * r, 1.02 + rng.randf() * 0.04, sin(a) * r)
			var m := Shape.blob(Vector3.ONE * rng.randf_range(0.06, 0.1) * Vector3(1, 0.7, 1), 0.2, k * 1.3, 5, 7)
			(embers if k % 3 == 0 else coals).append(_at(m, p))
		var iron := Shape.material(Color(0.17, 0.13, 0.1), Color(0.06, 0.045, 0.035), 4.0, 0.7, 0.9, 0.45, 33)
		return [Shape.centered(Shape.ground(bowl, 1.1, 0.6)), Shape.centered(Shape.ground(Shape.merge(legs), 1.0, 0.4)), Shape.centered(Shape.merge(coals)), Shape.centered(Shape.merge(embers)), iron])


## A crystal of ice: an uneven six-sided prism with a pointed tip, base
## buried below 0, [param h] tall.
static func _shard(i: int) -> ArrayMesh:
	return _cached("shard%d" % i, func() -> ArrayMesh:
		var rng := RandomNumberGenerator.new()
		rng.seed = 51 + i * 13
		var r := rng.randf_range(0.12, 0.22)
		var h := 1.0
		var shoulder := rng.randf_range(0.62, 0.8)
		var tip := Vector3(rng.randf_range(-0.04, 0.04), h, rng.randf_range(-0.04, 0.04))
		var lo := PackedVector3Array()
		var hi := PackedVector3Array()
		for k in 6:
			var a := TAU * k / 6.0 + rng.randf_range(-0.12, 0.12)
			var rr := r * rng.randf_range(0.8, 1.15)
			lo.append(Vector3(cos(a) * rr, -0.15, sin(a) * rr))
			hi.append(Vector3(cos(a) * rr * 0.85, h * shoulder + rng.randf_range(-0.06, 0.06), sin(a) * rr * 0.85))
		var tris := PackedVector3Array()
		for k in 6:
			var j := (k + 1) % 6
			tris.append_array(PackedVector3Array([lo[k], lo[j], hi[j], lo[k], hi[j], hi[k], hi[k], hi[j], tip]))
		return _faceted(tris, Vector3(0, h * 0.4, 0)))


static func _ice_mat() -> StandardMaterial3D:
	return _cached("mice", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.4, 0.52, 0.62, 0.82)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.12
		m.metallic = 0.15
		m.metallic_specular = 0.8
		m.emission_enabled = true
		m.emission = Color(0.07, 0.13, 0.19)
		m.rim_enabled = true
		m.rim = 0.5
		m.rim_tint = 0.4
		return m)


## A clump of reeds: [stalks, seed heads].
static func _reed_kit(i: int) -> Array:
	return _cached("reeds%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 211 + i * 19
		var stalks := []
		var heads := []
		for k in 22:
			var a := rng.randf() * TAU
			var o := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * 0.55
			var h := rng.randf_range(0.6, 1.4)
			var bend := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.05, 0.25) * h
			var pts := Shape.curve(o + Vector3.DOWN * 0.05, o + bend * 0.2 + Vector3.UP * h * 0.55, o + bend + Vector3.UP * h, 4)
			stalks.append(Shape.limb(pts, PackedFloat32Array([0.02, 0.015, 0.008, 0.0]), 3, 2))
			if k % 4 == 0:
				var hp := _along(pts, 0.78)
				var hd := (_along(pts, 0.9) - hp).normalized()
				heads.append(Shape.limb(PackedVector3Array([hp, hp + hd * 0.14]), Shape.taper(0.026, 0.024, 2), 5, 1))
		return [Shape.ground(Shape.merge(stalks), 1.2, 0.35), Shape.merge(heads)])


## A clump of pale cave fungus: [stems, caps].
static func _shroom_kit(i: int) -> Array:
	return _cached("shroom%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 401 + i * 23
		var stems := []
		var caps := []
		for k in rng.randi_range(3, 6):
			var a := rng.randf() * TAU
			var o := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.0, 0.4)
			var s := rng.randf_range(0.5, 1.2) if k > 0 else 1.5
			var h := 0.42 * s * rng.randf_range(0.7, 1.1)
			var lean := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.02, 0.1) * s
			var top := o + lean + Vector3.UP * h
			stems.append(Shape.limb(PackedVector3Array([o + Vector3.DOWN * 0.02, o + lean * 0.3 + Vector3.UP * h * 0.5, top]), PackedFloat32Array([0.035 * s, 0.022 * s, 0.025 * s]), 6, 2))
			var cs := 0.12 * s
			var cap := Shape.lathe(PackedVector2Array([Vector2(0.02 * s, -0.01 * s), Vector2(cs * 0.7, -0.005 * s), Vector2(cs, -0.02 * s), Vector2(cs * 1.02, 0.0), Vector2(cs * 0.85, 0.045 * s), Vector2(cs * 0.45, 0.08 * s), Vector2(0.0, 0.09 * s)]), 14, 7, 0.025)
			caps.append(_moved(cap, Transform3D(Basis(lean.cross(Vector3.UP).normalized() if lean.length() > 0.001 else Vector3.RIGHT, -lean.length() * 1.5), top)))
		return [Shape.ground(Shape.merge(stems), 0.4, 0.4), Shape.merge(caps)])


## A dripping stalagmite with its little one beside it: [big, small],
## centred, [param i] picking the height.
static func _stalag_kit(i: int) -> Array:
	return _cached("stalag%d" % i, func() -> Array:
		var out := []
		for part in 2:
			var h: float = [1.3, 1.8, 2.3, 2.8][i % 4] * (1.0 if part == 0 else 0.55)
			var r := 0.5 if part == 0 else 0.3
			var prof := PackedVector2Array([Vector2(r * 1.15, -0.05), Vector2(r * 0.9, h * 0.1), Vector2(r * 0.68, h * 0.3), Vector2(r * 0.45, h * 0.55), Vector2(r * 0.22, h * 0.8), Vector2(r * 0.07, h * 0.96), Vector2(0.0, h)])
			var m := Shape.lathe(prof, 12, 7, 0.1)
			var sd := i * 2.3 + part
			m = Shape.warp(m, func(p: Vector3) -> Vector3:
				return p + Vector3(sin(p.y * 3.1 + sd) * 0.05, 0, cos(p.y * 2.7 + sd) * 0.05) * (p.y / h))
			if part == 1:
				m = _at(m, Vector3(0.45, 0, 0.2))
			out.append(Shape.centered(m))
		return out)

class_name Dressing
## The things that make each biome feel like its place, beyond the common
## props in Arena._prop: iron fences and mausoleums in the graveyard, skull
## niches and chains in the catacombs, rotten pilings in the sunken isles,
## crystals and mine timbers in the caves, banners and racks in the keep,
## spikes and cages in the pit. Meshes are built once and shared.
##
## Things that stand against a wall are built with their back at local -z
## and their face towards +z; a fence section runs along x.

## kind -> one line on what it is.
const KINDS := {
	# The forsaken chapel's graveyard.
	fence = "a wrought iron fence section between two stone posts, some bars bent or gone",
	mausoleum = "a small stone crypt with a pediment roof, an iron door ajar and a step",
	cross = "a weathered stone grave cross, celtic or plain, leaning",
	ruin_wall = "a broken chapel wall with a pointed gothic window arch",
	# The catacombs.
	skull_niche = "an ossuary shelf: a stone frame stacked with skulls and long-bone ends",
	bone_pile = "a heap of skulls and bones on a mound of bone dust",
	chains = "chains hanging from an iron wall ring, one ending in shackles",
	cobweb = "faint sheets of old cobweb in the angle of a wall",
	altar = "a stone altar under a dark cloth with guttering candles and a skull",
	# The sunken isles.
	piling = "rotten wooden posts sticking up out of the water at angles",
	boat = "a half-sunk rowboat, tilted, with a broken oar",
	sunken_ruin = "mossy fluted column stumps and a toppled drum",
	lily = "a cluster of floating lily pads with a pale flower or two",
	hanging_moss_tree = "a drowned dead tree hung with strands of grey moss",
	# The caves.
	crystal = "dim teal or violet crystals growing out of a rock, faintly lit",
	mine_support = "a mine's timber frame: two posts, a beam and braces",
	mine_cart = "a rusty ore cart on a short piece of rail",
	fungus_shelf = "bracket fungi growing in tiers from a rock",
	drip_pool = "a shallow dark pool ringed with wet stones",
	# The frozen keep.
	banner = "a tattered, frosted banner on a standing pole",
	weapon_rack = "a frosted rack of spears and swords with a shield",
	snowdrift = "a soft wind-shaped heap of snow",
	frozen_statue = "a stone knight on a plinth, rimed with frost and icicles",
	barricade = "a broken wooden barricade, frosted, snow banked at its foot",
	icicle_rock = "an overhanging rock capped with snow, icicles hanging off it",
	# The infernal pit.
	spikes = "a cluster of iron and bone spikes, a skull impaled on one",
	cage = "a gibbet cage with a skeleton, hung from a charred post",
	chains_pit = "chains running from a charred stake to the ground",
	skull_pile = "a heap of charred skulls, embers in some of the sockets",
	obsidian_spire = "a jagged black glassy spire with glowing cracks",
	lava_vent = "a cracked mound with a molten core, smoke and embers",
}


## Build [param kind] under [param body] (a Prop at the spot, already turned
## at random). Returns {r = collision radius, or < 0 for walk-through}.
static func build(kind: String, body: Node3D, rng: RandomNumberGenerator, biome: Dictionary) -> Dictionary:
	var wall: Color = biome.get("wall", Color(0.25, 0.24, 0.23))
	var moss: float = biome.get("moss", 0.0)
	var moss_c: Color = biome.get("moss_c", Color(0.12, 0.16, 0.08))
	var stone := Art.stone(wall, moss, moss_c)
	match kind:
		"fence": return _fence(body, rng, stone)
		"mausoleum": return _mausoleum(body, rng, stone, wall, moss_c)
		"cross": return _cross(body, rng, wall, moss, moss_c)
		"ruin_wall": return _ruin_wall(body, rng, Art.stone(wall.darkened(0.05), moss, moss_c))
		"skull_niche": return _skull_niche(body, rng, wall, moss, moss_c)
		"bone_pile": return _bone_pile(body, rng)
		"chains": return _chains(body, rng)
		"cobweb": return _cobweb(body, rng)
		"altar": return _altar(body, rng, stone)
		"piling": return _piling(body, rng)
		"boat": return _boat(body, rng)
		"sunken_ruin": return _sunken_ruin(body, rng, wall, moss_c)
		"lily": return _lily(body, rng)
		"hanging_moss_tree": return _moss_tree(body, rng)
		"crystal": return _crystal(body, rng, stone)
		"mine_support": return _mine_support(body, rng)
		"mine_cart": return _mine_cart(body, rng, stone)
		"fungus_shelf": return _fungus_shelf(body, rng, stone)
		"drip_pool": return _drip_pool(body, rng, wall)
		"banner": return _banner(body, rng)
		"weapon_rack": return _weapon_rack(body, rng)
		"snowdrift": return _snowdrift(body, rng)
		"frozen_statue": return _frozen_statue(body, rng, stone)
		"barricade": return _barricade(body, rng)
		"icicle_rock": return _icicle_rock(body, rng, stone)
		"spikes": return _spikes(body, rng)
		"cage": return _cage(body, rng)
		"chains_pit": return _chains_pit(body, rng)
		"skull_pile": return _skull_pile(body, rng)
		"obsidian_spire": return _obsidian_spire(body, rng)
		"lava_vent": return _lava_vent(body, rng)
	return {r = -1.0}


# --- The chapel's graveyard --------------------------------------------------


static func _fence(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	var k: Array = _fence_kit(rng.randi() % 4)
	for sx: float in [-1.25, 1.25]:
		Art.part(body, _box(0.3, 1.25, 0.3), stone, Vector3(sx, 0.625, 0))
		Art.part(body, _box(0.38, 0.08, 0.38), stone, Vector3(sx, 1.29, 0))
		Art.part(body, _cyl(0.0, 0.26, 0.16, 4), stone, Vector3(sx, 1.41, 0), Vector3(0, 45, 0))
	Art.part(body, _box(2.2, 0.16, 0.22), stone, Vector3(0, 0.08, 0))
	for pc: Array in k:
		_put(body, pc, _iron())
	return {r = 0.3}


## Iron between the posts, in two halves (centred): rails, bars with spear
## tips, some bent, a couple gone.
static func _fence_kit(i: int) -> Array:
	return _cached("fence%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9001 + i * 37
		var halves := [[], []]
		var sag := rng.randf_range(0.0, 0.12) if i % 2 == 1 else 0.0
		for h in 2:
			var xa := -1.1 if h == 0 else 0.0
			var xb := 0.0 if h == 0 else 1.1
			for y: float in [0.3, 1.02]:
				var drop := sag if (h == 1 and y > 1.0) else 0.0
				halves[h].append(Shape.limb(PackedVector3Array([Vector3(xa, y, 0), Vector3(xb, y - drop, 0)]), Shape.taper(0.018, 0.018, 2), 4, 1))
		var n := 15
		for b in n:
			var x := lerpf(-1.02, 1.02, float(b) / (n - 1))
			if rng.randf() < 0.1:
				continue
			var h2 := 0 if x < 0.0 else 1
			var top := 1.3 + (0.04 if b % 2 == 0 else 0.0)
			var bend := rng.randf() < 0.22
			var mid := Vector3(x, 0.7, 0)
			var end := Vector3(x, top, 0)
			if bend:
				mid += Vector3(rng.randf_range(-0.05, 0.05), 0, rng.randf_range(-0.16, 0.16))
				end += Vector3(rng.randf_range(-0.12, 0.12), -rng.randf_range(0.05, 0.2), mid.z * 1.8)
			var pts := Shape.curve(Vector3(x, 0.14, 0), mid, end, 4)
			halves[h2].append(Shape.limb(pts, Shape.taper(0.013, 0.012, 4), 4, 1))
			var dir := (pts[3] - pts[2]).normalized()
			var tip := Shape.lathe(PackedVector2Array([Vector2(0.012, 0.0), Vector2(0.032, 0.04), Vector2(0.014, 0.1), Vector2(0.0, 0.135)]), 4)
			halves[h2].append(_moved(tip, Transform3D(Basis(Quaternion(Vector3.UP, dir)), pts[3])))
		var out := []
		for hv: Array in halves:
			out.append(Shape.centered(Shape.ground(Shape.merge(hv), 1.3, 0.6)))
		return out)


static func _mausoleum(body: Node3D, rng: RandomNumberGenerator, stone: Material, wall: Color, moss_c: Color) -> Dictionary:
	stone = Art.stone(wall.darkened(0.08), 0.6, moss_c)
	var heavy := Art.stone(wall.darkened(0.15), 0.85, moss_c)
	var dark_stone := Art.stone(wall.darkened(0.2), 0.3, moss_c)
	# Platform and step.
	Art.part(body, _box(2.6, 0.22, 2.9), dark_stone, Vector3(0, 0.11, -0.1))
	Art.part(body, _box(1.4, 0.11, 0.36), dark_stone, Vector3(0, 0.055, 1.52))
	# The house: walls, corner pilasters, a cornice.
	Art.part(body, _box(2.0, 1.9, 2.3), stone, Vector3(0, 1.17, -0.15))
	for sx: float in [-1.0, 1.0]:
		for z: float in [1.04, -1.34]:
			Art.part(body, _box(0.24, 1.9, 0.14), stone, Vector3(sx * 0.92, 1.17, z))
	Art.part(body, _box(2.3, 0.16, 2.62), heavy, Vector3(0, 2.2, -0.15))
	# Gable, then the roof slabs over it.
	var k: Dictionary = _mausoleum_kit()
	Art.part(body, k.gable, stone)
	# The roof in four courses of stone slates a side, each lapping over the
	# one below, a slate or two slipped.
	var slates := [Art.stone(wall.darkened(0.05), 0.45, moss_c), Art.stone(wall.darkened(0.32), 0.45, moss_c)]
	var slope := deg_to_rad(26.0)
	var run := 1.36 / cos(slope)
	for sx: float in [-1.0, 1.0]:
		var down := Vector3(sx * cos(slope), -sin(slope), 0)
		var up_n := Vector3(sx * sin(slope), cos(slope), 0)
		for c in 4:
			var d := (c + 0.5) * run / 4.0
			var at := Vector3(0, 2.86, -0.15) + down * d + up_n * (0.02 + c * 0.035)
			var slip := Vector3(0, 0, rng.randf_range(-0.12, 0.12)) if rng.randf() < 0.15 else Vector3.ZERO
			Art.part(body, _box(run / 4.0 + 0.1, 0.07, 2.78), slates[c % 2], at + slip, Vector3(0, 0, -sx * (26.0 - 6.0)))
	Art.part(body, _box(0.12, 0.12, 2.8), heavy, Vector3(0, 2.86, -0.15))
	# A round window in the pediment, dark.
	Art.part(body, _cyl(0.13, 0.13, 0.04, 12), _dark(), Vector3(0, 2.48, 1.06), Vector3(90, 0, 0))
	# Door: a dark doorway, a lintel, and the iron door hung open a little.
	Art.part(body, _box(0.86, 1.36, 0.04), _dark(), Vector3(0, 0.9, 1.0))
	Art.part(body, _box(1.12, 0.2, 0.16), heavy, Vector3(0, 1.67, 1.06))
	for sx: float in [-1.0, 1.0]:
		Art.part(body, _box(0.14, 1.36, 0.12), stone, Vector3(sx * 0.5, 0.9, 1.04))
	var hinge := Node3D.new()
	hinge.position = Vector3(-0.42, 0.9, 1.05)
	hinge.rotation_degrees.y = -rng.randf_range(15.0, 55.0)
	body.add_child(hinge)
	Art.part(hinge, _box(0.82, 1.32, 0.04), Shape.material(Color(0.14, 0.11, 0.09), Color(0.05, 0.04, 0.035), 5.0, 0.7, 0.9, 0.5, 204), Vector3(0.41, 0, 0.0))
	Art.part(hinge, k.door, _iron(), Vector3(0.41, 0, 0.0))
	# A small cross on the ridge, or a stone urn.
	if rng.randf() < 0.6:
		Art.part(body, _box(0.08, 0.5, 0.08), heavy, Vector3(0, 3.1, 0.95))
		Art.part(body, _box(0.3, 0.08, 0.08), heavy, Vector3(0, 3.2, 0.95))
	else:
		Art.part(body, _cyl(0.08, 0.12, 0.26, 8), heavy, Vector3(0, 3.0, 0.95))
	# A fallen block by the wall.
	if rng.randf() < 0.7:
		var sx2 := 1.0 if rng.randf() < 0.5 else -1.0
		Art.part(body, _box(0.42, 0.22, 0.3), heavy, Vector3(sx2 * 1.45, 0.11, rng.randf_range(-0.8, 0.8)), Vector3(rng.randf_range(-8, 8), rng.randf() * 90.0, rng.randf_range(-10, 10)))
	return {r = 1.4}


static func _mausoleum_kit() -> Dictionary:
	return _cached("mausoleum", func() -> Dictionary:
		var tris := PackedVector3Array()
		var z0 := -1.38
		var z1 := 1.09
		var a := [Vector3(-1.12, 2.28, 0), Vector3(1.12, 2.28, 0), Vector3(0, 2.83, 0)]
		var f: Array[Vector3] = []
		var b: Array[Vector3] = []
		for p: Vector3 in a:
			f.append(p + Vector3(0, 0, z1))
			b.append(p + Vector3(0, 0, z0))
		tris.append_array(PackedVector3Array([f[0], f[1], f[2], b[0], b[2], b[1]]))
		for e in 3:
			var j := (e + 1) % 3
			tris.append_array(PackedVector3Array([f[e], b[e], b[j], f[e], b[j], f[j]]))
		var gable := _faceted(tris, Vector3(0, 2.45, (z0 + z1) * 0.5))
		# Iron bands and a ring on the door.
		var door := Shape.merge([
			_boxm(Vector3(0.84, 0.05, 0.06), _xf(Vector3(0, 0.45, 0))),
			_boxm(Vector3(0.84, 0.05, 0.06), _xf(Vector3(0, -0.45, 0))),
			_boxm(Vector3(0.84, 0.05, 0.06), _xf(Vector3(0, 0.0, 0))),
			_boxm(Vector3(0.05, 1.3, 0.06), _xf(Vector3(-0.38, 0.0, 0))),
			_moved(_ring(0.05, 0.009, 8), _xf(Vector3(0.28, -0.05, 0.05), Vector3(90, 0, 0))),
		])
		return {gable = gable, door = door})


static func _cross(body: Node3D, rng: RandomNumberGenerator, wall: Color, moss: float, moss_c: Color) -> Dictionary:
	var st := Art.stone(wall.lightened(0.05), maxf(moss, 0.5), moss_c)
	Art.part(body, _box(0.56, 0.22, 0.44), Art.stone(wall.darkened(0.05), maxf(moss, 0.5), moss_c), Vector3(0, 0.11, 0))
	var lean := Node3D.new()
	lean.position = Vector3(0, 0.22, 0)
	lean.rotation_degrees = Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12))
	body.add_child(lean)
	var h := rng.randf_range(1.3, 1.6)
	Art.part(lean, _box(0.38, 0.16, 0.3), st, Vector3(0, 0.08, 0))
	Art.part(lean, _box(0.17, h, 0.13), st, Vector3(0, 0.16 + h * 0.5, 0))
	var arm := h * 0.72 + 0.16
	var broken := rng.randf() < 0.25
	Art.part(lean, _box(0.62 if not broken else 0.4, 0.16, 0.13), st, Vector3(0 if not broken else -0.11, arm, 0))
	if rng.randf() < 0.6:
		Art.part(lean, _ring_mesh(), st, Vector3(0, arm, 0))
	return {r = 0.3}


static func _ring_mesh() -> ArrayMesh:
	return _cached("crossring", func() -> ArrayMesh:
		return _moved(_ring(0.2, 0.035, 18, 5), _xf(Vector3.ZERO, Vector3(90, 0, 0))))


static func _ruin_wall(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	var k: Array = _ruin_kit(rng.randi() % 3)
	for pc: Array in k:
		_put(body, pc, stone)
	return {r = 0.8}


## Where the window's opening is, grown by [param g] (the arch ring round it).
static func _in_arch(x: float, y: float, g: float) -> bool:
	if absf(x) > 0.5 + g or y < 0.95:
		return false
	if y < 1.75:
		return true
	return Vector2(x, y).distance_to(Vector2(0.5, 1.75)) < 1.0 + g and Vector2(x, y).distance_to(Vector2(-0.5, 1.75)) < 1.0 + g


## A chapel wall fragment, 2.6 m wide: courses of squared blocks over a
## rubble core, a pointed window with its arch stones, the top broken off
## unevenly. Pieces: the blocks and core of the left, middle and right,
## the arch stones, the footing, rubble.
static func _ruin_kit(i: int) -> Array:
	return _cached("ruin%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7301 + i * 59
		var trend: Array = [[3.2, 3.1, 2.4, 1.5], [2.6, 3.3, 3.2, 2.7], [3.0, 2.9, 1.2, 0.7]][i]
		var tops := PackedFloat32Array()
		var walk := 0.0
		for c in 26:
			var t := c / 25.0 * (trend.size() - 1)
			var k := mini(int(t), trend.size() - 2)
			walk = clampf(walk + rng.randf_range(-0.16, 0.16), -0.3, 0.3)
			var h := lerpf(trend[k], trend[k + 1], t - k) + walk
			tops.append(snappedf(h, 0.1))
		var top := func(x: float) -> float:
			return tops[clampi(int((x + 1.3) / 0.1), 0, tops.size() - 1)]
		var z0 := -0.55
		var z1 := -0.1
		var zc := (z0 + z1) * 0.5
		var solid := func(x: float, y: float) -> bool:
			return y < top.call(x) and not _in_arch(x, y, 0.2)
		var spans := [[-1.3, -0.6], [-0.6, 0.6], [0.6, 1.3]]
		var groups := [[], [], []]
		for g in 3:
			groups[g].append(_extrude(solid, spans[g][0], spans[g][1], 0.0, 3.4, 0.1, z0 + 0.025, z1 - 0.025))
		# Courses of blocks, staggered, wherever the whole block is wall.
		var y := 0.24
		var course := 0
		while y < 3.4:
			var bh := 0.3 if course % 3 != 2 else 0.22
			var x := -1.3 - (0.0 if course % 2 == 0 else 0.22)
			while x < 1.3:
				var bw := rng.randf_range(0.38, 0.56)
				var xa := maxf(x, -1.3)
				var xb := minf(x + bw, 1.3)
				x += bw
				if xb - xa < 0.12:
					continue
				var ok := true
				for q in 5:
					for r in 3:
						if not solid.call(lerpf(xa + 0.02, xb - 0.02, q / 4.0), lerpf(y + 0.02, y + bh - 0.02, r / 2.0)):
							ok = false
				if not ok:
					continue
				var mx := (xa + xb) * 0.5
				var g2 := 0 if mx < -0.6 else (1 if mx < 0.6 else 2)
				groups[g2].append(_boxm(Vector3(xb - xa - 0.025, bh - 0.025, z1 - z0 + rng.randf_range(-0.01, 0.02)), _xf(Vector3(mx, y + bh * 0.5, zc + rng.randf_range(-0.008, 0.008)), Vector3(rng.randf_range(-1, 1), rng.randf_range(-1.5, 1.5), rng.randf_range(-1, 1)))))
			y += bh
			course += 1
		var out := []
		for g in 3:
			out.append(Shape.centered(Shape.merge(groups[g])))
		# Arch stones and jambs, skipped where the wall has fallen.
		var stones := []
		for side: float in [-1.0, 1.0]:
			var c := Vector2(-side * 0.5, 1.75)
			var a0 := 0.0 if side > 0.0 else PI
			var a1 := acos(0.5 / 1.1) if side > 0.0 else PI - acos(0.5 / 1.1)
			for s in 4:
				var a := lerpf(a0, a1, (s + 0.5) / 4.0)
				var p := c + Vector2(cos(a), sin(a)) * 1.1
				if p.y > top.call(p.x) + 0.05:
					continue
				var w := absf(a1 - a0) / 4.0 * 1.1 * 0.94
				stones.append(_boxm(Vector3(w, 0.24, 0.53), _xf(Vector3(p.x, p.y, zc), Vector3(0, 0, rad_to_deg(a) - 90.0))))
			for s in 3:
				var yj := 1.08 + s * 0.27
				if yj > top.call(side * 0.6):
					continue
				var w2 := 0.24 if s % 2 == 0 else 0.32
				stones.append(_boxm(Vector3(w2, 0.25, 0.53), _xf(Vector3(side * (0.5 + w2 * 0.5), yj, zc))))
		stones.append(_boxm(Vector3(1.3, 0.09, 0.6), _xf(Vector3(0, 0.92, zc + 0.03))))
		out.append(Shape.centered(Shape.merge(stones)))
		# The footing, then rubble at the foot.
		out.append(Shape.centered(_boxm(Vector3(2.72, 0.24, 0.6), _xf(Vector3(0, 0.12, zc)))))
		var rubble := []
		for r in rng.randi_range(4, 7):
			var s2 := rng.randf_range(0.1, 0.22)
			rubble.append(_at(Shape.blob(Vector3(s2 * 1.4, s2 * 0.7, s2), 0.25, r * 2.1 + i, 5, 7), Vector3(rng.randf_range(-1.3, 1.3), s2 * 0.4, rng.randf_range(0.0, 0.6))))
		for r in 2:
			rubble.append(_boxm(Vector3(0.42, 0.28, 0.4), _xf(Vector3(rng.randf_range(-1.0, 1.0), 0.12, rng.randf_range(0.25, 0.7)), Vector3(rng.randf_range(-15, 15), rng.randf() * 90.0, rng.randf_range(-12, 12)))))
		out.append(Shape.centered(Shape.merge(rubble)))
		return out)


# --- The catacombs -------------------------------------------------------------


static func _skull_niche(body: Node3D, rng: RandomNumberGenerator, wall: Color, moss: float, moss_c: Color) -> Dictionary:
	var st := Art.stone(wall.lightened(0.05), moss * 0.6, moss_c)
	Art.part(body, _box(1.4, 2.0, 0.1), Art.stone(wall.darkened(0.55), 0.0, moss_c), Vector3(0, 1.0, -0.45))
	for sx: float in [-1.0, 1.0]:
		Art.part(body, _box(0.16, 2.0, 0.56), st, Vector3(sx * 0.78, 1.0, -0.2))
	Art.part(body, _box(1.8, 0.2, 0.62), st, Vector3(0, 2.1, -0.18))
	Art.part(body, _box(1.8, 0.16, 0.62), st, Vector3(0, 0.08, -0.18))
	for y: float in [0.78, 1.42]:
		Art.part(body, _box(1.42, 0.06, 0.52), st, Vector3(0, y, -0.2))
	for pc: Array in _niche_kit(rng.randi() % 3):
		_put(body, pc, _bone_m())
	return {r = 0.6}


## Each bay's bones, centred: long-bone ends stacked like cordwood below,
## a row of skulls in the middle, skulls and loose bones at the top.
static func _niche_kit(i: int) -> Array:
	return _cached("niche%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4401 + i * 71
		var low := []
		for row in 2:
			for c in 6:
				var x := -0.55 + c * 0.22 + (0.11 if row % 2 == 1 else 0.0)
				if x > 0.62:
					continue
				var y := 0.24 + row * 0.085 + rng.randf_range(-0.01, 0.01)
				var zf := 0.02 + rng.randf_range(-0.04, 0.02)
				var end := Shape.merge([
					Shape.limb(PackedVector3Array([Vector3(0, 0, -0.2), Vector3(0, 0, -0.02)]), Shape.taper(0.026, 0.024, 2), 4, 1),
					_at(Shape.blob(Vector3(0.045, 0.038, 0.035), 0.12, c + row * 3.0 + i, 2, 5), Vector3(0, 0, 0)),
				])
				low.append(Shape.tint(_moved(end, Transform3D(Basis(Vector3.FORWARD, rng.randf() * TAU), Vector3(x, y, zf))), Color.WHITE * rng.randf_range(0.75, 1.0)))
		# A row of skulls on top of the stack.
		for c in 4:
			var x := -0.48 + c * 0.32
			low.append(_moved(_skull1(c * 1.7 + i), Transform3D(Basis(Vector3.UP, rng.randf_range(-0.25, 0.25)) * Basis.from_scale(Vector3.ONE * rng.randf_range(0.95, 1.1)), Vector3(x, 0.42, -0.02))))
		var mid := []
		for c in 4:
			var x := -0.5 + c * 0.33 + rng.randf_range(-0.03, 0.03)
			mid.append(Shape.tint(_moved(_skull1(c * 2.3 + 11.0 + i), Transform3D(Basis(Vector3.UP, rng.randf_range(-0.35, 0.35)) * Basis(Vector3.RIGHT, rng.randf_range(-0.15, 0.05)), Vector3(x, 0.82, -0.04))), Color.WHITE * rng.randf_range(0.75, 1.0)))
		for c in 2:
			mid.append(_moved(_bone(rng.randf_range(0.36, 0.46), 0.018, c), Transform3D(Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)) * Basis(Vector3.FORWARD, rng.randf_range(-0.1, 0.1)), Vector3(rng.randf_range(-0.35, 0.35), 1.03 + c * 0.035, -0.25))))
		var high := []
		for c in 3:
			if rng.randf() < 0.2:
				continue
			high.append(_moved(_skull1(c * 3.1 + 21.0 + i), Transform3D(Basis(Vector3.UP, rng.randf_range(-0.6, 0.6)), Vector3(-0.42 + c * 0.38 + rng.randf_range(-0.05, 0.05), 1.46, rng.randf_range(-0.12, 0.0)))))
		for c in 2:
			high.append(_moved(_bone(rng.randf_range(0.3, 0.44), 0.017, c + 7.0), Transform3D(Basis(Vector3.UP, rng.randf_range(-1.2, 1.2)), Vector3(rng.randf_range(-0.4, 0.4), 1.47, rng.randf_range(-0.3, -0.05)))))
		return [Shape.centered(Shape.ground(Shape.merge(low), 2.0, 0.55)), Shape.centered(Shape.merge(mid)), Shape.centered(Shape.merge(high))])


static func _bone_pile(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _pile_kit(rng.randi() % 4)
	_put(body, k[0], Shape.material(Color(0.26, 0.23, 0.19), Color(0.1, 0.09, 0.07), 4.0, 0.95, 0.8, 0.0, 413))
	for n in range(1, k.size()):
		_put(body, k[n], _bone_m())
	return {r = 0.5}


static func _pile_kit(i: int) -> Array:
	return _cached("pile%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5501 + i * 41
		var rx := rng.randf_range(0.7, 0.85)
		var rz := rng.randf_range(0.55, 0.7)
		var h := rng.randf_range(0.3, 0.42)
		var mound := _heap(rx, rz, h, i * 1.3)
		var height := func(x: float, z: float) -> float:
			var q := 1.0 - (x * x) / (rx * rx) - (z * z) / (rz * rz)
			return h * pow(maxf(q, 0.0), 1.2)
		var groups := [[], []]
		for b in rng.randi_range(10, 13):
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * 0.8
			var x := cos(a) * rx * d
			var z := sin(a) * rz * d
			var l := rng.randf_range(0.3, 0.5)
			var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, rng.randf_range(-0.4, 0.4)) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)), Vector3(x, height.call(x, z) + 0.01, z))
			groups[b % 2].append(_moved(_bone(l, l * 0.06, b + i * 2.0), xf))
		for s in rng.randi_range(4, 6):
			var a := rng.randf() * TAU
			var d := 0.0 if s == 0 else rng.randf_range(0.3, 0.75)
			var x := cos(a) * rx * d
			var z := sin(a) * rz * d
			var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.6, 0.15)) * Basis(Vector3.FORWARD, rng.randf_range(-0.4, 0.4)), Vector3(x, height.call(x, z) - 0.03, z))
			groups[s % 2].append(Shape.tint(_moved(_skull1(s * 2.7 + i), xf), Color.WHITE * rng.randf_range(0.8, 1.0)))
		# A curl of ribs.
		var rib_at := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		rib_at.y = height.call(rib_at.x, rib_at.z)
		var yaw := rng.randf() * TAU
		for r in 3:
			var o := Vector3(0, 0.01, r * 0.07)
			groups[1].append(_moved(Shape.limb(Shape.curve(o + Vector3(-0.17, 0, 0), o + Vector3(0, 0.06, 0.12), o + Vector3(0.17, 0, 0.02), 5), Shape.taper(0.012, 0.007, 5), 4, 1), Transform3D(Basis(Vector3.UP, yaw), rib_at)))
		return [Shape.centered(Shape.ground(mound, h, 0.6)), Shape.centered(Shape.ground(Shape.merge(groups[0]), 0.5, 0.55)), Shape.centered(Shape.ground(Shape.merge(groups[1]), 0.5, 0.55))])


static func _chains(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _chains_kit(rng.randi() % 3)
	Art.part(body, k[0], _iron())
	Art.part(body, k[1], _rust())
	return {r = -1.0}


static func _chains_kit(i: int) -> Array:
	return _cached("chains%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 6101 + i * 23
		var iron := []
		var rust := []
		var anchors: Array[Vector3] = [Vector3(rng.randf_range(-0.3, 0.0), rng.randf_range(2.1, 2.4), -0.46)]
		anchors.append(anchors[0] + Vector3(rng.randf_range(0.6, 0.9), rng.randf_range(-0.2, 0.15), 0))
		for a: Vector3 in anchors:
			iron.append(_boxm(Vector3(0.16, 0.16, 0.03), _xf(a + Vector3(0, 0, -0.02))))
			iron.append(_moved(_ring(0.05, 0.012, 8), _xf(a + Vector3(0, -0.05, 0.03))))
		var hang := anchors[0] + Vector3(0, -0.1, 0.03)
		# A sagging loop between the rings.
		rust.append(_chain(Shape.curve(hang, (hang + anchors[1]) * 0.5 + Vector3(0, -rng.randf_range(0.4, 0.7), 0.1), anchors[1] + Vector3(0, -0.1, 0.03), 9), 0.15, 0.017))
		# One hanging down to shackles.
		var low := hang + Vector3(rng.randf_range(-0.05, 0.05), -rng.randf_range(0.9, 1.2), rng.randf_range(0.06, 0.14))
		rust.append(_chain(PackedVector3Array([hang, low]), 0.15, 0.017))
		for s: float in [-1.0, 1.0]:
			rust.append(_moved(_ring(0.065, 0.02, 10, 4), _xf(low + Vector3(s * 0.06, -0.08, 0.0), Vector3(90, 0, s * 25.0))))
		if i != 1:
			# The other trailing to the floor and lying there.
			var from := anchors[1] + Vector3(0, -0.1, 0.03)
			var down := Vector3(from.x + rng.randf_range(-0.1, 0.2), 0.03, -0.2)
			var pts := PackedVector3Array([from, Vector3(down.x, 0.25, -0.35), down, down + Vector3(rng.randf_range(-0.35, 0.35), 0, 0.3)])
			for p in range(pts.size()):
				pts[p].y = maxf(pts[p].y, 0.02)
			rust.append(_chain(pts, 0.15, 0.017))
		return [Shape.ground(Shape.merge(iron), 2.5, 0.6), Shape.ground(Shape.merge(rust), 2.5, 0.5)])


static var _web_mat: ShaderMaterial


static func _cobweb(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	if _web_mat == null:
		var sh := Shader.new()
		sh.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_never, shadows_disabled, diffuse_lambert, specular_disabled;
uniform vec4 tint : source_color = vec4(0.7, 0.7, 0.68, 0.2);
float line(float v, float w) {
	float d = abs(fract(v - 0.5) - 0.5) / max(fwidth(v), 0.0001);
	return 1.0 - clamp(d / w, 0.0, 1.0);
}
void fragment() {
	vec2 p = UV;
	float r = length(p);
	float a = atan(p.y, p.x) / 1.5708;
	float spokes = line(a * 9.0, 1.2);
	float rings = line(r * 11.0 + sin(a * 56.5) * 0.12, 1.0);
	float edge = 1.0 - smoothstep(0.82, 1.0, r);
	float torn = step(0.25, fract(sin(floor(a * 9.0) * 12.9 + floor(r * 11.0) * 78.2) * 43758.5));
	float w = max(spokes, rings * torn) * edge;
	ALBEDO = tint.rgb;
	ROUGHNESS = 1.0;
	ALPHA = w * tint.a + edge * 0.015;
}
"""
		_web_mat = ShaderMaterial.new()
		_web_mat.shader = sh
	var sheets: Array = _cached("webs", func() -> Array:
		var out := []
		# From the angle of wall and floor, up the wall and out over the floor.
		out.append(_web_quad(Vector3(0, 0.02, -0.46), Vector3(0.9, 1.25, 0.02), Vector3(-0.35, 0.0, 0.9)))
		out.append(_web_quad(Vector3(-0.1, 0.02, -0.46), Vector3(-1.0, 0.9, 0.05), Vector3(0.1, 0.05, 0.75)))
		out.append(_web_quad(Vector3(0.5, 1.9, -0.46), Vector3(-0.75, -0.6, 0.35), Vector3(0.45, -0.85, 0.2)))
		return out)
	var n := rng.randi_range(2, 3)
	for s in n:
		var m := Art.part(body, sheets[(s + rng.randi()) % sheets.size()], _web_mat, Vector3(rng.randf_range(-0.2, 0.2), 0, 0), Vector3(0, rng.randf_range(-10, 10), 0), Vector3.ONE * rng.randf_range(0.8, 1.2))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {r = -1.0}


## A web stretched from corner [param o] along [param e1] and [param e2],
## sagging a little in the middle; UV 0 at the corner.
static func _web_quad(o: Vector3, e1: Vector3, e2: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 6
	var sag := e1.cross(e2).normalized() * 0.08
	for a in n:
		for b in n:
			for q: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := float(a + q.x) / n
				var v := float(b + q.y) / n
				st.set_uv(Vector2(u, v))
				st.add_vertex(o + e1 * u + e2 * v + sag * sin(u * PI) * sin(v * PI))
	st.generate_normals()
	return st.commit()


static func _altar(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	Art.part(body, _box(1.9, 0.12, 1.0), stone, Vector3(0, 0.06, -0.1))
	Art.part(body, _box(1.6, 0.82, 0.74), stone, Vector3(0, 0.53, -0.12))
	Art.part(body, _box(1.76, 0.1, 0.86), stone, Vector3(0, 0.99, -0.12))
	var k: Dictionary = _altar_kit(rng.randi() % 2)
	Art.part(body, k.cloth, Art.cloth(Color(0.16, 0.06, 0.07), 160.0))
	Art.part(body, k.skull, _bone_m())
	Art.part(body, k.wax, Shape.material(Color(0.5, 0.43, 0.32), Color(0.4, 0.33, 0.23), 6.0, 0.5, 0.25, 0.0, 51))
	Art.part(body, k.wick, Fx.solid(Color(0.04, 0.03, 0.03)))
	var fm := Art.part(body, k.flame, Fx.glow(Color(1.0, 0.62, 0.28), 4.0))
	fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tops: PackedVector3Array = k.tops
	for t in range(0, tops.size(), 2):
		var hl := Fx.halo(Color(1.0, 0.55, 0.22), 0.25, 0.55)
		hl.position = tops[t]
		body.add_child(hl)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.62, 0.32)
	l.light_energy = 0.9
	l.omni_range = 4.0
	l.position = Vector3(0, 1.5, 0.1)
	body.add_child(l)
	return {r = 0.8}


static func _altar_kit(i: int) -> Dictionary:
	return _cached("altar%d" % i, func() -> Dictionary:
		var rng := RandomNumberGenerator.new()
		rng.seed = 8801 + i * 13
		# The cloth: across the top from the back, over the front edge and
		# hanging down in folds, its hem ragged.
		var rows := []
		var cols := 12
		var path: Array[Vector2] = []
		for s in 5:
			path.append(Vector2(lerpf(-0.36, 0.4, s / 4.0), 1.047))
		path.append(Vector2(0.445, 1.035))
		path.append(Vector2(0.465, 0.99))
		for s in 6:
			path.append(Vector2(0.47 + s * 0.004, lerpf(0.92, 0.34, s / 5.0)))
		var hem := PackedFloat32Array()
		for c in cols + 1:
			hem.append(rng.randf_range(0.0, 0.16))
		for r in path.size():
			var row := PackedVector3Array()
			for c in cols + 1:
				var x := lerpf(-0.52, 0.52, float(c) / cols)
				var p := path[r]
				var hang := clampf((0.98 - p.y) / 0.6, 0.0, 1.0)
				var y := p.y + hem[c] * hang * hang
				var z := p.x + sin(x * 19.0 + i) * 0.018 * hang
				row.append(Vector3(x, y, z - 0.12))
			rows.append(row)
		var cloth := Shape.ground(_sheet2(rows), 1.1, 0.5)
		# A skull at the back, candles round it.
		var sk := _moved(_skull1(3.3 + i), Transform3D(Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)), Vector3(rng.randf_range(-0.15, 0.15), 1.04, -0.36)))
		var wax := []
		var wicks := []
		var flames := []
		var tops := PackedVector3Array()
		var spots := [Vector2(-0.65, -0.3), Vector2(-0.55, 0.1), Vector2(-0.68, 0.12), Vector2(0.6, -0.32), Vector2(0.66, 0.05), Vector2(0.52, -0.05), Vector2(-0.4, -0.38), Vector2(0.38, -0.4)]
		for s in spots.size():
			if rng.randf() < 0.2:
				continue
			var at: Vector2 = spots[s]
			var r := rng.randf_range(0.025, 0.045)
			var h := rng.randf_range(0.08, 0.32)
			var base := Vector3(at.x, 1.04, at.y - 0.12)
			wax.append(_at(Shape.lathe(PackedVector2Array([Vector2(r * 1.7, -0.004), Vector2(r * 1.2, 0.012), Vector2(r, h * 0.5), Vector2(r * 1.03, h - 0.01), Vector2(r * 0.7, h), Vector2(0.0, h - 0.008)]), 7), base))
			wax.append(Shape.limb(PackedVector3Array([base + Vector3(r, h - 0.005, 0), base + Vector3(r * 1.05, h * 0.6, 0), base + Vector3(r * 1.1, h * 0.35, 0)]), PackedFloat32Array([0.006, 0.007, 0.009]), 4, 1))
			wicks.append(Shape.limb(PackedVector3Array([base + Vector3.UP * (h - 0.01), base + Vector3.UP * (h + 0.014)]), PackedFloat32Array([0.003, 0.0025]), 3, 1))
			var top := base + Vector3.UP * (h + 0.036)
			tops.append(top)
			flames.append(Shape.warp(Shape.blob(Vector3(0.011, 0.026, 0.011), 0.0, 1.0, 5, 6), func(p: Vector3) -> Vector3:
				var kk := 1.0 - clampf(p.y / 0.026, -1.0, 1.0) * 0.5
				return Vector3(p.x * kk, p.y, p.z * kk) + top))
		return {cloth = cloth, skull = sk, wax = Shape.ground(Shape.merge(wax), 1.4, 0.7), wick = Shape.merge(wicks), flame = Shape.merge(flames), tops = tops})


# --- The sunken isles ------------------------------------------------------------


static func _piling(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var wood := _grain("piling", Color(0.24, 0.21, 0.16), Color(0.07, 0.06, 0.045), Vector3(10, 1.5, 10), 0.75, 1.4, 601)
	for pc: Array in _piling_kit(rng.randi() % 5):
		_put(body, pc, wood)
	return {r = 0.25}


static func _piling_kit(i: int) -> Array:
	return _cached("piling%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1201 + i * 17
		var out := []
		var n: int = [3, 2, 4, 1, 3][i]
		for p in n:
			var a := TAU * p / n + rng.randf_range(-0.5, 0.5)
			var at := Vector3(cos(a), 0, sin(a)) * (0.0 if n == 1 else rng.randf_range(0.15, 0.45))
			var h := rng.randf_range(0.6, 1.7) * (1.0 if p > 0 else 1.25)
			var r := rng.randf_range(0.09, 0.14)
			var tilt := Vector3(cos(a + rng.randf_range(-0.6, 0.6)), 0, sin(a + rng.randf_range(-0.6, 0.6))) * rng.randf_range(0.08, 0.45)
			var pts := PackedVector3Array()
			var rad := PackedFloat32Array()
			for s in 5:
				var t := s / 4.0
				pts.append(at + Vector3(0, -0.4 + t * (h + 0.4), 0) + tilt * t * (h + 0.4) + Vector3(rng.randf_range(-0.015, 0.015), 0, rng.randf_range(-0.015, 0.015)))
				rad.append(r * (1.0 - 0.15 * t) * rng.randf_range(0.9, 1.05))
			var parts := [Shape.limb(pts, rad, 8, 2)]
			# A broken top: a few splinters standing off the rim.
			var top := pts[4]
			var dir := (pts[4] - pts[3]).normalized()
			var s1 := dir.cross(Vector3.UP).normalized() if absf(dir.y) < 0.99 else Vector3.RIGHT
			var s2 := dir.cross(s1)
			for k in rng.randi_range(2, 4):
				var ang := rng.randf() * TAU
				var o := (s1 * cos(ang) + s2 * sin(ang)) * r * 0.55
				parts.append(Shape.limb(PackedVector3Array([top + o - dir * 0.05, top + o + dir * rng.randf_range(0.08, 0.24)]), PackedFloat32Array([r * 0.4, 0.004]), 4, 1))
			if rng.randf() < 0.5:
				# A rope wound round it.
				var ry := rng.randf_range(0.3, h * 0.7)
				var c := pts[0].lerp(pts[4], (ry + 0.4) / (h + 0.4))
				parts.append(_moved(_ring(r * 1.05, 0.018, 12, 4), Transform3D(Basis(Quaternion(Vector3.UP, dir)), c)))
			var m := Shape.shade(Shape.merge(parts), func(q: Vector3, nrm: Vector3) -> Color:
				# Slimy and dark at the waterline, silvered and dry higher up.
				var wet := 1.0 - smoothstep(0.0, 0.45, q.y)
				var c2 := Color(1.05, 1.03, 0.98).lerp(Color(0.42, 0.5, 0.34), wet)
				return c2 * (0.8 + 0.2 * (nrm.y * 0.5 + 0.5)))
			out.append(Shape.centered(m))
		return out)


static func _boat(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var wood := _grain("boat", Color(0.25, 0.2, 0.14), Color(0.08, 0.065, 0.05), Vector3(1.6, 10, 10), 0.8, 1.2, 611)
	var k: Array = _boat_kit()
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.24, 0)
	pivot.rotation_degrees = Vector3(rng.randf_range(10, 20) * (1.0 if rng.randf() < 0.5 else -1.0), 0, rng.randf_range(9, 16) * (1.0 if rng.randf() < 0.5 else -1.0))
	body.add_child(pivot)
	for pc: Array in k:
		_put(pivot, pc, wood)
	if rng.randf() < 0.7:
		# A broken oar left across it.
		Art.part(pivot, _oar_mesh(), wood, Vector3(rng.randf_range(-0.3, 0.3), 0.15, 0), Vector3(rng.randf_range(-5, 5), rng.randf_range(-40, 40), 6))
	return {r = 0.9}


static func _boat_kit() -> Array:
	return _cached("boat", func() -> Array:
		var nf := 10
		var hull := func(t: float, f: float, inset: float) -> Vector3:
			var q := (t + 0.1) / 1.1
			var w := 0.62 * sqrt(maxf(0.0, 1.0 - q * q))
			var d := 0.42 * (1.0 - 0.35 * t * t)
			var sheer := 0.1 * t * t + 0.06 * maxf(t, 0.0)
			w = maxf(w - inset, 0.0)
			d -= inset
			var y := sheer - d * pow(maxf(cos(f), 0.0), 0.7)
			return Vector3(t * 1.3, y, w * sin(f))
		var halves := []
		for half in 2:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var ta := -1.0 if half == 0 else 0.0
			var tb := 0.0 if half == 0 else 1.0
			for a in 7:
				var t0 := lerpf(ta, tb, float(a) / 7.0)
				var t1 := lerpf(ta, tb, float(a + 1) / 7.0)
				for b in nf:
					var f0 := lerpf(-PI * 0.5, PI * 0.5, float(b) / nf)
					var f1 := lerpf(-PI * 0.5, PI * 0.5, float(b + 1) / nf)
					# Strakes: every other plank a little darker.
					var plank := Color.WHITE * (1.0 if (b >> 1) % 2 == 0 else 0.82)
					for skin in 2:
						var ins := 0.0 if skin == 0 else 0.035
						var p00: Vector3 = hull.call(t0, f0, ins)
						var p10: Vector3 = hull.call(t1, f0, ins)
						var p11: Vector3 = hull.call(t1, f1, ins)
						var p01: Vector3 = hull.call(t0, f1, ins)
						var mid := (p00 + p11) * 0.5
						var out := Vector3(0, mid.y - 0.1, mid.z).normalized() * (1.0 if skin == 0 else -1.0)
						st.set_color(plank * (1.0 if skin == 0 else 0.6))
						_quad(st, p00, p10, p11, p01, out)
				# The gunwale: across the top between the skins.
				for f: float in [-PI * 0.5, PI * 0.5]:
					var o0: Vector3 = hull.call(t0, f, 0.0)
					var o1: Vector3 = hull.call(t1, f, 0.0)
					var i0: Vector3 = hull.call(t0, f, 0.035)
					var i1: Vector3 = hull.call(t1, f, 0.035)
					st.set_color(Color(0.9, 0.9, 0.9))
					_quad(st, o0, o1, i1 + Vector3(0, 0.0, 0), i0, Vector3.UP)
			if half == 0:
				# The transom closing the stern.
				for b in nf:
					var f0 := lerpf(-PI * 0.5, PI * 0.5, float(b) / nf)
					var f1 := lerpf(-PI * 0.5, PI * 0.5, float(b + 1) / nf)
					var c := Vector3(-1.3, 0.12, 0)
					st.set_color(Color(0.85, 0.85, 0.85))
					_tri(st, c, hull.call(-1.0, f0, 0.0), hull.call(-1.0, f1, 0.0), Vector3.LEFT)
					_tri(st, c, hull.call(-1.0, f0, 0.035), hull.call(-1.0, f1, 0.035), Vector3.RIGHT)
			# A thwart to sit on.
			var tx := -0.55 if half == 0 else 0.35
			var w: float = (hull.call(tx / 1.3, PI * 0.5, 0.03) as Vector3).z
			var seat := _boxm(Vector3(0.2, 0.035, w * 2.0), _xf(Vector3(tx, hull.call(tx / 1.3, PI * 0.5, 0.0).y - 0.12, 0)))
			var m := Shape.merge([st.commit(), seat])
			halves.append(Shape.centered(Shape.ground(m, 0.3, 0.55)))
		return halves)


static func _oar_mesh() -> ArrayMesh:
	return _cached("oar", func() -> ArrayMesh:
		return Shape.ground(Shape.merge([
			Shape.limb(PackedVector3Array([Vector3(-0.9, 0, 0), Vector3(0.45, 0, 0)]), Shape.taper(0.025, 0.022, 2), 6, 1),
			_at(Shape.slab(Vector3(0.22, 0.012, 0.07), 0.3, 4, 8), Vector3(0.62, 0, 0)),
		]), 0.3, 0.6))


static func _sunken_ruin(body: Node3D, rng: RandomNumberGenerator, wall: Color, moss_c: Color) -> Dictionary:
	var st := Shape.material(Color(0.3, 0.31, 0.28), Color(0.13, 0.14, 0.12), 3.0, 0.9, 0.9, 0.0, 641)
	for pc: Array in _ruin_cols(rng.randi() % 3):
		_put(body, pc, st)
	return {r = 0.7}


## A fluted column drum from 0 to [param h], radius [param r], its top
## broken off jagged when [param broken].
static func _column(r: float, h: float, broken: bool, seed: float) -> ArrayMesh:
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 1.12, 0.0), Vector2(r * 1.1, 0.06), Vector2(r, 0.12), Vector2(r * 0.97, h * 0.5), Vector2(r * 0.94, h), Vector2(0.0, h)])
	var m := Shape.lathe(prof, 24)
	return Shape.warp(m, func(p: Vector3) -> Vector3:
		var a := atan2(p.z, p.x)
		var k := 1.0 - 0.05 * maxf(cos(a * 12.0), 0.0) if p.y > 0.12 else 1.0
		var q := Vector3(p.x * k, p.y, p.z * k)
		if broken and p.y > h - 0.01:
			q.y += 0.07 * sin(a * 3.0 + seed) + 0.035 * sin(a * 7.0 + seed * 2.0)
			if Vector2(p.x, p.z).length() < 0.01:
				q.y -= 0.05
		return q)


static func _ruin_cols(i: int) -> Array:
	return _cached("rcols%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2301 + i * 29
		var out := []
		var tilt := Basis(Vector3(1, 0, rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.04, 0.12))
		var plinth := _moved(_boxm(Vector3(0.95, 0.32, 0.95)), Transform3D(tilt, Vector3(0, 0.1, 0)))
		out.append(Shape.centered(plinth))
		var h := rng.randf_range(0.7, 1.6)
		out.append(Shape.centered(_moved(_column(0.32, h, true, i * 2.0), Transform3D(tilt, Vector3(0, 0.26, 0)))))
		if i != 1:
			var a := rng.randf() * TAU
			var at := Vector3(cos(a), 0, sin(a)) * 0.95
			out.append(Shape.centered(_moved(_column(0.26, rng.randf_range(0.25, 0.5), true, i * 3.0 + 1.0), Transform3D(Basis(Vector3.RIGHT, rng.randf_range(-0.1, 0.1)), at + Vector3(0, -0.08, 0)))))
		# A toppled drum lying half sunk.
		var a2 := rng.randf() * TAU
		var lie := Transform3D(Basis(Vector3.UP, a2) * Basis(Vector3.FORWARD, PI * 0.5), Vector3(cos(a2 + 1.6), 0, sin(a2 + 1.6)) * 0.85 + Vector3(0, 0.2, 0))
		out.append(Shape.centered(_moved(_column(0.27, rng.randf_range(0.6, 0.9), false, 0.0), lie)))
		if i == 1:
			# A fallen capital.
			out.append(Shape.centered(_moved(Shape.merge([_boxm(Vector3(0.7, 0.14, 0.7), _xf(Vector3(0, 0.07, 0))), _at(Shape.lathe(PackedVector2Array([Vector2(0.24, 0.0), Vector2(0.28, 0.06), Vector2(0.34, 0.12), Vector2(0.0, 0.12)]), 14), Vector3(0, 0.14, 0))]), Transform3D(Basis(Vector3.UP, rng.randf()) * Basis(Vector3.RIGHT, 2.6), Vector3(-0.7, 0.18, 0.5)))))
		# Moss on what faces up, slime green-black along the waterline.
		var mossy := []
		for pc: Array in out:
			var at: Vector3 = pc[1]
			mossy.append([Shape.shade(pc[0], func(p: Vector3, nrm: Vector3) -> Color:
				var y := p.y + at.y
				var c := Color.WHITE.lerp(Color(0.45, 0.6, 0.3), smoothstep(0.3, 0.8, nrm.y) * (0.6 + 0.4 * sin(p.x * 9.0 + p.z * 7.0)))
				c = c.lerp(Color(0.3, 0.36, 0.22), 1.0 - smoothstep(0.0, 0.35, y))
				return c * lerpf(0.6, 1.0, clampf(y / 1.2, 0.0, 1.0))), at])
		return mossy)


static func _lily(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _lily_kit(rng.randi() % 4)
	var pads := Art.part(body, k[0], Shape.material(Color(0.2, 0.26, 0.13), Color(0.08, 0.11, 0.05), 5.0, 0.35, 0.35, 0.0, 401))
	pads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if k[1] != null:
		Art.part(body, k[1], Shape.material(Color(0.68, 0.64, 0.6), Color(0.5, 0.42, 0.42), 8.0, 0.6, 0.2, 0.0, 402))
	return {r = -1.0}


static func _lily_kit(i: int) -> Array:
	return _cached("lily%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3301 + i * 11
		var pads := []
		var flowers := []
		var spots: Array[Vector3] = []
		for p in rng.randi_range(6, 11):
			var r := rng.randf_range(0.12, 0.3)
			var at := Vector3.ZERO
			for _t in 10:
				at = Vector3(rng.randf_range(-0.8, 0.8), 0.02 + p * 0.002, rng.randf_range(-0.6, 0.6))
				var ok := true
				for s: Vector3 in spots:
					if Vector2(s.x - at.x, s.z - at.z).length() < (r + s.y) * 0.85:
						ok = false
				if ok:
					break
			spots.append(Vector3(at.x, r, at.z))
			var notch := rng.randf_range(0.3, 0.6)
			var rot := rng.randf() * TAU
			var pts := PackedVector3Array([at + Vector3(0, 0.004, 0)])
			for s in 14:
				var a := rot + notch * 0.5 + (TAU - notch) * s / 13.0
				var rr := r * rng.randf_range(0.95, 1.03)
				pts.append(at + Vector3(cos(a) * rr, 0.012, sin(a) * rr))
			var col := Color(0.75, 0.62, 0.4) if rng.randf() < 0.2 else Color.WHITE * rng.randf_range(0.7, 1.05)
			pads.append(Shape.tint(Shape.sheet(pts), col))
			if rng.randf() < 0.2 and flowers.size() < 2:
				for q in 7:
					var a := TAU * q / 7.0
					var d := Vector3(cos(a), 0, sin(a))
					flowers.append(Shape.sheet(PackedVector3Array([at + Vector3(0, 0.02, 0), at + d * 0.03 + d.cross(Vector3.UP) * 0.02 + Vector3(0, 0.05, 0), at + d * 0.065 + Vector3(0, 0.08, 0), at + d * 0.03 - d.cross(Vector3.UP) * 0.02 + Vector3(0, 0.05, 0)])))
		return [Shape.merge(pads), Shape.merge(flowers) if not flowers.is_empty() else null])


static func _moss_tree(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _moss_tree_kit(rng.randi() % 4)
	var s := rng.randf_range(0.9, 1.12)
	var bark := _grain("drownbark", Color(0.17, 0.16, 0.13), Color(0.05, 0.05, 0.04), Vector3(9, 1.6, 9), 0.85, 1.6, 621)
	_put(body, k[0], bark, s)
	_put(body, k[1], bark, s)
	var moss := _put(body, k[2], Shape.material(Color(0.2, 0.23, 0.19), Color(0.13, 0.15, 0.12), 2.0, 0.95, 0.3, 0.0, 622), s)
	moss.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {r = 0.35}


static func _moss_tree_kit(i: int) -> Array:
	return _cached("mosstree%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4701 + i * 31
		var h := rng.randf_range(2.4, 3.2)
		var lean := Vector3(rng.randf_range(0.2, 0.5), 0, 0).rotated(Vector3.UP, rng.randf() * TAU)
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		for s in 6:
			var t := s / 5.0
			pts.append(Vector3(0, -0.15 + t * h, 0) + lean * t * t + Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08)) * t)
			rad.append(lerpf(0.26, 0.05, pow(t, 0.8)))
		var trunk := [Shape.limb(pts, rad, 8, 2)]
		for r in 5:
			var a := TAU * r / 5.0 + rng.randf_range(-0.3, 0.3)
			var d := Vector3(cos(a), 0, sin(a))
			trunk.append(Shape.limb(Shape.curve(Vector3(0, 0.45, 0) + d * 0.08, d * 0.35 + Vector3(0, 0.15, 0), d * rng.randf_range(0.6, 0.85) + Vector3(0, -0.1, 0), 4), Shape.taper(0.11, 0.025, 4), 6, 1))
		var branches := []
		var moss_from: Array[Vector3] = []
		for b in rng.randi_range(4, 6):
			var t := rng.randf_range(0.45, 0.92)
			var at := _along(pts, t)
			var a := rng.randf() * TAU
			var d := Vector3(cos(a), 0, sin(a))
			var l := rng.randf_range(0.7, 1.3) * (1.1 - t * 0.4)
			var bp := Shape.curve(at, at + d * l * 0.55 + Vector3(0, l * 0.35, 0), at + d * l + Vector3(0, rng.randf_range(-0.15, 0.2), 0), 4)
			branches.append(Shape.limb(bp, Shape.taper(lerpf(0.09, 0.04, t), 0.012, 4), 5, 2))
			for q in 4:
				moss_from.append(_along(bp, rng.randf_range(0.25, 0.98)))
			var tw := _along(bp, 0.6)
			var d2 := (d + Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.2, 0.4), rng.randf_range(-0.8, 0.8))).normalized()
			branches.append(Shape.limb(PackedVector3Array([tw, tw + d2 * 0.25, tw + d2 * 0.42 + Vector3(0, -0.06, 0)]), Shape.taper(0.025, 0.006, 3), 4, 1))
		# Moss: beards of thin strands hanging straight down off the branches,
		# swaying a little, and a clump where each drapes over.
		var moss := []
		for m in moss_from.size():
			var top := moss_from[m] + Vector3(0, -0.02, 0)
			moss.append(_at(Shape.blob(Vector3(0.05, 0.035, 0.05), 0.3, m * 1.3, 2, 4), top))
			for q in 2:
				var l := rng.randf_range(0.3, 1.1)
				var o := Vector3(rng.randf_range(-0.04, 0.04), 0, rng.randf_range(-0.04, 0.04))
				var spts := PackedVector3Array()
				for k in 4:
					var t := k / 3.0
					spts.append(top + o * (1.0 + t) + Vector3(sin(t * 3.0 + m + q) * 0.03, -l * t, cos(t * 2.0 + m) * 0.03))
				moss.append(Shape.limb(spts, Shape.taper(rng.randf_range(0.012, 0.022), 0.003, 4), 3, 1))
		return [Shape.centered(Shape.ground(Shape.merge(trunk), h, 0.4)), Shape.centered(Shape.ground(Shape.merge(branches), h, 0.6)), Shape.centered(Shape.ground(Shape.merge(moss), h, 0.5))])


# --- The caves ---------------------------------------------------------------------


static func _crystal(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	var violet := rng.randf() < 0.45
	var c := Color(0.36, 0.28, 0.5) if violet else Color(0.2, 0.44, 0.44)
	var k: Array = _crystal_kit(rng.randi() % 4)
	_put(body, k[0], stone)
	var mat: StandardMaterial3D = _cached("mcrystal" + c.to_html(), func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = c.darkened(0.6)
		m.roughness = 0.15
		m.metallic = 0.3
		m.metallic_specular = 0.8
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.3
		m.rim_enabled = true
		m.rim = 0.5
		m.rim_tint = 0.6
		return m)
	_put(body, k[1], mat)
	_put(body, k[2], mat)
	var hl := Fx.halo(c, 1.2, 0.35)
	hl.position = Vector3(0, 0.7, 0.1)
	body.add_child(hl)
	var l := OmniLight3D.new()
	l.light_color = c.lightened(0.25)
	l.light_energy = 0.7
	l.omni_range = 3.5
	l.position = Vector3(0, 0.9, 0.35)
	body.add_child(l)
	return {r = 0.5}


## A six-sided crystal along +y, [param h] long, [param r] across, its
## point a little off centre: flat-faced.
static func _prism6(r: float, h: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var lo := PackedVector3Array()
	var hi := PackedVector3Array()
	var sh := rng.randf_range(0.62, 0.82)
	var tip := Vector3(rng.randf_range(-0.2, 0.2) * r, h, rng.randf_range(-0.2, 0.2) * r)
	for k in 6:
		var a := TAU * k / 6.0 + rng.randf_range(-0.1, 0.1)
		var rr := r * rng.randf_range(0.85, 1.1)
		lo.append(Vector3(cos(a) * rr, -0.2, sin(a) * rr))
		hi.append(Vector3(cos(a) * rr * 0.92, h * sh + rng.randf_range(-0.04, 0.04) * h, sin(a) * rr * 0.92))
	var tris := PackedVector3Array()
	for k in 6:
		var j := (k + 1) % 6
		tris.append_array(PackedVector3Array([lo[k], lo[j], hi[j], lo[k], hi[j], hi[k], hi[k], hi[j], tip]))
	return _faceted(tris, Vector3(0, h * 0.4, 0))


static func _crystal_kit(i: int) -> Array:
	return _cached("crystal%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2701 + i * 19
		var rock := Shape.warp(Shape.blob(Vector3(0.62, 0.38, 0.45), 0.22, i * 2.3 + 1.0, 8, 12), func(p: Vector3) -> Vector3:
			return Vector3(p.x, p.y, maxf(p.z, -0.3)))
		var groups := [[], []]
		var n := rng.randi_range(8, 11)
		for k in n:
			var big := k < 3
			var h := rng.randf_range(0.75, 1.3) if big else rng.randf_range(0.25, 0.65)
			var r := h * rng.randf_range(0.1, 0.15)
			var x := rng.randf_range(-0.45, 0.45) * (0.6 if big else 1.0)
			var z := rng.randf_range(-0.2, 0.3)
			var at := Vector3(x, 0.22 + 0.1 * (1.0 - absf(x) * 2.0), z)
			var dir := Vector3(x * 2.2 + rng.randf_range(-0.35, 0.35), 1.0, z * 0.8 - 0.15 + rng.randf_range(-0.15, 0.25)).normalized()
			var b := Basis(Quaternion(Vector3.UP, dir)) * Basis(Vector3.UP, rng.randf() * TAU)
			groups[k % 2].append(_moved(_prism6(r, h, rng), Transform3D(b, at)))
		return [Shape.centered(Shape.ground(rock, 0.5, 0.45)), Shape.centered(Shape.merge(groups[0])), Shape.centered(Shape.merge(groups[1]))])


static func _mine_support(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var post := _grain("minepost", Color(0.26, 0.19, 0.12), Color(0.08, 0.055, 0.035), Vector3(9, 1.2, 9), 0.9, 1.3, 701)
	var beam := _grain("minebeam", Color(0.24, 0.18, 0.11), Color(0.08, 0.055, 0.035), Vector3(1.2, 9, 9), 0.9, 1.3, 702)
	var lean := rng.randf_range(-3.0, 3.0)
	for sx: float in [-1.0, 1.0]:
		Art.part(body, _box(0.36, 0.14, 0.36), Art.stone(Color(0.22, 0.22, 0.22), 0.0), Vector3(sx * 1.1, 0.07, -0.25))
		Art.part(body, _box(0.24, 2.55, 0.24), post, Vector3(sx * 1.1, 1.4, -0.25), Vector3(0, 0, lean if sx > 0.0 else 0.0))
		Art.part(body, _box(0.14, 0.75, 0.16), post, Vector3(sx * 0.84, 2.34, -0.25), Vector3(0, 0, sx * 45.0))
		Art.part(body, _box(0.04, 0.2, 0.27), _iron(), Vector3(sx * 1.1, 2.68, -0.25))
	if rng.randf() < 0.35:
		# Cracked and sagging in the middle.
		for sx: float in [-1.0, 1.0]:
			Art.part(body, _box(1.36, 0.26, 0.28), beam, Vector3(sx * 0.67, 2.76 - 0.04, -0.25), Vector3(0, 0, sx * 2.0))
	else:
		Art.part(body, _box(2.7, 0.26, 0.28), beam, Vector3(0, 2.8, -0.25))
	if rng.randf() < 0.6:
		# A coil of rope hanging off a nail.
		Art.part(body, _rope_mesh(), _grain("rope", Color(0.4, 0.33, 0.22), Color(0.18, 0.14, 0.09), Vector3(12, 12, 12), 0.95, 0.8, 703), Vector3(1.1 * (1.0 if rng.randf() < 0.5 else -1.0), 1.6, -0.1))
	return {r = 0.3}


static func _rope_mesh() -> ArrayMesh:
	return _cached("ropecoil", func() -> ArrayMesh:
		var parts := []
		for k in 4:
			parts.append(_moved(_ring(0.15 + k * 0.006, 0.016, 12, 4), _xf(Vector3(k * 0.004, -0.15 - k * 0.012, 0.0), Vector3(90, 0, k * 6.0))))
		parts.append(Shape.limb(PackedVector3Array([Vector3(0.1, -0.26, 0.01), Vector3(0.12, -0.45, 0.03), Vector3(0.1, -0.6, 0.05)]), Shape.taper(0.016, 0.014, 3), 4, 1))
		return Shape.ground(Shape.merge(parts), 0.4, 0.7))


static func _mine_cart(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	var sleeper := _grain("sleeper", Color(0.2, 0.15, 0.1), Color(0.06, 0.045, 0.03), Vector3(9, 9, 1.2), 0.9, 1.3, 711)
	for x: float in [-0.95, -0.32, 0.32, 0.95]:
		Art.part(body, _box(0.18, 0.08, 1.0), sleeper, Vector3(x + rng.randf_range(-0.04, 0.04), 0.04, 0), Vector3(0, rng.randf_range(-5, 5), 0))
	var rail := _rust()
	for z: float in [-0.33, 0.33]:
		Art.part(body, _box(2.5, 0.07, 0.05), rail, Vector3(0, 0.115, z))
	var cart := Node3D.new()
	cart.rotation_degrees = Vector3(0, rng.randf_range(-6, 6), 0)
	cart.position.x = rng.randf_range(-0.3, 0.3)
	body.add_child(cart)
	var tub := Shape.material(Color(0.24, 0.13, 0.07), Color(0.07, 0.045, 0.03), 4.0, 0.85, 1.1, 0.35, 712)
	Art.part(cart, _box(1.0, 0.05, 0.68), tub, Vector3(0, 0.38, 0))
	for sz: float in [-1.0, 1.0]:
		Art.part(cart, _box(1.14, 0.62, 0.04), tub, Vector3(0, 0.69, sz * 0.38), Vector3(sz * 7.0, 0, 0))
		Art.part(cart, _box(1.2, 0.05, 0.06), _iron(), Vector3(0, 1.0, sz * 0.42))
	for sx: float in [-1.0, 1.0]:
		Art.part(cart, _box(0.04, 0.62, 0.8), tub, Vector3(sx * 0.535, 0.69, 0), Vector3(0, 0, -sx * 7.0))
		Art.part(cart, _box(0.06, 0.05, 0.86), _iron(), Vector3(sx * 0.575, 1.0, 0))
		for sz: float in [-1.0, 1.0]:
			Art.part(cart, _cyl(0.15, 0.15, 0.06, 12), _iron(), Vector3(sx * 0.36, 0.3, sz * 0.33), Vector3(90, 0, 0))
	for sx: float in [-1.0, 1.0]:
		Art.part(cart, _cyl(0.025, 0.025, 0.72, 6), _iron(), Vector3(sx * 0.36, 0.3, 0), Vector3(90, 0, 0))
	if rng.randf() < 0.65:
		# Ore still in it.
		Art.part(cart, _ore_mesh(), stone, Vector3(0, 0.84, 0))
	return {r = 0.7}


static func _ore_mesh() -> ArrayMesh:
	return _cached("ore", func() -> ArrayMesh:
		var rng := RandomNumberGenerator.new()
		rng.seed = 991
		var parts := []
		for k in 9:
			var s := rng.randf_range(0.1, 0.17)
			parts.append(_at(Shape.blob(Vector3(s, s * 0.8, s), 0.3, k * 1.9, 4, 6), Vector3(rng.randf_range(-0.38, 0.38), rng.randf_range(-0.04, 0.08), rng.randf_range(-0.24, 0.24))))
		return Shape.ground(Shape.merge(parts), 0.2, 0.6))


static func _fungus_shelf(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	var k: Array = _fungus_kit(rng.randi() % 4)
	_put(body, k[0], stone)
	var fm := Shape.material(Color(0.4, 0.34, 0.26), Color(0.27, 0.22, 0.16), 3.0, 0.8, 0.5, 0.0, 421)
	_put(body, k[1], fm)
	_put(body, k[2], fm)
	return {r = 0.4}


static func _fungus_kit(i: int) -> Array:
	return _cached("fungus%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3901 + i * 43
		var rx := rng.randf_range(0.42, 0.55)
		var ry := rng.randf_range(0.5, 0.75)
		var rz := 0.38
		var c := Vector3(0, ry * 0.75, -0.12)
		var rock := _at(Shape.warp(Shape.blob(Vector3(rx, ry, rz), 0.2, i * 1.7 + 3.0, 9, 12), func(p: Vector3) -> Vector3:
			return Vector3(p.x, p.y, maxf(p.z, -0.3))), c)
		var groups := [[], []]
		var n := rng.randi_range(7, 11)
		for b in n:
			var a := rng.randf_range(-1.3, 1.3)
			var y := rng.randf_range(-0.55, 0.55) * ry
			var k := sqrt(maxf(0.05, 1.0 - (y * y) / (ry * ry)))
			var at := c + Vector3(sin(a) * rx * k, y, cos(a) * rz * k)
			var r := rng.randf_range(0.12, 0.26)
			var sd := b * 1.3 + i
			var shelf := Shape.warp(Shape.blob(Vector3(r, r * 0.22, r * 0.85), 0.12, sd, 5, 10), func(p: Vector3) -> Vector3:
				var q := p
				if q.z < 0.0:
					q.z *= 0.25
				# The lip curls down a little at the edge.
				q.y -= (q.x * q.x + q.z * q.z) / (r * r) * r * 0.12
				return q)
			shelf = Shape.shade(shelf, func(p: Vector3, nrm: Vector3) -> Color:
				var d := clampf(Vector2(p.x, p.z).length() / r, 0.0, 1.0)
				var top := Color(0.62, 0.55, 0.48).lerp(Color(1.15, 1.1, 0.95), smoothstep(0.7, 1.0, d))
				var under := Color(1.25, 1.2, 1.05)
				return under.lerp(top, smoothstep(-0.3, 0.3, nrm.y)))
			groups[b % 2].append(_moved(shelf, Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, rng.randf_range(-0.1, 0.1)), at)))
		return [Shape.centered(Shape.ground(rock, ry * 1.5, 0.45)), Shape.centered(Shape.merge(groups[0])), Shape.centered(Shape.merge(groups[1]))])


static func _drip_pool(body: Node3D, rng: RandomNumberGenerator, wall: Color) -> Dictionary:
	var k: Array = _pool_kit(rng.randi() % 3)
	var water: StandardMaterial3D = _cached("mpool", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.04, 0.08, 0.09, 0.7)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.06
		m.metallic_specular = 1.0
		m.rim_enabled = true
		m.rim = 0.4
		return m)
	Art.part(body, k[2], Shape.material(Color(0.09, 0.1, 0.09), Color(0.04, 0.045, 0.04), 3.0, 0.5, 0.6, 0.0, 431))
	var w := Art.part(body, k[0], water)
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Art.part(body, k[1], Art.stone(wall.darkened(0.3), 0.6, Color(0.08, 0.18, 0.16)))
	return {r = -1.0}


static func _pool_kit(i: int) -> Array:
	return _cached("pool%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5101 + i * 7
		var n := 16
		var rs := PackedFloat32Array()
		var base := rng.randf_range(0.6, 0.85)
		for s in n:
			rs.append(base * (1.0 + 0.18 * sin(s * 0.9 + i) + rng.randf_range(-0.08, 0.08)))
		var pts := PackedVector3Array([Vector3(0, 0.03, 0)])
		for s in n + 1:
			var a := TAU * s / n
			pts.append(Vector3(cos(a) * rs[s % n], 0.03, sin(a) * rs[s % n] * 0.8))
		var water := Shape.sheet(pts)
		var bed := Shape.warp(water, func(p: Vector3) -> Vector3: return Vector3(p.x * 0.97, 0.008, p.z * 0.97))
		var stones := []
		for s in n:
			if rng.randf() < 0.25:
				continue
			var a := TAU * (s + rng.randf_range(-0.2, 0.2)) / n
			var r := rs[s] + rng.randf_range(0.0, 0.08)
			var sz := rng.randf_range(0.07, 0.22)
			stones.append(_moved(Shape.blob(Vector3(sz * 1.4, sz * 0.35, sz), 0.4, s * 1.7 + i, 4, 7), Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.2, 0.2)), Vector3(cos(a) * r, sz * 0.08, sin(a) * r * 0.8))))
		return [water, Shape.ground(Shape.merge(stones), 0.12, 0.6), bed])


# --- The frozen keep ------------------------------------------------------------------


static func _banner(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var blue := rng.randf() < 0.45
	var k: Array = _banner_kit(rng.randi() % 3, blue)
	Art.part(body, k[0], Art.cloth(Color.WHITE, 130.0))
	_put(body, k[1], _frost_m())
	return {r = 0.25}


static func _banner_kit(i: int, blue: bool) -> Array:
	return _cached("banner%d%s" % [i, blue], func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 6601 + i * 13
		var base := Color(0.12, 0.15, 0.3) if blue else Color(0.36, 0.08, 0.07)
		var device := Color(0.55, 0.5, 0.36)
		var cols := 10
		var nrow := 18
		var w := 0.74
		var l := 1.5
		var cut := PackedFloat32Array()
		for c in cols + 1:
			var u := float(c) / cols
			# Swallowtail, torn deeper in places.
			cut.append(absf(u - 0.5) * 0.5 - 0.25 + rng.randf_range(0.0, 0.3))
		var rows := []
		var colors := []
		for r in nrow + 1:
			var v := float(r) / nrow
			var row := PackedVector3Array()
			var crow := PackedColorArray()
			for c in cols + 1:
				var u := float(c) / cols
				var vv := v * (l + cut[c]) / l
				var y := 2.32 - vv * l
				var x := (u - 0.5) * w
				var z := -0.19 + sin(u * TAU * 2.2 + i) * 0.035 * (0.3 + vv) + vv * vv * 0.05
				row.append(Vector3(x, y, z))
				var col := base * (1.0 - 0.3 * vv)
				# A faded device: a pale cross on the field, a border at the top.
				if (absf(u - 0.5) < 0.09 and vv > 0.12 and vv < 0.62) or (absf(vv - 0.32) < 0.05 and absf(u - 0.5) < 0.3) or vv < 0.05:
					col = device
				# Rime along the top and in patches.
				var frost := (1.0 - smoothstep(0.0, 0.1, vv)) * 0.55 + smoothstep(0.85, 1.0, vv) * 0.3 + smoothstep(0.8, 0.98, sin(u * 17.0 + i) * sin(vv * 11.0 + 2.0 * i)) * 0.25
				crow.append(col.lerp(Color(0.85, 0.88, 0.92), clampf(frost, 0.0, 0.8)))
			rows.append(row)
			colors.append(crow)
		var holes := {}
		for h in rng.randi_range(2, 5):
			holes[Vector2i(rng.randi_range(1, cols - 2), rng.randi_range(4, nrow - 2))] = true
		var cloth := _sheet2(rows, colors, holes)
		var pole := Color(0.2, 0.18, 0.17)
		var parts := [
			Shape.limb(PackedVector3Array([Vector3(0, 0.0, -0.25), Vector3(0, 2.7, -0.25)]), Shape.taper(0.035, 0.03, 2), 8, 1),
			Shape.limb(PackedVector3Array([Vector3(-0.45, 2.34, -0.21), Vector3(0.45, 2.34, -0.21)]), Shape.taper(0.022, 0.022, 2), 6, 1),
			_at(Shape.blob(Vector3(0.05, 0.05, 0.05), 0.0, 1.0, 5, 8), Vector3(-0.47, 2.34, -0.21)),
			_at(Shape.blob(Vector3(0.05, 0.05, 0.05), 0.0, 1.0, 5, 8), Vector3(0.47, 2.34, -0.21)),
			_at(Shape.lathe(PackedVector2Array([Vector2(0.04, 0.0), Vector2(0.06, 0.06), Vector2(0.0, 0.22)]), 6), Vector3(0, 2.7, -0.25)),
		]
		for f in 3:
			var a := PI * 0.5 + TAU * f / 3.0 + 0.4
			var d := Vector3(cos(a), 0, sin(a))
			parts.append(Shape.limb(PackedVector3Array([Vector3(0, 0.5, -0.25), Vector3(0, 0.0, -0.25) + d * 0.45 + Vector3(0, 0.02, 0)]), Shape.taper(0.028, 0.022, 2), 6, 1))
		return [Shape.ground(cloth, 2.4, 0.55), Shape.centered(_frost(Shape.merge(parts), pole, 0.9, 2.7))])


static func _weapon_rack(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	for pc: Array in _rack_kit(rng.randi() % 3):
		_put(body, pc, _frost_m())
	return {r = 0.6}


static func _rack_kit(i: int) -> Array:
	return _cached("rack%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7701 + i * 17
		var wood := Color(0.3, 0.22, 0.15)
		var steel := Color(0.4, 0.42, 0.46)
		var frame := []
		for sx: float in [-1.0, 1.0]:
			frame.append(_boxm(Vector3(0.1, 1.55, 0.12), _xf(Vector3(sx * 0.75, 0.775, -0.32))))
			frame.append(_boxm(Vector3(0.12, 0.08, 0.5), _xf(Vector3(sx * 0.75, 0.04, -0.15))))
		frame.append(_boxm(Vector3(1.62, 0.09, 0.08), _xf(Vector3(0, 1.38, -0.3))))
		frame.append(_boxm(Vector3(1.62, 0.07, 0.07), _xf(Vector3(0, 0.6, -0.3))))
		frame.append(_boxm(Vector3(1.56, 0.1, 0.12), _xf(Vector3(0, 0.12, 0.0))))
		var out := [Shape.centered(_frost(Shape.merge(frame), wood, 1.0, 1.5))]
		var spears := []
		var heads := []
		var n := rng.randi_range(3, 5)
		for s in n:
			if rng.randf() < 0.15:
				continue
			var x := lerpf(-0.6, 0.6, float(s) / (n - 1)) + rng.randf_range(-0.04, 0.04)
			var butt := Vector3(x, 0.17, 0.0)
			var rest := Vector3(x + rng.randf_range(-0.1, 0.1), 1.43, -0.3)
			var dir := (rest - butt).normalized()
			var end := butt + dir * rng.randf_range(2.0, 2.3)
			spears.append(Shape.limb(PackedVector3Array([butt, end]), Shape.taper(0.018, 0.015, 2), 5, 1))
			var head := Shape.warp(Shape.lathe(PackedVector2Array([Vector2(0.018, 0.0), Vector2(0.022, 0.06), Vector2(0.045, 0.14), Vector2(0.03, 0.24), Vector2(0.0, 0.3)]), 4), func(p: Vector3) -> Vector3:
				return Vector3(p.x, p.y, p.z * 0.3))
			heads.append(_moved(head, Transform3D(Basis(Quaternion(Vector3.UP, dir)), end)))
		out.append(Shape.centered(_frost(Shape.merge(spears), wood, 0.7, 2.2)))
		# A pair of swords stood point-down in the trough, and a shield.
		for s: float in [-0.3, 0.32]:
			if rng.randf() < 0.25:
				continue
			var lean := rng.randf_range(-0.12, 0.12)
			var b := Basis(Vector3.FORWARD, lean) * Basis(Vector3.RIGHT, -0.25)
			var o := Vector3(s, 0.16, -0.02)
			var blade := _moved(_moved(Art.blade_mesh(0.85), Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0.85, 0))), Transform3D(b, o))
			heads.append(blade)
			heads.append(_moved(Shape.merge([_boxm(Vector3(0.24, 0.04, 0.05), _xf(Vector3(0, 0.87, 0))), Shape.limb(PackedVector3Array([Vector3(0, 0.89, 0), Vector3(0, 1.08, 0)]), Shape.taper(0.022, 0.022, 2), 5, 1), _at(Shape.blob(Vector3(0.04, 0.045, 0.04), 0.0, 1.0, 4, 6), Vector3(0, 1.11, 0))]), Transform3D(b, o)))
		out.append(Shape.centered(_frost(Shape.merge(heads), steel, 0.6, 2.2)))
		if i != 1:
			var sh := Shape.merge([
				_moved(Shape.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.32, 0.0), Vector2(0.33, 0.03), Vector2(0.3, 0.05), Vector2(0.0, 0.05)]), 16), _xf(Vector3.ZERO, Vector3(90, 0, 0))),
				_at(Shape.blob(Vector3(0.08, 0.08, 0.05), 0.0, 1.0, 5, 8), Vector3(0, 0, 0.06)),
			])
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			out.append(Shape.centered(_frost(_moved(sh, Transform3D(Basis(Vector3.UP, side * 0.3) * Basis(Vector3.RIGHT, -0.25), Vector3(side * 0.98, 0.33, -0.12))), Color(0.3, 0.12, 0.08) if i == 0 else Color(0.14, 0.16, 0.24), 1.0, 1.0)))
		return out)


static func _snowdrift(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var m := Art.part(body, _drift(rng.randi() % 4, 1.0), _drift_m())
	m.scale = Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.8, 1.2), rng.randf_range(0.8, 1.3))
	return {r = -1.0}


## A wind-shaped heap of snow [param s] metres or so across, meeting the
## floor smoothly at its edge.
static func _drift(i: int, s: float) -> ArrayMesh:
	return _cached("drift%d%.2f" % [i, s], func() -> ArrayMesh:
		var rng := RandomNumberGenerator.new()
		rng.seed = 8101 + i * 3
		var rx := rng.randf_range(1.1, 1.6) * s
		var rz := rng.randf_range(0.7, 1.0) * s
		var h := rng.randf_range(0.4, 0.6) * s
		var crest := rng.randf_range(-0.4, 0.4)
		var height := func(u: float, v: float) -> float:
			var q := maxf(0.0, 1.0 - u * u - v * v)
			# Steep on the lee side (+z), long on the windward.
			var lee := 1.0 + 0.5 * clampf(-v, -1.0, 1.0)
			var lump := 1.0 + 0.15 * sin(u * 5.0 + i) * sin(v * 4.0 + i * 2.0)
			return h * pow(q, 1.4) * lee * lump * (1.0 + crest * u * 0.4)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rings := 9
		var seg := 20
		var pt := func(ri: int, si: int) -> Vector3:
			var t := float(ri) / rings
			var a := TAU * si / seg
			var u := cos(a) * t
			var v := sin(a) * t
			var edge := 1.0 + 0.16 * sin(a * 3.0 + i * 1.7) + 0.08 * sin(a * 7.0 + i)
			return Vector3(u * rx * edge, height.call(u, v) - 0.01, v * rz * edge)
		for ri in rings:
			for si in seg:
				var a: Vector3 = pt.call(ri, si)
				var b: Vector3 = pt.call(ri + 1, si)
				var c: Vector3 = pt.call(ri + 1, si + 1)
				var d: Vector3 = pt.call(ri, si + 1)
				_tri(st, a, b, c, Vector3.UP)
				if ri > 0:
					_tri(st, a, c, d, Vector3.UP)
		var m := Shape.merge([st.commit()])
		return Shape.shade(m, func(p: Vector3, nrm: Vector3) -> Color:
			var k := lerpf(0.8, 1.0, clampf(p.y / h, 0.0, 1.0))
			var c := Color(0.74, 0.8, 0.93).lerp(Color.WHITE, smoothstep(0.6, 1.0, nrm.y)) * k
			# Thinning out to nothing at the edge, so it lies on the floor.
			c.a = smoothstep(0.0, 0.14, p.y + 0.01)
			return c))


static func _frozen_statue(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	Art.part(body, _box(1.04, 0.24, 1.04), stone, Vector3(0, 0.12, 0))
	Art.part(body, _box(0.82, 0.52, 0.82), stone, Vector3(0, 0.5, 0))
	Art.part(body, _box(0.94, 0.08, 0.94), stone, Vector3(0, 0.8, 0))
	for pc: Array in _knight_kit(rng.randi() % 2):
		_put(body, pc, _frost_m())
	var ice := _put(body, _icicles_kit(), _ice_m())
	ice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {r = 0.55}


static func _knight_kit(i: int) -> Array:
	return _cached("knight%d" % i, func() -> Array:
		var g := Color(0.27, 0.28, 0.31)
		var y0 := 0.84
		var legs := []
		for sx: float in [-1.0, 1.0]:
			legs.append(Shape.limb(PackedVector3Array([Vector3(sx * 0.11, y0 + 0.06, 0.02), Vector3(sx * 0.115, y0 + 0.45, 0.0), Vector3(sx * 0.11, y0 + 0.85, 0.0)]), PackedFloat32Array([0.065, 0.075, 0.095]), 8, 2))
			legs.append(_at(Shape.blob(Vector3(0.07, 0.055, 0.13), 0.05, sx, 5, 8), Vector3(sx * 0.11, y0 + 0.05, 0.05)))
			legs.append(_at(Shape.blob(Vector3(0.075, 0.06, 0.06), 0.05, sx + 2.0, 5, 8), Vector3(sx * 0.115, y0 + 0.46, 0.04)))
		legs.append(Shape.lathe(PackedVector2Array([Vector2(0.2, y0 + 0.66), Vector2(0.24, y0 + 0.78), Vector2(0.235, y0 + 0.95), Vector2(0.21, y0 + 1.0)]), 14, 6, 0.05))
		var torso := [Shape.lathe(PackedVector2Array([Vector2(0.2, y0 + 0.95), Vector2(0.23, y0 + 1.12), Vector2(0.25, y0 + 1.3), Vector2(0.2, y0 + 1.42), Vector2(0.08, y0 + 1.48)]), 14)]
		# A cape from the shoulders to the plinth, open at the front.
		torso.append(Shape.lathe(PackedVector2Array([Vector2(0.36, y0 + 0.02), Vector2(0.33, y0 + 0.5), Vector2(0.29, y0 + 1.0), Vector2(0.27, y0 + 1.36), Vector2(0.2, y0 + 1.44)]), 12, 6, 0.1, PI * 0.95))
		for sx: float in [-1.0, 1.0]:
			torso.append(_at(Shape.blob(Vector3(0.13, 0.09, 0.12), 0.06, sx * 3.0, 6, 9), Vector3(sx * 0.25, y0 + 1.39, 0.0)))
			torso.append(Shape.limb(PackedVector3Array([Vector3(sx * 0.27, y0 + 1.36, 0.02), Vector3(sx * 0.26, y0 + 1.13, 0.1), Vector3(sx * 0.07, y0 + 1.04, 0.24)]), PackedFloat32Array([0.07, 0.06, 0.05]), 7, 2))
			torso.append(_at(Shape.blob(Vector3(0.05, 0.05, 0.05), 0.08, sx, 4, 6), Vector3(sx * 0.035, y0 + 1.04, 0.26)))
		var head := [
			_at(Shape.blob(Vector3(0.12, 0.15, 0.13), 0.02, 2.0, 7, 10), Vector3(0, y0 + 1.62, 0.0)),
			_at(Shape.blob(Vector3(0.03, 0.05, 0.13), 0.0, 1.0, 4, 6), Vector3(0, y0 + 1.75, -0.01)),
			Shape.tint(_at(Shape.blob(Vector3(0.09, 0.012, 0.03), 0.0, 1.0, 3, 6), Vector3(0, y0 + 1.64, 0.115)), Color(0.15, 0.15, 0.17)),
		]
		if i == 1:
			# A great helm with a raised comb from brow to nape.
			head.append(Shape.limb(Shape.curve(Vector3(0, y0 + 1.7, 0.1), Vector3(0, y0 + 1.82, -0.02), Vector3(0, y0 + 1.68, -0.14), 5), Shape.taper(0.018, 0.012, 5), 5, 1))
		var sword := [
			_moved(Art.blade_mesh(0.9), Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, y0 + 0.94, 0.27))),
			_boxm(Vector3(0.34, 0.05, 0.06), _xf(Vector3(0, y0 + 0.96, 0.27))),
			Shape.limb(PackedVector3Array([Vector3(0, y0 + 0.98, 0.27), Vector3(0, y0 + 1.12, 0.27)]), Shape.taper(0.025, 0.025, 2), 5, 1),
		]
		return [
			Shape.centered(_frost(Shape.merge(legs), g, 0.55, 2.6)),
			Shape.centered(_frost(Shape.merge(torso), g, 0.55, 2.6)),
			Shape.centered(_frost(Shape.merge(head), g, 0.55, 2.6)),
			Shape.centered(_frost(Shape.merge(sword), g, 0.45, 2.6)),
		])


## Icicles off the statue: the pauldrons, the elbows, the guard, the
## plinth's edge.
static func _icicles_kit() -> Array:
	return _cached("staticicles", func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		var y0 := 0.84
		var spots: Array[Vector3] = []
		for sx: float in [-1.0, 1.0]:
			for k in 3:
				spots.append(Vector3(sx * (0.2 + k * 0.06), y0 + 1.31, rng.randf_range(-0.06, 0.08)))
			spots.append(Vector3(sx * 0.27, y0 + 1.09, 0.1))
			spots.append(Vector3(sx * 0.15, y0 + 0.93, 0.27))
		for k in 10:
			var a := TAU * k / 10.0 + rng.randf_range(-0.2, 0.2)
			var d := Vector3(cos(a), 0, sin(a))
			var p := d / maxf(absf(d.x), absf(d.z)) * 0.47
			spots.append(Vector3(p.x, 0.76, p.z))
		var parts := []
		for s: Vector3 in spots:
			var l := rng.randf_range(0.06, 0.2)
			parts.append(_icicle(s, l, rng.randf_range(0.012, 0.022)))
		return Shape.centered(Shape.merge(parts)))


static func _icicle(at: Vector3, l: float, r: float) -> ArrayMesh:
	return _at(Shape.lathe(PackedVector2Array([Vector2(0.0, -l), Vector2(r * 0.45, -l * 0.55), Vector2(r, 0.0), Vector2(0.0, 0.01)]), 5), at)


static func _barricade(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	for pc: Array in _barricade_kit(rng.randi() % 3):
		_put(body, pc, _frost_m())
	Art.part(body, _drift(1, 0.55), _drift_m(), Vector3(0, 0, 0.15))
	return {r = 0.8}


static func _barricade_kit(i: int) -> Array:
	return _cached("barricade%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9301 + i * 23
		var wood := Color(0.3, 0.23, 0.16)
		var out := []
		for sx: float in [-0.9, 0.9]:
			var x := sx + rng.randf_range(-0.05, 0.05)
			out.append(Shape.centered(_frost(Shape.merge([
				_boxm(Vector3(0.13, 1.45, 0.13), _xf(Vector3(x, 0.55, 0), Vector3(0, 0, 34))),
				_boxm(Vector3(0.13, 1.45, 0.13), _xf(Vector3(x, 0.55, 0.0), Vector3(0, 0, -34))),
			]), wood, 1.0, 1.3)))
		var broken := rng.randi() % 3
		for p in 3:
			var y := 0.38 + p * 0.33
			var tilt := rng.randf_range(-4, 4)
			if p == broken:
				# Snapped: one end still nailed on and hanging, the rest down.
				var l := rng.randf_range(0.7, 1.1)
				out.append(Shape.centered(_frost(Shape.merge([_boxm(Vector3(l, 0.2, 0.05), _xf(Vector3(-1.15 + l * 0.5, y - 0.05, 0.13), Vector3(0, 0, -12)))] + _splinters(Vector3(-1.15 + l, y - 0.15, 0.13), rng)), wood, 1.0, 1.3)))
				out.append(Shape.centered(_frost(_boxm(Vector3(2.4 - l - 0.3, 0.2, 0.05), _xf(Vector3(0.4, 0.04, 0.55 + rng.randf_range(0, 0.2)), Vector3(90, rng.randf_range(-20, 20), 0))), wood, 1.0, 1.3)))
			else:
				out.append(Shape.centered(_frost(_boxm(Vector3(2.4, 0.2, 0.05), _xf(Vector3(0, y, 0.13), Vector3(0, 0, tilt))), wood, 1.0, 1.3)))
		# Sharpened stakes pointing out.
		var stakes := []
		for s in 3:
			var x := rng.randf_range(-0.8, 0.8)
			var b := Vector3(x, 0.1, -0.15)
			var d := Vector3(rng.randf_range(-0.2, 0.2), 0.55, 1.0).normalized()
			stakes.append(Shape.limb(PackedVector3Array([b, b + d * 0.9, b + d * 1.1]), PackedFloat32Array([0.045, 0.04, 0.0]), 5, 1))
		out.append(Shape.centered(_frost(Shape.merge(stakes), wood, 1.0, 1.3)))
		return out)


static func _splinters(at: Vector3, rng: RandomNumberGenerator) -> Array:
	var out := []
	for k in 3:
		out.append(Shape.limb(PackedVector3Array([at + Vector3(-0.05, rng.randf_range(0.0, 0.18), 0), at + Vector3(rng.randf_range(0.08, 0.2), rng.randf_range(0.0, 0.18), 0)]), PackedFloat32Array([0.02, 0.003]), 3, 1))
	return out


static func _icicle_rock(body: Node3D, rng: RandomNumberGenerator, stone: Material) -> Dictionary:
	var k: Array = _icerock_kit(rng.randi() % 4)
	_put(body, k[0], stone)
	_put(body, k[1], _snow_m())
	var ice := _put(body, k[2], _ice_m())
	ice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {r = 0.6}


static func _icerock_kit(i: int) -> Array:
	return _cached("icerock%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2201 + i * 47
		var rx := rng.randf_range(0.6, 0.8)
		var ry := rng.randf_range(0.5, 0.75)
		var rz := rng.randf_range(0.5, 0.65)
		var flare := 0.5
		var cy := ry * 0.55
		# Wider near the top than at the foot, so it overhangs.
		var shape := func(p: Vector3) -> Vector3:
			var t := clampf((p.y + ry) / (2.0 * ry), 0.0, 1.0)
			var k := (1.0 - flare * 0.6) + flare * smoothstep(0.2, 0.75, t)
			return Vector3(p.x * k, p.y * (0.85 if p.y > 0.0 else 1.0), p.z * k) + Vector3(0, cy, 0)
		var rock := Shape.warp(Shape.blob(Vector3(rx, ry, rz), 0.18, i * 3.1 + 2.0, 9, 13), shape)
		var snow := Shape.warp(Shape.blob(Vector3(rx * 0.85, ry * 0.3, rz * 0.85), 0.15, i * 3.1 + 5.0, 6, 13), func(p: Vector3) -> Vector3:
			return Vector3(p.x, maxf(p.y, -ry * 0.05), p.z) + Vector3(0, cy + ry * 0.7, 0))
		var ice := []
		var n := rng.randi_range(9, 15)
		for c in n:
			var a := TAU * c / n + rng.randf_range(-0.15, 0.15)
			# Under the widest ring, a little in.
			var t := 0.66
			var y := -ry + t * 2.0 * ry
			var kk := (1.0 - flare * 0.6) + flare * smoothstep(0.2, 0.75, t)
			var ring := sqrt(maxf(0.0, 1.0 - (y * y) / (ry * ry)))
			var p := Vector3(cos(a) * rx * kk * ring * 0.97, y * 0.85 + cy - 0.03, sin(a) * rz * kk * ring * 0.97)
			ice.append(_icicle(p, rng.randf_range(0.15, 0.55), rng.randf_range(0.025, 0.05)))
		return [Shape.centered(Shape.ground(rock, ry * 2.0, 0.4, Color(0.6, 0.7, 0.9))), Shape.centered(Shape.ground(snow, ry * 2.0, 0.8, Color(0.75, 0.82, 0.95))), Shape.centered(Shape.merge(ice))])


# --- The infernal pit ------------------------------------------------------------------


static func _spikes(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _spikes_kit(rng.randi() % 4)
	_put(body, k[0], _ash_m())
	_put(body, k[1], _rust())
	_put(body, k[2], _char_m())
	if k.size() > 3:
		_put(body, k[3], _char_m())
	return {r = 0.5}


static func _spikes_kit(i: int) -> Array:
	return _cached("spikes%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1301 + i * 61
		var mound := _heap(0.75, 0.65, 0.22, i * 2.0)
		var iron := []
		var bone := []
		var n := rng.randi_range(7, 10)
		var tallest := Vector3.ZERO
		var tall_dir := Vector3.UP
		var tall_l := 0.0
		for s in n:
			var a := TAU * s / n + rng.randf_range(-0.3, 0.3)
			var d := Vector3(cos(a), 0, sin(a))
			var at := d * rng.randf_range(0.0, 0.35) + Vector3(0, 0.05, 0)
			var l := rng.randf_range(0.8, 2.0)
			var dir := (Vector3.UP + d * rng.randf_range(0.1, 0.5)).normalized()
			if s % 3 == 2:
				# A bone horn, curved.
				var side := d.cross(Vector3.UP)
				bone.append(Shape.limb(Shape.curve(at + Vector3(0, -0.1, 0), at + dir * l * 0.55 + side * 0.1, at + dir * l * 0.85 + d * 0.25, 5), Shape.taper(0.1, 0.01, 5), 6, 2))
			else:
				var pts := PackedVector3Array([at + Vector3(0, -0.1, 0), at + dir * l * 0.8, at + dir * l])
				var spike := Shape.limb(pts, PackedFloat32Array([0.065, 0.04, 0.0]), 4, 1)
				iron.append(Shape.shade(spike, func(p: Vector3, _n: Vector3) -> Color:
					# Old blood towards the point.
					var k := smoothstep(0.4, 0.95, (p - at).dot(dir) / l)
					return Color.WHITE.lerp(Color(0.45, 0.12, 0.08), k * 0.8)))
				if l > tall_l:
					tall_l = l
					tallest = at
					tall_dir = dir
		var out := [Shape.centered(Shape.ground(mound, 0.16, 0.6)), Shape.centered(Shape.ground(Shape.merge(iron), 1.5, 0.5)), Shape.centered(Shape.ground(Shape.merge(bone), 1.5, 0.5))]
		if i != 3 and tall_l > 0.0:
			var c := tallest + tall_dir * tall_l * 0.62
			var b := Basis(Quaternion(Vector3.UP, tall_dir)) * Basis(Vector3.RIGHT, -0.4)
			out.append(Shape.centered(_moved(_skull1(i * 1.1 + 5.0, Color(0.03, 0.02, 0.02)), Transform3D(b, c - b * Vector3(0, 0.1, 0)))))
		return out)


static func _cage(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _cage_kit(rng.randi() % 2)
	var charred := _grain("charwood", Color(0.13, 0.1, 0.08), Color(0.03, 0.025, 0.02), Vector3(9, 1.4, 9), 0.95, 1.5, 801)
	_put(body, k[0], charred)
	_put(body, k[1], _rust())
	_put(body, k[2], _char_m())
	return {r = 0.6}


static func _cage_kit(i: int) -> Array:
	return _cached("cage%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2901 + i * 7
		var wood := [
			Shape.limb(PackedVector3Array([Vector3(0, -0.1, -0.48), Vector3(0.02, 1.5, -0.47), Vector3(0, 3.0, -0.48)]), PackedFloat32Array([0.13, 0.11, 0.1]), 7, 1),
			Shape.limb(PackedVector3Array([Vector3(0, 2.85, -0.58), Vector3(0, 2.86, 0.32)]), Shape.taper(0.08, 0.075, 2), 6, 1),
			Shape.limb(PackedVector3Array([Vector3(0, 2.2, -0.46), Vector3(0, 2.8, -0.05)]), Shape.taper(0.06, 0.06, 2), 6, 1),
		]
		var c := Vector3(0, 0, 0.18)
		var top := 2.28
		var prof := [Vector2(0.15, 0.42), Vector2(0.23, 0.62), Vector2(0.21, 1.1), Vector2(0.27, 1.72), Vector2(0.2, 2.05), Vector2(0.05, top)]
		var iron := []
		var bars := 9
		for b in bars:
			var a := TAU * b / bars
			var pts := PackedVector3Array()
			for p: Vector2 in prof:
				pts.append(c + Vector3(cos(a) * p.x, p.y, sin(a) * p.x))
			iron.append(Shape.limb(pts, Shape.taper(0.012, 0.012, pts.size()), 4, 1))
		for p in [0, 2, 3]:
			var pp: Vector2 = prof[p]
			iron.append(_at(_ring(pp.x, 0.016, 10, 4), c + Vector3(0, pp.y, 0)))
		iron.append(_at(_ring(0.05, 0.02, 8, 4), c + Vector3(0, top + 0.02, 0)))
		iron.append(_at(Shape.lathe(PackedVector2Array([Vector2(0.0, 0.4), Vector2(0.15, 0.4), Vector2(0.16, 0.43), Vector2(0.0, 0.44)]), 9), c))
		iron.append(_chain(PackedVector3Array([c + Vector3(0, top + 0.05, 0), Vector3(c.x, 2.8, c.z)]), 0.09, 0.011))
		# A slumped skeleton inside, one arm hanging out between the bars.
		var bones := []
		bones.append(_moved(_skull1(i + 2.0, Color(0.05, 0.035, 0.03)), Transform3D(Basis(Vector3.RIGHT, 0.6) * Basis(Vector3.FORWARD, 0.3), c + Vector3(0.02, 1.62, 0.03))))
		bones.append(Shape.limb(Shape.curve(c + Vector3(0, 1.6, -0.08), c + Vector3(0, 1.2, -0.12), c + Vector3(0, 0.9, -0.06), 5), Shape.taper(0.022, 0.02, 5), 5, 1))
		for r in 4:
			var y := 1.48 - r * 0.09
			bones.append(_at(Shape.limb(Shape.curve(Vector3(-0.03, 0, -0.09), Vector3(-0.15, -0.03, 0.02), Vector3(0.0, -0.06, 0.1), 4), Shape.taper(0.01, 0.007, 4), 4, 1), c + Vector3(0, y, 0)))
			bones.append(_at(Shape.limb(Shape.curve(Vector3(0.03, 0, -0.09), Vector3(0.15, -0.03, 0.02), Vector3(0.0, -0.06, 0.1), 4), Shape.taper(0.01, 0.007, 4), 4, 1), c + Vector3(0, y, 0)))
		bones.append(_at(Shape.blob(Vector3(0.12, 0.07, 0.08), 0.2, 3.0, 4, 7), c + Vector3(0, 0.9, -0.02)))
		bones.append(_moved(_bone(0.4, 0.02, 1.0), Transform3D(Basis(Vector3.FORWARD, 1.2), c + Vector3(0.24, 1.3, 0.05))))
		bones.append(_moved(_bone(0.32, 0.016, 2.0), Transform3D(Basis(Vector3.FORWARD, 1.4), c + Vector3(0.33, 0.96, 0.08))))
		for k in 3:
			bones.append(_moved(_bone(rng.randf_range(0.3, 0.42), 0.02, k + 4.0), Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, rng.randf_range(0.2, 0.6)), c + Vector3(rng.randf_range(-0.06, 0.06), 0.52 + k * 0.05, rng.randf_range(-0.06, 0.06)))))
		return [Shape.centered(Shape.ground(Shape.merge(wood), 3.0, 0.5)), Shape.centered(Shape.ground(Shape.merge(iron), 2.5, 0.55)), Shape.centered(Shape.ground(Shape.merge(bones), 2.0, 0.6))])


static func _chains_pit(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _chains_pit_kit(rng.randi() % 3)
	Art.part(body, k[0], _grain("charwood", Color(0.13, 0.1, 0.08), Color(0.03, 0.025, 0.02), Vector3(9, 1.4, 9), 0.95, 1.5, 801))
	Art.part(body, k[1], _rust())
	if k[2] != null:
		Art.part(body, k[2], _char_m())
	return {r = -1.0}


static func _chains_pit_kit(i: int) -> Array:
	return _cached("chainspit%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3701 + i * 5
		var base := Vector3(0, 0, -0.3)
		var h := rng.randf_range(1.8, 2.3)
		var stake := Shape.merge([
			Shape.limb(PackedVector3Array([base + Vector3(0, -0.1, 0), base + Vector3(0.03, h * 0.6, 0), base + Vector3(0, h, 0), base + Vector3(0.02, h + 0.25, 0)]), PackedFloat32Array([0.15, 0.13, 0.11, 0.0]), 6, 2),
		])
		var iron := [_at(Shape.lathe(PackedVector2Array([Vector2(0.125, -0.06), Vector2(0.135, 0.0), Vector2(0.125, 0.06)]), 10), base + Vector3(0, h - 0.25, 0))]
		var collar := base + Vector3(0, h - 0.25, 0)
		var ends: Array[Vector3] = [Vector3(-0.75, 0.02, 0.35), Vector3(0.7, 0.02, 0.45), Vector3(0.1, 0.02, 0.8)]
		for e in ends.size():
			if i == 1 and e == 2:
				continue
			var end: Vector3 = ends[e] + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
			var from := collar + (Vector3(end.x, 0, end.z) - Vector3(collar.x, 0, collar.z)).normalized() * 0.14
			var pts := Shape.curve(from, from.lerp(end, 0.4) + Vector3(0, -h * 0.6, 0), end, 9)
			for p in pts.size():
				pts[p].y = maxf(pts[p].y, 0.02)
			iron.append(_chain(pts, 0.18, 0.022))
			# A floor ring or an open shackle at the end.
			iron.append(_moved(_ring(0.07, 0.016, 10, 4), _xf(end + Vector3(0, 0.015, 0), Vector3(90, 0, 0))))
		var skull: ArrayMesh = null
		if i != 2:
			skull = _moved(_skull1(i * 2.0 + 1.0, Color(0.03, 0.02, 0.02)), Transform3D(Basis(Vector3.UP, rng.randf_range(-1.0, 1.0)) * Basis(Vector3.RIGHT, -0.3), Vector3(rng.randf_range(-0.4, 0.4), 0.0, 0.25)))
			skull = Shape.ground(skull, 0.2, 0.6)
		return [Shape.ground(stake, h, 0.45), Shape.ground(Shape.merge(iron), h, 0.55), skull])


static func _skull_pile(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _skull_pile_kit(rng.randi() % 3)
	_put(body, k[0], _ash_m())
	for n in [1, 2, 3]:
		_put(body, k[n], _char_m())
	var em := _put(body, k[4], Fx.glow(Color(1.0, 0.35, 0.08), 1.6))
	em.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {r = 0.5}


static func _skull_pile_kit(i: int) -> Array:
	return _cached("skullpile%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4901 + i * 97
		var mound := _heap(0.75, 0.7, 0.18, i * 1.7)
		var groups := [[], [], []]
		var embers := []
		var layers := [[8, 0.42, 0.04], [5, 0.24, 0.2], [2, 0.08, 0.38]]
		for li in layers.size():
			var ly: Array = layers[li]
			var n: int = ly[0]
			for s in n:
				var a := TAU * s / n + li * 0.5 + rng.randf_range(-0.15, 0.15)
				var at := Vector3(cos(a) * ly[1], ly[2], sin(a) * ly[1])
				var xf := Transform3D(Basis(Vector3.UP, -a + PI * 0.5 + rng.randf_range(-0.5, 0.5)) * Basis(Vector3.RIGHT, rng.randf_range(-0.35, 0.2)) * Basis(Vector3.FORWARD, rng.randf_range(-0.3, 0.3)) * Basis.from_scale(Vector3.ONE * rng.randf_range(1.25, 1.45)), at)
				var sk := _skull(s * 1.9 + li * 7.0 + i)
				var soot := Color.WHITE * rng.randf_range(0.6, 1.0)
				if rng.randf() < 0.35:
					groups[li].append(Shape.tint(_moved(sk[0], xf), soot))
					embers.append(_moved(sk[1], xf))
				else:
					groups[li].append(Shape.tint(_moved(Shape.merge([sk[0], Shape.tint(sk[1], Color(0.04, 0.03, 0.025))]), xf), soot))
		if embers.is_empty():
			embers.append(_moved(_skull(1.0)[1], Transform3D(Basis(), Vector3(0, 0.28, 0))))
		var out := [Shape.centered(Shape.ground(mound, 0.14, 0.6))]
		for g: Array in groups:
			out.append(Shape.centered(Shape.ground(Shape.merge(g), 0.5, 0.45)))
		out.append(Shape.centered(Shape.merge(embers)))
		return out)


static func _obsidian_spire(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _spire_kit(rng.randi() % 3)
	var glass: StandardMaterial3D = _cached("mobsidian", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.035, 0.03, 0.04)
		m.roughness = 0.08
		m.metallic = 0.35
		m.metallic_specular = 0.9
		m.rim_enabled = true
		m.rim = 0.25
		m.rim_tint = 0.2
		return m)
	for n in k.size() - 1:
		_put(body, k[n], glass)
	var g := _put(body, k[k.size() - 1], Fx.glow(Color(1.0, 0.32, 0.07), 2.6))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hl := Fx.halo(Color(1.0, 0.3, 0.06), 1.6, 0.35)
	hl.position = Vector3(0, 0.25, 0)
	body.add_child(hl)
	return {r = 0.6}


static func _spire_kit(i: int) -> Array:
	return _cached("spire%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 6301 + i * 53
		var out := []
		var veins := []
		var n := rng.randi_range(4, 6)
		for s in n:
			var main := s == 0
			var h := rng.randf_range(2.2, 3.2) if main else rng.randf_range(0.9, 2.0)
			var r := rng.randf_range(0.28, 0.36) if main else rng.randf_range(0.14, 0.26)
			var a := TAU * s / n + rng.randf_range(-0.3, 0.3)
			var d := Vector3(cos(a), 0, sin(a))
			var at := Vector3.ZERO if main else d * rng.randf_range(0.25, 0.45)
			var dir := (Vector3.UP + (d * rng.randf_range(0.0, 0.12) if main else d * rng.randf_range(0.15, 0.5))).normalized()
			var sides := rng.randi_range(5, 7)
			var lo := PackedVector3Array()
			var hi := PackedVector3Array()
			var shoulder := rng.randf_range(0.45, 0.7)
			var tip := Vector3(rng.randf_range(-0.3, 0.3) * r, h, rng.randf_range(-0.3, 0.3) * r)
			for k in sides:
				var aa := TAU * k / sides + rng.randf_range(-0.2, 0.2)
				var rr := r * rng.randf_range(0.75, 1.2)
				lo.append(Vector3(cos(aa) * rr, -0.15, sin(aa) * rr))
				hi.append(Vector3(cos(aa) * rr * rng.randf_range(0.35, 0.6), h * shoulder * rng.randf_range(0.8, 1.15), sin(aa) * rr * rng.randf_range(0.35, 0.6)))
			var tris := PackedVector3Array()
			for k in sides:
				var j := (k + 1) % sides
				tris.append_array(PackedVector3Array([lo[k], lo[j], hi[j], lo[k], hi[j], hi[k], hi[k], hi[j], tip]))
			var b := Basis(Quaternion(Vector3.UP, dir)) * Basis(Vector3.UP, rng.randf() * TAU)
			var xf := Transform3D(b, at)
			out.append(Shape.centered(_moved(_faceted(tris, Vector3(0, h * 0.3, 0)), xf)))
			# Cracks: zigzags running up the middle of a few faces.
			for f in (3 if main else 1):
				var k := rng.randi() % sides
				var j := (k + 1) % sides
				var pts := PackedVector3Array()
				var steps := 6
				for q in steps + 1:
					var t := float(q) / steps * rng.randf_range(0.7, 0.95)
					var a0 := lo[k].lerp(hi[k], t)
					var a1 := lo[j].lerp(hi[j], t)
					var w := 0.5 + (0.22 if q % 2 == 0 else -0.22) * (1.0 - t)
					var p := a0.lerp(a1, w)
					var c := Vector3(0, p.y, 0)
					pts.append(p + (p - c).normalized() * 0.004)
				veins.append(_moved(Shape.limb(pts, Shape.taper(0.016 if main else 0.01, 0.004, pts.size()), 3, 1), xf))
		# Glowing seams in the ground at its foot.
		for q in 4:
			var a := rng.randf() * TAU
			var d := Vector3(cos(a), 0, sin(a))
			var side := d.cross(Vector3.UP)
			veins.append(Shape.limb(PackedVector3Array([d * 0.3 + Vector3(0, 0.005, 0), d * 0.55 + side * 0.06, d * 0.8 - side * 0.04 + Vector3(0, 0.005, 0)]), PackedFloat32Array([0.02, 0.015, 0.005]), 3, 1))
		# Splinters of black glass about it.
		var bits := []
		for q in 5:
			var a := rng.randf() * TAU
			var sz := rng.randf_range(0.08, 0.16)
			bits.append(_moved(_prism6(sz * 0.4, sz, rng), Transform3D(Basis(Vector3(cos(a), 0, sin(a)), rng.randf_range(0.8, 1.5)), Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.6, 0.95) + Vector3(0, 0.03, 0))))
		out.append(Shape.centered(Shape.merge(bits)))
		out.append(Shape.centered(Shape.merge(veins)))
		return out)


static func _lava_vent(body: Node3D, rng: RandomNumberGenerator) -> Dictionary:
	var k: Array = _vent_kit(rng.randi() % 3)
	_put(body, k[0], Shape.material(Color(0.12, 0.09, 0.08), Color(0.035, 0.025, 0.025), 3.0, 0.85, 1.2, 0.0, 811))
	var cracks := _put(body, k[1], Fx.glow(Color(1.0, 0.36, 0.08), 2.4))
	cracks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var core := _put(body, k[2], Fx.glow(Color(1.0, 0.55, 0.15), 3.5))
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hl := Fx.halo(Color(1.0, 0.45, 0.12), 1.3, 0.9, 0.3)
	hl.position = Vector3(0, 0.45, 0)
	body.add_child(hl)
	var smoke := CPUParticles3D.new()
	smoke.amount = 14
	smoke.lifetime = 3.5
	smoke.mesh = _smoke_mesh()
	smoke.position = Vector3(0, 0.35, 0)
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.12
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.initial_velocity_min = 0.35
	smoke.initial_velocity_max = 0.7
	smoke.gravity = Vector3(0.12, 0.15, 0.0)
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.0
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.4))
	grow.add_point(Vector2(1, 1.6))
	smoke.scale_amount_curve = grow
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.5, 0.25, 0.15, 0.0))
	ramp.set_color(1, Color(0.12, 0.1, 0.1, 0.0))
	ramp.add_point(0.15, Color(0.35, 0.2, 0.14, 0.5))
	ramp.add_point(0.6, Color(0.16, 0.13, 0.12, 0.3))
	smoke.color_ramp = ramp
	smoke.local_coords = false
	smoke.preprocess = 3.0
	body.add_child(smoke)
	smoke.emitting = true
	var em := Fx.particles(Color(1.0, 0.5, 0.15), 8, 1.2, 0.06)
	em.position = Vector3(0, 0.4, 0)
	em.direction = Vector3.UP
	em.spread = 25.0
	em.initial_velocity_min = 0.8
	em.initial_velocity_max = 1.6
	em.gravity = Vector3.DOWN * 0.6
	body.add_child(em)
	em.emitting = true
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.light_energy = 1.3
	l.omni_range = 4.5
	l.position = Vector3(0, 0.7, 0)
	body.add_child(l)
	return {r = 0.5}


static func _smoke_mesh() -> QuadMesh:
	return _cached("smokeq", func() -> QuadMesh:
		var q := QuadMesh.new()
		q.size = Vector2(0.7, 0.7)
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.4, Color(1, 1, 1, 0.6))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		m.albedo_texture = t
		q.material = m
		return q)


static func _vent_kit(i: int) -> Array:
	return _cached("vent%d" % i, func() -> Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7901 + i * 31
		var prof := PackedVector2Array([Vector2(0.78, -0.05), Vector2(0.62, 0.1), Vector2(0.44, 0.28), Vector2(0.3, 0.4), Vector2(0.24, 0.42), Vector2(0.19, 0.37), Vector2(0.13, 0.28), Vector2(0.0, 0.26)])
		var sd := i * 2.0
		var lump := func(p: Vector3) -> Vector3:
			var a := atan2(p.z, p.x)
			var k := 1.0 + 0.1 * sin(a * 5.0 + sd) + 0.06 * sin(a * 11.0 + sd * 2.0)
			return Vector3(p.x * k, p.y * (1.0 + 0.15 * sin(a * 3.0 + sd)), p.z * k)
		var mound := Shape.warp(Shape.lathe(prof, 22), lump)
		# Radius and height of the slope at distance d from the middle.
		var surf := func(d: float) -> float:
			if d >= 0.78:
				return -0.05
			for q in prof.size() - 1:
				var p0: Vector2 = prof[q]
				var p1: Vector2 = prof[q + 1]
				if d <= p0.x and d >= p1.x:
					return lerpf(p0.y, p1.y, (p0.x - d) / maxf(p0.x - p1.x, 0.0001))
			return 0.26
		var cracks := []
		for c in rng.randi_range(5, 7):
			var a := TAU * c / 6.0 + rng.randf_range(-0.3, 0.3)
			var pts := PackedVector3Array()
			for s in 6:
				var d := lerpf(0.26, 0.72, s / 5.0)
				var aa := a + (0.08 if s % 2 == 0 else -0.08) * (1.0 - s / 6.0)
				var p: Vector3 = lump.call(Vector3(cos(aa) * d, surf.call(d), sin(aa) * d))
				pts.append(p + Vector3(0, 0.012, 0))
			cracks.append(Shape.limb(pts, Shape.taper(0.028, 0.006, 6), 3, 1))
		var core := _at(Shape.blob(Vector3(0.19, 0.04, 0.19), 0.15, sd, 4, 10), Vector3(0, 0.3, 0))
		return [Shape.centered(Shape.ground(mound, 0.4, 0.5)), Shape.centered(Shape.merge(cracks)), Shape.centered(core)])


# --- Shared pieces ---------------------------------------------------------------------


static var _kit := {}


static func _cached(key: String, make: Callable) -> Variant:
	if not _kit.has(key):
		_kit[key] = make.call()
	return _kit[key]


static func _at(mesh: ArrayMesh, off: Vector3) -> ArrayMesh:
	return Shape.warp(mesh, func(p: Vector3) -> Vector3: return p + off)


static func _moved(mesh: ArrayMesh, xf: Transform3D) -> ArrayMesh:
	return Shape.warp(mesh, func(p: Vector3) -> Vector3: return xf * p)


## A place and turn (degrees, as a node's) as a transform.
static func _xf(pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot * PI / 180.0) * Basis.from_scale(scl), pos)


static func _put(parent: Node3D, piece: Array, mat: Material, scl := 1.0) -> MeshInstance3D:
	return Art.part(parent, piece[0], mat, (piece[1] as Vector3) * scl, Vector3.ZERO, Vector3.ONE * scl)


static func _along(pts: PackedVector3Array, t: float) -> Vector3:
	var f := clampf(t, 0.0, 1.0) * (pts.size() - 1)
	var i := mini(int(f), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], f - i)


static func _box(x: float, y: float, z: float) -> BoxMesh:
	return _cached("box%.3f,%.3f,%.3f" % [x, y, z], func() -> BoxMesh: return Art.box(x, y, z))


static func _cyl(top: float, bottom: float, h: float, seg := 10) -> CylinderMesh:
	return _cached("cyl%.3f,%.3f,%.3f,%d" % [top, bottom, h, seg], func() -> CylinderMesh: return Art.cyl(top, bottom, h, seg))


## A box as an ArrayMesh, moved by [param xf], to merge with others.
static func _boxm(size: Vector3, xf := Transform3D.IDENTITY) -> ArrayMesh:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _box(size.x, size.y, size.z).get_mesh_arrays())
	return _moved(am, xf)


## A ring of radius [param r] round the y axis, [param t] thick.
static func _ring(r: float, t: float, n := 10, seg := 4) -> ArrayMesh:
	var pts := PackedVector3Array()
	for k in n + 1:
		var a := TAU * k / n
		pts.append(Vector3(cos(a) * r, 0, sin(a) * r))
	return Shape.limb(pts, Shape.taper(t, t, pts.size()), seg, 1)


## Chain links along [param pts], each [param link] long, every other one
## turned a quarter.
static func _chain(pts: PackedVector3Array, link := 0.1, thick := 0.012) -> ArrayMesh:
	var lens := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		lens.append(lens[i - 1] + pts[i].distance_to(pts[i - 1]))
	var total := lens[lens.size() - 1]
	var n := maxi(1, int(total / (link * 0.74)))
	var parts := []
	for k in n:
		var s := (k + 0.5) * total / n
		var i := 0
		while i < pts.size() - 2 and lens[i + 1] < s:
			i += 1
		var f := (s - lens[i]) / maxf(lens[i + 1] - lens[i], 0.0001)
		var c := pts[i].lerp(pts[i + 1], f)
		var d := (pts[i + 1] - pts[i]).normalized()
		var s1 := d.cross(Vector3.UP)
		if s1.length() < 0.1:
			s1 = d.cross(Vector3.RIGHT)
		s1 = s1.normalized()
		var s2 := d.cross(s1).normalized()
		var side := s1 if k % 2 == 0 else s2
		var loop := PackedVector3Array()
		for q in 6:
			var a := TAU * q / 5.0
			loop.append(c + d * cos(a) * link * 0.5 + side * sin(a) * link * 0.28)
		parts.append(Shape.limb(loop, Shape.taper(thick, thick, 6), 3, 1))
	return Shape.merge(parts)


## One long bone along x, knobbed at both ends (cheaper than the arena's).
static func _bone(l: float, r: float, seed: float) -> ArrayMesh:
	var hl := l * 0.5
	return Shape.merge([
		Shape.limb(PackedVector3Array([Vector3(-hl + r, 0, 0), Vector3(0, 0, 0), Vector3(hl - r, 0, 0)]), PackedFloat32Array([r * 0.95, r * 0.7, r * 0.95]), 4, 1),
		_at(Shape.blob(Vector3(r * 1.3, r * 1.2, r * 1.9), 0.1, seed, 3, 5), Vector3(-hl, 0, 0)),
		_at(Shape.blob(Vector3(r * 1.3, r * 1.2, r * 1.9), 0.1, seed + 1.0, 3, 5), Vector3(hl, 0, 0)),
	])


## A plain skull facing +z, resting on the floor: [bone, sockets].
static func _skull(seed: float) -> Array:
	var bone := Shape.merge([
		_at(Shape.blob(Vector3(0.082, 0.085, 0.105), 0.04, seed, 5, 7), Vector3(0, 0.1, -0.01)),
		_at(Shape.blob(Vector3(0.064, 0.05, 0.05), 0.05, seed + 2.0, 3, 6), Vector3(0, 0.055, 0.068)),
	])
	var holes := Shape.merge([
		_at(Shape.blob(Vector3(0.025, 0.022, 0.016), 0.0, 1.0, 2, 4), Vector3(-0.031, 0.082, 0.102)),
		_at(Shape.blob(Vector3(0.025, 0.022, 0.016), 0.0, 1.0, 2, 4), Vector3(0.031, 0.082, 0.102)),
		_at(Shape.blob(Vector3(0.01, 0.016, 0.01), 0.0, 1.0, 2, 4), Vector3(0, 0.054, 0.116)),
	])
	return [bone, holes]


## A skull as one mesh, its sockets darkened to [param dark].
static func _skull1(seed: float, dark := Color(0.08, 0.065, 0.05)) -> ArrayMesh:
	var sk := _skull(seed)
	return Shape.merge([sk[0], Shape.tint(sk[1], dark)])


## A low heap [param rx] by [param rz], [param h] high, meeting the floor
## smoothly at its edge.
static func _heap(rx: float, rz: float, h: float, seed: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 6
	var seg := 16
	var pt := func(ri: int, si: int) -> Vector3:
		var t := float(ri) / rings
		var a := TAU * si / seg
		var lump := 1.0 + 0.2 * sin(a * 3.0 + seed) * sin(t * 4.0 + seed)
		return Vector3(cos(a) * t * rx, h * pow(maxf(0.0, 1.0 - t * t), 1.2) * lump - 0.01, sin(a) * t * rz)
	for ri in rings:
		for si in seg:
			var a: Vector3 = pt.call(ri, si)
			var b: Vector3 = pt.call(ri + 1, si)
			var c: Vector3 = pt.call(ri + 1, si + 1)
			var d: Vector3 = pt.call(ri, si + 1)
			_tri(st, a, b, c, Vector3.UP)
			if ri > 0:
				_tri(st, a, c, d, Vector3.UP)
	return Shape.merge([st.commit()])


## Flat-shaded triangles of a convex solid round [param mid], turned to face
## outwards: cut stone, crystal.
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


## One triangle facing [param n] (its corners swapped if they wind the
## other way).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (c - a).cross(b - a).dot(n) < 0.0:
		var t := b
		b = c
		c = t
	var fn := (c - a).cross(b - a).normalized()
	for v in [a, b, c]:
		st.set_normal(fn)
		st.add_vertex(v)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	_tri(st, a, b, c, n)
	_tri(st, a, c, d, n)


## A grid of points ([param rows], each a row across) as cloth seen from
## both sides, coloured by [param colors] if given, with [param holes]
## (Vector2i cells) left out.
static func _sheet2(rows: Array, colors: Array = [], holes := {}) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rows.size() - 1:
		var r0: PackedVector3Array = rows[i]
		var r1: PackedVector3Array = rows[i + 1]
		for j in r0.size() - 1:
			if holes.has(Vector2i(j, i)):
				continue
			var idx := [[i, j], [i, j + 1], [i + 1, j + 1], [i + 1, j]]
			var p := [r0[j], r0[j + 1], r1[j + 1], r1[j]]
			for tri: Array in [[0, 1, 2], [0, 2, 3], [0, 2, 1], [0, 3, 2]]:
				for v: int in tri:
					if not colors.is_empty():
						st.set_color((colors[idx[v][0]] as PackedColorArray)[idx[v][1]])
					st.add_vertex(p[v])
	return Shape.merge([st.commit()])


## A grid of 2D cells (in x and y, [param cell] across) where [param solid]
## says so, stood up from [param z0] to [param z1]: masonry with holes and
## broken edges.
static func _extrude(solid: Callable, x0: float, x1: float, y0: float, y1: float, cell: float, z0: float, z1: float) -> ArrayMesh:
	var nx := int(round((x1 - x0) / cell))
	var ny := int(round((y1 - y0) / cell))
	var grid := []
	for j in ny:
		var row := []
		for i in nx:
			row.append(solid.call(x0 + (i + 0.5) * cell, y0 + (j + 0.5) * cell))
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in ny:
		var ya := y0 + j * cell
		var yb := ya + cell
		var i := 0
		while i < nx:
			if not grid[j][i]:
				i += 1
				continue
			var s := i
			while i < nx and grid[j][i]:
				i += 1
			var xa := x0 + s * cell
			var xb := x0 + i * cell
			_quad(st, Vector3(xa, ya, z1), Vector3(xb, ya, z1), Vector3(xb, yb, z1), Vector3(xa, yb, z1), Vector3.BACK)
			_quad(st, Vector3(xa, ya, z0), Vector3(xb, ya, z0), Vector3(xb, yb, z0), Vector3(xa, yb, z0), Vector3.FORWARD)
			_quad(st, Vector3(xa, ya, z0), Vector3(xa, ya, z1), Vector3(xa, yb, z1), Vector3(xa, yb, z0), Vector3.LEFT)
			_quad(st, Vector3(xb, ya, z0), Vector3(xb, ya, z1), Vector3(xb, yb, z1), Vector3(xb, yb, z0), Vector3.RIGHT)
		# Tops and bottoms where the row above or below is open.
		for up: int in [1, -1]:
			var y := yb if up == 1 else ya
			var i2 := 0
			while i2 < nx:
				var open := func(k: int) -> bool:
					var jj := j + up
					return grid[j][k] and (jj < 0 or jj >= ny or not grid[jj][k])
				if not open.call(i2):
					i2 += 1
					continue
				var s2 := i2
				while i2 < nx and open.call(i2):
					i2 += 1
				var xa2 := x0 + s2 * cell
				var xb2 := x0 + i2 * cell
				_quad(st, Vector3(xa2, y, z0), Vector3(xb2, y, z0), Vector3(xb2, y, z1), Vector3(xa2, y, z1), Vector3.UP * up)
	return st.commit()


# --- Materials -------------------------------------------------------------------------


static func _grain(key: String, base: Color, dark: Color, axis: Vector3, rough := 0.85, bump := 0.9, seed := 1) -> StandardMaterial3D:
	return _cached("m" + key, func() -> StandardMaterial3D:
		var m: StandardMaterial3D = Shape.material(base, dark, 1.0, rough, bump, 0.0, seed).duplicate()
		m.uv1_scale = axis
		return m)


static func _iron() -> StandardMaterial3D:
	return Shape.material(Color(0.15, 0.14, 0.13), Color(0.05, 0.045, 0.04), 5.0, 0.55, 0.8, 0.55, 31)


static func _rust() -> StandardMaterial3D:
	return Shape.material(Color(0.25, 0.14, 0.08), Color(0.07, 0.045, 0.03), 5.0, 0.85, 1.0, 0.3, 203)


static func _bone_m() -> StandardMaterial3D:
	return Shape.material(Color(0.46, 0.42, 0.34), Color(0.25, 0.21, 0.15), 5.0, 0.75, 0.6, 0.0, 41)


static func _char_m() -> StandardMaterial3D:
	return Shape.material(Color(0.24, 0.2, 0.16), Color(0.05, 0.04, 0.035), 5.0, 0.9, 0.7, 0.0, 503)


static func _ash_m() -> StandardMaterial3D:
	return Shape.material(Color(0.13, 0.11, 0.1), Color(0.04, 0.03, 0.03), 3.0, 0.95, 0.9, 0.0, 504)


static func _snow_m() -> StandardMaterial3D:
	return Shape.material(Color(0.7, 0.74, 0.8), Color(0.6, 0.64, 0.72), 1.5, 0.7, 0.3, 0.0, 311)


## Snow lying on the floor: [method _snow_m] fading out where the points say.
static func _drift_m() -> StandardMaterial3D:
	return _cached("mdrift", func() -> StandardMaterial3D:
		var m: StandardMaterial3D = Shape.material(Color(0.62, 0.66, 0.73), Color(0.54, 0.58, 0.66), 1.5, 0.7, 0.3, 0.0, 312).duplicate()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		return m)


## Light, frosty stuff whose own colour comes from the points: see [method _frost].
static func _frost_m() -> StandardMaterial3D:
	return Shape.material(Color(0.8, 0.82, 0.86), Color(0.62, 0.65, 0.7), 4.0, 0.6, 0.5, 0.0, 301)


static func _dark() -> StandardMaterial3D:
	return Fx.solid(Color(0.025, 0.02, 0.018))


static func _ice_m() -> StandardMaterial3D:
	return _cached("mice", func() -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.45, 0.56, 0.66, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.1
		m.metallic = 0.15
		m.metallic_specular = 0.8
		m.emission_enabled = true
		m.emission = Color(0.07, 0.13, 0.19)
		m.rim_enabled = true
		m.rim = 0.5
		m.rim_tint = 0.4
		return m)


## [param mesh] coloured [param base] (for [method _frost_m]), frost white
## on what faces up and in patches, [param amount] of it, darker towards
## the floor below [param top] metres.
static func _frost(mesh: ArrayMesh, base: Color, amount := 1.0, top := 2.0) -> ArrayMesh:
	var fc := Color(1.0, 1.0, 1.0)
	return Shape.shade(mesh, func(p: Vector3, nrm: Vector3) -> Color:
		var k := lerpf(0.55, 1.0, clampf(p.y / top, 0.0, 1.0))
		var f := smoothstep(0.55, 0.95, nrm.y)
		f += 0.25 * smoothstep(0.55, 0.95, sin(p.x * 13.0 + p.z * 7.0) * sin(p.y * 11.0 + p.z * 5.0))
		f = clampf(f * amount, 0.0, 0.9)
		var c := (base / 0.8).lerp(fc, f)
		return c * lerpf(k, 1.0, f))

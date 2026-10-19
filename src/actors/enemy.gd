class_name Enemy
extends Actor
## A monster. Every kind is a row in KINDS; bosses are kinds with a "boss" key.
## Ranged monsters fire bullet patterns ("shots", taken in turn), slams throw a
## ring of bullets, and bosses cycle through BOSS_PATTERNS. Bullets are slow
## and bright: the game is to walk, roll and swing through them.

const KINDS := {
	ghoul = {name = "Ghoul", hp = 40.0, speed = 4.3, dmg = 9.0, reach = 1.3, el = El.EARTH, size = 0.9, attack = "melee"},
	skeleton = {name = "Skeleton", hp = 50.0, speed = 3.3, dmg = 10.0, reach = 1.4, el = El.EARTH, size = 1.0, attack = "melee", undead = true, resist = {El.FROST: 0.3, El.EARTH: -0.3, El.VOID: 0.5}},
	# A floating eye that keeps its distance and stares out fans of void.
	watcher = {name = "Watcher", hp = 34.0, speed = 3.0, dmg = 9.0, reach = 10.0, keep = 8.0, el = El.VOID, size = 1.0, attack = "ranged", shots = ["fan3"], resist = {El.VOID: 0.6, El.LIGHTNING: -0.4}},
	cultist = {name = "Cultist", hp = 42.0, speed = 3.0, dmg = 11.0, reach = 9.0, keep = 7.0, el = El.FIRE, size = 1.0, attack = "ranged", shots = ["fan5", "ring10"], resist = {El.FIRE: 0.6}},
	bile = {name = "Bile Horror", hp = 95.0, speed = 2.1, dmg = 12.0, reach = 1.5, el = El.WATER, size = 1.25, attack = "melee", mass = 2.0, resist = {El.WATER: 1.0, El.EARTH: 0.2}, burst = true},
	imp = {name = "Imp", hp = 30.0, speed = 5.2, dmg = 8.0, reach = 7.0, keep = 5.0, el = El.FIRE, size = 0.7, attack = "ranged", shots = ["burst3"], heals_from = El.FIRE, resist = {El.FROST: -0.5, El.WATER: -0.5}},
	brute = {name = "Brute", hp = 240.0, speed = 2.7, dmg = 24.0, reach = 2.2, el = El.EARTH, size = 1.7, attack = "slam", ring = 10, mass = 3.5, resist = {El.EARTH: 0.3}},
	frost_brute = {name = "Frost Brute", hp = 260.0, speed = 2.5, dmg = 22.0, reach = 2.2, el = El.FROST, size = 1.7, attack = "slam", ring = 10, mass = 3.5, resist = {El.FROST: 0.9, El.FIRE: -0.4}},
	wraith = {name = "Wraith", hp = 45.0, speed = 3.8, dmg = 10.0, reach = 8.0, keep = 6.0, el = El.FROST, size = 1.0, attack = "ranged", shots = ["wave7"], undead = true, resist = {El.FROST: 1.0, El.EARTH: 0.5}},
	drowned = {name = "Drowned", hp = 55.0, speed = 3.1, dmg = 11.0, reach = 1.4, el = El.WATER, size = 1.0, attack = "melee", resist = {El.WATER: 1.0, El.FIRE: 0.4}, always_wet = true},
	demon = {name = "Demon", hp = 130.0, speed = 3.5, dmg = 16.0, reach = 1.7, el = El.FIRE, size = 1.35, attack = "melee", mass = 2.0, resist = {El.FIRE: 1.0, El.FROST: -0.3}},
	# Hangs back among the graves and looses one fast arrow along a line it
	# shows you first; the aim locks just before it shoots, so step aside.
	# Brittle bones: earth and life break it.
	bone_archer = {name = "Bone Archer", model = "skeleton", hp = 32.0, speed = 3.2, dmg = 14.0, reach = 16.0, keep = 11.0, el = El.EARTH, size = 1.0, attack = "ranged", shots = ["snipe"], wind = 1.1, undead = true, resist = {El.FROST: 0.3, El.EARTH: -0.3, El.VOID: 0.5}, spawn = "far"},
	# Keeps far back and raises skeletons out of the ground around it; when
	# it dies, everything it raised falls apart. Kill it first. Its robes burn.
	necromancer = {name = "Necromancer", hp = 60.0, speed = 2.7, dmg = 9.0, reach = 12.0, keep = 10.0, el = El.VOID, size = 1.0, attack = "ranged", shots = ["fan3"], raise = "skeleton", solo = true, resist = {El.VOID: 0.8, El.FIRE: -0.3}, spawn = "far"},
	# Tunnels under the floor where nothing hits it, a mound of earth closing
	# in, and bursts up under you. Up, it fights for a few seconds and digs
	# back down, unless it is chilled, frozen or bogged in mud: then it is
	# stuck up top (and frozen earth shatters).
	lurker = {name = "Lurker", hp = 70.0, speed = 3.4, dmg = 12.0, reach = 1.5, el = El.EARTH, size = 1.1, attack = "burrow", mass = 1.6, resist = {El.EARTH: 0.4, El.FROST: -0.3}, spawn = "under"},
	# A spark that darts about and dashes straight through you; double damage
	# if you are wet, so it is worst out on the water. Lightning feeds it,
	# earth grounds it.
	sprite = {name = "Storm Sprite", hp = 26.0, speed = 5.5, dmg = 7.0, reach = 6.5, keep = 4.5, el = El.LIGHTNING, size = 0.7, attack = "dash", dash = [15.0, 0.32], wind = 0.5, heals_from = El.LIGHTNING, resist = {El.EARTH: -0.6}},
	# Squats in the water and lobs globs of bog that land where it saw you a
	# moment ago (the ring shows where), slowing you and leaving you soaked:
	# a sprite's favourite prey. Always wet itself, so lightning and frost
	# are deadly to it; fire dries it out.
	toad = {name = "Bog Toad", hp = 55.0, speed = 2.4, dmg = 7.0, reach = 12.0, keep = 8.0, el = El.MUD, size = 1.0, attack = "lob", wind = 0.7, resist = {El.WATER: 1.0, El.EARTH: 0.3, El.FIRE: -0.4}, always_wet = true, spawn = "water"},
	# A tower shield in front turns aside almost everything that hits it
	# there. Get round it, arc lightning through the metal, or knock it aside
	# with earth or a gust: then it is open for a moment.
	shieldbearer = {name = "Shieldbearer", hp = 120.0, speed = 2.4, dmg = 14.0, reach = 1.6, el = El.EARTH, size = 1.15, attack = "melee", mass = 2.5, shield = true, resist = {El.LIGHTNING: -0.3}},
	# Hunts in packs and comes from behind or the side, leaping at you from
	# a few metres and leaving fire where it pushed off. Water and frost
	# put it out.
	hellhound = {name = "Hellhound", hp = 38.0, speed = 5.6, dmg = 10.0, reach = 5.5, el = El.FIRE, size = 0.85, attack = "dash", dash = [13.0, 0.3], wind = 0.55, trail = El.FIRE, resist = {El.FIRE: 1.0, El.WATER: -0.5, El.FROST: -0.3}, pack = 3, spawn = "flank"},
	# Bosses: one per biome, in the arena at the end of its level.
	gravekeeper = {name = "The Gravekeeper", model = "skeleton", hp = 1100.0, speed = 2.6, dmg = 26.0, reach = 2.6, el = El.EARTH, size = 2.3, attack = "slam", mass = 8.0, undead = true, resist = {El.VOID: 0.8, El.FROST: 0.3}, boss = true, ring = 16, summon = ["skeleton", "skeleton", "watcher"], nova = El.VOID},
	abbot = {name = "The Bloated Abbot", model = "bile", hp = 1300.0, speed = 2.0, dmg = 26.0, reach = 2.6, el = El.WATER, size = 2.4, attack = "slam", mass = 8.0, resist = {El.WATER: 1.0}, boss = true, ring = 16, summon = ["cultist", "ghoul", "ghoul"], nova = El.MUD},
	drowned_king = {name = "The Drowned King", model = "drowned", hp = 1400.0, speed = 2.6, dmg = 26.0, reach = 2.6, el = El.WATER, size = 2.3, attack = "slam", mass = 8.0, resist = {El.WATER: 1.0, El.FIRE: 0.5}, boss = true, ring = 16, summon = ["drowned", "drowned", "bile"], nova = El.WATER, always_wet = true},
	warden = {name = "The Frost Warden", model = "frost_brute", hp = 1600.0, speed = 2.4, dmg = 30.0, reach = 2.8, el = El.FROST, size = 2.4, attack = "slam", mass = 9.0, resist = {El.FROST: 1.0, El.FIRE: -0.3}, boss = true, ring = 16, summon = ["wraith", "wraith", "skeleton"], nova = El.ICE},
	pit_lord = {name = "The Pit Lord", model = "demon", hp = 2200.0, speed = 2.8, dmg = 34.0, reach = 3.0, el = El.FIRE, size = 2.6, attack = "slam", mass = 10.0, resist = {El.FIRE: 1.0, El.FROST: -0.3}, boss = true, ring = 16, summon = ["imp", "imp", "demon"], nova = El.MAGMA},
}

const HP_SHADER := preload("res://src/fx/hp_bar.gdshader")
const BOSS_PATTERNS := ["spiral", "rings", "nova", "fan9"]

const AFFIXES := [
	{name = "Fire Enchanted", el = El.FIRE, resist = El.FIRE},
	{name = "Cold Enchanted", el = El.FROST, resist = El.FROST},
	{name = "Lightning Enchanted", el = El.LIGHTNING, resist = El.LIGHTNING},
	{name = "Stone Skin", armor = 0.6},
	{name = "Extra Fast", speed = 1.45},
	{name = "Vampiric", leech = 0.5},
]
const PREFIX := ["Bone", "Gore", "Rot", "Ash", "Grim", "Blood", "Murk", "Hollow", "Vile", "Grave"]
const SUFFIX := ["maw", "rend", "gut", "skull", "howl", "fang", "shade", "bane", "claw", "spite"]

var kind := "ghoul"
var cfg: Dictionary
var target: Actor
var elite := {}
var elite_name := ""
var _wind := 0.0
var _cool := 0.0
var _think := 0.0
var _special := 4.0
var _summon_t := 8.0
var _strafe := 1.0
var _model: Node3D
var _hurt_t := 0.0
var _walk := 0.0
var _eyes: Array = []
var _hp_bar: MeshInstance3D
var _hp_mat: ShaderMaterial
var _shot_i := 0
var _pattern_i := 0
## Bullets fired later: [seconds left, Callable].
var _pending: Array = []
var _spiral_t := 0.0
var _spiral_ang := 0.0
var _spiral_step := 0.0
## Raised by a necromancer, and falls apart with it.
var master: Enemy
var _raise_t := 5.0
## Dashing (sprites, hounds): time left, which way, who it already hit.
var _dash_t := 0.0
var _dash_dir := Vector3.ZERO
var _dash_hit: Array = []
## A lurker under the floor, and how long it stays up once it surfaced.
var _under := false
var _surface_t := 0.0
var _mound: Node3D
var _layer := 0
## A shieldbearer's shield is knocked aside this long.
var _open_t := 0.0
var _shield: Node3D
var _aim_bar: MeshInstance3D
var _aim_lock := Vector3.ZERO
## While a pose tween (rising from the ground) runs, the walk bob keeps off.
var _pose_t := 0.0
## Every attack shows itself in the body while the monster winds up
## (_windup_pose): it rears back for a blow, rises for a slam, crouches for
## a dash, and a ball of its element swells in front of it for a shot. The
## way it will go is followed until three quarters in, then held, so a step
## or a roll at the last moment gets you out. Nothing is drawn on the floor.
var _orb: MeshInstance3D
var _base_scale := Vector3.ONE
var _lock := Vector3.ZERO
## How far to each side of where it faces a melee blow reaches.
const MELEE_ARC := 1.1


func setup(k: String, hp_scale: float, champion: bool) -> Enemy:
	kind = k
	cfg = KINDS[k]
	team = 1
	max_hp = cfg.hp * hp_scale
	speed = cfg.speed * randf_range(0.92, 1.08)
	radius = 0.42 * cfg.size
	mass = cfg.get("mass", 1.0)
	undead = cfg.get("undead", false)
	resist = cfg.get("resist", {}).duplicate()
	heals_from = cfg.get("heals_from", -1)
	if champion and not cfg.get("boss", false):
		elite = AFFIXES.pick_random()
		max_hp *= 2.2
		elite_name = PREFIX.pick_random() + SUFFIX.pick_random()
		elite_name = elite_name.capitalize() + " the " + elite.name
		if elite.has("resist"):
			resist[elite.resist] = 1.0
		if elite.has("armor"):
			armor = elite.armor
		if elite.has("speed"):
			speed *= elite.speed
	hp = max_hp
	_strafe = 1.0 if randf() < 0.5 else -1.0
	return self


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = maxf(1.6 * cfg.size, radius * 2.0 + 0.1)
	shape.shape = cap
	shape.position = Vector3.UP * cap.height * 0.5
	add_child(shape)
	_model = Node3D.new()
	add_child(_model)
	_build(cfg.get("model", kind))
	_model.scale = Vector3.ONE * (cfg.size if cfg.has("model") else 1.0)
	_base_scale = _model.scale
	setup_status_fx()
	if elite or cfg.get("boss", false):
		# No name over its head (no text over characters): the aura and its
		# size tell you it is special.
		if elite.has("el"):
			var aura := Fx.particles(El.COLOR[elite.el], 20, 0.8, 0.3)
			aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			aura.emission_sphere_radius = radius * 1.2
			aura.position.y = 0.9
			aura.direction = Vector3.UP
			aura.initial_velocity_max = 1.0
			add_child(aura)
			aura.emitting = true
	_hp_bar = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.55 + cfg.size * 0.2, 0.05)
	_hp_bar.mesh = q
	_hp_mat = ShaderMaterial.new()
	_hp_mat.shader = HP_SHADER
	_hp_mat.render_priority = 2
	_hp_bar.material_override = _hp_mat
	_hp_bar.position = Vector3(0, 1.95 * cfg.size + 0.15, 0)
	_hp_bar.visible = false
	_hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_bar)
	if cfg.get("always_wet", false):
		wet = 999.0
	if cfg.get("aim_line", false):
		# The line its shot will take, drawn while it draws the bow.
		_aim_bar = MeshInstance3D.new()
		_aim_bar.mesh = Art.box(0.05, 0.02, 1.0)
		_aim_bar.material_override = Fx.additive(Color(1.0, 0.25, 0.15, 0.6), 1.4).duplicate()
		_aim_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_aim_bar.visible = false
		_aim_bar.top_level = true
		add_child(_aim_bar)
	if cfg.attack == "burrow":
		_mound = Node3D.new()
		add_child(_mound)
		var dirt := Fx.solid(Color(0.24, 0.18, 0.12), 1.0)
		for i in 5:
			var a := i * TAU / 5.0
			Art.part(_mound, Art.sphere(0.3, 6), dirt, Vector3(cos(a) * 0.3, 0.02, sin(a) * 0.3), Vector3.ZERO, Vector3(1, 0.4, 1))
		var dust := Fx.particles(Color(0.35, 0.27, 0.18, 0.6), 14, 0.6, 0.18)
		dust.direction = Vector3.UP
		dust.initial_velocity_max = 1.2
		dust.position.y = 0.1
		_mound.add_child(dust)
		dust.emitting = true
		_layer = collision_layer
		_go_under(true)
	if cfg.get("boss", false):
		var l := OmniLight3D.new()
		l.light_color = El.COLOR[cfg.el]
		l.light_energy = 1.2
		l.omni_range = 6.0
		l.position.y = 2.5
		add_child(l)


func _mat(c: Color) -> StandardMaterial3D:
	return Fx.solid(c, 0.9)


func _add(mesh: Mesh, c: Color, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var m := Art.part(_model, mesh, _mat(c), pos, rot, scl)
	meshes.append(m)
	return m


func _eye_pair(y: float, z: float, sep: float, c := Color(1.0, 0.1, 0.05), r := 0.035) -> void:
	for s in [-1, 1]:
		var e := Art.part(_model, Art.sphere(r, 6), Fx.glow(c, 5.0), Vector3(sep * s, y, z))
		_eyes.append(e)


## Monster models are built in code from smooth shapes (Shape): limbs that
## bend through joints, lumpy bodies, robes turned on a lathe, all in mottled,
## bumpy materials shaded darker towards the floor. Each part is its own
## mesh (the hit flash, the status tint and the death scatter work part by
## part), made once per kind and shared by every monster of it.
func _build(m: String) -> void:
	match m:
		"ghoul":
			_ghoul()
		"skeleton":
			_skeleton()
		"cultist":
			_cultist()
		"imp":
			_imp()
		"brute", "frost_brute":
			_brute(m == "frost_brute")
		"wraith":
			_wraith()
		"drowned":
			_drowned()
		"demon":
			_demon()
		"watcher":
			_watcher()
		"bile":
			_bile()
		"necromancer":
			_necromancer()
		"toad":
			_toad()
		"shieldbearer":
			_shieldbearer()
		"hellhound":
			_hellhound()
		"lurker":
			_lurker()
		"sprite":
			_sprite()
		_:
			_add(Art.sphere(0.4), Color.MAGENTA, Vector3(0, 0.8, 0))


## Meshes of monster parts, made once and shared: key -> [mesh, centre].
static var _parts := {}


## A part [param make] builds (in model space, feet at the origin), shaded
## darker towards the floor up to [param top] metres. It is made once per
## [param key]; the instance sits at the part's middle, so as debris it
## tumbles round itself and comes to rest on the floor.
func _part(key: String, mat: Material, make: Callable, top := 1.6, under := Color.WHITE) -> MeshInstance3D:
	var e := _shared(key, make, top, under)
	var mi := Art.part(_model, e[0], mat, e[1])
	meshes.append(mi)
	return mi


## The made-once mesh of a part and where its middle goes: [mesh, centre].
static func _shared(key: String, make: Callable, top := 1.6, under := Color.WHITE) -> Array:
	if not _parts.has(key):
		_parts[key] = Shape.centered(Shape.ground(make.call(), top, 0.45, under))
	return _parts[key]


## The same part on both sides: [param make] takes the side (1 for +x,
## -1 for -x) so a pose can differ left and right.
func _sides(key: String, mat: Material, make: Callable, top := 1.6, under := Color.WHITE) -> void:
	for s: float in [1.0, -1.0]:
		_part("%s%d" % [key, int(s)], mat, make.bind(s), top, under)


## A tube through [param pts] with radii [param r] (plain arrays).
static func _tube(pts: Array, r: Array, seg := 8) -> ArrayMesh:
	# Closed loops (belts, rings) are round already: no smoothing.
	var sub := 1 if pts.size() > 8 and (pts[0] as Vector3).is_equal_approx(pts[-1]) else (3 if seg >= 8 else 2)
	return Shape.limb(PackedVector3Array(pts), PackedFloat32Array(r), seg, sub)


## A bone from [param a] to [param b]: a thin shaft with knobbed ends.
static func _bone(a: Vector3, b: Vector3, r: float, seg := 6) -> ArrayMesh:
	return _tube([a, a.lerp(b, 0.1), a.lerp(b, 0.5), a.lerp(b, 0.9), b], [r * 1.5, r * 1.05, r * 0.85, r * 1.05, r * 1.4], seg)


## A claw or talon: a curved tapering spike.
static func _claw(a: Vector3, bend: Vector3, b: Vector3, r: float) -> ArrayMesh:
	return Shape.limb(Shape.curve(a, bend, b, 4), PackedFloat32Array([r, r * 0.75, r * 0.45, r * 0.12]), 4, 1)


## A small straight spike, cheap: teeth, thorns, barbs.
static func _spike(a: Vector3, b: Vector3, r: float) -> ArrayMesh:
	return Shape.limb(PackedVector3Array([a, b]), PackedFloat32Array([r, 0.0]), 3, 1)


## The dark hollow an eye sits in: a pit pressed into the face, the glow
## set inside it.
func _sockets(key: String, y: float, z: float, sep: float, r: float, c: Color, er := 0.022) -> void:
	_part(key + "_pits", _hollow(), func() -> ArrayMesh:
		return Shape.merge([
			Shape.warp(Shape.blob(Vector3(r * 1.1, r * 0.8, r * 0.6), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + Vector3(sep, y, z)),
			Shape.warp(Shape.blob(Vector3(r * 1.1, r * 0.8, r * 0.6), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + Vector3(-sep, y, z)),
		]))
	_eye_pair(y, z + r * 0.25, sep, c, er)


## Claws and nails: the skin darkened this much (Shape.tint).
const NAIL := Color(0.4, 0.34, 0.3)


## Near black, for eye pits and open mouths.
static func _hollow() -> Material:
	return Shape.flat(Color(0.025, 0.018, 0.015), 1.0)


## Ghoul: a starved, hunched corpse-eater. Knobbed spine and ribs showing
## through grey, bruised skin, long arms hanging to the floor with hooked
## claws, a long bald skull thrust forward on a thin neck, its jaw hanging
## open on a row of teeth. Crouched on bent legs, ready to spring.
func _ghoul() -> void:
	var skin := Shape.material(Color(0.46, 0.46, 0.4), Color(0.31, 0.27, 0.27), 4.0, 0.6, 0.6, 0.0, 3)
	var rag := Shape.material(Color(0.24, 0.2, 0.16), Color(0.09, 0.07, 0.06), 3.0, 0.95, 0.6, 0.0, 5)
	var teeth := Shape.flat(Color(0.62, 0.56, 0.42), 0.5)
	var top := 1.3
	var head := Vector3(0, 1.21, 0.43)
	_part("gh_body", skin, func() -> ArrayMesh:
		var t := _tube([Vector3(0, 0.72, -0.15), Vector3(0, 0.88, -0.1), Vector3(0, 1.04, 0.0), Vector3(0, 1.14, 0.12), Vector3(0, 1.15, 0.2)], [0.12, 0.13, 0.17, 0.17, 0.12], 12)
		t = Shape.warp(t, func(p: Vector3) -> Vector3:
			# Broad across the shoulders, flat front to back, ribs ridged
			# along the flanks and a sunken belly.
			var chest := smoothstep(0.85, 1.05, p.y)
			p.x *= lerpf(1.0, 1.35, chest)
			var flank := absf(p.x) / 0.2
			p.x += signf(p.x) * 0.012 * sin(p.y * 95.0) * chest * flank
			if p.z > -0.05 and p.y < 0.98:
				p.z -= 0.03 * smoothstep(0.75, 0.9, p.y)
			return p)
		# Knuckled vertebrae standing up along the hunched back.
		var pts := Shape.curve(Vector3(0, 0.84, -0.22), Vector3(0, 1.16, -0.1), Vector3(0, 1.26, 0.16), 11)
		var r := []
		for i in pts.size():
			r.append(0.03 if i % 2 == 0 else 0.018)
		var neck := _tube([Vector3(0, 1.17, 0.16), Vector3(0, 1.2, 0.28), head + Vector3(0, -0.02, -0.04)], [0.065, 0.045, 0.045], 8)
		return Shape.merge([t, _tube(Array(pts), r, 6), neck]), top)
	_part("gh_head", skin, func() -> ArrayMesh:
		var h := Shape.warp(Shape.blob(Vector3(0.085, 0.085, 0.13), 0.04, 2.0, 10, 16), func(p: Vector3) -> Vector3:
			# A long skull: the cranium swept up and back, a heavy brow, the
			# face narrowing to a muzzle with hollow cheeks.
			if p.z < 0.0:
				p.y += -p.z * 0.35
				p.x *= 1.0 + -p.z * 0.8
			if p.z > 0.03:
				p.x *= 1.0 - (p.z - 0.03) * 2.5
			if p.y > 0.03 and p.z > 0.04 and p.z < 0.09:
				p.y += 0.012
			return p + head)
		var parts := [h]
		for s: float in [1.0, -1.0]:
			# Torn, pointed ears laid back.
			var a := head + Vector3(s * 0.07, 0.02, -0.02)
			parts.append(_tube([a, a + Vector3(s * 0.04, 0.02, -0.04), a + Vector3(s * 0.06, 0.03, -0.09)], [0.018, 0.012, 0.003], 5))
		return Shape.merge(parts), top)
	_part("gh_jaw", skin, func() -> ArrayMesh:
		var j := Shape.blob(Vector3(0.055, 0.025, 0.085), 0.03, 4.0, 6, 10)
		return Shape.warp(j, func(p: Vector3) -> Vector3:
			# Hanging open from hinges under the ears.
			p.x *= 1.0 - maxf(0.0, p.z) * 3.0
			return Basis(Vector3.RIGHT, 0.45) * p + head + Vector3(0, -0.085, 0.035)), top)
	_part("gh_mouth", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.045, 0.04, 0.06), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.055, 0.06)), top)
	_part("gh_teeth", teeth, func() -> ArrayMesh:
		var parts := []
		for jaw: float in [1.0, -1.0]:
			for i in 7:
				var u := (i - 3.0) / 3.0
				var at := head + Vector3(u * 0.04, -0.035 if jaw > 0.0 else -0.1 + absf(u) * 0.01, 0.11 - u * u * 0.04 - (0.0 if jaw > 0.0 else 0.025))
				parts.append(_spike(at, at + Vector3(0, -0.024 * jaw, 0.003), 0.007))
		return Shape.merge(parts), top)
	_sockets("gh", head.y + 0.025, head.z + 0.075, 0.035, 0.022, Color(0.85, 0.9, 0.35), 0.016)
	_sides("gh_uarm", skin, func(s: float) -> ArrayMesh:
		return _tube([Vector3(s * 0.21, 1.12, 0.12), Vector3(s * 0.29, 0.97, 0.15), Vector3(s * 0.34, 0.8, 0.2)], [0.065, 0.05, 0.045], 8), top)
	_sides("gh_farm", skin, func(s: float) -> ArrayMesh:
		return _tube([Vector3(s * 0.34, 0.8, 0.2), Vector3(s * 0.33, 0.6, 0.3), Vector3(s * 0.3, 0.4, 0.38)], [0.045, 0.04, 0.034], 8), top)
	_sides("gh_hand", skin, func(s: float) -> ArrayMesh:
		var parts := [_tube([Vector3(s * 0.3, 0.4, 0.38), Vector3(s * 0.3, 0.34, 0.41)], [0.04, 0.045], 8)]
		for f in 4:
			var o := (f - 1.5) * 0.024
			var a := Vector3(s * (0.3 + o), 0.33, 0.42)
			parts.append(_tube(Array(Shape.curve(a, a + Vector3(s * o * 0.6, -0.06, 0.05), a + Vector3(s * o, -0.13, 0.04), 4)), [0.014, 0.012, 0.01, 0.008], 4))
			# Long, dirty, hooked nails.
			var c := Vector3(s * (0.3 + o * 2.0), 0.2, 0.46)
			parts.append(Shape.tint(_claw(c, c + Vector3(0, -0.04, 0.03), c + Vector3(0, -0.06, -0.02), 0.009), NAIL))
		return Shape.merge(parts), top)
	_sides("gh_thigh", skin, func(s: float) -> ArrayMesh:
		return _tube([Vector3(s * 0.12, 0.74, -0.14), Vector3(s * 0.17, 0.6, 0.0), Vector3(s * 0.2, 0.44, 0.12)], [0.075, 0.06, 0.05], 8), top)
	_sides("gh_shin", skin, func(s: float) -> ArrayMesh:
		var parts := [_tube([Vector3(s * 0.2, 0.44, 0.12), Vector3(s * 0.18, 0.26, 0.0), Vector3(s * 0.16, 0.09, -0.1)], [0.05, 0.04, 0.035], 8)]
		parts.append(_tube([Vector3(s * 0.16, 0.09, -0.12), Vector3(s * 0.165, 0.04, -0.02), Vector3(s * 0.17, 0.025, 0.1)], [0.04, 0.035, 0.03], 8))
		for f in 3:
			var o := (f - 1.0) * 0.025
			var a := Vector3(s * 0.17 + o, 0.025, 0.11)
			parts.append(Shape.tint(_claw(a, a + Vector3(o * 0.5, 0.0, 0.04), a + Vector3(o, -0.02, 0.06), 0.01), NAIL))
		return Shape.merge(parts), top)
	_part("gh_rag", rag, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.19, 0.5), Vector2(0.17, 0.62), Vector2(0.145, 0.76), Vector2(0.13, 0.8)]), 14, 5, 0.2)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			# A torn hem: ragged at the bottom, longer front and back.
			var a := atan2(p.z, p.x)
			if p.y < 0.6:
				p.y += 0.06 * absf(sin(a * 3.0 + 1.0)) - 0.05 * absf(sin(a))
			return Vector3(p.x * 1.05, p.y, p.z * 0.85 - 0.14)), top)


## Skeleton: a dead soldier still at its post. Yellowed bones with knobbed
## joints, a ribcage you can see through, a skull with dark sockets and
## embers in them; a rusted pauldron, a rag at the hips and a notched,
## rusted sword (a bow and quiver for the archer, a grave spade and an
## iron crown for the Gravekeeper). Leaning in, knees bent.
func _skeleton() -> void:
	var bone := Shape.material(Color(0.72, 0.67, 0.56), Color(0.47, 0.41, 0.31), 4.0, 0.6, 0.6, 0.0, 11)
	var rust := Shape.material(Color(0.36, 0.34, 0.33), Color(0.33, 0.17, 0.08), 4.0, 0.45, 0.8, 0.6, 13)
	var rag := Shape.material(Color(0.2, 0.17, 0.14), Color(0.08, 0.06, 0.05), 3.0, 0.95, 0.6, 0.0, 17)
	var wood := Shape.material(Color(0.3, 0.22, 0.14), Color(0.13, 0.09, 0.06), 5.0, 0.8, 0.5, 0.0, 19)
	var top := 1.75
	var archer := kind == "bone_archer"
	var head := Vector3(0, 1.6, 0.08)
	_part("sk_skull", bone, func() -> ArrayMesh:
		var h := Shape.blob(Vector3(0.07, 0.08, 0.09), 0.02, 3.0, 12, 16)
		return Shape.warp(h, func(p: Vector3) -> Vector3:
			# A round cranium swelling at the back, the face below it
			# narrowing to the cheekbones and the upper teeth, a ridge over
			# the eyes; bowed a little, looking down at you.
			if p.y < 0.0:
				p.x *= 1.0 + p.y * 3.2
				p.z += -p.y * 0.4
			if p.z < -0.02:
				p.y += 0.012
			if p.z > 0.05 and p.y > -0.015 and p.y < 0.025:
				p.z += 0.007
			return Basis(Vector3.RIGHT, 0.15) * p + head), top)
	_part("sk_jaw", bone, func() -> ArrayMesh:
		var j := Shape.blob(Vector3(0.048, 0.02, 0.045), 0.0, 1.0, 6, 10)
		return Shape.warp(j, func(p: Vector3) -> Vector3:
			# The chin out front, the hinges up at the back.
			p.y += maxf(0.0, -p.z) * 0.6
			p.x *= 1.0 + maxf(0.0, -p.z) * 6.0
			return p + head + Vector3(0, -0.085, 0.045)), top)
	_part("sk_nose", _hollow(), func() -> ArrayMesh:
		return Shape.sheet(PackedVector3Array([head + Vector3(0, -0.008, 0.094), head + Vector3(-0.01, -0.038, 0.09), head + Vector3(0.01, -0.038, 0.09)])), top)
	_sockets("sk", head.y + 0.008, head.z + 0.062, 0.029, 0.024, Color(1.0, 0.35, 0.12), 0.017)
	_part("sk_spine", bone, func() -> ArrayMesh:
		var pts := Shape.curve(Vector3(0, 0.95, -0.03), Vector3(0, 1.22, -0.1), Vector3(0, 1.5, 0.03), 13)
		var r := []
		for i in pts.size():
			r.append(0.028 if i % 2 == 0 else 0.018)
		return _tube(Array(pts), r, 6), top)
	_part("sk_ribs", bone, func() -> ArrayMesh:
		var parts := []
		for i in 6:
			# A barrel: widest in the middle, each rib sloping down from
			# the spine round to the breastbone.
			var y := 1.41 - i * 0.05
			var w := 0.15 - absf(i - 2.0) * 0.012
			for s: float in [1.0, -1.0]:
				var a := Vector3(s * 0.025, y + 0.02, -0.08)
				var mid := Vector3(s * w * 1.25, y - 0.01, -0.01)
				var b := Vector3(s * 0.03, y - 0.075, 0.1 - i * 0.006)
				parts.append(Shape.limb(Shape.curve(a, mid, b, 6), PackedFloat32Array([0.012, 0.012, 0.011, 0.01, 0.009, 0.008]), 4, 1))
		parts.append(_tube([Vector3(0, 1.41, 0.1), Vector3(0, 1.3, 0.105), Vector3(0, 1.17, 0.09)], [0.022, 0.018, 0.012], 6))
		for s: float in [1.0, -1.0]:
			parts.append(_bone(Vector3(s * 0.02, 1.44, 0.07), Vector3(s * 0.19, 1.46, -0.01), 0.014))
		return Shape.merge(parts), top)
	_part("sk_pelvis", bone, func() -> ArrayMesh:
		var b := Shape.blob(Vector3(0.14, 0.065, 0.08), 0.06, 5.0, 8, 12)
		return Shape.warp(b, func(p: Vector3) -> Vector3:
			# Wings of the hip bones flaring up at the sides.
			p.y += absf(p.x) * 0.5 - 0.03
			p.z -= absf(p.x) * 0.15
			return p + Vector3(0, 0.95, -0.01)), top)
	# Where the arms go: the right (-x) holds the sword low and forward, an
	# archer holds its bow out in the left (-x) hand.
	var elbow := func(s: float) -> Vector3:
		if archer and s < 0.0:
			return Vector3(-0.27, 1.25, 0.12)
		return Vector3(s * 0.26, 1.17, 0.03)
	var wrist := func(s: float) -> Vector3:
		if archer and s < 0.0:
			return Vector3(-0.2, 1.25, 0.4)
		if s < 0.0:
			return Vector3(-0.24, 0.97, 0.21)
		return Vector3(0.27, 0.96, 0.16)
	_sides("sk_uarm" + ("a" if archer else ""), bone, func(s: float) -> ArrayMesh:
		return _bone(Vector3(s * 0.2, 1.43, -0.01), elbow.call(s), 0.022), top)
	_sides("sk_farm" + ("a" if archer else ""), bone, func(s: float) -> ArrayMesh:
		var off := Vector3(0, 0, 0.016)
		var e: Vector3 = elbow.call(s)
		var w: Vector3 = wrist.call(s)
		var parts := [_bone(e + off, w + off, 0.016), _bone(e - off, w - off, 0.012)]
		# The hand: a knot of small bones and four hooked fingers.
		parts.append(Shape.warp(Shape.blob(Vector3(0.028, 0.038, 0.024), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + w + Vector3(0, -0.04, 0.01)))
		for f in 4:
			var a := w + Vector3((f - 1.5) * 0.013, -0.07, 0.02)
			parts.append(_tube(Array(Shape.curve(a, a + Vector3(0, -0.04, 0.03), a + Vector3(0, -0.05, -0.01), 4)), [0.008, 0.007, 0.006, 0.005], 4))
		return Shape.merge(parts), top)
	_sides("sk_femur", bone, func(s: float) -> ArrayMesh:
		return _bone(Vector3(s * 0.11, 0.92, -0.02), Vector3(s * 0.13, 0.5, 0.08), 0.026), top)
	_sides("sk_shin", bone, func(s: float) -> ArrayMesh:
		var off := Vector3(0.012, 0, 0)
		var k := Vector3(s * 0.13, 0.5, 0.08)
		var a := Vector3(s * 0.12, 0.09, -0.03)
		var parts := [_bone(k + off, a + off, 0.02), _bone(k - off, a - off, 0.013)]
		# The foot: a heel and four long toes.
		parts.append(Shape.warp(Shape.blob(Vector3(0.035, 0.03, 0.04), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + Vector3(s * 0.12, 0.05, -0.03)))
		for f in 4:
			var t := Vector3(s * 0.12 + (f - 1.5) * 0.017, 0.035, 0.0)
			parts.append(_tube([t, t + Vector3(0, -0.01, 0.06), t + Vector3(0, -0.02, 0.1)], [0.01, 0.009, 0.007], 4))
		return Shape.merge(parts), top)
	if not archer and kind != "gravekeeper":
		_part("sk_helm", rust, func() -> ArrayMesh:
			# A dented iron cap with a brim and a nose guard, rusted brown.
			var d := Shape.blob(Vector3(0.083, 0.088, 0.097), 0.03, 9.0, 8, 14)
			var cap := Shape.warp(d, func(p: Vector3) -> Vector3:
				p.y = maxf(p.y, 0.0) + 0.012
				return Basis(Vector3.RIGHT, 0.15) * p + head)
			var brim := Shape.warp(_tube(_circle(Vector3.ZERO, 0.088, 16), _same(0.011, 16), 5), func(p: Vector3) -> Vector3:
				return Basis(Vector3.RIGHT, 0.15) * Vector3(p.x, 0.012, p.z * 1.12) + head)
			var nasal := _tube([head + Vector3(0, 0.03, 0.097), head + Vector3(0, -0.035, 0.1)], [0.009, 0.007], 4)
			return Shape.merge([cap, brim, nasal]), top)
	_part("sk_rag", rag, func() -> ArrayMesh:
		# A loincloth on a cord: a torn flap hanging in front and a longer
		# one behind.
		var parts := [Shape.warp(_tube(_circle(Vector3.ZERO, 0.13, 14), _same(0.016, 14), 5), func(p: Vector3) -> Vector3:
			return Vector3(p.x, 0.97 - p.z * 0.25, p.z * 0.75))]
		for side: float in [1.0, -1.0]:
			var z := 0.085 * side
			var drop := 0.24 if side > 0.0 else 0.32
			var pts := [Vector3(0, 0.98, z), Vector3(-0.09, 0.98, z)]
			for i in 9:
				var u := float(i) / 8.0
				var torn := 0.05 * absf(sin(u * 11.0 + side)) + 0.03 * absf(sin(u * 23.0))
				var hw := 0.06
				pts.append(Vector3(lerpf(-hw, hw, u), 0.98 - drop * (1.0 - 0.3 * absf(u - 0.5)) + torn, z))
			pts.append(Vector3(0.09, 0.98, z))
			parts.append(Shape.warp(Shape.sheet(PackedVector3Array(pts)), func(p: Vector3) -> Vector3:
				# Wrapped round the hips, hanging loose below, a fold or two.
				p.z += side * (0.05 * (0.98 - p.y) - p.x * p.x * 3.0) + 0.012 * sin(p.x * 70.0)
				return p))
		return Shape.merge(parts), top)
	if archer:
		var g := Vector3(-0.2, 1.22, 0.42)
		_part("sk_bow", wood, func() -> ArrayMesh:
			# Held out upright: a recurved bow, thick at the grip.
			var pts := [g + Vector3(0, -0.5, -0.02), g + Vector3(0, -0.36, 0.07), g + Vector3(0, -0.15, 0.06), g, g + Vector3(0, 0.15, 0.06), g + Vector3(0, 0.36, 0.07), g + Vector3(0, 0.5, -0.02)]
			return _tube(pts, [0.008, 0.014, 0.018, 0.022, 0.018, 0.014, 0.008], 6), top)
		_part("sk_string", Shape.flat(Color(0.6, 0.57, 0.5), 0.9), func() -> ArrayMesh:
			return _tube([g + Vector3(0, -0.5, -0.02), g + Vector3(0, 0, -0.06), g + Vector3(0, 0.5, -0.02)], [0.003, 0.003, 0.003], 4), top)
		_part("sk_quiver", rag, func() -> ArrayMesh:
			var parts := [_tube([Vector3(0.1, 1.0, -0.17), Vector3(0.0, 1.3, -0.16), Vector3(-0.08, 1.5, -0.15)], [0.045, 0.05, 0.052], 8)]
			for i in 4:
				var a := Vector3(-0.08 + (i - 1.5) * 0.015, 1.5, -0.15 + (i % 2) * 0.015)
				parts.append(_tube([a, a + Vector3(-0.04, 0.14, 0.0)], [0.006, 0.006], 4))
			return Shape.merge(parts), top)
		_part("sk_fletch", Shape.flat(Color(0.32, 0.08, 0.06), 0.9), func() -> ArrayMesh:
			var parts := []
			for i in 4:
				var a := Vector3(-0.12 + (i - 1.5) * 0.015, 1.64, -0.15 + (i % 2) * 0.015)
				parts.append(Shape.sheet(PackedVector3Array([a, a + Vector3(-0.02, 0.07, 0.025), a + Vector3(-0.025, 0.08, -0.02)])))
			return Shape.merge(parts), top)
	elif kind == "gravekeeper":
		_part("sk_crown", rust, func() -> ArrayMesh:
			var c := head + Vector3(0, 0.07, -0.01)
			var parts := [_tube(_circle(c, 0.09, 14), _same(0.012, 14), 5)]
			for i in 7:
				var a := i * TAU / 7.0
				var at := c + Vector3(cos(a) * 0.09, 0, sin(a) * 0.09)
				parts.append(_claw(at, at + Vector3(0, 0.04, 0), at + Vector3(cos(a) * 0.01, 0.08, sin(a) * 0.01), 0.012))
			return Shape.merge(parts), top)
		_part("sk_spade", wood, func() -> ArrayMesh:
			var shaft := _tube([Vector3(-0.25, 0.52, 0.36), Vector3(-0.24, 0.97, 0.22), Vector3(-0.22, 1.5, 0.1)], [0.016, 0.016, 0.018], 6)
			var grip := _tube([Vector3(-0.29, 1.5, 0.1), Vector3(-0.15, 1.5, 0.1)], [0.016, 0.016], 5)
			return Shape.merge([shaft, grip]), top)
		_part("sk_blade", rust, func() -> ArrayMesh:
			# A grave-digger's spade, worn square and notched at the edge.
			var outline := [Vector2(0, 0.3), Vector2(-0.1, 0.28), Vector2(-0.11, 0.08), Vector2(-0.06, 0.0), Vector2(-0.02, 0.01), Vector2(0.0, -0.01), Vector2(0.06, 0.0), Vector2(0.11, 0.08), Vector2(0.1, 0.28), Vector2(0, 0.3)]
			var pts := PackedVector3Array([Vector3(0, 0.15, 0)])
			var rim := []
			for o: Vector2 in outline:
				pts.append(Vector3(o.x, o.y, 0))
				rim.append(Vector3(o.x, o.y, 0))
			var plate := Shape.merge([Shape.sheet(pts), _tube(rim, _same(0.01, rim.size() - 1), 4)])
			var bas := Basis(Vector3.RIGHT, 0.3)
			return Shape.warp(plate, func(p: Vector3) -> Vector3:
				p.z -= p.x * p.x * 1.5
				return bas * p + Vector3(-0.26, 0.24, 0.42)), top)
	else:
		_part("sk_sword", rust, func() -> ArrayMesh:
			# Held low and forward, the point raised.
			var h := Vector3(-0.24, 0.92, 0.22)
			var bas := Basis(Vector3.RIGHT, Vector3.UP.angle_to(Vector3(0, 0.45, 0.85)))
			var blade := Shape.warp(Shape.blob(Vector3(0.036, 0.38, 0.008), 0.0, 1.0, 10, 8), func(p: Vector3) -> Vector3:
				# Tapered to a point, a notch out of the edge.
				var t := (p.y + 0.38) / 0.76
				p.x *= lerpf(1.0, 0.3, t * t) * (0.65 if absf(t - 0.55) < 0.06 else 1.0)
				return h + bas * (p + Vector3(0, 0.44, 0)))
			var guard := Shape.warp(_tube([Vector3(-0.09, 0.02, 0), Vector3(0, 0, 0), Vector3(0.09, 0.02, 0)], [0.013, 0.015, 0.013], 5), func(p: Vector3) -> Vector3: return h + bas * (p + Vector3(0, 0.06, 0)))
			var grip := Shape.warp(_tube([Vector3(0, -0.1, 0), Vector3(0, 0.05, 0)], [0.014, 0.014], 5), func(p: Vector3) -> Vector3: return h + bas * p)
			return Shape.merge([blade, guard, grip]), top)


## Points round a circle of radius [param r] about [param c], flat, closed.
static func _circle(c: Vector3, r: float, n: int) -> Array:
	var out := []
	for i in n + 1:
		var a := i * TAU / n
		out.append(c + Vector3(cos(a) * r, 0, sin(a) * r))
	return out


## A ring of radius [param r] round [param axis] at [param at], as thick as
## [param thick]: bands, cuffs, chain links, crowns.
static func _band(at: Vector3, axis: Vector3, r: float, thick: float, n := 14) -> ArrayMesh:
	var b := Basis(Quaternion(Vector3.UP, axis.normalized()))
	return Shape.warp(_tube(_circle(Vector3.ZERO, r, n), _same(thick, n), 5 if thick > 0.02 else 4), func(p: Vector3) -> Vector3: return at + b * p)


static func _same(r: float, n: int) -> Array:
	var out := []
	for i in n + 1:
		out.append(r)
	return out


## Cultist: a fire priest in heavy, dirty crimson robes, a ragged black
## mantle over the shoulders, a deep hood with a pale bone mask in it and
## embers for eyes. One hand grips an iron-shod staff with a fire caught in
## a claw at its head, the other is held out, ready to cast.
func _cultist() -> void:
	var robe := Shape.material(Color(0.33, 0.07, 0.07), Color(0.2, 0.05, 0.05), 4.0, 0.92, 0.6, 0.0, 23)
	var mantle := Shape.material(Color(0.12, 0.1, 0.09), Color(0.05, 0.04, 0.04), 3.0, 0.95, 0.7, 0.0, 29)
	var mask := Shape.material(Color(0.66, 0.6, 0.5), Color(0.38, 0.32, 0.25), 6.0, 0.6, 0.4, 0.0, 31)
	var flesh := Shape.material(Color(0.5, 0.42, 0.38), Color(0.3, 0.22, 0.2), 6.0, 0.6, 0.5, 0.0, 37)
	var wood := Shape.material(Color(0.24, 0.17, 0.11), Color(0.1, 0.07, 0.05), 6.0, 0.8, 0.6, 0.0, 19)
	var iron := Shape.material(Color(0.25, 0.24, 0.24), Color(0.25, 0.13, 0.07), 5.0, 0.45, 0.8, 0.7, 13)
	var top := 1.8
	_part("cu_robe", robe, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.34, 0.0), Vector2(0.31, 0.2), Vector2(0.25, 0.55), Vector2(0.2, 0.9), Vector2(0.19, 1.1), Vector2(0.21, 1.28), Vector2(0.17, 1.42), Vector2(0.08, 1.48)]), 22, 7, 0.14)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			# The hem dragged and torn, the cloth deeper at the back, the
			# whole figure leaning in.
			var a := atan2(p.z, p.x)
			if p.y < 0.15:
				p.y = maxf(0.0, p.y + 0.05 * absf(sin(a * 5.0 + 0.4)) - 0.03)
			p.z *= 0.85
			p.z += p.y * 0.05 - 0.02
			return p), top)
	_part("cu_mantle", mantle, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.3, 1.02), Vector2(0.27, 1.18), Vector2(0.24, 1.32), Vector2(0.17, 1.43), Vector2(0.11, 1.48)]), 20, 9, 0.18)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			# Shorter in front, hanging in ragged points behind.
			var a := atan2(p.z, p.x)
			if p.y < 1.2:
				p.y -= (0.12 * maxf(0.0, -sin(a)) + 0.04 * absf(sin(a * 6.0))) * (1.2 - p.y) / 0.18
				p.y += 0.08 * maxf(0.0, sin(a))
			p.z = p.z * 0.85 + p.y * 0.05 - 0.02
			return p), top)
	_part("cu_belt", mantle, func() -> ArrayMesh:
		var ring := Shape.warp(_tube(_circle(Vector3.ZERO, 0.2, 16), _same(0.018, 16), 5), func(p: Vector3) -> Vector3:
			return Vector3(p.x, 0.98 - p.z * 0.1, p.z * 0.85 + 0.03))
		var knot := _tube([Vector3(0.08, 0.98, 0.2), Vector3(0.1, 0.8, 0.22), Vector3(0.11, 0.6, 0.2)], [0.02, 0.016, 0.012], 5)
		return Shape.merge([ring, knot]), top)
	var hood_at := Vector3(0, 1.5, 0.06)
	_part("cu_hood", robe, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.15, -0.12), Vector2(0.155, 0.0), Vector2(0.145, 0.1), Vector2(0.11, 0.19), Vector2(0.05, 0.25), Vector2(0.0, 0.27)]), 16, 4, 0.08, 1.5)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			# Peaked, the point falling back; the front edge drawn forward
			# so the face sits in shadow.
			p.z -= maxf(0.0, p.y - 0.15) * 0.6
			p.z += 0.02
			return p + hood_at), top)
	_part("cu_shadow", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.11, 0.13, 0.08), 0.0, 1.0, 6, 10), func(p: Vector3) -> Vector3: return p + hood_at + Vector3(0, 0.04, 0.03)), top)
	_part("cu_mask", mask, func() -> ArrayMesh:
		var m := Shape.blob(Vector3(0.075, 0.095, 0.04), 0.02, 2.0, 8, 12)
		return Shape.warp(m, func(p: Vector3) -> Vector3:
			# A smooth face plate, a long chin, no mouth.
			p.z = maxf(p.z, 0.0) - (p.x * p.x) * 4.0
			if p.y < 0.0:
				p.x *= 1.0 + p.y * 3.0
			return p + hood_at + Vector3(0, 0.03, 0.1)), top)
	_sockets("cu", hood_at.y + 0.055, hood_at.z + 0.13, 0.03, 0.018, Color(1.0, 0.45, 0.1), 0.016)
	_sides("cu_sleeve", robe, func(s: float) -> ArrayMesh:
		# The right (-x) arm down at the staff, the left reaching forward.
		var sh := Vector3(s * 0.2, 1.35, 0.0)
		var el := Vector3(s * 0.32, 1.1, 0.08) if s < 0.0 else Vector3(0.3, 1.12, 0.18)
		var wr := Vector3(-0.36, 1.0, 0.2) if s < 0.0 else Vector3(0.24, 1.12, 0.42)
		return _tube([sh, el, wr], [0.07, 0.07, 0.095], 10), top)
	_sides("cu_hand", flesh, func(s: float) -> ArrayMesh:
		var wr := Vector3(-0.36, 0.98, 0.24) if s < 0.0 else Vector3(0.23, 1.11, 0.47)
		var parts := [Shape.warp(Shape.blob(Vector3(0.035, 0.04, 0.03), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + wr)]
		for f in 4:
			var a := wr + Vector3((f - 1.5) * 0.017, -0.02, 0.025)
			var tip := a + (Vector3(0, -0.02, 0.06) if s > 0.0 else Vector3(s * 0.03, 0.0, 0.0))
			parts.append(_tube([a, tip.lerp(a, 0.4) + Vector3(0, 0.01, 0), tip], [0.01, 0.009, 0.006], 4))
		return Shape.merge(parts), top)
	var st := Vector3(-0.4, 0.0, 0.24)
	_part("cu_staff", wood, func() -> ArrayMesh:
		# Knotted, crooked wood.
		var pts := []
		var r := []
		for i in 9:
			var t := float(i) / 8.0
			pts.append(st + Vector3(sin(t * 9.0) * 0.012, 0.05 + t * 1.65, cos(t * 7.0) * 0.012))
			r.append(0.026 if i % 3 == 1 else 0.02)
		return _tube(pts, r, 6), top)
	_part("cu_claw", iron, func() -> ArrayMesh:
		# An iron claw at the head, its prongs curled round the fire.
		var c := st + Vector3(0, 1.78, 0)
		var parts := [_tube([c + Vector3(0, -0.1, 0), c + Vector3(0, -0.05, 0)], [0.03, 0.035], 6)]
		for i in 4:
			var a := i * TAU / 4.0 + 0.4
			var o := Vector3(cos(a), 0, sin(a))
			parts.append(_claw(c + Vector3(0, -0.06, 0), c + o * 0.11 + Vector3(0, 0.02, 0), c + o * 0.04 + Vector3(0, 0.13, 0), 0.014))
		return Shape.merge(parts), top)
	Art.part(_model, Art.sphere(0.075, 10), Fx.glow(El.COLOR[El.FIRE], 4.0), st + Vector3(0, 1.82, 0))


## Imp: a small, wiry fire devil. Hunched on backward-bent goat legs, long
## clawed arms, swept-back horns, a whip of a tail and torn bat wings half
## spread behind it; scorched dark red hide, embers in the eyes and a glow
## in its open mouth.
func _imp() -> void:
	var hide := Shape.material(Color(0.4, 0.13, 0.08), Color(0.15, 0.05, 0.04), 6.0, 0.55, 0.8, 0.0, 41)
	var wing := Shape.material(Color(0.25, 0.08, 0.06), Color(0.1, 0.03, 0.03), 4.0, 0.7, 0.4, 0.0, 43)
	var horn := Shape.material(Color(0.16, 0.13, 0.11), Color(0.05, 0.04, 0.04), 8.0, 0.4, 0.6, 0.0, 47)
	var top := 1.15
	var head := Vector3(0, 0.98, 0.2)
	_part("im_body", hide, func() -> ArrayMesh:
		var t := _tube([Vector3(0, 0.56, -0.08), Vector3(0, 0.66, -0.06), Vector3(0, 0.8, 0.0), Vector3(0, 0.9, 0.1)], [0.09, 0.1, 0.13, 0.1], 10)
		return Shape.warp(t, func(p: Vector3) -> Vector3:
			# A narrow waist, a deep chest, ribs and a spine showing.
			var chest := smoothstep(0.66, 0.82, p.y)
			p.x *= lerpf(0.9, 1.3, chest)
			p.x += signf(p.x) * 0.008 * sin(p.y * 110.0) * chest
			return p), top)
	_part("im_head", hide, func() -> ArrayMesh:
		var h := Shape.blob(Vector3(0.075, 0.075, 0.09), 0.04, 6.0, 9, 14)
		return Shape.warp(h, func(p: Vector3) -> Vector3:
			# Wide at the cheekbones, a pointed chin, a heavy brow.
			if p.y < 0.0:
				p.x *= 1.0 + p.y * 4.0
				p.z += -p.y * 0.4
			if p.y > 0.02 and p.z > 0.04:
				p.y += 0.01
			return p + head), top)
	_part("im_mouth", Fx.glow(El.COLOR[El.FIRE], 1.6), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.03, 0.012, 0.02), 0.0, 1.0, 4, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.04, 0.085)), top)
	_sockets("im", head.y + 0.015, head.z + 0.07, 0.03, 0.02, Color(1.0, 0.8, 0.15), 0.015)
	_sides("im_horn", horn, func(s: float) -> ArrayMesh:
		var a := head + Vector3(s * 0.045, 0.05, 0.02)
		return _tube(Array(Shape.curve(a, a + Vector3(s * 0.08, 0.1, -0.06), a + Vector3(s * 0.07, 0.07, -0.2), 6)), [0.024, 0.02, 0.016, 0.011, 0.007, 0.002], 6), top)
	_sides("im_ear", hide, func(s: float) -> ArrayMesh:
		var a := head + Vector3(s * 0.07, 0.0, -0.01)
		return _tube([a, a + Vector3(s * 0.06, 0.02, -0.03), a + Vector3(s * 0.11, 0.04, -0.05)], [0.02, 0.012, 0.002], 5), top)
	_sides("im_arm", hide, func(s: float) -> ArrayMesh:
		var sh := Vector3(s * 0.13, 0.86, 0.06)
		var el := Vector3(s * 0.22, 0.68, 0.02)
		var wr := Vector3(s * 0.2, 0.55, 0.2)
		var parts := [_tube([sh, el, wr], [0.04, 0.03, 0.024], 7)]
		for f in 3:
			var o := (f - 1.0) * 0.02
			var a := wr + Vector3(o, 0, 0.02)
			parts.append(_claw(a, a + Vector3(o * 0.5, 0.0, 0.05), a + Vector3(o, -0.05, 0.07), 0.01))
		return Shape.merge(parts), top)
	_sides("im_leg", hide, func(s: float) -> ArrayMesh:
		# Goat legs: thigh forward, shin back, a long raised foot.
		var parts := [_tube([Vector3(s * 0.07, 0.58, -0.08), Vector3(s * 0.11, 0.42, 0.06), Vector3(s * 0.11, 0.24, -0.08), Vector3(s * 0.1, 0.05, -0.03)], [0.055, 0.04, 0.026, 0.02], 7)]
		for f in 3:
			var o := (f - 1.0) * 0.022
			var a := Vector3(s * 0.1 + o, 0.04, -0.02)
			parts.append(_claw(a, a + Vector3(o * 0.3, 0.0, 0.05), a + Vector3(o * 0.6, -0.03, 0.08), 0.012))
		return Shape.merge(parts), top)
	_part("im_tail", hide, func() -> ArrayMesh:
		var pts := [Vector3(0, 0.58, -0.12), Vector3(0, 0.45, -0.3), Vector3(0.08, 0.3, -0.42), Vector3(0.2, 0.3, -0.5), Vector3(0.26, 0.42, -0.5)]
		var t := _tube(pts, [0.03, 0.022, 0.016, 0.012, 0.008], 6)
		var barb := _claw(pts[4], pts[4] + Vector3(0.03, 0.06, 0.0), pts[4] + Vector3(0.0, 0.1, 0.02), 0.02)
		return Shape.merge([t, barb]), top)
	_sides("im_wing", wing, func(s: float) -> ArrayMesh:
		# A bat wing half spread: an arm of bone and a torn membrane strung
		# between its fingers.
		var root := Vector3(s * 0.08, 0.86, -0.08)
		var joint := Vector3(s * 0.32, 1.08, -0.22)
		var tips := [Vector3(s * 0.62, 1.2, -0.3), Vector3(s * 0.58, 0.9, -0.34), Vector3(s * 0.46, 0.66, -0.3), Vector3(s * 0.26, 0.6, -0.22)]
		var parts := [_tube([root, joint], [0.025, 0.018], 6)]
		var edge := tips + [root + Vector3(0, -0.16, 0.02)]
		for i in tips.size():
			parts.append(_tube([joint, tips[i]], [0.014, 0.004], 5))
		for i in edge.size() - 1:
			# Each panel sags in a scallop between two fingers.
			var a: Vector3 = edge[i]
			var b: Vector3 = edge[i + 1]
			var dip := ((a + b) * 0.5).lerp(joint, 0.3)
			parts.append(Shape.sheet(PackedVector3Array([joint, a, dip, b])))
		return Shape.merge(parts), top)


## Brute: a hulking ogre, all shoulders and arms. A small brutal head thrust
## forward under a hump of muscle, a heavy brow, tusks jutting from an
## underbite; arms like tree trunks with shackles still on the wrists and
## fists the size of its head, short bowed legs. A hide loincloth and a
## crude spiked iron plate strapped to one shoulder.
## The Frost Brute is the same giant gone pale with cold: rimed white on
## top, blue beneath, ice crystals grown out across its shoulders and back.
func _brute(frost: bool) -> void:
	var k := "fb" if frost else "br"
	var skin := Shape.material(Color(0.5, 0.54, 0.58), Color(0.28, 0.31, 0.36), 4.0, 0.45, 0.7, 0.0, 53) if frost else Shape.material(Color(0.45, 0.36, 0.29), Color(0.26, 0.19, 0.15), 4.0, 0.55, 0.7, 0.0, 53)
	var leather := Shape.material(Color(0.25, 0.18, 0.12), Color(0.14, 0.1, 0.07), 4.0, 0.85, 0.5, 0.0, 59)
	var iron := Shape.material(Color(0.3, 0.29, 0.29), Color(0.3, 0.16, 0.08), 4.0, 0.42, 0.3, 0.7, 13)
	var tusk := Shape.material(Color(0.7, 0.64, 0.5), Color(0.5, 0.42, 0.3), 8.0, 0.5, 0.4, 0.0, 61)
	var top := 2.3
	var cold := Color(0.62, 0.7, 0.85) if frost else Color.WHITE
	var head := Vector3(0, 1.9, 0.6)
	_part(k + "_torso", skin, func() -> ArrayMesh:
		var t := _tube([Vector3(0, 0.95, -0.04), Vector3(0, 1.2, 0.04), Vector3(0, 1.52, 0.06), Vector3(0, 1.76, 0.08)], [0.31, 0.36, 0.45, 0.34], 16)
		return Shape.warp(t, func(p: Vector3) -> Vector3:
			# Wide through the chest, a hard gut, a hunched back rising into
			# a hump of muscle behind the head; slabs of pectoral muscle and
			# a groove down the spine.
			var chest := smoothstep(1.25, 1.65, p.y)
			p.x *= lerpf(1.1, 1.45, chest)
			var ax := absf(p.x)
			if p.z > 0.0:
				p.z += 0.08 * exp(-pow((ax - 0.24) / 0.15, 2.0)) * exp(-pow((p.y - 1.58) / 0.13, 2.0))
				p.z -= 0.03 * exp(-pow(ax / 0.05, 2.0)) * smoothstep(1.1, 1.5, p.y)
				p.z += 0.06 * exp(-pow((p.y - 1.15) / 0.16, 2.0)) * smoothstep(0.1, 0.3, p.z)
			else:
				p.z += 0.05 * exp(-pow(ax / 0.07, 2.0)) * smoothstep(1.0, 1.4, p.y)
				p.y += 0.14 * smoothstep(1.5, 1.85, p.y) * smoothstep(0.0, -0.3, p.z)
			return p), top, cold)
	_part(k + "_traps", skin, func() -> ArrayMesh:
		# The hump of muscle the head hangs forward from.
		var b := Shape.blob(Vector3(0.36, 0.2, 0.3), 0.04, 6.0, 9, 14)
		return Shape.warp(b, func(p: Vector3) -> Vector3:
			p.z += p.y * 0.6
			return p + Vector3(0, 1.84, 0.2)), top, cold)
	_sides(k + "_shoulder", skin, func(s: float) -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.25, 0.22, 0.25), 0.05, 3.0 + s, 9, 14), func(p: Vector3) -> Vector3: return p + Vector3(s * 0.58, 1.8, 0.08)), top, cold)
	_part(k + "_head", skin, func() -> ArrayMesh:
		var h := Shape.blob(Vector3(0.13, 0.135, 0.14), 0.04, 4.0, 10, 14)
		var skull := Shape.warp(h, func(p: Vector3) -> Vector3:
			# A flat, sloping skull; the jaw wider than the forehead and
			# pushed out under it.
			if p.y > 0.03:
				p.y = 0.03 + (p.y - 0.03) * 0.6
				p.z -= (p.y - 0.03) * 0.8
			if p.y < -0.02:
				p.x *= 1.0 + (-0.02 - p.y) * 2.5
				p.z += 0.04
			return p + head)
		var brow := _tube(Array(Shape.curve(head + Vector3(-0.11, 0.04, 0.08), head + Vector3(0, 0.07, 0.17), head + Vector3(0.11, 0.04, 0.08), 5)), [0.035, 0.04, 0.042, 0.04, 0.035], 7)
		var nose := Shape.warp(Shape.blob(Vector3(0.035, 0.04, 0.035), 0.05, 2.0, 5, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.005, 0.16))
		return Shape.merge([skull, brow, nose]), top, cold)
	_part(k + "_mouth", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.08, 0.02, 0.04), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.075, 0.16)), top)
	_part(k + "_tusks", tusk, func() -> ArrayMesh:
		var parts := []
		for s: float in [1.0, -1.0]:
			var a := head + Vector3(s * 0.07, -0.09, 0.17)
			parts.append(_claw(a, a + Vector3(s * 0.01, 0.06, 0.02), a + Vector3(s * 0.035, 0.1, -0.01), 0.02))
		return Shape.merge(parts), top)
	_sockets(k, head.y + 0.025, head.z + 0.14, 0.055, 0.026, Color(1.0, 0.25, 0.05) if not frost else Color(0.5, 0.85, 1.0), 0.019)
	_sides(k + "_uarm", skin, func(s: float) -> ArrayMesh:
		return _tube([Vector3(s * 0.64, 1.78, 0.06), Vector3(s * 0.77, 1.55, 0.07), Vector3(s * 0.83, 1.32, 0.12)], [0.2, 0.18, 0.14], 10), top, cold)
	_sides(k + "_farm", skin, func(s: float) -> ArrayMesh:
		# The forearm and a clenched fist: a heavy palm, four fingers rolled
		# under it, the knuckles in front, a thumb across.
		var c := Vector3(s * 0.8, 0.7, 0.36)
		var parts := [_tube([Vector3(s * 0.83, 1.32, 0.12), Vector3(s * 0.85, 1.12, 0.22), Vector3(s * 0.8, 0.86, 0.32)], [0.14, 0.17, 0.12], 10), Shape.warp(Shape.blob(Vector3(0.12, 0.13, 0.11), 0.04, 5.0 + s, 8, 12), func(p: Vector3) -> Vector3: return p + c)]
		for f in 4:
			var o := Vector3(s * (f - 1.5) * 0.06, 0.0, 0.0)
			parts.append(_tube([c + o + Vector3(0, 0.08, 0.04), c + o + Vector3(0, 0.05, 0.13), c + o + Vector3(0, -0.04, 0.14), c + o + Vector3(0, -0.09, 0.07)], [0.042, 0.045, 0.04, 0.035], 4))
		parts.append(_tube([c + Vector3(-s * 0.1, 0.02, 0.0), c + Vector3(-s * 0.1, -0.05, 0.08), c + Vector3(-s * 0.03, -0.07, 0.13)], [0.045, 0.04, 0.035], 5))
		return Shape.merge(parts), top, cold)
	_sides(k + "_cuff", iron, func(s: float) -> ArrayMesh:
		# An iron shackle on each wrist, a few links of broken chain.
		var at := Vector3(s * 0.81, 0.92, 0.3)
		var axis := Vector3(s * 0.04, 0.24, -0.1).normalized()
		var parts := [_band(at, axis, 0.15, 0.045, 12), _band(at + axis * 0.09, axis, 0.145, 0.03, 10)]
		for i in 3:
			var l := at + Vector3(s * 0.12, -0.08 - i * 0.07, -0.02)
			parts.append(_band(l, Vector3(1, 0, 0) if i % 2 == 0 else Vector3(0, 0, 1), 0.035, 0.012, 8))
		return Shape.merge(parts), top)
	_sides(k + "_thigh", skin, func(s: float) -> ArrayMesh:
		return _tube([Vector3(s * 0.24, 0.98, -0.02), Vector3(s * 0.32, 0.74, 0.06), Vector3(s * 0.35, 0.5, 0.1)], [0.22, 0.2, 0.14], 10), top, cold)
	_sides(k + "_shin", skin, func(s: float) -> ArrayMesh:
		var shin := _tube([Vector3(s * 0.35, 0.5, 0.1), Vector3(s * 0.35, 0.34, 0.05), Vector3(s * 0.33, 0.12, 0.0)], [0.14, 0.15, 0.11], 10)
		var f := Shape.blob(Vector3(0.13, 0.08, 0.2), 0.05, 2.0 + s, 7, 12)
		var foot := Shape.warp(f, func(p: Vector3) -> Vector3:
			p.y = maxf(p.y, -0.06)
			return p + Vector3(s * 0.34, 0.07, 0.08))
		var parts := [shin, foot]
		for t in 3:
			var a := Vector3(s * 0.34 + (t - 1) * 0.06, 0.04, 0.25)
			parts.append(_claw(a, a + Vector3(0, 0.0, 0.04), a + Vector3(0, -0.03, 0.06), 0.03))
		return Shape.merge(parts), top, cold)
	_part(k + "_loin", leather, func() -> ArrayMesh:
		var belt := Shape.warp(_tube(_circle(Vector3.ZERO, 0.36, 18), _same(0.05, 18), 6), func(p: Vector3) -> Vector3:
			return Vector3(p.x * 1.1, 0.98 - p.z * 0.1, p.z * 0.95 + 0.04))
		var parts := [belt]
		for side: float in [1.0, -1.0]:
			# Flaps hanging over the gut in front and the rump behind, torn
			# at the hem.
			var z := 0.38 * side + 0.04
			var pts := [Vector3(0, 0.96, z), Vector3(-0.2, 0.97, z)]
			for i in 7:
				var u := float(i) / 6.0
				pts.append(Vector3(lerpf(-0.18, 0.18, u), 0.55 + 0.06 * absf(sin(u * 9.0 + side)), z + side * 0.06))
			pts.append(Vector3(0.2, 0.97, z))
			parts.append(Shape.warp(Shape.sheet(PackedVector3Array(pts)), func(p: Vector3) -> Vector3:
				p.z += side * (0.05 - p.x * p.x * 1.5) + 0.015 * sin(p.x * 40.0)
				return p))
		return Shape.merge(parts), top)
	_part(k + "_plate", iron, func() -> ArrayMesh:
		# A crude iron plate strapped to the left shoulder, a spike or two.
		var d := Shape.blob(Vector3(0.3, 0.05, 0.3), 0.04, 9.0, 6, 14)
		var plate := Shape.warp(d, func(p: Vector3) -> Vector3:
			p.y -= (p.x * p.x + p.z * p.z) * 2.2
			return Basis(Vector3.BACK, -0.45) * p + Vector3(0.64, 2.0, 0.06))
		var parts := [plate]
		for i in 3:
			var at := Vector3(0.57 + i * 0.09, 2.04 - i * 0.05, 0.0 + (i - 1) * 0.08)
			parts.append(_claw(at, at + Vector3(0.02, 0.06, 0), at + Vector3(0.05, 0.14, -0.02), 0.03))
		# Its strap runs across the chest and back, under the other arm.
		var strap := []
		for q: Vector3 in _circle(Vector3.ZERO, 1.0, 20):
			strap.append(Basis(Vector3.BACK, -0.75) * Vector3(q.x * 0.72, 0, q.z * 0.6) + Vector3(0.05, 1.58, 0.1))
		parts.append(_tube(strap, _same(0.028, 20), 5))
		return Shape.merge(parts), top)
	if frost:
		# Ice grown out of the shoulders and back, glowing faintly cold.
		var ice := Shape.glassy(Color(0.62, 0.84, 1.0), 0.5)
		_part("fb_ice", ice, func() -> ArrayMesh:
			var parts := []
			var seeds := [Vector3(-0.55, 2.0, 0.0), Vector3(-0.4, 2.05, -0.15), Vector3(-0.2, 2.0, -0.3), Vector3(0.0, 2.02, -0.32), Vector3(0.2, 1.98, -0.3), Vector3(0.1, 1.85, -0.45), Vector3(-0.15, 1.8, -0.48), Vector3(-0.7, 1.9, 0.1)]
			for i in seeds.size():
				var at: Vector3 = seeds[i]
				var out := Vector3(at.x * 0.6, 1.0, at.z * 1.2).normalized()
				var len := 0.22 + 0.12 * sin(i * 2.3) * sin(i * 2.3)
				var bend := out.rotated(Vector3.RIGHT, sin(i * 1.7) * 0.3)
				parts.append(_tube([at - out * 0.04, at + bend * len * 0.5, at + bend * len], [0.05, 0.035, 0.0], 5))
			return Shape.merge(parts), top)


## Wraith: an empty, hooded shroud hanging in the air, its hem torn into
## long streamers that trail into cold mist. Out of the sleeves come long
## grey arms of skin and bone with hooked fingers, reaching for you; in the
## black of the hood, two pale points.
func _wraith() -> void:
	var cloak := Shape.material(Color(0.13, 0.15, 0.19), Color(0.05, 0.06, 0.08), 3.0, 0.95, 0.6, 0.0, 71)
	var flesh := Shape.material(Color(0.48, 0.53, 0.56), Color(0.3, 0.34, 0.38), 6.0, 0.5, 0.5, 0.0, 73)
	var top := 1.9
	_part("wr_shroud", cloak, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.36, 0.05), Vector2(0.32, 0.35), Vector2(0.26, 0.75), Vector2(0.22, 1.1), Vector2(0.23, 1.3), Vector2(0.2, 1.45), Vector2(0.1, 1.55)]), 22, 8, 0.2)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			# Torn into long points at the bottom, longest behind, the cloth
			# blown back as it drifts towards you.
			var a := atan2(p.z, p.x)
			var hang := 1.0 - smoothstep(0.05, 0.6, p.y)
			p.y += hang * (0.25 * absf(sin(a * 4.5 + 0.6)) + 0.1 * absf(sin(a * 11.0)) - 0.1)
			p.z -= hang * 0.25 + p.y * -0.04
			return p), top)
	_part("wr_streamers", cloak, func() -> ArrayMesh:
		# A few rags trailing out behind.
		var parts := []
		for i in 4:
			var x := (i - 1.5) * 0.14
			var a := Vector3(x, 0.4 + absf(x) * 0.5, -0.22)
			var pts := PackedVector3Array([a + Vector3(-0.05, 0, 0), a + Vector3(0.05, 0, 0), a + Vector3(0.04 + x * 0.2, -0.22, -0.3), a + Vector3(x * 0.3, -0.32, -0.5), a + Vector3(-0.03 + x * 0.2, -0.2, -0.28)])
			parts.append(Shape.warp(Shape.sheet(pts), func(p: Vector3) -> Vector3:
				p.y += 0.04 * sin(p.z * 14.0 + i)
				return p))
		return Shape.merge(parts), top)
	var hood_at := Vector3(0, 1.5, 0.05)
	_part("wr_hood", cloak, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.17, -0.14), Vector2(0.17, 0.0), Vector2(0.155, 0.1), Vector2(0.12, 0.2), Vector2(0.05, 0.27), Vector2(0.0, 0.28)]), 16, 4, 0.1, 1.6)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			p.z -= maxf(0.0, p.y - 0.12) * 0.7
			p.z += 0.04
			return p + hood_at), top)
	_part("wr_void", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.12, 0.14, 0.09), 0.0, 1.0, 6, 10), func(p: Vector3) -> Vector3: return p + hood_at + Vector3(0, 0.04, 0.05)), top)
	_eye_pair(hood_at.y + 0.06, hood_at.z + 0.13, 0.045, Color(0.55, 0.9, 1.0), 0.02)
	_sides("wr_sleeve", cloak, func(s: float) -> ArrayMesh:
		var sh := Vector3(s * 0.21, 1.33, 0.0)
		return _tube([sh, Vector3(s * 0.32, 1.18, 0.12), Vector3(s * 0.34, 1.12, 0.3)], [0.07, 0.08, 0.12], 10), top)
	_sides("wr_arm", flesh, func(s: float) -> ArrayMesh:
		# Bone-thin forearms reaching out, long fingers curled like hooks.
		var w := Vector3(s * 0.33, 1.12, 0.62)
		var parts := [_tube([Vector3(s * 0.34, 1.12, 0.28), Vector3(s * 0.34, 1.13, 0.45), w], [0.035, 0.03, 0.025], 6)]
		for f in 4:
			var o := (f - 1.5) * 0.022
			var a := w + Vector3(s * o, 0.0, 0.02)
			parts.append(_tube(Array(Shape.curve(a, a + Vector3(s * o * 0.8, 0.0, 0.12), a + Vector3(s * o, -0.08, 0.14), 4)), [0.011, 0.01, 0.008, 0.005], 4))
		return Shape.merge(parts), top)
	var wisps := Fx.particles(Color(0.5, 0.75, 0.9, 0.5), 18, 1.0, 0.4)
	wisps.position.y = 0.3
	wisps.direction = Vector3.DOWN
	wisps.initial_velocity_max = 0.5
	_model.add_child(wisps)
	wisps.emitting = true


## Drowned: a sailor long under the water, come back up. Bloated, wet,
## grey-green and blotched, shambling with its head hung forward, jaw
## slack; strands of weed hanging off its scalp and shoulders, barnacles on
## its back, the rotten remains of a shirt and a length of rusted chain
## still locked round one wrist.
func _drowned() -> void:
	var skin := Shape.material(Color(0.43, 0.43, 0.32), Color(0.24, 0.25, 0.18), 4.0, 0.42, 0.6, 0.0, 79)
	var weed := Shape.material(Color(0.16, 0.22, 0.12), Color(0.07, 0.1, 0.06), 6.0, 0.4, 0.5, 0.0, 83)
	var cloth := Shape.material(Color(0.36, 0.34, 0.28), Color(0.18, 0.18, 0.14), 3.0, 0.6, 0.6, 0.0, 89)
	var iron := Shape.material(Color(0.3, 0.27, 0.24), Color(0.33, 0.17, 0.08), 6.0, 0.5, 0.6, 0.5, 13)
	var shell := Shape.material(Color(0.55, 0.52, 0.45), Color(0.3, 0.28, 0.24), 10.0, 0.7, 0.8, 0.0, 97)
	var top := 1.6
	var head := Vector3(0, 1.38, 0.3)
	_part("dr_body", skin, func() -> ArrayMesh:
		var t := _tube([Vector3(0, 0.82, -0.04), Vector3(0, 0.98, 0.0), Vector3(0, 1.15, 0.06), Vector3(0, 1.3, 0.14), Vector3(0, 1.34, 0.22)], [0.15, 0.2, 0.21, 0.18, 0.08], 12)
		t = Shape.warp(t, func(p: Vector3) -> Vector3:
			# Swollen belly, round sloping shoulders, a stoop.
			p.x *= lerpf(1.1, 1.3, smoothstep(1.0, 1.25, p.y))
			if p.z > 0.0 and p.y < 1.1:
				p.z += 0.06 * exp(-pow((p.y - 0.95) / 0.1, 2.0))
			return p)
		var neck := _tube([Vector3(0, 1.28, 0.16), head + Vector3(0, -0.04, -0.06)], [0.07, 0.06], 8)
		return Shape.merge([t, neck]), top)
	_part("dr_head", skin, func() -> ArrayMesh:
		var h := Shape.warp(Shape.blob(Vector3(0.1, 0.11, 0.11), 0.07, 9.0, 10, 14), func(p: Vector3) -> Vector3:
			# Puffy, waterlogged, the face sagging down.
			if p.y < 0.0:
				p.x *= 1.0 + p.y * 1.2
				p.z += -p.y * 0.3
			return p + head)
		return h, top)
	_part("dr_jaw", skin, func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.065, 0.025, 0.06), 0.03, 2.0, 6, 10), func(p: Vector3) -> Vector3:
			return Basis(Vector3.RIGHT, 0.4) * p + head + Vector3(0, -0.11, 0.05)), top)
	_part("dr_mouth", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.05, 0.035, 0.04), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.07, 0.08)), top)
	_sockets("dr", head.y + 0.025, head.z + 0.088, 0.04, 0.024, Color(0.4, 1.0, 0.8), 0.016)
	_part("dr_weed", weed, func() -> ArrayMesh:
		# Weed hanging off the scalp and draped over the shoulders.
		var parts := []
		for i in 9:
			var a := i * TAU / 9.0
			var at := head + Vector3(cos(a) * 0.08, 0.07, sin(a) * 0.07 - 0.02)
			var drop := 0.25 + 0.12 * absf(sin(i * 2.7))
			parts.append(_tube([at, at + Vector3(cos(a) * 0.05, -drop * 0.5, sin(a) * 0.03 - 0.02), at + Vector3(cos(a) * 0.07, -drop, sin(a) * 0.02 - 0.05)], [0.012, 0.01, 0.003], 4))
		for s: float in [1.0, -1.0]:
			for i in 3:
				var at := Vector3(s * (0.15 + i * 0.07), 1.3 - i * 0.03, -0.02 + i * 0.03)
				parts.append(_tube([at, at + Vector3(s * 0.03, -0.18, 0.02), at + Vector3(s * 0.02, -0.36, -0.01)], [0.014, 0.01, 0.003], 4))
		return Shape.merge(parts), top)
	_part("dr_barnacles", shell, func() -> ArrayMesh:
		var parts := []
		for i in 7:
			var at := Vector3(sin(i * 2.1) * 0.15, 1.05 + sin(i * 1.3) * 0.15, -0.18 - absf(cos(i * 2.1)) * 0.03)
			parts.append(_tube([at, at + Vector3(0, 0, -0.025)], [0.022, 0.014], 5))
		return Shape.merge(parts), top)
	_part("dr_shirt", cloth, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.24, 0.7), Vector2(0.24, 0.86), Vector2(0.255, 1.0), Vector2(0.27, 1.14)]), 16, 5, 0.25)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			var a := atan2(p.z, p.x)
			if p.y < 0.86:
				p.y += 0.08 * absf(sin(a * 3.5 + 1.0)) + 0.05 * absf(sin(a * 9.0))
			p.z = p.z * 0.9 + 0.03 + maxf(0.0, p.z) * 0.15 * exp(-pow((p.y - 0.95) / 0.1, 2.0))
			return p), top)
	_sides("dr_arm", skin, func(s: float) -> ArrayMesh:
		# Arms dangling forward, the hands heavy and swollen.
		var sh := Vector3(s * 0.27, 1.24, 0.1)
		var el := Vector3(s * 0.33, 0.98, 0.2)
		var w := Vector3(s * 0.3, 0.78, 0.36)
		var parts := [_tube([sh, el, w], [0.07, 0.055, 0.045], 8)]
		parts.append(Shape.warp(Shape.blob(Vector3(0.045, 0.06, 0.04), 0.06, 3.0 + s, 6, 10), func(p: Vector3) -> Vector3: return p + w + Vector3(0, -0.06, 0.03)))
		for f in 4:
			var a := w + Vector3(s * (f - 1.5) * 0.02, -0.1, 0.05)
			parts.append(_tube([a, a + Vector3(0, -0.05, 0.02), a + Vector3(0, -0.08, -0.01)], [0.014, 0.012, 0.009], 4))
		return Shape.merge(parts), top)
	_sides("dr_leg", skin, func(s: float) -> ArrayMesh:
		var parts := [_tube([Vector3(s * 0.12, 0.8, -0.02), Vector3(s * 0.15, 0.45, 0.08), Vector3(s * 0.14, 0.08, -0.02)], [0.085, 0.065, 0.05], 8)]
		parts.append(_tube([Vector3(s * 0.14, 0.06, -0.06), Vector3(s * 0.145, 0.04, 0.06), Vector3(s * 0.15, 0.03, 0.13)], [0.05, 0.045, 0.035], 8))
		return Shape.merge(parts), top)
	_part("dr_chain", iron, func() -> ArrayMesh:
		var w := Vector3(0.3, 0.8, 0.34)
		var parts := [_band(w, Vector3(0.0, 0.6, 0.5), 0.055, 0.016, 10)]
		for i in 5:
			var at := w + Vector3(0.03, -0.07 - i * 0.055, -0.03 - i * 0.03)
			parts.append(_band(at, Vector3(1, 0, 0) if i % 2 == 0 else Vector3(0, 0, 1), 0.026, 0.008, 8))
		return Shape.merge(parts), top)
	if kind == "drowned_king":
		_part("dr_crown", iron, func() -> ArrayMesh:
			# A drowned king's crown, crusted and bent.
			var c := head + Vector3(0, 0.08, -0.01)
			var parts := [_tube(_circle(c, 0.09, 12), _same(0.014, 12), 5)]
			for i in 6:
				var a := i * TAU / 6.0 + 0.3
				var at := c + Vector3(cos(a) * 0.09, 0, sin(a) * 0.09)
				parts.append(_spike(at, at + Vector3(cos(a) * 0.015, 0.08 + 0.02 * sin(i * 3.0), sin(a) * 0.015), 0.016))
			return Shape.merge(parts), top)


## Demon: a hulking hell-beast. Scorched black-red hide split by glowing
## cracks over a furnace of a chest, a long skull crowned with heavy horns
## curling forward, a ridge of spines down its back, long arms with hooked
## talons, goat legs on cloven hooves, a barbed tail and great torn wings
## folded half open behind it.
func _demon() -> void:
	var hide := Shape.material(Color(0.32, 0.09, 0.06), Color(0.13, 0.04, 0.03), 4.0, 0.5, 0.6, 0.0, 101)
	var horn := Shape.material(Color(0.2, 0.16, 0.13), Color(0.07, 0.05, 0.04), 8.0, 0.35, 0.7, 0.0, 47)
	var wing := Shape.material(Color(0.2, 0.06, 0.05), Color(0.09, 0.03, 0.02), 3.0, 0.7, 0.4, 0.0, 43)
	var top := 2.3
	var head := Vector3(0, 1.9, 0.38)
	_part("de_torso", hide, func() -> ArrayMesh:
		# A deep, broad chest over a narrow waist: separate masses of chest,
		# belly and hips, so the forms overlap like muscle does.
		var chest := Shape.warp(Shape.blob(Vector3(0.36, 0.27, 0.26), 0.03, 7.0, 12, 16), func(p: Vector3) -> Vector3:
			var ax := absf(p.x)
			if p.z > 0.0:
				# Slabs of pectoral muscle and a groove between them.
				p.z += 0.05 * exp(-pow((ax - 0.15) / 0.1, 2.0)) * smoothstep(-0.1, 0.05, p.y)
				p.z -= 0.025 * exp(-pow(ax / 0.04, 2.0))
			else:
				p.z -= 0.03 * exp(-pow(ax / 0.05, 2.0)) - 0.03
			p.y -= ax * 0.15
			return p + Vector3(0, 1.55, 0.06))
		var belly := _tube([Vector3(0, 1.02, -0.04), Vector3(0, 1.18, 0.0), Vector3(0, 1.36, 0.04)], [0.17, 0.16, 0.2], 12)
		belly = Shape.warp(belly, func(p: Vector3) -> Vector3:
			# Ridged stomach muscle.
			if p.z > 0.05:
				p.z += 0.012 * sin(p.y * 50.0) * exp(-pow(p.x / 0.08, 2.0))
			return p)
		var hips := Shape.warp(Shape.blob(Vector3(0.21, 0.12, 0.15), 0.03, 3.0, 8, 12), func(p: Vector3) -> Vector3: return p + Vector3(0, 1.0, -0.05))
		return Shape.merge([chest, belly, hips]), top)
	_part("de_spines", horn, func() -> ArrayMesh:
		var parts := []
		for i in 7:
			var t := float(i) / 6.0
			var at := Vector3(0, lerpf(1.75, 1.05, t), lerpf(-0.12, -0.24, t) - sin(t * PI) * 0.1)
			parts.append(_spike(at, at + Vector3(0, 0.08 - t * 0.06, -0.14 + t * 0.04), 0.03 - t * 0.012))
		return Shape.merge(parts), top)
	_part("de_head", hide, func() -> ArrayMesh:
		var h := Shape.warp(Shape.blob(Vector3(0.14, 0.13, 0.17), 0.05, 4.0, 10, 14), func(p: Vector3) -> Vector3:
			# A long, heavy-jawed skull with a ridged brow.
			if p.y < 0.0:
				p.x *= 1.0 + p.y * 1.5
				p.z += -p.y * 0.5
			if p.y > 0.02 and p.z > 0.06:
				p.y += 0.02
			return p + head)
		var brow := _tube(Array(Shape.curve(head + Vector3(-0.1, 0.04, 0.09), head + Vector3(0, 0.03, 0.17), head + Vector3(0.1, 0.04, 0.09), 5)), [0.025, 0.03, 0.025, 0.03, 0.025], 6)
		var neck := _tube([Vector3(0, 1.66, 0.12), head + Vector3(0, -0.05, -0.08)], [0.14, 0.1], 10)
		return Shape.merge([h, brow, neck]), top)
	_part("de_mouth", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.06, 0.025, 0.04), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.08, 0.15)), top)
	_part("de_fangs", horn, func() -> ArrayMesh:
		var parts := []
		for s: float in [1.0, -1.0]:
			for i in 2:
				var at := head + Vector3(s * (0.035 + i * 0.02), -0.06, 0.18 - i * 0.02)
				parts.append(_spike(at, at + Vector3(0, -0.05 + i * 0.015, 0.005), 0.009))
		return Shape.merge(parts), top)
	# An ember deep in its throat.
	Art.part(_model, Art.sphere(0.025, 6), Fx.glow(El.COLOR[El.FIRE], 3.0), head + Vector3(0, -0.075, 0.14))
	_sides("de_horn", horn, func(s: float) -> ArrayMesh:
		# Ram-thick at the root, sweeping back and out, then hooking forward.
		var a := head + Vector3(s * 0.07, 0.08, 0.02)
		var pts := [a, a + Vector3(s * 0.12, 0.12, -0.08), a + Vector3(s * 0.26, 0.16, -0.06), a + Vector3(s * 0.32, 0.26, 0.06), a + Vector3(s * 0.3, 0.38, 0.16)]
		return _tube(pts, [0.05, 0.045, 0.035, 0.022, 0.003], 7), top)
	_sides("de_arm", hide, func(s: float) -> ArrayMesh:
		var sh := Vector3(s * 0.46, 1.66, 0.04)
		var el := Vector3(s * 0.6, 1.32, -0.03)
		var w := Vector3(s * 0.56, 1.04, 0.3)
		# Lean and corded rather than round: the deltoid capping the
		# shoulder, a bicep that swells and thins to the elbow, a forearm
		# thick below the elbow and narrow at the wrist.
		var parts := [Shape.warp(Shape.blob(Vector3(0.12, 0.1, 0.12), 0.06, 2.0 + s, 8, 12), func(p: Vector3) -> Vector3: return p + sh + Vector3(-s * 0.04, 0.02, 0))]
		# One unbroken limb so the elbow does not read as a joint of a doll.
		var path := [sh, sh.lerp(el, 0.4) + Vector3(0, 0, 0.03), el + Vector3(0, 0.03, -0.02), el.lerp(w, 0.3) + Vector3(s * 0.015, 0, 0), el.lerp(w, 0.75), w]
		parts.append(_tube(path, [0.085, 0.095, 0.06, 0.075, 0.05, 0.035], 10))
		# A narrow, long-boned hand rather than a fist.
		parts.append(Shape.warp(Shape.blob(Vector3(0.045, 0.06, 0.035), 0.04, 5.0, 6, 10), func(p: Vector3) -> Vector3: return p + w + Vector3(0, -0.06, 0.03)))
		for f in 4:
			var o := (f - 1.5) * 0.03
			var a := w + Vector3(s * o, -0.1, 0.06)
			parts.append(Shape.tint(_claw(a, a + Vector3(s * o * 0.5, -0.04, 0.08), a + Vector3(s * o, -0.12, 0.06), 0.016), NAIL))
		return Shape.merge(parts), top)
	_sides("de_leg", hide, func(s: float) -> ArrayMesh:
		# Goat legs: a thick thigh forward to the knee, the shin raking back
		# to a high hock, a long bone down to a cloven hoof.
		var hip := Vector3(s * 0.16, 1.0, -0.04)
		var knee := Vector3(s * 0.23, 0.66, 0.2)
		var hock := Vector3(s * 0.23, 0.3, -0.1)
		var hoof := Vector3(s * 0.22, 0.06, 0.02)
		var parts := [_tube([hip, hip.lerp(knee, 0.45) + Vector3(0, 0, 0.04), knee, knee.lerp(hock, 0.4) + Vector3(0, 0, -0.01), hock, hoof], [0.14, 0.12, 0.07, 0.065, 0.042, 0.036], 10)]
		parts.append(Shape.tint(Shape.warp(Shape.blob(Vector3(0.06, 0.05, 0.08), 0.03, 3.0, 6, 10), func(p: Vector3) -> Vector3:
			p.y = maxf(p.y, -0.035)
			return p + hoof + Vector3(0, -0.015, 0.03)), Color(0.35, 0.3, 0.3)))
		return Shape.merge(parts), top)
	_part("de_tail", hide, func() -> ArrayMesh:
		var pts := [Vector3(0, 1.02, -0.18), Vector3(0, 0.7, -0.45), Vector3(0.15, 0.35, -0.65), Vector3(0.4, 0.2, -0.7), Vector3(0.55, 0.3, -0.62)]
		var t := _tube(pts, [0.07, 0.05, 0.035, 0.025, 0.015], 7)
		return Shape.merge([t, Shape.tint(_claw(pts[4], pts[4] + Vector3(0.06, 0.08, 0.02), pts[4] + Vector3(0.04, 0.18, 0.06), 0.035), NAIL)]), top)
	_sides("de_wing", wing, func(s: float) -> ArrayMesh:
		# A great bat wing, half spread, torn between its fingers.
		var root := Vector3(s * 0.18, 1.66, -0.2)
		var joint := Vector3(s * 0.62, 2.15, -0.5)
		var tips := [Vector3(s * 1.22, 2.3, -0.6), Vector3(s * 1.15, 1.75, -0.72), Vector3(s * 0.95, 1.25, -0.7), Vector3(s * 0.62, 1.0, -0.55)]
		var parts := [_tube([root, root.lerp(joint, 0.5) + Vector3(0, 0.05, 0), joint], [0.05, 0.04, 0.03], 7)]
		var edge := tips + [root + Vector3(0, -0.36, 0.02)]
		for i in tips.size():
			parts.append(_tube([joint, tips[i]], [0.022, 0.006], 5))
		parts.append(Shape.tint(_claw(joint, joint + Vector3(s * 0.02, 0.08, 0.02), joint + Vector3(s * 0.0, 0.14, 0.08), 0.025), NAIL))
		for i in edge.size() - 1:
			var a: Vector3 = edge[i]
			var b: Vector3 = edge[i + 1]
			var dip := ((a + b) * 0.5).lerp(joint, 0.28)
			parts.append(Shape.sheet(PackedVector3Array([joint, a, dip, b])))
		return Shape.merge(parts), top)


## Watcher: a great bloodshot eye hanging in the air, wrapped in a hood of
## raw, wrinkled flesh that pulls back from the front like lids, feelers
## trailing and curling under it. Its iris glows when it is about to stare
## out a fan of void.
func _watcher() -> void:
	var white := Shape.material(Color(0.8, 0.74, 0.66), Color(0.55, 0.2, 0.16), 3.0, 0.25, 0.3, 0.0, 107)
	var flesh := Shape.material(Color(0.4, 0.2, 0.22), Color(0.2, 0.08, 0.1), 4.0, 0.45, 0.8, 0.0, 109)
	var top := 1.9
	var c := Vector3(0, 1.45, 0)
	# It looks down and ahead, so the iris shows from the camera above.
	var look := Basis(Vector3.RIGHT, 0.45)
	_part("wa_ball", white, func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.4, 0.4, 0.4), 0.01, 1.0, 12, 18), func(p: Vector3) -> Vector3: return p + c), top)
	_part("wa_lids", flesh, func() -> ArrayMesh:
		# Turned on its side so the opening looks forward: wrinkled flesh
		# round the back of the eye, the lids drawn back into an almond.
		var l := Shape.lathe(PackedVector2Array([Vector2(0.02, -0.47), Vector2(0.28, -0.4), Vector2(0.44, -0.2), Vector2(0.47, 0.0), Vector2(0.44, 0.13), Vector2(0.41, 0.2), Vector2(0.38, 0.24)]), 22, 9, 0.06)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			var q := Vector3(p.x, -p.z, p.y)
			# Squeeze the opening into a slit wider than it is tall.
			var front := smoothstep(0.0, 0.24, q.z)
			q.y *= lerpf(1.0, 0.72, front)
			q.x *= lerpf(1.0, 1.06, front)
			return c + look * q), top)
	_part("wa_veins", flesh, func() -> ArrayMesh:
		# Swollen veins creeping over the white from the lids.
		var parts := []
		for i in 7:
			var a := i * TAU / 7.0 + 0.2
			var d := Vector3(cos(a) * 0.62, sin(a) * 0.4, 0.68).normalized()
			var e := Vector3(cos(a) * 0.35, sin(a) * 0.22, 0.91).normalized()
			parts.append(_tube([c + look * (d * 0.405), c + look * (d.lerp(e, 0.5).normalized() * 0.405), c + look * (e * 0.4)], [0.012, 0.008, 0.002], 4))
		return Shape.merge(parts), top)
	var ie := _shared("wa_iris", func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.15, 0.15, 0.04), 0.0, 1.0, 6, 16), func(p: Vector3) -> Vector3: return c + look * (p + Vector3(0, 0, 0.375))), top)
	var iris := Art.part(_model, ie[0], Fx.glow(El.COLOR[El.VOID], 2.5), ie[1])
	_eyes.append(iris)
	_part("wa_pupil", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.045, 0.1, 0.03), 0.0, 1.0, 6, 10), func(p: Vector3) -> Vector3: return c + look * (p + Vector3(0, 0, 0.405))), top)
	_part("wa_feelers", flesh, func() -> ArrayMesh:
		var parts := []
		for i in 6:
			var a := i * TAU / 6.0 + 0.3
			var o := Vector3(cos(a), 0, sin(a))
			var at := c + o * 0.18 + Vector3(0, -0.36, -0.06)
			var curl := o.cross(Vector3.UP) * 0.12 * (1.0 if i % 2 == 0 else -1.0)
			var pts := [at, at + o * 0.08 + Vector3(0, -0.22, 0), at + o * 0.12 + curl + Vector3(0, -0.48, 0), at + o * 0.05 + curl * 1.6 + Vector3(0, -0.66, 0), at + curl * 1.2 + Vector3(0, -0.76, 0)]
			parts.append(_tube(pts, [0.05, 0.035, 0.025, 0.015, 0.004], 6))
		return Shape.merge(parts), top)
	_model.add_child(Fx.halo(El.COLOR[El.VOID], 1.2, 0.5, 1.0))
	_model.get_child(-1).position = c + look * Vector3(0, 0, 0.3)


## Bile Horror: a bloated mountain of sick, bruised flesh on stumpy legs.
## Its gut sags in rolls almost to its knees, swollen fit to burst and sewn
## shut with black stitches; the shoulders hunch up round a small head sunk
## into the fat, clusters of boils weep over its back, short thick arms end
## in fat grasping hands. The Bloated Abbot wears what is left of a monk's
## cowl and rope over the same body.
func _bile() -> void:
	var abbot := kind == "abbot"
	var k := "ab" if abbot else "bi"
	var flesh := Shape.material(Color(0.44, 0.44, 0.32), Color(0.27, 0.22, 0.23), 4.0, 0.5, 0.8, 0.0, 113)
	var boil := Shape.material(Color(0.6, 0.55, 0.3), Color(0.38, 0.24, 0.22), 8.0, 0.25, 0.4, 0.0, 117)
	var thread := Shape.flat(Color(0.06, 0.05, 0.04), 0.8)
	var robe := Shape.material(Color(0.26, 0.21, 0.16), Color(0.14, 0.11, 0.09), 3.0, 0.95, 0.6, 0.0, 127)
	var top := 1.9
	var head := Vector3(0, 1.36, 0.47)
	var body := func(p: Vector3) -> Vector3:
		# Pear-shaped and sagging: heaviest low and in front, the belly
		# hanging in a lip over the groin, rolls of fat round the flanks.
		if p.y < 0.0:
			p.x *= 1.0 + -p.y * 0.3
			p.z *= 1.0 + -p.y * 0.2
			p.z += -p.y * 0.22
		else:
			p.x *= 1.0 - p.y * 0.25
		var roll := sin(p.y * 22.0) * 0.022 * smoothstep(0.1, 0.4, Vector2(p.x, p.z).length())
		p.x += signf(p.x) * roll
		p.z += signf(p.z) * roll * 0.5
		# The crease under the hanging belly.
		if p.z > 0.0:
			p.z -= 0.07 * exp(-pow((p.y + 0.36) / 0.06, 2.0))
		return p + Vector3(0, 0.95, 0.02)
	# Bruising: purple-grey blotches over the skin and darker veins of it
	# in the folds, so it looks diseased rather than soft.
	var bruise := func(p: Vector3, _n: Vector3) -> Color:
		var b := sin(p.x * 9.0 + p.y * 4.0) * sin(p.y * 7.0 - p.z * 6.0) * sin(p.z * 8.0 + p.x * 3.0)
		var k2 := smoothstep(0.05, 0.4, b)
		return Color(1, 1, 1).lerp(Color(0.62, 0.5, 0.6), k2)
	_part(k + "_gut", flesh, func() -> ArrayMesh:
		return Shape.shade(Shape.warp(Shape.blob(Vector3(0.6, 0.6, 0.55), 0.04, 2.0, 14, 18), body), bruise), top)
	_part(k + "_shoulders", flesh, func() -> ArrayMesh:
		# Hunched up round the head, a hump of fat behind it.
		var b := Shape.blob(Vector3(0.52, 0.3, 0.4), 0.07, 5.0, 10, 14)
		return Shape.shade(Shape.warp(b, func(p: Vector3) -> Vector3:
			p.y += absf(p.x) * 0.3 - maxf(0.0, p.z) * 0.35
			return p + Vector3(0, 1.36, -0.02)), bruise), top)
	_part(k + "_stitches", thread, func() -> ArrayMesh:
		# A long seam sewn down the belly, the cross-stitches pulled tight.
		var seam := []
		for i in 10:
			var t := float(i) / 9.0
			# Points on the body's surface, a little out.
			var d := Vector3(sin(t * 5.0) * 0.05, lerpf(0.6, -0.75, t), 1.0).normalized()
			seam.append(body.call(Vector3(d.x * 0.61, d.y * 0.61, d.z * 0.56)))
		var parts := [_tube(seam, _same(0.007, seam.size() - 1), 4)]
		for i in range(1, seam.size() - 1):
			var at: Vector3 = seam[i]
			parts.append(_tube([at + Vector3(-0.045, 0.01, -0.014), at + Vector3(0, 0, 0.003), at + Vector3(0.045, -0.01, -0.014)], [0.006, 0.006, 0.006], 3))
		return Shape.merge(parts), top)
	_part(k + "_boils", boil, func() -> ArrayMesh:
		# Scattered over the back and shoulders, a few on the flanks.
		var parts := []
		for i in 16:
			# Spread evenly over the back half (golden angle), jittered.
			var t := (i + 0.5) / 16.0
			var a := i * 2.39996
			var d := Vector3(cos(a) * sqrt(1.0 - t * t), t * 0.9 - 0.15, -absf(sin(a)) * sqrt(1.0 - t * t) - 0.2).normalized()
			var at: Vector3 = body.call(Vector3(d.x * 0.6, d.y * 0.6, d.z * 0.55))
			var r := 0.022 + 0.03 * absf(sin(i * 3.3))
			parts.append(Shape.warp(Shape.blob(Vector3(r, r * 0.7, r), 0.1, i, 4, 7), func(p: Vector3) -> Vector3: return p + at))
		return Shape.merge(parts), top)
	_part(k + "_head", flesh, func() -> ArrayMesh:
		var h := Shape.warp(Shape.blob(Vector3(0.13, 0.12, 0.11), 0.06, 3.0, 9, 14), func(p: Vector3) -> Vector3:
			# Jowls and chins sagging down into the chest, a fat brow
			# hooding the eyes.
			if p.y < 0.0:
				p.x *= 1.0 + -p.y * 4.0
				p.z += -p.y * 0.5
			if p.y > 0.02 and p.z > 0.04:
				p.z += 0.015
			return p + head)
		return h, top)
	_part(k + "_mouth", _hollow(), func() -> ArrayMesh:
		# Hanging slack open, wider than the face, drooling.
		var maw := Shape.warp(Shape.blob(Vector3(0.075, 0.04, 0.04), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3:
			p.y -= p.x * p.x * 3.0
			return p + head + Vector3(0, -0.08, 0.11))
		var drool := _tube([head + Vector3(0.03, -0.11, 0.135), head + Vector3(0.035, -0.17, 0.15), head + Vector3(0.03, -0.24, 0.16)], [0.01, 0.007, 0.004], 4)
		return Shape.merge([maw, drool]), top)
	_part(k + "_teeth", boil, func() -> ArrayMesh:
		# A few stumps of yellow teeth in the gums.
		var parts := []
		for i in 5:
			var x := (i - 2.0) * 0.028 + 0.004 * sin(i * 5.0)
			var at := head + Vector3(x, -0.05 - x * x * 3.0, 0.135 - absf(x) * 0.3)
			parts.append(_spike(at, at + Vector3(0, -0.025 - 0.01 * absf(sin(i * 3.0)), 0.004), 0.009))
		return Shape.merge(parts), top)
	_sockets(k, head.y + 0.03, head.z + 0.1, 0.05, 0.02, Color(0.85, 0.8, 0.25), 0.012)
	_sides(k + "_arm", flesh, func(s: float) -> ArrayMesh:
		var sh := Vector3(s * 0.5, 1.32, 0.08)
		var w := Vector3(s * 0.66, 0.86, 0.42)
		var parts := [_tube([sh, Vector3(s * 0.68, 1.1, 0.22), w], [0.15, 0.12, 0.08], 10)]
		parts.append(Shape.warp(Shape.blob(Vector3(0.07, 0.08, 0.06), 0.06, 3.0 + s, 6, 10), func(p: Vector3) -> Vector3: return p + w + Vector3(0, -0.07, 0.04)))
		for f in 4:
			var a := w + Vector3(s * (f - 1.5) * 0.03, -0.12, 0.06)
			parts.append(_tube([a, a + Vector3(0, -0.06, 0.03), a + Vector3(0, -0.1, 0.0)], [0.022, 0.02, 0.015], 5))
		return Shape.merge(parts), top)
	_sides(k + "_leg", flesh, func(s: float) -> ArrayMesh:
		var parts := [_tube([Vector3(s * 0.26, 0.5, 0.0), Vector3(s * 0.3, 0.3, 0.04), Vector3(s * 0.3, 0.1, 0.03)], [0.17, 0.15, 0.13], 10)]
		parts.append(Shape.warp(Shape.blob(Vector3(0.14, 0.07, 0.18), 0.05, 2.0 + s, 7, 10), func(p: Vector3) -> Vector3:
			p.y = maxf(p.y, -0.05)
			return p + Vector3(s * 0.3, 0.06, 0.08)))
		return Shape.merge(parts), top)
	if abbot:
		_part("ab_cowl", robe, func() -> ArrayMesh:
			# A monk's cowl pulled up round the head, open at the face, its
			# hem lying over the hunched shoulders.
			var l := Shape.lathe(PackedVector2Array([Vector2(0.3, -0.16), Vector2(0.21, -0.06), Vector2(0.18, 0.04), Vector2(0.16, 0.13), Vector2(0.1, 0.21), Vector2(0.0, 0.24)]), 16, 6, 0.1, 1.5)
			return Shape.warp(l, func(p: Vector3) -> Vector3:
				var a := atan2(p.z, p.x)
				if p.y < -0.1:
					p.y += 0.03 * absf(sin(a * 4.0))
				p.z -= maxf(0.0, p.y - 0.08) * 0.5
				return p + head + Vector3(0, 0.02, -0.03)), top)
		_part("ab_rope", robe, func() -> ArrayMesh:
			var ring := []
			for q: Vector3 in _circle(Vector3.ZERO, 1.0, 18):
				ring.append(body.call(Vector3(q.x * cos(0.45) * 0.6, -sin(0.45) * 0.6, q.z * cos(0.45) * 0.55) * 1.03))
			var end := _tube([ring[4], ring[4] + Vector3(0.02, -0.2, 0.03), ring[4] + Vector3(0.03, -0.38, 0.0)], [0.022, 0.02, 0.016], 5)
			return Shape.merge([_tube(ring, _same(0.025, 18), 5), end]), top)


## Necromancer: tall, gaunt, hooded in robes of rotten green and black that
## pool on the floor, a mantle of bones over the shoulders (a ribcage worn
## as a breastplate, skulls on the shoulders), a grey withered hand held
## out, the other on a staff of knotted bone with a skull on top and a
## green witch-light in it. Green eyes in the dark of the hood.
func _necromancer() -> void:
	var robe := Shape.material(Color(0.13, 0.17, 0.12), Color(0.06, 0.08, 0.06), 4.0, 0.92, 0.6, 0.0, 131)
	var black := Shape.material(Color(0.08, 0.08, 0.08), Color(0.03, 0.03, 0.03), 3.0, 0.95, 0.6, 0.0, 137)
	var bone := Shape.material(Color(0.7, 0.66, 0.56), Color(0.45, 0.4, 0.3), 5.0, 0.6, 0.6, 0.0, 11)
	var flesh := Shape.material(Color(0.45, 0.46, 0.42), Color(0.28, 0.3, 0.27), 6.0, 0.6, 0.5, 0.0, 139)
	var green := Color(0.45, 1.0, 0.5)
	var top := 2.0
	_part("ne_robe", robe, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.36, 0.0), Vector2(0.3, 0.12), Vector2(0.22, 0.5), Vector2(0.17, 0.95), Vector2(0.16, 1.2), Vector2(0.19, 1.42), Vector2(0.15, 1.58), Vector2(0.07, 1.64)]), 22, 8, 0.14)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			var a := atan2(p.z, p.x)
			# Pooling on the floor in a ragged train behind.
			if p.y < 0.12:
				p.z -= maxf(0.0, -sin(a)) * 0.18 * (0.12 - p.y) / 0.12
				p.y = maxf(0.0, p.y + 0.03 * absf(sin(a * 6.0)) - 0.02)
			p.z = p.z * 0.85 - 0.02
			return p), top)
	_part("ne_tabard", black, func() -> ArrayMesh:
		# A long black panel down the front and the back, torn at the end.
		var parts := []
		for side: float in [1.0, -1.0]:
			var pts := [Vector3(0, 1.3, 0), Vector3(-0.1, 1.3, 0)]
			for i in 7:
				var u := float(i) / 6.0
				pts.append(Vector3(lerpf(-0.11, 0.11, u), 0.3 + 0.08 * absf(sin(u * 9.0 + side * 2.0)), 0))
			pts.append(Vector3(0.1, 1.3, 0))
			parts.append(Shape.warp(Shape.sheet(PackedVector3Array(pts)), func(p: Vector3) -> Vector3:
				var r := 0.165 + (1.3 - p.y) * 0.06 + 0.02
				p.z = side * (r * 0.85 - p.x * p.x * 3.0) - 0.02
				return p))
		return Shape.merge(parts), top)
	var hood_at := Vector3(0, 1.66, 0.05)
	_part("ne_hood", robe, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.24, -0.16), Vector2(0.16, -0.05), Vector2(0.15, 0.06), Vector2(0.13, 0.17), Vector2(0.08, 0.26), Vector2(0.03, 0.34), Vector2(0.0, 0.36)]), 16, 4, 0.08, 1.4)
		return Shape.warp(l, func(p: Vector3) -> Vector3:
			p.z -= maxf(0.0, p.y - 0.15) * 0.9
			p.z += 0.03
			return p + hood_at), top)
	_part("ne_shadow", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.1, 0.12, 0.08), 0.0, 1.0, 6, 10), func(p: Vector3) -> Vector3: return p + hood_at + Vector3(0, 0.03, 0.03)), top)
	_eye_pair(hood_at.y + 0.04, hood_at.z + 0.11, 0.035, green, 0.016)
	_part("ne_bones", bone, func() -> ArrayMesh:
		# A ribcage worn over the chest and a skull on each shoulder.
		var parts := []
		for i in 4:
			var y := 1.45 - i * 0.06
			for s: float in [1.0, -1.0]:
				var a := Vector3(s * 0.02, y, 0.2)
				parts.append(Shape.limb(Shape.curve(a, Vector3(s * 0.15, y - 0.02, 0.17), Vector3(s * 0.2, y - 0.05, 0.03), 5), PackedFloat32Array([0.012, 0.012, 0.011, 0.01, 0.009]), 4, 1))
		parts.append(_tube([Vector3(0, 1.48, 0.2), Vector3(0, 1.25, 0.2)], [0.016, 0.012], 5))
		for s: float in [1.0, -1.0]:
			var sk := Vector3(s * 0.2, 1.53, 0.0)
			parts.append(Shape.warp(Shape.blob(Vector3(0.065, 0.07, 0.075), 0.02, 3.0, 8, 10), func(p: Vector3) -> Vector3:
				if p.y < 0.0:
					p.x *= 1.0 + p.y * 3.0
				return Basis(Vector3.UP, s * 0.6) * p + sk))
		return Shape.merge(parts), top)
	_part("ne_skullpits", _hollow(), func() -> ArrayMesh:
		var parts := []
		for s: float in [1.0, -1.0]:
			var sk := Vector3(s * 0.2, 1.53, 0.0)
			var fwd := Basis(Vector3.UP, s * 0.6) * Vector3(0, 0, 1)
			for e: float in [1.0, -1.0]:
				var side := fwd.cross(Vector3.UP)
				var at := sk + fwd * 0.062 + side * e * 0.025 + Vector3(0, 0.005, 0)
				parts.append(Shape.warp(Shape.blob(Vector3(0.017, 0.015, 0.012), 0.0, 1.0, 4, 6), func(p: Vector3) -> Vector3: return p + at))
		return Shape.merge(parts), top)
	_sides("ne_sleeve", robe, func(s: float) -> ArrayMesh:
		# The right (-x) hand on the staff, the left held out, fingers spread.
		var sh := Vector3(s * 0.19, 1.48, 0.0)
		var el := Vector3(-0.3, 1.2, 0.06) if s < 0.0 else Vector3(0.28, 1.25, 0.16)
		var wr := Vector3(-0.38, 1.13, 0.14) if s < 0.0 else Vector3(0.3, 1.24, 0.4)
		return _tube([sh, el, wr], [0.06, 0.065, 0.09], 10), top)
	_sides("ne_hand", flesh, func(s: float) -> ArrayMesh:
		var wr := Vector3(-0.4, 1.11, 0.17) if s < 0.0 else Vector3(0.3, 1.24, 0.44)
		var parts := [Shape.warp(Shape.blob(Vector3(0.03, 0.035, 0.025), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + wr)]
		for f in 4:
			var spread := (f - 1.5) * 0.35
			var a := wr + Vector3((f - 1.5) * 0.014, 0.0, 0.02)
			var dir := (Vector3(0, 0, 1).rotated(Vector3.UP, spread * s) if s > 0.0 else Vector3(-1, 0, 0.3).normalized())
			parts.append(_tube([a, a + dir * 0.05 + Vector3(0, 0.0, 0), a + dir * 0.09 + Vector3(0, -0.02, 0)], [0.009, 0.008, 0.005], 4))
		return Shape.merge(parts), top)
	var st := Vector3(-0.42, 0.0, 0.17)
	_part("ne_staff", bone, func() -> ArrayMesh:
		# A staff of bone: knuckled like a spine, a skull at the top.
		var pts := []
		var r := []
		for i in 15:
			var t := float(i) / 14.0
			pts.append(st + Vector3(sin(t * 6.0) * 0.01, 0.05 + t * 1.9, 0))
			r.append(0.022 if i % 2 == 0 else 0.016)
		var skull := Shape.warp(Shape.blob(Vector3(0.07, 0.075, 0.08), 0.02, 3.0, 8, 12), func(p: Vector3) -> Vector3:
			if p.y < 0.0:
				p.x *= 1.0 + p.y * 3.0
			return p + st + Vector3(0, 2.02, 0.01))
		return Shape.merge([_tube(pts, r, 5), skull]), top)
	Art.part(_model, Art.sphere(0.022, 6), Fx.glow(green, 5.0), st + Vector3(-0.025, 2.03, 0.07))
	Art.part(_model, Art.sphere(0.022, 6), Fx.glow(green, 5.0), st + Vector3(0.025, 2.03, 0.07))
	var motes := Fx.particles(Color(0.45, 1.0, 0.5, 0.6), 14, 1.2, 0.1)
	motes.position = st + Vector3(0, 2.02, 0)
	motes.direction = Vector3.UP
	motes.initial_velocity_max = 0.4
	motes.gravity = Vector3.UP * 0.4
	_model.add_child(motes)
	motes.emitting = true


## Bog Toad: a huge, squat swamp toad, broad as a barrel. Warty mud-brown
## back with darker blotches, a pale, sagging throat, a wide lipless mouth,
## eyes bulging up out of the top of the head, front legs splayed and the
## great hind legs folded under it, ready to heave.
func _toad() -> void:
	var skin := Shape.material(Color(0.33, 0.33, 0.18), Color(0.17, 0.17, 0.09), 4.0, 0.35, 0.8, 0.0, 149)
	var belly := Shape.material(Color(0.58, 0.55, 0.38), Color(0.42, 0.38, 0.26), 4.0, 0.4, 0.5, 0.0, 151)
	var top := 1.0
	_part("to_body", skin, func() -> ArrayMesh:
		var b := Shape.blob(Vector3(0.58, 0.36, 0.6), 0.04, 2.0, 12, 18)
		var body := Shape.warp(b, func(p: Vector3) -> Vector3:
			# Flat underneath, a hump at the back, the head end wide and low.
			p.y = maxf(p.y, -0.22)
			p.y += 0.08 * exp(-pow((p.z + 0.15) / 0.3, 2.0)) * smoothstep(0.0, 0.2, p.y)
			p.x *= 1.0 + 0.12 * smoothstep(0.0, 0.5, p.z)
			return p + Vector3(0, 0.42, -0.02))
		var parts := [body]
		# Warts over the back, darker.
		for i in 18:
			var a := i * 2.39996
			var r := sqrt((i + 0.5) / 18.0)
			var at := Vector3(cos(a) * r * 0.48, 0.0, sin(a) * r * 0.5 - 0.05)
			at.y = 0.42 + 0.36 * sqrt(maxf(0.0, 1.0 - pow(at.x / 0.58, 2.0) - pow((at.z + 0.02) / 0.6, 2.0))) - 0.01
			var w := 0.035 + 0.025 * absf(sin(i * 4.1))
			parts.append(Shape.tint(Shape.warp(Shape.blob(Vector3(w, w * 0.6, w), 0.1, i, 4, 7), func(p: Vector3) -> Vector3: return p + at), Color(0.7, 0.65, 0.55)))
		return Shape.merge(parts), top)
	_part("to_throat", belly, func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.42, 0.18, 0.3), 0.03, 3.0, 8, 14), func(p: Vector3) -> Vector3:
			p.y = maxf(p.y, -0.12)
			return p + Vector3(0, 0.3, 0.3)), top)
	_part("to_lip", _hollow(), func() -> ArrayMesh:
		# The seam of the wide mouth running round the front of the head.
		var pts := []
		for i in 9:
			var a := lerpf(-1.2, 1.2, i / 8.0)
			pts.append(Vector3(sin(a) * 0.5, 0.46 - absf(sin(a)) * 0.04, 0.12 + cos(a) * 0.46))
		return _tube(pts, _same(0.012, 8), 4), top)
	_sides("to_eye", skin, func(s: float) -> ArrayMesh:
		# The bulge the eye sits in, up on top of the head.
		return Shape.warp(Shape.blob(Vector3(0.085, 0.06, 0.09), 0.03, 4.0 + s, 7, 10), func(p: Vector3) -> Vector3: return p + Vector3(s * 0.24, 0.74, 0.3)), top)
	_sockets("to", 0.77, 0.37, 0.24, 0.04, Color(1.0, 0.7, 0.1), 0.02)
	_sides("to_arm", skin, func(s: float) -> ArrayMesh:
		var parts := [_tube([Vector3(s * 0.4, 0.4, 0.3), Vector3(s * 0.5, 0.22, 0.42), Vector3(s * 0.5, 0.04, 0.5)], [0.1, 0.075, 0.055], 8)]
		for f in 4:
			var a := Vector3(s * 0.5, 0.03, 0.5)
			var d := Vector3(s * (f - 1.5) * 0.06, 0, 0.1)
			parts.append(_tube([a, a + d, a + d * 1.4 + Vector3(0, 0.0, 0)], [0.032, 0.026, 0.026], 5))
		return Shape.merge(parts), top)
	_sides("to_haunch", skin, func(s: float) -> ArrayMesh:
		# The folded hind leg: a great thigh along the flank, the shin and
		# the long webbed foot tucked forward under it.
		var thigh := Shape.warp(Shape.blob(Vector3(0.2, 0.17, 0.32), 0.05, 2.0 + s, 8, 12), func(p: Vector3) -> Vector3:
			return Basis(Vector3.UP, s * 0.35) * p + Vector3(s * 0.52, 0.26, -0.22))
		var shin := _tube([Vector3(s * 0.62, 0.12, -0.42), Vector3(s * 0.68, 0.07, -0.1), Vector3(s * 0.66, 0.04, 0.12)], [0.09, 0.075, 0.06], 8)
		var foot := Shape.warp(Shape.blob(Vector3(0.12, 0.025, 0.16), 0.0, 1.0, 5, 10), func(p: Vector3) -> Vector3: return p + Vector3(s * 0.66, 0.025, 0.24))
		return Shape.merge([thigh, shin, foot]), top)


## Shieldbearer: a dead knight in heavy, rusted plate, hunched behind a
## battered tower shield of iron-bound planks. A great helm with a dark
## eye slit and two embers behind it, layered pauldrons, a mail skirt,
## heavy gauntlets and a flanged mace held low beside the shield.
func _shieldbearer() -> void:
	var plate := Shape.material(Color(0.36, 0.35, 0.35), Color(0.3, 0.18, 0.1), 4.0, 0.38, 0.6, 0.75, 157)
	var dark := Shape.material(Color(0.2, 0.19, 0.19), Color(0.16, 0.1, 0.06), 6.0, 0.5, 0.8, 0.6, 163)
	var cloth := Shape.material(Color(0.25, 0.08, 0.07), Color(0.12, 0.04, 0.04), 3.0, 0.95, 0.6, 0.0, 167)
	var wood := Shape.material(Color(0.3, 0.21, 0.13), Color(0.15, 0.1, 0.06), 5.0, 0.85, 0.7, 0.0, 19)
	var top := 1.95
	var head := Vector3(0, 1.66, 0.04)
	_part("sh_body", plate, func() -> ArrayMesh:
		# A barrel of a breastplate with a ridge down the front, the fauld
		# plates below it, a gorget at the neck.
		var chest := Shape.warp(Shape.blob(Vector3(0.28, 0.3, 0.2), 0.0, 1.0, 10, 16), func(p: Vector3) -> Vector3:
			p.z += 0.03 * exp(-pow(p.x / 0.05, 2.0)) * smoothstep(-0.2, 0.0, p.z) * (1.0 if p.z > 0.0 else 0.0)
			p.x *= 1.0 + p.y * 0.4
			return p + Vector3(0, 1.22, 0.0))
		var parts := [chest]
		for i in 3:
			parts.append(_band(Vector3(0, 0.98 - i * 0.07, 0.0), Vector3.UP, 0.22 + i * 0.015, 0.035, 14))
		parts.append(_band(Vector3(0, 1.5, 0.0), Vector3.UP, 0.12, 0.04, 12))
		return Shape.merge(parts), top)
	_part("sh_skirt", dark, func() -> ArrayMesh:
		var l := Shape.lathe(PackedVector2Array([Vector2(0.3, 0.5), Vector2(0.27, 0.68), Vector2(0.24, 0.86), Vector2(0.22, 0.95)]), 16, 6, 0.06)
		return Shape.warp(l, func(p: Vector3) -> Vector3: return Vector3(p.x, p.y, p.z * 0.85)), top)
	_part("sh_tabard", cloth, func() -> ArrayMesh:
		# A rag of a surcoat hanging in front, torn short.
		var pts := [Vector3(0, 1.0, 0.26), Vector3(-0.12, 1.0, 0.26)]
		for i in 6:
			var u := float(i) / 5.0
			pts.append(Vector3(lerpf(-0.12, 0.12, u), 0.45 + 0.07 * absf(sin(u * 8.0)), 0.3))
		pts.append(Vector3(0.12, 1.0, 0.26))
		return Shape.sheet(PackedVector3Array(pts)), top)
	_part("sh_helm", plate, func() -> ArrayMesh:
		# A great helm: flat-topped, a ridge over the eye slit, breaths
		# below it.
		var h := Shape.slab(Vector3(0.14, 0.18, 0.15), 0.7, 8, 14)
		var helm := Shape.warp(h, func(p: Vector3) -> Vector3:
			# Tapering up into a blunt point, the face plate pushed forward
			# into a keel down the middle.
			var up := smoothstep(0.0, 0.18, p.y)
			p.x *= 1.0 - up * 0.35
			p.z *= 1.0 - up * 0.3
			p.z += 0.03 * smoothstep(0.0, 0.15, p.z) * (1.0 - absf(p.x) / 0.14)
			return p + head)
		var keel := _tube([head + Vector3(0, 0.17, 0.08), head + Vector3(0, 0.08, 0.17), head + Vector3(0, 0.02, 0.185)], [0.01, 0.014, 0.012], 5)
		var breaths := []
		for i in 4:
			var y := -0.05 - i * 0.025
			breaths.append(Shape.tint(_tube([head + Vector3(0.03, y, 0.172), head + Vector3(0.09, y, 0.145)], [0.006, 0.006], 3), Color(0.2, 0.2, 0.2)))
		return Shape.merge([helm, keel] + breaths), top)
	_part("sh_slit", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.slab(Vector3(0.11, 0.013, 0.02), 0.5, 4, 8), func(p: Vector3) -> Vector3:
			p.z -= p.x * p.x * 3.0
			return p + head + Vector3(0, 0.0, 0.172)), top)
	_eye_pair(head.y, head.z + 0.165, 0.045, Color(1.0, 0.4, 0.12), 0.012)
	_sides("sh_pauldron", plate, func(s: float) -> ArrayMesh:
		var parts := []
		for i in 3:
			var d := Shape.blob(Vector3(0.17 - i * 0.015, 0.03, 0.16 - i * 0.01), 0.0, 1.0, 6, 12)
			parts.append(Shape.warp(d, func(p: Vector3) -> Vector3:
				p.y -= (p.x * p.x + p.z * p.z) * 4.0
				return Basis(Vector3.BACK, s * (0.35 + i * 0.25)) * p + Vector3(s * (0.3 + i * 0.04), 1.47 - i * 0.07, 0.0)))
		return Shape.merge(parts), top)
	_sides("sh_arm", dark, func(s: float) -> ArrayMesh:
		# Mail sleeves under the plates; the left (+x) arm behind the shield.
		var sh := Vector3(s * 0.32, 1.38, 0.0)
		var el := Vector3(s * 0.4, 1.12, 0.12) if s > 0.0 else Vector3(-0.42, 1.1, 0.0)
		var w := Vector3(0.24, 1.0, 0.32) if s > 0.0 else Vector3(-0.42, 0.88, 0.16)
		return _tube([sh, el, w], [0.075, 0.065, 0.055], 8), top)
	_sides("sh_gauntlet", plate, func(s: float) -> ArrayMesh:
		var w := Vector3(0.24, 1.0, 0.32) if s > 0.0 else Vector3(-0.42, 0.88, 0.16)
		var cuff := Shape.warp(_tube([w + Vector3(0, 0.07, -0.05), w], [0.075, 0.06], 8), func(p: Vector3) -> Vector3: return p)
		var fist := Shape.slab(Vector3(0.05, 0.055, 0.05), 0.5, 5, 8)
		return Shape.merge([cuff, Shape.warp(fist, func(p: Vector3) -> Vector3: return p + w + Vector3(0, -0.05, 0.02))]), top)
	_sides("sh_leg", plate, func(s: float) -> ArrayMesh:
		var parts := [_tube([Vector3(s * 0.13, 0.62, 0.0), Vector3(s * 0.15, 0.4, 0.04), Vector3(s * 0.15, 0.1, 0.0)], [0.085, 0.075, 0.065], 8)]
		parts.append(Shape.warp(Shape.blob(Vector3(0.07, 0.06, 0.07), 0.0, 1.0, 6, 10), func(p: Vector3) -> Vector3: return p + Vector3(s * 0.15, 0.42, 0.06)))
		parts.append(Shape.warp(Shape.slab(Vector3(0.07, 0.045, 0.13), 0.5, 5, 10), func(p: Vector3) -> Vector3: return p + Vector3(s * 0.15, 0.045, 0.05)))
		return Shape.merge(parts), top)
	_part("sh_mace", dark, func() -> ArrayMesh:
		var w := Vector3(-0.42, 0.84, 0.18)
		var haft := _tube([w + Vector3(0, 0.12, -0.04), w + Vector3(0, -0.3, 0.1)], [0.018, 0.02], 5)
		var parts := [haft]
		var c := w + Vector3(0, -0.36, 0.12)
		parts.append(Shape.warp(Shape.blob(Vector3(0.05, 0.07, 0.05), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + c))
		for i in 6:
			var a := i * TAU / 6.0
			var o := Vector3(cos(a), 0, sin(a))
			parts.append(Shape.warp(Shape.slab(Vector3(0.012, 0.06, 0.03), 0.5, 4, 6), func(p: Vector3) -> Vector3: return c + Basis(Vector3.UP, -a) * (p + Vector3(0, 0, 0.055)) * 1.0))
		return Shape.merge(parts), top)
	_shield = Node3D.new()
	_shield.position = Vector3(0.12, 0, 0.42)
	_model.add_child(_shield)
	var e := _shared("sh_planks", func() -> ArrayMesh:
		# Five planks side by side, bowed a little round the bearer, worn
		# and split at the bottom.
		var parts := []
		for i in 5:
			var x := (i - 2.0) * 0.17
			var p := Shape.slab(Vector3(0.082, 0.66 - absf(sin(i * 2.3)) * 0.03, 0.035), 0.25, 6, 10)
			parts.append(Shape.warp(p, func(q: Vector3) -> Vector3:
				q += Vector3(x, 0.96, 0)
				q.z -= q.x * q.x * 0.6
				return q))
		return Shape.merge(parts), top)
	var mi := Art.part(_shield, e[0], wood, e[1])
	meshes.append(mi)
	var e2 := _shared("sh_bands", func() -> ArrayMesh:
		# Iron rim bands top and bottom and a round boss in the middle.
		var parts := []
		for y: float in [1.52, 0.4]:
			var pts := []
			for i in 9:
				var x := lerpf(-0.44, 0.44, i / 8.0)
				pts.append(Vector3(x, y, 0.045 - x * x * 0.6))
			parts.append(_tube(pts, _same(0.03, 8), 5))
		parts.append(Shape.warp(Shape.blob(Vector3(0.12, 0.12, 0.06), 0.0, 1.0, 7, 12), func(p: Vector3) -> Vector3:
			p.z = maxf(p.z, 0.0)
			return p + Vector3(0, 0.96, 0.03)))
		return Shape.merge(parts), top)
	var mi2 := Art.part(_shield, e2[0], plate, e2[1])
	meshes.append(mi2)


## Hellhound: a lean, starved hound of the pit, low and long. Cracked black
## hide stretched over its ribs with the fire showing through the splits
## along its back, a long wolfish skull full of teeth, ears laid back, a
## ridge of spines along the neck, long legs with hooked claws and a tail
## that burns at the tip.
func _hellhound() -> void:
	var hide := Shape.material(Color(0.13, 0.09, 0.08), Color(0.05, 0.03, 0.03), 5.0, 0.6, 0.8, 0.0, 173)
	var bone := Shape.material(Color(0.3, 0.26, 0.22), Color(0.12, 0.1, 0.08), 8.0, 0.45, 0.6, 0.0, 47)
	var top := 1.0
	var head := Vector3(0, 0.8, 0.62)
	_part("hh_body", hide, func() -> ArrayMesh:
		var t := _tube([Vector3(0, 0.62, -0.42), Vector3(0, 0.6, -0.2), Vector3(0, 0.66, 0.12), Vector3(0, 0.74, 0.36), Vector3(0, 0.8, 0.5)], [0.11, 0.12, 0.17, 0.16, 0.09], 12)
		return Shape.warp(t, func(p: Vector3) -> Vector3:
			# A deep chest, the belly tucked up behind it, ribs showing.
			if p.y < 0.6:
				p.y += (0.6 - p.y) * 0.45 * (1.0 - smoothstep(-0.1, 0.15, p.z))
			var ribs := smoothstep(-0.15, 0.0, p.z) * (1.0 - smoothstep(0.3, 0.4, p.z))
			p.x += signf(p.x) * 0.012 * sin(p.z * 70.0) * ribs * smoothstep(0.04, 0.12, absf(p.x))
			p.x *= 0.85
			return p), top)
	_part("hh_spines", bone, func() -> ArrayMesh:
		var parts := []
		for i in 9:
			var t := float(i) / 8.0
			var at := Vector3(0, lerpf(0.98, 0.74, t) - sin(t * PI) * 0.04, lerpf(0.5, -0.36, t))
			parts.append(_spike(at + Vector3(0, -0.06, 0), at + Vector3(0, 0.08 - t * 0.05, -0.08), 0.022 - t * 0.008))
		return Shape.merge(parts), top)
	_part("hh_head", hide, func() -> ArrayMesh:
		# A long, narrow skull, the muzzle running out to a blunt nose.
		var skull := Shape.warp(Shape.blob(Vector3(0.1, 0.09, 0.13), 0.03, 2.0, 9, 12), func(p: Vector3) -> Vector3: return p + head)
		var snout := _tube([head + Vector3(0, -0.01, 0.06), head + Vector3(0, -0.03, 0.18), head + Vector3(0, -0.04, 0.26)], [0.065, 0.05, 0.04], 8)
		var parts := [skull, snout]
		for s: float in [1.0, -1.0]:
			var a := head + Vector3(s * 0.06, 0.06, -0.03)
			parts.append(_tube([a, a + Vector3(s * 0.04, 0.05, -0.06), a + Vector3(s * 0.05, 0.07, -0.14)], [0.03, 0.02, 0.003], 5))
		return Shape.merge(parts), top)
	_part("hh_jaw", hide, func() -> ArrayMesh:
		# Hanging open.
		return _tube([head + Vector3(0, -0.07, 0.02), head + Vector3(0, -0.11, 0.14), head + Vector3(0, -0.13, 0.22)], [0.045, 0.035, 0.025], 6), top)
	_part("hh_maw", Fx.glow(El.COLOR[El.FIRE], 1.5), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.03, 0.02, 0.08), 0.0, 1.0, 4, 8), func(p: Vector3) -> Vector3: return p + head + Vector3(0, -0.075, 0.14)), top)
	_part("hh_teeth", bone, func() -> ArrayMesh:
		var parts := []
		for s: float in [1.0, -1.0]:
			for i in 3:
				var at := head + Vector3(s * 0.03, -0.05, 0.25 - i * 0.05)
				parts.append(_spike(at, at + Vector3(0, -0.035, 0.0), 0.008))
				var lo := head + Vector3(s * 0.025, -0.12, 0.2 - i * 0.05)
				parts.append(_spike(lo, lo + Vector3(0, 0.03, 0.0), 0.007))
		return Shape.merge(parts), top)
	_sockets("hh", head.y + 0.03, head.z + 0.085, 0.05, 0.022, Color(1.0, 0.55, 0.1), 0.016)
	_sides("hh_fore", hide, func(s: float) -> ArrayMesh:
		var sh := Vector3(s * 0.12, 0.66, 0.34)
		var parts := [_tube([sh, Vector3(s * 0.15, 0.42, 0.3), Vector3(s * 0.14, 0.22, 0.36), Vector3(s * 0.14, 0.05, 0.4)], [0.085, 0.05, 0.032, 0.03], 8)]
		for f in 3:
			var a := Vector3(s * 0.14 + (f - 1) * 0.022, 0.03, 0.42)
			parts.append(Shape.tint(_claw(a, a + Vector3(0, 0.0, 0.04), a + Vector3(0, -0.03, 0.06), 0.011), Color(0.6, 0.55, 0.5)))
		return Shape.merge(parts), top)
	_sides("hh_hind", hide, func(s: float) -> ArrayMesh:
		# A dog's hind leg: the thigh forward, a high hock behind.
		var hip := Vector3(s * 0.1, 0.64, -0.36)
		var parts := [_tube([hip, Vector3(s * 0.15, 0.44, -0.22), Vector3(s * 0.14, 0.3, -0.42), Vector3(s * 0.13, 0.05, -0.36)], [0.12, 0.075, 0.038, 0.032], 8)]
		for f in 3:
			var a := Vector3(s * 0.13 + (f - 1) * 0.022, 0.03, -0.33)
			parts.append(Shape.tint(_claw(a, a + Vector3(0, 0.0, 0.04), a + Vector3(0, -0.03, 0.06), 0.011), Color(0.6, 0.55, 0.5)))
		return Shape.merge(parts), top)
	_part("hh_tail", hide, func() -> ArrayMesh:
		return _tube([Vector3(0, 0.66, -0.5), Vector3(0, 0.6, -0.68), Vector3(0.06, 0.5, -0.82), Vector3(0.1, 0.46, -0.92)], [0.04, 0.03, 0.02, 0.008], 6), top)
	# The fire under the hide: splits along the back and the tip of the tail.
	var splits := _shared("hh_splits", func() -> ArrayMesh:
		var parts := []
		for i in 5:
			var z := lerpf(0.3, -0.3, i / 4.0)
			var y := 0.79 - absf(z) * 0.08
			for s: float in [1.0, -1.0]:
				parts.append(_tube([Vector3(s * 0.03, y, z + 0.02), Vector3(s * 0.08, y - 0.04, z), Vector3(s * 0.12, y - 0.12, z - 0.02)], [0.008, 0.012, 0.004], 4))
		return Shape.merge(parts), top)
	Art.part(_model, splits[0], Fx.element(El.MAGMA, 1.4), splits[1])
	Art.part(_model, Art.cyl(0.02, 0.05, 0.25), Fx.element(El.FIRE, 1.4), Vector3(0.12, 0.5, -0.96), Vector3(-70, 0, 0))


## Lurker: a hunched burrower, half mole and half beetle. Overlapping plates
## of horn down a humped back, caked with dirt; pale, bristled flesh where
## the plates part; a blunt, armoured snout low to the ground with a split
## of teeth under it; tiny eyes; and two huge spade claws for digging,
## held forward like a mantis.
func _lurker() -> void:
	var shell := Shape.material(Color(0.28, 0.21, 0.15), Color(0.11, 0.08, 0.06), 4.0, 0.55, 0.9, 0.0, 181)
	var flesh := Shape.material(Color(0.42, 0.33, 0.28), Color(0.24, 0.17, 0.14), 6.0, 0.6, 0.6, 0.0, 187)
	var horn := Shape.material(Color(0.5, 0.45, 0.36), Color(0.22, 0.18, 0.13), 6.0, 0.4, 0.6, 0.0, 191)
	var top := 1.1
	var snout := Vector3(0, 0.5, 0.62)
	_part("lu_body", flesh, func() -> ArrayMesh:
		# The soft body under the plates, low at the head end.
		var b := Shape.blob(Vector3(0.44, 0.36, 0.6), 0.05, 2.0, 10, 16)
		return Shape.warp(b, func(p: Vector3) -> Vector3:
			p.y += 0.12 * smoothstep(0.3, -0.3, p.z) * smoothstep(-0.2, 0.2, p.y)
			p.y = maxf(p.y, -0.26)
			return p + Vector3(0, 0.52, -0.05)), top)
	_part("lu_plates", shell, func() -> ArrayMesh:
		# Six overlapping arched plates over the back, front to back, each
		# lying on the body and lifted at its hind edge so the next one
		# tucks under it.
		var parts := []
		for i in 6:
			var t := float(i) / 5.0
			var z := lerpf(0.4, -0.5, t)
			var f := sqrt(maxf(0.05, 1.0 - pow((z + 0.05) / 0.62, 2.0)))
			var hz := 0.36 * f + 0.12 * smoothstep(0.3, -0.3, z)
			var wz := 0.44 * f
			var pl := Shape.blob(Vector3(1.0, 0.035, 0.12), 0.05, 7.0 + i, 5, 14)
			parts.append(Shape.warp(pl, func(p: Vector3) -> Vector3:
				var a := p.x * 1.45
				var lift := 0.03 + p.y + maxf(0.0, -p.z) * 0.25
				return Vector3(sin(a) * (wz + lift), cos(a) * (hz + lift), p.z) + Vector3(0, 0.52, z)))
		return Shape.merge(parts), top)
	_part("lu_head", shell, func() -> ArrayMesh:
		# A blunt wedge of a head, armoured, the snout a flat shovel.
		var h := Shape.slab(Vector3(0.2, 0.13, 0.17), 0.6, 7, 12)
		var head := Shape.warp(h, func(p: Vector3) -> Vector3:
			p.y -= maxf(0.0, p.z) * 0.4
			p.x *= 1.0 - maxf(0.0, p.z) * 1.2
			return p + snout + Vector3(0, 0.04, -0.06))
		var brow := _tube([snout + Vector3(-0.17, 0.12, -0.08), snout + Vector3(0, 0.15, -0.02), snout + Vector3(0.17, 0.12, -0.08)], [0.03, 0.035, 0.03], 6)
		return Shape.merge([head, brow]), top)
	_part("lu_maw", _hollow(), func() -> ArrayMesh:
		return Shape.warp(Shape.blob(Vector3(0.1, 0.02, 0.06), 0.0, 1.0, 4, 8), func(p: Vector3) -> Vector3: return p + snout + Vector3(0, -0.07, 0.06)), top)
	_part("lu_teeth", horn, func() -> ArrayMesh:
		var parts := []
		for i in 6:
			var x := (i - 2.5) * 0.03
			var at := snout + Vector3(x, -0.05, 0.1 - absf(x) * 0.5)
			parts.append(_spike(at, at + Vector3(0, -0.04, 0.005), 0.008))
		return Shape.merge(parts), top)
	_sockets("lu", snout.y + 0.1, snout.z - 0.02, 0.17, 0.018, Color(1.0, 0.6, 0.1), 0.012)
	_sides("lu_arm", flesh, func(s: float) -> ArrayMesh:
		# Thick forearms held forward, hunched like a mantis.
		var sh := Vector3(s * 0.34, 0.6, 0.3)
		return _tube([sh, Vector3(s * 0.5, 0.45, 0.42), Vector3(s * 0.48, 0.24, 0.6)], [0.11, 0.09, 0.075], 8), top)
	_sides("lu_claw", horn, func(s: float) -> ArrayMesh:
		# The digging hand: a broad palm and three long spade claws.
		var w := Vector3(s * 0.48, 0.24, 0.6)
		var parts := [Shape.warp(Shape.blob(Vector3(0.09, 0.05, 0.08), 0.0, 1.0, 5, 8), func(p: Vector3) -> Vector3: return p + w)]
		for f in 3:
			var a := w + Vector3(s * (f - 1) * 0.05, -0.02, 0.05)
			var spread := Vector3(s * (f - 1) * 0.03, 0, 0)
			parts.append(Shape.warp(_claw(a, a + Vector3(0, -0.04, 0.12) + spread, a + Vector3(0, -0.2, 0.18) + spread * 1.6, 0.034), func(p: Vector3) -> Vector3:
				# Flattened into a spade.
				var c := a.lerp(a + Vector3(0, -0.12, 0.15), 0.5)
				var d := p - c
				return c + Vector3(d.x * 1.0, d.y, d.z) + Vector3(0, 0, 0)))
		return Shape.merge(parts), top)
	_sides("lu_leg", flesh, func(s: float) -> ArrayMesh:
		# Short hind legs, splayed, knuckled feet.
		var hip := Vector3(s * 0.3, 0.4, -0.38)
		var parts := [_tube([hip, Vector3(s * 0.44, 0.24, -0.36), Vector3(s * 0.44, 0.05, -0.28)], [0.1, 0.075, 0.06], 8)]
		for f in 3:
			var a := Vector3(s * 0.44 + (f - 1) * 0.04, 0.04, -0.24)
			parts.append(Shape.tint(_claw(a, a + Vector3(0, 0, 0.04), a + Vector3(0, -0.035, 0.07), 0.016), Color(0.75, 0.7, 0.6)))
		return Shape.merge(parts), top)


## Storm Sprite: a knot of living lightning, all light and no body, so it
## stays an effect: a white-hot core, a crackling shell, spikes and sparks.
func _sprite() -> void:
	Art.part(_model, Art.sphere(0.16, 10), Fx.glow(Color(1.0, 0.95, 0.7), 5.0), Vector3(0, 1.2, 0))
	var shell2 := Art.part(_model, Art.sphere(0.3, 10), Fx.element(El.LIGHTNING, 1.6), Vector3(0, 1.2, 0))
	meshes.append(shell2)
	for i in 4:
		var a2 := i * TAU / 4.0
		Art.part(_model, Art.cyl(0.0, 0.04, 0.45, 4), Fx.glow(El.COLOR[El.LIGHTNING], 3.0), Vector3(cos(a2) * 0.3, 1.2, sin(a2) * 0.3), Vector3(90, rad_to_deg(-a2) + 90.0, 0))
	var sparks := Fx.particles(El.COLOR[El.LIGHTNING], 16, 0.35, 0.08)
	sparks.position.y = 1.2
	sparks.initial_velocity_max = 2.0
	sparks.spread = 180.0
	_model.add_child(sparks)
	sparks.emitting = true
	_model.add_child(Fx.halo(El.COLOR[El.LIGHTNING], 1.0, 0.6, 1.0))
	_model.get_child(-1).position.y = 1.2


## Each kind dies its own way (Joep: no red bloom for everyone). Skeletons
## fall apart into bones, ice shatters, the fragile ones (imps, watchers)
## and demons blow up and hurt whoever stands close, friend or foe, so
## killing them next to someone is a risk.
func _death() -> void:
	var at := global_position
	var big: float = cfg.size if cfg.has("model") else 1.0
	var boss: bool = cfg.get("boss", false)
	match cfg.get("model", kind):
		"skeleton":
			# The bones lose what held them together and clatter down.
			var d := Debris.scatter(_model, at, 1.8 * big, 3.0, 5.0)
			d.bits(at + Vector3.UP * 0.4, Color(0.8, 0.76, 0.66), 6, 0.06 * big, 2.0, 2.0)
			_gone(6.0)
		"ghoul":
			var d2 := Debris.scatter(_model, at, 2.6, 4.0, 3.0)
			d2.bits(at + Vector3.UP * 0.6, Color(0.25, 0.3, 0.18), 8, 0.1, 3.0, 3.0)
			_gone(4.0)
		"frost_brute":
			# A frozen giant shatters into shards of ice.
			Debris.scatter(_model, at, 3.5 * big, 5.0, 3.0, Fx.element(El.ICE, 1.0))
			Fx.burst(at + Vector3.UP, El.COLOR[El.ICE], 20, 6.0, 0.25)
			Fx.ring(at, El.COLOR[El.FROST], 3.0 * big, 0.4)
			if Game.I:
				Game.I.shake(0.5)
			_gone(4.0)
		"imp":
			_blow_up(El.FIRE, 0.35, 2.4, 12.0, 1.0)
		"sprite":
			_blow_up(El.LIGHTNING, 0.2, 2.2, 8.0, 0.0)
		"lurker":
			var d5 := Debris.scatter(_model, at, 2.4, 3.0, 3.0)
			d5.bits(at + Vector3.UP * 0.4, Color(0.3, 0.22, 0.15), 10, 0.1, 3.0, 3.0)
			_gone(4.0)
		"necromancer":
			# Its hold on the dead goes with it: a sigh of green, then robes
			# empty to the floor.
			Fx.burst(at + Vector3.UP * 1.3, Color(0.45, 1.0, 0.5), 24, 3.0, 0.2)
			Fx.puff(at + Vector3.UP, Color(0.3, 0.5, 0.3, 0.5), 1.4)
			var tw5 := create_tween()
			tw5.tween_property(_model, "scale", Vector3(1.3, 0.1, 1.3), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw5.tween_interval(1.5)
			tw5.tween_property(_model, "position:y", -0.4, 1.0)
			_gone(3.5)
		"watcher":
			_blow_up(El.VOID, 0.5, 2.6, 12.0, 0.0)
		"demon":
			# Its skin cracks into magma, it swells, and it goes off.
			for m in meshes:
				m.material_override = Fx.element(El.MAGMA, 1.2)
			_blow_up(El.FIRE, 1.4 if boss else 0.8, 5.0 if boss else 3.2, 30.0 if boss else 20.0, 3.0 if boss else 2.0)
		"cultist", "hellhound":
			# Burns up: the robe chars black and slumps into ash, embers rise.
			for m in meshes:
				m.material_override = Fx.solid(Color(0.07, 0.05, 0.05), 1.0)
			var embers := Fx.particles(El.COLOR[El.FIRE], 30, 1.2, 0.18)
			embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			embers.emission_sphere_radius = 0.4
			embers.position = Vector3.UP * 0.9
			embers.direction = Vector3.UP
			embers.gravity = Vector3.UP * 1.5
			embers.initial_velocity_max = 1.2
			embers.one_shot = true
			embers.explosiveness = 0.3
			add_child(embers)
			embers.emitting = true
			var tw := create_tween()
			tw.tween_property(_model, "scale", Vector3(1.25, 0.08, 1.25) * big, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_interval(1.5)
			tw.tween_property(_model, "position:y", -0.4, 1.0)
			_gone(3.6)
		"wraith":
			# Nothing to fall: it unravels into cold mist and is gone.
			Fx.puff(at + Vector3.UP, Color(0.55, 0.75, 0.9, 0.6), 1.4 * big)
			var tw2 := create_tween()
			tw2.tween_property(_model, "scale", Vector3(0.1, 2.2, 0.1) * big, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw2.parallel().tween_property(_model, "position:y", 1.5, 0.6)
			tw2.tween_callback(_model.hide)
			_gone(3.0)
		"drowned", "toad":
			# Falls apart into water: a splash and a puddle where it stood.
			Debris.scatter(_model, at, 1.5 * big, 2.0, 0.6)
			Fx.burst(at + Vector3.UP * 0.5, El.COLOR[El.WATER], 18, 4.0, 0.25)
			if Game.I:
				Game.I.arena.add_field(at, El.WATER, 1.6 * big, 6.0, null)
			_gone(3.5)
		"bile":
			# It pops (the burst is in die), the skin flies everywhere.
			var d3 := Debris.scatter(_model, at, 5.0 * big, 5.0, 2.0)
			d3.bits(at + Vector3.UP * 0.8, Color(0.4, 0.42, 0.15), 12, 0.12 * big, 5.0, 4.0)
			_gone(4.0)
		_:
			# Brutes topple like felled trees and shake the floor.
			var tw3 := create_tween()
			tw3.tween_property(_model, "rotation:x", -PI / 2.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw3.parallel().tween_property(_model, "position:y", 0.15, 0.5)
			tw3.tween_callback(func():
				if Game.I:
					Game.I.shake(0.7)
				var d4 := Debris.new()
				Fx.root.add_child(d4)
				d4.bits(global_position, Color(0.4, 0.33, 0.25), 10, 0.14, 3.0, 2.5))
			tw3.tween_interval(1.5)
			tw3.tween_property(_model, "position:y", -1.8, 1.4)
			_gone(4.0)
	if boss and Game.I:
		Game.I.shake(1.2)


## Swell and flash for [param fuse] seconds, then burst in [param el]:
## [param dmg] to everyone within [param r], monsters too, and a field of
## [param field] radius left behind.
func _blow_up(el: int, fuse: float, r: float, dmg: float, field: float) -> void:
	var c: Color = El.COLOR[el]
	var tw := create_tween()
	tw.tween_property(_model, "scale", _model.scale * 1.45, fuse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var glow := Fx.halo(c, 1.6 * r * 0.5, 0.6, 1.0)
	glow.position = Vector3.UP * 0.9
	add_child(glow)
	tw.parallel().tween_property(glow, "scale", Vector3.ONE * 1.8, fuse)
	tw.tween_callback(func():
		var at := global_position
		var s := _attack_spell(el, dmg * (Game.I.monster_damage if Game.I else 1.0))
		var nova := NovaFx.new()
		nova.setup(self, {counts = {el: 1}, payload = [], primary = el, n = {radius = r, rate = s.scale}})
		if Game.I:
			Game.I.spawn(nova, at)
			Game.I.shake(0.4 + r * 0.1)
			if field > 0.0:
				Game.I.arena.add_field(at, el, field, 5.0, null)
		var d := Debris.scatter(_model, at, 6.0, 6.0, 1.5)
		d.bits(at + Vector3.UP * 0.8, c.darkened(0.5), 6, 0.08, 6.0, 5.0)
		glow.queue_free())
	_gone(fuse + 4.0)


## Free the dead monster after [param t] seconds, once its death has played.
func _gone(t: float) -> void:
	var tw := create_tween()
	tw.tween_interval(t)
	tw.tween_callback(queue_free)


func _physics_process(dt: float) -> void:
	tick_status(dt)
	if not alive:
		return
	if Game.I and Game.I.paused_play:
		return
	_think -= dt
	_cool = maxf(0.0, _cool - dt)
	if _think <= 0.0 or target == null or (not target.alive and Game.I and Game.I.wizards.any(func(w): return w.alive)):
		_think = 0.5
		target = _pick_target()
	var want := Vector3.ZERO
	_open_t = maxf(0.0, _open_t - dt)
	if _shield:
		_shield.rotation.y = lerp_angle(_shield.rotation.y, 1.3 if _open_t > 0.0 else 0.0, 10.0 * dt)
	if _dash_t > 0.0:
		_dashing(dt)
		_animate(dt)
		return
	if _under:
		_tunnel(dt)
		return
	if cfg.attack == "burrow":
		_surface_t -= dt
		# Back down when its time up top is over, unless the cold or the mud
		# holds it.
		if _surface_t <= 0.0 and _wind <= 0.0 and can_act() and chill <= 0.0 and slow <= 0.0:
			_go_under()
			return
	if cfg.has("raise"):
		_raise(dt)
	if target and can_act():
		var to := target.global_position - global_position
		to.y = 0
		var d := to.length()
		var dir := to / maxf(d, 0.01)
		var reach: float = cfg.reach + target.radius
		if _wind > 0.0:
			_wind -= dt
			_tell(1.0 - _wind / _wind_time())
			_warning(1.0 - _wind / _wind_time())
			if _aim_bar:
				_draw_aim(1.0 - _wind / _wind_time())
			if _wind <= 0.0:
				_strike()
		elif cfg.has("keep"):
			var keep: float = cfg.get("keep", 6.0)
			if d > reach:
				want = dir
			elif d < keep - 1.0:
				want = -dir
			else:
				want = dir.cross(Vector3.UP) * _strafe * 0.5
			if d <= reach and _cool <= 0.0:
				_begin()
		else:
			if d > reach * 0.8:
				want = dir
			if d <= reach and _cool <= 0.0:
				_begin()
		want += _separation() * 0.8
		if want.length() > 1.0:
			want = want.normalized()
		var face := dir if want.length() < 0.2 or _wind > 0.0 else want.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(face.x, face.z), 8.0 * dt)
	if cfg.get("boss", false):
		_boss(dt)
		if _spiral_t > 0.0:
			want *= 0.25
	_run_pending(dt)
	drive(want * move_speed(), dt)
	_animate(dt)


func _wind_time() -> float:
	if cfg.has("wind"):
		return cfg.wind
	return 0.9 if cfg.attack == "slam" else 0.6


func _begin() -> void:
	_wind = _wind_time()
	_lock = _aim()
	_warn_end()
	# A glint over the head: something is coming.
	Fx.flash(global_position + Vector3.UP * (1.3 * float(cfg.size) + 0.4), Color(1.0, 0.85, 0.55), 0.7, 0.25)
	if cfg.attack in ["ranged", "lob"]:
		_orb = Fx.halo(El.COLOR[elite.get("el", cfg.el)], 0.5, 0.9, 1.0)
		add_child(_orb)
	_warning(0.0)


## The wind-up shown, [param k] from 0 to 1.
func _warning(k: float) -> void:
	if k < 0.75:
		_lock = _aim()
	if _orb:
		_orb.global_position = global_position + _lock * (radius + 0.35) + Vector3.UP * 1.0
		_orb.scale = Vector3.ONE * (0.4 + 1.1 * k)


func _warn_end() -> void:
	if _orb and is_instance_valid(_orb):
		_orb.queue_free()
	_orb = null


func _tell(k: float) -> void:
	for e in _eyes:
		e.scale = Vector3.ONE * (1.0 + k * 1.5)


func _attack_spell(el: int, dmg: float) -> Dictionary:
	var e: float = El.EFFECT[el].get("dmg", 8.0)
	return {counts = {el: 1}, payload = [], primary = el, scale = dmg / e}


func _strike() -> void:
	_tell(0.0)
	_warn_end()
	_cool = randf_range(1.2, 1.8) if cfg.attack != "slam" else 2.2
	if target == null:
		return
	var dmg: float = cfg.dmg * (Game.I.monster_damage if Game.I else 1.0)
	var el: int = elite.get("el", cfg.el)
	var s := _attack_spell(el, dmg)
	var attack: String = cfg.attack
	if attack == "burrow":
		attack = "melee"
	match attack:
		"dash":
			# Off it goes, straight through where the target stood.
			_dash_t = cfg.dash[1]
			_dash_dir = _lock if _lock != Vector3.ZERO else _aim()
			_dash_hit.clear()
			_cool = randf_range(2.2, 3.0)
			if cfg.has("trail") and Game.I:
				Game.I.arena.add_field(global_position, cfg.trail, 0.9, 2.5, null)
		"lob":
			_lob(target.global_position + target.velocity * 0.35, el, dmg)
			_cool = randf_range(1.8, 2.6)
		"melee":
			var to := target.global_position - global_position
			to.y = 0
			# Only where it showed: out of the slice is out of reach.
			var side := absf(_lock.signed_angle_to(to, Vector3.UP)) if to.length() > 0.3 else 0.0
			if to.length() <= cfg.reach + target.radius + 0.6 and side <= MELEE_ARC + atan2(target.radius, maxf(to.length(), 0.1)):
				target.melee_hit = true
				if cfg.get("shield", false):
					# A shove with the shield as well as the mace.
					target.push += to.normalized() * 7.0 / target.mass
				var dealt := target.hit_spell(s, s.scale, self, to.normalized(), 1.0)
				target.melee_hit = false
				if elite.has("leech"):
					healed(dealt * elite.leech)
				_model.position = to.normalized() * 0.3
				create_tween().tween_property(_model, "position", Vector3.ZERO, 0.2)
		"slam":
			var r: float = cfg.reach + 0.8
			Fx.ring(global_position, El.COLOR[el].lerp(Color(0.6, 0.5, 0.4), 0.5), r, 0.3)
			Fx.burst(global_position + (target.global_position - global_position).normalized() * 1.2, Color(0.5, 0.4, 0.3), 20, 5.0)
			if Game.I:
				Game.I.shake(0.3 if not cfg.get("boss", false) else 0.6)
			if cfg.has("ring"):
				_ring(cfg.ring, 6.0, el, dmg * 0.6, randf() * TAU)
			for w in (Game.I.wizards if Game.I else []):
				var to: Vector3 = w.global_position - global_position
				to.y = 0
				if w.alive and to.length() < r + w.radius:
					w.melee_hit = true
					w.hit_spell(s, s.scale, self, to.normalized(), 1.0)
					w.melee_hit = false
		"ranged":
			var shots: Array = cfg.get("shots", ["fan3"])
			_volley(shots[_shot_i % shots.size()], el, dmg)
			_shot_i += 1


func _aim() -> Vector3:
	if target == null or not is_instance_valid(target):
		return Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
	var d := target.global_position - global_position
	d.y = 0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


## One of the small monsters' patterns.
func _volley(pattern: String, el: int, dmg: float) -> void:
	match pattern:
		"fan3":
			_fan(3, 22.0, 9.0, el, dmg)
		"fan5":
			_fan(5, 56.0, 7.0, el, dmg * 0.8)
		"ring10":
			_ring(10, 5.0, el, dmg * 0.8, randf() * TAU)
		"burst3":
			for i in 3:
				_later(0.16 * i, func(): _fan(1, 0.0, 9.5, el, dmg * 0.7))
		"wave7":
			_fan(7, 84.0, 4.6, el, dmg * 0.7, 0.26)
		"snipe":
			# One fast arrow down the line it showed, locked a moment ago.
			var dir := _aim_lock if _aim_lock != Vector3.ZERO else _aim()
			var sp := _attack_spell(el, dmg)
			sp.arrow = true
			Bullet.fire(self, global_position + dir * (radius + 0.3), dir, 17.0, sp, 0.16)
			_aim_lock = Vector3.ZERO
			if _aim_bar:
				_aim_bar.visible = false


func _fan(count: int, spread_deg: float, speed_m: float, el: int, dmg: float, size := 0.22) -> void:
	var aim := _aim()
	for i in count:
		var k := 0.0 if count == 1 else float(i) / (count - 1) - 0.5
		var dir := aim.rotated(Vector3.UP, deg_to_rad(spread_deg) * k)
		Bullet.fire(self, global_position + dir * (radius + 0.3), dir, speed_m, _attack_spell(el, dmg), size)


func _ring(count: int, speed_m: float, el: int, dmg: float, offset: float, size := 0.24) -> void:
	for i in count:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, offset + TAU * i / count)
		Bullet.fire(self, global_position + dir * (radius + 0.3), dir, speed_m, _attack_spell(el, dmg), size)


func _later(seconds: float, f: Callable) -> void:
	if seconds <= 0.0:
		f.call()
	else:
		_pending.append([seconds, f])


func _run_pending(dt: float) -> void:
	if _pending.is_empty():
		return
	var keep: Array = []
	for p in _pending:
		p[0] -= dt
		if p[0] <= 0.0:
			if can_act():
				p[1].call()
		else:
			keep.append(p)
	_pending = keep


func _boss(dt: float) -> void:
	_special -= dt
	_summon_t -= dt
	var el: int = cfg.nova
	var dmg: float = cfg.dmg * 0.5 * (Game.I.monster_damage if Game.I else 1.0)
	if _spiral_t > 0.0:
		_spiral_t -= dt
		_spiral_step -= dt
		if _spiral_step <= 0.0 and can_act():
			_spiral_step = 0.1
			_spiral_ang += 0.33
			_ring(3, 6.0, el, dmg, _spiral_ang, 0.26)
	if _special <= 0.0 and can_act():
		_special = randf_range(4.5, 6.0)
		var pattern: String = BOSS_PATTERNS[_pattern_i % BOSS_PATTERNS.size()]
		_pattern_i += 1
		# Shown first like every attack, in the body: a glint, and it rears
		# up and swells (_windup_pose) before the pattern comes.
		Fx.flash(global_position + Vector3.UP * (1.3 * float(cfg.size) + 0.4), Color(1.0, 0.85, 0.55), 1.2, 0.3)
		_boss_wind = BOSS_WIND
		_later(BOSS_WIND, func(): if alive: _boss_pattern(pattern, el, dmg))
	if _summon_t <= 0.0:
		_summon_t = randf_range(10.0, 14.0)
		for k in cfg.summon:
			Game.I.run.spawn_enemy(k, global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), false)


const BOSS_WIND := 0.8
var _boss_wind := 0.0


## A boss's pattern once its wind-up (BOSS_WIND) is over.
func _boss_pattern(pattern: String, el: int, dmg: float) -> void:
	match pattern:
		"spiral":
			_spiral_t = 3.2
			_spiral_step = 0.0
		"rings":
			for i in 3:
				var off := (0.5 if i % 2 == 1 else 0.0) * TAU / 20.0
				_later(0.55 * i, func(): _ring(20, 5.2, el, dmg, off, 0.28))
		"fan9":
			for i in 3:
				_later(0.45 * i, func(): _fan(9, 90.0, 7.5, el, dmg))
		"nova":
			var s := _attack_spell(el, cfg.dmg * 0.7 * (Game.I.monster_damage if Game.I else 1.0))
			var nova := NovaFx.new()
			nova.setup(self, {counts = s.counts, payload = [], primary = el, n = {radius = 7.0, rate = s.scale}})
			nova.only_team = 0
			Game.I.spawn(nova, global_position)
			Game.I.shake(0.5)


## The aim line while drawing: it follows the target until [param k] is
## 0.75, then holds still, and that is where the arrow goes.
func _draw_aim(k: float) -> void:
	if k < 0.75 or _aim_lock == Vector3.ZERO:
		_aim_lock = _aim()
	var from := global_position + Vector3.UP * 1.0
	var length := 16.0
	_aim_bar.visible = true
	_aim_bar.global_transform = Transform3D(Basis.looking_at(_aim_lock, Vector3.UP), from + _aim_lock * length * 0.5)
	_aim_bar.scale = Vector3(1.0 + k, 1.0, length)
	(_aim_bar.material_override as StandardMaterial3D).albedo_color.a = 0.15 + 0.55 * k


## Dashing: a straight run, hitting every wizard it passes through once.
func _dashing(dt: float) -> void:
	_dash_t -= dt
	if not can_act():
		_dash_t = 0.0
		return
	velocity = _dash_dir * cfg.dash[0] + push
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	if cfg.has("trail") and randf() < 0.3 and Game.I:
		Fx.burst(global_position + Vector3.UP * 0.4, El.COLOR[cfg.trail], 3, 1.0, 0.2)
	var dmg: float = cfg.dmg * (Game.I.monster_damage if Game.I else 1.0)
	var s := _attack_spell(elite.get("el", cfg.el), dmg)
	for w in (Game.I.wizards if Game.I else []):
		if not w.alive or w in _dash_hit:
			continue
		if w.global_position.distance_to(global_position) < radius + w.radius + 0.25:
			_dash_hit.append(w)
			w.melee_hit = true
			w.hit_spell(s, s.scale, self, _dash_dir, 1.0)
			w.melee_hit = false
			if elite.has("leech"):
				healed(dmg * elite.leech)


## A glob of bog arcs over to [param at] (a ring shows where), and bursts
## there: a little damage, slowed and soaked, and a puddle left.
func _lob(at: Vector3, el: int, dmg: float) -> void:
	at = Game.I.arena.clamp_inside(at) if Game.I else at
	var flight := 0.9
	Fx.ring(at, El.COLOR[el].lightened(0.3), 1.6, flight)
	var glob := Node3D.new()
	Fx.root.add_child(glob)
	var from := global_position + Vector3.UP * 0.8
	glob.global_position = from
	Art.part(glob, Art.sphere(0.22, 8), Fx.element(el, 1.0))
	var arc := func(k: float) -> void:
		glob.global_position = from.lerp(at, k) + Vector3.UP * sin(k * PI) * 4.0
	var tw := glob.create_tween()
	tw.tween_method(arc, 0.0, 1.0, flight)
	tw.tween_callback(func():
		var s := _attack_spell(el, dmg)
		var nova := NovaFx.new()
		nova.setup(self, {counts = s.counts, payload = [], primary = el, n = {radius = 1.6, rate = s.scale}})
		nova.only_team = 0
		if Game.I:
			Game.I.spawn(nova, at)
			Game.I.arena.add_field(at, El.WATER, 1.4, 5.0, null)
		glob.queue_free())


## A lurker goes down into the floor: nothing can hit it there.
func _go_under(at_once := false) -> void:
	_under = true
	_wind = 0.0
	_warn_end()
	collision_layer = 0
	_hp_bar.visible = false
	_mound.visible = true
	if at_once:
		_model.visible = false
		return
	Fx.burst(global_position + Vector3.UP * 0.2, Color(0.3, 0.22, 0.15), 14, 3.0)
	var tw := create_tween()
	tw.tween_property(_model, "position:y", -1.6, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _model.visible = false)


## Under the floor: close in on the target, shake the ground over it, burst up.
func _tunnel(dt: float) -> void:
	invuln = maxf(invuln, 0.1)
	_mound.rotation.y += dt * 4.0
	_mound.position.y = absf(sin(Time.get_ticks_msec() / 90.0)) * 0.04
	if target == null:
		drive(Vector3.ZERO, dt)
		return
	var to := target.global_position - global_position
	to.y = 0
	if _wind > 0.0:
		_wind -= dt
		_mound.scale = Vector3.ONE * (1.0 + (0.7 - _wind) * 0.8)
		drive(Vector3.ZERO, dt)
		if _wind <= 0.0:
			_erupt()
		return
	if to.length() < 1.2:
		# It is right under you: the ground heaves and a ring warns you.
		_wind = 0.7
		Fx.ring(global_position, Color(0.5, 0.35, 0.2), 1.9, 0.7)
		return
	drive(to.normalized() * speed * 1.35, dt)


func _erupt() -> void:
	_warn_end()
	_under = false
	invuln = 0.0
	collision_layer = _layer
	_mound.visible = false
	_mound.scale = Vector3.ONE
	_model.visible = true
	_model.position.y = -1.4
	_pose_t = 0.3
	create_tween().tween_property(_model, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_surface_t = 4.5
	_cool = 1.0
	var at := global_position
	var d := Debris.new()
	Fx.root.add_child(d)
	d.bits(at + Vector3.UP * 0.2, Color(0.3, 0.22, 0.15), 12, 0.14, 5.0, 2.0)
	if Game.I:
		Game.I.shake(0.3)
	var dmg: float = cfg.dmg * (Game.I.monster_damage if Game.I else 1.0)
	var s := _attack_spell(elite.get("el", cfg.el), dmg)
	for w in (Game.I.wizards if Game.I else []):
		var to: Vector3 = w.global_position - at
		to.y = 0
		if w.alive and to.length() < 1.9 + w.radius:
			w.melee_hit = true
			w.hit_spell(s, s.scale, self, to.normalized() if to.length() > 0.1 else Vector3.FORWARD, 1.0)
			w.melee_hit = false
			w.stun = maxf(w.stun, 0.45)


## A necromancer raises two skeletons out of the ground near it now and
## then, never more than four at once.
func _raise(dt: float) -> void:
	_raise_t -= dt
	# Only with someone to throw them at.
	if _raise_t > 0.0 or not can_act() or not Game.I or target == null or target.global_position.distance_to(global_position) > 18.0:
		return
	_raise_t = randf_range(7.0, 9.0)
	var mine := Game.I.enemies.filter(func(e): return e.master == self and e.alive).size()
	_wind = 0.0
	_warn_end()
	for i in mini(2, 4 - mine):
		var a := randf() * TAU
		var at := Game.I.arena.clamp_inside(global_position + Vector3(cos(a), 0, sin(a)) * randf_range(1.8, 3.0))
		var e := Enemy.new().setup(cfg.raise, max_hp / cfg.hp * 0.8, false)
		e.master = self
		e.position = at
		e.stun = 0.7
		Game.I.add_enemy(e)
		e._model.position.y = -1.6
		e._pose_t = 0.75
		e.create_tween().tween_property(e._model, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		Fx.burst(at + Vector3.UP * 0.3, Color(0.45, 1.0, 0.5), 14, 2.5, 0.2)
		Fx.ring(at, Color(0.45, 1.0, 0.5), 1.2, 0.5)


## The shield: hits that come at it from the front do a fifth of their
## damage, unless lightning (it runs through the metal) or the shield is
## knocked aside (a hard shove from earth or air opens it for a moment).
func hit_spell(spell: Dictionary, scale: float, src: Actor, dir: Vector3, ff := 1.0) -> float:
	if not cfg.get("shield", false) or not alive or dir.length() < 0.01:
		return super(spell, scale, src, dir, ff)
	var before := push.length()
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var front := dir.normalized().dot(fwd) < -0.35
	var conducts: bool = spell.counts.has(El.LIGHTNING) or spell.counts.has(El.STORM)
	var blocked: bool = front and _open_t <= 0.0 and not conducts
	var keep := armor
	if blocked:
		armor *= 0.2
		shown.resist = true
		if scale > 0.2:
			Fx.burst(global_position + fwd * 0.5 + Vector3.UP, Color(1.0, 0.85, 0.5), 6, 3.0, 0.12)
	var dealt := super(spell, scale, src, dir, ff)
	armor = keep
	if push.length() - before > 3.0:
		_open_t = 1.8
	return dealt


## The nearest living wizard. With every wizard down, the nearest grave:
## the monsters gather round it and beat on it instead of standing still.
func _pick_target() -> Actor:
	var best: Actor = null
	var bd := INF
	var wizards: Array = Game.I.wizards if Game.I else []
	var anyone := wizards.any(func(w): return w.alive)
	for w in wizards:
		if anyone and not w.alive:
			continue
		var d := global_position.distance_to(w.global_position)
		if w == target:
			d -= 2.0
		if d < bd:
			bd = d
			best = w
	return best


func _separation() -> Vector3:
	var out := Vector3.ZERO
	for e in (Game.I.enemies if Game.I else []):
		if e == self or not e.alive:
			continue
		var d: Vector3 = global_position - e.global_position
		d.y = 0
		var l := d.length()
		var want: float = radius + e.radius + 0.3
		if l < want and l > 0.01:
			out += d / l * (want - l) / want
	return out


func _animate(dt: float) -> void:
	# Last frame's flinch comes off before the pose is worked out again.
	_model.position -= _flinch_off
	_model.rotation.x -= _flinch_rot.x
	_model.rotation.z -= _flinch_rot.z
	var moving := velocity.length() > 0.4
	_walk += dt * (8.0 if moving else 0.0) * speed / 3.0
	_pose_t = maxf(0.0, _pose_t - dt)
	if _pose_t <= 0.0:
		_model.position.y = absf(sin(_walk)) * 0.06
	_model.rotation.z = sin(_walk) * 0.06
	_boss_wind = maxf(0.0, _boss_wind - dt)
	if _wind > 0.0 or _boss_wind > 0.0:
		_windup_pose(1.0 - _wind / _wind_time() if _wind > 0.0 else 1.0 - _boss_wind / BOSS_WIND)
	else:
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, 10.0 * dt)
		_model.scale = _model.scale.lerp(_base_scale, 12.0 * dt)
	if kind == "sprite":
		var ts := Time.get_ticks_msec() / 1000.0 + float(get_instance_id() % 53)
		_model.position.y = sin(ts * 3.3) * 0.15
		_model.rotation.y += dt * 6.0
	elif kind == "wraith" or cfg.get("model", "") == "wraith":
		_model.position.y = 0.3 + sin(Time.get_ticks_msec() / 400.0) * 0.1
	elif kind == "watcher":
		# It floats: a slow bob and sway instead of a walk.
		var tt := Time.get_ticks_msec() / 1000.0 + float(get_instance_id() % 97)
		_model.position.y = 0.25 + sin(tt * 2.1) * 0.15
		_model.rotation.z = sin(tt * 1.3) * 0.08
	_flinch()
	_hp_bar.visible = hp < max_hp and alive
	if _hp_bar.visible:
		var f := hp / max_hp
		_hp_mat.set_shader_parameter("fill", f)


## The wind-up read from the body, [param k] 0 to 1: each kind of attack
## its own pose, held tighter and trembling as the blow comes.
func _windup_pose(k: float) -> void:
	var e := k * k * (3.0 - 2.0 * k)
	var shake := sin(Time.get_ticks_msec() / 22.0) * 0.04 * smoothstep(0.6, 1.0, k)
	var attack: String = "slam" if cfg.get("boss", false) and _wind <= 0.0 else cfg.attack
	match attack:
		"slam":
			# Up on its toes and swelling, then it comes down.
			_model.rotation.x = -0.35 * e
			_model.position.y = 0.35 * e
			_model.scale = _base_scale * Vector3(1.0 + 0.08 * e, 1.0 + 0.18 * e, 1.0 + 0.08 * e)
		"dash":
			# Crouched low and leaning in, coiled.
			_model.rotation.x = 0.35 * e
			_model.scale = _base_scale * Vector3(1.0 + 0.12 * e, 1.0 - 0.25 * e, 1.0 + 0.12 * e)
		"ranged", "lob":
			_model.rotation.x = -0.25 * e
		_:
			# Rearing back for the blow, arms up.
			_model.rotation.x = -0.6 * e
			_model.scale = _base_scale * Vector3(1.0, 1.0 + 0.1 * e, 1.0)
	_model.rotation.z += shake


var _flinch_off := Vector3.ZERO
var _flinch_rot := Vector3.ZERO


## A hit snaps the body back from where it came and lets it spring upright:
## a quick jerk away, a lean, then a small overshoot back.
func _flinch() -> void:
	_flinch_off = Vector3.ZERO
	_flinch_rot = Vector3.ZERO
	if hurt_t <= 0.0 or not alive:
		return
	var u := 1.0 - hurt_t / HURT_TIME
	# Out fast, back slower, a touch past upright at the end.
	var a := sin(minf(u * 1.6, 1.0) * PI * 0.5) * (1.0 - u) - 0.15 * sin(u * PI) * u
	var local := global_basis.inverse() * hurt_dir
	local.y = 0.0
	var k := a * hurt_k
	_flinch_off = local * 0.18 * k
	_flinch_rot = Vector3(local.z * 0.45 * k, 0.0, -local.x * 0.45 * k)
	_model.position += _flinch_off
	_model.rotation.x += _flinch_rot.x
	_model.rotation.z += _flinch_rot.z


func die(src: Actor) -> void:
	super.die(src)
	_warn_end()
	_model.position -= _flinch_off
	_model.rotation.x -= _flinch_rot.x
	_model.rotation.z -= _flinch_rot.z
	_flinch_off = Vector3.ZERO
	_flinch_rot = Vector3.ZERO
	if _aim_bar:
		_aim_bar.visible = false
	if cfg.has("raise") and Game.I:
		# Everything it raised falls apart with it.
		for e in Game.I.enemies.duplicate():
			if e.master == self and e.alive:
				e.take(e.hp + 1.0)
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	if Game.I:
		Game.I.on_enemy_died(self, src)
		Soul.drop(self)
	if cfg.get("burst", false):
		var s := _attack_spell(El.MUD, 18.0)
		var nova := NovaFx.new()
		nova.setup(self, {counts = {El.MUD: 1}, payload = [], primary = El.MUD, n = {radius = 2.6, rate = s.scale}})
		nova.only_team = 0
		Game.I.spawn(nova, global_position)
		Game.I.arena.add_field(global_position, El.MUD, 2.0, 7.0, null)
	if elite.has("el"):
		var nova2 := NovaFx.new()
		var s2 := _attack_spell(elite.el, 14.0)
		nova2.setup(self, {counts = s2.counts, payload = [], primary = elite.el, n = {radius = 2.8, rate = s2.scale}})
		nova2.only_team = 0
		Game.I.spawn(nova2, global_position)
	_death()
	_hp_bar.visible = false

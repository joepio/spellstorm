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
## Every attack shows itself while the monster winds up: where it will land
## on the floor (Telegraph), or for shots a ball of its element swelling in
## front of it. The way it will go is followed until three quarters in,
## then held, so a step or a roll at the last moment gets you out.
var _warn: Telegraph
var _orb: MeshInstance3D
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


func _build(m: String) -> void:
	match m:
		"ghoul":
			var skin := Color(0.42, 0.47, 0.38)
			_add(Art.sphere(0.32), skin, Vector3(0, 0.85, 0.05), Vector3(20, 0, 0), Vector3(1.0, 1.15, 0.8))
			_add(Art.sphere(0.2), skin.darkened(0.1), Vector3(0, 1.15, 0.28))
			_add(Art.cyl(0.05, 0.08, 0.7), skin, Vector3(0.32, 0.65, 0.25), Vector3(70, 0, -10))
			_add(Art.cyl(0.05, 0.08, 0.7), skin, Vector3(-0.32, 0.65, 0.25), Vector3(70, 0, 10))
			_add(Art.cyl(0.07, 0.09, 0.6), skin.darkened(0.2), Vector3(0.15, 0.3, 0))
			_add(Art.cyl(0.07, 0.09, 0.6), skin.darkened(0.2), Vector3(-0.15, 0.3, 0))
			_add(Art.box(0.22, 0.05, 0.12), Color(0.15, 0.02, 0.02), Vector3(0, 1.06, 0.43))
			_eye_pair(1.2, 0.44, 0.07, Color(0.9, 0.9, 0.3))
		"skeleton":
			var bone := Color(0.82, 0.78, 0.68)
			_add(Art.box(0.36, 0.5, 0.18), bone, Vector3(0, 1.05, 0))
			for i in 4:
				_add(Art.box(0.42, 0.04, 0.2), bone.darkened(0.15), Vector3(0, 0.88 + i * 0.1, 0.01))
			_add(Art.cyl(0.04, 0.04, 0.35), bone, Vector3(0, 0.66, 0))
			_add(Art.sphere(0.17), bone, Vector3(0, 1.48, 0.02), Vector3.ZERO, Vector3(1, 1.1, 1.05))
			_add(Art.box(0.2, 0.08, 0.12), bone.darkened(0.2), Vector3(0, 1.36, 0.08))
			_add(Art.cyl(0.035, 0.035, 0.7), bone, Vector3(0.28, 1.0, 0.05), Vector3(10, 0, 8))
			_add(Art.cyl(0.035, 0.035, 0.7), bone, Vector3(-0.28, 1.0, 0.05), Vector3(10, 0, -8))
			_add(Art.cyl(0.04, 0.04, 0.65), bone, Vector3(0.12, 0.33, 0))
			_add(Art.cyl(0.04, 0.04, 0.65), bone, Vector3(-0.12, 0.33, 0))
			if kind == "bone_archer":
				# A bow, not a sword, and a quiver on its back.
				var wood := Color(0.3, 0.2, 0.12)
				for sgn: float in [-1.0, 1.0]:
					_add(Art.cyl(0.025, 0.03, 0.6), wood, Vector3(0.3, 1.05 + sgn * 0.26, 0.35), Vector3(sgn * 28.0, 0, 0))
				_add(Art.cyl(0.006, 0.006, 1.0), Color(0.85, 0.85, 0.8), Vector3(0.3, 1.05, 0.2))
				_add(Art.cyl(0.07, 0.07, 0.5), wood.darkened(0.2), Vector3(-0.1, 1.15, -0.16), Vector3(-15, 0, 12))
			else:
				_add(Art.box(0.06, 0.8, 0.12), Color(0.45, 0.45, 0.48), Vector3(0.32, 0.95, 0.35), Vector3(60, 0, 0))
			_eye_pair(1.5, 0.15, 0.06, Color(1.0, 0.25, 0.1), 0.04)
		"cultist":
			var robe := Color(0.35, 0.05, 0.06)
			_add(Art.cyl(0.18, 0.45, 1.3), robe, Vector3(0, 0.65, 0))
			_add(Art.cyl(0.0, 0.24, 0.55), robe.darkened(0.2), Vector3(0, 1.5, -0.02), Vector3(-10, 0, 0))
			_add(Art.sphere(0.16), Color(0.03, 0.02, 0.02), Vector3(0, 1.35, 0.06))
			_add(Art.cyl(0.03, 0.03, 1.4), Color(0.2, 0.15, 0.1), Vector3(0.38, 0.75, 0.1))
			Art.part(_model, Art.sphere(0.1), Fx.glow(El.COLOR[El.FIRE], 4.0), Vector3(0.38, 1.5, 0.1))
			_eye_pair(1.37, 0.19, 0.055)
		"bile":
			var flesh := Color(0.48, 0.5, 0.22)
			_add(Art.sphere(0.62, 14), flesh, Vector3(0, 0.9, 0), Vector3.ZERO, Vector3(1.1, 1.0, 1.0))
			for i in 6:
				var a := i * TAU / 6.0
				_add(Art.sphere(0.18), Color(0.6, 0.65, 0.2), Vector3(cos(a) * 0.55, 0.9 + sin(i * 1.7) * 0.3, sin(a) * 0.5))
			_add(Art.sphere(0.25), flesh.darkened(0.1), Vector3(0, 1.55, 0.15))
			_add(Art.cyl(0.12, 0.15, 0.5), flesh.darkened(0.3), Vector3(0.3, 0.25, 0))
			_add(Art.cyl(0.12, 0.15, 0.5), flesh.darkened(0.3), Vector3(-0.3, 0.25, 0))
			_eye_pair(1.6, 0.36, 0.09, Color(0.9, 0.9, 0.2))
		"imp":
			var red := Color(0.6, 0.12, 0.06)
			_add(Art.sphere(0.25), red, Vector3(0, 0.65, 0), Vector3.ZERO, Vector3(1, 1.2, 0.9))
			_add(Art.sphere(0.18), red, Vector3(0, 1.0, 0.08))
			_add(Art.cyl(0.0, 0.05, 0.2), Color(0.15, 0.1, 0.08), Vector3(0.1, 1.17, 0.05), Vector3(0, 0, -25))
			_add(Art.cyl(0.0, 0.05, 0.2), Color(0.15, 0.1, 0.08), Vector3(-0.1, 1.17, 0.05), Vector3(0, 0, 25))
			_add(Art.box(0.5, 0.35, 0.03), red.darkened(0.4), Vector3(0.3, 0.8, -0.15), Vector3(0, 30, 20))
			_add(Art.box(0.5, 0.35, 0.03), red.darkened(0.4), Vector3(-0.3, 0.8, -0.15), Vector3(0, -30, -20))
			_add(Art.cyl(0.05, 0.06, 0.4), red, Vector3(0.1, 0.25, 0))
			_add(Art.cyl(0.05, 0.06, 0.4), red, Vector3(-0.1, 0.25, 0))
			_eye_pair(1.03, 0.24, 0.06, Color(1.0, 0.8, 0.1))
		"brute", "frost_brute":
			var skin := Color(0.45, 0.38, 0.32) if m == "brute" else Color(0.55, 0.65, 0.75)
			_add(Art.sphere(0.65, 12), skin, Vector3(0, 1.45, 0), Vector3(15, 0, 0), Vector3(1.2, 1.0, 0.9))
			_add(Art.sphere(0.25), skin.darkened(0.1), Vector3(0, 2.0, 0.35))
			_add(Art.cyl(0.18, 0.25, 1.2), skin, Vector3(0.75, 1.0, 0.2), Vector3(15, 0, -12))
			_add(Art.cyl(0.18, 0.25, 1.2), skin, Vector3(-0.75, 1.0, 0.2), Vector3(15, 0, 12))
			_add(Art.sphere(0.3), skin.darkened(0.2), Vector3(0.82, 0.4, 0.35))
			_add(Art.sphere(0.3), skin.darkened(0.2), Vector3(-0.82, 0.4, 0.35))
			_add(Art.cyl(0.2, 0.25, 0.8), Color(0.25, 0.18, 0.12), Vector3(0.3, 0.4, 0))
			_add(Art.cyl(0.2, 0.25, 0.8), Color(0.25, 0.18, 0.12), Vector3(-0.3, 0.4, 0))
			_add(Art.box(1.0, 0.25, 0.7), Color(0.3, 0.2, 0.14), Vector3(0, 0.9, 0))
			if m == "frost_brute":
				for i in 5:
					Art.part(_model, Art.cyl(0.0, 0.1, 0.45, 5), Fx.glow(El.COLOR[El.ICE], 1.0), Vector3(randf_range(-0.6, 0.6), 1.9, randf_range(-0.4, 0.1)), Vector3(randf_range(-30, 0), 0, randf_range(-30, 30)))
			_eye_pair(2.05, 0.57, 0.09, Color(1.0, 0.2, 0.05), 0.05)
		"wraith":
			var cloak := Color(0.08, 0.1, 0.14)
			_add(Art.cyl(0.15, 0.5, 1.4), cloak, Vector3(0, 0.95, 0))
			_add(Art.sphere(0.22), cloak.darkened(0.3), Vector3(0, 1.75, 0.02))
			var wisps := Fx.particles(Color(0.5, 0.75, 0.9, 0.5), 18, 1.0, 0.4)
			wisps.position.y = 0.3
			wisps.direction = Vector3.DOWN
			wisps.initial_velocity_max = 0.5
			_model.add_child(wisps)
			wisps.emitting = true
			_eye_pair(1.77, 0.19, 0.07, Color(0.5, 0.9, 1.0), 0.04)
		"drowned":
			var skin := Color(0.3, 0.42, 0.45)
			_add(Art.sphere(0.32), skin, Vector3(0, 0.95, 0.05), Vector3(25, 0, 0), Vector3(0.9, 1.25, 0.75))
			_add(Art.sphere(0.19), skin, Vector3(0, 1.32, 0.25))
			_add(Art.cyl(0.04, 0.07, 0.8), skin, Vector3(0.3, 0.75, 0.2), Vector3(50, 0, -10))
			_add(Art.cyl(0.04, 0.07, 0.8), skin, Vector3(-0.3, 0.75, 0.2), Vector3(50, 0, 10))
			_add(Art.cyl(0.07, 0.08, 0.6), skin.darkened(0.3), Vector3(0.14, 0.3, 0))
			_add(Art.cyl(0.07, 0.08, 0.6), skin.darkened(0.3), Vector3(-0.14, 0.3, 0))
			for i in 4:
				_add(Art.cyl(0.02, 0.03, 0.5), Color(0.15, 0.3, 0.15), Vector3(randf_range(-0.2, 0.2), 1.1, randf_range(-0.2, 0.2)), Vector3(randf_range(-20, 20), 0, randf_range(-20, 20)))
			_eye_pair(1.36, 0.42, 0.07, Color(0.4, 1.0, 0.8))
		"demon":
			var red := Color(0.45, 0.07, 0.04)
			_add(Art.sphere(0.5, 12), red, Vector3(0, 1.3, 0), Vector3(10, 0, 0), Vector3(1.1, 1.2, 0.85))
			_add(Art.sphere(0.24), red.darkened(0.1), Vector3(0, 1.95, 0.15))
			_add(Art.cyl(0.0, 0.08, 0.5), Color(0.1, 0.08, 0.06), Vector3(0.18, 2.25, 0.1), Vector3(-20, 0, -30))
			_add(Art.cyl(0.0, 0.08, 0.5), Color(0.1, 0.08, 0.06), Vector3(-0.18, 2.25, 0.1), Vector3(-20, 0, 30))
			_add(Art.cyl(0.12, 0.17, 1.0), red, Vector3(0.6, 1.1, 0.15), Vector3(20, 0, -15))
			_add(Art.cyl(0.12, 0.17, 1.0), red, Vector3(-0.6, 1.1, 0.15), Vector3(20, 0, 15))
			_add(Art.cyl(0.14, 0.18, 0.8), red.darkened(0.3), Vector3(0.25, 0.4, 0))
			_add(Art.cyl(0.14, 0.18, 0.8), red.darkened(0.3), Vector3(-0.25, 0.4, 0))
			_add(Art.box(1.3, 0.8, 0.04), Color(0.2, 0.03, 0.02), Vector3(0, 1.5, -0.45), Vector3(10, 0, 0))
			Art.part(_model, Art.sphere(0.2), Fx.glow(El.COLOR[El.FIRE], 2.5), Vector3(0, 1.4, 0.42), Vector3.ZERO, Vector3(1, 1, 0.3))
			_eye_pair(2.0, 0.36, 0.09, Color(1.0, 0.75, 0.1), 0.045)
		"watcher":
			# A big bloodshot eyeball held up by nothing, a ring of fleshy lids
			# round it and feelers hanging under it; the iris glows when it shoots.
			var flesh := Color(0.36, 0.2, 0.26)
			_add(Art.sphere(0.42, 16), Color(0.86, 0.82, 0.76), Vector3(0, 1.45, 0))
			for sgn: float in [-1.0, 1.0]:
				_add(Art.sphere(0.46, 14), flesh, Vector3(0, 1.45 + sgn * 0.2, -0.06), Vector3(sgn * -35.0, 0, 0), Vector3(1.0, 0.45, 0.95))
			for i in 7:
				var a := i * TAU / 7.0
				_add(Art.sphere(0.07, 6), Color(0.6, 0.12, 0.12), Vector3(cos(a) * 0.3, 1.45 + sin(a) * 0.3, 0.3 + randf() * 0.04), Vector3.ZERO, Vector3(1.6, 0.4, 0.4))
			for i in 5:
				var a2 := i * TAU / 5.0 + 0.3
				_add(Art.cyl(0.05, 0.015, 0.75, 5), flesh.darkened(0.25), Vector3(cos(a2) * 0.2, 0.85, sin(a2) * 0.2 - 0.05), Vector3(randf_range(-18, 18), 0, randf_range(-18, 18)))
			var iris := Art.part(_model, Art.cyl(0.2, 0.2, 0.04, 16), Fx.glow(El.COLOR[El.VOID], 2.5), Vector3(0, 1.45, 0.4), Vector3(90, 0, 0))
			_eyes.append(iris)
			_add(Art.cyl(0.09, 0.09, 0.05, 12), Color(0.02, 0.0, 0.03), Vector3(0, 1.45, 0.42), Vector3(90, 0, 0))
			_model.add_child(Fx.halo(El.COLOR[El.VOID], 1.2, 0.5, 1.0))
			_model.get_child(-1).position = Vector3(0, 1.45, 0.3)
		"necromancer":
			# Tall, thin, hooded in rotten green, a skull on a long staff.
			var robe2 := Color(0.12, 0.17, 0.1)
			_add(Art.cyl(0.14, 0.42, 1.5), robe2, Vector3(0, 0.75, 0))
			_add(Art.cyl(0.0, 0.22, 0.6), robe2.darkened(0.25), Vector3(0, 1.72, -0.03), Vector3(-12, 0, 0))
			_add(Art.sphere(0.15), Color(0.02, 0.02, 0.02), Vector3(0, 1.56, 0.07))
			_add(Art.box(0.5, 0.12, 0.3), robe2.darkened(0.4), Vector3(0, 1.3, 0))
			_add(Art.cyl(0.025, 0.03, 1.9), Color(0.18, 0.14, 0.1), Vector3(0.4, 0.95, 0.12))
			_add(Art.sphere(0.12), Color(0.82, 0.78, 0.68), Vector3(0.4, 1.95, 0.12), Vector3.ZERO, Vector3(1, 1.1, 1.1))
			Art.part(_model, Art.sphere(0.07), Fx.glow(Color(0.5, 1.0, 0.5), 4.0), Vector3(0.4, 1.95, 0.22))
			var motes := Fx.particles(Color(0.45, 1.0, 0.5, 0.6), 14, 1.2, 0.1)
			motes.position = Vector3(0.4, 1.95, 0.12)
			motes.direction = Vector3.UP
			motes.initial_velocity_max = 0.4
			motes.gravity = Vector3.UP * 0.4
			_model.add_child(motes)
			motes.emitting = true
			_eye_pair(1.58, 0.2, 0.05, Color(0.45, 1.0, 0.45))
		"lurker":
			# A hunched burrower: a plated back, a blunt snout, big digging claws.
			var shell := Color(0.3, 0.22, 0.15)
			_add(Art.sphere(0.55, 10), shell, Vector3(0, 0.6, -0.05), Vector3(-15, 0, 0), Vector3(1.0, 0.75, 1.2))
			for i in 4:
				_add(Art.box(0.9 - i * 0.1, 0.08, 0.28), shell.darkened(0.3), Vector3(0, 0.98 - i * 0.07, -0.35 + i * 0.25), Vector3(-20 + i * 14, 0, 0))
			_add(Art.sphere(0.24), Color(0.45, 0.33, 0.25), Vector3(0, 0.55, 0.55), Vector3.ZERO, Vector3(1, 0.8, 1.2))
			for sgn: float in [-1.0, 1.0]:
				_add(Art.cyl(0.07, 0.1, 0.5), shell, Vector3(sgn * 0.48, 0.4, 0.35), Vector3(60, 0, sgn * -20))
				for k in 3:
					_add(Art.cyl(0.0, 0.04, 0.25, 4), Color(0.85, 0.8, 0.7), Vector3(sgn * (0.52 + k * 0.05), 0.2, 0.6), Vector3(80, 0, 0))
			_eye_pair(0.68, 0.72, 0.1, Color(1.0, 0.6, 0.1), 0.03)
		"sprite":
			# A knot of lightning: a bright core, a crackling shell, sparks.
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
		"toad":
			var skin2 := Color(0.3, 0.36, 0.16)
			_add(Art.sphere(0.55, 12), skin2, Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.15, 0.8, 1.1))
			_add(Art.sphere(0.4, 10), Color(0.62, 0.6, 0.36), Vector3(0, 0.35, 0.22), Vector3.ZERO, Vector3(1.1, 0.6, 0.9))
			_add(Art.box(0.7, 0.04, 0.12), Color(0.12, 0.05, 0.05), Vector3(0, 0.55, 0.6))
			for sgn: float in [-1.0, 1.0]:
				_add(Art.sphere(0.13), skin2.darkened(0.1), Vector3(sgn * 0.25, 0.92, 0.32))
				_add(Art.sphere(0.2), skin2.darkened(0.2), Vector3(sgn * 0.5, 0.18, -0.25), Vector3.ZERO, Vector3(1, 0.6, 1.5))
				_add(Art.sphere(0.12), skin2.darkened(0.2), Vector3(sgn * 0.35, 0.1, 0.45), Vector3.ZERO, Vector3(1.3, 0.5, 1))
			for i in 7:
				_add(Art.sphere(0.06, 5), Color(0.42, 0.3, 0.12), Vector3(randf_range(-0.45, 0.45), 0.75 + randf() * 0.1, randf_range(-0.3, 0.2)))
			_eye_pair(0.97, 0.4, 0.25, Color(1.0, 0.75, 0.1), 0.05)
		"shieldbearer":
			# Rusted plate, a slit helm, a tower shield and a short mace.
			var steel := Color(0.36, 0.36, 0.38)
			_add(Art.box(0.55, 0.65, 0.35), steel, Vector3(0, 1.15, 0))
			_add(Art.cyl(0.2, 0.25, 0.4), steel.darkened(0.2), Vector3(0, 0.7, 0))
			_add(Art.cyl(0.18, 0.2, 0.38), steel.lightened(0.1), Vector3(0, 1.68, 0.02))
			_add(Art.box(0.25, 0.03, 0.05), Color(0.02, 0.02, 0.02), Vector3(0, 1.7, 0.2))
			for sgn: float in [-1.0, 1.0]:
				_add(Art.cyl(0.08, 0.1, 0.65), steel.darkened(0.3), Vector3(sgn * 0.15, 0.32, 0))
				_add(Art.sphere(0.15), steel.lightened(0.05), Vector3(sgn * 0.36, 1.42, 0))
			_add(Art.cyl(0.04, 0.04, 0.6), Color(0.25, 0.18, 0.1), Vector3(-0.42, 0.9, 0.15), Vector3(50, 0, 0))
			_add(Art.sphere(0.12, 6), steel.darkened(0.4), Vector3(-0.42, 1.12, 0.38))
			_shield = Node3D.new()
			_shield.position = Vector3(0.12, 0, 0.42)
			_model.add_child(_shield)
			var wood2 := Color(0.28, 0.18, 0.1)
			meshes.append(Art.part(_shield, Art.box(0.85, 1.35, 0.08), Fx.solid(wood2, 0.9), Vector3(0, 0.95, 0)))
			meshes.append(Art.part(_shield, Art.box(0.92, 0.08, 0.1), Fx.solid(steel, 0.5), Vector3(0, 1.6, 0)))
			meshes.append(Art.part(_shield, Art.box(0.92, 0.08, 0.1), Fx.solid(steel, 0.5), Vector3(0, 0.3, 0)))
			meshes.append(Art.part(_shield, Art.sphere(0.12, 8), Fx.solid(steel.lightened(0.2), 0.4), Vector3(0, 0.95, 0.05), Vector3.ZERO, Vector3(1, 1, 0.5)))
		"hellhound":
			# Low and long, ribs glowing through cracked black hide.
			var hide := Color(0.1, 0.06, 0.05)
			_add(Art.sphere(0.35, 10), hide, Vector3(0, 0.62, 0), Vector3(90, 0, 0), Vector3(0.85, 1.6, 0.85))
			_add(Art.sphere(0.24, 8), hide, Vector3(0, 0.78, 0.55), Vector3.ZERO, Vector3(0.9, 0.85, 1.3))
			_add(Art.box(0.2, 0.1, 0.25), hide.darkened(0.2), Vector3(0, 0.7, 0.8))
			for sgn: float in [-1.0, 1.0]:
				_add(Art.cyl(0.0, 0.06, 0.2), hide, Vector3(sgn * 0.12, 0.98, 0.5), Vector3(-25, 0, sgn * -20))
				_add(Art.cyl(0.05, 0.07, 0.55), hide, Vector3(sgn * 0.2, 0.28, 0.35))
				_add(Art.cyl(0.05, 0.07, 0.55), hide, Vector3(sgn * 0.2, 0.28, -0.35))
			Art.part(_model, Art.box(0.3, 0.08, 0.6), Fx.element(El.MAGMA, 1.4), Vector3(0, 0.82, 0))
			Art.part(_model, Art.cyl(0.03, 0.06, 0.5), Fx.element(El.FIRE, 1.4), Vector3(0, 0.75, -0.7), Vector3(-60, 0, 0))
			_eye_pair(0.85, 0.75, 0.08, Color(1.0, 0.55, 0.1), 0.035)
		_:
			_add(Art.sphere(0.4), Color.MAGENTA, Vector3(0, 0.8, 0))


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
	var attack: String = cfg.attack
	match attack:
		"melee", "burrow":
			_warn = Telegraph.slice(cfg.reach + 0.6 + radius, MELEE_ARC)
		"slam":
			_warn = Telegraph.slice(cfg.reach + 0.8 + radius)
		"dash":
			_warn = Telegraph.lane(radius * 2.0 + 0.5, cfg.dash[0] * cfg.dash[1] + radius)
		_:
			_orb = Fx.halo(El.COLOR[elite.get("el", cfg.el)], 0.5, 0.9, 1.0)
			add_child(_orb)
	_warning(0.0)


## The wind-up shown, [param k] from 0 to 1.
func _warning(k: float) -> void:
	if k < 0.75:
		_lock = _aim()
	if _warn:
		_warn.place(global_position, _lock)
		_warn.set_fill(k)
	if _orb:
		_orb.global_position = global_position + _lock * (radius + 0.35) + Vector3.UP * 1.0
		_orb.scale = Vector3.ONE * (0.4 + 1.1 * k)


func _warn_end() -> void:
	if _warn and is_instance_valid(_warn):
		_warn.finish()
	_warn = null
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
		# Shown first like every attack: the nova's full reach on the floor,
		# a pattern of bullets as a ring round the boss and a glint.
		Fx.flash(global_position + Vector3.UP * (1.3 * float(cfg.size) + 0.4), Color(1.0, 0.85, 0.55), 1.2, 0.3)
		var warn := Telegraph.slice(7.0 if pattern == "nova" else radius + 1.5)
		warn.place(global_position, Vector3.FORWARD)
		var tw := warn.create_tween()
		tw.tween_method(warn.set_fill, 0.0, 1.0, BOSS_WIND)
		tw.tween_callback(warn.finish)
		_later(BOSS_WIND, func(): if alive: _boss_pattern(pattern, el, dmg))
	if _summon_t <= 0.0:
		_summon_t = randf_range(10.0, 14.0)
		for k in cfg.summon:
			Game.I.run.spawn_enemy(k, global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), false)


const BOSS_WIND := 0.8


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
	var warn := Telegraph.slice(1.6)
	warn.place(at, Vector3.FORWARD)
	warn.create_tween().tween_method(warn.set_fill, 0.0, 1.0, flight)
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
		warn.finish()
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
		_warn = Telegraph.slice(1.9 + 0.3)
		_warn.place(global_position, Vector3.FORWARD)
		_warn.create_tween().tween_method(_warn.set_fill, 0.0, 1.0, 0.7)
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
	if _wind > 0.0:
		# Rearing back for the blow, further the closer it comes.
		_model.rotation.x = -0.45 * (1.0 - _wind / _wind_time())
	else:
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, 10.0 * dt)
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

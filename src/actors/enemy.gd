class_name Enemy
extends Actor
## A monster. Every kind is a row in KINDS; bosses are kinds with a "boss" key.

const KINDS := {
	ghoul = {name = "Ghoul", hp = 40.0, speed = 4.3, dmg = 9.0, reach = 1.3, el = El.EARTH, size = 0.9, attack = "melee"},
	skeleton = {name = "Skeleton", hp = 50.0, speed = 3.3, dmg = 10.0, reach = 1.4, el = El.EARTH, size = 1.0, attack = "melee", undead = true, resist = {El.FROST: 0.3, El.EARTH: -0.3, El.VOID: 0.5}},
	archer = {name = "Skeleton Archer", hp = 34.0, speed = 3.0, dmg = 9.0, reach = 10.0, keep = 8.0, el = El.EARTH, size = 1.0, attack = "ranged", undead = true, resist = {El.FROST: 0.3, El.EARTH: -0.3}},
	cultist = {name = "Cultist", hp = 42.0, speed = 3.0, dmg = 11.0, reach = 9.0, keep = 7.0, el = El.FIRE, size = 1.0, attack = "ranged", resist = {El.FIRE: 0.6}},
	bile = {name = "Bile Horror", hp = 95.0, speed = 2.1, dmg = 12.0, reach = 1.5, el = El.WATER, size = 1.25, attack = "melee", mass = 2.0, resist = {El.WATER: 1.0, El.EARTH: 0.2}, burst = true},
	imp = {name = "Imp", hp = 30.0, speed = 5.2, dmg = 8.0, reach = 7.0, keep = 5.0, el = El.FIRE, size = 0.7, attack = "ranged", heals_from = El.FIRE, resist = {El.FROST: -0.5, El.WATER: -0.5}},
	brute = {name = "Brute", hp = 240.0, speed = 2.7, dmg = 24.0, reach = 2.2, el = El.EARTH, size = 1.7, attack = "slam", mass = 3.5, resist = {El.EARTH: 0.3}},
	frost_brute = {name = "Frost Brute", hp = 260.0, speed = 2.5, dmg = 22.0, reach = 2.2, el = El.FROST, size = 1.7, attack = "slam", mass = 3.5, resist = {El.FROST: 0.9, El.FIRE: -0.4}},
	wraith = {name = "Wraith", hp = 45.0, speed = 3.8, dmg = 10.0, reach = 8.0, keep = 6.0, el = El.FROST, size = 1.0, attack = "ranged", undead = true, resist = {El.FROST: 1.0, El.EARTH: 0.5}},
	drowned = {name = "Drowned", hp = 55.0, speed = 3.1, dmg = 11.0, reach = 1.4, el = El.WATER, size = 1.0, attack = "melee", resist = {El.WATER: 1.0, El.FIRE: 0.4}, always_wet = true},
	demon = {name = "Demon", hp = 130.0, speed = 3.5, dmg = 16.0, reach = 1.7, el = El.FIRE, size = 1.35, attack = "melee", mass = 2.0, resist = {El.FIRE: 1.0, El.FROST: -0.3}},
	# Bosses: one per biome, the last room of it.
	gravekeeper = {name = "The Gravekeeper", model = "skeleton", hp = 1100.0, speed = 2.6, dmg = 26.0, reach = 2.6, el = El.EARTH, size = 2.3, attack = "slam", mass = 8.0, undead = true, resist = {El.VOID: 0.8, El.FROST: 0.3}, boss = true, summon = ["skeleton", "skeleton", "archer"], nova = El.VOID},
	abbot = {name = "The Bloated Abbot", model = "bile", hp = 1300.0, speed = 2.0, dmg = 26.0, reach = 2.6, el = El.WATER, size = 2.4, attack = "slam", mass = 8.0, resist = {El.WATER: 1.0}, boss = true, summon = ["cultist", "ghoul", "ghoul"], nova = El.MUD},
	drowned_king = {name = "The Drowned King", model = "drowned", hp = 1400.0, speed = 2.6, dmg = 26.0, reach = 2.6, el = El.WATER, size = 2.3, attack = "slam", mass = 8.0, resist = {El.WATER: 1.0, El.FIRE: 0.5}, boss = true, summon = ["drowned", "drowned", "bile"], nova = El.WATER, always_wet = true},
	warden = {name = "The Frost Warden", model = "frost_brute", hp = 1600.0, speed = 2.4, dmg = 30.0, reach = 2.8, el = El.FROST, size = 2.4, attack = "slam", mass = 9.0, resist = {El.FROST: 1.0, El.FIRE: -0.3}, boss = true, summon = ["wraith", "wraith", "skeleton"], nova = El.ICE},
	pit_lord = {name = "The Pit Lord", model = "demon", hp = 2200.0, speed = 2.8, dmg = 34.0, reach = 3.0, el = El.FIRE, size = 2.6, attack = "slam", mass = 10.0, resist = {El.FIRE: 1.0, El.FROST: -0.3}, boss = true, summon = ["imp", "imp", "demon"], nova = El.MAGMA},
}

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
var _label: Label3D
var _hp_bar: MeshInstance3D


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
		_label = Label3D.new()
		_label.text = cfg.name if cfg.get("boss", false) else elite_name
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.no_depth_test = true
		_label.font = Art.title_font()
		_label.font_size = 40 if cfg.get("boss", false) else 30
		_label.outline_size = 10
		_label.outline_modulate = Color(0, 0, 0, 0.9)
		_label.modulate = Color(1.0, 0.75, 0.3) if cfg.get("boss", false) else Color(0.45, 0.6, 1.0)
		_label.pixel_size = 0.006
		_label.position = Vector3(0, 2.2 * cfg.size + 0.5, 0)
		add_child(_label)
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
	q.size = Vector2(1.0, 0.08)
	_hp_bar.mesh = q
	_hp_bar.material_override = Fx.glow(Color(0.8, 0.05, 0.05), 1.0)
	(_hp_bar.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bar.position = Vector3(0, 1.95 * cfg.size + 0.15, 0)
	_hp_bar.visible = false
	_hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hp_bar)
	if cfg.get("always_wet", false):
		wet = 999.0
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
			if kind == "archer":
				_add(Art.cyl(0.02, 0.02, 1.1), Color(0.35, 0.22, 0.1), Vector3(-0.38, 1.0, 0.25), Vector3(0, 0, 10))
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
		_:
			_add(Art.sphere(0.4), Color.MAGENTA, Vector3(0, 0.8, 0))


func _physics_process(dt: float) -> void:
	tick_status(dt)
	if not alive:
		return
	if Game.I and Game.I.paused_play:
		return
	_think -= dt
	_cool = maxf(0.0, _cool - dt)
	if _think <= 0.0 or target == null or not target.alive:
		_think = 0.5
		target = _pick_target()
	var want := Vector3.ZERO
	if target and can_act():
		var to := target.global_position - global_position
		to.y = 0
		var d := to.length()
		var dir := to / maxf(d, 0.01)
		var reach: float = cfg.reach + target.radius
		if _wind > 0.0:
			_wind -= dt
			_tell(1.0 - _wind / _wind_time())
			if _wind <= 0.0:
				_strike()
		elif cfg.attack == "ranged":
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
	drive(want * move_speed(), dt)
	_animate(dt)


func _wind_time() -> float:
	return 0.9 if cfg.attack == "slam" else (0.6 if cfg.attack == "ranged" else 0.45)


func _begin() -> void:
	_wind = _wind_time()


func _tell(k: float) -> void:
	for e in _eyes:
		e.scale = Vector3.ONE * (1.0 + k * 1.5)


func _attack_spell(el: int, dmg: float) -> Dictionary:
	var e: float = El.EFFECT[el].get("dmg", 8.0)
	return {counts = {el: 1}, payload = [], primary = el, scale = dmg / e}


func _strike() -> void:
	_tell(0.0)
	_cool = randf_range(1.2, 1.8) if cfg.attack != "slam" else 2.2
	if target == null:
		return
	var dmg: float = cfg.dmg * (Game.I.monster_damage if Game.I else 1.0)
	var el: int = elite.get("el", cfg.el)
	var s := _attack_spell(el, dmg)
	match cfg.attack:
		"melee":
			var to := target.global_position - global_position
			to.y = 0
			if to.length() <= cfg.reach + target.radius + 0.6:
				var dealt := target.hit_spell(s, s.scale, self, to.normalized(), 1.0)
				if elite.has("leech"):
					hp = minf(max_hp, hp + dealt * elite.leech)
				_model.position = to.normalized() * 0.3
				create_tween().tween_property(_model, "position", Vector3.ZERO, 0.2)
		"slam":
			var r: float = cfg.reach + 0.8
			Fx.ring(global_position, El.COLOR[el].lerp(Color(0.6, 0.5, 0.4), 0.5), r, 0.3)
			Fx.burst(global_position + (target.global_position - global_position).normalized() * 1.2, Color(0.5, 0.4, 0.3), 20, 5.0)
			if Game.I:
				Game.I.shake(0.3 if not cfg.get("boss", false) else 0.6)
			for w in (Game.I.wizards if Game.I else []):
				var to: Vector3 = w.global_position - global_position
				to.y = 0
				if w.alive and to.length() < r + w.radius:
					w.hit_spell(s, s.scale, self, to.normalized(), 1.0)
		"ranged":
			var bolt := ProjectileFx.new()
			var spell := {counts = {el: 1}, payload = [], primary = el, n = {speed = 11.0, radius = 0.18, rate = s.scale, splash = 0.0, pierce = false}}
			bolt.setup(self, spell)
			bolt.hostile_only = true
			var dir := (target.global_position - global_position)
			dir.y = 0
			bolt.launch(dir.normalized(), 0.375)
			if Game.I:
				Game.I.spawn(bolt, global_position + Vector3.UP * 1.1 + dir.normalized() * 0.6)


func _boss(dt: float) -> void:
	_special -= dt
	_summon_t -= dt
	if _special <= 0.0 and can_act():
		_special = randf_range(5.0, 7.0)
		var el: int = cfg.nova
		var s := _attack_spell(el, cfg.dmg * 0.7 * (Game.I.monster_damage if Game.I else 1.0))
		var nova := NovaFx.new()
		nova.setup(self, {counts = s.counts, payload = [], primary = el, n = {radius = 7.0, rate = s.scale}})
		nova.only_team = 0
		Game.I.spawn(nova, global_position)
		Game.I.shake(0.5)
	if _summon_t <= 0.0:
		_summon_t = randf_range(10.0, 14.0)
		for k in cfg.summon:
			Game.I.run.spawn_enemy(k, global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), false)


func _pick_target() -> Actor:
	var best: Actor = null
	var bd := INF
	for w in (Game.I.wizards if Game.I else []):
		if not w.alive:
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
	var moving := velocity.length() > 0.4
	_walk += dt * (8.0 if moving else 0.0) * speed / 3.0
	_model.position.y = absf(sin(_walk)) * 0.06
	_model.rotation.z = sin(_walk) * 0.06
	if _wind > 0.0:
		_model.rotation.x = -0.25 * (1.0 - _wind / _wind_time())
	else:
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, 10.0 * dt)
	if kind == "wraith" or cfg.get("model", "") == "wraith":
		_model.position.y = 0.3 + sin(Time.get_ticks_msec() / 400.0) * 0.1
	_hp_bar.visible = hp < max_hp and alive
	if _hp_bar.visible:
		var f := hp / max_hp
		_hp_bar.scale = Vector3(maxf(f, 0.02) * (1.0 + cfg.size * 0.3), 1, 1)


func take(dmg: float, src: Actor = null) -> void:
	super.take(dmg, src)
	if alive and dmg > 3.0 and Game.I:
		Game.I.damage_number(global_position + Vector3.UP * (1.8 * cfg.size), dmg)


func die(src: Actor) -> void:
	super.die(src)
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	Fx.burst(global_position + Vector3.UP * 0.8, Color(0.55, 0.03, 0.03), 26 + int(cfg.size * 10), 5.0, 0.3)
	if Game.I:
		Game.I.on_enemy_died(self, src)
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
	# Collapse into a heap.
	var tw := create_tween()
	tw.tween_property(_model, "rotation:x", -PI / 2.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(_model, "position:y", 0.1, 0.35)
	tw.tween_interval(1.5)
	tw.tween_property(_model, "position:y", -1.5, 1.2)
	tw.tween_callback(queue_free)
	if _label:
		_label.queue_free()
	_hp_bar.visible = false

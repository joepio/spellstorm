class_name Bullet
extends Node3D
## A monster's bullet: a small shot made of its element, shaped by it (fire
## a comet with a tail, frost a shard, water a drop, earth a tumbling rock,
## lightning a crackling spark), wearing the same element shader as the
## wizards' spells (bullet.gdshader). Monsters fire them in patterns (fans,
## rings, spirals, see Enemy). A wizard's staff swing knocks one back, and
## then it turns gold and hurts monsters.

static var all: Array[Bullet] = []
static var _meshes := {}
static var _mats := {}

var vel := Vector3.ZERO
## {counts, payload, primary, scale}, as Enemy._attack_spell makes it.
var spell: Dictionary
var src: Actor
var team := 1
var radius := 0.22
var life := 7.0
var power := 1.0
var _shell: MeshInstance3D


static func fire(from: Actor, at: Vector3, dir: Vector3, speed: float, s: Dictionary, size := 0.22) -> Bullet:
	var b := Bullet.new()
	b.src = from
	b.team = from.team
	b.spell = s
	b.radius = size
	b.vel = dir.normalized() * speed
	if Game.I:
		Game.I.spawn(b, Vector3(at.x, 1.0, at.z))
		Game.I.count("bullets")
	return b


static func _sphere(r: float) -> SphereMesh:
	var k := snappedf(r, 0.01)
	if not _meshes.has(k):
		_meshes[k] = Art.sphere(k, 10)
	return _meshes[k]


## The look of one element's bullets, shared by all of them; [param hot]
## for one a wizard knocked back.
static func material(e: int, hot := false) -> ShaderMaterial:
	var key := "%d%s" % [e, "h" if hot else ""]
	if not _mats.has(key):
		# Pale elements burn out to white at full strength: keep them icy.
		var energy := 0.85 if e in [El.FROST, El.ICE, El.AIR, El.STEAM] else 1.3
		_mats[key] = Fx.shader("bullet", {element = e, base = El.COLOR[e], hot = 1.0 if hot else 0.0, energy = energy})
	return _mats[key]


## The soft fading tail of one element's fiery shots (trail.gdshader).
static func _tail_material(e: int) -> ShaderMaterial:
	var key := "t%d" % e
	if not _mats.has(key):
		_mats[key] = Fx.shader("trail", {color = El.COLOR[e]})
	return _mats[key]


static func _mesh(kind: String, r: float) -> Mesh:
	var key := "%s%.2f" % [kind, r]
	if not _meshes.has(key):
		match kind:
			"shard":
				_meshes[key] = Art.cyl(0.0, r * 0.7, r * 3.8, 5)
			"rock":
				_meshes[key] = Art.sphere(r, 5)
			"tail":
				_meshes[key] = Art.cyl(0.0, r * 0.9, r * 3.0, 12)
			"arrow":
				_meshes[key] = Art.cyl(r * 0.18, r * 0.18, r * 7.0, 5)
			_:
				_meshes[key] = Art.sphere(r, 12)
	return _meshes[key]


func _ready() -> void:
	all.append(self)
	var e: int = spell.primary
	# Drawn a little smaller than it hits, and a lot smaller than before
	# (Joep): the rim keeps it readable.
	var r := radius * 0.72
	_shell = MeshInstance3D.new()
	_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shell.material_override = material(e)
	add_child(_shell)
	if spell.get("arrow", false):
		# A bone archer's arrow: a long thin shaft with a pale head.
		_shell.mesh = _mesh("arrow", r)
		_shell.rotation_degrees.x = -90.0
		var head := Art.part(_shell, Art.cyl(0.0, r * 0.5, r * 1.4, 5), Fx.glow(Color(1.0, 0.9, 0.75), 2.0), Vector3(0, r * 4.0, 0))
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_face()
		return
	match e:
		El.FROST, El.ICE:
			_shell.mesh = _mesh("shard", r * 0.8)
			_shell.rotation_degrees.x = -90.0
		El.EARTH, El.MUD:
			_shell.mesh = _mesh("rock", r)
			_spin = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		El.WATER:
			_shell.mesh = _mesh("ball", r)
			_shell.scale = Vector3(0.85, 0.85, 1.35)
		El.LIGHTNING, El.STORM:
			_shell.mesh = _mesh("ball", r * 0.8)
			_crackle = true
		_:
			_shell.mesh = _mesh("ball", r)
	if e in [El.FIRE, El.MAGMA, El.VOID, El.STEAM]:
		# A tail streaming out behind it.
		var tail := MeshInstance3D.new()
		tail.mesh = _mesh("tail", r)
		tail.material_override = _tail_material(e)
		tail.rotation_degrees.x = 90.0
		tail.position.z = r * 1.9
		tail.scale = Vector3(0.8, 1.3, 0.8)
		tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tail)
	_face()


var _spin := Vector3.ZERO
var _crackle := false


## Point along the flight: -z is forward, so shards and tails line up.
func _face() -> void:
	if vel.length() > 0.01:
		basis = Basis.looking_at(vel.normalized(), Vector3.UP)


func _exit_tree() -> void:
	all.erase(self)


## Knocked back by [param by]'s staff: it flies where they aim, faster and
## harder, and now only hurts monsters.
func deflect(by: Actor, dir: Vector3) -> void:
	src = by
	team = by.team
	vel = dir.normalized() * maxf(vel.length() * 1.6, 12.0)
	power = 2.0
	life = 2.0
	_shell.material_override = material(spell.primary, true)
	_face()
	Fx.burst(global_position, Color(1.0, 0.85, 0.4), 8, 3.0, 0.2)


func _physics_process(dt: float) -> void:
	if Game.I and Game.I.paused_play:
		return
	life -= dt
	if life <= 0.0:
		_pop(false)
		return
	var from := global_position
	var to := from + vel * dt
	if Game.I and Game.I.arena.ray(from, to):
		_pop(true)
		return
	global_position = to
	if _spin != Vector3.ZERO:
		_shell.rotate(_spin, dt * 9.0)
	elif _crackle:
		_shell.scale = Vector3.ONE * randf_range(0.7, 1.25)
	for a in (Game.I.living() if Game.I else []):
		if not a.alive or a.team == team or a.invuln > 0.0:
			continue
		var d := Vector2(a.global_position.x - to.x, a.global_position.z - to.z).length()
		if d < a.radius + radius:
			if Game.I:
				Game.I.count("bullet_hits" if team == 1 else "deflect_hits")
			a.hit_spell(spell, spell.scale * power, src if is_instance_valid(src) else null, vel.normalized(), 1.0)
			_pop(true)
			return


func _pop(show: bool) -> void:
	set_physics_process(false)
	if show:
		Fx.burst(global_position, El.COLOR[spell.primary], 8, 3.0, 0.2)
	queue_free()

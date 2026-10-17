class_name Bullet
extends Node3D
## A monster's bullet: a slow, bright orb with a white core, easy to read and
## to dodge. Monsters fire them in patterns (fans, rings, spirals, see Enemy).
## A wizard's staff swing knocks one back, and then it hurts monsters.

static var all: Array[Bullet] = []
static var _meshes := {}
static var _core_mat: StandardMaterial3D
static var _gold_mat: StandardMaterial3D

var vel := Vector3.ZERO
## {counts, payload, primary, scale}, as Enemy._attack_spell makes it.
var spell: Dictionary
var src: Actor
var team := 1
var radius := 0.22
var life := 7.0
var power := 1.0
var _shell: MeshInstance3D
var _core: MeshInstance3D


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


func _ready() -> void:
	all.append(self)
	if _core_mat == null:
		_core_mat = Fx.glow(Color(1, 0.97, 0.9), 4.0)
		_gold_mat = Fx.glow(Color(1.0, 0.82, 0.35), 4.0)
	# A white-hot core in a glowing shell of the element's colour, with a
	# faint halo: bright enough to read on every floor.
	var c: Color = El.COLOR[spell.primary]
	_shell = MeshInstance3D.new()
	_shell.mesh = _sphere(radius)
	_shell.material_override = _glass(c, 0.85)
	_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shell)
	var halo := MeshInstance3D.new()
	halo.mesh = _sphere(radius * 1.8)
	halo.material_override = _glass(c, 0.22)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	_core = MeshInstance3D.new()
	_core.mesh = _sphere(radius * 0.5)
	_core.material_override = _core_mat
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_core)


static var _glass_mats := {}


static func _glass(c: Color, alpha: float) -> StandardMaterial3D:
	var key := "%s%.2f" % [c.to_html(), alpha]
	if not _glass_mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(minf(c.r * 1.4, 1.0), minf(c.g * 1.4, 1.0), minf(c.b * 1.4, 1.0), alpha)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glass_mats[key] = m
	return _glass_mats[key]


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
	_core.material_override = _gold_mat
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

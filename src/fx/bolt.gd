class_name BoltFx
extends Node3D
## One staff bolt, the shot that fires while the right stick aims. Small, fast
## and of one element, so it brings that element's status: fire burns, frost
## chills, water soaks, lightning shocks. Life bolts fly through the living
## and heal friends instead.

const SPEED := 22.0
const LIFE := 0.85

static var _mesh: SphereMesh

var caster: Wizard
var el := El.FIRE
var scale_k := 0.5
var vel := Vector3.ZERO
var spell: Dictionary
var t := 0.0


func setup(w: Wizard, e: int, k: float, dir: Vector3) -> BoltFx:
	caster = w
	el = e
	scale_k = k
	vel = dir.normalized() * SPEED
	spell = {counts = {e: 1}, payload = [], primary = e, n = {}}
	return self


func _ready() -> void:
	if _mesh == null:
		_mesh = Art.sphere(0.13, 8)
	var m := MeshInstance3D.new()
	m.mesh = _mesh
	m.material_override = Fx.glow(El.COLOR[el].lightened(0.2), 3.5)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = Vector3(1, 1, 2.4)
	add_child(m)
	look_at(global_position + vel, Vector3.UP)


func _physics_process(dt: float) -> void:
	t += dt
	if t > LIFE:
		_end(global_position)
		return
	var from := global_position
	var to := from + vel * dt
	var wall: Dictionary = Game.I.arena.ray(from, to) if Game.I else {}
	if wall:
		if wall.collider and wall.collider.has_method("damage") and el != El.LIFE:
			wall.collider.damage(2.0)
		_end(wall.position)
		return
	global_position = to
	for a in (Game.I.living() if Game.I else []):
		if a == caster:
			continue
		var friend: bool = a.team == caster.team
		if el == El.LIFE:
			if not friend and not a.undead:
				continue
		elif friend or not a.alive:
			continue
		if friend and a.alive and a.hp >= a.max_hp:
			continue
		var d := Vector2(a.global_position.x - to.x, a.global_position.z - to.z).length()
		if d < a.radius + 0.18:
			a.hit_spell(spell, scale_k, caster, vel.normalized(), 1.0)
			if not friend:
				caster.add_mana(Wizard.MANA_PER_BOLT)
			Fx.burst(to, El.COLOR[el], 5, 2.5, 0.15)
			_end(to)
			return


func _end(at: Vector3) -> void:
	set_physics_process(false)
	# A bolt that lands still touches the ground: fire bolts boil puddles.
	if Game.I and Game.I.arena:
		Game.I.arena.touch_ground(Vector3(at.x, 0, at.z), 0.5, el, caster)
	queue_free()

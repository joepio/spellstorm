class_name Globe
extends Node3D
## A red globe of health, Diablo style: the only way to heal. Monsters drop
## them (elites and bosses always, see drop()), and so do broken coffins.
## Walk over one to take it; close by it rolls to you, and a wizard with full
## health leaves it for the others.

const HEAL := 45.0
const MAGNET := 2.2
const TAKE := 0.8
const LIFE := 30.0
const COLOR := Color(0.9, 0.06, 0.05)

static var all: Array[Globe] = []
static var _mat: StandardMaterial3D

var vel := Vector3.ZERO
var t := 0.0
var _body: Node3D


## Leave [param n] globes round [param at], rolling out a little.
static func drop(at: Vector3, n := 1) -> void:
	if not Game.I:
		return
	for i in n:
		var g := Globe.new()
		var a := randf() * TAU
		g.vel = Vector3(cos(a), 0, sin(a)) * (randf_range(1.0, 3.0) if n > 1 or i > 0 else 0.5)
		Game.I.spawn(g, Vector3(at.x, 0, at.z))


func _ready() -> void:
	all.append(self)
	if _mat == null:
		_mat = Fx.glow(Color(0.85, 0.05, 0.05), 2.5)
	_body = Node3D.new()
	_body.position.y = 0.5
	add_child(_body)
	var core := MeshInstance3D.new()
	core.mesh = Art.sphere(0.17, 10)
	core.material_override = _mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(core)
	_body.add_child(Fx.halo(COLOR, 1.1, 0.7, 0.3))
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.12, 0.1)
	l.light_energy = 0.8
	l.omni_range = 2.2
	add_child(l)
	l.position.y = 0.6


func _exit_tree() -> void:
	all.erase(self)


func _physics_process(dt: float) -> void:
	t += dt
	if t > LIFE:
		queue_free()
		return
	_body.visible = t < LIFE - 3.0 or fmod(t * 6.0, 1.0) < 0.6
	_body.position.y = 0.5 + sin(t * 3.3) * 0.1
	vel *= exp(-3.0 * dt)
	var pos := global_position
	if t > 0.3 and Game.I:
		var best: Wizard = null
		var best_d := MAGNET
		for w in Game.I.wizards:
			if not w.alive or w.hp >= w.max_hp - 0.5:
				continue
			var d := Vector2(w.global_position.x - pos.x, w.global_position.z - pos.z).length()
			if d < best_d:
				best = w
				best_d = d
		if best:
			if best_d < TAKE:
				best.healed(HEAL * float(best.mods().get("heal", 1.0)))
				Fx.burst(best.global_position + Vector3.UP, COLOR, 16, 3.0, 0.15)
				Fx.light_pop(best.global_position, COLOR, 2.0, 3.0, 0.3)
				Game.I.count("globes")
				queue_free()
				return
			var to := best.global_position - pos
			to.y = 0.0
			vel += to.normalized() * (10.0 + 20.0 * (1.0 - best_d / MAGNET)) * dt
	pos += vel * dt
	global_position = Game.I.arena.clamp_inside(pos) if Game.I else pos

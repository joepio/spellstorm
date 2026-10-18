class_name Globe
extends Node3D
## Blood, the only way to heal: wizards drink it. It spills from slain
## monsters (often from the common ones, always from elites and bosses, see
## Game.on_enemy_died), from jars of blood and from broken coffins: a pool
## of it on the floor, nothing more. Walk over it to drink. Close by it
## runs to you, the side facing you reaching out (blood.gdshader); drinking
## slurps the whole pool up into you. A wizard with full health leaves it
## for the others.

const HEAL := 30.0
const MAGNET := 2.2
const TAKE := 0.8
const LIFE := 30.0
const COLOR := Color(0.9, 0.06, 0.05)

## How long drinking it takes, from the first touch to the last drop.
const SLURP := 0.5

static var all: Array[Globe] = []
static var _mesh: CylinderMesh

var vel := Vector3.ZERO
var t := 0.0
var _mat: ShaderMaterial
var _drinker: Wizard
var _slurp := 0.0
var _pull := 0.0


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
	if _mesh == null:
		_mesh = Art.cyl(0.32, 0.32, 0.02, 48)
	_mat = Fx.shader("blood", {seed = randf() * 50.0, pull = 0.0, suck = 0.0})
	var pool := MeshInstance3D.new()
	pool.mesh = _mesh
	pool.material_override = _mat
	pool.position.y = 0.02
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pool)


## The wizard drinks: a stream of blood runs up into them.
static func _drink(w: Wizard, from: Vector3) -> void:
	var p := Fx.particles(COLOR, 22, 0.35, 0.12)
	p.one_shot = true
	p.explosiveness = 0.6
	var to := w.global_position + Vector3.UP * 1.25 - from
	p.direction = to.normalized()
	p.spread = 8.0
	p.initial_velocity_min = to.length() / 0.35
	p.initial_velocity_max = to.length() / 0.3
	p.gravity = Vector3.ZERO
	Parts.style(p, El.WATER)
	p.color_ramp = Fx.ramp(COLOR)
	p.gravity = Vector3.ZERO
	Fx._spawn(p, from)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _exit_tree() -> void:
	all.erase(self)


func _physics_process(dt: float) -> void:
	t += dt
	if _drinker:
		_slurp_step(dt)
		return
	if t > LIFE:
		queue_free()
		return
	visible = t < LIFE - 3.0 or fmod(t * 6.0, 1.0) < 0.6
	vel *= exp(-3.0 * dt)
	var pos := global_position
	var pull := 0.0
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
			var to := best.global_position - pos
			to.y = 0.0
			_mat.set_shader_parameter("to", Vector2(to.x, to.z))
			pull = 1.0 - best_d / MAGNET
			if best_d < TAKE:
				best.healed(HEAL * float(best.mods().get("heal", 1.0)))
				Game.I.count("globes")
				_drinker = best
				all.erase(self)
				_drink(best, global_position + Vector3.UP * 0.05)
				return
			vel += to.normalized() * (10.0 + 20.0 * pull) * dt
	_pull = lerpf(_pull, pull, 1.0 - exp(-10.0 * dt))
	_mat.set_shader_parameter("pull", _pull)
	pos += vel * dt
	global_position = Game.I.arena.clamp_inside(pos) if Game.I else pos


## Being drunk: the pool runs along its tongue into the drinker and is gone.
func _slurp_step(dt: float) -> void:
	_slurp += dt / SLURP
	if _slurp >= 1.0 or not is_instance_valid(_drinker):
		queue_free()
		return
	var to := _drinker.global_position - global_position
	to.y = 0.0
	_mat.set_shader_parameter("to", Vector2(to.x, to.z))
	_mat.set_shader_parameter("pull", 1.0)
	_mat.set_shader_parameter("suck", _slurp)
	global_position += to * minf(1.0, 4.0 * dt)

class_name Globe
extends Node3D
## Blood, the only way to heal: wizards drink it. It spills from slain
## monsters (often from the common ones, always from elites and bosses, see
## Game.on_enemy_died), from jars of blood and from broken coffins: a red
## pool with a drop of it hanging over. Walk over it to drink; close by it
## runs to you, and a wizard with full health leaves it for the others.

const HEAL := 30.0
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
		_mat = Fx.solid(Color(0.55, 0.02, 0.03), 0.15)
		_mat.metallic_specular = 1.0
		_mat.emission_enabled = true
		_mat.emission = Color(0.6, 0.02, 0.02)
		_mat.emission_energy_multiplier = 0.8
	# The pool: a few flat splats of dark blood on the floor.
	var pool := Fx.solid(Color(0.32, 0.01, 0.02), 0.1)
	for i in 4:
		var a := randf() * TAU
		var r := 0.0 if i == 0 else randf_range(0.15, 0.3)
		var splat := MeshInstance3D.new()
		splat.mesh = Art.sphere(randf_range(0.16, 0.26) if i > 0 else 0.3, 10)
		splat.material_override = pool
		splat.scale = Vector3(1.0, 0.04, randf_range(0.7, 1.0))
		splat.position = Vector3(cos(a) * r, 0.02, sin(a) * r)
		splat.rotation.y = randf() * TAU
		splat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(splat)
	# And a drop of it hanging over, round below and drawn to a point.
	_body = Node3D.new()
	_body.position.y = 0.5
	add_child(_body)
	var drop := MeshInstance3D.new()
	drop.mesh = Art.sphere(0.14, 12)
	drop.material_override = _mat
	drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(drop)
	var tip := MeshInstance3D.new()
	tip.mesh = Art.cyl(0.0, 0.12, 0.2, 10)
	tip.material_override = _mat
	tip.position.y = 0.15
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(tip)
	_body.add_child(Fx.halo(COLOR, 0.9, 0.5, 0.3))
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.12, 0.1)
	l.light_energy = 0.6
	l.omni_range = 2.0
	add_child(l)
	l.position.y = 0.6


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
	if t > LIFE:
		queue_free()
		return
	visible = t < LIFE - 3.0 or fmod(t * 6.0, 1.0) < 0.6
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
				_drink(best, global_position + Vector3.UP * 0.5)
				Fx.light_pop(best.global_position, COLOR, 1.5, 3.0, 0.3)
				Game.I.count("globes")
				queue_free()
				return
			var to := best.global_position - pos
			to.y = 0.0
			vel += to.normalized() * (10.0 + 20.0 * (1.0 - best_d / MAGNET)) * dt
	pos += vel * dt
	global_position = Game.I.arena.clamp_inside(pos) if Game.I else pos

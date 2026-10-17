class_name Soul
extends Node3D
## A small blue shard of mana a dead monster leaves behind (blue like the
## mana orb): walk over it to take its mana
## (Balance.SOUL_MANA_PER_HP of the monster's health, split over a few wisps).
## Close by it drifts to you; a wizard with full mana leaves it for the others.

const MAGNET := 2.4
const TAKE := 0.75
const LIFE := 14.0
const COLOR := Color(0.25, 0.5, 1.0)

static var all: Array[Soul] = []
static var _core_mat: StandardMaterial3D

var mana := 4.0
var vel := Vector3.ZERO
var t := 0.0
var _base_y := 0.6
var _body: Node3D


## Scatter the souls of [param e] around where it fell.
static func drop(e: Actor) -> void:
	if not Game.I:
		return
	var total: float = e.max_hp * Balance.SOUL_MANA_PER_HP
	var count := clampi(ceili(total / 5.0), 1, 10)
	for i in count:
		var s := Soul.new()
		s.mana = total / count
		var a := randf() * TAU
		s.vel = Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 4.5)
		Game.I.spawn(s, e.global_position + Vector3.UP * 0.9)


func _ready() -> void:
	all.append(self)
	if _core_mat == null:
		_core_mat = Fx.glow(Color(0.45, 0.65, 1.0), 3.0)
	_body = Node3D.new()
	add_child(_body)
	var size := clampf(0.07 + mana * 0.006, 0.07, 0.11)
	var core := MeshInstance3D.new()
	core.mesh = Art.box(size, size, size)
	core.material_override = _core_mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.rotation = Vector3(0.6, 0.0, 0.6)
	_body.add_child(core)
	_body.add_child(Fx.halo(COLOR, size * 6.0, 0.5))
	# A faint tail of motes rising off it, like breath in the cold.
	var trail := Fx.particles(COLOR, 6, 0.5, 0.05)
	trail.local_coords = false
	trail.direction = Vector3.UP
	trail.spread = 30.0
	trail.initial_velocity_min = 0.3
	trail.initial_velocity_max = 0.7
	trail.gravity = Vector3(0, 0.6, 0)
	_body.add_child(trail)
	trail.emitting = true
	t = randf() * 0.2


func _exit_tree() -> void:
	all.erase(self)


func _physics_process(dt: float) -> void:
	t += dt
	if t > LIFE:
		queue_free()
		return
	# Fading out: it flickers its last two seconds.
	_body.visible = t < LIFE - 2.0 or fmod(t * 8.0, 1.0) < 0.6
	var pos := global_position
	vel *= exp(-3.0 * dt)
	if t > 0.35 and Game.I:
		var best: Wizard = null
		var best_d := MAGNET
		for w in Game.I.wizards:
			if not w.alive or w.mana >= Wizard.MANA_MAX - 0.5:
				continue
			var d := Vector2(w.global_position.x - pos.x, w.global_position.z - pos.z).length()
			if d < best_d:
				best = w
				best_d = d
		if best:
			if best_d < TAKE:
				best.add_mana(mana)
				Fx.burst(best.global_position + Vector3.UP * 1.2, COLOR, 6, 2.0, 0.12)
				Game.I.count("souls")
				queue_free()
				return
			var to := best.global_position + Vector3.UP * 0.9 - pos
			vel += to.normalized() * (14.0 + 30.0 * (1.0 - best_d / MAGNET)) * dt
	pos += vel * dt
	pos.y = lerpf(pos.y, _base_y + sin(t * 3.0) * 0.12, 1.0 - exp(-4.0 * dt))
	global_position = Game.I.arena.clamp_inside(pos) + Vector3(0, pos.y, 0) if Game.I else pos
	_body.rotation.y = t * 3.0

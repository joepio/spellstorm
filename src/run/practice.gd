class_name Practice
extends RefCounted
## The practice strip at the start of the first level, for wizards who have
## not learned anything yet (Joep's onboarding; no words, the world shows
## it). Four stops one after another, each behind a wall of mist that opens
## once it is done:
##   1. urns to shoot (walk and shoot)
##   2. an archer whose arrows show their line first (roll through them, LT)
##   3. a caster lobbing big slow balls (knock one back with the staff, RB)
##   4. a small shrine: stand in it to learn your first two elements
## Wizards who already learned skip nothing: they just walk through.

## How far along the path each stop is, from where the wizards start.
const URNS_AT := 10.0
const WARD_1 := 14.0
const ARCHER_AT := 24.0
const WARD_2 := 27.0
const CASTER_AT := 36.0
const WARD_3 := 39.0
const SHRINE_AT := 44.0
const WARD_4 := 47.0
## Where the first pack waits, past the strip.
const END := 56.0
const SHRINE_R := 1.4
const LEARN_TIME := 0.9

var run: Run
var start := 0.0
var urns: Array = []
var archer: Enemy
var caster: Enemy
var shrine: Node3D
var _hold := {}


func _init(r: Run) -> void:
	run = r


## Does the first level need the strip: someone at the couch knows nothing.
static func wanted() -> bool:
	if Game.I.force_practice:
		return true
	if Game.I.unlock_all or Game.I.forced_unlocks >= 0:
		return false
	return Game.I.wizards.any(func(w): return w.bot == null and w.unlocks < 0)


func build() -> void:
	var arena: Arena = Game.I.arena
	start = arena.progress_of(arena.start)
	var across := _across(URNS_AT)
	var c := arena.point_at(start + URNS_AT)
	for i in 3:
		var p := c + across * (i - 1) * 2.6
		var u := arena._prop("urn", Vector3(p.x, 0, p.y))
		if u:
			urns.append(u)
	run.add_ward(start + WARD_1, _urns_done, func(): archer = _spawn("practice_archer", ARCHER_AT))
	run.add_ward(start + WARD_2, func(): return _beaten(archer) and _all("rolled"), func(): caster = _spawn("practice_caster", CASTER_AT))
	run.add_ward(start + WARD_3, func(): return _beaten(caster) and _all("deflected"), _raise_shrine)
	run.add_ward(start + WARD_4, func(): return shrine != null and _learners().is_empty(), func(): pass)


func step(dt: float) -> void:
	if shrine == null or not is_instance_valid(shrine):
		return
	var best := 0.0
	for w in _learners():
		var d := Vector2(w.global_position.x - shrine.global_position.x, w.global_position.z - shrine.global_position.z).length()
		_hold[w] = minf(float(_hold.get(w, 0.0)) + dt, LEARN_TIME) if d < SHRINE_R else maxf(float(_hold.get(w, 0.0)) - dt * 2.0, 0.0)
		best = maxf(best, _hold[w])
		if _hold[w] >= LEARN_TIME:
			w.unlock_to(0)
			Fx.burst(shrine.global_position + Vector3.UP * 1.2, w.robe.lightened(0.35), 24, 3.5)
			_hold.erase(w)
	var fill: MeshInstance3D = shrine.get_meta("fill")
	(fill.material_override as ShaderMaterial).set_shader_parameter("progress", best / LEARN_TIME)


## Wizards at the couch who still have to learn their first elements.
func _learners() -> Array:
	return Game.I.wizards.filter(func(w): return w.alive and w.bot == null and w.unlocks < 0)


## Every living newcomer has done [param what] since its stop opened (bots
## and wizards who already know skip it).
func _all(what: String) -> bool:
	for w in _learners():
		if not w.get_meta(what, false):
			return false
	return true


## The nearest urn still standing, for bots.
func next_urn(w: Wizard) -> Node3D:
	var best: Node3D = null
	for u in urns:
		if is_instance_valid(u) and u.is_inside_tree() and (best == null or w.global_position.distance_to(u.global_position) < w.global_position.distance_to(best.global_position)):
			best = u
	return best


func _urns_done() -> bool:
	for u in urns:
		if is_instance_valid(u) and u.is_inside_tree():
			return false
	return true


func _beaten(e: Enemy) -> bool:
	return e != null and (not is_instance_valid(e) or not e.alive)


func _across(at: float) -> Vector2:
	var arena: Arena = Game.I.arena
	var dir := (arena.point_at(start + at + 1.0) - arena.point_at(start + at - 1.0)).normalized()
	return Vector2(-dir.y, dir.x)


func _spawn(kind: String, at: float) -> Enemy:
	for w in Game.I.wizards:
		w.remove_meta("rolled")
		w.remove_meta("deflected")
	var c := Game.I.arena.point_at(start + at)
	Game.I.summon_circle(Vector3(c.x, 0, c.y))
	var e := Enemy.new().setup(kind, 1.0, false)
	e.position = Game.I.arena.clamp_inside(Vector3(c.x, 0, c.y))
	e.set_meta("guard", -1)
	Game.I.add_enemy(e)
	return e


## A low stone with the two first elements floating over it, and the ring
## to stand in.
func _raise_shrine() -> void:
	var c := Game.I.arena.point_at(start + SHRINE_AT)
	var n := Node3D.new()
	var stone := Fx.solid(Color(0.3, 0.28, 0.27))
	Art.part(n, Art.cyl(0.3, 0.42, 0.7, 8), stone, Vector3(0, 0.35, 0))
	var gold := Color(1.0, 0.8, 0.45)
	var els: Array = []
	for w in _learners():
		for e in Wizard.ELEMENT_ORDER[w.element_order % Wizard.ELEMENT_ORDER.size()].slice(0, 2):
			if e not in els:
				els.append(e)
	if els.is_empty():
		els = [El.FIRE, El.LIGHTNING]
	for i in els.size():
		var a := TAU * i / els.size()
		var o := Art.part(n, Art.sphere(0.13, 12), Fx.element(els[i], 1.6), Vector3(cos(a) * 0.35, 1.15, sin(a) * 0.35))
		o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.light_color = gold
	l.light_energy = 1.4
	l.omni_range = 3.5
	l.position.y = 1.4
	n.add_child(l)
	Run._fill_ring(n, SHRINE_R, gold)
	n.position = Vector3(c.x, 0, c.y)
	Game.I.arena.add_child(n)
	n.scale = Vector3(1, 0.01, 1)
	n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.burst(n.position + Vector3.UP, gold, 16, 3.0)
	shrine = n

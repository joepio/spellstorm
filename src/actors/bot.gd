class_name Bot
extends RefCounted
## Plays a wizard for an AI seat by pressing the same buttons a player would:
## it shoots at the nearest monster, swings at what comes close, rolls away
## from bullets about to hit, and casts a recipe when it has the mana.

const RECIPES := [
	[[El.FIRE, El.FIRE, El.FIRE], "cast", 2.0],
	[[El.EARTH, El.EARTH, El.FIRE], "cast", 0.8],
	[[El.LIGHTNING, El.LIGHTNING, El.LIGHTNING], "cast", 1.6],
	[[El.WATER, El.FROST, El.WATER, El.FROST], "cast", 0.7],
	[[El.VOID, El.VOID, El.FIRE], "cast", 1.8],
	[[El.EARTH, El.EARTH, El.EARTH], "cast", 0.9],
	[[El.FROST, El.FROST, El.FROST], "cast", 1.5],
	[[El.WATER, El.WATER], "cast", 1.2],
	[[El.WATER, El.FIRE, El.WATER, El.FIRE], "cast", 1.6],
	[[El.AIR, El.LIGHTNING, El.LIGHTNING], "cast", 1.4],
	[[El.EARTH, El.EARTH, El.EARTH], "plant", 0.0],
	[[El.LIGHTNING, El.LIGHTNING], "plant", 0.0],
	[[El.VOID, El.VOID, El.EARTH], "plant", 0.0],
	[[El.FIRE, El.FIRE, El.FIRE, El.FIRE, El.FIRE], "cast", 0.0],
	[[El.LIGHTNING, El.LIGHTNING, El.LIGHTNING, El.LIGHTNING, El.LIGHTNING], "cast", 0.0],
]
const CLOSE := [[El.FROST, El.FROST, El.AIR], [El.FIRE, El.FIRE, El.EARTH], [El.EARTH, El.EARTH, El.AIR], [El.VOID, El.LIGHTNING, El.LIGHTNING]]

var plan: Array = []
var form := "cast"
var hold := 0.0
var _press_t := 0.0
var _hold_t := 0.0
var _phase := "idle"
var _think := 0.0
var _strafe := 1.0
var _goal := Vector3.ZERO
## For screenshots: always cast this recipe index.
var fixed_recipe := -1


func think(w: Wizard, dt: float) -> void:
	var pad := w.pad
	pad.poll()
	for b in [Pad.A, Pad.B, Pad.X, Pad.Y, Pad.LB, Pad.LT, Pad.RB, Pad.RS, Pad.UP, Pad.DOWN]:
		pad.set_button(b, false)
	pad.fire = false
	if not w.alive:
		pad.move = Vector2.ZERO
		return
	var run: Run = Game.I.run if Game.I else null
	var enemy := _nearest_enemy(w)
	var downed := _downed_friend(w)
	_think -= dt
	if _think <= 0.0:
		_think = 1.2
		_strafe = -_strafe if randf() < 0.3 else _strafe
	var move := Vector3.ZERO
	var aim := Vector3.ZERO
	if downed and _phase == "idle":
		plan = [El.LIFE, El.LIFE, El.LIFE]
		form = "cast"
		hold = 2.5
		_phase = "conjure"
	if run and run.state == "cleared" and enemy == null:
		_phase = "idle"
		pad.set_button(Pad.RT, false)
		var goal := run.portal.global_position if run.portal else Vector3.ZERO
		if w.get_meta("took", -1) != run.depth():
			for a in run.altars:
				if not a.taken:
					goal = a.node.global_position
					break
		move = goal - w.global_position
		pad.move = Vector2(move.x, move.z).normalized() if move.length() > 0.3 else Vector2.ZERO
		return
	var target_pos := downed.global_position if (downed and plan.has(El.LIFE)) else (enemy.global_position if enemy else w.global_position)
	var to := target_pos - w.global_position
	to.y = 0
	var d := to.length()
	if enemy or downed:
		aim = to.normalized()
		var want := 2.5 if (downed and plan.has(El.LIFE)) else 6.0
		if d > want + 1.0:
			move = to.normalized()
		elif d < want - 1.5:
			move = -to.normalized()
		move += to.normalized().cross(Vector3.UP) * _strafe * 0.6
	pad.move = Vector2(move.x, move.z).limit_length(1.0)
	pad.aim = Vector2(aim.x, aim.z)
	if downed and plan.has(El.LIFE):
		pad.fire = w.bolt_el == El.LIFE
	else:
		pad.fire = enemy != null and d < 16.0
	var threat := _bullet_threat(w)
	if threat != Vector3.ZERO and randf() < 0.12:
		pad.set_button(Pad.LT, true)
		pad.move = Vector2(threat.x, threat.z)
	elif _phase != "hold_rb" and enemy and (d < 2.4 or _bullet_in_reach(w)) and randf() < 0.5:
		pad.set_button(Pad.RB, true)
	match _phase:
		"idle":
			pad.set_button(Pad.RT, false)
			if enemy and d < 12.0:
				_choose(w, d)
				if w.mana >= _price():
					_phase = "conjure"
					_press_t = 0.0
				else:
					plan.clear()
		"conjure":
			_press_t -= dt
			if _press_t <= 0.0:
				if plan.is_empty():
					_phase = "cast"
				else:
					var e: int = plan.pop_front()
					_press(pad, e)
					_press_t = 0.13
		"cast":
			match form:
				"cast":
					pad.set_button(Pad.RT, true)
					_hold_t = hold
					_phase = "hold"
				"nova":
					pad.set_button(Pad.RB, true)
					_hold_t = Wizard.NOVA_HOLD + 0.1
					_phase = "hold_rb"
				"plant":
					pad.set_button(Pad.DOWN, true)
					_phase = "idle"
				"ward":
					pad.set_button(Pad.RS, true)
					_phase = "idle"
		"hold":
			_hold_t -= dt
			pad.set_button(Pad.RT, _hold_t > 0.0)
			if _hold_t <= 0.0:
				_phase = "rest"
				_hold_t = randf_range(0.2, 0.6)
		"hold_rb":
			_hold_t -= dt
			pad.set_button(Pad.RB, _hold_t > 0.0)
			if _hold_t <= 0.0:
				_phase = "idle"
		"rest":
			pad.set_button(Pad.RT, false)
			_hold_t -= dt
			if _hold_t <= 0.0:
				_phase = "idle"


## Roughly what the plan will cost; fusions make it a little cheaper.
func _price() -> float:
	var load := Wizard.MANA_PER_LOAD * plan.size()
	if plan.size() >= 5 and form == "cast" and plan.count(plan[0]) == plan.size():
		return load + Wizard.OVERLOAD_COST
	return load + Wizard.MANA_PER_ELEMENT * plan.size()


## Which way to roll when a bullet is about to hit, or zero.
func _bullet_threat(w: Wizard) -> Vector3:
	for b in Bullet.all:
		if not is_instance_valid(b) or b.team == w.team:
			continue
		var to := w.global_position - b.global_position
		to.y = 0
		if to.length() > 2.6 or b.vel.dot(to) <= 0.0:
			continue
		var side := b.vel.normalized().cross(Vector3.UP)
		return side if side.dot(to) > 0.0 else -side
	return Vector3.ZERO


func _bullet_in_reach(w: Wizard) -> bool:
	for b in Bullet.all:
		if is_instance_valid(b) and b.team != w.team and b.global_position.distance_to(w.global_position + Vector3.UP) < 2.2:
			return true
	return false


func _press(pad: Pad, e: int) -> void:
	for key in El.PAIRS:
		var pair: Array = El.PAIRS[key]
		var i := pair.find(e)
		if i != -1:
			pad.set_button(["A", "B", "X", "Y"].find(key), true)
			pad.set_button(Pad.LB, i == 1)
			return


func _choose(w: Wizard, d: float) -> void:
	if fixed_recipe >= 0:
		var r: Array = RECIPES[fixed_recipe % RECIPES.size()]
		plan = r[0].duplicate()
		form = r[1]
		hold = maxf(r[2], 0.3)
		return
	if w.hp < w.max_hp * 0.4 and randf() < 0.5:
		plan = [El.LIFE, El.LIFE, El.EARTH]
		form = "ward"
		return
	if d < 3.0 and randf() < 0.6:
		plan = CLOSE.pick_random().duplicate()
		form = "nova"
		return
	# Walls and totems now and then, not every cast.
	var pool := RECIPES.slice(0, RECIPES.size() - 2).filter(func(r): return r[1] != "plant" or randf() < 0.25)
	var r2: Array = pool.pick_random() if randf() < 0.95 else RECIPES[RECIPES.size() - 1 - randi() % 2]
	plan = r2[0].duplicate()
	form = r2[1]
	hold = r2[2] * randf_range(0.8, 1.3)


func _nearest_enemy(w: Wizard) -> Actor:
	var best: Actor = null
	var bd := INF
	for e in (Game.I.enemies if Game.I else []):
		if not e.alive:
			continue
		var d := w.global_position.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	return best


func _downed_friend(w: Wizard) -> Wizard:
	for o in Game.I.wizards:
		if o != w and not o.alive and o.global_position.distance_to(w.global_position) < 12.0:
			return o
	return null

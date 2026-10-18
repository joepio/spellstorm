class_name Actor
extends CharacterBody3D
## Anything with health that spells land on: wizards and monsters. Owns the
## status rules, so every spell, field and monster plays by the same ones:
##   Wet:     water soaks. Fire dries you instead of burning you, frost freezes
##            you on the spot, lightning does double damage.
##   Burning: fire and magma. Hurts over time; water or frost puts it out.
##   Poisoned: poison seeps in and hurts slowly for a long time; nothing
##            washes it out, and the undead feel it less.
##   Chilled: frost and ice stack up and slow; three stacks freeze solid.
##   Frozen:  cannot move. Earth shatters it for double damage, fire thaws it.
##   Shocked: lightning stuns for a moment.
##   Slowed:  mud halves your speed.

signal died(actor: Actor)

const BURN_DPS := Balance.BURN_DPS
const FREEZE_TIME := Balance.FREEZE_TIME

var team := 0
var hp := 100.0
var max_hp := 100.0
var radius := 0.45
var speed := 5.0
var mass := 1.0
var undead := false
## Base element -> resistance, 1 is immune, below 0 is a weakness.
var resist := {}
## Healed instead of hurt by this base element (imps bathe in fire).
var heals_from := -1
var alive := true
var armor := 1.0

var wet := 0.0
var burn := 0.0
## Poison left to seep out, in damage (Balance.POISON_DOSE).
var poison := 0.0
var chill := 0.0
var frozen := 0.0
## After a freeze, frost cannot freeze this actor again until this runs out.
var freeze_guard := 0.0
var stun := 0.0
## What hit last, so a death can fit it: the element that did the most
## damage, where it came from, and whether it was a monster's melee blow
## (Enemy sets melee_hit around its strike).
var last_el := -1
var last_dir := Vector3.ZERO
var last_melee := false
var melee_hit := false
## How far past zero the killing blow went.
var overkill := 0.0
var slow := 0.0
var slick := 0.0
var push := Vector3.ZERO
## Damage and healing since the last floating number (Game shows them),
## and whether a hit in that time found a weakness or a resistance.
var shown := {dmg = 0.0, heal = 0.0, weak = false, resist = false}
var flash := 0.0
## A hit lands: for HURT_TIME the body flashes white and jerks away from
## [member hurt_dir] (enemies, Enemy._flinch), [member hurt_k] as hard.
const HURT_TIME := 0.14
var hurt_t := 0.0
var hurt_dir := Vector3.ZERO
var hurt_k := 0.0
## Damage from a stream (sprays, beams) adds up until it is worth a flinch.
var _hurt_acc := 0.0
var haste := 1.0
## Seconds left of a dodge roll's invulnerability: monsters cannot touch you.
var invuln := 0.0

var meshes: Array[GeometryInstance3D] = []
var _overlay: ShaderMaterial
var _flames: CPUParticles3D
var _bubbles: CPUParticles3D


func _init() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func setup_status_fx() -> void:
	_overlay = ShaderMaterial.new()
	_overlay.shader = preload("res://src/fx/status_overlay.gdshader")
	for m in meshes:
		m.material_overlay = _overlay
	_flames = Fx.flames(radius)
	add_child(_flames)
	# Sickly bubbles rising off whoever is poisoned.
	_bubbles = Fx.particles(El.COLOR[El.POISON], 10, 0.9, 0.12)
	_bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_bubbles.emission_sphere_radius = radius
	_bubbles.position = Vector3.UP * 0.9
	_bubbles.direction = Vector3.UP
	_bubbles.gravity = Vector3.UP * 0.8
	_bubbles.initial_velocity_min = 0.2
	_bubbles.initial_velocity_max = 0.6
	_bubbles.emitting = false
	add_child(_bubbles)


## Resistance to one element, fused ones average their parts.
func resistance(e: int) -> float:
	var parts := El.parts(e)
	var r := 0.0
	for b in parts:
		var x := float(resist.get(b, 0.0))
		if undead and b == El.POISON:
			x += 0.4
		r += x
	return clampf(r / parts.size(), -1.0, 1.0)


## Apply [param spell] with strength [param scale] (1 for a burst, delta for
## continuous). [param ff] scales damage from a teammate. Returns damage done.
func hit_spell(spell: Dictionary, scale: float, src: Actor, dir: Vector3, ff := 1.0) -> float:
	if not alive:
		return 0.0
	var ally := src != null and src.team == team and src != self
	if invuln > 0.0 and not ally:
		return 0.0
	var dmg := 0.0
	var heal := 0.0
	var shove := 0.0
	var shock_hit := false
	var mods: Dictionary = src.mods() if src else {}
	var top_el := -1
	var top_d := 0.0
	for e in spell.counts:
		var n: float = spell.counts[e] * scale * float(mods.get("el_%d" % e, 1.0))
		var eff: Dictionary = El.EFFECT[e]
		var mult := 1.0 - resistance(e)
		if eff.has("dmg"):
			if mult > 1.05:
				shown.weak = true
			elif mult < 0.95:
				shown.resist = true
		if heals_from != -1 and El.contains(e, heals_from):
			heal += float(eff.get("dmg", 0.0)) * n
			continue
		if e == El.VOID and undead:
			heal += eff.dmg * n * 0.5
			continue
		var d: float = float(eff.get("dmg", 0.0)) * n * mult
		if d > top_d:
			top_d = d
			top_el = e
		if eff.has("shock"):
			if wet > 0.0:
				d *= 2.0 * float(mods.get("wet_shock", 1.0))
			shock_hit = true
			stun = maxf(stun, 0.3 if scale > 0.2 else 0.08)
		if e == El.EARTH and frozen > 0.0:
			d *= 2.0
			frozen = 0.0
			Fx.burst(global_position + Vector3.UP * 0.8, El.COLOR[El.ICE], 14)
		dmg += d
		shove += float(eff.get("push", 0.0)) * n * maxf(mult, 0.0)
		_status(eff, n * maxf(mult, 0.0))
	if ally:
		dmg *= ff
		shove *= maxf(ff, 0.35)
	dmg *= float(mods.get("dmg", 1.0)) * armor
	if heal > 0.0:
		healed(heal)
	if shove > 0.0 and dir.length() > 0.01:
		push += dir.normalized() * shove * 2.2 / mass
	if dmg > 0.0:
		last_el = top_el
		last_dir = dir
		last_melee = melee_hit
		take(dmg, src)
		_hurt(dmg, dir)
		if shock_hit:
			flash = 0.12
	if src and src.has_method("on_dealt") and dmg > 0.0 and not ally:
		src.on_dealt(dmg, spell)
	return dmg


func _hurt(dmg: float, dir: Vector3) -> void:
	_hurt_acc += dmg
	if _hurt_acc < 1.0 or hurt_t > HURT_TIME * 0.35:
		return
	hurt_k = clampf(0.45 + _hurt_acc / 12.0, 0.45, 1.3) / sqrt(maxf(mass, 1.0))
	_hurt_acc = 0.0
	hurt_t = HURT_TIME
	hurt_dir = Vector3(dir.x, 0, dir.z).normalized()


func _status(eff: Dictionary, n: float) -> void:
	if eff.has("wet"):
		if burn > 0.0:
			burn = 0.0
			Fx.puff(global_position + Vector3.UP, El.COLOR[El.STEAM])
		wet = minf(wet + eff.wet * n * 6.0, 7.0)
	if eff.has("burn"):
		if wet > 0.0:
			wet = maxf(0.0, wet - eff.burn * n * 5.0)
		else:
			burn = minf(burn + eff.burn * n * 4.0, Balance.BURN_MAX)
		if frozen > 0.0 or chill > 0.0:
			frozen = 0.0
			chill = 0.0
	if eff.has("chill"):
		if wet > 0.0 and n > 0.05:
			_freeze()
		else:
			chill += eff.chill * n
			if chill >= 3.0:
				_freeze()
	if eff.has("slow"):
		slow = maxf(slow, 3.0 * eff.slow * minf(n * 4.0, 1.0))
	if eff.has("poison"):
		poison = minf(poison + eff.poison * n * Balance.POISON_DOSE, Balance.POISON_CAP)


func _freeze() -> void:
	if freeze_guard > 0.0:
		# Still thawing out: frost only slows.
		chill = 2.0
		return
	frozen = freeze_time()
	freeze_guard = frozen + freeze_immunity()
	chill = 0.0
	wet = 0.0
	burn = 0.0


## Heal by [param amount], up to full, and show it.
func healed(amount: float) -> void:
	var before := hp
	hp = minf(max_hp, hp + amount)
	shown.heal += hp - before


func take(dmg: float, src: Actor = null) -> void:
	if not alive or invuln > 0.0:
		return
	shown.dmg += minf(dmg, hp)
	hp -= dmg
	if dmg > 2.5:
		flash = maxf(flash, 0.08)
	if hp <= 0.0:
		overkill = -hp
		hp = 0.0
		die(src)


func die(_src: Actor) -> void:
	alive = false
	died.emit(self)


## Whether a shot of radius [param r] moving from [param a] to [param b]
## this frame touches this actor. Checks the whole path, not just where the
## shot ends up, and is a little generous: the body you see is wider than the
## collision capsule, and shots fly above the ground under a tilted camera.
func hit_by(a: Vector3, b: Vector3, r: float) -> bool:
	var p := Vector2(global_position.x, global_position.z)
	var s := Vector2(a.x, a.z)
	var e := Vector2(b.x, b.z)
	var seg := e - s
	var t := 0.0
	if seg.length_squared() > 0.0001:
		t = clampf((p - s).dot(seg) / seg.length_squared(), 0.0, 1.0)
	return p.distance_to(s + seg * t) < radius * 1.3 + r + 0.1


func revive_progress(_amount: float) -> void:
	pass


func mods() -> Dictionary:
	return {}


## How long a freeze holds, and how long after it frost cannot freeze again.
## Monsters freeze for the full time; wizards override both (Wizard).
func freeze_time() -> float:
	return FREEZE_TIME


func freeze_immunity() -> float:
	return 0.0


func can_act() -> bool:
	return alive and frozen <= 0.0 and stun <= 0.0


func move_speed() -> float:
	var m := speed * haste
	m *= 1.0 - minf(chill * 0.18, 0.6)
	if slow > 0.0:
		m *= 0.5
	if _wading:
		m *= 0.72
	return m


## Move toward [param desired] (a velocity), with knockback on top.
func drive(desired: Vector3, delta: float) -> void:
	if not can_act():
		desired = Vector3.ZERO
	desired.y = 0.0
	var target := desired
	if slick > 0.0:
		# On ice you keep sliding where you were going.
		target = velocity.lerp(desired * 1.3, 1.5 * delta) - push
	velocity = target + push
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	_keep_inside()
	push *= exp(-5.0 * delta)


## Walls have gaps where they meet and a hard shove can squeeze through:
## in a walled level nobody ends up outside the band.
func _keep_inside() -> void:
	if not Game.I or not Game.I.arena or not Game.I.arena.corridor:
		return
	var q := Vector2(global_position.x, global_position.z)
	var d: float = Game.I.arena.bound(q)
	if d > -0.4:
		var o: Vector2 = Game.I.arena._bound_out(q)
		global_position.x -= o.x * (d + 0.4)
		global_position.z -= o.y * (d + 0.4)


var _wading := false
var _ripple_t := 0.0


func tick_status(delta: float) -> void:
	# Open water between islands: slow going, and you come out soaked.
	_wading = Game.I != null and Game.I.arena != null and Game.I.arena.in_water(global_position)
	if _wading and alive:
		wet = maxf(wet, 1.5)
		_ripple_t -= delta
		if _ripple_t <= 0.0:
			_ripple_t = 0.45 if velocity.length() > 0.5 else 1.2
			Fx.ripple(global_position, radius + 0.5, 0.9)
	if burn > 0.0:
		burn -= delta
		last_el = El.FIRE
		last_melee = false
		take(BURN_DPS * delta * (1.0 - resistance(El.FIRE)) * armor)
	if poison > 0.0:
		# The dose seeps out: fast while it is big, the last of it slowly.
		var seep := minf(poison, maxf(poison / Balance.POISON_TIME, Balance.POISON_FLOOR) * delta)
		poison -= seep
		if poison < 0.01:
			poison = 0.0
		if burn <= 0.0:
			last_el = El.POISON
		last_melee = false
		take(seep * (1.0 - resistance(El.POISON)) * armor)
	wet = maxf(0.0, wet - delta)
	chill = maxf(0.0, chill - 0.6 * delta)
	frozen = maxf(0.0, frozen - delta)
	freeze_guard = maxf(0.0, freeze_guard - delta)
	stun = maxf(0.0, stun - delta)
	slow = maxf(0.0, slow - delta)
	slick = maxf(0.0, slick - delta)
	flash = maxf(0.0, flash - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	_hurt_acc = maxf(0.0, _hurt_acc - delta * 2.0)
	invuln = maxf(0.0, invuln - delta)
	if _overlay:
		var c := Color(1, 1, 1, 0)
		if hurt_t > 0.0 and alive:
			# The hit flash: white, gone again in a blink.
			var k := hurt_t / HURT_TIME
			c = Color(1, 0.97, 0.92, 0.8 * k * k)
		elif frozen > 0.0:
			c = Color(0.6, 0.9, 1.0, 0.55)
		elif flash > 0.0:
			c = Color(1, 0.35, 0.3, 0.4)
		elif chill > 0.0:
			c = Color(0.6, 0.85, 1.0, minf(chill * 0.12, 0.35))
		elif wet > 0.0:
			c = Color(0.15, 0.35, 0.8, 0.25)
		elif slow > 0.0:
			c = Color(0.35, 0.25, 0.12, 0.35)
		elif poison > 0.0:
			c = Color(0.45, 0.85, 0.1, 0.3)
		_overlay.set_shader_parameter("tint", c)
	if _flames:
		_flames.emitting = burn > 0.0 and alive
	if _bubbles:
		_bubbles.emitting = poison > 0.0 and alive

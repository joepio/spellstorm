class_name Actor
extends CharacterBody3D
## Anything with health that spells land on: wizards and monsters. Owns the
## status rules, so every spell, field and monster plays by the same ones:
##   Wet:     water soaks. Fire dries you instead of burning you, frost freezes
##            you on the spot, lightning does double damage.
##   Burning: fire and magma. Hurts over time; water or frost puts it out.
##   Chilled: frost and ice stack up and slow; three stacks freeze solid.
##   Frozen:  cannot move. Earth shatters it for double damage, fire thaws it.
##   Shocked: lightning stuns for a moment.
##   Slowed:  mud halves your speed.

signal died(actor: Actor)

const BURN_DPS := 7.0
const FREEZE_TIME := 2.6

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
var chill := 0.0
var frozen := 0.0
var stun := 0.0
var slow := 0.0
var slick := 0.0
var push := Vector3.ZERO
var ward := {}
var ward_time := 0.0
var flash := 0.0
var haste := 1.0
## Seconds left of a dodge roll's invulnerability: monsters cannot touch you.
var invuln := 0.0

var meshes: Array[GeometryInstance3D] = []
var _overlay: StandardMaterial3D
var _flames: CPUParticles3D


func _init() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func setup_status_fx() -> void:
	_overlay = StandardMaterial3D.new()
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.albedo_color = Color(1, 1, 1, 0)
	for m in meshes:
		m.material_overlay = _overlay
	_flames = Fx.flames(radius)
	add_child(_flames)


## Resistance to one element, fused ones average their parts. Wards add theirs.
func resistance(e: int) -> float:
	var parts := El.parts(e)
	var r := 0.0
	for b in parts:
		var x := float(resist.get(b, 0.0))
		if ward_time > 0.0:
			x += Grammar.ward_resist(ward, b)
		r += x
	return clampf(r / parts.size(), -1.0, 1.0)


## Apply [param spell] with strength [param scale] (1 for a burst, delta for
## continuous). [param ff] scales damage from a teammate. Returns damage done.
func hit_spell(spell: Dictionary, scale: float, src: Actor, dir: Vector3, ff := 1.0) -> float:
	if not alive:
		if team == 0 and spell.counts.has(El.LIFE):
			revive_progress(El.EFFECT[El.LIFE].heal * spell.counts[El.LIFE] * scale)
		return 0.0
	var ally := src != null and src.team == team and src != self
	if invuln > 0.0 and not ally:
		return 0.0
	var dmg := 0.0
	var heal := 0.0
	var shove := 0.0
	var shock_hit := false
	var mods: Dictionary = src.mods() if src else {}
	for e in spell.counts:
		var n: float = spell.counts[e] * scale * float(mods.get("el_%d" % e, 1.0))
		var eff: Dictionary = El.EFFECT[e]
		var mult := 1.0 - resistance(e)
		if heals_from != -1 and El.contains(e, heals_from):
			heal += float(eff.get("dmg", 0.0)) * n
			continue
		if e == El.LIFE:
			if undead:
				dmg += eff.heal * n * mult * 1.4
			else:
				heal += eff.heal * n * float(mods.get("heal", 1.0))
			continue
		if e == El.VOID and undead:
			heal += eff.dmg * n * 0.5
			continue
		var d: float = float(eff.get("dmg", 0.0)) * n * mult
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
		hp = minf(max_hp, hp + heal)
	if shove > 0.0 and dir.length() > 0.01:
		push += dir.normalized() * shove * 2.2 / mass
	if dmg > 0.0:
		take(dmg, src)
		if shock_hit:
			flash = 0.12
	if src and src.has_method("on_dealt") and dmg > 0.0 and not ally:
		src.on_dealt(dmg, spell)
	return dmg


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
			burn = minf(burn + eff.burn * n * 4.0, 6.0)
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


func _freeze() -> void:
	frozen = FREEZE_TIME
	chill = 0.0
	wet = 0.0
	burn = 0.0


func take(dmg: float, src: Actor = null) -> void:
	if not alive or invuln > 0.0:
		return
	hp -= dmg
	if dmg > 2.5:
		flash = maxf(flash, 0.08)
	if hp <= 0.0:
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


func can_act() -> bool:
	return alive and frozen <= 0.0 and stun <= 0.0


func move_speed() -> float:
	var m := speed * haste
	m *= 1.0 - minf(chill * 0.18, 0.6)
	if slow > 0.0:
		m *= 0.5
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
	push *= exp(-5.0 * delta)


func tick_status(delta: float) -> void:
	if burn > 0.0:
		burn -= delta
		take(BURN_DPS * delta * (1.0 - resistance(El.FIRE)) * armor)
	wet = maxf(0.0, wet - delta)
	chill = maxf(0.0, chill - 0.6 * delta)
	frozen = maxf(0.0, frozen - delta)
	stun = maxf(0.0, stun - delta)
	slow = maxf(0.0, slow - delta)
	slick = maxf(0.0, slick - delta)
	flash = maxf(0.0, flash - delta)
	invuln = maxf(0.0, invuln - delta)
	if ward_time > 0.0:
		ward_time -= delta
		if ward_time <= 0.0:
			ward = {}
			armor = 1.0
			haste = 1.0
	if _overlay:
		var c := Color(1, 1, 1, 0)
		if frozen > 0.0:
			c = Color(0.6, 0.9, 1.0, 0.55)
		elif flash > 0.0:
			c = Color(1, 0.35, 0.3, 0.4)
		elif chill > 0.0:
			c = Color(0.6, 0.85, 1.0, minf(chill * 0.12, 0.35))
		elif wet > 0.0:
			c = Color(0.15, 0.35, 0.8, 0.25)
		elif slow > 0.0:
			c = Color(0.35, 0.25, 0.12, 0.35)
		_overlay.albedo_color = c
	if _flames:
		_flames.emitting = burn > 0.0 and alive

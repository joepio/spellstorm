class_name SpellFx
extends Node3D
## Base for a spell let loose in the world. Subclasses read their numbers from
## spell.n, which Grammar fills in.

var caster: Actor
var spell: Dictionary
var n: Dictionary
var t := 0.0
## Streams (spray, beam) report a segment so crossing streams can meet.
var stream_from := Vector3.ZERO
var stream_to := Vector3.ZERO
var is_stream := false


func setup(c: Actor, s: Dictionary) -> SpellFx:
	caster = c
	spell = s
	n = s.n
	return self


func ff() -> float:
	return Game.I.ff if Game.I else 0.5


## The main colour of the spell, and of each payload element.
func color() -> Color:
	return El.COLOR[spell.primary] if spell.primary >= 0 else Color.WHITE


func colors() -> Array:
	var out := [color()]
	for e in spell.payload:
		out.append(El.COLOR[e])
	return out


## The spell's elements, lead first, matching colors().
func elements() -> Array:
	return [spell.primary] + spell.payload


func targets() -> Array:
	return Game.I.living() if Game.I else []


## Every base element of the spell touches the ground there, so fire on a
## puddle makes steam and lightning on it electrifies it.
func touch(at: Vector3, r: float) -> void:
	if Game.I and Game.I.arena:
		for e in spell.counts:
			Game.I.arena.touch_ground(at, r, e, caster)


func finish() -> void:
	set_physics_process(false)
	queue_free()

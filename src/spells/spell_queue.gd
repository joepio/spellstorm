class_name SpellQueue
extends RefCounted
## The elements a wizard has conjured but not yet cast. Three rules, applied
## in this order every time an element is added:
##   1. Opposites cancel: the new element removes its opposite (from a fused
##      slot it removes just that part: Steam + Frost leaves Water).
##   2. Fusion: it melts with the first base element it fuses with
##      (Water + Fire = Steam) and takes that slot.
##   3. Otherwise it takes a new slot, if there is room.

const SIZE := 5

var slots: Array[int] = []
var size := SIZE


## Returns what happened: "cancel", "fuse", "add" or "full".
func add(e: int) -> String:
	var opp: int = El.OPPOSITE.get(e, -1)
	for i in slots.size():
		var s := slots[i]
		if s == opp:
			slots.remove_at(i)
			return "cancel"
		if El.is_fused(s) and El.contains(s, opp):
			var rest: Array = El.parts(s).duplicate()
			rest.erase(opp)
			slots[i] = rest[0]
			return "cancel"
	for i in slots.size():
		var s := slots[i]
		if not El.is_fused(s):
			var f := El.fuse(s, e)
			if f != -1:
				slots[i] = f
				return "fuse"
	if slots.size() >= size:
		return "full"
	slots.append(e)
	return "add"


func clear() -> void:
	slots.clear()


func is_empty() -> bool:
	return slots.is_empty()


func set_slots(s: Array) -> void:
	slots.clear()
	for e in s:
		slots.append(int(e))


func copy() -> Array:
	return slots.duplicate()

class_name SpellQueue
extends RefCounted
## The elements a wizard has conjured but not yet cast. Two rules, applied
## in this order every time an element is added:
##   1. Fusion: it melts with the first base element it fuses with
##      (Water + Fire = Steam) and takes that slot.
##   2. Otherwise it takes a new slot, if there is room.
## Opposites no longer cancel each other (Joep: that mechanism may go), so
## Fire and Frost simply sit side by side.

const SIZE := 3

var slots: Array[int] = []
var size := SIZE


## Returns what happened: "fuse", "add" or "full".
func add(e: int) -> String:
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

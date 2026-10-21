extends SceneTree
## Headless checks of the spell grammar: run with
##   godot --headless --script tests/spell_test.gd
## Prints how many distinct spells exist, and fails on any broken rule.

var failures := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: ", what)


func queue_of(presses: Array) -> Array:
	var q := SpellQueue.new()
	for e in presses:
		q.add(e)
	return q.copy()


func spell(presses: Array, form := "cast") -> Dictionary:
	return Grammar.compose(queue_of(presses), form)


func _init() -> void:
	# Queue rules.
	check(queue_of([El.WATER, El.FIRE]) == [El.STEAM], "water + fire is steam")
	check(queue_of([El.FIRE, El.WATER]) == [El.STEAM], "fire + water is steam")
	check(queue_of([El.WATER, El.FROST]) == [El.ICE], "water + frost is ice")
	check(queue_of([El.EARTH, El.FIRE]) == [El.MAGMA], "earth + fire is magma")
	check(queue_of([El.WATER, El.EARTH]) == [El.MUD], "water + earth is mud")
	check(queue_of([El.AIR, El.LIGHTNING]) == [El.STORM], "air + lightning is storm")
	check(queue_of([El.FIRE, El.FROST]) == [El.FIRE, El.FROST], "opposites sit side by side")
	check(queue_of([El.WATER, El.FIRE, El.FROST]) == [El.STEAM, El.FROST], "frost leaves steam alone")
	check(queue_of([El.STEAM, El.FIRE]) == [El.STEAM, El.FIRE], "fusions do not fuse again")
	check(queue_of([El.FIRE, El.FIRE, El.FIRE, El.FIRE]).size() == 3, "three slots")
	check(queue_of([El.WATER, El.FIRE, El.WATER, El.FIRE]) == [El.STEAM, El.STEAM], "two steams")

	# Shapes follow the heaviest class.
	check(spell([El.FIRE]).name == "Flamethrower", "fire is a flamethrower")
	check(spell([El.FIRE]).shape == "spray", "fire sprays")
	check(spell([El.EARTH, El.FIRE, El.FIRE]).name == "Burning Magma Lava Bomb" or spell([El.EARTH, El.FIRE, El.FIRE]).primary == El.MAGMA, "earth + fire fuses first")
	check(spell([El.EARTH, El.POISON]).name == "Venomous Boulder", "a venomous boulder")
	check(spell([El.LIGHTNING, El.FIRE]).shape == "strike", "lightning beats fire to the shape")
	check(spell([El.LIGHTNING, El.FIRE]).name == "Burning Thunderbolt", "a burning thunderbolt")
	check(spell([El.VOID, El.FIRE]).shape == "beam", "void is a beam")
	check(spell([El.WATER, El.FROST, El.ICE]).shape == "projectile", "ice is thrown")
	check(spell([El.FIRE, El.FIRE, El.FIRE]).name == "Meteor", "three fire is a meteor")
	check(spell([El.FIRE, El.FIRE, El.FIRE], "nova").name == "Fire Nova", "three fire around you is a nova")
	check(spell([El.WATER], "plant").name == "Puddle Trap", "plant water is a puddle trap")
	check(spell([El.EARTH, El.EARTH], "plant").shape == "trap", "planting under three is a trap")
	check(spell([El.EARTH, El.EARTH, El.EARTH], "plant").shape == "sentry", "a full queue plants a sentry")
	check(spell([El.EARTH, El.EARTH, El.EARTH], "plant").name == "Stone Sentry", "a stone sentry")
	check(spell([El.POISON], "enchant").name == "Poison Enchantment", "poison on yourself is an enchantment")
	check(spell([El.FIRE, El.FIRE], "enchant").name == "Fire Enchantment", "fire enchantment")
	check(spell([], "cast").shape == "staff", "an empty cast swings the staff")

	# Every reachable queue: breadth first over button presses.
	var seen := {[]: true}
	var frontier: Array = [[]]
	while not frontier.is_empty():
		var next: Array = []
		for slots in frontier:
			for e in El.BASE:
				var q := SpellQueue.new()
				q.set_slots(slots)
				q.add(e)
				var s := q.copy()
				if not seen.has(s):
					seen[s] = true
					next.append(s)
		frontier = next
	var keys := {}
	var names := {}
	var shapes := {}
	for slots in seen:
		for form in Grammar.FORMS:
			var sp := Grammar.compose(slots, form)
			keys[sp.key] = true
			names[sp.name] = true
			shapes[sp.shape] = int(shapes.get(sp.shape, 0)) + 1
			check(sp.name != "", "every spell has a name: %s %s" % [slots, form])
			check(sp.has("n"), "every spell has numbers: %s" % sp.key)
	print("queues: %d, distinct spells: %d, distinct names: %d" % [seen.size(), keys.size(), names.size()])
	print("shapes: ", shapes)
	check(keys.size() >= 300, "hundreds of spells")
	var castable := keys.keys().filter(func(k): return not (k.ends_with("|staff") or k.ends_with("|stomp") or k.ends_with("|fizzle"))).size()
	check(castable == Grammar.TOTAL, "Grammar.TOTAL is %d, the rules make %d" % [Grammar.TOTAL, castable])
	# Tomes: every key does something, every element has exactly one tome,
	# and every text fits on the shrine.
	var known := ["name", "text", "dmg", "heal", "reach", "charge", "enchant_time", "sword",
		"afflicted", "hp", "speed", "echo", "planter", "firewalker"]
	var tomed := {}
	for r: Dictionary in Relics.ALL:
		check(r.text.length() <= 52, "tome text fits: %s" % r.name)
		for k: String in r:
			if k.begins_with("el_"):
				tomed[int(k.substr(3))] = int(tomed.get(int(k.substr(3)), 0)) + 1
			else:
				check(k in known, "tome key %s does something (%s)" % [k, r.name])
	for e in El.ALL:
		check(tomed.get(e, 0) == 1, "%s has exactly one tome" % El.NAMES[e])
	var far := {reach = 1.35}
	check(Grammar.compose([El.FIRE], "cast", far).n.range > spell([El.FIRE]).n.range, "Long Nozzle lengthens sprays")
	check(Grammar.compose([El.VOID], "cast", far).n.range > spell([El.VOID]).n.range, "Long Nozzle lengthens beams")
	print("ok" if failures == 0 else "%d failures" % failures)
	quit(1 if failures > 0 else 0)

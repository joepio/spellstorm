extends SceneTree
## Measures every reachable spell against the damage budget (src/spells/balance.gd)
## and fails when one leaves the band. Run with
##   godot --headless --script tests/balance_test.gd [-- --all]
## --all prints every spell, not only the extremes.


func _init() -> void:
	var all := "--all" in OS.get_cmdline_user_args()
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
	var rows: Array = []
	var by_key := {}
	for slots in seen:
		for form in Grammar.FORMS:
			var sp := Grammar.compose(slots, form)
			if not Balance.measured(sp):
				continue
			# One row per distinct spell at each size: the same spell from
			# another press order lands on the same numbers.
			var sorted: Array = slots.duplicate()
			sorted.sort()
			var key := "%s|%s" % [sp.key, str(sorted)]
			if by_key.has(key):
				continue
			by_key[key] = true
			rows.append({spell = sp, r = Balance.ratio(sp) / Balance.target(sp), w = Balance.worth(sp)})
	rows.sort_custom(func(a, b): return a.r < b.r)
	var failures := 0
	var shapes := {}
	for row in rows:
		var sp: Dictionary = row.spell
		var b: Vector2 = Balance.BAND
		var bad: bool = row.r < b.x or row.r > b.y
		if bad:
			failures += 1
		if bad or all:
			print("%s %5.2f  %-38s %-10s %d el  %5.0f mana  worth %6.0f (hit %.0f burn %.0f freeze %.0f util %.0f heal %.0f x%.1f)" % [
				"FAIL" if bad else "    ", row.r, sp.name, sp.shape, sp.power, Balance.price(sp), row.w.total,
				row.w.hit, row.w.burn, row.w.freeze, row.w.utility, row.w.heal, row.w.targets])
		var st: Array = shapes.get(sp.shape, [99.0, 0.0, 0.0, 0])
		st[0] = minf(st[0], row.r)
		st[1] = maxf(st[1], row.r)
		st[2] += row.r
		st[3] += 1
		shapes[sp.shape] = st
	print("shape        min   avg   max   (1.0 = %.0f damage per mana)" % Balance.DMG_PER_MANA)
	for k in shapes:
		var st: Array = shapes[k]
		print("%-10s %5.2f %5.2f %5.2f  %d spells" % [k, st[0], st[2] / st[3], st[1], st[3]])
	print("bolts, worth a second (budget %.0f):" % Balance.BOLT_DPS)
	for e in El.EFFECT:
		var dps := Balance.bolt_dps(e)
		var off := dps < Balance.BOLT_DPS * Balance.BAND.x or dps > Balance.BOLT_DPS * Balance.BAND.y
		if off:
			failures += 1
		print("%s %-10s %5.1f" % ["FAIL" if off else "    ", El.NAMES[e], dps])
	print("balance: %d spells, %d out of band" % [rows.size(), failures])
	quit(1 if failures > 0 else 0)

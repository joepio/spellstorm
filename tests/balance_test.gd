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
			print("%s %5.2f  %-38s %-10s %d el  %5.0f mana  worth %6.0f (hit %.0f burn %.0f freeze %.0f util %.0f poison %.0f x%.1f)" % [
				"FAIL" if bad else "    ", row.r, sp.name, sp.shape, sp.power, Balance.price(sp), row.w.total,
				row.w.hit, row.w.burn, row.w.freeze, row.w.utility, row.w.poison, row.w.targets])
		var st: Array = shapes.get(sp.shape, [99.0, 0.0, 0.0, 0, 99.0, 0.0])
		st[0] = minf(st[0], row.r)
		st[1] = maxf(st[1], row.r)
		st[2] += row.r
		st[3] += 1
		st[4] = minf(st[4], row.w.targets)
		st[5] = maxf(st[5], row.w.targets)
		shapes[sp.shape] = st
	print("shape        min   avg   max   (1.0 = %.0f damage per mana)   monsters expected" % Balance.DMG_PER_MANA)
	for k in shapes:
		var st: Array = shapes[k]
		print("%-10s %5.2f %5.2f %5.2f  %4d spells   %.1f to %.1f" % [k, st[0], st[2] / st[3], st[1], st[3], st[4], st[5]])
	# Damage over time is credited less the later it comes (PATIENCE), so
	# what a spell really deals per mana is highest where it lasts longest:
	# poison first. Spells led by each element, averaged.
	print("real damage per mana, spells led by each element (credited 1.0 = %.0f):" % Balance.DMG_PER_MANA)
	var by_el := {}
	for row in rows:
		var sp2: Dictionary = row.spell
		var acc: Array = by_el.get(sp2.primary, [0.0, 0])
		acc[0] += row.w.real / maxf(row.w.total, 0.001) * row.r
		acc[1] += 1
		by_el[sp2.primary] = acc
	var best_e := -1
	var best := 0.0
	for e in El.BASE:
		if not by_el.has(e):
			continue
		var avg: float = by_el[e][0] / by_el[e][1]
		if avg > best:
			best = avg
			best_e = e
		print("     %-10s %5.2f" % [El.NAMES[e], avg])
	if best_e != El.POISON:
		failures += 1
		print("FAIL poison should deal the most real damage per mana, %s does" % El.NAMES[best_e])
	print("bolts, worth a second (budget %.0f times skill):" % Balance.BOLT_DPS)
	print("     element     rate  speed range  skill  target  worth/s  per bolt  ammo")
	for e in El.EFFECT:
		var dps := Balance.bolt_dps(e)
		var goal := Balance.BOLT_DPS * Balance.skill(e)
		var off := dps < goal * Balance.BAND.x or dps > goal * Balance.BAND.y
		if off:
			failures += 1
		var f := Balance.flight(e)
		print("%s %-10s %5.1f %5.0f %5.0f  %5.2f  %6.1f  %7.1f  %8.2f  %4d" % ["FAIL" if off else "    ", El.NAMES[e],
			f.rate, f.speed, f.range, Balance.skill(e), goal, dps, dps / f.rate, Balance.ammo(e)])
	# Enchantments: a store of damage that every bolt and swing spends. How
	# long a store lasts while you only shoot, and how many swings it is.
	print("enchantments: store, then seconds of shooting or swings it buys")
	for slots in [[El.FIRE], [El.FIRE, El.FIRE], [El.FIRE, El.FIRE, El.FIRE],
			[El.FROST, El.FROST], [El.LIGHTNING, El.LIGHTNING, El.LIGHTNING],
			[El.EARTH, El.EARTH], [El.WATER, El.FIRE, El.LIGHTNING], [El.VOID, El.VOID, El.POISON],
			[El.LIGHTNING, El.WATER, El.POISON]]:
		var sp := Grammar.compose(slots, "enchant")
		var scales := Balance.bolt_scales(sp.counts, sp.primary, Balance.ENCHANT_BOLT)
		var store := Balance.enchant_store(sp)
		var shot := Balance.enchant_shot(sp, scales)
		var rate: float = Balance.flight(sp.primary).rate
		var secs := store / (shot * rate)
		var swings := store / Balance.enchant_swing(sp)
		# A store must last long enough to feel, and short enough to be a burst.
		var bad := secs < 2.0 or secs > Balance.ENCHANT_TIME or swings < 1.5
		if bad:
			failures += 1
		print("%s %-34s %4.0f dmg  %5.1f s of shooting (%.1f a bolt, %.1f/s)  %4.1f swings" % ["FAIL" if bad else "    ",
			sp.name, store, secs, shot, shot * rate, swings])
	print("balance: %d spells, %d out of band" % [rows.size(), failures])
	quit(1 if failures > 0 else 0)

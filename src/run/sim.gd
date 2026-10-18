class_name Sim
## Lives in src/ (not tests/) because main.gd calls it and exports leave tests/ out.
## A headless run with bots, checked at the end:
##   godot --headless --fixed-fps 60 --path . -- --sim 3600 [--biome N] [--seed N]
## Every mechanic must have happened: bolts, swings, rolls, monster bullets,
## spells for mana, kills, and props broken. Prints the counts; exit code 1 on a miss.


static func report(g: Game) -> int:
	var s: Dictionary = g.stats
	var need := ["shots", "swings", "rolls", "bullets", "casts", "kills", "souls"]
	if g.arena.corridor:
		need.append("props_broken")
	var bad: Array = []
	for k in need:
		if int(s.get(k, 0)) <= 0:
			bad.append(k)
	var alive := g.wizards.filter(func(w): return w.alive).size()
	print("sim: ", s, " wizards standing: ", alive, "/", g.wizards.size(), " level: ", g.run.depth(), " at ", int(g.run.lead_progress()), "/", int(g.arena.length()), " m")
	for w in g.wizards:
		if w.mana < 0.0 or w.mana > Wizard.MANA_MAX:
			bad.append("mana of %s is %.1f" % [w.player_name, w.mana])
	if bad.is_empty():
		print("sim: ok")
		return 0
	printerr("sim: never happened: ", bad)
	return 1

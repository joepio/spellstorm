class_name Relics
## Tomes found on shrines along each level. Each changes numbers in a way you
## can say in one sentence; none changes what a spell is.
##
## Every tome should be worth taking for most wizards (Joep: some were far
## too broad, others too niche, some unclear). So they come in three even
## families, and a tome that helps everything helps a little, a tome that
## helps one thing helps a lot:
##   * one per controller button pair, with the mixes made from it, so
##     whatever you lean on has its tome;
##   * one per way of casting (aim, burst, plant, enchant, sword);
##   * a few for the wizard: health, speed, blood, ground, statuses.
## Texts name exactly what changes, in the words the game uses.
## Keys: el_<element>, dmg, heal, reach, charge, enchant_time, sword and
## afflicted multiply; hp adds; speed multiplies move speed; echo, planter
## and firewalker switch something on.

const ALL := [
	# The four button pairs. Each fused element sits with one of them only.
	{"name": "Black Grimoire", "text": "Poison and Void +30%", "el_0": 1.3, "el_1": 1.3},
	{"name": "Ember and Rime Codex", "text": "Fire, Frost, Steam and Ice +35%", "el_2": 1.35, "el_3": 1.35, "el_8": 1.35, "el_9": 1.35},
	{"name": "Tide Scroll", "text": "Water, Air, Mud and Storm +50%", "el_4": 1.5, "el_7": 1.5, "el_10": 1.5, "el_12": 1.5},
	{"name": "Storm Sigil", "text": "Lightning, Earth and Magma +35%", "el_5": 1.35, "el_6": 1.35, "el_11": 1.35},
	# The ways of casting.
	{"name": "Quick Hands", "text": "Aimed spells wind up 40% faster", "charge": 0.6},
	{"name": "Long Nozzle", "text": "Sprays and beams reach 35% further", "reach": 1.35},
	{"name": "Echo Stone", "text": "Bursts around you go off twice", "echo": true},
	{"name": "Mason's Chisel", "text": "Keep 2 sentries and 5 traps out at once", "planter": true},
	{"name": "Runed Staff", "text": "Enchantments last twice as long", "enchant_time": 2.0},
	{"name": "Whetstone", "text": "Sword hits 60% harder", "sword": 1.6},
	# The wizard.
	{"name": "Thick Hide", "text": "+30 max health", "hp": 30},
	{"name": "Glass Staff", "text": "+15% to all your damage, -30 max health", "dmg": 1.15, "hp": -30},
	{"name": "Zephyr Feather", "text": "You move 20% faster", "speed": 1.2},
	{"name": "Red Chalice", "text": "Blood you drink heals 60% more", "heal": 1.6},
	{"name": "Pilgrim Boots", "text": "Nothing on the ground can hurt or slow you", "firewalker": true},
	{"name": "Hunter's Mark", "text": "+25% on wet, burning, chilled or poisoned monsters", "afflicted": 1.25},
]


static func pick(n: int, rng: RandomNumberGenerator, avoid: Array = []) -> Array:
	var pool: Array = ALL.filter(func(r): return not r.name in avoid)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var i := rng.randi() % pool.size()
		out.append(pool[i])
		pool.remove_at(i)
	return out

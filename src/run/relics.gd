class_name Relics
## Tomes found on altars after each room. Each changes numbers in a way you
## can say in one sentence; none changes what a spell is.
## Keys: el_<element> multiplies that element, dmg, heal, spray_range, charge
## and ward_time multiply, hp, hops, slots and siphon add, speed multiplies
## move speed, echo and firewalker switch something on.

const ALL := [
	{"name": "Tome of Kindling", "text": "Fire, Steam and Magma burn 50% hotter", "el_2": 1.5, "el_8": 1.5, "el_11": 1.5},
	{"name": "Rime Codex", "text": "Frost and Ice bite 50% harder", "el_3": 1.5, "el_9": 1.5},
	{"name": "Tide Scroll", "text": "Water and Mud hit 60% harder", "el_4": 1.6, "el_10": 1.6},
	{"name": "Storm Sigil", "text": "Lightning +40%, arcs jump to 2 more", "el_5": 1.4, "el_12": 1.4, "hops": 2},
	{"name": "Stone Heart", "text": "Earth, Mud and Magma +40%", "el_6": 1.4, "el_10": 1.4, "el_11": 1.4},
	{"name": "Zephyr Feather", "text": "Air pushes 80% harder, you walk 15% faster", "el_7": 1.8, "speed": 1.15},
	{"name": "Green Chalice", "text": "All your healing +60%", "heal": 1.6},
	{"name": "Black Grimoire", "text": "Void +40%, and it heals you for 15% of the damage", "el_1": 1.4, "siphon": 0.15},
	{"name": "Long Nozzle", "text": "Sprays reach 35% further", "spray_range": 1.35},
	{"name": "Quick Hands", "text": "Thrown spells charge twice as fast", "charge": 0.5},
	{"name": "Echo Stone", "text": "Bursts around you go off twice", "echo": true},
	{"name": "Warded Robes", "text": "Wards last twice as long", "ward_time": 2.0},
	{"name": "Thick Hide", "text": "+40 health", "hp": 40},
	{"name": "Firewalker Boots", "text": "Burning ground no longer hurts you", "firewalker": true},
	{"name": "Conductor's Ring", "text": "Lightning on wet targets +50% more", "wet_shock": 1.5},
	{"name": "Glass Staff", "text": "+30% damage, -25 health", "dmg": 1.3, "hp": -25},
]


static func pick(n: int, rng: RandomNumberGenerator, avoid: Array = []) -> Array:
	var pool: Array = ALL.filter(func(r): return not r.name in avoid)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var i := rng.randi() % pool.size()
		out.append(pool[i])
		pool.remove_at(i)
	return out

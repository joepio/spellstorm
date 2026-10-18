class_name Grammar
## Turns a queue of elements plus a cast form into one spell. This is the whole
## spell system; the effects in src/fx only carry out what this returns.
##
## The rules, in the order the player learns them:
##   * The form is the button: RT casts ahead, RB (hold) bursts around you,
##     LS (click) plants it at your feet, RS (click) enchants your bolts and staff.
##   * The heaviest element decides the shape of a cast:
##       solid (Earth, Ice, Mud, Magma)  throw it
##       energy (Lightning, Storm)       arc to targets
##       spirit (Poison, Void)           a beam
##       flow (Fire, Frost, Water,       a spray
##             Steam, Air)
##   * Planting always puts it at your feet. Up to four elements make a
##     trap that goes off when a monster comes close (what it does depends
##     on the same class: flow spills a field, solid spikes and pins, energy
##     blasts, void pulls in, poison leaves a pool); a full queue of five
##     makes a sentry that shoots your mix at monsters. Your own traps and
##     sentries never hurt your side.
##   * Within that class, the element you have most of leads.
##   * Every other element rides along as payload and adds its effect.
##   * More of an element makes it stronger, bigger or longer.
##   * Five of one base element cast ahead is its overload, the big one.

const CAST_NOUN := {
	El.EARTH: "Boulder", El.ICE: "Ice Shards", El.MUD: "Mud Ball", El.MAGMA: "Lava Bomb",
	El.LIGHTNING: "Chain Lightning", El.STORM: "Thunderclap",
	El.POISON: "Venom Beam", El.VOID: "Void Ray",
	El.FIRE: "Flamethrower", El.FROST: "Frost Breath", El.WATER: "Water Jet",
	El.STEAM: "Steam Jet", El.AIR: "Gale",
}
const NOVA_NOUN := {
	El.POISON: "Toxic Burst", El.VOID: "Void Burst", El.FIRE: "Fire Nova", El.FROST: "Frost Nova",
	El.WATER: "Splash", El.LIGHTNING: "Thunder Ring", El.EARTH: "Shockwave", El.AIR: "Gust Ring",
	El.STEAM: "Steam Burst", El.ICE: "Ice Ring", El.MUD: "Mudslide", El.MAGMA: "Eruption",
	El.STORM: "Tempest",
}
const PLANT_NOUN := {
	El.EARTH: "Spike Trap", El.ICE: "Ice Spikes", El.MUD: "Mud Trap", El.MAGMA: "Lava Trap",
	El.LIGHTNING: "Shock Trap", El.STORM: "Thunder Trap",
	El.POISON: "Poison Trap", El.VOID: "Void Mine",
	El.FIRE: "Fire Trap", El.FROST: "Frost Trap", El.WATER: "Puddle Trap", El.STEAM: "Steam Vent",
	El.AIR: "Gust Trap",
}
const SENTRY_NOUN := {
	El.EARTH: "Stone Sentry", El.ICE: "Ice Sentry", El.MUD: "Mud Sentry", El.MAGMA: "Lava Sentry",
	El.LIGHTNING: "Tesla Sentry", El.STORM: "Storm Sentry",
	El.POISON: "Venom Sentry", El.VOID: "Void Sentry",
	El.FIRE: "Fire Sentry", El.FROST: "Frost Sentry", El.WATER: "Water Sentry", El.STEAM: "Steam Sentry",
	El.AIR: "Wind Sentry",
}
## A queue this full plants a sentry instead of a trap.
const SENTRY_SLOTS := 5
const OVERLOAD_NOUN := {
	El.FIRE: "Meteor", El.FROST: "Blizzard", El.WATER: "Tidal Wave",
	El.LIGHTNING: "Thunderstorm", El.EARTH: "Earthquake", El.AIR: "Tornado",
	El.POISON: "Plague", El.VOID: "Black Hole",
}
## A full queue cast ahead is always a cataclysm: the big one of its
## strongest base element, with every other element in it riding along
## (OverloadFx). A fused element counts as this base, its other part rides.
const FUSED_BASE := {El.STEAM: El.WATER, El.ICE: El.FROST, El.MUD: El.EARTH, El.MAGMA: El.FIRE, El.STORM: El.LIGHTNING}
## Some mixes have a name of their own.
const CATACLYSM_NAME := {
	Vector2i(El.LIGHTNING, El.WATER): "Tempest",
	Vector2i(El.WATER, El.LIGHTNING): "Tempest",
	Vector2i(El.FIRE, El.AIR): "Firestorm",
	Vector2i(El.AIR, El.FIRE): "Firestorm",
	Vector2i(El.FIRE, El.EARTH): "Meteor Shower",
	Vector2i(El.EARTH, El.FIRE): "Eruption",
	Vector2i(El.FROST, El.AIR): "Whiteout",
	Vector2i(El.WATER, El.FROST): "Frozen Sea",
	Vector2i(El.VOID, El.LIGHTNING): "Event Horizon",
	Vector2i(El.POISON, El.WATER): "Blight Tide",
}
const ADJ := {
	El.POISON: "Venomous", El.VOID: "Cursed", El.FIRE: "Burning", El.FROST: "Freezing",
	El.WATER: "Soaking", El.LIGHTNING: "Shocking", El.EARTH: "Crushing", El.AIR: "Gusting",
	El.STEAM: "Scalding", El.ICE: "Glacial", El.MUD: "Muddy", El.MAGMA: "Molten",
	El.STORM: "Thundering",
}
const ENCHANT_ADJ := {
	El.POISON: "Poison", El.VOID: "Void", El.FIRE: "Fire", El.FROST: "Frost",
	El.WATER: "Water", El.LIGHTNING: "Lightning", El.EARTH: "Stone", El.AIR: "Wind",
	El.STEAM: "Steam", El.ICE: "Ice", El.MUD: "Mud", El.MAGMA: "Magma", El.STORM: "Storm",
}

const CAST_SHAPE := {El.Kind.SOLID: "projectile", El.Kind.ENERGY: "arc", El.Kind.SPIRIT: "beam", El.Kind.FLOW: "spray"}

const FORMS := ["cast", "nova", "plant", "enchant"]
## How many distinct spells these rules make; tests/spell_test.gd counts them
## by trying every sequence of button presses and fails if this drifts.
const TOTAL := 4400


## [param slots] in queue order, [param form] one of FORMS. [param mods] are
## the caster's relic modifiers (see Relics); they change numbers, never the
## shape or the name, so a spell stays the spell you expect.
static func compose(slots: Array, form: String, mods: Dictionary = {}) -> Dictionary:
	var counts := {}
	for e in slots:
		counts[e] = int(counts.get(e, 0)) + 1
	var spell := {form = form, counts = counts, slots = slots.duplicate(), power = slots.size(),
		primary = -1, shape = "fizzle", name = "", payload = [], key = ""}
	if slots.is_empty():
		match form:
			"cast", "plant": spell.shape = "staff"; spell.name = "Staff Swing"
			"nova": spell.shape = "stomp"; spell.name = "Stomp"
			_: spell.shape = "fizzle"; spell.name = "Fizzle"
		spell.key = "%s|%s" % [form, spell.shape]
		_numbers(spell, mods)
		return spell

	var primary: int
	if form == "nova" or form == "enchant":
		primary = _most(slots, counts, slots)
	else:
		var best_kind := 99
		for e in slots:
			best_kind = mini(best_kind, El.KIND[e])
		var heavy: Array = slots.filter(func(e): return El.KIND[e] == best_kind)
		primary = _most(slots, counts, heavy)
		if form == "cast":
			spell.shape = CAST_SHAPE[best_kind]
		else:
			spell.shape = "sentry" if slots.size() >= SENTRY_SLOTS else "trap"
	spell.primary = primary

	var payload: Array = []
	for e in slots:
		if e != primary and not e in payload:
			payload.append(e)
	payload.sort_custom(func(a, b):
		if counts[a] != counts[b]:
			return counts[a] > counts[b]
		return slots.find(a) < slots.find(b))
	spell.payload = payload

	match form:
		"cast":
			if slots.size() >= SpellQueue.SIZE:
				_cataclysm(spell, slots)
			else:
				spell.name = _adjectives(payload) + CAST_NOUN[primary]
		"nova":
			spell.shape = "nova"
			spell.name = _adjectives(payload) + NOVA_NOUN[primary]
		"plant":
			spell.name = _adjectives(payload) + (SENTRY_NOUN if spell.shape == "sentry" else PLANT_NOUN)[primary]
		"enchant":
			spell.shape = "enchant"
			var words: Array = []
			for e in [primary] + payload:
				if words.size() < 2:
					words.append(ENCHANT_ADJ[e])
			spell.name = " ".join(words) + " Enchantment"
	var sorted_payload := payload.duplicate()
	sorted_payload.sort()
	spell.key = "%s|%s|%d|%s" % [form, spell.shape, primary, ",".join(sorted_payload.map(func(e): return str(e)))]
	_numbers(spell, mods)
	return spell


## The element with the highest count among [param pool]; ties go to the one
## conjured first.
## Turn a full queue into a cataclysm: the base element with the most
## slots leads (fused slots count as their FUSED_BASE), the rest ride.
static func _cataclysm(spell: Dictionary, slots: Array) -> void:
	var base := {}
	for e in slots:
		var b: int = FUSED_BASE.get(e, e)
		base[b] = int(base.get(b, 0)) + 2
		for part in El.parts(e):
			if part != b:
				base[part] = int(base.get(part, 0)) + 1
	var lead := -1
	for b in base:
		if lead < 0 or base[b] > base[lead] or (base[b] == base[lead] and El.KIND[b] < El.KIND[lead]):
			lead = b
	var riders: Array = base.keys().filter(func(b): return b != lead)
	riders.sort_custom(func(a, b): return base[a] > base[b] if base[a] != base[b] else a < b)
	spell.shape = "overload"
	spell.primary = lead
	spell.riders = riders
	var key := Vector2i(lead, riders[0]) if not riders.is_empty() else Vector2i(-1, -1)
	if CATACLYSM_NAME.has(key):
		spell.name = CATACLYSM_NAME[key]
	else:
		spell.name = _adjectives(riders) + OVERLOAD_NOUN[lead]


static func _most(slots: Array, counts: Dictionary, pool: Array) -> int:
	var best: int = pool[0]
	for e in pool:
		if counts[e] > counts[best] or (counts[e] == counts[best] and slots.find(e) < slots.find(best)):
			best = e
	return best


static func _adjectives(payload: Array) -> String:
	var out := ""
	for i in mini(2, payload.size()):
		out += ADJ[payload[i]] + " "
	return out


## The summed per-unit effect of every element in the spell, scaled by
## the caster's relics. Fusions count once each, the same as a base element.
static func effect(spell: Dictionary, mods: Dictionary = {}) -> Dictionary:
	var out := {dmg = 0.0, poison = 0.0, push = 0.0, burn = 0.0, chill = 0.0, wet = 0.0, shock = 0.0, slow = 0.0, curse = 0.0}
	for e in spell.counts:
		var n: int = spell.counts[e]
		var m := float(mods.get("el_%d" % e, 1.0))
		for k in El.EFFECT[e]:
			out[k] += El.EFFECT[e][k] * n * m
		if e == El.VOID:
			out.curse += n
	out.dmg *= float(mods.get("dmg", 1.0))
	return out


## Size, range and timing of each shape. All the numbers live here so a
## balance pass touches one function. The rates are starting points:
## Balance.fit scales each one onto the damage budget.
static func _numbers(spell: Dictionary, mods: Dictionary) -> void:
	_raw_numbers(spell, mods)
	if not spell.n.has("rate") or not Balance.measured(spell):
		return
	# The factor comes from the spell without relics, so a relic still makes
	# you stronger. It depends only on the shape and the element counts.
	var counts: Array = spell.counts.keys()
	counts.sort()
	var key := "%s|%s|%s" % [spell.shape, spell.primary, ",".join(counts.map(func(e): return "%d:%d" % [e, spell.counts[e]]))]
	if not _fit.has(key):
		var base := spell.duplicate()
		_raw_numbers(base, {})
		_fit[key] = Balance.fit(base)
	spell.n.rate *= _fit[key]


static var _fit := {}


static func _raw_numbers(spell: Dictionary, mods: Dictionary) -> void:
	var p: int = spell.power
	var lead: int = spell.counts.get(spell.primary, 0)
	var n := {}
	match spell.shape:
		"spray":
			n = {range = (3.2 + 0.9 * lead) * float(mods.get("spray_range", 1.0)), angle = 26.0 + 4.0 * p,
				duration = 2.5 + 0.5 * p, rate = 1.0}
		"beam":
			n = {range = 15.0, width = 0.25 + 0.08 * p, duration = 3.0 + 0.5 * p, rate = 1.3}
		"arc":
			n = {range = 7.5 + 0.5 * p, hops = 1 + lead + p / 2 + int(mods.get("hops", 0)),
				hop_range = 4.5, interval = 0.4, duration = 2.0 + 0.4 * p, rate = 1.0}
		"projectile":
			var pieces := 1
			if spell.primary == El.ICE:
				pieces = 3 + 2 * lead
			n = {pieces = pieces, spread = 8.0 + 3.0 * pieces, speed = 16.0, radius = 0.25 + 0.12 * lead,
				charge_time = 1.0 * float(mods.get("charge", 1.0)), rate = 1.0 / pieces * (1.4 if pieces > 1 else 1.0),
				splash = 2.2 + 0.4 * lead if spell.primary in [El.MAGMA, El.MUD] else 0.0,
				pierce = spell.primary == El.ICE}
		"nova":
			n = {radius = 2.4 + 0.65 * p, rate = 1.25}
		"trap":
			# radius: the blast; field: what flow traps leave behind; stun:
			# how long solid spikes pin; duration: how long it lies in wait
			n = {radius = 2.2 + 0.35 * p, field = 1.4 + 0.35 * p, field_time = 5.0 + p,
				stun = 0.8 + 0.25 * lead, duration = 30.0, rate = 1.6}
		"sentry":
			n = {range = 9.0, interval = 0.3, duration = 14.0, rate = 0.5}
		"enchant":
			n = {duration = Balance.ENCHANT_TIME * float(mods.get("enchant_time", 1.0))}
		"overload":
			n = {radius = 5.0, rate = 4.0}
		"staff":
			n = {range = 1.8, rate = 1.0}
		"stomp":
			n = {radius = 2.5, rate = 1.0}
	spell.n = n




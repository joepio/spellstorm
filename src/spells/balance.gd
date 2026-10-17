class_name Balance
## The yardstick every spell is measured against, so no attack runs away
## with the game. See docs/balance.md for the rules in words.
##
## One number rules it: DMG_PER_MANA. A spell is worth the damage it does to
## everything it is likely to hit over its whole life, plus its statuses,
## shoves and healing turned into damage at fixed rates (worth). What it
## really costs is loading its elements plus casting it (price). Grammar
## then sets each spell's rate so worth / (price * DMG_PER_MANA) lands on
## its target (fit): 1.0, plus a little for every extra element and every
## extra kind of element, because a longer combo is more work to build.
## tests/balance_test.gd prints every spell and fails when one leaves BAND.

## The exchange rate: one mana buys this much damage.
const DMG_PER_MANA := 5.0

# The mana economy. Mana comes mostly from souls: every monster that dies
# leaves wisps worth SOUL_MANA_PER_HP of its health, which you walk over to
# take. Regen only keeps an empty wizard from being stuck.
const MANA_MAX := 100.0
const MANA_REGEN := 3.0
const SOUL_MANA_PER_HP := 0.15
const MANA_PER_LOAD := 3.0
const MANA_PER_ELEMENT := 8.0
const OVERLOAD_COST := 40.0
## A sentry is the big plant (a full queue): it costs this to plant.
const SENTRY_COST := 50.0
const MANA_PER_SWING := 3.0
const MANA_PER_DEFLECT := 3.0

# Bolts, the free attack. One bolt hits for this share of a whole element
# (El.EFFECT), set so every element is worth about BOLT_DPS a second with
# its status and shove counted (bolt_dps; tests/balance_test.gd checks it).
# Life heals friends instead.
const BOLT_RATE := 6.0
const BOLT_DPS := 20.0
const PLAIN_BOLT := 0.2
const BOLT := {El.LIFE: 0.4, El.VOID: 0.21, El.FIRE: 0.31, El.FROST: 0.8, El.WATER: 0.9,
	El.LIGHTNING: 0.24, El.EARTH: 0.19, El.AIR: 0.67,
	El.STEAM: 0.2, El.ICE: 0.22, El.MUD: 0.4, El.MAGMA: 0.15, El.STORM: 0.26}
const BURN_DPS := 7.0
## Extra budget for each element past the first, and for each kind of
## element past the first: five mixed slots get about 1.4.
const BONUS_PER_SLOT := 0.06
const BONUS_PER_KIND := 0.06
## How far a spell may end up from its target after fitting.
const BAND := Vector2(0.8, 1.3)
## Fitting never turns a spell's rate more than this far either way, so the
## shapes keep their character.
const FIT_RANGE := Vector2(0.05, 6.0)

## How many monsters each shape is expected to hit in a normal fight.
const TARGETS := {
	"projectile": 1.0, "beam": 1.0, "spray": 2.0, "nova": 3.0,
	"trap": 2.5, "overload": 4.0, "sentry": 1.0,
}
## How much of a lasting spell's life it actually has something to hit.
const UPTIME := {"sentry": 0.6, "rune": 0.3}
## Status worth, in damage: a freeze holds a monster still for FREEZE_TIME.
const FREEZE_WORTH := 12.0
const FREEZE_TIME := 2.6
## What a shove, a soak, a slow and a shock are worth, in damage, per unit.
const UTILITY := {push = 1.0, wet = 1.0, slow = 3.0, shock = 2.0}
## Healing a friend counts this much of the same damage.
const HEAL_WORTH := 0.6
## Friends a heal is expected to reach.
const FRIENDS := 1.5


## What a spell really costs: loading each element plus casting it.
static func price(s: Dictionary) -> float:
	var load_cost: float = MANA_PER_LOAD * s.slots.size()
	if s.shape == "overload":
		return load_cost + OVERLOAD_COST
	if s.shape == "sentry":
		return load_cost + SENTRY_COST
	return load_cost + MANA_PER_ELEMENT * s.power


## How a spell lands on one target: the summed hit scale over its life
## ([code]scale[/code]), the time it keeps hitting ([code]time[/code]) and
## how many targets ([code]targets[/code]). hit_spell multiplies El.EFFECT by
## the count of each element and the scale, so this is all a spell is.
static func delivery(s: Dictionary) -> Dictionary:
	var n: Dictionary = s.n
	match s.shape:
		"spray":
			# Damage falls off to 0.6 at the far end; most targets sit midway.
			return {scale = n.rate * n.duration * 0.8, time = n.duration, targets = TARGETS.spray}
		"beam":
			return {scale = n.rate * n.duration, time = n.duration, targets = TARGETS.beam}
		"arc":
			var zaps: float = floorf(n.duration / n.interval) + 1.0
			return {scale = n.rate * zaps, time = n.duration, targets = minf(1.0 + n.hops, 3.0)}
		"projectile":
			# A full charge throws at power 1.75 (ProjectileFx.launch).
			var hit: float = 1.75 * n.rate * n.pieces
			var targets := 1.0
			if n.splash > 0.0:
				targets += 1.5 * 0.6
			if n.pierce:
				targets = 1.5
			return {scale = hit, time = 0.0, targets = targets}
		"nova":
			return {scale = n.rate * 0.8, time = 0.0, targets = TARGETS.nova}
		"trap":
			if s.primary == El.LIFE:
				# A healing rune pulses once a second (RuneFx-style, TrapFx).
				return {scale = 0.35 * n.rate * n.duration * UPTIME.rune, time = n.duration * UPTIME.rune, targets = 1.0}
			return {scale = n.rate * 0.8, time = 0.0, targets = TARGETS.trap}
		"sentry":
			var shots: float = floorf(n.duration / n.interval) * UPTIME.sentry
			return {scale = n.rate * shots, time = n.duration * UPTIME.sentry, targets = TARGETS.sentry}
		"overload":
			return {scale = n.rate * 0.8, time = 0.0, targets = TARGETS.overload}
	return {scale = 0.0, time = 0.0, targets = 0.0}


## What a spell is worth, in damage, split into its parts.
static func worth(s: Dictionary) -> Dictionary:
	var d := delivery(s)
	var dmg := 0.0
	var heal := 0.0
	var burn := 0.0
	var chill := 0.0
	var utility := 0.0
	for e in s.counts:
		var c: float = s.counts[e]
		var eff: Dictionary = El.EFFECT[e]
		dmg += float(eff.get("dmg", 0.0)) * c
		heal += float(eff.get("heal", 0.0)) * c
		burn += float(eff.get("burn", 0.0)) * c
		chill += float(eff.get("chill", 0.0)) * c
		for k in UTILITY:
			utility += float(eff.get(k, 0.0)) * c * UTILITY[k]
	var per_target: float = dmg * d.scale
	# Burn: each unit of scale lights four seconds, capped at six past the
	# last hit (Actor._status), at BURN_DPS.
	var burn_worth: float = BURN_DPS * minf(d.time + 6.0, 4.0 * burn * d.scale)
	# Chill: three gathered freezes; a burst freezes at most once, a lasting
	# spell again every few seconds.
	var freezes: float = minf(chill * d.scale / 3.0, 1.0 + d.time / 4.0)
	var freeze_worth: float = FREEZE_WORTH * floorf(freezes)
	var utility_worth: float = utility * d.scale
	var heal_worth: float = heal * d.scale * HEAL_WORTH * FRIENDS
	var total: float = (per_target + burn_worth + freeze_worth + utility_worth) * d.targets + heal_worth
	return {total = total, hit = per_target, burn = burn_worth, freeze = freeze_worth,
		utility = utility_worth, heal = heal_worth, targets = d.targets}


## The spell's worth divided by its budget: 1.0 is spot on.
static func ratio(s: Dictionary) -> float:
	var p := price(s)
	if p <= 0.0:
		return 0.0
	return worth(s).total / (p * DMG_PER_MANA)


## Where a spell should land: a longer, more mixed combo earns a little more.
static func target(s: Dictionary) -> float:
	return 1.0 + BONUS_PER_SLOT * (s.slots.size() - 1) + BONUS_PER_KIND * (s.counts.size() - 1)


## Spells held to the budget. Wards are protection; the overloads are
## hand-made showpieces (OverloadFx), so both are only listed. Bolts and the staff are the free attacks, see bolt_dps.
static func measured(s: Dictionary) -> bool:
	return not s.shape in ["staff", "stomp", "fizzle", "ward", "overload"]


## The factor on the spell's rate that puts it on its target. Worth grows
## with the rate but not in a straight line (burn is capped, freezes come
## whole), so it is found by halving the gap.
static func fit(s: Dictionary) -> float:
	if not measured(s) or not s.n.has("rate"):
		return 1.0
	var goal := target(s)
	var rate: float = s.n.rate
	var lo := FIT_RANGE.x
	var hi := FIT_RANGE.y
	for i in 24:
		var mid := sqrt(lo * hi)
		s.n.rate = rate * mid
		if ratio(s) < goal:
			lo = mid
		else:
			hi = mid
	s.n.rate = rate
	return sqrt(lo * hi)


## What a stream of one element's bolts is worth a second: hits, burn,
## freezes and utility, the same way spells are counted.
static func bolt_dps(e: int) -> float:
	var eff: Dictionary = El.EFFECT[e]
	var per_s: float = BOLT[e] * BOLT_RATE
	var worth: float = float(eff.get("dmg", 0.0)) * per_s
	for k in UTILITY:
		worth += float(eff.get(k, 0.0)) * per_s * UTILITY[k]
	if eff.has("burn"):
		worth += BURN_DPS
	worth += FREEZE_WORTH * minf(float(eff.get("chill", 0.0)) * per_s / 3.0, 1.0 / FREEZE_TIME)
	worth += float(eff.get("heal", 0.0)) * per_s * HEAL_WORTH
	return worth

class_name Balance
## The yardstick every spell is measured against, so no attack runs away
## with the game. See docs/balance.md for the rules in words.
##
## One number rules it: DMG_PER_MANA. A spell is worth the damage it does to
## everything it is likely to hit over its whole life, plus its statuses,
## and shoves turned into damage at fixed rates (worth). What it
## really costs is loading its elements plus casting it (price). Grammar
## then sets each spell's rate so worth / (price * DMG_PER_MANA) lands on
## its target (fit): 1.0, plus a little for every extra element and every
## extra kind of element, because a longer combo is more work to build.
## tests/balance_test.gd prints every spell and fails when one leaves BAND.

## The exchange rate: one mana buys this much damage. Set so a spell hits
## each target clearly harder per second than the free bolts do (BOLT_DPS):
## spending mana must always beat not spending it.
const DMG_PER_MANA := 9.0

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

# Bolts, the free attack. Every element is worth about BOLT_DPS a second
# with its status and shove counted (bolt_dps), a little more when its bolts
# are harder to land (skill). Each element flies its own way (FLIGHT), and
# the strength of one bolt is worked out from that (bolt_scale), so a slow
# rock hits much harder than a quick spark.
const BOLT_DPS := 12.0
const PLAIN_BOLT := 0.12
## The plain golden bolt of an empty queue.
const PLAIN_FLIGHT := {rate = 6.0, speed = 22.0, range = 18.0, lob = false, hit = 0.18}
## How each base element's bolts fly: shots a second, speed, how far they
## go, whether they are thrown in an arc that lands at that range, and how
## wide they hit. Lightning does not fly at all (zap): a little spark of it
## jumps from the staff to the first thing in line. A fusion flies like the
## average of its two parts.
const FLIGHT := {
	El.FIRE: {rate = 6.0, speed = 22.0, range = 16.0, lob = false, hit = 0.2},
	El.FROST: {rate = 4.0, speed = 36.0, range = 22.0, lob = false, hit = 0.14},
	El.WATER: {rate = 9.0, speed = 16.0, range = 9.0, lob = true, hit = 0.2},
	El.LIGHTNING: {rate = 5.0, speed = 60.0, range = 11.0, lob = false, hit = 0.16, zap = true},
	El.EARTH: {rate = 1.5, speed = 15.0, range = 13.0, lob = true, hit = 0.34},
	El.AIR: {rate = 7.0, speed = 30.0, range = 18.0, lob = false, hit = 0.22},
	El.POISON: {rate = 3.0, speed = 11.0, range = 10.0, lob = true, hit = 0.26},
	El.VOID: {rate = 2.0, speed = 9.0, range = 15.0, lob = false, hit = 0.34},
}
## How long one loaded element lasts as bolts, at its own rate.
const AMMO_TIME := 1.35
const BURN_DPS := 7.0
## Poison is slower than fire but lasts, and nothing washes it out.
const POISON_DPS := 4.0
## Extra budget for each element past the first, and for each kind of
## element past the first: five mixed slots get about 1.4.
const BONUS_PER_SLOT := 0.06
const BONUS_PER_KIND := 0.06
## How far a spell may end up from its target after fitting.
const BAND := Vector2(0.8, 1.3)
## Fitting never turns a spell's rate more than this far either way, so the
## shapes keep their character.
const FIT_RANGE := Vector2(0.05, 30.0)

## How many monsters each shape is expected to hit follows from the area
## it covers: one, plus DENSITY monsters for every square metre past that,
## at most MAX_TARGETS. A bigger nova or a wider cone counts on more.
## Single-target shapes (a beam stops at the first, a sentry picks one)
## count one; chain lightning counts its jumps.
const DENSITY := 0.04
const MAX_TARGETS := 6.0
## Every monster past the first counts for this much: a spell that hits a
## crowd may do more in total, but on one monster alone it never beats a
## single-target spell of the same mana.
const CROWD := 0.5
## Easy spells are worth a little less, hard ones a little more: a sentry
## aims itself and chain lightning finds its targets, a thrown boulder has
## to be led and lands late.
const EASE := {"sentry": 0.85, "strike": 1.0, "spray": 0.95, "beam": 1.0, "nova": 1.0,
	"trap": 1.0, "projectile": 1.15, "enchant": 1.0}
## Every RT spell winds up for this long before it goes (Wizard.WINDUP).
const WINDUP := {spray = 0.4, beam = 0.55, strike = 0.6, projectile = 0.65, overload = 1.0}
## Shapes you hold: the staff is busy for the whole spell.
const HELD := ["spray", "beam"]
## How much of a lasting spell's life it actually has something to hit.
const UPTIME := {"sentry": 0.6}
## Status worth, in damage: a freeze holds a monster still for FREEZE_TIME.
const FREEZE_WORTH := 12.0
const FREEZE_TIME := 2.6
## What a shove, a soak, a slow and a shock are worth, in damage, per unit.
const UTILITY := {push = 1.0, wet = 1.0, slow = 3.0, shock = 2.0}


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
			# The cone covers its angle (the whole width) times range squared, halved.
			var cone: float = deg_to_rad(n.angle) * n.range * n.range * 0.5
			return {scale = n.rate * n.duration * 0.8, time = n.duration, targets = crowd(cone)}
		"beam":
			return {scale = n.rate * n.duration, time = n.duration, targets = 1.0}
		"strike":
			# The one struck in full, the rest of the splash at StrikeFx.SPLASH.
			return {scale = n.rate, time = 0.0, targets = 1.0 + (crowd(PI * n.radius * n.radius) - 1.0) * 0.6}
		"projectile":
			# A full charge throws at power 1.75 (ProjectileFx.launch).
			var hit: float = 1.75 * n.rate * n.pieces
			var targets := 1.0
			if n.splash > 0.0:
				# The splash, at about 0.6 strength, on whoever stands round the one hit.
				targets += (crowd(PI * n.splash * n.splash) - 1.0) * 0.6
			if n.pierce:
				targets = 1.5
			return {scale = hit, time = 0.0, targets = targets}
		"nova":
			return {scale = n.rate * 0.8, time = 0.0, targets = crowd(PI * n.radius * n.radius)}
		"trap":
			return {scale = n.rate * 0.8, time = 0.0, targets = crowd(PI * n.radius * n.radius)}
		"sentry":
			var shots: float = floorf(n.duration / n.interval) * UPTIME.sentry
			return {scale = n.rate * shots, time = n.duration * UPTIME.sentry, targets = 1.0}
		"overload":
			return {scale = n.rate * 0.8, time = 0.0, targets = crowd(PI * n.radius * n.radius)}
	return {scale = 0.0, time = 0.0, targets = 0.0}


## What a spell is worth, in damage, split into its parts.
static func worth(s: Dictionary) -> Dictionary:
	var d := delivery(s)
	var dmg := 0.0
	var poison := 0.0
	var burn := 0.0
	var chill := 0.0
	var utility := 0.0
	for e in s.counts:
		var c: float = s.counts[e]
		var eff: Dictionary = El.EFFECT[e]
		dmg += float(eff.get("dmg", 0.0)) * c
		poison += float(eff.get("poison", 0.0)) * c
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
	# Poison: each unit of scale adds five seconds, capped at ten past the
	# last hit, at POISON_DPS.
	var poison_worth: float = POISON_DPS * minf(d.time + 10.0, 5.0 * poison * d.scale)
	var total: float = (per_target + burn_worth + poison_worth + freeze_worth + utility_worth) * d.targets
	return {total = total, hit = per_target, burn = burn_worth, poison = poison_worth, freeze = freeze_worth,
		utility = utility_worth, targets = d.targets}


## The spell's worth divided by its budget: 1.0 is spot on.
static func ratio(s: Dictionary) -> float:
	var p := price(s)
	if p <= 0.0:
		return 0.0
	return gain(s) / (p * DMG_PER_MANA)


## How long the staff cannot shoot because of this spell: its wind-up and,
## for a spell you hold, all of it.
static func busy(s: Dictionary) -> float:
	var t: float = WINDUP.get(s.shape, 0.0)
	if s.shape in HELD:
		t += float(s.n.get("duration", 0.0))
	return t


## Monsters expected in [param area] square metres (see DENSITY).
static func crowd(area: float) -> float:
	return clampf(1.0 + DENSITY * area, 1.0, MAX_TARGETS)


## Monsters as they are credited: the first in full, the rest at CROWD.
static func credited(targets: float) -> float:
	return 1.0 + maxf(targets - 1.0, 0.0) * CROWD


## What a spell gains you over not casting it: its worth with the crowd
## credited at CROWD, less the bolts you could have fired meanwhile.
static func gain(s: Dictionary) -> float:
	var w := worth(s)
	var per: float = w.total / maxf(w.targets, 0.001)
	return per * credited(w.targets) - BOLT_DPS * busy(s)


## Where a spell should land: a longer, more mixed combo earns a little more.
static func target(s: Dictionary) -> float:
	var t: float = 1.0 + BONUS_PER_SLOT * (s.slots.size() - 1) + BONUS_PER_KIND * (s.counts.size() - 1)
	return t * float(EASE.get(s.shape, 1.0))


## Spells held to the budget. Enchantments feed the free attacks; the overloads are
## hand-made showpieces (OverloadFx), so both are only listed. Bolts and the staff are the free attacks, see bolt_dps.
static func measured(s: Dictionary) -> bool:
	return not s.shape in ["staff", "stomp", "fizzle", "enchant", "overload"]


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


## How [param e]'s bolts fly (FLIGHT); a fusion averages its parts.
static func flight(e: int) -> Dictionary:
	if e < 0:
		return PLAIN_FLIGHT
	if FLIGHT.has(e):
		return FLIGHT[e]
	var p: Array = El.PARTS[e]
	var a: Dictionary = FLIGHT[p[0]]
	var b: Dictionary = FLIGHT[p[1]]
	return {rate = sqrt(a.rate * b.rate), speed = (a.speed + b.speed) * 0.5, range = (a.range + b.range) * 0.5,
		lob = a.lob and b.lob, hit = (a.hit + b.hit) * 0.5, zap = a.get("zap", false) or b.get("zap", false)}


## How many bolts one loaded element of [param e] gives.
static func ammo(e: int) -> int:
	return maxi(2, roundi(flight(e).rate * AMMO_TIME))


## Harder bolts to land earn more: slow ones, ones you fire seldom (a miss
## costs more) and ones thrown in an arc.
static func skill(e: int) -> float:
	var f := flight(e)
	var k := 1.0 + 0.3 * (1.0 - minf(f.speed, 22.0) / 22.0)
	k += 0.1 * maxf(1.0 - f.rate / 6.0, 0.0)
	if f.lob:
		k += 0.1
	return k


## What one bolt of [param e] hitting at [param scale] is worth, as part of
## a stream at [param rate] a second: its hit and shove, and its share of
## the burn, poison and freezes a stream keeps up.
static func shot_worth(e: int, scale: float, rate: float) -> float:
	var eff: Dictionary = El.EFFECT[e]
	var w: float = float(eff.get("dmg", 0.0)) * scale
	for k in UTILITY:
		w += float(eff.get(k, 0.0)) * scale * UTILITY[k]
	if eff.has("burn"):
		w += BURN_DPS * minf(1.0, float(eff.burn) * scale * rate) / rate
	if eff.has("poison"):
		w += POISON_DPS * minf(1.0, float(eff.poison) * scale * rate) / rate
	w += FREEZE_WORTH * minf(float(eff.get("chill", 0.0)) * scale * rate / 3.0, 1.0 / FREEZE_TIME) / rate
	return w


static var _bolt_scale := {}


## How hard one bolt of [param e] hits, so its stream is worth
## BOLT_DPS times its skill a second.
static func bolt_scale(e: int) -> float:
	if _bolt_scale.has(e):
		return _bolt_scale[e]
	var rate: float = flight(e).rate
	var goal: float = BOLT_DPS * skill(e)
	var lo := 0.001
	var hi := 10.0
	for i in 40:
		var mid := sqrt(lo * hi)
		if shot_worth(e, mid, rate) * rate < goal:
			lo = mid
		else:
			hi = mid
	_bolt_scale[e] = sqrt(lo * hi)
	return _bolt_scale[e]


## How hard each element of a bolt hits. The front element sets how the
## bolt flies and how often it fires; every element keeps its own worth a
## second (bolt_scale at its own rate), so a slow bolt carries a bigger
## share of each. More copies hit harder; a mix splits the strength.
static func bolt_scales(counts: Dictionary, front: int, mult: float) -> Dictionary:
	var scales := {}
	var split := 1.0 / sqrt(float(counts.size()))
	var rate: float = flight(front).rate
	for e in counts:
		scales[e] = bolt_scale(e) * flight(e).rate / rate * (0.6 + 0.4 * counts[e]) * split * mult
	return scales


## What a stream of one element's bolts is worth a second.
static func bolt_dps(e: int) -> float:
	var rate: float = flight(e).rate
	return shot_worth(e, bolt_scale(e), rate) * rate


# Enchantments. An enchantment is a store of damage, priced like a spell
# (price times DMG_PER_MANA times its target): every enchanted bolt and
# every enchanted swing spends what it is worth from it, and when it is
# spent the sword is steel again. Shooting uses it up; it is a short,
# strong buff, not a free one. It also ends after ENCHANT_TIME.

## How much harder an enchanted bolt hits than a loaded one.
const ENCHANT_BOLT := 2.5
## How hard an enchanted swing hits with its elements, per element.
const ENCHANT_SWING := 0.6
## Monsters an enchanted swing is expected to catch.
const SWING_TARGETS := 2.0
const ENCHANT_TIME := 20.0
## What each base element's trick on an enchanted bolt adds, in damage,
## beyond its hit (BoltFx._charm_hit and _charm_end): a stun, a shove, a
## pull, a puddle of poison.
const CHARM := {El.EARTH: 1.5, El.AIR: 1.5, El.VOID: 1.5, El.POISON: 3.0}


## The store an enchantment starts with, in damage.
static func enchant_store(s: Dictionary) -> float:
	return price(s) * DMG_PER_MANA * target(s)


## What one enchanted bolt is worth: each element's hit (bolt_scale times
## its copies, split over the mix, times ENCHANT_BOLT, as Wizard fires it),
## then the base elements' tricks. Fire bursts on whoever stands by, frost
## goes through, lightning jumps to two more, water fires three at half.
static func enchant_shot(s: Dictionary, scales: Dictionary) -> float:
	var rate: float = flight(s.primary).rate
	var bases := {}
	var w := 0.0
	for e in scales:
		w += shot_worth(e, scales[e], rate)
		for b in El.parts(e):
			bases[b] = true
	# (Water fires three at half; about two land, so it counts as one.)
	if El.FROST in bases:
		w *= credited(1.5)
	var fire: float = scales.get(El.FIRE, scales.get(El.MAGMA, scales.get(El.STEAM, 0.0)))
	if El.FIRE in bases:
		# The burst at half the bolt's fire, on the struck monster and about
		# half a monster more.
		w += shot_worth(El.FIRE, maxf(fire, bolt_scale(El.FIRE)) * 0.5, rate) * credited(1.5)
	if El.LIGHTNING in bases:
		w += shot_worth(El.LIGHTNING, bolt_scale(El.LIGHTNING) * 1.2, rate) * 1.2 * CROWD
	for b in CHARM:
		if b in bases:
			w += CHARM[b]
	return w


## What one enchanted swing is worth: the whole enchantment at ENCHANT_SWING
## on the monsters in the arc.
static func enchant_swing(s: Dictionary) -> float:
	var w := 0.0
	for e in s.counts:
		var eff: Dictionary = El.EFFECT[e]
		var n: float = float(s.counts[e]) * ENCHANT_SWING
		w += float(eff.get("dmg", 0.0)) * n
		for k in UTILITY:
			w += float(eff.get(k, 0.0)) * n * UTILITY[k]
		w += BURN_DPS * minf(6.0, 4.0 * float(eff.get("burn", 0.0)) * n)
		w += POISON_DPS * minf(10.0, 5.0 * float(eff.get("poison", 0.0)) * n)
		w += FREEZE_WORTH * floorf(minf(float(eff.get("chill", 0.0)) * n / 3.0, 1.0))
	return w * credited(SWING_TARGETS)

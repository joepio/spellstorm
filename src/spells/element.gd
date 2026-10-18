class_name El
## The eight elements, the five fusions, and what each one does when it lands.
## Pure data: no nodes, so tests and the spell grammar can use it headless.

enum { POISON, VOID, FIRE, FROST, WATER, LIGHTNING, EARTH, AIR, STEAM, ICE, MUD, MAGMA, STORM }

const BASE := [POISON, VOID, FIRE, FROST, WATER, LIGHTNING, EARTH, AIR]
const FUSED := [STEAM, ICE, MUD, MAGMA, STORM]
const ALL := [POISON, VOID, FIRE, FROST, WATER, LIGHTNING, EARTH, AIR, STEAM, ICE, MUD, MAGMA, STORM]

const NAMES := ["Poison", "Void", "Fire", "Frost", "Water", "Lightning", "Earth", "Air",
	"Steam", "Ice", "Mud", "Magma", "Storm"]
## One letter for the HUD orbs.
const GLYPH := ["☠", "◆", "F", "❄", "W", "⚡", "E", "≈", "S", "I", "M", "L", "T"]

const COLOR := [
	Color(0.55, 0.95, 0.12),  # poison
	Color(0.7, 0.2, 0.95),    # void
	Color(1.0, 0.45, 0.1),    # fire
	Color(0.4, 0.88, 1.0),    # frost
	Color(0.2, 0.5, 1.0),     # water
	Color(1.0, 0.88, 0.25),   # lightning
	Color(0.62, 0.45, 0.28),  # earth
	Color(0.62, 1.0, 0.8),    # air
	Color(0.85, 0.85, 0.9),   # steam
	Color(0.55, 0.85, 1.0),   # ice
	Color(0.42, 0.32, 0.2),   # mud
	Color(1.0, 0.3, 0.05),    # magma
	Color(0.55, 0.6, 0.95),   # storm
]

## The controller: each face button holds a pair of opposites. Tap for the
## first, hold LB and tap for the second. Opposites cancel in the queue, so the
## same button with LB is also the undo for it.
const PAIRS := {
	"A": [POISON, VOID],
	"B": [FIRE, FROST],
	"X": [WATER, LIGHTNING],
	"Y": [EARTH, AIR],
}

const OPPOSITE := {
	POISON: VOID, VOID: POISON,
	FIRE: FROST, FROST: FIRE,
	WATER: LIGHTNING, LIGHTNING: WATER,
	EARTH: AIR, AIR: EARTH,
}

## Two base elements that melt together into one slot.
const PARTS := {
	STEAM: [WATER, FIRE],
	ICE: [WATER, FROST],
	MUD: [WATER, EARTH],
	MAGMA: [EARTH, FIRE],
	STORM: [AIR, LIGHTNING],
}

## Shape classes, heaviest first. The heaviest class in the queue decides the
## shape of an aimed spell; everything else rides along as payload.
enum Kind { SOLID, ENERGY, SPIRIT, FLOW }
const KIND := {
	EARTH: Kind.SOLID, ICE: Kind.SOLID, MUD: Kind.SOLID, MAGMA: Kind.SOLID,
	LIGHTNING: Kind.ENERGY, STORM: Kind.ENERGY,
	POISON: Kind.SPIRIT, VOID: Kind.SPIRIT,
	FIRE: Kind.FLOW, FROST: Kind.FLOW, WATER: Kind.FLOW, STEAM: Kind.FLOW, AIR: Kind.FLOW,
}

## What one unit of an element does on a hit. Continuous spells (spray, beam)
## apply this per second, bursts (projectile, nova, arc) once.
##   dmg: damage, push: knockback,
##   burn / poison / chill / wet / shock / slow: status strength.
## No element heals: health only comes back from the red globes monsters drop.
const EFFECT := {
	POISON: {dmg = 6.0, poison = 1.0},
	VOID: {dmg = 16.0},
	FIRE: {dmg = 7.0, burn = 1.0},
	FROST: {dmg = 3.0, chill = 1.0},
	WATER: {dmg = 1.0, wet = 1.0, push = 1.5},
	LIGHTNING: {dmg = 12.0, shock = 1.0},
	EARTH: {dmg = 16.0, push = 2.0},
	AIR: {dmg = 1.0, push = 4.0},
	STEAM: {dmg = 10.0, wet = 0.6, burn = 0.3},
	ICE: {dmg = 12.0, chill = 1.2},
	MUD: {dmg = 5.0, slow = 1.0, wet = 0.4},
	MAGMA: {dmg = 14.0, burn = 1.2},
	STORM: {dmg = 9.0, shock = 0.8, push = 2.0},
}


static func fuse(a: int, b: int) -> int:
	for f in PARTS:
		var p: Array = PARTS[f]
		if (p[0] == a and p[1] == b) or (p[0] == b and p[1] == a):
			return f
	return -1


static func is_fused(e: int) -> bool:
	return PARTS.has(e)


## Base elements an element is made of.
static func parts(e: int) -> Array:
	return PARTS.get(e, [e])


## Does any part of this element contain [param base]?
static func contains(e: int, base: int) -> bool:
	return base in parts(e)


static func name_of(e: int) -> String:
	return NAMES[e]


static func color_of(e: int) -> Color:
	return COLOR[e]

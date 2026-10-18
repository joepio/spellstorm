# Balance

How Spellstorm keeps attacks from running away with the game. The numbers
live in `src/spells/balance.gd`. `tests/balance_test.gd` checks every
reachable spell against them, and CI fails when one leaves the band.

## The exchange rate

**1 mana buys 9 damage** (`Balance.DMG_PER_MANA`).

Every spell is held to that rate. Bolts and the staff are not, because they
are the free attacks; they have their own budget (see below).

## What a spell costs

The price is what the player really pays:

- **loading:** 3 mana per element put in the queue (`MANA_PER_LOAD`);
- **casting:** 8 mana per element still in the queue (`MANA_PER_ELEMENT`).

One element is 11 mana and must be worth about 55 damage. Five elements are
55 mana and must be worth about 275 damage, plus the combo bonus.

## The combo bonus

A longer or more mixed queue takes more work to build, so it may hit a
little harder:

- **+6% for each element past the first** (`BONUS_PER_SLOT`);
- **+6% for each different element past the first** (`BONUS_PER_KIND`).

| Queue | Target |
|---|---|
| Fire | 1.00 |
| Fire Fire Fire | 1.12 |
| Earth Fire Void | 1.24 |
| five slots, three kinds | 1.36 |

## What a spell is worth

`Balance.worth()` adds up everything a spell does over its whole life, to
everything it is likely to hit:

- **Direct damage:** `El.EFFECT` dmg × the count of each element × how much
  of the spell lands. A spray lands every second of its duration, a
  thunderbolt or a nova once.
- **Burn:** 7 damage a second, at most 6 seconds past the last hit. More
  hits add time up to that, never more damage a second. Water or frost puts
  it out.
- **Freeze:** worth 12 damage, since it holds a monster still.
- **Utility, in damage per unit:** push 1, wet 1, slow 3, shock 2. Wet and
  shock are combo enablers (shock does double on wet), so they count, but
  not as much as damage.
- **Poison:** a dose of damage that seeps out: each unit of scale adds 25,
  and the dose drains a fifth of itself a second, so it fades instead of
  stopping (the last bit at 2 a second). Doses stack up to 150 on one
  monster. Nothing washes it off. No spell heals: health comes from blood
  that monsters spill and jars hold.

### Damage that comes later counts less

A monster burning for six seconds may die of something else first, walk
out of reach or be doused. So damage over time is credited by when it lands:
damage t seconds after the hit counts `exp(-t / PATIENCE)`, PATIENCE 4 s.
While a lasting spell keeps it topped up it counts in full, like any hit;
only what runs on after counts less.

- A full 6 s burn deals 42 and is credited 31.
- A poison dose comes out on average 5 s late and is credited 4/9 of itself:
  a dose of 100 is credited 44.

The budget pays for credited damage, so the longer an effect lasts, the more
it really deals per mana. Poison lasts longest and is the strongest element:
`tests/balance_test.gd` prints real damage per mana for spells led by each
element and fails when poison is not on top (now poison 1.30, fire 1.07,
the rest 0.8 to 1.0).

### How many monsters a shape hits

The expected number of monsters follows from the area a spell covers: one,
plus **0.04 monsters per square metre** of it (`DENSITY`), at most 6. A
bigger nova or a wider cone counts on more.

| Shape | Area | Expected |
|---|---|---|
| nova | the circle | 2.2 to 5.0 |
| trap | the blast circle | 1.8 to 2.6 |
| spray | the cone (angle × range² / 2) | 1.2 to 1.7 |
| projectile | 1, plus 0.6 of the splash circle | 1.0 to 2.1 |
| strike (thunderbolt) | 1, plus 0.6 of the splash circle | 1.1 to 1.4 |
| beam | stops at the first | 1 |
| sentry | picks one, in range 60% of the time | 1 |

### A crowd counts for half

Nothing is scaled while you play: every monster in the flames takes the
same damage, however many there are. But in the sum that sets a spell's
strength, **the first monster counts fully and every one after it for half**
(`CROWD`). A flamethrower expected to hit 2 counts as 1.5. So on one monster
alone an area spell is never stronger than a single-target spell of the same
mana, and on a crowd it is worth more.

### Time you cannot shoot is a cost

Bolts are free, so a spell has to beat what you would have done instead.
Every RT spell winds up first (`WINDUP`), and while you hold a flamethrower
or beam you cannot shoot at all. A spell's gain is its worth
**less 12 damage a second (`BOLT_DPS`) for every second the staff is busy**.
A flamethrower does a lot a second, but you also stop shooting for its whole
length, and the sum knows it.

### Hard spells earn a little more

`EASE` multiplies a shape's target: an aimed boulder that is slow to land
gets 15% more, a sentry that aims itself 15% less, a spray 5% less.

## How it stays balanced: fitting

`Grammar` builds every spell's size, range and duration as before. Then
`Balance.fit()` scales the spell's `rate`, which is the strength of each hit,
so its worth / (price × 5) lands exactly on its target.

Shapes and elements keep their character: a flamethrower still burns, a
boulder still shoves and a frost nova still freezes. They just cannot be
worth more than the mana you put in. The factor is worked out from the spell
without relics, so a relic still makes you stronger.

Tuning:

- Want all spells stronger or weaker? Change `DMG_PER_MANA`.
- Want one shape to do more? Change its `TARGETS` or `UPTIME`. That says the
  shape is worth less than it looked, so fitting gives it more.
- Want combos to pay more? Raise `BONUS_PER_SLOT` / `BONUS_PER_KIND`.

`tests/balance_test.gd -- --all` prints every spell with its worth split
into hit, burn, poison, freeze, utility.

### Not fitted

- **Cataclysms** (any full queue cast ahead: Meteor, Tempest, Black Hole and the rest) are
  hand-made showpieces in `OverloadFx` at a fixed 40 mana plus loading.
  They may be stronger than the budget, because they empty your queue.

## Enchantments: a store you shoot up

An enchantment (RS) is priced like a spell: loading plus 8 mana an element.
It turns that into a **store of damage** of price × 9 × its target
(`enchant_store`). Every enchanted bolt and every enchanted swing spends what
it is worth from the store (`enchant_shot`, `enchant_swing`), counted the
same way as everything else. When the store is spent the sword is steel
again; it also ends after 20 seconds. So it is a short, strong buff: an
enchanted bolt hits 2.5 times as hard as a loaded one (`ENCHANT_BOLT`), and
the harder you shoot, the faster it is gone. As it runs low, the element
draws back to the sword's edges.

`tests/balance_test.gd` prints how long a few enchantments last while you
only shoot, and how many swings they are, and fails when one lasts under 2
seconds or past the time limit.

**Sentries** (planting a full queue of five) are fitted like the rest, but
cost a fixed 50 mana plus loading (`SENTRY_COST`), so they are the big plant.

## Bolts: the free attack

A bolt costs nothing to fire. Every element's bolt stream is worth about
**12 damage a second** (`BOLT_DPS`), counting status and utility the same
way as spells, a little more when its bolts are harder to land (`skill`:
slow bolts, few a second, or thrown in an arc). Each element flies its own
way (`FLIGHT`):

| Element | Shots/s | Speed | Range | Arc | Feel |
|---|---|---|---|---|---|
| Fire | 6 | 22 | 16 | | the steady stream |
| Frost | 4 | 36 | 22 | | fast, far needles |
| Water | 9 | 16 | 9 | yes | a short hose |
| Lightning | 5 | instant | 11 | | a spark from the staff, no projectile |
| Earth | 1.5 | 15 | 13 | yes | a heavy thrown rock |
| Air | 7 | 30 | 18 | | quick gusts |
| Poison | 3 | 11 | 10 | yes | slow lobbed globs |
| Void | 2 | 9 | 15 | | slow, heavy orbs |

A fusion flies like the average of its two parts. The strength of one bolt
follows from that (`bolt_scale`), so a rock hits about five times as hard as
a fire spark. Loading an element (3 mana) gives 1.35 seconds of its bolts
(`AMMO_TIME`): 8 fire bolts, 2 rocks. In a mixed queue the front element sets
how the bolt flies; every element in it keeps its own worth a second.

A plain bolt (empty queue) does 0.12 of an earth hit: weak on purpose, so
loading is worth it.

## Where mana comes from

**Souls.** Every monster that dies drops blue mana shards worth
**0.15 mana per point of its health** (`SOUL_MANA_PER_HP`). A 40 HP ghoul
gives 6 mana, a 240 HP brute 36, and a boss caps at 10 shards. Walk over
them to take them; close by, they drift to you. A wizard with full mana
leaves them for the others. They fade after 14 seconds.

Besides souls:

- regen of 3 mana a second, so an empty wizard is never stuck for long
  (`MANA_REGEN`);
- 3 mana for a staff hit, and 3 for a deflected bullet.

Bolts no longer give mana. Going in for the souls is the risk that pays for
your spells.

### The loop in numbers

A pack of about 600 HP of monsters drops about 90 mana. Spending it all on
spells at 5 damage per mana kills about 450 HP. Bolts and the staff have to
do the rest, so the souls of one fight pay for most, but not all, of the
spells in the next.

## The staff swing

RB swings the staff in an arc of ±75° and 2.6 m (`SWING_ARC`,
`SWING_REACH`). It knocks enemy bullets back at twice their power. You
cannot shoot or cast during the swing (0.34 s). After it, the staff needs
0.7 s to recover (`SWING_RECOVER`): the gem goes dark and flashes when it is
ready again.

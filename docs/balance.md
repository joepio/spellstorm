# Balance

How Spellstorm keeps attacks from running away with the game. The numbers
live in `src/spells/balance.gd`. `tests/balance_test.gd` checks every
reachable spell against them, and CI fails when one leaves the band.

## The exchange rate

**1 mana buys 5 damage** (`Balance.DMG_PER_MANA`).

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
  of the spell lands. A spray lands every second of its duration, an arc
  on every zap, a nova once.
- **Burn:** 7 damage a second, at most 6 seconds past the last hit.
- **Freeze:** worth 12 damage, since it holds a monster still.
- **Utility, in damage per unit:** push 1, wet 1, slow 3, shock 2. Wet and
  shock are combo enablers (shock does double on wet), so they count, but
  not as much as damage.
- **Healing a friend:** 0.6 × the healing, for an expected 1.5 friends.

### How many monsters a shape hits

| Shape | Targets | Lasting? |
|---|---|---|
| projectile (boulder, lava bomb) | 1, 1.9 with splash, 1.5 for piercing ice | no |
| beam | 1 (it stops at the first) | yes |
| spray | 2 | yes |
| arc (chain lightning) | 1 + hops, at most 3 | yes |
| nova | 3 | no |
| field | 2, standing in it 40% of the time | yes |
| totem | 1 + hops, monster in range 60% of the time | yes |
| rune | 2.5 | no |

These are the assumptions to change when playtests show a shape hits more
or less than this.

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
into hit, burn, freeze, utility and heal.

### Not fitted

- **Wards** protect and **walls** block. These are not damage and are judged
  in play.
- **Overloads** (five of a kind: Meteor, Black Hole and the rest) are
  hand-made showpieces in `OverloadFx` at a fixed 40 mana plus loading.
  They may be stronger than the budget, because they empty your queue.

## Bolts: the free attack

A bolt costs nothing to fire. Loading an element (3 mana) gives 8 bolts.
Every element's bolt stream is worth about **20 damage a second**
(`BOLT_DPS`), counting status and utility the same way as spells. A water
bolt does little damage but soaks and shoves; a fire bolt does less on
impact and burns. The `BOLT` table sets the per-element strength, and the
test checks each one against the band.

A plain bolt (empty queue) does 0.2 of an earth hit: weak on purpose, so
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

A room of about 600 HP of monsters drops about 90 mana. Spending it all on
spells at 5 damage per mana kills about 450 HP. Bolts and the staff have to
do the rest, so the souls of one fight pay for most, but not all, of the
spells in the next.

## The staff swing

RB swings the staff in an arc of ±75° and 2.6 m (`SWING_ARC`,
`SWING_REACH`). It knocks enemy bullets back at twice their power. You
cannot shoot or cast during the swing (0.34 s). After it, the staff needs
0.7 s to recover (`SWING_RECOVER`): the gem goes dark and flashes when it is
ready again.

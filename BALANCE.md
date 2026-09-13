# Morrowind: Dreamforged balance target

## Level-one class baseline

The five optional Ashen classes use ordinary Morrowind favored attributes,
specializations, and major/minor skill assignments. On first load after character
creation, the player script adds +10 to each class major and +5 to each class minor
(+75 skill points total). Miscellaneous skills receive nothing. This creates a
deliberately steep specialist profile and improves reliability in the chosen play
style without increasing every defense, resource, or damage channel and without
granting free equipment or powers.

The boost is saved after application and never repeats. It does not erase racial
bonuses; vanilla classes receive no bonus.

Each Ashen class receives one ordinary starter kit. The kits solve immediate
weapon/armor/ammunition/resource gaps, but use low-tier vanilla items and no
Ashen affixes so generated drops remain the upgrade engine. Direct inventory
delivery avoids permanent Census Office edits and ensures irrelevant class kits
are never created.

War Mage receives four cheap combat fundamentals; Conjurer receives five low-level
spells spanning its five major schools, including Summon Ancestral Ghost. These
are existing vanilla spells, not stronger custom variants.

The target is Diablo 1 pressure translated to Morrowind scale: more frequent discrete fights, dangerous promoted enemies, and enough recovery to continue exploring without turning every cell into a modern swarm arena.

## Default encounter budget

| Area | Base budget | Density | Effective reserved budget | Typical generated group |
| --- | ---: | ---: | ---: | ---: |
| Exterior cell | 6 | 1.5 | 9 | 3 |
| Recognized dungeon cell | 3 | 1.5 | 5 | 2 |

These are saved lifetime ceilings per cell, not guaranteed populations. Town suppression, insufficient hostile anchors and failed placement can reduce the realized count. Existing processed cells do not refill or reroll.

The `Encounter density multiplier` is the main pacing control. A value of 1.0 restores the original 0.5 budgets/groups; 2.0 produces about 12/6 reserved enemies with groups around 4/2. Values above 2 are intentionally experimental.

The default wilderness spread is 1,000 units (about 47 feet / 14 meters). Additional creatures use offsets from 20% to 100% of that radius, keeping them close enough to read as a group. Larger values create dispersed one-off encounters instead.

## Enemy and equipment curves

New encounter level remains the greater of native level and a gently randomized player-influenced level. For every level added above native level, ordinary health gains `3 + min(8, 8% of native health)` before the user health multiplier. Strength gains 1.1 per added level before the damage multiplier. This gives low-level creatures enough durability to remain meaningful while making naturally durable enemies scale faster.

Champion, Elite and Unique health multipliers remain 1.2 / 1.5 / 1.9 after ordinary scaling. Their primary power scaling follows encounter level. Similar creature mode is the balance baseline. Random mode may select a naturally high-level creature at low player level and is deliberately less predictable.

Equipment magical power advances about once every three item levels. Physical-stat bonuses include both rarity/roll quality and a per-level contribution capped at +45 percentage points. Attribute bonuses rise from roughly +6 at level 1 toward the mid-20s around level 30, with rarity bonuses. Items already generated do not change.

## Rewards and recovery

Equipment-drop chances remain per enemy because frequent visible loot is part of the target. Healing and secondary-supply chances are divided by the square root of encounter density. At the 1.5 default, displayed 65% / 25% chances become approximately 53% / 20% per enemy, so higher population still yields more recovery without increasing linearly with every extra body.

Container and NPC inventory remixing changes item variety and quality but does not add items to empty containers. This limits its effect on total item count. Economy value remains a playtest concern because generated equipment is deliberately generous.

## Playtest signals

- If ordinary same-tier enemies take fewer than two meaningful attacks after level 10, raise Ordinary enemy health before raising density.
- If most fights take more than six ordinary attacks, lower health or player-level influence before lowering density.
- If healing accumulates faster than it is consumed across two dungeons, lower Healing potion drop chance.
- If combat becomes visually crowded or actors interfere with navigation, lower Encounter density multiplier to 1.25.
- Judge Random creature mode separately; it is a chaos option, not the reference balance profile.

# Morrowind: Dreamforged

**Current release: 0.10.15 - persistent outdoor pressure.**

## 0.10.15 Persistent outdoor pressure

- Wilderness pressure now persists through ordinary, Champion, Elite, and Unique encounters. A successful director group no longer spends or resets the pressure that drives the next encounter.
- Higher non-World-Boss promotions add more pressure and advance the World Boss arc, with only a World Boss victory or a settlement reset fully clearing the outdoor director state.
- Added regression coverage for the high-tier non-boss path so medium encounters can create a short respite without making the wilderness go quiet.

## 0.10.14 Director-safe defaults reset

- **Reset everything** now explicitly restores the new Director intensity and Target World Boss cadence controls alongside every other registered Dreamforged setting.
- Fresh-character initialization uses the same registered control list. Retired granular director keys remain available only for old-save compatibility and are never written back into the streamlined settings menu.

## 0.10.13 Unified action director

- Outdoor pressure now persists across exterior-cell boundaries. Crossing an invisible cell edge can no longer erase a nearly ready encounter.
- Ordinary wilderness kills and lower promotions now build encounter appetite and advance the World Boss arc. They no longer grant long pauses merely because the player engaged them.
- Healthy active exploration works toward a World Boss climax at about ten minutes by default. The chance rises late in the arc and the next eligible director group is guaranteed to contain one when the target is reached.
- World Boss victories release pressure and grant a three-minute recovery window that follows the player across exterior cells; non-boss promotions provide only brief tactical lulls.
- The settings menu replaces seventeen low-level encounter and boss knobs with **Director intensity** and **Target World Boss cadence**. Intensity jointly tunes encounter checks, groups, living threat, dens, and boss reinforcements.

## 0.10.12 Settings reset

- Creature-den particle overlays now use a dedicated removable VFX identity and disappear as soon as the Kwama Queen spawner dies.
- **Reset everything** now lives in a dedicated top section above General and compatibility. The reset is deferred by one update tick, touches only registered Dreamforged settings, and posts a confirmation message so OpenMW can rebuild its native controls cleanly.

## 0.10.9 Adaptive reward pacing

Dreamforged now maintains a saved global reward reserve alongside its encounter-pressure state. Every eligible defeat earns reward credit: ordinary enemies contribute only a trickle, while Champions, Elites, Uniques, and World Bosses contribute progressively more. On a promoted defeat the director may remain frugal, make a steady payout, or spend a large share of its reserve. That payout joins the enemy's personal loot budget, so accumulated effort can become a quality spike without bypassing rank floors or the six-item ceiling.

Promoted encounters that only meet their expected quality raise hidden reward hunger. Above-expected gear lowers it, and a Mythic lowers it sharply. Hunger increases the likelihood of a later payout or spending spree; it never directly guarantees a named item. Credit is earned and spent when enemies die and loot is generated, so leaving items behind, reloading, or farming harmless targets does not create a collection-based exploit.

The Loot settings expose an enable toggle, generosity multiplier, maximum reserve, and base spree chance. The default is intended as a humane single-player pace: no daily hooks, paid scarcity, timed obligations, or visible near-miss manipulation.

## 0.10.8 Loot budgets

- Promoted enemies now receive a power budget based on promotion rank, level, player overgear, and configured difficulty. The budget buys a small bounded package and spends leftovers upgrading quality instead of producing piles of cheap items.
- Champion, Elite, Unique, and World Boss packages have progressively higher quality floors and hard item-count limits. World Bosses cannot turn their budget into Common-through-Epic filler and retain one independent configurable Mythic chance.
- Ordinary creatures and enemies usually provide arrows, potions, and other supplies rather than procedural equipment. Procedural gear remains a modest lucky roll, while promoted encounters are the main loot-hunt loop.

## 0.10.7 Creature dens and threat budget

Outdoor director rolls can now become stationary, destructible creature dens built from a dynamically cloned Kwama Queen. A den receives one of four identities—Brood Nest, Grave Brood, Profane Hatchery, or Dwemer Incubator—and a matching magical visual treatment. Its family determines whether it produces beasts, undead, Daedra, or constructs. Dens begin their first wave after five seconds, produce a configurable 1–3 cycles by default, stop permanently when killed or exhausted, and grant a short local respite when destroyed.

Den tier is gated by combined character power: early characters receive Lesser dens, tier two becomes available around effective level 10, and Greater dens around effective level 25. Tier raises both durability and wave size. The exterior cap is now a threat-point budget rather than a headcount. Enemies near the player's combined level and best-equippable gear score cost roughly one point, while deliberately weaker enemies cost as little as 0.35; this naturally allows larger late-game groups without burying a new character.

Settings expose den chance, wave interval, and minimum/maximum cycles. The default den chance is 12% of successful outdoor director encounters.

## 0.10.6 Outdoor pressure director

Exterior encounters now originate from the moving player rather than individual native creature anchors. Every configurable interval, the director considers the current nearby threat count, player health, settlement status, and accumulated quiet-time pressure. Successful rolls place a bounded group ahead of the player's trajectory on validated walkable ground and send it toward the player. Failed rolls raise the next chance, creating waxing and waning pressure without spending an entire cell population at once.

The exterior budget now caps living director additions near the player instead of imposing a lifetime spawn quota. Champion, Elite, and Unique victories create progressively longer pauses; defeating a World Boss creates a three-minute local safe window for looting. Hostile interiors retain their existing compact-cell population system.

## 0.10.5 World Boss reward table

Every World Boss now produces six rewards from a dedicated base table: 1%
Common, 2% Uncommon, 7% Rare, 20% Epic, 30% Legendary, 20% Relic, and 20%
Mythic per reward. Encounter level, gear overage, and enemy health/damage
settings can promote a rolled result upward by one tier without distorting the
base table through percentile overflow. Spell tomes no longer replace one of
these six boss rewards.

Cell population state now stores an explicit additional-enemy count. Native
actors and random identity replacements never consume this budget, and World
Boss reinforcements remain governed by their own living-add cap. Existing
saves migrate their old extra-enemy counter into the new field.

## 0.10.4 natural World Boss rewards

World Bosses no longer receive a forced Relic or duplicate equipment reward.
They use the normal six-attempt promoted-enemy ladder, with rank and gear
bonuses widening the Relic slice without overflowing into it. At the default
World Boss bonus this is roughly a 12% Relic chance per successful attempt
(about 54% for at least one across six attempts); Mythic artifacts remain a
separate 10% base World Boss roll, increasing with gear overage.

## 0.10.3 rarity color and weighting fix

Ground-drop lights now use the same canonical RGB palette as the salvage menu
and target cards, so Common through Relic are visually consistent everywhere.
Rarity bonuses no longer collapse every percentile that overflows 100 into a
Relic. The natural Relic slice remains small and stable; World Bosses still
receive their explicit Relic reward, while Mythic artifacts remain a separate
rare boss roll.

## 0.10.2 player handoff and rarity polish

Fresh procedural equipment dropped by Dreamforged is reserved for the player
while it remains on the ground, so nearby civilians cannot carry off the reward
before it is seen. Once the player picks it up, the reservation is cleared; if
the player later drops that item, it behaves like ordinary unowned equipment and
NPC scavengers may collect it. Player-dropped non-Dreamforged gear is eligible
immediately. World Boss corpses retain their saved name, lore, and modifiers and
now identify themselves as `WORLD BOSS` instead of falling back to the base
creature name. Natural Relic rolls are reachable, and Legendary/Relic rewards
use equal family weighting so the small armor pool cannot crowd out high-tier
weapons.

## 0.10.1 terrain-aware ground drops

Ground rewards retain their forward-biased spread, then use the player's local
physics raycast to snap each item and its rarity light to a nearby walkable
surface. Exterior slopes and uneven dungeon floors should now be easier to
reach; unusual geometry keeps the original lifted position as a fallback.

## 0.10.0 layered enemy loot

Enemy rewards now use a looter-style pipeline. Each successful reward first rolls Weapon (50%), Armor (40%), Clothing (5%), or rings/amulets/other Accessory (5%). Weapon rewards then roll melee, ranged, or magical staff/wand; the player's class or strongest skill specialization gives its preferred archetype 55% weight while leaving the other styles available. A slot/subtype is chosen before an individual base record, preventing large modded melee catalogs from crowding bows and staves out.

Common is a new grey, no-affix tier below Uncommon. Uncommon has one affix, Rare has two, and Epic, Legendary, and Relic add progressively more effects. Mythic world-boss artifacts remain a protected special class rather than ordinary forge fodder. Existing saves migrate their old Magic-through-Relic items and forging coins upward into the new six-tier scale.

Ordinary enemies make one configurable reward attempt rather than receiving a guaranteed item. Champions, Elites, Uniques, and World Bosses make 2/3/4/6 attempts with increasingly favorable rarity rolls. Promoted attempts have at least a 97% success chance, so two Champion attempts both missing is a rare 0.09% event. Promotions do not force a trophy or rarity floor: every successful result still makes an honest Common-to-Relic roll, with better enemies merely shifting the odds upward. The family roll is now 50% Weapon, 40% Armor, 5% Clothing, and 5% rings/amulets/other Accessories. Curated spell tomes use the mage Weapon branch (alongside staves and wands), so they do not consume the small universal accessory share; their availability is intentionally limited to early/mid encounter bands. Ground rewards are enabled by default for new settings and spread in a forward-biased fan toward the player; disabling ground drops puts every generated reward into the corpse.

Dreamforged now supplies the general hostile-target display: ordinary and promoted enemies under the crosshair show a compact top-center name and health bar. Dead ordinary enemies replace it with a compact corpse summary; inspecting promoted corpses reveals the full modifier descriptions. World Bosses keep their separate long bottom health bar. Disable other actor-healthbar Lua widgets to avoid duplicate displays.

Unique and World Boss corpses also preserve a short generated history. Unique biographies combine creature-family origins, transformations, and one of the enemy's actual powers. Each creature World Boss title has its own lore fragment, followed by a power-aware sentence; NPC bosses use their preserved authored identity. The finished text is generated once at promotion and saved with that individual actor.

## 0.9.9 archetype drops and spell learning

Generated equipment now selects an archetype category before selecting an individual base. This fixes large load orders where hundreds of melee records numerically overwhelmed the smaller staff and bow pools despite their old per-record multipliers. Ashen War Mages, Conjurers, and Magic-specialized characters now strongly favor magical cast-on-use staves/wands; Archers strongly favor generated bows/crossbows whose effects operate at range. The overall family roll is 50% weapons, 40% armor, 5% garments, and 5% jewelry/accessories; the preferred weapon archetype is then weighted within the weapon branch. Other categories remain possible so drops are influenced rather than class-locked.

Twenty-four curated permanent spells are split across two early/mid encounter-level bands. Examples range from Ember Dart, Hearth Mend, Ash Shell, and Ancestor's Call through Triune Bolt, Aether Well, Tribunal Ward, Elemental Ruin, and Gate of Oblivion. A defeated enemy has a configurable 5% base tome chance; Magic profiles receive triple weight, non-Magic profiles half weight, promoted enemies improve the chance, and world bosses receive the strongest bonus. A small 10% roll can expose the next band early. Known spells and tome records already carried are removed from selection. Using a tome permanently adds its spell and consumes that tome; the strongest vendor-like effects remain rare without competing with true endgame generated gear.

## 0.9.8 ammunition supplies

Defeated enemies can now carry ordinary arrow or bolt bundles as a separate supply roll. The default base chance is 15%; Marksman contributes up to another 50 percentage points, while carrying or equipping a bow/crossbow contributes 25 and determines the compatible ammunition type. Encounter density normalizes the final chance so larger hordes do not create ammunition in direct proportion to every additional body. Bundle size also rises modestly with Marksman. Ammunition is selected from safe, unenchanted records loaded from Morrowind, its expansions, and installed content mods, with material strength trending upward with encounter level while retaining random variation. The base chance is configurable from 0–100 under Loot.

## 0.9.7 automatic loot filters

The Loot settings now contain independent auto-salvage toggles for Magic, Rare, Epic, Legendary, and Relic/Mythic Dreamforged gear. All are off by default. When a filtered item is newly added to the player's inventory, it is immediately removed and converted into one matching forging coin. Items already carried when a filter is enabled are not swept, equipped records are protected, and an item deliberately purchased through the reforging exchange is exempt from the acquisition scan. This makes ground-loot pickup useful without turning late-game inventory management into a weight-limit chore.

## 0.9.6 salvage and reforging exchange

Press F7 by default to open the Dreamforged Reforging Exchange. The single window has clearly divided instructions, forging/combining controls, and salvage controls. Every unequipped generated item is listed individually from Common through Relic so disposable gear appears before likely keepers; clicking one salvages a single copy into one forging coin matching its rarity. Equipped items are omitted from the list and rejected again by the global transaction handler. Five coins of one rarity create one random new item guaranteed to have that rarity; the exchange does not require gold, keeping it separate from Morrowind's normal economy. Three coins of any tier below Relic can also be combined into one coin of the next tier, providing a Horadric-Cube-style path from plentiful low-rarity finds toward rare reforges. Base quality, equipment category, affixes, numerical rolls, and weapon style remain random.

Coin balances are saved per character. This abstract exchange is an initial frontend; the backend can later support physical coins, a broker, and a Tribunal-style reforging altar.

## 0.9.5 native and modded base-quality progression

Generated equipment now rolls an independent base-quality band from 1–8 before rarity, affixes, and weapon style are applied. At level 1 the approximate distribution is 34/20/15/12/8/6/4/1 percent across bands 1–8, so an exceptional roll can produce an ebony-, glass-, or Daedric-class base immediately while ordinary materials remain overwhelmingly more likely. Character/encounter level gently shifts the entire distribution upward without removing any band.

The material chart is built dynamically from every eligible unenchanted weapon, armor, and clothing record loaded by OpenMW. Items are compared within their native equipment subtype using damage or armor, durability, enchant capacity, and value. This places Tribunal, Bloodmoon, Tamriel Rebuilt, and other mod-added visual/material variants alongside statistically comparable vanilla equipment without requiring explicit compatibility patches or hard-coded mod names. Scripted, enchanted, quest-labeled, unique-labeled, artifact-labeled, placeholder, and test records remain excluded in safe mode. Unsafe Chaos can admit the broader set.

Base quality is shown in generated-item details as `Base quality tier X/8`. It also contributes to effective gear score, because a top-material weapon or armor piece matters even before its procedural rarity and affixes are considered. Existing generated items retain their original base record and behave as quality tier 1 for gear-score metadata compatibility; newly generated items use the new system.

## How to install

Morrowind: Dreamforged requires **OpenMW 0.51 or newer**. It has no required dependency on Fresh Loot, Pretty Loot, or World Randomizer.

### OpenMW Launcher

1. Extract the archive into its own folder, preserving the included `scripts` and `l10n` directories. Do not extract it over Morrowind's original Data Files folder or over an older Dreamforged release.
2. Open the OpenMW Launcher and select **Data Files**.
3. Add the extracted Dreamforged folder as a data directory. If an older Dreamforged/AshenLoot folder is already registered, disable or remove that old directory so only the newest version is active.
4. Enable `AshenLoot.omwscripts`. Enable `AshenLoot-Classes.esp` as well if you want the five Dreamforged starting classes and their starting kits.
5. Keep `AshenLoot-Classes.esp` after the official Morrowind, Tribunal, and Bloodmoon master files. The Lua file can remain with the other `.omwscripts` entries.
6. Start or load a game, then open **Options → Scripts → Morrowind: Dreamforged** to select a preset and tune individual systems. F8 opens the loot browser and F7 opens the reforging exchange by default. Restart OpenMW after replacing an installed version.

### Manual `openmw.cfg` setup

Add the extracted folder and required Lua entry to your OpenMW configuration, replacing the example path with the real location:

```ini
data="C:/Games/OpenMWMods/Dreamforged-0.10.15"
content=AshenLoot.omwscripts
```

For the optional starting classes, also add:

```ini
content=AshenLoot-Classes.esp
```

Use only one Dreamforged/AshenLoot version at a time. Updating the mod does not require removing existing saves, but already-generated items and already-processed encounters retain their saved rolls.

## 0.9.4 configurable boss reinforcements

The Bosses settings group now exposes the first reinforcement delay, repeat interval, minimum and maximum wave size, and maximum living adds per World Boss. Defaults preserve the existing 20-second opening, 30-second repeat, 1–3 enemy waves, and six living adds. Setting the living-add cap to zero disables boss reinforcements independently of ordinary encounter generation.

## 0.9.3 active World Boss ceiling

Living World Bosses now obey a configurable active-cell ceiling, default 1 and maximum 10. The limit is checked immediately before each actor enters the promotion ladder, so the first successful World Boss reserves the cell while later promotions fall through to Unique, Elite, or Champion. A dead boss or one that leaves the cell frees the slot. Ordinary generated-population limits remain separate.

## 0.9.2 per-actor encounter and boss rolls

Exterior encounter activation is explicitly per native actor: when an eligible actor enters the configured player-distance band, it independently rolls to create one bounded group. The cell owns only the hard ceiling on generated population. Generated actors never become anchors. Promotions now use a fully configurable descending ladder: promotion chance, then World Boss, Unique, and Elite conditional chances, with Champion as the fallback. This permits rare multiple World Bosses in one cell and removes the former once-per-cell boss lottery. Settings now distinguish anchor activation distances from reinforcement placement distances.

## 0.9.1 exterior activation and wilderness resets

Exterior anchors now activate inside a configurable player-centered band (default 300–2200 units) across all active exterior cells, including visible adjacent cells. The minimum is an activation delay against already-melee-range anchors; the separate spawn exclusion radius applies only around the player, no longer around the native anchor. Successful additions retain their forced aggression and pursue the player. Cliff racers remain valid anchors even when the “exclude extra cliff racers” option prevents them from being selected as reinforcements. Exterior cells become eligible again after 72 game hours away by default, retaining any surviving generated enemies and reopening native anchors until the cell budget is filled. Every numeric setting label now displays its maximum accepted value.

## 0.9.0 uncapped progression and usability

Player and encounter levels are no longer capped at 100. Above level 100, enemies receive a continuous `level / 100` prestige multiplier to both baseline health and physical strength before promotion and gear-pressure bonuses (for example, 5x at level 500). Generated item metadata also retains uncapped drop levels, while the physical weapon ceiling remains protected from runaway charged damage. The settings page is split into eight ordered, documented groups, with existing saved values migrated automatically. Ground equipment rewards now land 110–360 units toward the player at the corpse's walkable elevation, scaled for corpse size; their rarity light follows the shifted item.

## 0.8.9 boss escalation loop

Gear-pressure health is now concentrated on promotions: Champions receive 25% of the extra multiplier, Elites 50%, Uniques 75%, world bosses 100%, and ordinary enemies none. At maximum pressure a world boss reaches 3x health on top of its existing 4.5x boss baseline. Overgearing can improve a promoted enemy's rarity floor and increases world-boss Mythic chance from 10% up to 40%. Fighting world bosses call 1–3 additional creatures after 20 seconds and every 30 seconds afterward, with at most six living boss reinforcements and no recursive spawning.

## 0.8.8 rarity-aware enemy durability

The best equipable Dreamforged gear combination now gives Rare, Epic, Legendary, Relic, and Mythic items increasingly substantial effective-level premiums instead of treating rarity as a nearly cosmetic +1 per tier. When effective gear level exceeds player level, newly processed enemies also gain up to 3x additional health scaling. Enemy damage is not increased by this durability response. Procedural weapon damage is now level-capped with a hard maximum of 120 because Morrowind's minimum/maximum values represent quick versus fully charged attacks—not a random damage roll. Strong native artifact damage is preserved.

## 0.8.7 bounded exterior groups

Each eligible native exterior creature now makes one configurable anchor roll when the player approaches. A successful anchor creates only the configured group size (default 1–3), and generated enemies can never generate another group. Spawns use a configurable ring (default 450–1000 units from both the player and anchor), while the existing density and exterior-budget settings remain the per-cell ceiling. This spreads high-density encounters across native anchors without enemies materializing on top of the player.

## 0.8.6 wilderness hordes and full safe variety

Exterior anchors now wake only when the player comes within the configurable
trigger range (default 1,800 units), so a cell spends its budget around the route
being explored instead of distant loaded creatures. Maximum density progressively
relaxes placement after strict attempts fail, allowing the full 48-enemy maximum
to form near viable terrain rather than silently refunding most slots.

Random mode draws from the full safe land-capable catalog at every player level:
Morrowind, Tribunal, Bloodmoon, Tamriel Rebuilt, and loaded creature mods. Only
clear quest/unique/summon/pet/generated identities and nongeneric scripted actors
remain protected. Selected creatures are scaled into the configured encounter
band after spawning, so exotic high-level bases can appear in weakened form for
low-level characters.

## 0.8.5 population-anchor fix

Unsafe Chaos broadens which identities may be promoted, transformed, or used as
item bases, but unsafe-only actors no longer generate reinforcement groups. The
ordinary cell budget and encounter pacing are therefore identical with the
switch on or off. Safe mode also recognizes respawning scripted creatures as
ordinary encounter records, improving wilderness density with mod-added fauna
without admitting protected quest specimens.

## 0.8.4 unsafe chaos

The default-off **Unsafe chaos: include protected actors and items** setting
admits scripted, essential, unique, service, companion, artifact, quest, and
normally excluded records into Ashen actor and procedural item pools. This can
produce deliberately absurd outcomes such as a promoted Vivec carrying an
affixed Keening copy. Godmaker also accepts peaceful protected targets in this
mode. It can break quests or services and may replace important carried items;
turning it off does not undo changes already made.

## 0.8.3 controller ability bindings

Controller defaults are **hold RB + D-pad Left** to cycle advancement abilities
and **hold RB + D-pad Right** to activate the selected ability. Modifier, Cycle,
and Activate buttons can each be changed under Options -> Scripts -> Ashen Loot.
Targeted techniques use the crosshair. Use three distinct buttons; OpenMW may
also perform a button's ordinary game binding when the combo is pressed.

## 0.8.1 world-boss mythics

Ten mythic staves and four strange wearables occupy a 10% slice of world-boss
Relic outcomes. Projectile-driven staves can transform safe creatures, create
dueling corrupted copies, revive safe fallen actors temporarily, summon random
friends or enemies, summon Daedra, reroll/promote NPCs, or repeatedly elevate a
hostile actor through World Boss. Mythic copies and summons expire after two
real-time minutes. Quest-sensitive actors are protected.

The wearable pool includes permanent levitation pants, extreme-speed/blinding
boots, an intellect/silence helm, and a chameleon/burden ring. These are
intentionally allowed to be bizarre and badly behaved as rare chase items.

## 0.8.0 Ashen advancement

Every skill awards passives at 50, 75, and 100, and every 75-point skill has a
distinct active technique. Combat, Magic, or Stealth specialization separately
grants rewards every five character levels from 5 through 50. Existing
characters receive earned milestones automatically.

Actives support flat or percentage Health/Magicka/Fatigue costs, real-time or
game-time cooldowns, and independently recovering charges. Shift+the configured
loot-browser key cycles unlocked actives; Ctrl+that key activates the selected
technique. Targeted techniques use the crosshair. Blood Covenant and Grave
Hunger provide Health-powered necromancer options.

## 0.7.10 named NPC bosses and caster/ranged loot

NPC world bosses keep their real name and receive a compact prefix or suffix
drawn from race, combat/magic/stealth specialization, and generic
Morrowind-themed pools. Existing saved NPC bosses migrate automatically.

Magic-focused characters favor mana and scroll supply rolls. Generated scrolls
span fire, frost, shock, direct damage, control, and defensive wards, with rare
enhanced versions. Safe unenchanted staff/wand records from loaded mods may act
as generated caster-weapon bases. Successful bow attacks forward all Ashen
custom weapon procs from the equipped bow.

## 0.7.9 class-aware loot and encounter gear scaling

Generated loot now leans modestly toward the player's specialization (Ashen
class when present, otherwise combat/magic/stealth skill totals) without
removing off-theme drops. New generated records show a **Drop level** matching
the encounter's persisted scaled level, and their stat/proc scaling uses that
level. The best equipable combination of tracked Ashen gear in the player's
inventory also contributes a small gear-equivalent level to future encounter
scaling; `gearLevelInfluence` defaults to 0.5 and can be set between 0 and 1.

## 0.7.8 recovery potions and loose dungeon loot

Generated recovery potions now use a Diablo-style five-name ladder: Minor,
normal, Major, Greater, and Super Healing/Mana/Stamina Potions. Numeric bands and
the Ashen Draught naming are gone from display names. Replenishing two-effect
versions retain a short `Replenishing` prefix. Health uses the native warm-red
exclusive bottle, mana the blue quality bottle, and stamina the green bargain
bottle; underlying effect magnitude still scales through all twenty five-level
power bands.

A new conservative one-time pass can remix loose shelf and floor items in
ancestral tombs, Daedric shrines/ruins, and Dwemer ruins. It defaults on at a 15%
selection chance and is separately toggleable. Each selected eligible equipment
piece rolls 55% similar ordinary native gear, 30% broader level-banded valuables,
10% native enchanted gear of the same subtype, and 5% Ashen-generated gear.
Non-equipment items use the same gradient with the inapplicable Ashen slice
folding into native treasure.

Only original placed instances are considered. Owned, scripted, player-dropped,
dynamically created, already enchanted, quest-like, over-level-value, container,
and book records are excluded. Replacements retain the original position,
rotation, scale, and stack count. Each eligible cell is marked after its first
pass and never rerolled in that save.

## 0.7.7 NPC gear gradient

NPC equipment no longer turns every eligible equipped weapon, armor, and
clothing slot into generated Ashen gear. Each slot is remixed within the same
equipment type so the NPC keeps a recognizable combat role. Most results are
level-banded ordinary native gear, a smaller tier is level-banded native
enchanted gear, and the rare top tier is Ashen-generated gear.

The new **NPC generated gear chance (%)** setting controls the ordinary NPC
top-tier chance and defaults to 5%. Rank acts like container quality: default
per-piece Ashen chances are 5% ordinary, 10% Champion, 17% Elite/dungeon leader,
25% Unique, and 35% world boss. Guards use 15%. Setting the base to zero disables
Ashen gear on NPC loadouts. Rolls are independent and uncapped, so a complete
generated set can still occur as a genuine anomaly; at 5%, three generated
pieces on an ordinary NPC are about a 1-in-8,000 event before rarity rolls.

Native-enchanted chances are 12% ordinary, 17% Champion, 22% Elite, 27% Unique,
and 30% world boss; guards use 25%. Everything else stays ordinary native gear.
All value ceilings and generated effects use the NPC's encounter target level.
Generated death rewards remain separate, so a named enemy can still provide its
guaranteed trophy in addition to whatever it actually carried. Replaced equipped
items are removed instead of leaving duplicate originals on the corpse.

## 0.7.6 container cache pass

The old same-category container remix technically worked, but was almost
invisible: bonemeal generally became another low-value ingredient. Containers
selected by the existing Container randomization chance now use a level-aware
native-loot gradient. A regular selected container gives each replaced stack a
70% believable same-category roll, a 25% broader valuable-native roll (including
gems, pearls, ordinary soul gems, and currency), and a 5% native enchanted-gear
roll. These are native items, not Ashen affixed records. Chests and locks shift
the gradient upward; a level-80 locked chest is approximately 29% ordinary, 45%
valuable native, and 26% native enchanted per replaced stack.

Each selected container independently rolls for a generated Ashen equipment
piece as a fourth, separate layer, with no dungeon cap. A regular selected urn has a 25% gear roll; chests
add 25 percentage points and lock difficulty adds up to 40. Chests are also more
likely to pass the base remix roll: chest status adds 20 percentage points and
lock difficulty adds up to 40. At the default 30% setting, an ordinary urn has
about a 7.5% overall Ashen-item chance, while a level-80 end chest lands near
80%. Most container-rich dungeons should average roughly one or two generated
pieces, but three to five remains possible on a lucky run.

Chest status and lock level also raise minimum-rarity odds. At lock level 80, a
selected chest has a 90% Rare-or-better boost chance and a 30% Epic-or-better
boost chance.
Ordinary containers still have a chance, and the six-tier Common-to-Relic
gradient remains the baseline (43% / 32% / 15% / 6% / 2% / 2%). Promotion
bonuses shift results upward without overflowing into Relic; World Bosses add
one explicit Relic reward on top of their normal attempts.
Owned, scripted, and previously processed containers remain protected. Each new
dungeon writes a compact cache summary to `openmw.log`.

## 0.7.5 encounter range and dungeon reruns

Random encounter mode now draws uniformly from safe, land-capable creature
records in every loaded leveled-creature list. That automatically includes
Morrowind, Tribunal, Bloodmoon, and mod creatures integrated into those lists.
Peaceful actors and fish can be anchors, but generated additions are placed on
land and receive hostile AI; swim-only records and hand-authored quest specimens
are excluded. Similar mode retains the regional/family behavior.

Exterior groups now continue outward through newly placed members until the
configured per-cell budget is filled. This keeps the 1,000-unit group feel while
preventing one sparse native anchor from leaving most of an 8,192-unit cell's
budget unused. The saved cap remains absolute, so high budget/density settings
now intentionally can flood a cell without an unbounded spawn loop.
Existing 0.7.4 exterior pack members are reconsidered once when active, allowing
partly spent cells to finish their saved budget; dead/removed packs are not
recreated. Newly visited cells provide the cleanest density test.

Creature encounters now target a configurable player-relative range. The
defaults allow four levels below through ten above the player, blended with the
native creature's strength by Level scaling. High-native-level creatures can be
downscaled in level, health, magicka, and strength, while the upper margin still
permits dangerous surprises. Generated Random-mode creatures normalize most
strongly, so a level-one character can encounter the broad catalog without
meeting an unchanged level-50 monster.

Recognized hostile interiors are rerunnable by default. After the mod observes
the dungeon's hostile population, detects it cleared, and the player leaves,
Ashen Loot can create a fresh randomized wave after 72 in-game hours. The wave
uses remembered safe actor positions, is level-scaled, persists in the save, and
can produce normal Ashen loot. It does not reset quests, resurrect native actors,
or reroll containers, avoiding damage to quest state and player storage.

## 0.7.4 reactive equipment effects

The procedural pool now includes Bloodletter open wounds, Dreambinding paralysis,
safe Beast/Will Command, Storm-Branching chain lightning, Crushing Blow, elemental
on-hit spell echoes, when-struck novas, and Briar Ward thorns.

| Affix | Equipment behavior |
|---|---|
| Bloodletter / Blood-Warded | Five-second level-scaled Damage Health on weapons; Restore Health on wearables |
| Dreambinding / Wakeful | One-second Paralyze on weapons; Resist Paralysis on wearables |
| Beast-Binding and Will-Binding | 18% chance to Command a safe creature or humanoid for 6 seconds; never affects players, essential/scripted actors, or service providers |
| Storm-Branching | Shock damage plus a 25% chance to arc to the nearest hostile within 500 units |
| Of Crushing Weight | 18% chance for capped current-health damage; world bosses take 35% of the ordinary proc |
| Of Arcane Echoes | Weapons have a 25% elemental-burst chance; wearables have a 20% when-struck shock nova |
| Of the Briar Ward | Wearers retaliate against melee attackers with level-scaled damage, limited to once per second |

Each scripted proc uses its own cooldown. Multiple equipped copies of one proc do
not stack; the strongest equipped version is used. These effects appear in native
item enchantments where possible and in the target card/F8 details for scripted
behavior.

Settlement population suppression is now toggleable. When disabled, populated exterior cells may receive replacement creatures and additional groups, but guards themselves are never used as monster-spawn anchors. Recognized guards receive a separate default-on progression pass: their target level is at least 80% of player level plus four, their health and strength use a 1.35 multiplier, and their generated gear targets six levels higher with Rare-or-better minimum rarity. Guard power is adjustable from 1.0 to 2.5.

Citizens remember successful scavenged upgrades. With one upgrade they proactively intercept aggressive creatures within 375 units; two upgrades extend that to 500; three or more to 625. They still avoid proactive defense below 35% health and retain the immediate attacked-by-creature response above 20% health.

## 0.5.1 Diablo 1 balance pass

Version 0.5.1 adds an encounter-density multiplier defaulting to 1.5. With the existing 6/3 base budgets this reserves about 9 additional exterior enemies and 5 additional dungeon enemies per new cell, normally in groups of 3/2. Level-added enemy health now accounts for native durability, strength grows more meaningfully with added levels, and healing/supply chances are normalized by the square root of density. See `BALANCE.md` for the full target and tuning guidance.

## 0.5.0 remix and variety pass

Ashen Loot 0.5.0 layers broad Morrowind loot remixing underneath its Diablo-style equipment. Eligible dungeon containers and hostile NPC inventories can replace safe existing contents with level-aware items drawn from loaded game/mod records. Replacement weapons, armor and clothing receive Ashen Loot rarity, physical-stat rolls and enchantments; ordinary supplies remain ordinary randomized supplies. Scripted/quest-like items, owned or scripted containers, and equipped originals are protected. Defaults are 30% of eligible dungeon containers and 45% of eligible hostile NPC inventories, with separate toggles.

Ground equipment can receive a small pulsing rarity-colored light. NPC scavengers scan farther and accept smaller upgrades without requiring one exact idle-package label. Extra encounters can match the anchor's family/level or draw from the full curated safe land-creature pool. A separate default-on toggle prevents additional cliff racers without removing native ones.

Equipment gained six prefixes and six suffixes; promoted monsters gained six powers. Item magical magnitude, physical-stat rolls and attribute scaling rise more strongly with item/player level. Existing generated items and already-processed encounters are unchanged.

## 0.4.0 wilderness spread update

Extra wilderness spawns use simple seeded random offsets: up to three per new hostile anchor, within the existing per-cell budget. The Wilderness spawn spread setting defaults to 3000 world units. There are no navmesh, slope, water or spacing rejection checks for these exterior spawns.
## Overview

For OpenMW 0.51. Original Lua implementation; no Fresh Loot, Pretty Loot, or World Randomizer dependency. The target is Diablo 1/2 and Borderlands 1 pacing: more small encounters, meaningful individual opponents, and enough recovery to keep exploring.

## Install and start testing

Installed package: `C:/Users/super/Documents/MorrowindMods/AshenLoot-0.7.5`.

## Ashen starting classes

`AshenLoot-Classes.esp` adds five optional playable classes for a level-one run in
the denser Ashen Loot world. Vanilla classes remain available.

- **Ashen Warrior** — heavily specialized armored melee fighter.
- **Ashen War Mage** — destruction, healing, armor, and a backup weapon.
- **Ashen Archer** — dedicated ranged pressure and mobility.
- **Ashen Rogue** — stealth, access, evasion, and short-blade burst damage.
- **Ashen Conjurer** — summons, illusion, mysticism, alteration, and enchantment.

Each Ashen class receives a one-time bonus of +10 to its five major skills and +5
to its five minor skills (+75 total). Miscellaneous skills remain at their normal
low values. Favored attributes, racial bonuses, and
birthsigns work normally. Load `AshenLoot-Classes.esp` before
`AshenLoot.omwscripts`; the class plugin is required only for these class choices.

After chargen, the selected Ashen class also receives one practical starter kit
directly in inventory. Kits contain basic iron, steel, or chitin equipment plus a
small supply of relevant potions; Archer receives ammunition, Rogue receives
apprentice lock tools, and the two caster kits receive extra magicka restoration.
Starter items are intentionally ordinary and never receive Ashen affixes.

Ashen War Mages also start with Fire Bite, Hearth Heal, Shield, and Bound Mace.

When Protected Beasts is installed, beast-race players can equip its mapped
boots and helms. Procedural Ashen versions are converted from their original
base item and retain their generated enchantment and equipment stats.

## World bosses and Relics

From player level 5, each eligible cell gets one persistent world-boss roll
(3% by default) when a genuinely aggressive actor is processed. Peaceful actors
can anchor extra land encounters but cannot become bosses. A boss carries six
distinct Ashen powers, has roughly 4.5x base health, and receives a generated
lore-style identity drawn from three creature-specific given names and twelve
family epithets. Its scale is normalized by broad creature size: small models
grow most, Ogrim-sized models stay near native size indoors, and large outdoor
bosses can reach roughly 2x scale. While it is alive and within the configured
5,000-unit range, its name and long red health bar remain above the bottom HUD.
Settings expose enablement, chance, minimum level, and tracking range.

World Boss attempts can produce Relics through the same rarity ladder as other
promoted enemies, with rank and gear bonuses increasing that chance. Relics use
a curated copy of an iconic vanilla, Tribunal, or Bloodmoon weapon/armor
record, keep its recognizable name, model, and native enchantment, then add six
Ashen effects and enhanced physical stats. The original artifact and its quest
remain untouched. Relics do not enter ordinary, elite, container, or
NPC-randomization drop pools. A separate 10% base roll can instead produce a
Mythic artifact.
Ashen Conjurers start with Summon Ancestral Ghost, Bound Dagger, Chameleon,
Detect Creature, and Water Walking. Existing racial spells are preserved and
duplicates are not added.
Development source: `C:/Users/super/Documents/OpenMW-AshenLoot`.
Enable exactly one `AshenLoot.omwscripts`. QuickLoot can stay enabled.

Restart OpenMW. In Options → Scripts → Ashen Loot, select **Dungeon crawler** on each existing character if desired. Existing characters keep their saved preset, including Testing. New characters default to Dungeon crawler.

Use separate save slots for this first pass. Removing the other mods does not reverse changes already stored in a save; old generated equipment and replaced actors may remain. The configuration backup can restore the previous enabled-mod list, but cannot undo gameplay changes in a subsequently saved character.

## Current defaults

- 25% promotion chance; 35% ordinary bonus-equipment chance. Promotions always award equipment.
- 65% healing-draught chance on creatures AND eligible hostile NPCs; 25% additional fatigue/magicka/scroll supply chance. Supplies stay on bodies.
- Player-level influence 0.6. Creature encounter levels default to a player-relative band of -4/+10 and may scale downward as well as upward. Previously processed encounters retain their roll.
- Up to six additional enemies per exterior cell and three per dungeon interior cell, in small groups near existing hostile anchors. These are lifetime budgets for this save, not guaranteed counts.
- 50% chance to replace an eligible distant ground creature. Random mode uses safe loaded encounter lists; Similar mode uses themed families. Swim-only additions are excluded.
- Dungeon cells receive a minimum elite when a suitable hostile is processed.
- Cleared recognized dungeons repopulate after 72 in-game hours once the player has left; configurable or disableable.
- Ground equipment drops are optional and OFF by default. Enemy target cards default to bottom center.
- Scavenging and close-range civilian monster defense are enabled, independently switchable.
- Similar additional-monster pools and cliff-racer exclusion are enabled. Random curated pools are optional.
- Dungeon-container and hostile-NPC inventory remixing are enabled at 30% / 45%.

All these controls are available in Script Settings. Health and physical-strength multipliers are separate from density, loot, rarity promotion, and level influence. The preset changes promotion and equipment-drop odds; other controls remain independent.

## Equipment and supplies

Generated equipment has an item level, rarity, seeded stat roll and affixes. New drops improve with progression; items already found do not silently grow with the player. Base-item value bands widen and rise with level, admitting better material tiers. Version 0.5 strengthens level contribution to magical magnitude, physical stats and attribute bonuses. These are balance heuristics rather than a complete hand-rated catalog of every installed mod item.

Weapons have Quick, Balanced or Heavy stat profiles with real attack-speed and damage changes. Melee weapons cast on strike. Staves and bows/crossbows cast ranged spells on use. New weapon enchantments have 10,000 charge and cost 1: effectively maintenance-free, not magicka-powered.

Armor and clothing have constant enchantments. Magic/Rare equipment has two magical effects, Epic three, Legendary four, in addition to physical stat variation. Higher rarities also broaden the roll range. Attribute affixes grow approximately from +5 at level 1 toward +20 at level 30 before rarity adjustments. New random equipment excludes attribute drain/repair, equipment disintegration and fatigue-damage suffixes. Resource recovery, absorption and useful combat buffs remain.

Rarity labels are part of new item names, so they appear in native inventory and QuickLoot text. Colored details remain in the target card and F8 loot browser. This does not replace the engine inventory renderer or reproduce all Pretty Loot animations/formatting. F8 advances the browser; Shift+F8 closes it.

Generated health, fatigue and magicka draughts restore over five seconds; some have a complementary second effect. Generated scrolls offer fire damage or a combined fire/shock variant. These initial recipes are deliberately limited, with level bands and cached records. Broader curated recipes are future work. Dungeon leaders can supplement up to two unowned, unscripted containers with healing without replacing their contents.

## Encounters

Champion → Elite → Unique has one, two or three compatible powers, respectively. New health multipliers are 1.2 / 1.5 / 1.9. Rewards are at least Rare / Epic / Legendary. New promotions exclude the old fatigue-damage modifiers. Primary ability and damaging-proc magnitudes scale gently with encounter level; cooldowns and silence duration do not grow. Existing 0.3 promotions retain their old rank labels and effects.

Unique is currently a procedural three-power rank, not an authored boss with bespoke phases or exclusive effects. When placement and cell budgets allow, unique anchors request two adds rather than one. There is no recurring summon/loot farm.

Creature pools use curated level estimates and loaded-record matching for beasts, undead, Daedra and constructs. Recognized northern records are restricted to northern source creatures. Scripted, essential, obvious unique and summon records are excluded as replacement candidates. This is broad thematic matching, not complete biome/lore classification.

Replacements require distance from the player and a clearance check. Fighting actors keep their identity. Additional groups use walking navmesh positions and collision/separation checks. Exterior cells with several peaceful NPCs suppress replacement and extra groups as a conservative settlement safeguard. Failed placements consume their reservation, avoiding retry storms.

Dungeon detection uses names such as tomb/shrine/ruin and a fallback for interiors without services, excluding recognizable homes, guilds, inns and similar places. The first eligible hostile receives the leader designation. This may place a boss near an entrance or create several leaders in a multi-cell dungeon. It is not a connected-dungeon/deepest-room analysis and cannot guarantee a leader when all actors are protected or dead.

Eligible hostile NPCs receive scaled health/strength and up to three equipment upgrades in matching item types. They wield/wear that actual loot; their original inventory remains. Destruction-capable NPCs with sufficient magicka can receive a cheap level-scaled elemental spell. This is an initial caster-loadout pass, not a complete replacement of all native spells. NPC anchors add level-aware creature reinforcements rather than cloning named people. Similar mode infers undead for tombs, crypts, vampires and necromancers; Daedra for shrines and cult locations; constructs for identified Dwemer locations; and beasts elsewhere. Random mode draws from all four families.

Quest/scripted/essential actors, service providers and follow/escort companions are protected from normal progression. Actors become eligible through strong native aggression or observed combat with the player. This does not deliberately turn peaceful civilians hostile.

## NPC interaction

Idle nonquest NPCs can notice unowned weapons/armor within 1,400 units, walk toward an upgrade, collect it and equip it. Weapon scoring considers their weapon skill. Existing travel/follow/escort/combat/activation jobs are left alone; there is a timeout on scavenging trips. Fresh procedural ground rewards are reserved for the player until they are picked up; after the player drops one, it is ordinary unowned gear and can be collected immediately. Other schedule/animation mods still need playtesting together.

Civilians attacked at close range by a creature can initiate defense if above 20% health. This is a simple self-defense behavior, not geometric detection of being cornered or a complete tactical AI. It never initiates attacks on the player. Low-health fleeing remains native behavior.

## Persistence and first-pass limits

Rolls, replacement relationships, spawn budgets, rewards, gear and supply caches are saved. Each reference is processed/rewarded once. There is no timed population reset in 0.4.0; resurrected or same-reference respawns do not generate fresh rewards. Returning to a cell does not reroll it. Existing old encounters may retain earlier powers and loot while newly encountered actors use 0.4 progression.

Generated equipment is capped at 2,000 cached records per save. Compatible cached items are reused at the cap; a specific NPC slot may receive no new item if no compatible fallback exists. Supply/spell caches are separately limited by their small finite recipe bands.

Optional ground drops use the corpse position with a vertical offset. Slopes, deep water and unusual geometry need playtesting; corpse inventory is the default reliable destination. Scenery, plants, placed world loot and other environmental objects are not randomized.

See VALIDATION.md for actual test coverage. Balance is an initial tunable implementation, not a measured reproduction of another game's DPS or encounter pacing.


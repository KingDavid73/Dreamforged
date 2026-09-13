# Ashen Loot changelog

## 0.10.4 - natural World Boss rewards

- Removed the forced World Boss Relic/curated-artifact fallback. World Bosses
  now use their normal six reward attempts and the shared Common-to-Relic
  ladder; rank and gear bonuses widen the Relic chance without percentile
  overflow.
- Kept Mythic artifacts as a separate 10% base World Boss roll, increasing with
  gear overage.

## 0.10.3 - rarity color and weighting fix

- Ground-drop lights now read the canonical rarity palette used by salvage and
  target-card text, removing the visible Rare/Epic/Legendary color drift.
- Fixed promoted rarity bonuses overflowing into a clamped percentile 100,
  which made Relic the most common result in large promoted battles. Relic now
  keeps its small natural slice; World Bosses retain their guaranteed Relic,
  and Mythic remains a separate rare roll.

## 0.10.2 - player-reserved ground loot and rarity polish

- Reserved fresh procedural ground rewards for the player until pickup. NPCs
  ignore these items during their scan, and the authoritative pickup handler
  rejects them as a second guard. Once a player picks one up, its reservation is
  removed; a later player drop is normal unowned gear and may be scavenged.
  Ordinary player-dropped equipment remains eligible immediately.
- Kept World Boss corpse cards alive after death, including their saved name,
  biography, modifiers, and an explicit `WORLD BOSS` label.
- Restored natural Relic rolls and made Legendary/Relic family selection equal,
  preventing the small high-tier armor pool from dominating those rewards.

## 0.10.1 - terrain-aware ground placement

- Added a local physics probe for generated ground rewards. Forward-spread
  items and their rarity lights now snap to nearby walkable terrain when
  possible, with the existing lifted position retained as a fallback for
  unusual geometry.

## 0.10.0 - layered, class-aware enemy loot

- Changed the reforging exchange default to F2, migrating old F9/F10 defaults while preserving other custom bindings. The exchange now visually separates instructions, forging/combining, and salvage, and sorts salvage candidates Common-to-Relic.
- Removed the reforging gold service fee; five matching forging coins are now the complete cost. Fixed duplicate rarity labels in generated-item and salvage displays.
- Changed the reforging exchange default to F7, removed debug-menu keys F2-F4 from the selector, and migrated the previous F2 default to F7.

- Rebalanced the equipment family roll to 50% Weapon, 40% Armor, 5% Clothing, and 5% rings/amulets/other Accessory. Mage tome rewards now use the Weapon branch beside staves and wands, and curated tomes are limited to early/mid encounter bands.

- Added Common no-affix gear and shifted Uncommon through Relic into a six-tier ordinary rarity ladder; Mythic artifacts remain protected special drops.
- Rebuilt reward selection as 50% Weapon, 40% Armor, 5% Clothing, and 5% rings/amulets/other Accessory, with class-aware melee/ranged/magic weighting and subtype-first base selection.
- Replaced guaranteed single equipment rewards with per-attempt rolls: ordinary/Champion/Elite/Unique/World Boss enemies receive 1/2/3/4/6 attempts plus rank-based rarity bonuses. Promoted attempts have a 97% success floor, leaving only a 0.09% chance that both Champion attempts miss.
- Promotions improve attempt count, success chance, and rarity weighting without forcing a trophy or minimum tier; every result can still span the full rarity gradient.
- Moved curated spell tomes into the mage Weapon-family branch and retained duplicate protection.
- Spread multiple ground rewards in a forward-biased fan toward the player; disabling ground drops sends generated rewards into the corpse.
- Added Common and Uncommon auto-salvage filters, six forging-coin balances, and migration for pre-0.10 generated items and coins.
- Added a compact top-center name/health display for ordinary and promoted hostile crosshair targets. Living promotions show power names only, promoted corpses show full descriptions, and World Bosses retain the separate bottom bar.
- Added persistent corpse biographies for Uniques and World Bosses. Modular Unique histories reflect creature family and powers; every creature World Boss title has a dedicated lore fragment augmented by one of its rolled powers.
- Fixed death rewards aborting with `Bad LiveCellRef cast to WEAP from Armor`: the pre-reward ammunition scan now rejects non-weapons before reading their weapon record, and forced/iconic reward-base probes are guarded. Both ordinary promoted drops and mixed weapon/armor World Boss relic pools proceed normally.
- Made living and corpse target cards mutually exclusive at top center, replaced the unsupported power separator glyph, and removed Dreamforged's duplicate ground-item crosshair box in favor of OpenMW's native activation box.
- Fixed the reforging exchange using an invalid custom OpenMW UI mode. It now opens in a valid, native-window-free Interface mode, and the F9 default migrates to F10 to avoid quick-load.
- Spell tomes now teach and consume themselves when activated on the ground, used from inventory, or picked up. Ordinary corpses receive the same bordered summary style as promoted corpses.

## 0.8.2 — catastrophic momentum

- Replaced the Boots of Reckless Speed's Boots-of-Blinding-Speed-like effect
  with the **Boots of Catastrophic Momentum**: +500 Speed and +500 Acrobatics,
  no compensating blindness, and essentially no prospect of precise steering.

## 0.8.3 - controller ability bindings

- Added configurable controller Modifier, Cycle, and Activate buttons for Ashen
  advancement abilities. Defaults are RB + D-pad Left to cycle and RB + D-pad
  Right to activate; targeted abilities continue to use the crosshair.
- Preserved the existing Shift/Ctrl plus loot-browser-key keyboard controls.

## 0.8.4 - optional unsafe chaos

- Added a default-off switch that appends normally protected actors and item
  records to Ashen processing pools, including scripted/essential/unique NPCs
  and artifact or quest-style equipment bases.
- Unsafe Godmaker can promote peaceful protected targets. Existing changes are
  intentionally not reversed when the setting is disabled.

## 0.8.5 - population anchors and Dreamforged branding

- Prevented unsafe-only actors from serving as reinforcement anchors. Unsafe
  Chaos now broadens identities and item bases without increasing the cell's
  configured population budget or causing an enrollment burst by itself.
- Admitted ordinary respawning scripted creatures in safe mode, so common
  creatures supplied by mods are less likely to be mistaken for quest actors.
- Changed player-facing menus, messages, generated record labels, metadata, and
  chargen class names to Morrowind: Dreamforged. Internal AshenLoot identifiers
  remain unchanged for compatibility with saves and integrations.

## 0.8.6 - proximity-triggered wilderness hordes

- Exterior encounter anchors now activate within a configurable player radius,
  default 1,800 units, instead of spending budgets around distant loaded actors.
- Random mode admits the full safe land-capable catalog at every player level,
  including expansions, Tamriel Rebuilt, and creature mods; spawned actors are
  scaled afterward into the configured encounter-level band.
- Maximum density uses more placement attempts and a conservative second-stage
  fallback. The isolated exterior test placed all 48 configured additions using
  42 distinct creature records with Unsafe Chaos disabled.

## 0.8.1 — world-boss mythics

- Added a 10% Mythic outcome to world-boss Relic drops: ten unusual staves and
  four deliberately broken/silly constant-effect wearables.
- Added Wabbajack transformation; Skull of Corruption dueling copies; Staff of
  Worms temporary revival; friendly and hostile random-creature callers;
  Sanguine Rose Daedra summons; Kingmaker NPC rerolls; and repeated Godmaker
  promotion through World Boss. Summons expire after two real-time minutes.
- Added Apotheosis, Hasedoki's Rebuke, Pants of the Unending Sky, Boots of
  Reckless Speed, Helm of Too Many Thoughts, and Ring of Being Elsewhere.
- Protected players, essential/scripted/service actors and non-respawning named
  NPCs from unsafe copy/resurrection operations.

## 0.8.0 — Ashen advancement

- Added skill milestones at 50/75/100 for all 27 skills: minor and medium
  passives, a signature active at 75, and a unique mastery at 100.
- Added Combat, Magic, and Stealth rewards every five levels from 5 through 50.
- Added flat/percentage Health, Magicka, and Fatigue costs, simulation/game-time
  cooldowns, and independently recovering charges. Health costs are nonlethal.
- Shift+the loot-browser key cycles actives; Ctrl+that key activates one.
  Targeted techniques use the crosshair. Conjuration and Mysticism include
  Health-powered necromancy techniques.

## 0.7.10 — named NPC bosses and caster/ranged loot

- Hostile NPC world bosses retain their authored name and receive a compact
  lore-styled title selected from race, specialization, and generic pools.
- Safe unenchanted staves and wands from loaded content can enter the caster
  loot pool. Six scalable scroll families add elemental, control, and warding
  choices; magic classes favor scroll and mana supply rolls.
- A runtime regression now proves equipped-bow custom procs trigger from
  successful ranged hits. Permanent curated spell tomes remain deferred.

## 0.7.9 — class-aware loot and encounter gear scaling

- Generated Ashen drops now use a light player-specialization bias. The five
  Ashen classes have explicit profiles; vanilla classes fall back to current
  combat/magic/stealth skill totals. The bias favors relevant categories while
  retaining the full eligible pool and does not alter forced relic bases.
- Generated items record and display the scaled encounter's **Drop level**;
  item stats and proc magnitudes use that same persisted level.
- The best equipable combination of generated gear in the player's inventory
  contributes a modest, configurable (`gearLevelInfluence`, default 0.5)
  gear-equivalent level to new encounter scaling. Native and ordinary items do
  not affect the score; ring/glove slot conflicts are accounted for.

## 0.7.8

- Renamed generated recovery consumables to a five-step Minor / normal / Major /
  Greater / Super Healing, Mana, and Stamina Potion ladder. Removed numeric band
  labels while retaining twenty underlying level-scaled power bands.
- Assigned consistent native warm-red, blue, and green bottle art to generated
  health, mana, and stamina potions.
- Added a default-on, separately adjustable 15% one-time gradient pass for loose
  items in ancestral tombs and Daedric/Dwemer ruins: 55% similar ordinary, 30%
  broader valuable, 10% native enchanted, and 5% Ashen for eligible equipment.
- Protected ownership, scripts, books, existing enchantments, quest-like/high-value
  records, player-dropped and dynamic objects. Replacements preserve placement,
  rotation, scale, and stack count; processed cells never reroll.

## 0.7.7

- Replaced automatic generated NPC loadouts with a level-aware three-tier gear
  gradient: same-type ordinary native gear, rarer native enchanted gear, and
  still-rarer Ashen-generated gear.
- Added **NPC generated gear chance (%)**, default 5%. Champion, Elite, Unique,
  world-boss, and guard ranks raise the per-piece chance to 10/17/25/35/15% at
  default settings. Zero disables generated NPC gear.
- Kept rolls independent and uncapped so exceptional full sets remain possible,
  while an ordinary three-piece generated set is about a 1-in-8,000 event at
  the default. Guaranteed death trophies remain a separate reward layer.
- Preserved weapon/armor/clothing subtype when remixing, level-banded native and
  generated power, processed carried items before queued equipment, and removed
  replaced originals so corpses do not contain duplicate loadouts.

## 0.7.6

- Replaced the invisible same-category-only dungeon remix with a native-loot
  gradient. Regular selected containers roll roughly 70% believable
  same-category replacements, 25% broader valuables (including curated gems,
  pearls, soul gems, and currency), and 5% native enchanted gear per existing
  stack. Chests and locks shift those odds upward; level-80 locked chests land
  near 29/45/26 ordinary/valuable/enchanted.
- Each selected container independently rolls for generated Ashen gear, with no
  per-dungeon cap. Ordinary selected urns have a 25% gear chance; chests and
  locks raise remix, gear, and minimum-rarity odds. The standard
  65/25/8/2 Magic/Rare/Epic/Legendary curve remains the baseline and Relics stay
  boss-only.
- Added per-cell diagnostic logging for eligible, selected, remixed, and rewarded
  container counts. Previously processed containers are not rerolled, protecting
  player-stashed contents.

## 0.7.5

- Replaced Random mode's narrow authored creature catalog with all safe walking
  and flying records referenced by loaded leveled-creature lists, plus ordinary
  respawning records. Expansion and integrated mod creatures participate
  automatically; swim-only and quest-specific records are excluded.
- Made generated additions hostile even when a peaceful land creature, fish, or
  NPC served as their anchor. Similar mode continues to preserve encounter
  family while Random mode samples the full eligible catalog uniformly.
- Exterior groups can now chain from newly placed members until the configured
  saved cell budget is filled. This preserves compact 1,000-unit groups but no
  longer leaves most slots unused when a cell has only one native creature.
  Existing 0.7.4 exterior pack members migrate once and can finish an unspent
  budget when they next become active.
- Added configurable creature encounter bounds, defaulting to four levels below
  through ten above the player. Creature level, health, magicka, and strength
  can now scale downward as well as upward; native power still influences the
  result and leaves room for deliberately dangerous encounters.
- Added optional rerunnable dungeons. A hostile interior observed as cleared and
  then left repopulates after 72 in-game hours by default, using remembered safe
  positions and fresh level-scaled randomized enemies. Native actors, quests,
  corpses, containers, and stored items are not reset.
- Added four settings for the encounter band, dungeon reruns, and reset delay;
  saved director state migrated to version 11.

## 0.7.4

- Added five weapon prefixes and two suffixes covering Bloodletter open wounds,
  one-second Dreambinding paralysis, safe Beast/Will Command, Storm-Branching
  chain lightning, Crushing Blow, and Arcane Echoes.
- Added wearable Briar Ward thorns and Warding Echo retaliation. Custom equipped
  gear can now produce level-scaled melee retaliation, 25% elemental on-hit
  bursts, 20% when-struck novas, capped 18% Crushing Blows, safe six-second
  Command, and 25% secondary chain shocks, all with individual cooldowns.
- Command excludes players, essential/scripted actors, and service providers.
  Crushing Blow is capped by item level and reduced to 35% effectiveness against
  world bosses. Proc state and generated spells persist across saves.
- Added reachability tests for every defined equipment proc and real-engine tests
  using equipped generated weapons and armor.

## 0.7.3

- Removed the stale eight-entry enemy-modifier roll allowlist. All fourteen
  non-fatigue modifiers in the rules table can now be selected and combined;
  the two fatigue-damage variants remain legacy-compatible but intentionally
  excluded from new rolls.
- Extended regression coverage so selection and real-engine combat tests fail
  if a defined modifier becomes unreachable or its passive/proc stops working.

## 0.7.2

- Restricted random world-boss rolls and dungeon leader guarantees to actors
  with genuinely aggressive AI. Existing peaceful world bosses are demoted and
  their old scale, health bonus, and powers are removed when they next activate.
- Peaceful, swimming, and flying creatures may still anchor wilderness packs,
  but their additional actors are selected exclusively from land-capable pools.
- Normalized boss scale by creature size: small actors grow much more than
  medium actors, while Ogrim-sized actors use conservative indoor caps and can
  reach roughly double size outdoors.
- Replaced the top debug-like boss readout with a bottom-centered name and long,
  dark-red health bar.
- Reworked boss naming into three stable given-name variants per creature type
  plus twelve lore-styled epithets per family. Common Vvardenfell creatures use
  authored names; unfamiliar mod creatures receive deterministic themed names.

## 0.7.1

- Made ground-drop rarity lights explicitly model-less; they no longer inherit a
  standing torch mesh from an arbitrary Light template. Old marker torches are
  removed while loading an earlier Ashen save.
- Rebuilt exterior group placement around reachable walk-navmesh points with
  ground, slope, water, overhead-clearance, player-distance, and crowding checks.
- Failed placements now refund their saved cell-budget slots instead of silently
  consuming them. Placement results are written to `openmw.log` for diagnosis.

## 0.7.0

- Added persistent random world bosses, enabled by default at a 3% per-cell roll
  from player level 5. They are 1.45x size, have six distinct powers, roughly
  4.5x base health, extra reinforcements, and an always-visible proximity HUD bar.
- Added the boss-only Relic tier. Relics copy a curated iconic Morrowind,
  Tribunal, or Bloodmoon weapon/armor template without changing the original,
  retain its native enchantment, and add six stronger Ashen effects/stats.
- Added settings for boss enablement, cell chance, minimum level, and HUD range.

## 0.6.4

- Replaced the skeleton/nix-hound-only NPC reinforcement fallback with varied,
  level-aware pools. Similar mode infers undead, Daedra, constructs, or beasts;
  Random mode draws from every creature family.
- Cliff-racer exclusion now also applies to NPC-anchored reinforcements.

## 0.6.3

- Fixed sparse wilderness encounters: peaceful native creatures such as scribs,
  kwama, and guars can now anchor additional hostile creature groups. Previously
  only actors with Fight 80+ could trigger the wilderness budget.
- Settlement suppression continues to prevent those packs in populated town cells.

## 0.6.2

- Enabled and correctly ordered the already-installed Protected Beasts core,
  vanilla/TR boot mappings, Argonian full helms, and Hist Helms integration.
- Added Protected Beasts interoperability for generated Ashen armor, preserving
  its enchantment and procedural stats when a beast-compatible base is swapped in.

## 0.6.1

- Fixed ground-drop rarity lights being effectively invisible because their
  object scale was set to 0.001; lights now use a visible 180-unit pulse.
- Deferred Ashen class skill bonuses and starting kits until chargen and NCGDMW
  initialization complete.
- Preserved the attribute values confirmed on the class review screen through
  NCGDMW's public stat interface.
- Made caster starter spell delivery deterministic after chargen.

## 0.6.0

- Added five optional, sharply specialized native chargen classes: Ashen Warrior,
  War Mage, Archer, Rogue, and Conjurer.
- Added a one-time, class-specific level-one cushion of +10 to each major skill
  and +5 to each minor skill (+75 total); miscellaneous skills remain untouched.
- Kept the vanilla class list intact and avoided bonus gear or bespoke abilities,
  so race, birthsign, loot, and normal advancement remain meaningful.
- Added a one-time basic starter kit tailored to each Ashen class. Kits are placed
  directly in inventory to avoid Census Office cell-edit conflicts.
- Added explicit low-level starter spellbooks for War Mage and Conjurer so their
  intended play styles function immediately after chargen.

## 0.5.3

- Tightened the default wilderness spread from 3,000 to 1,000 units so additional creatures read as encounter groups.
- Existing saves still set to the exact old 3,000 default migrate to 1,000; custom spread values are preserved.

## 0.5.2

- Added a settlement-suppression toggle; disabling it permits extra encounters in populated exterior cells.
- Added separately toggleable guard progression and a 1.0–2.5 guard-power multiplier. Guards target higher levels and Rare-or-better equipment but never become monster-spawn anchors.
- Scavenged equipment now gives civilians persistent proactive-defense confidence with 375/500/625-unit engagement radii after one/two/three upgrades.

## 0.5.1

- Added a 0.5–3.0 encounter-density multiplier, default 1.5. Effective new-cell budgets are approximately 9 exterior / 5 dungeon enemies, usually generated in groups of 3 / 2.
- Reworked level-added health to scale with native durability and increased strength growth per added level.
- Normalized healing and secondary-supply chances by the square root of density to prevent population and recovery from growing at the same rate.
- Documented the target curve and playtest signals in `BALANCE.md`.

## 0.5.0

- Added saved toggles for broad dungeon-container and hostile-NPC inventory remixing, with 30% and 45% defaults. Safe existing contents are replaced from loaded-content pools; eligible gear receives Ashen Loot stats and enchantments.
- Added Similar and Random curated additional-monster modes plus default-on exclusion of extra cliff racers.
- Added optional pulsing rarity-colored lights to generated ground equipment.
- Expanded scavenger awareness from 600 to 1,400 units and made idle-package handling compatible with more schedules.
- Added six equipment prefixes, six suffixes and six promoted-monster powers.
- Strengthened level scaling for magical effects, attributes and physical equipment stats.

# 0.4.0

Standalone dungeon-crawler first pass. New implementation does not depend on Fresh Loot, Pretty Loot or World Randomizer.

- Persistent level-aware actor progression and themed creature replacement, including eligible hostile NPCs. Additional small groups use navigation/clearance checks and saved per-cell budgets.
- Minimum elite in eligible dungeon interiors; Champion / Elite / Unique ranks with one/two/three powers and Rare / Epic / Legendary minimum trophies. No recursive add spawning.
- Actual NPC equipment upgrades, basic elemental caster loadouts, level-scaled recovery draughts and combat scrolls. Creatures can drop healing too. Optional supplemental dungeon-container healing.
- Level-based item strength and material bands, Quick/Balanced/Heavy weapon stat rolls, two to four magical effects, readable rarity labels in inventory names. Removed low-impact drain/repair/disintegration suffixes from new equipment.
- Melee on-strike effects; staff/bow ranged on-use casting; generated weapons have 10,000 charge at cost 1. Armor/clothing stay constant-effect.
- Idle NPC equipment scavenging and limited close-range civilian defense against creatures. Ownership, quest/service/follower protections and bounded scanning.
- Bottom-center target card with position selector; optional ground equipment drops with a scavenging grace period.
- 27 native Script Settings controls; Dungeon crawler defaults to 25% promotions / 35% equipment, 65% healing and 25% secondary supplies. Existing saved presets are retained.
- Isolated engine coverage for generated records, real combat effects, settings callbacks, NPC equipment, navigation spawns, creature replacement, supplies and save/reload, including standalone Tamriel Rebuilt + QuickLoot.

First-pass limitations and exact defaults are in README.md. Unique ranks are procedural rather than bespoke bosses. Spawn budgets do not reset, dungeon guarantees are per-cell, and no universal recoloring of native inventory rows is implemented.
# 0.3.0

- Ten enemy modifiers with effects tied to their epithets: elemental shields and strikes, poison, fatigue retaliation, pursuit, strength/fatigue pressure, lifesteal, brief silence and magicka theft.
- Native resistible hit spells with per-modifier cooldowns, caster attribution, impact effects and save persistence. Apply to NPC victims as well as player/creature victims. No proc on missed or magical hits.
- Six prefixes and eight suffixes with distinct weapon/wearable names. Replaced resistance-only equipment prefixes, strengthened offensive duration, added ranged on-use bow spells, useful stamina/agility rarity bonuses, and tier-gated metaphysical affixes.
- Elite trophy affix matches its primary modifier. New elite/champion health multipliers are 1.35/1.8.
- New-character default is Balanced (16% elites / 12% ordinary drops); saved settings remain unchanged. Testing remains 50% / 100%.
- Versioned item/ability caches; existing loot and pre-0.3 elite abilities/names remain intact, including accurate legacy target-card descriptions.
- Added sourced lore/design notes distinguishing published game lore, Tamriel Rebuilt writing and Kirkbride's non-canon supplemental texts.
- Retains the 0.2.0 settings UI initialization fix.

# 0.2.0

Settings hotfix (same version): initialize character defaults per key instead of resetting the entire global storage section. This avoids an OpenMW 0.51 menu rebuild bug that displayed No/nil values, routed clicks to player storage, and lost preset/key selector arguments. Verified native menu renderer values and setter callbacks in an isolated engine session.

- Replaced the vanilla creature allowlist with all-creature coverage, including Tamriel Data/Rebuilt and generated creature records. Optional scripted/essential protection, always-on companion/service-provider safeguards, optional respawning NPC coverage.
- Added a default two-second quiet period after activation, observed base-health changes and World Randomizer events. Replacement actors get their own roll; disabled originals and hidden parent proxies are excluded.
- Remember player hostility during the quiet period. Fast kills receive ordinary loot without a late corpse promotion.
- Track elite health using the dynamic-stat modifier, and update only the mod's contribution after a base-health reroll. Preserve older 0.1 promotions in their legacy form.
- Add character-specific Script Settings: Testing/Balanced/Custom presets, percentages, delay, actor protection, NPC opt-in, target cards and F6â€“F11 hotkey selection. Default Testing provides 50% elites and 100% ordinary drops.
- Use original creature names with family-specific epithets; simplify weapon affixes and distinguish resistance-item prefixes.
- Add combined engine tests using the user's installed Fresh Loot, World Randomizer, Tamriel Data and Tamriel Rebuilt, including save/reload.

# 0.1.0

Initial independent loot/elite prototype with Fresh Loot rarity presentation integration.

## 0.8.7 - bounded wilderness groups

- Replaced recursive exterior reinforcement chains with one roll per native creature anchor.
- Added configurable exterior anchor chance and minimum/maximum group size.
- Added a configurable minimum spawn distance; exterior additions now use a min/max ring around both player and anchor.
- Generated additional creatures can no longer become population anchors.
- Preserved density-scaled per-cell budgets, broad safe random pools, and post-selection level scaling.
## 0.8.8 - rarity-aware gear pressure

- Increased gear-score contribution by rarity: Common 0, Rare 4, Epic 10, Legendary 18, Relic/Mythic 28 effective levels.
- Added up to 3x enemy-health scaling when effective gear level exceeds character level.
- Kept the durability response tied to the existing gear-influence control and left enemy damage unchanged.
- Capped procedural weapon physical damage by drop level/style, with an absolute 120 maximum, while preserving higher native artifact damage where applicable.
## 0.8.9 - boss-focused gear pressure and rewards

- Removed the direct overgear health multiplier from ordinary enemies.
- Applied 25/50/75/100% of overgear durability pressure to Champion/Elite/Unique/World Boss health bonuses.
- Added overgear-based promoted rarity improvements and raised world-boss Mythic chance from 10% toward a 40% cap.
- Added world-boss combat reinforcements: 1–3 after 20 seconds and every 30 seconds, capped at six living adds and excluded from recursive anchor logic.
## 0.9.0 - uncapped progression and settings cleanup

- Removed player, effective-gear, generated encounter, and item-metadata level caps at 100.
- Added continuous post-100 prestige scaling to enemy health and physical strength (`level / 100`).
- Reorganized the monolithic settings list into eight ordered functional groups and migrated existing save values.
- Shifted ground equipment drops 110–360 units toward the player, with corpse-size adjustment, a small vertical lift, and synchronized rarity light placement.
## 0.9.1 - exterior encounter reliability

- Added configurable minimum and maximum player distance for exterior anchor activation (defaults 300–2200).
- Allowed visible active adjacent-cell creatures to trigger exterior encounters instead of requiring exact player-cell identity.
- Removed the redundant minimum-distance rejection around the native anchor; spawn safety now excludes only the player radius.
- Added optional wilderness-cell repopulation with a default 72-game-hour reset.
- Kept cliff racers eligible as native anchors while respecting their exclusion from generated reinforcements.
- Added maximum accepted values to every numeric setting label.

## 0.9.2 - promotion-based World Bosses

- Removed the persistent once-per-cell World Boss roll.
- Made World Boss the highest conditional result for each successfully promoted eligible aggressive actor.
- Added a configurable Elite-tier chance and expanded World Boss and Unique tier controls to 0–100%; Champion is the ladder fallback.
- Preserved per-native-actor proximity activation and the per-cell generated-population ceiling.
- Clarified activation-range, player-exclusion, anchor-placement, and cell-budget wording in settings.

## 0.9.3 - active World Boss cap

- Added a configurable living World Boss ceiling per active cell (default 1, maximum 10).
- Prevented a reinforcement group from independently promoting several World Bosses after the first fills the cell slot.
- Kept the cap dynamic: boss death or departure frees the slot without restoring a once-per-cell roll.

## 0.9.4 - configurable World Boss pressure

- Added settings for first boss-wave delay, repeat interval, minimum/maximum wave size, and maximum living adds.
- Preserved the former 20-second, 30-second, 1–3, and six-add behavior as defaults.
- Allowed a zero living-add cap to disable World Boss reinforcements without disabling ordinary encounter groups.

## 0.9.5 - dynamic base-quality tiers

- Added an independent eight-band base-material quality roll before procedural rarity, affixes, and weapon style.
- Gave level 1 a 1% top-band jackpot while applying a gentle uncapped-level logarithmic bonus that never excludes low bands.
- Replaced the hard-coded vanilla material-name pool with safe dynamically classified loaded equipment.
- Ranked comparable subtypes using native damage/armor, durability, enchant capacity, and value so mod-added gear joins automatically.
- Displayed base quality in item details and included it in effective gear score.

## 0.9.9 - archetype drops and curated spell tomes

- Replaced per-record class weighting with category-first selection, preventing large melee catalogs from drowning out staves, wands, bows, and crossbows.
- Strongly weighted Magic profiles toward cast-on-use staves/wands and Archers toward generated ranged weapons while preserving off-archetype possibilities.
- Added 24 permanent spells across four tiers as learn-on-use tome drops, with known/carried duplicate protection and stronger Magic/promoted-enemy weighting.
- Added a configurable 0–100 spell-tome base chance, default 5%.

## 0.9.8 - renewable ammunition supplies

- Added a configurable defeated-enemy ammunition roll, independent of potion/scroll supplies.
- Marksman skill and carrying/equipping a bow or crossbow substantially improve drop chance; the launcher selects arrows versus bolts.
- Bundles use safe ordinary ammunition from all loaded content, trend upward in material power with encounter level, and grow modestly with Marksman.

## 0.9.7 - automatic loot-filter salvage

- Added independent default-off acquisition filters for Magic, Rare, Epic, Legendary, and Relic/Mythic generated gear.
- Newly acquired filtered items become one same-tier forging coin without lingering in inventory or consuming carry weight.
- Existing inventory is baselined rather than swept; equipped records and freshly purchased reforges are protected.

## 0.9.6 - Dreamforged reforging exchange

- Added an F9 interactive salvage and reforging window with a configurable hotkey.
- Converted individual unequipped Dreamforged items into one same-rarity forging coin each.
- Added five-for-one same-rarity reforges with level-scaled gold fees and randomized replacement bases and affixes.
- Added three-for-one coin combining from Magic through Legendary, producing one coin of the next rarity up to Relic.
- Protected equipped items in both the displayed list and authoritative global transaction handler.
- Persisted coin balances per player and refunded currency if record generation fails.

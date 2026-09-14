# Morrowind: Dreamforged handoff — 0.10.14 installed

**Current installed release: 0.10.14.**

0.10.14 makes new-character initialization and **Reset everything** operate on
the same currently registered settings list. Regression coverage explicitly
changes and restores Director intensity and Target World Boss cadence, and
confirms retired low-level director controls are not registered again.

0.10.13 unifies outdoor pacing behind Director intensity and a target World
Boss cadence. Pressure persists across exterior cells; ordinary combat adds to
the action/boss arc; only Unique and World Boss victories grant substantial
recovery. At default settings, healthy active travel reaches a guaranteed
eligible outdoor World Boss group at roughly ten minutes, with a rising chance
to encounter one somewhat earlier.

0.10.12 shortens the top-level action to **Reset everything** and posts a
confirmation message after the deferred reset completes. The reset remains
scoped to registered Dreamforged groups only.

0.10.11 places the all-settings reset in its own top-of-page settings
section, above General and compatibility. Its bulk global writes are deferred
to the next global update tick so native section resets can rebuild controls
without losing buttons or shifting the page. The previous 0.10.10 den VFX
cleanup remains included.

0.10.5 gives each World Boss six independent rewards from a dedicated
1/2/7/20/30/20/20 Common-through-Mythic table. Level, overgear, and configured
enemy health/damage can promote individual results upward. Spell tomes cannot
replace these boss rewards. Cell budgets now persist as `additionalCount` and
explicitly exclude native actors, identity replacements, and separately capped
World Boss reinforcements.

0.10.4 removes the forced World Boss Relic. Bosses now use six ordinary reward
attempts with rank/gear rarity bonuses; the widened Relic chance is about 12%
per successful default World Boss attempt, while Mythic remains a separate 10%
base roll. The curated Relic fallback is gone.

0.10.3 makes ground-drop lights reuse the salvage/target-card rarity palette.
It also fixes rarity-bonus overflow: promoted rolls are capped below the small
natural Relic slice instead of turning all values above 100 into Relics. World
Bosses still guarantee one Relic and roll Mythic separately at the configured
gear-pressure chance.

0.10.2 reserves fresh procedural ground rewards for the player while they are
loose. The reservation is removed once the player picks the item up, so a later
player drop is ordinary unowned gear that NPC scavengers may collect. Existing
player-dropped gear remains eligible immediately. Dead World Boss target cards
now keep the saved boss name, lore, modifiers, and an explicit `WORLD BOSS`
label instead of reverting to the base creature name. Natural Relic rarity rolls
are reachable, and Legendary/Relic family selection is equalized.

0.10.1 keeps the 0.10.0 loot/family and mage-tome changes and adds a local
physics ground probe for dropped rewards. Items still spread toward the player,
but when the player is in the same cell the item and its rarity light are moved
to the nearest walkable surface below the intended position. Failed or unusual
probes leave the safe lifted placement unchanged.

The reforging exchange now defaults to F7 because F2/F3/F4 are OpenMW shader/performance/debug menus and F5/F9/F10 are occupied by quick-save, quick-load, and Lua debug. Existing Dreamforged F2/F9/F10 defaults migrate to F7, while other custom bindings remain untouched. Its combined window now has distinct instruction, forge/combine, and salvage sections; salvage candidates sort Common-to-Relic. Reforging requires forging coins only; the gold service fee was removed so the exchange remains separate from Morrowind's normal economy. UI labels no longer prepend a second rarity tier to generated item names.

0.10.0 replaces the one-reward model with a 50/40/5/5 Weapon/Armor/Clothing/Accessory family roll, followed by subtype and base-quality selection. Combat, Magic, and Marksman-oriented profiles weight their preferred weapon archetype at 55%. Common is now the no-affix floor, followed by one-affix Uncommon and the existing Rare/Epic/Legendary/Relic progression. Ordinary through World Boss enemies receive 1/2/3/4/6 reward attempts with rank-based rarity bonuses; promoted attempts have a 97% minimum success chance, but impose no forced trophy or rarity floor. Curated spell tomes use the mage Weapon branch alongside staves and wands, and are limited to early/mid encounter bands. Multiple ground rewards form a forward-biased fan toward the player, while disabling ground drops routes them into the corpse. Version-20 save migration preserves old generated gear and forging balances on the shifted tier scale.

The SME actor-healthbar script is disabled in the live OpenMW configuration. Dreamforged now owns the compact top-center hostile target name/health display; living promotions show power names only, promoted corpses show full mechanics, and World Bosses retain the bottom bar. Unique and World Boss actors receive a deterministic saved corpse biography. Unique prose combines family and power slots, while every creature World Boss title has a dedicated lore fragment.

The post-0.10 live drop failure was a real pre-generation abort, not unlucky rolls or hidden corpse loot. The ammunition supply scan queried every equipped object through `Weapon.record`, so an armored player caused every death handler to fail before loot rolls; World Boss iconic-base discovery had the same unsafe typed probe. Both paths now validate/probe types safely. Ground items use only OpenMW's native activation box; promoted corpse details replace the living top card instead of appearing as a second bottom card.

0.9.9 fixes class-biased loot by choosing category before base record: Magic profiles strongly favor cast-on-use staves/wands and Archers favor ranged proc weapons regardless of raw loaded-record counts. It adds 24 consumable spell tomes across early/mid level bands, excludes known/carried duplicates, and gives Magic profiles triple the configurable base drop chance.

0.9.8 adds renewable ordinary arrows and bolts as a separate defeated-enemy supply roll. Marksman skill and possession of a compatible launcher strongly raise the configured base chance; equipped/carried bows and crossbows choose arrow versus bolt. Loaded safe mod ammunition participates and selection trends with encounter level.

0.9.7 adds five default-off rarity filters. Newly acquired generated items in enabled tiers automatically become matching forging coins; pre-existing inventory, equipped records, and intentional reforging purchases are protected.

0.9.6 adds an interactive reforging exchange. Unequipped generated items salvage individually into one same-rarity coin; five coins generate one item with that exact rarity while base quality/category/affixes/style reroll. Three coins combine into one coin of the next tier (through Relic). Equipped items are filtered in player UI and rejected globally. Balances persist per player. The backend can later support physical coins, a broker, and an altar.

0.9.5 replaces the hard-coded vanilla material-prefix/value-window generator with a dynamic eight-band base-quality chart. Loaded unenchanted gear is ranked within subtype by combat/armor stats, durability, enchant capacity, and value, admitting safe mod-added variants automatically. Level gently boosts the independent quality roll; level 1 retains a 1% top-band jackpot. Quality is displayed and adds two effective gear levels per band above 1.

0.9.4 surfaces World Boss reinforcement pressure in settings: initial delay 20 seconds, repeat interval 30 seconds, wave size 1–3, and six living adds by default. All are configurable; a zero living-add cap disables boss waves.

0.9.3 adds a live per-cell World Boss ceiling, default 1 and configurable to 10. It is not a one-time cell roll: eligible promotions continue normally, but the World Boss rung is unavailable while the cell already contains the configured number of living bosses. Death or leaving the cell releases the slot.

0.9.2 removes the per-cell World Boss lottery. Every successfully promoted eligible aggressive actor independently rolls the configured World Boss chance, with World Boss as the promotion ladder's highest result. Exterior native actors likewise roll independently when entering the activation band; cell state supplies only the hard generated-population ceiling. Generated actors cannot become anchors. Settings distinguish activation range from placement radius.

0.9.1 fixes thin exterior populations by accepting anchors in active adjacent exterior cells, using a default 300–2200 player-centered activation band, and removing the redundant anchor-centered spawn exclusion. Wilderness cells reset native anchors after 72 game hours away by default while retaining living additions. Numeric setting labels expose their maximum accepted value.

0.9.0 removes the level-100 encounter cap and adds an uncapped `level / 100` prestige multiplier beyond 100 to health and strength. Settings are split into General, Scaling, Wilderness, Dungeons, Bosses, Loot, NPC, and Interface groups with automatic migration. Boss ground rewards shift toward the player outside large corpses.

0.8.9 concentrates gear-pressure durability on promoted enemies (25/50/75/100% by rank through world boss), improves promoted rarity floors, and scales world-boss Mythic chance from 10% to 40%. World bosses call 1–3 adds after 20 seconds of player combat and every 30 seconds afterward, capped at six living adds; these adds cannot chain.

0.8.8 makes gear pressure rarity-aware: tier premiums are 0/4/10/18/28 effective levels, blended by the existing gear-influence setting. Effective gear levels above player level additionally multiply newly processed enemy health by 10% per level, capped at 3x; enemy damage is unchanged.

0.8.7 replaces recursive exterior hordes with bounded native-anchor groups. Each native creature rolls once (65% default), successful anchors create 1–3 extras by default, generated extras cannot become anchors, and placement uses a 450–1000 unit ring from both player and anchor. Density and exterior budget remain the hard saved cell ceiling.

0.8.6 makes exterior anchors proximity-triggered (default 1,800 units), broadens
safe Random mode to essentially every land-capable loaded creature except clear
quest/unique/summon/pet/generated identities, and relaxes placement progressively
at maximum density. Its isolated exterior test filled the maximum 48-enemy budget
with 42 distinct creature records while Unsafe Chaos was off.

0.8.5 fixes Unsafe Chaos enrollment so unsafe-only identities may be promoted,
transformed, or used as loot bases without becoming extra-population anchors.
Safe mode now admits ordinary respawning scripted creatures, addressing overly
sparse modded wilderness pools. Player-facing runtime branding and the five
chargen class display names now use Morrowind: Dreamforged; internal IDs remain
AshenLoot for save and compatibility stability.

0.8.4 adds the default-off Unsafe Chaos setting. It admits scripted, essential,
unique, service, companion, artifact, quest, and other excluded records into
actor and item pools. Godmaker may promote peaceful protected targets while it
is enabled. Disabling it later does not undo generated records or actor changes.

0.8.3 adds controller play for unlocked advancement abilities. The Script
Settings page exposes separate Modifier, Cycle, and Activate button selectors;
defaults are RB + D-pad Left/Right. Keyboard controls remain available.

0.8.2 changes the speed Mythic to Boots of Catastrophic Momentum: +500 Speed
and +500 Acrobatics with no blindness. It is intentionally uncontrollable.

0.8.1 adds a 10% Mythic branch to world-boss Relic drops: ten projectile or
native-effect staves and four silly constant-effect wearables. Wabbajack,
Corruption copies, Worms revival, random friendly/hostile summons, Sanguine
Daedra, Kingmaker rerolls, and Godmaker promotion are guarded against unsafe
quest targets. Temporary creations expire after 120 simulation seconds.

0.8.0 adds Ashen advancement. All 27 skills grant 50/75/100 passives and a
signature active at 75; Combat/Magic/Stealth paths grant ten level rewards from
5–50. Actives support Health/Magicka/Fatigue flat or percent costs, real/game-
time cooldowns, recovering charges, crosshair targets, and save persistence.
Shift+loot key cycles; Ctrl+loot key activates. Conjuration and Mysticism add
Health-powered necromancy techniques.

0.7.10 preserves authored NPC names on world bosses and adds
race/specialization-aware titles. It admits safe unenchanted staff/wand bases
from loaded content, adds six scalable scroll families, biases magic-class
supplies toward scrolls/mana, and tests ranged generated-bow procs. Curated
permanent spell tomes remain deliberately deferred.

0.7.9 adds specialization-biased generated gear, persisted/displayed encounter
**Drop level**, and best-equipable-combination gear scoring for bounded encounter
scaling (`gearLevelInfluence`, default 0.5).

0.7.8 gives generated recovery potions a clean Minor/normal/Major/Greater/Super
Healing, Mana, and Stamina ladder with native red/blue/green bottle art. It also
adds a default-on 15% one-time loose-item remix for tombs and Daedric/Dwemer
ruins. Eligible equipment uses a 55/30/10/5 similar-native / valuable-native /
native-enchanted / Ashen gradient. The pass excludes books, ownership, scripts,
existing enchantments, quest-like/high-value records, dynamic/player-dropped
objects, and preserves placement. Settings: `randomizeLooseDungeonItems` and
`looseDungeonItemPercent`.

0.7.7 replaces full procedural NPC suits with an uncapped level-aware gear
gradient. Equipped and carried weapons/armor/clothing preserve their subtype:
most become ordinary native gear, a smaller share native enchanted gear, and a
rare share Ashen-generated gear. New setting `npcAshenGearPercent` defaults to
5%; Champion/Elite/Unique/world-boss/guard chances are 10/17/25/35/15%. Zero
disables the Ashen layer. Independent rolls preserve rare fully-kitted anomalies;
guaranteed death trophies remain separate. Replaced equipped originals are now
removed rather than duplicated on corpses.

0.7.6 fixes the practical invisibility of dungeon container randomization. Each
newly selected safe container remixes existing stacks through an ordinary /
valuable-native / native-enchanted gradient (70/25/5 for regular containers,
about 29/45/26 for a level-80 locked chest). The valuables pool includes curated
gems, pearls, ordinary soul gems, and currency while excluding keys and quest
props. Every selected container independently rolls for Ashen
gear with no per-dungeon cap: ordinary selected urns are 25%, while chests and
locks increase remix, gear, and minimum-rarity odds. Expected yield is roughly
one or two generated items in a container-rich dungeon, but lucky runs can
produce more. Relics remain
boss-only. Owned/scripted and previously processed containers remain untouched.
A per-cell `openmw.log` summary reports eligible, selected, remixed, and prize
counts.

0.7.5 broadens Random encounter selection to safe ordinary creatures referenced by every loaded leveled-creature list, so expansions and integrated creature mods join the pool. Generated additions are hostile and land-safe even when anchored by peaceful creatures or fish. Exterior packs chain through new members until the configured saved cell budget is filled, fixing sparse one-anchor cells while remaining strictly capped. Creature encounters now use a configurable player-relative -4/+10 default band and can downscale high-native-level creature health, magicka, strength, and level. Recognized hostile interiors can repopulate with a fresh randomized wave after being observed cleared, left, and allowed to rest for 72 in-game hours. This does not reset native corpses, quests, or containers.

0.6.0 adds five sharply specialized native playable Ashen classes (Warrior, War Mage, Archer, Rogue, Conjurer) and a saved, one-time +75-point focused skill boost (+10 majors, +5 minors) for those classes. Miscellaneous skills and vanilla classes are unchanged. The prior 1,000-unit default exterior spread remains in place.

0.5.2 adds toggleable settlement suppression, higher separate guard progression/gear, an adjustable guard-power multiplier, and persistent proactive defense for civilians who scavenge upgrades. Guards never serve as extra-monster anchors. Normal-play interaction with the user's guard behavior mod remains to be observed.

0.5.1 is a Diablo 1-oriented cohesion pass. Encounter density defaults to 1.5 (about 9 exterior / 5 dungeon reserved additions, groups near 3/2); level-added health now scales partly with native durability; strength gains 1.1 per added level; and recovery chances are divided by square-root density. `BALANCE.md` contains the rationale and playtest signals. Existing processed cells/actors/items do not reroll.

0.5.0 installed. It adds broader and less schedule-fragile NPC scavenging; broad container/NPC inventory remix underneath Ashen affixes; colored pulsing lights for generated ground equipment; Similar versus Random extra-monster pools; default-on exclusion of extra cliff racers; six more equipment prefixes, six suffixes and six monster powers; and stronger item-level scaling. Existing generated items/processed encounters are not rerolled. See README and VALIDATION for exact behavior and test limits.

User wants a standalone Morrowind dungeon crawler, taking pacing inspiration from Diablo 1/2 and Borderlands 1. More frequent small fights in wilderness/dungeons, interesting individual enemies, level-aware gear/creature tiers, and ample healing. Avoid modern screen-clearing swarm spectacle and low-impact affixes such as attribute drain/repair or narrow resistance. No environmental/plant randomization.

0.7.8 source is this directory. Installed copy: `C:/Users/super/Documents/MorrowindMods/AshenLoot-0.7.8`. Distribution: `C:/Users/super/Documents/AshenLoot-0.7.8.zip`.

Live configuration: `C:/Users/super/Documents/My Games/OpenMW/openmw.cfg`. Backup before this switch: `openmw.cfg.before-AshenLoot-0.4.0-20260909` in the same directory. Fresh Loot addon/scripts, World Randomizer, Pretty Loot and its no-pickup-message patch are disabled; QuickLoot remains enabled. Old installation directories were not deleted. Source backup: `C:/Users/super/Documents/AshenLoot-0.3.0-before-0.4.zip`.

Read README.md for exact implemented behavior and limitations, and VALIDATION.md for actual engine test coverage. New characters default to Dungeon crawler. Saved characters retain their settings, so the user should select that preset explicitly when desired and test in separate save slots. No real character saves were opened or modified during development.

Main new files: progression.lua (saved director, loot tiers, supplies, loadouts, replacements/groups), civilian.lua (equipment scavenging and limited self-defense). global.lua integrates them; actor.lua applies local stats/equipment; player.lua handles navigation queries and repositioned target cards. Rules and records handle item scaling/stat variants/effect counts/cheap charge. All in scripts/ashenloot.

Final isolated tests: v4-profile (50 settings, broad safe encounter pool, loose-item gradient, potion tiers, level band, 80 item cases, supplies, ranks, actual NPC gear, UI and save/reload); v4-world-profile (real placed-item remix, direct high-native downscale, navmesh spawns, safe expansion-creature replacement, dungeon rerun wave, ownership-aware pickup/equipment and persistence); effects-profile (all native abilities and real hit procs rechecked through the native-damage phase; the complete prior run also covers immunity, cooldowns and save/reload). Tests deliberately launch and exit an isolated engine. Never include test .omwscripts in the live config or package.

Known first-pass gaps: no native actor/container/quest reset, connected-dungeon/deepest-room boss logic, authored unique mechanics, complete faction/biome catalog, broad caster/support spell kits, complete Pretty Loot/native inventory color replacement, or custom magicka/recharge logic. Dungeon reruns add new waves at remembered positions only. Ground drops are experimental and off by default. NPC schedule compatibility and spontaneous scavenging/self-defense still require normal-play observation. Level-scaled supply recipes are limited but functional. Do not imply these unimplemented refinements were completed.

Next action is user playtest feedback across levels, followed by targeted fixes/balance. The user authorized the first-pass implementation and config switch; do not ask again whether to perform those already completed actions.

Follow-up: user explicitly requested simple wide random-offset wilderness spawns and minimal testing to save tokens. Added exteriorSpread (default 3000), three extras per new anchor within existing budgets, one ground-height ray, no exterior placement rejection checks. Dungeon logic unchanged. Keep validation limited to smoke checks for this update.

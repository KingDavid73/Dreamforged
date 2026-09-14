# Ashen Loot validation

## 0.10.7 experimental creature dens (2026-09-13)

- A targeted real-world run forced a den encounter, dynamically cloned and placed the stationary Kwama Queen record, then produced family-wave additions through the exterior navmesh with no creature-record or animation errors.
- Threat accounting now uses saved per-actor costs derived from requested encounter level versus combined character/gear power; dens cost two points and all child waves share the same live budget.
- The full isolated regression passed all visible settings, record generation, progression, encounters, inventories, UI initialization, and save/reload. Physical den combat, exact particle appearance, and long-session pacing remain live-playtest items.

## 0.10.6 outdoor pressure director (2026-09-13)

- Exterior population is now driven by timed player movement, accumulated quiet-roll pressure, a live nearby-add cap, health/threat respite, and forward-biased local placement.
- Promoted exterior deaths pause pressure for 20/45/90 seconds by tier; World Boss deaths create a three-minute safe window in that exterior cell.
- Interior anchor population and rerunnable dungeon behavior are unchanged.
- The complete isolated regression passed all 78 visible settings, generated records, progression, encounters, inventories, UI initialization, and save/reload. A targeted exterior run then moved the player through a real Ashlands navmesh and produced a bounded forward group containing three different loaded creature records. Expected test-harness quit warnings were the only script traceback.

## 0.10.5 World Boss table and addition budget (2026-09-13)

- Deterministic rules coverage verifies the exact 1/2/7/20/30/20/20
  Common-through-Mythic World Boss distribution before upward modifiers.
- World-placement coverage now reads the explicit `additionalCount` cell
  budget. Native actors, identity replacements, and separately capped boss
  adds are excluded from that counter.
- The full isolated OpenMW regression passed through save/reload. The
  world-placement run passed the updated additional-budget, navmesh, scaling,
  and inventory-transfer checks; its later fixture setting writes hit the
  profile's pre-existing `Unexpected content key` registration issue rather
  than a Dreamforged callback failure.

## 0.10.4 natural World Boss rewards (2026-09-13)

- Rules coverage confirms the World Boss rarity bonus widens the Relic slice
  without clamping overflow into Relic; normal six-attempt rewards remain
  independent of the separate Mythic roll.
- The isolated OpenMW regression should be rerun before packaging. Existing
  0.10.3 suites passed settings, generated records, promotions, loot, UI, and
  save/reload.

## 0.10.3 rarity color and weighting fix (2026-09-13)

- Deterministic rules coverage confirms rarity bonuses cannot collapse into a
  Relic overflow: a high promoted roll reaches Legendary, while the natural
  Relic percentile remains reachable.
- Ground-glow construction now consumes `R.rarities[tier].color`, the same
  table used by salvage and target-card text.
- Full isolated OpenMW regression should be rerun before packaging; the prior
  0.10.2 run passed all settings, item/effect generation, promotions, loot,
  UI, and save/reload checks.

## 0.10.2 player handoff and rarity polish (2026-09-13)

- The clean isolated OpenMW regression passed all settings, generated item and
  spell-tome records, promotions, inventory/container remix, ground rewards,
  UI, and save/reload checks after adding player-reserved ground rewards and
  World Boss corpse-card labeling. No Dreamforged `FAIL`, Lua callback error,
  or `onUpdate` failure was emitted.
- Fresh procedural rewards remain protected while loose; ordinary player-dropped
  gear remains eligible for NPC scavenging. The authoritative unowned-item
  transfer path remains covered by the world regression.
- Natural Relic rarity rolls and equal Legendary/Relic family weighting are
  covered by deterministic rules checks.
- Logs: `tests/v4-profile/openmw.log` (clean run at 00:25:30) and
  `tests/v4-world-profile/openmw.log` (clean run at 00:29:11).

## 0.10.1 terrain-aware ground placement (2026-09-12)

- The full isolated OpenMW regression passed all settings, generated item and
  spell-tome records, promotions, inventory/container remix, ground rewards,
  UI, and save/reload checks with the short-lived local ground-probe script
  enabled. No `FAIL`, `ERROR`, or Lua-error entries were emitted.
- Ground rewards retain their forward fan while the local helper returns a
  walkable height-map/world-collision position to the global script; unusual
  geometry keeps the original lifted fallback.
- Log: `tests/v4-profile/openmw.log` (run `ground-align-test-20260912d.log`).

## 0.8.1 world-boss mythics (2026-09-11)

- The full isolated regression created all ten mythic staff and four mythic
  wearable records, verified metadata, directly invoked a random friendly
  summon, and completed all advancement, loot, encounter, UI and save tests.
- Log: `tests/v4-profile/mythic2-stdout.log`.

## 0.8.0 Ashen advancement (2026-09-11)

- The full isolated regression created at least 115 advancement records: all 27
  skills' 50/75/100 passives, 27 signature actives, and ten specialization
  milestones. It verified cooldown rejection and three-charge game-time state.
- Effects and real-world suites passed prior proc, ranged, scaling, navmesh,
  container, dungeon-rerun, NPC equipment, and save/reload coverage.
- Logs: `tests/v4-profile/advancement3-stdout.log`,
  `tests/effects-profile/advancement-stdout.log`, and
  `tests/v4-world-profile/advancement-stdout.log`.

## 0.7.10 NPC boss names and caster/ranged pass (2026-09-11)

- The isolated full regression preserved authored NPC names across twenty
  deterministic race/specialization title rolls, verified six distinct scroll
  recipes, and passed all prior item, encounter, inventory, UI, and save/reload
  checks.
- The effects suite equipped a generated bow and proved its custom on-hit proc
  damages the target through the ranged physical-hit path. All enemy/equipment
  proc tests and cooldown persistence also passed.
- Test logs: `tests/v4-profile/run-new-stdout.log` and
  `tests/effects-profile/run-new-stdout.log`.

## 0.7.8 recovery potion and loose-item pass (2026-09-11)

- The full isolated regression passed all 50 settings; sampled every loose-item
  gradient tier; verified Minor, normal, and Super potion naming; checked the
  native red health and blue mana icons; and passed all prior item, NPC,
  encounter, UI, and save/reload cases.
- The real-world shrine fixture classified Assarnatamat correctly, enumerated
  two safe original placed items, selected and replaced one in position at the
  default 15% roll, and preserved its processed-cell state through save/reload.
- Test logs: `tests/v4-profile/openmw.log` (14:44) and
  `tests/v4-world-profile/openmw.log` (14:45).

## 0.7.7 NPC gear gradient (2026-09-11)

- The full isolated regression passed all 48 settings and verified default
  ordinary/Elite/world-boss Ashen chances of 5/17/35%, alongside the native
  enchanted tier. A real NPC's equipped weapon and cuirass were replaced with
  same-type level-aware gear, the originals were removed, repeated processing
  stayed stable, and save/reload preserved the result.
- The real-world suite passed NPC scavenging/equipment, ownership protection,
  container gradients, encounters, dungeon reruns, and save/reload unchanged.
- Test logs: `tests/v4-profile/openmw.log` (14:32) and
  `tests/v4-world-profile/openmw.log` (14:33).

## 0.7.6 container loot gradient (2026-09-11)

- The isolated full regression sampled the broad native pool, confirmed the
  curated miscellaneous valuables category, and exercised ordinary, valuable,
  and native-enchanted outcomes from the locked-chest gradient. All existing
  item, encounter, class, inventory, UI, death, and save/reload checks passed.
- The real-world fixture created and locked a safe dungeon container at level
  80, remixed its contents, independently added generated Ashen gear, and
  preserved the result through save/reload. Its cell summary reported 2/2
  selected containers, 12 remixed stacks, and 2 generated prizes.
- Test logs: `tests/v4-profile/openmw.log` (14:23) and
  `tests/v4-world-profile/openmw.log` (14:24).

## 0.7.5 broad encounter pool, level band, and dungeon reruns (2026-09-11)

- The isolated full regression passed all 47 settings, sampled 250 Random-mode
  selections, confirmed a broad catalog, land/flying locomotion, safe generic
  encounter membership, player-relative target levels, and swimming-anchor land
  packs. Existing item, boss, class, inventory, UI, death, and save/reload checks
  also passed.
- The real-world fixture placed navmesh-validated groups, replaced a distant rat
  with a safe loaded-list creature, directly verified a level-50-native creature
  downscales its actual level and health for a level-one target, generated a
  five-enemy dungeon rerun wave at remembered positions, and preserved the
  results through save/reload.
- The combat-effects profile re-passed all sixteen native enemy abilities, all
  fourteen real hit-handler procs, cooldown/non-stacking behavior, and native
  damage/drain behavior before the isolated harness stopped advancing at its
  later poison-immunity stage. The complete 0.7.4 effects run remains valid for
  the unchanged proc code; the 0.7.5 actor change is confined to level scaling.
- Test logs: `tests/v4-profile/openmw.log` (14:00),
  `tests/v4-world-profile/openmw.log` (13:56), and
  `tests/effects-profile/openmw.log` (13:50 partial rerun).

## 0.7.4 reactive equipment effects (2026-09-11)

- Rules/record regression constructed every new prefix and suffix and verified
  all six scripted proc definitions are reachable from generated equipment.
- The isolated real-engine effects profile equipped generated gear and verified
  melee thorns, elemental chance-on-hit, when-struck nova damage, safe creature
  Command, capped Crushing Blow, and a chain shock reaching a second hostile.
- The complete V4 regression also passed native open-wound/paralysis/Command
  record construction, every existing loot and enemy feature, and save/reload.
- Test logs: `tests/v4-profile/openmw.log` (09:28 run) and
  `tests/effects-profile/openmw.log` (09:29 run).

## 0.7.3 complete enemy-modifier selection (2026-09-11)

- The rules regression verifies that all fourteen supported modifiers are in the
  procedural selection pool and that only the two intentionally retired
  fatigue-damage variants are excluded.
- The isolated real-engine combat profile instantiated all sixteen definitions,
  applied all sixteen passive abilities, and triggered all fourteen defined
  attack/retaliation spells through actual combat-hit handlers. It also passed
  miss/magic-hit rejection, cooldown deduplication, native damage and resistance,
  caster attribution, disable behavior, and save/reload persistence.
- The full V4 regression passed all loot, Relic, boss, encounter, class,
  inventory-remix, progression, death-reward, UI, and save/reload checks.
- Test logs: `tests/v4-profile/openmw.log` and
  `tests/effects-profile/openmw.log` (09:16 and 09:17 runs).

## 0.7.2 world-boss eligibility, presentation, and names (2026-09-11)

- The full isolated OpenMW 0.51 regression passed all 43 settings, item/Relic
  creation, expanded boss-name diversity, land-only swimming-anchor packs,
  aggressive-versus-peaceful boss eligibility, indoor size classes, HUD
  creation, combat rewards, and save/reload without Ashen Lua errors.
- Eighteen deterministic Rat boss seeds produced at least eight distinct full
  names from the new three-given-name/twelve-epithet combination system.
- The bottom HUD uses a fixed 760-pixel dark-red bar and a full-width centered
  name row. Normal-play review at the user's UI scale and outdoor model-size
  extremes remains appropriate.
- Existing peaceful bosses are demoted when activated and their cell rolls are
  reopened. This migration was source-reviewed; it was not run against the
  user's real character save.

## 0.7.1 ground markers and exterior placement (2026-09-10)

- The full isolated OpenMW 0.51 regression passed all 43 settings, item and
  Relic generation, creature pools, starter kits, inventory remix, progression,
  ground rewards, world-boss state, and save/reload without Ashen Lua errors.
- Dynamic rarity markers were created from Morrowind's native model-less
  `yellow light` template; the rejected empty-model draft and visible torch
  inheritance are gone.
- The exterior smoke profile placed nine generated actors using the new walk-
  navmesh, ground, slope, water, clearance, distance, and crowding validation.
  Placement logs confirmed successful 3/3 groups and zero-result refunds.
- Existing saves migrate away old marker objects. Normal-play review of light
  color/strength and density in newly visited cells remains appropriate.

## 0.7.0 world bosses and Relics (2026-09-10)

- The isolated engine regression generated a Relic from the real Daedric
  Crescent template, verified tier 5 and expanded enchantment effects, created
  a six-modifier 4.5x-health world boss, and retained it through save/reload.
- All 43 native settings controls initialized and their setters passed.
- The remaining validation is normal-play boss frequency, HUD placement with the
  user's UI suite, physical scale by creature model, and long-term Relic balance.

## 0.6.3 wilderness anchor fix (2026-09-10)

- The full isolated 39-setting, item, encounter, death, and save/reload suite
  passed after allowing peaceful native creatures to anchor wilderness packs.
- The live OpenMW log showed Ashen Loot 0.6.2 loading without Lua/director errors;
  the sparse Pelagiad-Balmora result was traced to the Fight 80 anchor filter.
- Normal-play density on previously unvisited exterior cells remains the required
  visual/encounter validation.

## 0.6.1 lifecycle fix (2026-09-10)

- The isolated 39-setting/item/encounter/save-reload regression passed with no
  Lua errors after the class lifecycle and ground-light changes.
- Source review verified that Ashen class bonuses now wait for completed chargen
  and initialized NCGDMW state, then use NCGDMW's public Attribute/Skill API.
- Visual strength of the new 180-unit rarity pulse and the restored regional
  groundcover set still require normal in-game review.

## 0.6.0 focused validation (2026-09-10)

- Generated `AshenLoot-Classes.esp` from the checked-in builder and parsed it with
  OpenMW's `esmtool`.
- Confirmed all five CLAS records are playable and have the intended favored
  attributes, specialization, five major skills, and five minor skills.
- Confirmed the class bonus is persistent and bounded: +10 majors, +5 minors,
  capped at 100, and guarded by saved `classBoosted` state.
- Executed all five starter kits in the isolated OpenMW profile and verified every
  War Mage and Conjurer starter spell is present on the player.

## 0.5.3 focused validation (2026-09-10)

- The isolated OpenMW regression passed all 39 settings, encounter modes, inventory/effect generation, rewards and save/reload with the 1,000-unit default. Log: `tests/v4-profile/spread1000-stdout.log`; stderr was empty.
- Version-5 saves using exactly 3,000 are migrated once; other configured spread values are not changed.

## 0.5.2 focused validation (2026-09-10)

- The isolated OpenMW suite passed all 39 settings plus the existing item, effects, encounter, inventory, reward and save/reload regression. Log: `tests/v4-profile/guards-stdout.log`; stderr was empty.
- Guard recognition, higher scaling/equipment and the settlement bypass share the normal once-per-reference director path. Guards exit that path before promotion, supply supplementation or extra-group creation.
- Civilian scavenging count is saved in the NPC-local script. Proactive AI behavior and interaction with the user's guard-consistency mod still require normal-play observation.

## 0.5.1 balance validation (2026-09-10)

- The isolated base engine suite passed all 36 Script Settings, item/effect generation, Similar/Random pools, cliff-racer exclusion, broad inventory remix, NPC loadouts, ground rewards and save/reload under the 1.5 density default. Log: `tests/v4-profile/balance-stdout.log`; stderr was empty.
- Density arithmetic and group sizing are deterministic. Ordinary health/strength changes run through the existing once-per-reference local scaling guard, so saved actors do not compound the new formula.
- This is a cohesion pass, not a measured full-playthrough calibration. Average realized population, time-to-kill, potion surplus and economy value still require playtesting in newly visited cells.

## 0.5.0 focused validation (2026-09-10)

Isolated OpenMW 0.51 runs; no real character save was opened or modified.

- Base profile: all 35 native settings initialized and their global setters worked; 80 existing item combinations, all new equipment/monster effect records, Similar/Random creature modes, extra cliff-racer exclusion, broad inventory remix with Ashen affix layering, ground-light creation, NPC loadouts, rewards and save/reload passed. Log: `tests/v4-profile/v5-final-stdout.log`; stderr was empty.
- Tamriel Data / TR_Mainland / QuickLoot profile: expanded loaded-content pools, settings, effects, inventory remix, ground lights, loadouts and save/reload passed. Log: `tests/v4-tr-profile/v5-stdout.log`; stderr was empty.
- Scavenging behavior was corrected from normal-play feedback and retains earlier controlled transfer/equipment coverage. Its longer-range spontaneous walking still requires another normal-play observation.
- Inventory remix protects scripted records and limits containers to unowned, unscripted dungeon containers. This is an original level-aware implementation informed by World Randomizer's broad type/subtype pooling; it is not a bit-for-bit reproduction.

## 0.4.0 validation (2026-09-09)

Installed OpenMW 0.51, isolated temporary characters and save directories. No real character save was opened or overwritten.

- `tests/v4-profile`: 80 combinations across item levels 1/10/30/60, all four rarities and five base item types. Verified two/three/four magical effects, actual native staff/bow casting types, melee charge/cost, 12 generated potion/scroll variants, NPC wielded weapon/worn armor upgrades, promotion ranks, creature healing, ground equipment, duplicate-death protection, dynamic-record and director save/reload.
- `tests/v4-tr-profile`: the same suite with Tamriel_Data.esm, TR_Mainland.esm and QuickLoot, without Fresh Loot or World Randomizer. All 27 native Script Settings controls initialized with non-nil defaults and working global setters. Logs: stdout.log / stderr.log in that profile.
- `tests/v4-world-profile`: real walking-navmesh placement in Assarnatamat, saved cell budgets, level-30 creature scaling, guaranteed dungeon elite, distant rat replacement with an actual different creature tier, unowned weapon transfer/equip and rejection of owned equipment. Save/reload retained generated encounters and scavenged gear.
- `tests/effects-profile/v4-stdout.log`: existing real Combat handler regression, with director replacement/scaling disabled to keep controlled fixtures stable. All ten legacy-compatible passive abilities, nine attack/retaliation procs, missed/magical-hit rejection, duplicate-proc suppression, damage, lifesteal, magicka/fatigue changes, poison immunity, disable setting and saved cooldowns passed. This includes legacy modifiers retained for existing saves, although new procedural rolls exclude fatigue-damage modifiers. Missing optional postprocess shaders in this isolated profile are unrelated to Lua/combat behavior.

Final successful runs contain no Lua failures. Earlier failed runs informed fixes for armor slot names, test fixtures, simultaneous item moves, menu storage initialization and sphere-cast API limitations. Startup warnings for the test scripts' deliberate core.quit() are expected.

Limits: no full playthrough, whole-load-order compatibility claim, visual screenshot approval, long-term economy balance, proof of all NPC schedule-mod interactions, or migration test of real player saves. Pickup/equipment validation uses controlled requests; spontaneous walking/scavenging and civilian self-defense require normal-play observation. Dungeon grouping is per-cell and population budgets do not regenerate. Placement rejection may produce fewer extra enemies than the configured maximum. Northern/modded creature classification remains heuristic. Old saves can retain previous mods' baked changes after those mods are disabled.

## Historical validation
# Ashen Loot engine validation â€” 0.3.0 and historical 0.2.0 checks

Engine: installed OpenMW 0.51.0, revision f4bec41444; LuaJIT 2.1.

## 0.3.0 combat/lore pass

All profiles below are isolated from real character saves. The earlier 0.2 results below remain as historical coverage, not a description of the new effects.

- Item/UI regression: all 240 combinations of six prefixes and eight suffixes on five base items generated real engine records. Checked exact effect IDs against both weapon and wearable affixes, ranged bow enchantment range, natural tier gates, primary-effect names, thematic trophy matching, cache reuse, native settings menu defaults/setter callbacks, Fresh Loot recognition, rewards and save/reload. Log: `tests/settings-fix-stdout.log` (the filename is retained from the previous fix).
- Combat profile: all ten passive elite abilities applied through the real engine. All nine proc/retaliation spells triggered through actual `I.Combat.onHit` handlers, with correct caster attribution and no duplicate stacking from rapid hits. Misses and magic hits did not proc. Verified actual fire/frost/shock/poison health loss, Absorb Health caster healing, magicka drain and fatigue retaliation. Native poison immunity prevented damage. Disabling the mod suppressed new procs. Save/reload retained generated proc records, cooldown timestamps and rules identity. Log: `tests/effects-profile/engine-stdout.log`.
- Combined Fresh Loot 3.4.5 / World Randomizer 0.6.7 / Tamriel Data / TR_Mainland profile: Balanced defaults and live Testing/Custom settings, replacement creature `t_glb_fau_horkergrey_04`, real mainland creature `t_cyr_cre_dreu_01`, delayed promotion and later base-health reroll, fast ordinary kill/drop, native inventory randomization, and save/reload all passed. Log: `tests/compat-profile/engine-stdout.log`.

No Lua errors or stderr output appeared in these successful runs. Engine warnings for the test harness's deliberate `core.quit()` are expected. These are controlled combat events, not a manual full playthrough. Native shield reflection/retaliation, every resistance/absorption/reflect combination, long-term equipment stacking and the entire remaining user mod list were not exhaustively tested. Impact VFX use installed native assets; no visual screenshot review was performed.

The two supplemental metaphysical sources and the separation between lore evidence and invented mechanics are documented in `LORE-NOTES.md`.

## 0.2.0 settings hotfix

The original startup section reset exposed a bug in the installed engine's `scripts/omw/settings/menu.lua`: its whole-section change handler calls `renderGroup(group)` without the global flag. The resulting controls use player storage and lose global renderer arguments. Ashen Loot now initializes defaults with individual key writes. No engine files were changed.

The added `tests/scripts/ashenloot_test/settings_ui.lua` wraps the installed native renderers and exercises their actual menu setter callbacks. It verifies all nine initial values, changes every toggle, both percentages, the delay, the preset and the F8/F9 selector, checks global storage, then restores defaults. This tests the menu/storage integration; it does not simulate physical mouse clicks. The regression engine run also verifies loot, elite abilities, Fresh Loot integration and save/reload. Results: `tests/settings-fix-stdout.log`.

Actual OpenMW sessions, with isolated config/user-data/save directories under `tests`. No existing character saves were loaded or altered. The normal `openmw.cfg` was not edited. Runtime tests used Morrowind.esm, Tribunal.esm, Bloodmoon.esm and Ashen Loot. The final run also loaded the installed Fresh Loot 3.4.5 scripts and enchantment addon.

## World Randomizer and mainland coverage

An additional isolated profile loaded **Fresh Loot 3.4.5, World Randomizer 0.6.7, Tamriel_Data.esm and TR_Mainland.esm together**. Its final combined run completed successfully at 22:29 local time. It exercised the installed randomizer's actual creature replacement and actor event handlers, rather than a mock implementation. Combat AI was disabled in that test profile to prevent guild NPCs killing the fixtures; controlled Combat hit events established player hostility.

Passed:

- Testing defaults (50% elites / 100% ordinary drops), Balanced (16% / 12%), and live Custom percentages.
- Actual World Randomizer creature replacement. The disabled original was not promoted, and the replacement was eligible and subsequently promoted. The final run selected `tr_m1_lud_stcent_02`.
- A real Tamriel Data creature, `t_cyr_cre_dreu_01`, received an elite promotion after a delayed randomizer health update. No allowlist entry or custom patch for that record was required.
- No promotion before the configured quiet period. The generated name retained the source creature's name.
- Randomized base health 80 remained 80, with a separately tracked 40-point elite modifier and 120 current health. A later reroll to base 160 recalculated the bonus to 80 without changing the randomizer's base value or stacking the old bonus.
- A successful lethal player hit before the promotion delay produced ordinary loot at 100% chance, without promoting the corpse.
- Generated elite corpse loot was excluded from the randomizer's generated data pool and survived its actual inventory-randomization handler.
- Actual save/reload preserved a living replacement elite's ability and health modifier, the Testing settings, corpse loot and reward deduplication.

The full combined log is `tests/compat-profile/engine-stdout.log`; stderr was empty, with no Lua errors or layout warnings in the successful run. Earlier failing test runs exposed and led to fixes for event timing, settings leaking between characters, and the engine's base-stat behavior for native Fortify Health. Final elite health uses the separate dynamic-stat modifier instead.

## Item/UI regression suite

Passed checks:

1. Repeatable random sequence; all four rarity tiers reachable; 1,000 enemy rolls without repeated modifiers within a champion.
2. 120 actual item/enchantment combinations: every prefix/suffix combination on an iron longsword, iron cuirass, common ring, chitin short bow and iron war axe. Verified generated names/enchantments and nonempty effect lists through engine records.
3. Correct cast mode for axe (on strike) and bow (on use).
4. Forced generation of each rarity and reuse of an identical cached record.
5. Player exclusion, generic rat eligibility, and elite promotion on the original creature reference.
6. Elite ability present in the creature's actual spell list, with the expected active-effect magnitude.
7. Colored loot browser created in the player UI context; no Lua layout warnings in the final run.
8. Real Fresh Loot-generated item recognized by the rarity bridge and browser.
9. Corpse reward created, and duplicate death-event calls did not create additional loot.
10. Actual save and reload preserved generated item names, enchantment records, elite identity data and reward tracking; replaying the death event after reload did not duplicate loot.

Full regression console output is retained in the development source's `tests/engine-stdout.log`. The standard Script Settings page is registered using OpenMW's own number, checkbox and select renderers and the mod's localization resource.

Limitations of these checks: they establish API/runtime behavior, not long-term gameplay balance, full visual QA, full-mod-list compatibility, all combat interactions or UI compatibility with QuickLoot/Pretty Loot/Inventory Extender. The native engine save thumbnail omits HUD overlays, so it was not usable for visual inspection of the new UI. Existing stock UI was not replaced.

Test harness files remain in the source directory only and are intentionally omitted from the distributable package. Neither `smoke.omwscripts` nor `compat.omwscripts` should be enabled in normal play: the harnesses deliberately create actors and inventory, manipulate fixtures and test settings, save/reload and exit the engine.


## Simple wilderness spread follow-up
User requested minimal validation. One isolated engine smoke check passed: six extra exterior actors generated, with no Lua errors. Log: tests/v4-world-profile/spread-stdout.log. No balance, slope/water or placement-quality pass was performed.

## 0.8.2 catastrophic-momentum regression

The isolated v4 engine suite passed after replacing Reckless Speed with the Boots of Catastrophic Momentum. OpenMW successfully created all ten mythic staves and four mythic wearables, including the boots' constant-effect Fortify Speed 500 and Fortify Acrobatics 500 enchantment. The complete item, boss, advancement, encounter, inventory and save/reload regression also passed. Log: `tests/v4-profile/momentum-stdout.log`.

## 0.8.3 controller-settings regression

The isolated v4 engine suite loaded the controller handler without Lua errors and verified that all 54 Script Settings controls, including the new Modifier, Cycle, and Activate selectors, have non-nil defaults and working storage setters. The complete item, boss, advancement, encounter, inventory, and save/reload regression passed. Log: `tests/v4-profile/controller-stdout.log`. Physical controller button presses still require in-game playtesting.

## 0.8.4 unsafe-chaos regression

The isolated v4 engine suite verified safe-mode rejection and unsafe-mode admission using a protected active NPC and an artifact record. It also confirmed that the artifact enters the procedural Ashen base pool only while Unsafe Chaos is enabled. All 55 Script Settings controls and the complete item, boss, advancement, encounter, inventory, and save/reload regression passed. Log: `tests/v4-profile/unsafe-stdout.log`.

## 0.8.5 population-anchor and branding regression

The unsafe fixture remains eligible for promotion and item-pool expansion but is explicitly rejected as a reinforcement anchor. Ordinary safe encounter records retain the cell director's configured population path. The rebuilt class plugin reports Dreamforged names for all five classes and Dreamforged author metadata. All 55 settings and the complete engine/save-reload suite passed. Log: `tests/v4-profile/dreamforged-085-stdout.log`.

## 0.8.6 exterior horde and full-safe-pool regression

An isolated exterior test used Unsafe Chaos off, Random mode, density 3, and the 16-slot base exterior budget. Proximity activation plus progressive maximum-density placement produced all 48 allowed additional actors using 42 distinct creature records. The normal suite then passed all 56 settings and the complete item, boss, advancement, encounter, inventory, and save/reload checks. Logs: `tests/v4-world-profile/horde-stdout.log` and `tests/v4-profile/dreamforged-086-stdout.log`.
## 0.8.7 bounded exterior group regression

- Settings regression covers all 60 controls, including anchor chance, group bounds, and spawn-ring minimum.
- Exterior pack smoke test uses one native anchor with a forced 3–5 group and verifies that only 3–5 additions exist after processing settles, proving generated actors do not chain.
- Placement rejects candidates inside the configured minimum from either player or native anchor; the bounded test completed using the 450–1000 ring.
- Engine results: one forced native anchor produced four actors from its configured 3–5 range and remained bounded; the complete regression passed all 60 settings and all existing systems. Logs: `tests/v4-world-profile/bounded-087-stdout.log` and `tests/v4-profile/dreamforged-087-stdout.log`.
## 0.8.8 rarity-aware gear pressure regression

- Pure scaling checks verify no health increase at equal player/gear level, 2x health at ten effective levels over the player, and the 3x cap for extreme equipment.
- A low-level Relic generated from a Daedric battle axe is checked against its charged-damage ceiling, guarding against the former 200+ maximums.
- The complete engine regression continues to cover generated records, all settings, encounter scaling, bosses, inventories, progression, and save/reload.
- Full OpenMW 0.51 regression passed on 2026-09-12; log: `tests/v4-profile/dreamforged-088-stdout.log`.
## 0.8.9 boss escalation regression

- Forced promotions under maximum 3x gear pressure verify rank-specific health scaling, including a 13.5x world-boss profile (4.5x baseline times 3x gear pressure).
- Existing encounter tests verify generated actors remain excluded from population-anchor recursion; boss adds use the same marked generated-actor path and are capped independently at six living reinforcements.
- Full OpenMW 0.51 regression passed on 2026-09-12; log: `tests/v4-profile/dreamforged-089-stdout.log`.
## 0.9.0 uncapped scaling, grouped settings, and ground-drop regression

- Pure checks preserve the level-100 baseline, verify a 5x prestige multiplier at level 500, and confirm Random generated encounters retain target level 500.
- Settings validation covers all 60 controls across eight saved category groups and verifies each renderer callback writes to its mapped storage section.
- Ground-drop validation requires the generated equipment object to land more than 80 units from the dead actor instead of remaining inside its body.
- Full OpenMW 0.51 regression passed on 2026-09-12; log: `tests/v4-profile/dreamforged-090-stdout.log`.
## 0.9.1 exterior activation and settings regression

- Settings validation covers all 63 controls across eight groups, including activation minimum, wilderness reset toggle, and reset duration.
- Maximum-density exterior smoke uses Random mode, a 100–8000 activation band, 100% anchor chance, 3–5 additions per native anchor, and the 48-actor cell ceiling; it requires at least 24 visible additions across at least six creature records without exceeding the cap.
- Spawn placement retains the player-centered exclusion radius but no longer rejects otherwise-valid positions for proximity to the source anchor.
- Targeted OpenMW exterior test produced 51 bounded additions across active same/adjacent cells using 44 creature records; every individual cell remained within its 48-addition maximum. Generated actors receive a direct player-targeting Combat package. Log: `tests/v4-world-profile/exterior-091-stdout.log`.
- Complete OpenMW regression passed all 63 settings plus loot, promotion, progression, encounter, inventory, ground-drop, and save/reload checks. Log: `tests/v4-profile/dreamforged-091-stdout.log`.

## 0.9.2 promotion-ladder World Boss regression

- Source inspection confirms no runtime `worldBossRolled` or per-cell World Boss eligibility gate remains.
- World Boss eligibility is passed into the ordinary promotion call and rolled only inside the successful-promotion branch; forced dungeon leaders use the same conditional roll.
- Settings expose the complete descending ladder: promotion, World Boss, Unique, Elite, then Champion fallback (64 total controls).
- Exterior native actors remain independently proximity-processed, generated actors remain ineligible as anchors, and the cell count remains the sole population ceiling.
- OpenMW 0.51 loaded all modified scripts without Lua initialization errors. The legacy full-suite fixture currently stops on pre-existing unrelated defaults and bow-range assertions, so this release is marked for focused in-game validation.

## 0.9.3 active World Boss cap regression

- Promotion eligibility counts living World Boss metadata among actors currently in the candidate's cell immediately before every promotion.
- At the default cap of 1, the first successful World Boss closes that rung for subsequent actors while leaving Unique, Elite, and Champion outcomes available.
- The counter ignores dead bosses and actors outside the candidate cell, allowing the slot to reopen dynamically.
- Settings validation now enumerates 65 controls, including the 1–10 active-cell boss ceiling.

## 0.9.4 configurable World Boss reinforcement regression

- Settings validation enumerates 70 controls, adding initial delay, repeat interval, wave minimum/maximum, and living-add cap.
- Runtime scheduling reads the configured delays; wave generation orders reversed minimum/maximum values safely and clamps each wave to remaining capacity.
- A zero living-add cap prevents both scheduling and global wave creation.

## 0.9.5 dynamic base-quality regression

- OpenMW 0.51 loads the dynamic loaded-record classifier and revised item-record metadata without Dreamforged Lua initialization errors.
- Base-quality bands are computed independently within equipment subtype from native performance fields; selection chooses the nearest populated band after the level-influenced roll.
- Level 1 has exactly one top-band result on an unmodified d100 roll, while the logarithmic level bonus shifts odds rather than imposing a minimum tier.
- Safe mode excludes scripted, enchanted, quest/unique/artifact-labeled, test, and placeholder records; loaded ordinary expansion and mod records require no name allowlist.
- The legacy full-suite fixture still halts on its previously documented unrelated initial-settings and bow-range assertions before procedural drop checks, so live catalog distribution remains an in-game validation item.

## 0.9.6 reforging exchange regression

- OpenMW 0.51 loads the interactive player UI, global transaction handlers, configurable F9 selector, and persistent exchange state without Dreamforged Lua initialization errors.
- Salvage requires a valid player-owned generated item and rejects equipped objects globally even if a stale UI callback is invoked.
- Coin combining is server-authoritative, consumes three coins of one tier, and creates one coin of the next tier; Relic is the ceiling.
- Reforging requires five exact-rarity coins and the full level-scaled gold fee; failed item generation refunds both currencies.
- Settings enumeration covers 71 controls. Mouse interaction and custom-mode presentation remain explicit live-playtest items.
- The complete OpenMW regression passed all 71 settings plus loot, promotion, progression, encounters, inventory, UI initialization, and save/reload checks after coin combining was added. Log: `tests/v4-profile/dreamforged-096b-stdout.log`.

## 0.9.7 automatic salvage regression

- Five independent rarity settings default off and are included in native settings enumeration (76 controls total).
- The inventory-delta scan only converts newly acquired generated records. It refreshes its baseline while disabled and after a successful reforge, and it conservatively protects any record currently equipped.
- The complete OpenMW regression passed all 76 settings plus generated records, promotion, progression, encounters, inventory processing, UI initialization, and save/reload. Log: `tests/v4-profile/dreamforged-097-stdout.log`. Live pickup conversion and filter messaging remain explicit playtest items.

## 0.9.8 renewable ammunition regression

- A separate 0–100 ammunition setting defaults to 15%, raising settings enumeration to 77 controls.
- Supply selection distinguishes bows/arrows and crossbows/bolts, weights chance using Marksman and launcher possession, and selects safe unenchanted ammunition across loaded content by a level-influenced power ordering.
- The complete OpenMW regression passed all 77 settings plus generated records, progression, encounters, inventories, UI initialization, and save/reload. Log: `tests/v4-profile/dreamforged-098-stdout.log`.

## 0.9.9 archetype and spell-tome regression

- Base selection now performs deterministic category-first weighting before choosing a record within the selected category, so installed catalog size cannot erase class preferences.
- Twenty-four four-tier spell definitions create permanent Spell records and learn-on-use Book records. Selection excludes spells already known and tome records already carried.
- Spell-tome base chance is configurable and raises settings enumeration to 78 controls.
- The complete OpenMW regression passed all 78 settings, explicitly created and validated all 24 Spell/Book record pairs, and passed generated loot, progression, encounters, inventories, UI initialization, and save/reload. Log: `tests/v4-profile/dreamforged-099c-stdout.log`. Live inventory-use consumption remains a playtest item.
## 0.10.0 layered loot regression

- Validate all six ordinary rarity tiers: Common has no enchantment, Uncommon one affix, Rare two, and Epic/Legendary/Relic progressively expand effect counts.
- Validate family-first 55/35/10 selection, class-aware melee/ranged/magic weighting, and subtype-first base choice against the loaded catalog.
- Validate 1/2/3/4/6 reward attempts, promoted rarity pressure without a forced tier, Accessory-family spell tomes, and forward-fan ground placement.
- Validate six coin balances, Common/Uncommon filters, protected Mythics, and version-20 migration before release packaging.

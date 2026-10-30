# Dreamforged 0.11.2 — The Unending Dream (playable prototype)

## Depth-aware enemy selection (0.11.2)

Shallow caves favor rats, foragers, and workers. Deeper cave cycles introduce
warriors, kagouti, and blighted creatures. Tombs progress toward stronger undead;
Dwemer floors toward sphere and steam constructs; Daedric floors toward atronachs,
ogrim, and golden saints. Guardians also use depth-appropriate curated forms.
Selection continues by absolute depth when the twelve layouts cycle. Exhausted
themes retain strong archetypes while existing stat scaling increases difficulty.

The archetype strength band starts at 1 and increases by 0.75 per depth;
guardians use a band four points higher. This is a selection estimate, not final
actor level. It adds no health/damage multiplier: preparation still uses the
existing baseline + 1.25 per depth target and existing depth/prestige factors.
Combined combat and loot scaling remains a separate balancing task.

Compatible expansion/mod creatures have a 25% chance to supplement ordinary
spawns when the band has candidates. Candidates must have a population-list
reference, a recognizable theme, walking movement, and no script, essential flag,
or services. Known special, quest, corpse, and domestic tags are rejected.
Scripted candidates stay ineligible even with Unsafe Chaos enabled. No extra
creature mod is required. Cached dungeon-owned copies are nonrespawning and
retain their installed appearance, stats, spells, and inventory across save/load.
Guardians remain on authored lists. Classification can be extended later.

Full-suite sampling found 134 eligible optional archetypes. In native-only cave
samples the mean strength estimate increased from 1.63 at depth 1 to 16.53 at
depth 25. These numbers describe species choice, not final combat level.

Existing 0.11.1 inhabitants persist; new floors and reinforcement spawns use
the new selection. No run reset or new game is required.

## Enemy selection repair (0.11.1)

Each theme selects private, script-free combat archetypes with explicit hostility
and dedicated boss choices. Original world creature records are untouched.
Dungeon records are excluded from ordinary world spawn pools. There is no
arbitrary fallback to Pack Guars.

Living enemies from the old selector are replaced in place once when their floor
is visited, preserving health fraction and guardian role. Dead enemies and
completed guardians stay dead. Run depth and rewards persist. No new game or
run reset is required. Reinforcement behavior remains tasks 03-04.

## Start the delve

Travel to the road just north/northeast of Seyda Neen, near Addamasartus.
Look for **Nerethi, Maelstrom Herald**, a softly illuminated Dunmer stranger.
Talk to her and choose **Take me to the refuge**. There is no giant gateway.
The herald is placed on a separately sampled, flat patch of your actual modded
terrain. Her old gateway and buried-NPC placement migrate away on load.

Nerethi claims to serve Fa-Nuit-Hen, the Demiprince associated with martial
motions in Morrowind's first Sermon and with Maelstrom in later lore. This
particular herald, refuge and dungeon are original mod fiction.

The refuge provides:
- A descent shrine, which starts or resumes your run.
- A return portal, which returns you to the floor/position you left.
- An exit back to Seyda Neen.
- Velyna, Broker of Dreams. Talk to her to inspect and buy equipment for coins,
  or explicitly abandon/reset a run. Reset does not reroll her stock.

Dream Portal is learned in the refuge. Cast it within the dungeon to return
here; it does not overwrite Mark. Use the return portal to resume.

## Floors and encounters

Twelve generated, connected, open-plan layouts: three Cave, three Ancestral
Tomb, three Dwemer and three Daedric. Depth continues beyond 12 by recycling
these layouts with fresh inhabitants and higher scaling. Layout shapes are
fixed in this prototype; they are not newly generated every time you enter.

A World Boss is guaranteed every third depth, including at low player level.
Ordinary random World Boss rolls are suppressed in these cells. The dungeon
has a small starting population and an ongoing director: reinforcements use
reachable, unoccupied, offscreen anchors; waves defer while navigation builds
or no safe anchor is available. The live population is capped at eight.
Boss encounters pause ordinary waves nearby and have at most four extra adds.
Victory provides a lull and advances the broker's stock refresh epoch once.

Theme changes every three depths; difficulty never resets when themes cycle.
Run baseline is captured from your gear level. Spawn level increases with
depth, with additional health/damage and reward-budget factors. Affix counts
use the existing bounded promotion system. This needs balance playtesting.

The run is saved with your game. Portal trips and save/load preserve enemies,
boss victories and stock purchases. Leaving does not reset your run. Old
layout slots recycle when their theme returns; the shrine is the normal way
back out. Unclaimed rewards in a recycled slot are removed; carried items
and coins are preserved. This is a single-player feature.

## Economy

New generated Common-through-Relic equipment and Mythic artifacts have zero
gold value. Their effects, damage, condition and enchantments are unchanged.
Ordinary generated gear retains the existing salvage/coin and reforge actions.
Tooltips explain trade-in value. Mythic artifacts retain their existing
non-salvageable status. Native Morrowind items retain normal gold values.
Equipment generated before this update is left intact with its previous value;
we do not replace equipped/stored items or alter existing saves on disk.

The broker displays three offers (Rare, Epic, Legendary), each costing eight
coins of its own rarity. Inspect before purchasing. Each offer can be bought
once. Stock refreshes after dungeon boss victories, never just by returning
upstairs. Identify is deliberately deferred.

## Install / undo

Installed release location: Documents\MorrowindMods\Dreamforged-0.11.2.
The main OpenMW config uses this folder instead of 0.10.29 and loads
Dreamforged-Delve.esp alongside AshenLoot.omwscripts. Isowind inherits this.
Existing Isowind camera/HUD fixes and the inert Stats & Potions Limit
compatibility parent remain intact.

A timestamped openmw.cfg.before-Dreamforged-0.11.0 backup is saved next to the
main config. Restore it to return to the old configuration. Keep a pre-update
save if you want to return to a run without this plugin; missing-plugin
warnings can occur when loading a newer save with the old configuration.

## Validation and limitations

Engine regression scripts cover quest/portal learning, zero-gold offers,
coin debits and duplicate-purchase protection, portal persistence, real World
Boss promotion, boss-based stock refresh, save/load, theme transitions and
recycling at depth 13. Tested in Isowind with the full suite and in stock
OpenMW 0.51. Navigation paths across all twelve layouts and ground collision
were exercised across the runs. The herald test checks grounded placement,
legacy-gate cleanup, transport and journal progression against the full suite.

Visual capture was unavailable; the first oversized gateway was rejected by
the user and replaced with the tested NPC-only entrance. Art dressing,
isometric readability, long-run balance and combat feel need playtesting.
This is a first playable implementation, not a polished dungeon expansion.

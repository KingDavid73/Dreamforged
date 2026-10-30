# Dungeon enemy selection diagnosis — task 01

## Task 02 resolution (0.11.1)

The plugin now supplies 16 private combat archetypes cloned from the explicitly
named Morrowind creatures in `tools/delve-enemies.json`. The generator strips
MWScript and AI packages, removes respawn/essential flags, supplies walking
movement, and sets fight 100/flee 0 without services. Selection validates only
these theme-specific lists; guardians use ordered explicit boss backups.

Inspection of the loaded scripts explains why blanket admission was unsafe:
`Creatures_RP_Purist.ESP` adds fight/stat randomizers and child spawners
(`plx_spawn_nixpup`, `plx_spawn_rspiders2`, `ttooth_alit_spawns`, and
`ttooth_kagouti_spawns`). `Creatures_RP_daedric_drop_rebalance.ESP` adds a
Dremora weapon/drop script. Private archetypes avoid those side effects;
normal world records and their scripts remain intact. Dungeon-only records
are explicitly excluded from ordinary world random selection.

Correct source IDs are `ancestor_ghost` and `bonewalker_greater`. The selector
mixes its deterministic random stream before choosing a species so adjacent
spawn seeds do not repeatedly pick the same archetype.

Saved living actors from the old selection system are replaced on visiting
their floor. Replacement preserves count, position, guardian role, and health
fraction, and removes old actor bookkeeping. Dead actors are left alone;
migration is versioned and idempotent. Depth-based base-creature expansion and
optional mod creatures remain task 02a; director reinforcement work remains
tasks 03–04.

Confirmed 2026-10-30 against the installed Dreamforged 0.11.0 scripts and the user's full OpenMW content configuration, running the Isowind engine in an isolated test profile. No gameplay code or personal configuration changed.

## Root cause

`scripts/ashenloot/delve.lua` rejects every themed candidate with an attached MWScript, including boss candidates. The loaded suite adds scripts to all existing candidates in those lists:

| Candidate | Loaded script |
| --- | --- |
| rat | plx_rat_ai |
| kwama forager | plx_forager_ai |
| nix-hound | plx_spawn_nixpup |
| alit | ttooth_alit_spawns |
| skeleton, bonelord | plx_stat_random_und_dis |
| centurion_spider, centurion_sphere, centurion_steam | plx_spawn_rspiders2 |
| scamp, clannfear, daedroth | plx_stat_randomiser |
| dremora | rv_dremora_weapon |
| kagouti | ttooth_kagouti_spawns |

`ancestral ghost` and `bonewalker greater` are nonexistent record IDs in the loaded configuration. Thus no ordinary themed pool or preferred boss survives the filter.

The fallback iterates the entire creature record store and takes the first unscripted, nonessential, walking record accepted by `safeRecord`. Runtime reproduction confirms that first record is `guar_pack`, named **Pack Guar**. It is not a random themed choice. Bosses use the same fallback while retaining the boss flag.

The safety predicate allows ordinary unscripted creatures; it does not require a hostile combat archetype. The actor event sets fight to 80 but does not explicitly initiate combat. Actual hostility and promotion of the resulting guar were not tested by this diagnostic; selecting a pack animal is independently confirmed.

## Task 02 correction requirements

1. Correct and validate all explicit ordinary and boss IDs against loaded records.
2. Inspect suite-added scripts before deciding whether to retain them, allow known safe ones, or create controlled dungeon-specific records. Simply allowing every scripted record risks scripted child spawns and other side effects.
3. Use explicit combat archetypes and theme-appropriate backup choices. Remove the arbitrary whole-store fallback; missing pools should produce actionable diagnostics rather than domestic animals.
4. Keep guaranteed boss identity separate from ordinary fallback selection.
5. Verify variety, combat behavior, boss promotion, and any script side effects in actual full-suite dungeon encounters. Check existing saved floor actors as well as newly generated floors; a selection fix alone will not replace already saved guars.

## Evidence and reproduction

- `tests/scripts/ashenloot_test/enemy_selection.lua`: read-only runtime record probe and reproduction of the fallback predicate.
- `tests/enemy-selection-test.omwscripts`: global test manifest.
- `tests/enemy-selection-diagnosis.txt`: captured runtime findings, ending in `first fallback=guar_pack name=Pack Guar` and `COMPLETE`.
- Local ignored runtime log: `tests/enemy-selection-profile/openmw.log`.

The isolated profile uses normal configured content plus the test data directory and Isowind's existing HUD compatibility data. Launch with `--config <profile> --skip-menu --no-sound --start="Seyda Neen, Census and Excise Office"`. The probe quits automatically and creates no player saves. Earlier diagnostic launches omitted the Isowind HUD compatibility data and failed before execution; those are not test evidence.

Unrelated existing content warnings and a music-script initialization error occurred during startup. They do not alter the record-selection findings. This task did not test director reinforcement behavior or fix enemy selection.

# Dreamforged implementation backlog

Status: tasks 01, 02, and 02a complete (2026-10-30). Next: task 03, diagnose missing dungeon director spawns.

## Working agreement

- Work on one numbered task at a time, in order unless a dependency or user instruction changes priority.
- Before editing, inspect the current repository, applicable AGENTS.md instructions, installed build, and relevant configuration. Earlier conversation describes a snapshot, not guaranteed current state.
- Complete the task's focused checks before moving on. Record changed files, test evidence, remaining limitations, and installed version here.
- A passing isolated test does not establish that the full mod suite works. Use actual gameplay where the acceptance criteria require it.
- Keep changes recoverable and preserve save compatibility where practical. Do not reset personal saves for testing.
- Split a task further if it grows beyond one independently testable change. Track newly discovered work below rather than silently expanding scope.
- Preserve the working NPC entrance, generated floor foundation, portal return, and descent progression.

## Queue

- [x] **01 — Reproduce and diagnose enemy selection.** Trace themed pools, record IDs, eligibility filters, and fallback logic in the full suite. Log requested and selected records and rejection reasons. Check ordinary enemies and bosses. Done: a reproducible explanation for the pack-guar behavior, with evidence and a proposed correction.
- [x] **02 — Fix themed enemy and boss selection.** Validate creature IDs against loaded content; replace arbitrary fallbacks with explicit appropriate choices. Done: multiple floor themes produce varied appropriate creatures, including a real boss on every third floor, without pack-guar substitution.
- [x] **02a — Add depth-aware enemy archetype pools.** After task 02 establishes reliable selection, progressively introduce stronger and stranger theme-appropriate base creatures as depth increases, rather than only multiplying rat stats. Early caves can favor rats and other weak beasts; deeper caves and later cave cycles can draw from stronger animal-like creatures. Admit suitable creatures added by installed mods through validated theme, combat-role, and strength classification; require no additional creature mod. Exclude domestic/service animals, quest actors, and unsafe scripted specimens. Keep selection strength distinct from promotion rarity. Done: deterministic samples across shallow/deep depths and repeated palette cycles demonstrate changing archetypes; test both base-content and full-suite configurations, including fallback behavior when optional mod creatures are absent. Audit scaling alongside task 05 to prevent double amplification.
- [ ] **03 — Diagnose missing director spawns.** Trace budget, indoor guards, population counts, visibility, navigation, ground placement, and spawn rejection. Separate initial population from reinforcement waves. Done: every failed attempt has an understandable reason and the actual blocker is reproduced.
- [ ] **04 — Fix dungeon reinforcements.** Correct the identified blockers and stale population accounting. Done: full-suite gameplay shows repeat encounters, bounded population, recovery periods, safe placement, and continued operation after portal travel and save/load.
- [ ] **04a — Make encounter context explicit.** Define mutually exclusive wilderness, ordinary interior, and generated-dungeon contexts with their own encounter policies. Classify generated floors explicitly before applying ordinary indoor restrictions; treat the refuge as a safe context. Share validated selection/placement helpers where useful, while keeping budget, population, reinforcement, and boss rules explicit per context. First inspect current paths: the confirmed selection defect is in the dungeon-specific selector, whereas indoor reinforcement restrictions remain an unverified hypothesis. Done: a context/rule table and focused regression checks cover outdoor encounters, ordinary hostile interiors, safe interiors/refuge, and generated floors, including portal and save/load transitions.
- [ ] **04b — Give dungeon director messages a patron voice.** Route player-facing dungeon director messages through Fa-Nuit-Hen's martial trial theme, directly or through Nerethi, rather than the existing Dagoth Ur/dreamer framing. Cover encounter pressure, lulls, guardians, milestones, and rewards where those message events exist. Keep message selection contextual and separate from combat mechanics. Done: representative dungeon events use consistent patron-themed text, ordinary-world events retain their intended voice, and entering/leaving the dungeon switches message context correctly without duplicate announcements.
- [ ] **05 — Measure current combat and reward output.** Capture early/middle/late player and dungeon progression, including the current high-level character. Measure encounters, pack size, promotions, promotion tiers, drops per kill, rarity, consumables, and bosses. Audit overlapping player/enemy/gear/depth multipliers. Done: a compact baseline report supports subsequent tuning.
- [ ] **06 — Research Diablo 1/2 reference behavior.** Research D1 named-enemy density and D1/D2 drop rules using attributable sources. Distinguish ordinary monsters, special monsters, bosses, and progression. Treat 1–3 named enemies per floor as a proposed target, not a historical fact. Done: sourced notes and explicit proposed tuning targets.
- [ ] **07 — Tune director spending and promotions.** Favor larger groups and more frequent spawns over promotions; preserve breathing room. Favor higher promotion tiers with progression rather than unbounded promotion frequency. Separate general settings from dungeon overrides and scheduled bosses. Done: measured comparisons show more ordinary combat and fewer distinctive promoted enemies at early and late progression.
- [ ] **08 — Tune generated reward frequency and rarity.** Most ordinary enemies yield no generated rewards; consumables are most common among successful drops, then normal equipment. Reduce routine multiple high-tier rewards from promoted enemies. Keep legendary+ exciting while preserving late-game progression and meaningful third-floor bosses. Done: compare measured distributions with task 06 targets; verify ordinary, promoted, and boss rewards.
- [ ] **09 — Correct rarity presentation.** Make uncommon green and rare blue; audit higher-tier labels, tooltips, and existing highlight colors for consistency. Done: inspect representative items of every tier in the installed build.
- [ ] **10 — Audit generated-item economy.** Verify zero-gold generated gear, including special items. Resolve and document consumable/tome gold values consistently with the agreed resource sink; preserve forging-coin trade-ins and meaningful broker costs. Identification remains an undecided future idea, not a committed feature. Done: representative reward types and broker transactions have intended values without affecting native items.
- [ ] **11 — Unify generated enemy ground drops.** Route generated equipment, consumables, ammunition, scrolls, and tomes through the same ground-drop system. Preserve ordinary Morrowind loot behavior and direct inventory transactions such as purchases/reforging. Done: each generated reward category lands on the ground exactly once and remains collectible.
- [ ] **12 — Add readable generated-drop highlights.** Use rarity colors for equipment and subtle neutral presentation for normal items/consumables. Spread nearby drops; check floors, slopes, walls, and clutter. Done: drops are distinguishable and selectable; pickup, autosalvage, save/load, floor recycling, and cleanup do not duplicate or destroy carried rewards. No new automatic pickup behavior unless requested.
- [ ] **13 — Restore the minimap.** Diagnose HUD overrides, visibility settings, Isowind configuration, and conflicts. Done: readable minimap in the current full-suite setup at the user's UI scale, with configuration changes documented.
- [ ] **14 — Assess stock OpenMW isometric support.** Inspect Isowind's camera, aiming, movement, interaction, zoom, and visibility behavior; check current stock APIs and code licensing. Done: documented Lua-versus-engine feasibility and a small implementation scope. Desired end state uses the normal launcher/graphics without the unwanted multiplayer/MMO stack or pixel filter.
- [ ] **15 — Prototype view cycling and camera.** Implement first-person → third-person → isometric cycling with rotation and zoom as supported by task 14. Done: reliable transitions in exterior and interior gameplay, compatible with normal camera settings and full-suite controls.
- [ ] **16 — Complete isometric interaction affordances.** Add required aiming, cursor interaction, movement, and occlusion behavior. Verify vertical navigation, combat, inventory interaction, and minimap readability. Done: a playable stock-OpenMW prototype with any engine limitations clearly documented before expanding scope.
- [ ] **17 — Research and design dungeon furnishings.** Select Morrowind-appropriate doors, chests, barrels/urns, tomes, sarcophagi, shrines, and mechanisms. Define placement rules and a small reusable set per theme. Done: an asset/behavior plan that preserves broad spaces and reachable routes.
- [ ] **18 — Add decorative placement.** Populate themes with controlled density and unobstructed paths. Done: navigation and isometric visibility remain usable across all layouts; floors feel less barren without excessive clutter.
- [ ] **19 — Add interactable furnishings.** Implement a small set of caches, sarcophagi, inscriptions, doors, and shrines. Share the tuned reward economy. Done: interactions, ambushes/rewards, persistence, and reset behavior work without reward duplication or blocked essential routes.
- [ ] **20 — Research optional quest and route patterns.** Study Butcher, Skeleton King, and Poisoned Well structures, then design original Morrowind equivalents grounded in the herald/refuge lore. Include clues, optional routes, hidden bosses, and persistence decisions. Done: a small content specification with hooks, mechanics, rewards, and reset rules.
- [ ] **21 — Implement one optional encounter end to end.** Start with one clue-led dangerous encounter, introduced/tracked through Nerethi or the refuge where appropriate. Done: discovery, entry, encounter, completion, reward, death, portal return, and save/load all work.
- [ ] **22 — Add a side objective and alternate route.** Implement one themed objective that changes a floor or unlocks a route. Done: essential descent remains reachable; objective states and reset rules survive save/load.
- [ ] **23 — Add a hidden boss.** Implement an exploration/mechanism unlock, distinct from routine promotions and third-floor bosses. Done: unlock, encounter, reward, and repeat-run behavior are reliable and appropriately scarce.
- [ ] **24 — Integrated release verification.** Test ordinary outdoor/indoor play, shallow/deep floors, all palettes, bosses, highlighted drops, broker economy, portal returns, recycled layouts, and saves in the installed full suite. Package and document the tested build. Done: evidence and known limitations recorded; only justified outstanding work remains.

## Task completion record

For each completed task append:

```text
Task:
Outcome:
Changed files / configuration:
Checks and evidence:
Installed build:
Limitations / follow-up tasks:
```

## Newly discovered work

2026-10-30: added tasks 02a (depth-based archetypes and optional mod creatures), 04a (explicit encounter contexts), and 04b (dungeon patron messaging). Letter suffixes preserve existing task references while inserting dependencies in the queue. Work remains one task at a time.

## Suggested release checkpoints

1. Tasks 01–04: reliable enemy selection and director operation.
2. Tasks 05–12: measured combat/loot balance and highlighted generated drops.
3. Tasks 13–16: minimap and optional native isometric mode.
4. Tasks 17–24: furnishings, optional content, and integrated verification.

These checkpoints do not require implementing the whole group before testing individual tasks.

### Task 01 — completed 2026-10-30

Outcome: reproduced the pack-guar fallback in the full loaded suite. Every existing themed candidate has a suite-added MWScript and is rejected; two IDs do not exist. The unrestricted fallback selects guar_pack for ordinary enemies and bosses.

Changed files: diagnostic test/manifest, captured findings, and ENEMY-SELECTION-DIAGNOSIS.md in C:/Users/super/Documents/Dreamforged-github-import. No gameplay code or personal settings changed.

Checks: runtime probe of all 16 distinct configured creature IDs and the exact fallback predicate; output confirms first fallback=guar_pack name=Pack Guar and COMPLETE. Evidence: tests/enemy-selection-diagnosis.txt.

Installed build: unchanged, Dreamforged 0.11.0.

Follow-up: task 02 must inspect script side effects, correct IDs, remove arbitrary fallback, verify combat/boss behavior, and address guars already stored in active floor saves. Director behavior remains separate, tasks 03–04.


### Task 02 — completed 2026-10-30

Outcome: explicit private combat archetypes and boss backups replace the unrestricted fallback. Corrected ancestor_ghost and bonewalker_greater IDs. Inspected suite-added scripts: aggression/stat changes and child spawning make blanket scripted-creature admission unsafe. Original world records remain intact; private records are excluded from ordinary world selection. Deterministic selection mixes draws to avoid repeated species from adjacent spawn seeds.

Saved floors: living old-selector enemies are replaced in place once, preserving population, guardian role, and health fraction. Dead enemies and completed bosses persist. No run reset required.

Changed files: tools/build_delve.cjs, tools/delve-enemies.json, Dreamforged-Delve.esp, scripts/ashenloot/delve_enemies.lua, delve.lua, actor.lua, progression.lua, documentation, and focused runtime tests.

Checks: full-suite Isowind and base-content stock OpenMW runs both report [ENEMY FIX] ALL PASS. Verified all twelve floors, themed ordinary creatures, guardians at depths 3/6/9/12, actual nearby combat, private-record world-pool exclusion, save/load migration, corpse preservation, health preservation, and migration idempotence. Plugin rebuild is deterministic. Evidence: tests/enemy-fix-full-pass.txt and tests/enemy-fix-stock-pass.txt in the repository. Runtime checks are automated in-engine checks, not visual gameplay review.

Installed build: Dreamforged 0.11.1; launch normally after restarting OpenMW/Isowind. All 48 installed files were hash-checked against source at installation. An additional actual-configuration launch passed the installed first-floor spawn check; evidence: tests/enemy-installed-pass.txt.

Remaining: task 02a adds depth-dependent archetypes and optional mod creatures. Tasks 03-04 diagnose/fix reinforcements; task 04a defines explicit encounter contexts. Those tasks remain unchecked. This release also brings the previously uncommitted 0.11.0 dungeon prototype into Git history.

### Task 02a — completed 2026-10-30

Outcome: expanded authored roster from 16 to 32 combat archetypes; absolute depth weights stronger species and guardian forms across repeated palettes. Exhausted native themes retain strong forms. Optional expansion/mod creatures supplement ordinary spawns at a bounded 25% chance when suitable depth-band candidates exist. Eligibility requires a recognizable theme, walking, a population-list reference, no script/essential/services, and no known special actor tags. Respawn flags alone were insufficient and admitted location-specific variants, so list membership is mandatory.

Optional lifetime: cached dungeon-owned nonrespawning snapshots preserve mod visuals/stats/spells/inventory, avoid original record death counts/respawns, and persist across save/load. World random pools exclude these generated records, including with Unsafe Chaos. Existing 0.11.1 actors remain; new spawns use depth-aware selection. No reset required.

Checks: full-suite Isowind and base-content stock OpenMW sample/regression runs passed, covering the authored roster at depths 1-80, deterministic choice, shallow/deep and repeated-palette distributions through depth 121, native-only fallback, bounded optional rates, all twelve actual floors, guardians, combat, and saved-guar migration. Full-suite catalog: 134 optional records; base game plus official expansions: 12. Native cave mean strength estimate was 1.63 at depth 1 versus 16.53 at depth 25. Estimates are species-selection bands, not final actor levels.

After adding optional snapshots, a focused full-suite depth13 run also passed actual stronger floor generation, a mod kwama-grubber spawn, nonrespawn/script checks, record reuse, existing preparation target, real combat, world-pool exclusion, and save/load identity. Evidence: tests/enemy-depth-full-pass.txt, tests/enemy-depth-stock-pass.txt, tests/enemy-deep-pass.txt. Tests are automated in-engine checks, not visual QA.

Scaling audit: no additional health/damage/loot or promotion multiplier was introduced. Existing player/gear baseline, +1.25 target level per depth, +8% health/+4% damage/+5% loot budget per depth, and prestige remain. Task 05 still audits their combined balance with stronger native species.

Installed build: Dreamforged 0.11.2. Changed files include delve_selection.lua, delve.lua, progression.lua (case-insensitive generated-record exclusion), generated roster/plugin, builder manifest, runtime tests, and documentation. All 49 installed files were hash-checked against source; the generated plugin rebuild is deterministic. A normal-configuration launch passed the new-roster, depth-curve, and first-floor population checks; evidence: tests/enemy-depth-installed-pass.txt.

Remaining: task 03 diagnoses reinforcement failures. Quest/pet filters are conservative heuristics; unusual mod conventions may require later classification additions. Scripted mod creatures remain excluded; authored guardians remain curated. Optional discovery occurs once per load, not every frame.

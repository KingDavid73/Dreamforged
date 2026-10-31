# Dreamforged implementation backlog

Status: tasks 01, 02, 02a, 03, 04, 04a, 04c, 04b, 05, and 05a complete (2026-10-30). Next: task 06, research Diablo 1/2 reference behaviour before tuning.

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
- [x] **03 — Diagnose missing director spawns.** Trace budget, indoor guards, population counts, visibility, navigation, ground placement, and spawn rejection. Separate initial population from reinforcement waves. Done: every failed attempt has an understandable reason and the actual blocker is reproduced.
- [x] **04 — Fix dungeon reinforcements.** Correct rendered-camera visibility/FOV timing, try alternative safe anchors after rejection instead of repeatedly sampling the same failed point, and stop boss adds from reusing an occupied fixed anchor. Preserve readiness retries for cold navigation data; handle stale accounting and late responses. Done: full-suite gameplay shows repeat encounters, bounded population, recovery periods, safe placement, and continued operation after portal travel and save/load. Check that reinforcement groups actually reach the encounter rather than remaining idle offscreen; preserve local ambient encounters.
- [x] **04a — Make encounter context explicit.** Define mutually exclusive wilderness, ordinary interior, and generated-dungeon contexts with their own encounter policies. Classify generated floors explicitly before applying ordinary indoor restrictions; treat the refuge as a safe context. Share validated selection/placement helpers where useful, while keeping budget, population, reinforcement, and boss rules explicit per context. First inspect current paths: the confirmed selection defect is in the dungeon-specific selector, whereas indoor reinforcement restrictions remain an unverified hypothesis. Done: a context/rule table and focused regression checks cover outdoor encounters, ordinary hostile interiors, safe interiors/refuge, and generated floors, including portal and save/load transitions. The debug HUD must report the active dungeon context and its real state instead of presenting overworld pressure/boss-cycle numbers as dungeon scheduling evidence.
- [x] **04c — Establish dense dungeon populations and adaptive pacing.** Research Diablo/Diablo 2 encounter density/layout patterns and primary Left 4 Dead director design references, then implement a dungeon-specific baseline: substantial ambient populations plus reinforcement groups that build pressure, peak, and grant recovery windows. The dungeon should feel denser and more actively directed than the overworld. Use nearby active threat, health/recent damage, combat activity, and recent kills where reliable; avoid a constant unbounded horde. Separate floor population from active encounter limits so distant ambient enemies do not exhaust all reinforcement capacity. Keep nearby/performance caps and boss-add bounds, give depleted players recovery, and preserve lower promotion frequency/high-tier rarity as task 07's tuning intent. Done: full-suite traversal tests compare encounter/arrival rates, nearby peaks, recovery windows, threat on shallow/deep floors, boss pacing, and performance against task 03's baseline. Sample stationary, moving, struggling, and strong players; no surprise visible spawns, blocked routes, or runaway populations. Density should primarily add ordinary enemies; coordinate promotion/reward limits with tasks 07-08 so higher headcount does not multiply named enemies and high-tier loot. Measure cold/warm navigation and varied creature bounds as part of performance. Choose numeric targets from research and measurements rather than treating the current four initial enemies/eight-actor whole-floor cap as desired density.
- [x] **04b — Give dungeon director messages a patron voice.** Route player-facing dungeon director messages through Fa-Nuit-Hen's martial trial theme, directly or through Nerethi, rather than the existing Dagoth Ur/dreamer framing. Cover encounter pressure, lulls, guardians, milestones, and rewards where those message events exist. Keep message selection contextual and separate from combat mechanics. Done: representative dungeon events use consistent patron-themed text, ordinary-world events retain their intended voice, and entering/leaving the dungeon switches message context correctly without duplicate announcements.
- [x] **05 — Measure current combat and reward output.** Capture early/middle/late player and dungeon progression, including the current high-level character. Measure encounters, pack size, promotions, promotion tiers, drops per kill, rarity, consumables, and bosses. Audit overlapping player/enemy/gear/depth multipliers. Done: a compact baseline report supports subsequent tuning.
- [x] **05a — Repair RNG stream independence before tuning.** Task 05 verified affine coupling between equal-length stream suffixes in the current linear seed hash. The ordinary density/equipment gates intersect about 10.37% instead of about 1.98% under independence in the diagnostic; promotion/first-rank streams are coupled too. Introduce a tested stream separation/mixing strategy for new rolls without rewriting existing items or saved outcomes. Audit related reward, promotion, rank and consecutive engine-ID streams. Preserve intended probability tables, density/promotion caps and save compatibility. Done: deterministic repeatability and cross-stream/consecutive-ID distribution checks, live ordinary-drop and promotion/rank regressions in base/full-suite configurations, unchanged existing items/saves, and updated baseline. Do not silently substitute a few burned draws as an unvalidated global fix.
- [ ] **06 — Research Diablo 1/2 reference behavior.** Research D1 named-enemy density and D1/D2 drop rules using attributable sources. Distinguish ordinary monsters, special monsters, bosses, and progression. Treat 1–3 named enemies per floor as a proposed target, not a historical fact. Done: sourced notes and explicit proposed tuning targets.
- [ ] **07 — Tune director spending and promotions.** Favor larger groups and more frequent spawns over promotions; preserve breathing room. Favor higher promotion tiers with progression rather than unbounded promotion frequency. Separate general settings from dungeon overrides and scheduled bosses. Audit the inactive encounterDensity/exteriorBudget controls and gear scoring inconsistencies found in task 05 as part of choosing effective knobs. Done: measured comparisons show more ordinary combat and fewer distinctive promoted enemies at early and late progression.
- [ ] **08 — Tune generated reward frequency and rarity.** Most ordinary enemies yield no generated rewards; consumables are most common among successful drops, then normal equipment. Reduce routine multiple high-tier rewards from promoted enemies. Keep legendary+ exciting while preserving late-game progression and meaningful third-floor bosses. Audit generation-cap reuse against planned rarity and count Mythic by its explicit metadata flag. Done: compare measured distributions with task 06 targets; verify ordinary, promoted, and boss rewards.
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

2026-10-30: added tasks 02a (depth-based archetypes and optional mod creatures), 04a (explicit encounter contexts), and 04b (dungeon patron messaging). Letter suffixes preserve existing task references while inserting dependencies in the queue. Work remains one task at a time. 2026-10-30: added task 04c before patron messaging for the requested Diablo-style density and Left 4 Dead-style adaptive dungeon pacing; strengthened task 04 arrival checks and task 04a HUD-context checks.

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

### Task 03 — completed 2026-10-30

Outcome: reproduced missing waves in the full suite and isolated the rendered-camera visibility failure. The isometric floor made eight requests over the natural 45-second scheduler observation: all were rejected as visible, yielding zero waves/four initial actors. Six ground-valid anchor probes were classified visible by the old helper while an independent actual-FOV projection placed them offscreen. Focused camera metadata confirms request-time/rendered FOV 30 degrees versus validation-frame/base FOV 80 degrees, with viewport-ray half-angle about 40 degrees. Task 04 must capture the appropriate camera state and use its actual projection; merely reading FOV in the existing onFrame callback remains wrong.

Control: same engine/content with the Isowind script disabled eventually spawned a two-enemy group indoors (six actors total), and both reinforcements entered combat. Six earlier wave failures were visible-anchor rejections, not navigation failures. An early manual offscreen probe returned nav status 2; the later accepted wave returned status 0. Those differing path results do not isolate readiness versus endpoint coverage; no permanent indoor guard blocks the dedicated scheduler. The HUD reports the ordinary world's Interior state and pressure fields, not dungeon-wave state.

Boss case: near the third-floor guardian, ordinary waves paused and both boss-add requests failed because fixed anchor 2 was occupied. No adds appeared. The selector also consumes only one candidate per request; adjacent short wave seeds favor the same index. Trying other eligible anchors after a rejection belongs in task 04.

Added bounded per-floor diagnostics: gate counters, 32-entry state history, alive/cap, six candidate distance/occupancy/range entries, and last response ground/visibility/navigation/occupancy/camera details. These do not change placement policy, counts, or pacing. Evidence: tests/director-iso-diagnosis.txt, tests/director-control-diagnosis.txt, tests/director-camera-diagnosis.txt; reproduction scripts: director_probe.lua and director_probe_player.lua, with director-probe.omwscripts and optional director-quick.omwscripts marker. Test profiles are isolated; test-only health protection and brief wave suspension during anchor probes do not apply to gameplay. Natural-wave observation begins after probes finish.

Installed build: remains 0.11.2. Diagnostic instrumentation is source-only/unreleased; no gameplay release or personal configuration change for this task. The missing-wave fix is task 04. Task 04a adds explicit contexts and truthful HUD status. Added task 04c before flavor messages for dense Diablo-style ambient populations plus Left 4 Dead-style adaptive pressure, peaks, and recovery, with separate active-threat/performance limits. Task 07 handles broader promotion tuning and task 08 loot scarcity.

### Task 04 — completed 2026-10-30

Outcome: coherent request-time rendered-camera snapshots fix the 30/80-degree mismatch. Bounded rotating searches try alternative anchor neighborhoods; each member has exact ground, clearance, occupancy, view, range, and route checks. Incoming groups actively pursue the player; ambient starting groups remain four, and the guardian's exit is reserved. Live capacity is eight dungeon-owned enemies, with a cumulative four-add guardian budget and no ordinary waves during nearby guardian fights.

Additional blocker found in integration: on floor 2, the player agent (22,22,65) returned NavMeshNotFound=2 while existing forager, worker, and rat agents returned Success=0. Navigation now uses registered scene-agent meshes. If all relevant meshes are absent, the generated floor's exact tile graph is searched with physical segment checks and bounded rerouting; existing-but-rejected navmesh paths are not bypassed. The graph is generated from the same tiles as floor collision, without changing geometry or placed reference IDs.

Lifetime: requests are cancelled on travel/load/context changes and disabled settings. Tokens, freshness, position, and capacity checks reject late/duplicate results. Resume/load grace includes guardian adds. Zero-count removed references no longer block live capacity or cause repeated-removal errors; removed old-selection actors are not resurrected by migration.

Checks: clean full-suite Isowind and base-content stock OpenMW runs both report [REINFORCEMENT FIX] ALL PASS. Covered natural waves, combat and measurable movement toward player, independent actual-view checks of accepted points, first/third/isometric views, isometric zoom, portal/load cancellation and grace, stale/duplicate responses, settings, alternate retries, cleared floors, authored-route fallback/off-floor rejection, real guardian adds, live/cumulative caps, and successful-add timing. Selected due times and injected stale/rejected replies are test fixtures; natural initial waves and physical routes are exercised normally. Tests use isolated userdata and player health/fatigue protection. These are automated in-engine checks, not visual QA or density acceptance.

Evidence: tests/reinforcement-isowind-pass.txt, tests/reinforcement-stock-pass.txt, tests/reinforcement-navigation-proof.txt. Test sources: reinforcement.lua and reinforcement_player.lua. Checkpoint continuation evidence also exists during development; final Isowind and stock evidence is from clean runs.

Build: 0.11.3. Runtime changes are in delve.lua, delve_player.lua, actor.lua, new delve_view.lua/delve_navigation.lua, generated layout metadata, and its builder. All 53 installed files were hash-checked against source; plugin/layout rebuilds are deterministic. The actual configured installation passed its hidden-group, rendered-view, 30-degree FOV, navigation, and capacity check; evidence: tests/reinforcement-installed-pass.txt. No new game or reset required; existing inhabitants persist and new reinforcement groups use pursuit.

Remaining: task 04a fixes contexts/HUD. Task 04c adds the requested dense ambient population and adaptive dungeon pacing. Promotion/loot scarcity tuning remains tasks 07-08; this task retains baseline counts/intervals and adds no reward/stat multiplier.

### Task 04a — completed 2026-10-30

Outcome: centralized mutually exclusive wilderness, ordinary hostile/safe interior, generated-floor, refuge, and unknown policies. Exact authored floor membership replaces the broad name pattern. Refuge actors cannot receive automatic progression/promotions or legacy shrine encounters/resets. Ordinary interior classification preserves existing name/service heuristics, adding offices to safe names.

HUD: progression publishes the active context; the generated scheduler supplies actual depth, living owned population/cap, ordinary waves, guardian state, adds used/cap, next check, and placement status. Wilderness keeps pressure/cycle/phase; ordinary interiors show their actual rule mode. Teleport/load invalidates previous display state and old-cell payloads are rejected. UI destruction after teleport is deferred to onFrame as required by the engine. No hypothetical dungeon pressure/phase is displayed.

Isolation: interior kills no longer feed the wilderness pressure/boss cycle or victory feedback. Legacy placement/replacement completions recheck originating cell and active policy; interior additions require the player still to be present. Dedicated generated waves retain their own validated placement and caps.

Changed files: encounter_context.lua, director_debug.lua, progression.lua, global.lua, player.lua, delve.lua, delve_rules.lua, ENCOUNTER-CONTEXTS.md, release documentation, and focused context test scripts/manifests.

Checks: full loaded suite with Isowind and base-content stock OpenMW both report [CONTEXT FIX] ALL PASS. Verified actual refuge exclusion with a live creature, safe office and hostile Addamasartus policies, actual ordinary interior pack placement, exterior HUD, generated floor counters and real reinforcement group, portal return/resume, stale-cell event rejection, wilderness feedback isolation, and save/load provider/HUD recovery. Evidence: tests/context-full-pass.txt and tests/context-stock-pass.txt. These are automated in-engine checks of actual UI object/text state, not visual gameplay review. Test health/fatigue protection remains outside the release.

Installed build: Dreamforged 0.11.4; all 56 files hash-checked against source. Active normal OpenMW data path updated with a recoverable configuration backup. A separate actual-installation launch passed dungeon/refuge HUD and metric checks without a repository runtime override: tests/context-installed-pass.txt. Existing runs persist; no reset required.

Limitations / next: third-party ordinary interiors still use the existing heuristic, not a complete authored safe-location catalog. Task 04c adds dense populations and adaptive dungeon pacing; 04b patron messages follows. Promotion/loot tuning remains 07-08; minimap 13 and native isometric camera/controls 14-16 remain queued.

### Task 04c — completed 2026-10-30

Outcome: researched Diablo population/grouping, Blizzard D2 monster roles, and Valve director pacing; references and proposals in DUNGEON-PACING.md. New floors receive 24–32 ordinary ambient enemies in broad connected pockets, checked in bounded hidden/physical/navigation batches. Separate nearby/incoming, floor-live and lifetime budgets keep ambient population from exhausting reinforcement allowance or enabling unbounded stationary generation.

Pacing: actual health/recent loss, proximity, incoming pursuit, Combat-package reports and nearby deaths drive build, eight-second peak, fade and 25-second recovery. Nearby admission is 8/12; no new ordinary waves during fade/recovery or depletion. Existing enemies stay dangerous. Guardians remain guaranteed every third depth with four cumulative adds, withheld from depleted players; victory grants quiet recovery. The HUD exposes actual dungeon phase/intensity and nearby/incoming metrics.

Density safeguards: at most two ordinary promotions per floor and at most 8% per ordinary roll. Unpromoted generated-reward eligibility is sampled at 4/ambient-target before existing rules, keeping added ordinary headcount from multiplying generated rewards. Native inventory and promoted/guardian reward rules persist. General promotion tiers and drop tuning remain tasks 05–08.

Checks: full-suite Isowind and base-content stock OpenMW both report [DENSITY] ALL PASS; actual control-driven traversal (~3,533/3,552 units), stationary arrivals, 20%-health recovery, healing/clearance, portal/resume, save/load, all themes, depths 25/30 with level 50 baseline, promotion limit and guardian adds/recovery. Evidence: tests/density-full-pass.txt and tests/density-stock-pass.txt. Dedicated configured-installation checks cover actual HUD, rendered visibility, varied creature bounds/clearance and themes/depth30: tests/density-installed-pass.txt.

Measurements: stationary nearby peaks 9/11, one natural wave and one/two arrivals in the primary post-generation observation; ambient 24 shallow, 26 at depths 7/10, 32 at depths 25/30, plus scheduled guardians. Initial batch means about 0.48/0.26 ms; full-suite deep/theme maximum about 1.38 ms. A sequential configured baseline held the same 60 FPS cap: old 0.11.4 mean 16.77 ms/six owned actors versus 0.11.5 mean 16.81 ms/25; p95 both 16.67 ms. These are short capped/cached samples, not a universal performance or human balance guarantee. Admission caps cannot prevent a player from pulling existing ambient groups together.

Changed files: delve_pacing.lua, delve_population.lua, delve.lua, delve_player.lua, actor.lua, global.lua, director_debug.lua, DUNGEON-PACING.md, focused tests and release docs. Installed build: Dreamforged 0.11.5; normal data path updated with a recoverable configuration backup. Existing floors retain inhabitants; descend for dense new floors. No personal save/run reset.

Next: 04b patron messaging. Broader combat/reward balance, ground drops, minimap and native isometric controls remain queued.

Final compatibility check: an isolated stock-engine old-format save fixture retained four original actor identities and old reward rules, gained adaptive pacing without population top-up, and rejected expired/travel population replies: tests/density-legacy-pass.txt. All 59 installed files were hash-checked; tests are excluded from the release. Installed theme checks reached a maximum ~1.69 ms per validation batch.

### Task 04b — completed 2026-10-30

Outcome: original Fa-Nuit-Hen captions now cover generated-floor descent, buildup/peak/recovery, reinforcement groups, guardian approach/victory, promotions and rewards. Refuge rest uses the patron. Ordinary-world pools and named special-encounter speakers persist. Overworld pressure polling and special captions are blocked indoors; actor-specific narration requires the originating cell.

Deduplication: per-floor offered milestone flags persist; priority/expiry coalesces pending cues, with an eight-second patron cooldown. Guardian generation is silent; approach introduces it once, and the scheduler owns one victory cue. Mechanical broker/recovery status remains separate. Travel/load clears pending/visible old-cell captions without replaying milestones. Zero voice frequency mutes and discards cues; routine frequency remains adjustable.

Changed files: patron_lines.lua, narration.lua, delve.lua, global.lua, player.lua, PATRON-NARRATION.md, focused test scripts/manifests/evidence, and release docs. Enemy stats, species selection, pacing durations, spawn budgets, promotion/reward rules and camera controls are unchanged. Text is original mod fiction; no voice recordings or canonical dialogue were imported.

Checks: actual configured full-suite Isowind 0.11.6 and stock/base-content OpenMW both report [PATRON] ALL PASS. Covered all text pools/interpolation, unchanged world/special speakers, priority, actual caption card/events, descent, controlled scheduler peaks/lulls, rewards, cooldown, origin checks, portal clearing/resume, save/load, silent guardian generation, one approach/victory, mute, and world-voice restoration. Evidence: tests/patron-installed-pass.txt, tests/patron-stock-pass.txt; earlier source/full-suite pass tests/patron-full-pass.txt. Tests protect the player and accelerate selected phase/voice timers; no manual visual/audio acceptance is claimed.

Installed build: Dreamforged 0.11.6, active data path updated with a timestamped recoverable config backup. Existing saves/runs persist; no reset needed. Next: task 05 baseline combat/reward measurements; broader tuning, minimap and native isometric controls remain in the queue.

Final installed refuge-rest check passed: tests/patron-refuge-pass.txt. All 61 installed files were hash-checked against source; test helpers/profiles are excluded from the release.

### Task 05 — completed 2026-10-30

Outcome: BALANCE-BASELINE.md records the 0.11.6 baseline, without gameplay or probability changes. Measurements distinguish actual generated items, conditional reward plans, and source rules. 110 conditional cohorts / 1,100,000 plan trials; 522 initial actors and 336 refined actors, with 426 scripted kills total. Live probes cover level 1/depth 1, level 25/depth 12, level 100/depth 30, controlled promotion classes/pressure branches, actual health/strength, consumable units/stacks, empty kills and flag-correct Mythic classification. Existing 0.11.5 traversal/arrival evidence remains applicable because 0.11.6 changed narration only.

Personal context: newest-save isolated copy is level 16/effective gear34, run baseline 34 at depth 6; inventory 209 generated units includes 60 Relics and1 Mythic. Record count 706 is below generation limit 2000; reserve ~126. Original save hashes stayed unchanged. Archived level 351 metadata was identified but its isolated runtime load stopped at missing disabled dependencies; no content was re-enabled. Explicit351 stress rows are not represented as measurements of that old build.

Findings: promoted rewards bypass density gating and scale to routine Legendary/Relic packages. Actual late-depth six-Unique cohort created17 Relics. At default pressure extremes, ordinary requested groups shrink4→2–4 while promotion chance grows16.25%→50%. Most dense ordinary kills yielded nothing in live samples (51/60 early;53/60 middle/late), while old ordinary rules yielded nothing on17/60 early kills. Affine RNG stream coupling invalidates independent-gate assumptions; added05a before06.

Scaling audit: carried generated gear, missing level metadata/tier6 premiums, frozen run target, native target scaling, prestige, depth health/strength/reward factors, bounded promoted durability, reserve credit and generation-cap fallback are distinguished. Inactive density/budget controls and placeholder base-asset warnings require follow-up in07/08; uncommon source color is already green, so09 must trace actual presentation rather than assume the source constant is wrong.

Evidence: tests/balance-*-results.json, balance-personal-summary.json and balance-validation.txt; focused manifests/Lua probes; tools/build_balance_overlay.cjs and tools/report_balance.cjs. The overlay and observational hooks exist only in isolated test profiles. No production runtime, installed data path, personal saves or tuning values changed. Installed build remains 0.11.6; no new gameplay archive was issued.

Limitations: protected scripted kills, Rat bodies, controlled pressure/phase branches and small live conditional samples do not measure human time-to-kill or represent every species/build. Kernel trials are pre-creation plans with specified reset bank states, not a complete campaign. Archived351 equipment/DPS was not measured. Missing-model/unrelated suite warnings limit visual claims. Next: 05a RNG repair, then06 reference research and07–08 tuning.

### Task 05a — RNG stream independence (2026-10-30)

Outcome: repaired affine coupling for explicitly opted-in future decisions with a versioned, framed MurmurHash3 seed mixer and separate gameplay namespaces. Probability tables, density/promotion caps and reward budgets remain unchanged; legacy item RNG is preserved.

Changed files / configuration: scripts/ashenloot/{random_stream,rules,global,progression,delve}.lua; main OpenMW data path now Dreamforged-0.11.7 with timestamped cfg backup. RNG-INDEPENDENCE.md records updated measurements and compatibility boundaries.

Checks and evidence: identical stock/installed golden and distribution results; 705 hash vectors plus framed vectors; three 100k-ID joint/marginal samples and 13 x 50k namespace samples per engine; 4,000 live actor outcomes across full/stock; 500k conditional reward plans; old-0.11.6 save fixture preserves inventory metadata, inhabitants, committed promotions and budget; installed native population/placement/HUD regression passes all palettes/depth30. See tests/rng-*-pass.txt and result JSON files.

Installed build: 0.11.7; dist/Dreamforged-0.11.7.zip.

Limitations / follow-up: no reset of personal saves; unresolved future rolls change intentionally. Scripted probes do not replace human balance testing. Promoted multi-high-tier rewards and progression amplification remain tasks 07–08. Next is task 06.

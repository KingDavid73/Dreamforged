# Combat and reward baseline — Dreamforged 0.11.6

Measured 2026-10-30 against gameplay commit 3abad1e780600bd443d79474a3e31afebc5d8ce8. **No balance or gameplay changes are included in this task.** This report separates observed engine output, conditional reward-plan samples, and source-derived rules. These are current behavior, not desired tuning targets.

## Findings that should guide the next work

1. Fix RNG stream coupling before adjusting rates. The density reward gate and first ordinary equipment roll are not independent; neither are the promotion gate and first rank roll. Unique suffix labels alone do not solve the linear, equal-length seed relationship.
2. Promoted enemies bypass the density reward gate. Level, overgear, depth and reserve credit then buy multiple high-tier items. High-end drops becoming routine is real; it is not explained solely by an extremely high player level.
3. Rising overworld pressure favors promotions while requested ordinary groups shrink from four toward a 2–4 range. This is the opposite direction to the requested quantity-first emphasis.
4. New dense floors suppress most ordinary reward events, but preserved old floors keep the old reward eligibility. Consumable and equipment frequency must be measured separately.
5. The current character is level 16, effective gear 34, at saved depth 6 with frozen run baseline 34. Its inventory contains 60 Relics and 1 Mythic item(s), among 209 generated item units. Inventory totals are **not** drop rates.

## Method and limits

- Full-suite Isowind, current configured installation, isolated new-game profiles for live cohorts. Three levels (1/25/100), depths (1/12/30), 522 spawned actors in the initial promotion/stat probe; 90 of those were killed. A refined reward probe killed another 336 actors, including 60 ordinary kills in each of four profiles and six per promoted class. Actor stats include native/inventory/affix effects actually applied by the loaded suite.
- 110 conditional reward cohorts × 10,000 = **1,100,000 plan trials**, using the actual production budget/reserve/plan functions through a generated, ignored test-only overlay. Each trial starts with bank 0 or 125.982; these are independent conditional scenarios, not a simulated campaign. The ordinary chance expression is extracted from source. Plans precede item creation, pool failures, tome conversion, and generation-cap reuse.
- Live reward attribution wraps the existing ground-drop function in the isolated test, preserving its result, then compares corpse inventory and owned ground items. Ammunition units and stacks are reported separately. Mythic is recognized by its explicit metadata flag: its stored numeric tier is 6, despite being tier 7 in reward plans.
- The newest personal save was copied, loaded, sampled and quit without saving. Its original SHA-256 stayed unchanged. An archived level-351 save was identified from metadata; missing disabled dependencies prevented its runtime load. No disabled mod was re-enabled. The level-351 rows below are explicit stress profiles, **not** measurements of that archived character's equipment or DPS.
- Player health/fatigue were protected; selected ranks and levels were controlled. Rat bodies isolate progression/promotion effects rather than represent every dungeon species. Pressure-labelled probes exercise the actual promotion branch in a controlled interior arena, not an end-to-end wilderness traversal. There is no human time-to-kill, damage-taken, or difficulty verdict here. Small live samples are smoke measurements; the larger conditional samples explain the mechanism.

## Current-character snapshot

| Signal | Readout |
| --- | --- |
| Level / effective gear | 16 / 34 |
| Run baseline / depth / derived spawn target | 34 / 6 / 40 |
| Damage proxy: strongest attack / reliable hit / DPS | 220 / 132 / 66 |
| Weapon / spell contribution | 220 / 39.27825 |
| Combat feedback | 1.25 |
| Generated inventory, tiers 1→7 | 4, 18, 61, 42, 23, 60, 1 |
| Generation count / limit | 706 / 2000 (reuse cap not active) |
| Reward reserve / hunger | 125.98 / 0 |
| Settings | Crawler; health/damage 1/1; intensity 1; gear influence .5; adaptive loot on |

Gear scoring scans the best generated item available per slot in the **whole inventory**, not only equipped gear. Some older equipped metadata lacks a level and is ignored. The rarity premium table covers tiers 1–5 but gives tier 6/7 zero premium; that is a separate scoring inconsistency, not evidence that Relics inflate the score correctly.

## Observed live ordinary rewards

| Profile | Kills | Nothing generated | Equipment units | Potion stacks | Scroll stacks | Ammo stacks / units |
| --- | --- | --- | --- | --- | --- | --- |
| Legacy L1 / depth 1 | 60 | 17 (28.3%) | 7 | 44 | 4 | 3 / 39 |
| Dense L1 / depth 1 | 60 | 51 (85.0%) | 8 | 8 | 2 | 2 / 22 |
| Dense L25 / depth 12 | 60 | 53 (88.3%) | 6 | 3 | 2 | 3 / 36 |
| Dense L100 / depth 30 | 60 | 53 (88.3%) | 9 | 4 | 0 | 0 / 0 |

Native meat/inventory is excluded. For this ordinary sample, consumable stacks collectively exceed equipment stacks. A no-equipment roll is not the same as a no-reward kill. These cohorts have no procedural overgear and are not intended to reproduce the current character's complete class/build.

## Encounter baseline

The 0.11.5 traversal evidence remains applicable: 0.11.6 changed narration, not combat. Its full-suite stationary sample recorded one successful group/one arriving reinforcement over 45 seconds after generation, peak nearby nine and 25 owned living actors. The stock control recorded one group/two arrivals, peak nearby eleven and 26 owned actors. These are observations under protected, non-killing play, not promised wave rates for every run.

| Context | Baseline policy |
| --- | --- |
| Wilderness | Default five-second roll while moving; 150 travel units per check; chance 35% plus pressure, capped95%; nine weighted nearby population points at intensity1, plus danger/phase/boss pauses. Requested ordinary group four at pressure0, 2–4 at pressure100, before capacity/special selection. |
| Ordinary hostile interior | Actor-triggered packs: normally two added actors, three/four with Unique/World Boss anchors, bounded by five additions at default settings. Native population is separate. |
| Generated floor | 24 ambient actors at depth1, 26 at depth7, 32 at depth25; successful reinforcement groups up to two, next check11s in build/7s in peak; separate nearby8/12 and six live reinforcement allowances. |
| Recovery / guardian | Fade admits no ordinary reinforcements; 25s quiet after threats resolve, extended for depletion; guardian each third depth with four cumulative adds and35s victory recovery. Forty-eight live/96 lifetime floor bounds. |

## Conditional equipment plans

Empty starting reserve; numbers are planned equipment units per defeated actor of that class, including the ordinary eligibility/chance gates. They are not rarity-roll weights or all-enemy averages.

| Scenario | Ordinary | Champion | Elite | Unique | World Boss |
| --- | --- | --- | --- | --- | --- |
| world-early | 0.12 | 1.93 | 2.46 | 3.07 | 3.24 |
| world-mid | 0.24 | 1.99 | 2.47 | 3.26 | 3.65 |
| world-late | 0.33 | 2.00 | 2.50 | 3.46 | 4.40 |
| delve-early | 0.11 | 1.92 | 2.46 | 3.08 | 3.24 |
| delve-mid | 0.14 | 1.99 | 2.47 | 3.47 | 4.40 |
| delve-late | 0.10 | 2.01 | 2.51 | 3.52 | 4.51 |
| delve-extreme | 0.09 | 1.99 | 2.50 | 3.48 | 4.48 |
| personal-legacy | 0.26 | 2.00 | 2.48 | 3.45 | 4.26 |
| personal-dense | 0.16 | 1.99 | 2.46 | 3.41 | 4.26 |

| Scenario / class | Legendary+ units per kill | Kills with ≥2 Legendary+ |
| --- | --- | --- |
| world-early / World Boss | 3.24 | 100.0% |
| personal-legacy / Unique | 2.05 | 87.2% |
| delve-mid / Unique | 2.15 | 94.9% |
| delve-late / Champion | 1.21 | 21.4% |
| delve-late / Elite | 2.42 | 75.4% |
| delve-late / Unique | 3.52 | 100.0% |
| delve-extreme / Champion | 1.99 | 66.1% |

The level-1 boss already has a minimum three-slot package and Legendary procedural floor, with one separate nominal 20% Mythic opportunity per kill. At late depth, surplus budget upgrades slots to Relic; it does not buy unlimited slots. The old standalone World Boss rarity-CDF helper and upward-bonus helper are not called by the current death-budget path.

At the current-character-like L16/gear34/target40/depth6 profile, preserved ordinary rules planned 0.26 equipment units/kill; dense rules planned 0.16. The ratio is not one sixth because of the coupled gate. The dense gate does not reduce promoted packages. Complete cold/warm reserve cohorts are in the raw JSON.

## Actual created promoted equipment

Six killed actors per cell. Final columns separate Mythic flags from numeric tier 6. Reserve state evolves during this live run; these small samples need not equal independent empty-reserve means.

| Level / depth | Class | Items | Legendary | Relic | Mythic |
| --- | --- | --- | --- | --- | --- |
| 1 / 1 | Champion | 10 | 0 | 0 | 0 |
| 1 / 1 | Elite | 18 | 4 | 0 | 0 |
| 1 / 1 | Unique | 17 | 5 | 1 | 0 |
| 1 / 1 | World Boss | 20 | 12 | 7 | 1 |
| 25 / 12 | Champion | 11 | 1 | 0 | 0 |
| 25 / 12 | Elite | 16 | 4 | 3 | 0 |
| 25 / 12 | Unique | 22 | 8 | 6 | 0 |
| 25 / 12 | World Boss | 29 | 10 | 19 | 0 |
| 100 / 30 | Champion | 9 | 1 | 6 | 0 |
| 100 / 30 | Elite | 20 | 4 | 15 | 0 |
| 100 / 30 | Unique | 17 | 0 | 17 | 0 |
| 100 / 30 | World Boss | 25 | 0 | 21 | 4 |

## Promotion and combat observations

Actual 48-actor controlled promotion cohorts, counts shown as ordinary/champion/elite/unique/world-boss. Dense batches reset the ordinary promotion allowance at actor 25, representing two 24-enemy floors. World-boss cadence, specials and overspend bonuses are excluded.

| Level | Pressure 0 | Pressure 100 | Dense |
| --- | --- | --- | --- |
| 1 | 36/9/3/0/0 | 24/4/11/9/0 | 46/2/0/0/0 |
| 25 | 44/1/2/1/0 | 24/5/11/8/0 | 44/4/0/0/0 |
| 100 | 35/10/3/0/0 | 23/8/10/5/2 | 48/0/0/0/0 |

Do not interpret the zero promotions in one 48-actor dense sample as a level-dependent rate: the configured chance is unchanged, the cap and deterministic ID sequence matter, and these samples are small. The isolated RNG test below demonstrates an additional structural rank bias.

Mean observed total health on Rat bodies (including health modifiers), from six actual actors per class:

| Level / target / depth | Ordinary | Champion | Elite | Unique | World Boss |
| --- | --- | --- | --- | --- | --- |
| 1 / 1 / 1 | 20 | 24 | 36 | 56 | 109 |
| 25 / 38 / 12 | 371 | 445 | 565 | 726 | 1771 |
| 100 / 136 / 30 | 2230 | 2682 | 3358 | 4263 | 10088 |

This is an HP/progression baseline, not measured hits-to-kill. The themed selector independently chooses stronger species with depth, so actual guardian/body resistance and attack packages add another source of difficulty.

## Verified RNG coupling

The seed hash is linear base-31 modulo 2,147,483,647, followed by the same first LCG step. Equal-length suffixes leave a constant modulo offset between first outputs for every common actor prefix. The engine test's largest affine-offset error was below 3e-16.

| Equipment threshold | Measured gate passes | Measured equipment passes | Joint passes | Expected if independent | Diagnostic later-draw control |
| --- | --- | --- | --- | --- | --- |
| 12.4% | 16559 | 11963 | 10367 | 1981 | 1919 |
| 18.25% | 16559 | 17963 | 10367 | 2974 | 2953 |
| 22.25% | 16559 | 22048 | 10367 | 3651 | 3636 |

Each row has 100,000 seeds and a one-sixth density gate. The later-draw control is diagnostic only; no burn/jump fix was installed. The actual `:density-reward` and `:loot-budget-v1` suffixes both have 15 characters. Promotion `:elite` and rank `:rank4` both have six: with an 8% promotion gate and a 5% first Unique roll, the no-world-boss branch produced **0 intersections**, versus about 392 under independence. That branch applies to normal generated-dungeon promotions. Guaranteed guardians bypass it.

## Scaling audit: active versus legacy factors

| Layer | Current behavior / interaction |
| --- | --- |
| Player / gear | Effective gear is at least player level, lifting toward mean best carried slot score by gear influence. Damage score can also lift preparation power. |
| Run target | Frozen run-entry gear baseline + 1.25 × (depth−1), floored. Existing spawnLevels overrides normal creature interpolation/jitter. |
| Native HP / strength | Preparation first adjusts the native body to target level, then applies configured health/damage, prestige, and depth factors. Strength is capped at 10,000. |
| Prestige | max(1, effective preparation power / 100). At 351 and depth30: HP factor 3.51×3.32=11.65 and strength factor 3.51×2.16=7.58, before body/level/affix effects. |
| Depth | Health ×(1+.08×(d−1)); strength ×(1+.04×(d−1)); reward base budget ×(1+.05×(d−1)). At depth30: 3.32 / 2.16 / 2.45. |
| Promoted durability | max(body-based health, charged-hit target), bounded scale 4/6/9/30 by class; health bonus capped at 30,000; affix abilities may add more. The legacy gearHealthScale helper is not another active HP multiplier. |
| Rewards | Base + per-enemy-level + current overgear + configured excess difficulty, then depth multiplier, then adaptive reserve spend. Promotion class sets slot count and floor. |
| Reserve | Eligible kills add credit; promoted kills can release it. Hunger/sprees affect release. It is additive after depth scaling, not another multiplicative depth factor. |
| Generation cap | At maxGeneratedItems, giveLoot can reuse known records. That fallback does not require exact planned rarity, so it needs a separate audit; current character is below the cap. |
| Overworld quantity / promotion | At default settings, pressure0 requests four ordinary actors; pressure100 requests 2–4 before capacity. Promotion chance rises from 16.25% to 50%, plus possible overspend. Rank bonuses rise with pressure. Native promotion remains 25%. |
| Controls to verify | Progression directorDensity() currently derives 1.5×directorIntensity; exposed encounterDensity and exteriorBudget are not consumed by that director path. Do not assume those sliders are effective knobs. |

## Next actions, in order

1. **05a — repair and validate RNG stream independence**, preserving existing rolled items/saves and without changing intended probability tables. Cover reward eligibility/equipment, promotion/rank first draws, and consecutive engine IDs.
2. **06 — reference research**, then **07 — quantity-first director/promotion tuning** and **08 — reward frequency/tiers**. Retain meaningful boss rewards while stopping routine promoted Relic piles.
3. During 07/08, audit unscored tier6/Mythic gear and missing level metadata, inactive density/budget controls, and generation-cap rarity reuse. Missing-model warnings also appeared during generated item creation; count results do not prove every base asset renders correctly.

Raw data: tests/balance-kernel-results.json, balance-live-results.json, balance-drops-results.json, balance-correlation-results.json and balance-personal-summary.json. The initial live probe records stored numeric tier counts; use the refined drops file for flag-correct Mythic classification. Rebuild this report with `node tools/report_balance.cjs`. Generate the measurement-only closure overlay with `node tools/build_balance_overlay.cjs`; it stays under an ignored test profile, outside the installed mod. No personal saves, main configuration, or installed runtime files were changed by this task.

To repeat engine probes, use a separate OpenMW config directory/user-data path inheriting the normal suite; add the repository's tests directory and the corresponding balance-*.omwscripts manifest. Kernel sampling additionally adds the generated overlay as the last data directory. Start live/kernel/drop probes in the refuge. The correlation probe used only official masters plus the installed mod and tests. The personal probe requires an isolated copy of the chosen save with --load-savegame; it reads once and quits without saving. Never enable these test manifests or protected-player helpers in the normal gameplay profile.

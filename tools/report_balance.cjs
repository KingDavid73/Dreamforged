// Rebuild the compact baseline from measured, sanitized JSON exports.
const fs=require('fs'),path=require('path');const root=path.resolve(__dirname,'..');
const read=n=>JSON.parse(fs.readFileSync(path.join(root,'tests',n),'utf8'));
const kernel=read('balance-kernel-results.json'),live=read('balance-live-results.json'),drops=read('balance-drops-results.json'),personal=read('balance-personal-summary.json'),correlation=read('balance-correlation-results.json');
if(kernel.length!==110||kernel.reduce((s,x)=>s+x.samples,0)!==1100000)throw Error('Unexpected kernel sample totals');
for(const x of kernel)if(Object.values(x.tiers).reduce((s,n)=>s+n,0)!==x.items)throw Error('Plan tier total mismatch');
for(const x of [...live,...drops])if(Object.values(x.promotions).reduce((s,n)=>s+n,0)!==x.n)throw Error('Actor cohort total mismatch');
for(const x of drops)if(Object.values(x.tiers).reduce((s,n)=>s+n,0)!==(x.equipment||0)||x.zeroAnyKills>x.zeroEquipmentKills)throw Error('Reward attribution total mismatch');
const mean=x=>Object.values(x).reduce((a,b)=>a+b,0)/Object.values(x).length;
const f=(x,n=2)=>Number(x).toFixed(n),pct=x=>f(100*x,1)+'%';
const find=(name,rank,bank=0)=>kernel.find(x=>x.name===name&&x.rank===rank&&x.bank===bank);
const table=(headers,rows)=>[headers.join(' | '),headers.map(()=> '---').join(' | '),...rows.map(x=>x.join(' | '))].map(x=>'| '+x+' |').join('\n');
const roles=['Ordinary','Champion','Elite','Unique','World Boss'];
let out=`# Combat and reward baseline — Dreamforged 0.11.6

Measured 2026-10-30 against gameplay commit 3abad1e780600bd443d79474a3e31afebc5d8ce8. **No balance or gameplay changes are included in this task.** This report separates observed engine output, conditional reward-plan samples, and source-derived rules. These are current behavior, not desired tuning targets.

## Findings that should guide the next work

1. Fix RNG stream coupling before adjusting rates. The density reward gate and first ordinary equipment roll are not independent; neither are the promotion gate and first rank roll. Unique suffix labels alone do not solve the linear, equal-length seed relationship.
2. Promoted enemies bypass the density reward gate. Level, overgear, depth and reserve credit then buy multiple high-tier items. High-end drops becoming routine is real; it is not explained solely by an extremely high player level.
3. Rising overworld pressure favors promotions while requested ordinary groups shrink from four toward a 2–4 range. This is the opposite direction to the requested quantity-first emphasis.
4. New dense floors suppress most ordinary reward events, but preserved old floors keep the old reward eligibility. Consumable and equipment frequency must be measured separately.
5. The current character is level ${personal.level}, effective gear ${personal.gearLevel}, at saved depth ${personal.depth} with frozen run baseline ${personal.runBaseline}. Its inventory contains ${personal.inventoryTiers['6']} Relics and ${personal.inventoryTiers['7']} Mythic item(s), among ${personal.generatedInventory} generated item units. Inventory totals are **not** drop rates.

## Method and limits

- Full-suite Isowind, current configured installation, isolated new-game profiles for live cohorts. Three levels (1/25/100), depths (1/12/30), 522 spawned actors in the initial promotion/stat probe; 90 of those were killed. A refined reward probe killed another 336 actors, including 60 ordinary kills in each of four profiles and six per promoted class. Actor stats include native/inventory/affix effects actually applied by the loaded suite.
- 110 conditional reward cohorts × 10,000 = **1,100,000 plan trials**, using the actual production budget/reserve/plan functions through a generated, ignored test-only overlay. Each trial starts with bank 0 or 125.982; these are independent conditional scenarios, not a simulated campaign. The ordinary chance expression is extracted from source. Plans precede item creation, pool failures, tome conversion, and generation-cap reuse.
- Live reward attribution wraps the existing ground-drop function in the isolated test, preserving its result, then compares corpse inventory and owned ground items. Ammunition units and stacks are reported separately. Mythic is recognized by its explicit metadata flag: its stored numeric tier is 6, despite being tier 7 in reward plans.
- The newest personal save was copied, loaded, sampled and quit without saving. Its original SHA-256 stayed unchanged. An archived level-351 save was identified from metadata; missing disabled dependencies prevented its runtime load. No disabled mod was re-enabled. The level-351 rows below are explicit stress profiles, **not** measurements of that archived character's equipment or DPS.
- Player health/fatigue were protected; selected ranks and levels were controlled. Rat bodies isolate progression/promotion effects rather than represent every dungeon species. Pressure-labelled probes exercise the actual promotion branch in a controlled interior arena, not an end-to-end wilderness traversal. There is no human time-to-kill, damage-taken, or difficulty verdict here. Small live samples are smoke measurements; the larger conditional samples explain the mechanism.

## Current-character snapshot

${table(['Signal','Readout'],[
 ['Level / effective gear',personal.level+' / '+personal.gearLevel],['Run baseline / depth / derived spawn target',personal.runBaseline+' / '+personal.depth+' / 40'],
 ['Damage proxy: strongest attack / reliable hit / DPS',personal.damage.rawHit+' / '+personal.damage.hit+' / '+personal.damage.dps],
 ['Weapon / spell contribution',personal.damage.bestWeapon+' / '+personal.damage.bestSpell],['Combat feedback',personal.damage.feedback],
 ['Generated inventory, tiers 1→7',Object.values(personal.inventoryTiers).join(', ')],
 ['Generation count / limit',personal.generatedRecordCount+' / '+personal.settings.maxGeneratedItems+' (reuse cap not active)'],
 ['Reward reserve / hunger',f(personal.rewardDirector.bank)+' / '+personal.rewardDirector.hunger],
 ['Settings','Crawler; health/damage 1/1; intensity 1; gear influence .5; adaptive loot on']])}

Gear scoring scans the best generated item available per slot in the **whole inventory**, not only equipped gear. Some older equipped metadata lacks a level and is ignored. The rarity premium table covers tiers 1–5 but gives tier 6/7 zero premium; that is a separate scoring inconsistency, not evidence that Relics inflate the score correctly.

## Observed live ordinary rewards

${table(['Profile','Kills','Nothing generated','Equipment units','Potion stacks','Scroll stacks','Ammo stacks / units'],drops.filter(x=>x.rank===0).map(x=>[
 (x.legacy?'Legacy':'Dense')+' L'+x.player+' / depth '+x.depth,x.n,x.zeroAnyKills+' ('+pct(x.zeroAnyKills/x.n)+')',x.equipment||0,x.stacks.potions||0,x.stacks.scrolls||0,(x.stacks.ammunition||0)+' / '+(x.ammunition||0)]))}

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

${table(['Scenario','Ordinary','Champion','Elite','Unique','World Boss'],['world-early','world-mid','world-late','delve-early','delve-mid','delve-late','delve-extreme','personal-legacy','personal-dense'].map(name=>[name,...roles.map((_,rank)=>f(find(name,rank).items/10000))]))}

${table(['Scenario / class','Legendary+ units per kill','Kills with ≥2 Legendary+'],[['world-early',4],['personal-legacy',3],['delve-mid',3],['delve-late',1],['delve-late',2],['delve-late',3],['delve-extreme',1]].map(([name,rank])=>{const x=find(name,rank);return[name+' / '+roles[rank],f(['5','6','7'].reduce((s,k)=>s+(x.tiers[k]||0),0)/10000),pct(x.multiHigh/10000)]}))}

The level-1 boss already has a minimum three-slot package and Legendary procedural floor, with one separate nominal 20% Mythic opportunity per kill. At late depth, surplus budget upgrades slots to Relic; it does not buy unlimited slots. The old standalone World Boss rarity-CDF helper and upward-bonus helper are not called by the current death-budget path.

At the current-character-like L16/gear34/target40/depth6 profile, preserved ordinary rules planned ${f(find('personal-legacy',0).items/10000)} equipment units/kill; dense rules planned ${f(find('personal-dense',0).items/10000)}. The ratio is not one sixth because of the coupled gate. The dense gate does not reduce promoted packages. Complete cold/warm reserve cohorts are in the raw JSON.

## Actual created promoted equipment

Six killed actors per cell. Final columns separate Mythic flags from numeric tier 6. Reserve state evolves during this live run; these small samples need not equal independent empty-reserve means.

${table(['Level / depth','Class','Items','Legendary','Relic','Mythic'],drops.filter(x=>!x.legacy&&x.rank>0).map(x=>[x.player+' / '+x.depth,roles[x.rank],x.equipment||0,x.tiers['5']||0,x.tiers['6']||0,x.tiers['7']||0]))}

## Promotion and combat observations

Actual 48-actor controlled promotion cohorts, counts shown as ordinary/champion/elite/unique/world-boss. Dense batches reset the ordinary promotion allowance at actor 25, representing two 24-enemy floors. World-boss cadence, specials and overspend bonuses are excluded.

${table(['Level','Pressure 0','Pressure 100','Dense'],[1,25,100].map(level=>[level,...['world-low','world-high','dense-natural'].map(mode=>{const x=live.find(x=>x.player===level&&x.mode===mode);return roles.map((_,k)=>x.promotions[k]||0).join('/')} )]))}

Do not interpret the zero promotions in one 48-actor dense sample as a level-dependent rate: the configured chance is unchanged, the cap and deterministic ID sequence matter, and these samples are small. The isolated RNG test below demonstrates an additional structural rank bias.

Mean observed total health on Rat bodies (including health modifiers), from six actual actors per class:

${table(['Level / target / depth',...roles],[1,25,100].map(level=>{const rows=live.filter(x=>x.player===level&&x.mode==='forced');return[level+' / '+rows[0].target+' / '+rows[0].depth,...roles.map((_,rank)=>f(mean(rows.find(x=>x.rank===rank).health),0))]}))}

This is an HP/progression baseline, not measured hits-to-kill. The themed selector independently chooses stronger species with depth, so actual guardian/body resistance and attack packages add another source of difficulty.

## Verified RNG coupling

The seed hash is linear base-31 modulo 2,147,483,647, followed by the same first LCG step. Equal-length suffixes leave a constant modulo offset between first outputs for every common actor prefix. The engine test's largest affine-offset error was below 3e-16.

${table(['Equipment threshold','Measured gate passes','Measured equipment passes','Joint passes','Expected if independent','Diagnostic later-draw control'],correlation.filter(x=>!x.kind).map(x=>[x.chance+'%',x.gate,x.equipment,x.joint,f(x.expectedIndependent,0),x.controlJoint]))}

Each row has 100,000 seeds and a one-sixth density gate. The later-draw control is diagnostic only; no burn/jump fix was installed. The actual \`:density-reward\` and \`:loot-budget-v1\` suffixes both have 15 characters. Promotion \`:elite\` and rank \`:rank4\` both have six: with an 8% promotion gate and a 5% first Unique roll, the no-world-boss branch produced **0 intersections**, versus about 392 under independence. That branch applies to normal generated-dungeon promotions. Guaranteed guardians bypass it.

## Scaling audit: active versus legacy factors

${table(['Layer','Current behavior / interaction'],[
 ['Player / gear','Effective gear is at least player level, lifting toward mean best carried slot score by gear influence. Damage score can also lift preparation power.'],
 ['Run target','Frozen run-entry gear baseline + 1.25 × (depth−1), floored. Existing spawnLevels overrides normal creature interpolation/jitter.'],
 ['Native HP / strength','Preparation first adjusts the native body to target level, then applies configured health/damage, prestige, and depth factors. Strength is capped at 10,000.'],
 ['Prestige','max(1, effective preparation power / 100). At 351 and depth30: HP factor 3.51×3.32=11.65 and strength factor 3.51×2.16=7.58, before body/level/affix effects.'],
 ['Depth','Health ×(1+.08×(d−1)); strength ×(1+.04×(d−1)); reward base budget ×(1+.05×(d−1)). At depth30: 3.32 / 2.16 / 2.45.'],
 ['Promoted durability','max(body-based health, charged-hit target), bounded scale 4/6/9/30 by class; health bonus capped at 30,000; affix abilities may add more. The legacy gearHealthScale helper is not another active HP multiplier.'],
 ['Rewards','Base + per-enemy-level + current overgear + configured excess difficulty, then depth multiplier, then adaptive reserve spend. Promotion class sets slot count and floor.'],
 ['Reserve','Eligible kills add credit; promoted kills can release it. Hunger/sprees affect release. It is additive after depth scaling, not another multiplicative depth factor.'],
 ['Generation cap','At maxGeneratedItems, giveLoot can reuse known records. That fallback does not require exact planned rarity, so it needs a separate audit; current character is below the cap.'],
 ['Overworld quantity / promotion','At default settings, pressure0 requests four ordinary actors; pressure100 requests 2–4 before capacity. Promotion chance rises from 16.25% to 50%, plus possible overspend. Rank bonuses rise with pressure. Native promotion remains 25%.'],
 ['Controls to verify','Progression directorDensity() currently derives 1.5×directorIntensity; exposed encounterDensity and exteriorBudget are not consumed by that director path. Do not assume those sliders are effective knobs.']])}

## Next actions, in order

1. **05a — repair and validate RNG stream independence**, preserving existing rolled items/saves and without changing intended probability tables. Cover reward eligibility/equipment, promotion/rank first draws, and consecutive engine IDs.
2. **06 — reference research**, then **07 — quantity-first director/promotion tuning** and **08 — reward frequency/tiers**. Retain meaningful boss rewards while stopping routine promoted Relic piles.
3. During 07/08, audit unscored tier6/Mythic gear and missing level metadata, inactive density/budget controls, and generation-cap rarity reuse. Missing-model warnings also appeared during generated item creation; count results do not prove every base asset renders correctly.

Raw data: tests/balance-kernel-results.json, balance-live-results.json, balance-drops-results.json, balance-correlation-results.json and balance-personal-summary.json. The initial live probe records stored numeric tier counts; use the refined drops file for flag-correct Mythic classification. Rebuild this report with \`node tools/report_balance.cjs\`. Generate the measurement-only closure overlay with \`node tools/build_balance_overlay.cjs\`; it stays under an ignored test profile, outside the installed mod. No personal saves, main configuration, or installed runtime files were changed by this task.

To repeat engine probes, use a separate OpenMW config directory/user-data path inheriting the normal suite; add the repository's tests directory and the corresponding balance-*.omwscripts manifest. Kernel sampling additionally adds the generated overlay as the last data directory. Start live/kernel/drop probes in the refuge. The correlation probe used only official masters plus the installed mod and tests. The personal probe requires an isolated copy of the chosen save with --load-savegame; it reads once and quits without saving. Never enable these test manifests or protected-player helpers in the normal gameplay profile.
`;
fs.writeFileSync(path.join(root,'BALANCE-BASELINE.md'),out);
console.log('Wrote BALANCE-BASELINE.md from 110 reward-plan cohorts, 24 live cohorts and 20 refined drop cohorts.');

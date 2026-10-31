# Gameplay RNG stream repair — 0.11.7

Task 05a fixes correlated **new** reward and promotion decisions. Intended probability tables, class/depth curves, density and promotion caps, enemy stats, and reward budgets are unchanged. Broader scarcity/density tuning remains tasks 06–08.

## Defect and repair

The old seed hash was linear. Labels of the same length, such as `:density-reward` and `:loot-budget-v1`, gave first draws a constant modulo offset rather than independent behaviour. The analogous promotion/rank labels also biased which ranks could pass a promotion gate. See the frozen 0.11.6 measurements in BALANCE-BASELINE.md.

New gameplay decisions opt into `R.stream(seed, namespace)`. A versioned, length-framed seed/namespace tuple is mixed with MurmurHash3 x86_32, then initializes the existing 31-bit Park–Miller sequence with a nonzero state. This is a deterministic game generator; it makes no cryptographic claim. Namespace framing distinguishes ambiguous concatenations and uses byte lengths consistently for UTF-8.

The hash port uses exact split 16-bit multiplication, arithmetic shifts/rotations, and normalized unsigned XOR to avoid Lua-number rounding or signed-bit differences. It follows [Austin Appleby's public-domain reference](https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp); XOR uses the [OpenMW 0.51 utility API](https://openmw.readthedocs.io/en/openmw-0.51.0/reference/lua-scripting/openmw_util.html). Independent JavaScript `Math.imul` reference vectors cover empty inputs, short tails, block boundaries, long strings, UTF-8 and unsigned seed extremes.

Separate namespaces now cover density eligibility, equipment admission, reward-budget decisions, supplies, spell tomes, promotion admission, World Boss/Unique/Elite rank gates, modifier selection, dungeon species, and initial placement choice. Rank gates do not shift position when another rank branch is skipped. No arbitrary draw-burning workaround is used.

The legacy `R.rng` stays byte-for-byte algorithmically unchanged. Item specifications, cached item generation, names and other legacy consumers retain their existing generator. This avoids a global reroll of deterministic content and limits the change to explicitly opted-in future decisions.

## Save compatibility

- Existing record metadata, inventory objects, cached items, reward flags, named/ranked actors and their modifiers remain saved outcomes. No migration clears or recalculates them.
- Already-prepared nonpromoted actors keep that decision. Future unresolved rolls, new actors and future uncommitted death rewards use the repaired streams.
- Existing floor inhabitants persist; species changes affect new spawns. No selection-version bump or forced floor regeneration is introduced.
- Reward reserve, floor promotion allowance and progression are preserved. No save/run reset is needed.

An isolated stock 0.11.6 runtime created and saved a fixture with three generated items, a populated floor and committed promotions. The new runtime loaded a copy and compared item IDs/counts/metadata, inhabitants, names/ranks/modifiers and the floor's promotion budget. The comparison passed. No personal save was loaded or written for that upgrade check.

## Verification scope

Exact hash/framed-stream vectors, legacy-sequence comparison, cross-engine output comparison, marginal/joint frequency checks and neighbouring-ID correlation tests cover decimal, consecutive hexadecimal and strided hexadecimal identifiers. All opted-in namespaces receive consecutive-ID marginal tests. These are regression tests for the identified defect, not a formal proof of statistical independence for every possible seed.

Live probes run through the real death/reward and promotion code in isolated full-suite Isowind and stock/base-content profiles. Each checks 500 ordinary deaths plus 1,500 controlled promotion outcomes, including both pressure extremes and dense-floor caps. Player protection and controlled arena placement are test-only. Results are not human combat balance or visual acceptance.

The repaired conditional baseline is recorded separately from 0.11.6 rather than overwriting its evidence. It uses the same production closure sampling, with the current budget and equipment-stream expressions extracted into the ignored test overlay. This is pre-item-creation sampling with specified reset reserve states, not a complete campaign.

## Recorded results (2026-10-30)

The installed 0.11.7 Isowind/full-suite and stock OpenMW runs match exactly for golden vectors and all three 100,000-ID distribution samples. Each also passes 705 independent hash vectors, 20 framed-stream cases with 12 draws each, legacy output checks, and 50,000-ID marginals for each of the 13 gameplay namespaces. Evidence: tests/rng-installed-pass.txt, rng-stock-pass.txt and rng-distribution-results.json.

| Diagnostic, 100,000 strided engine-style IDs | Old 0.11.6 | Repaired | Approximate independent expectation |
| --- | ---: | ---: | ---: |
| Dense ordinary eligibility plus equipment gate | 10,367 | 1,993 | 2,000 |
| 8% promotion plus 5% first Unique gate | 0 | 416 | 400 |

Old figures come from the frozen baseline diagnostic; the old configured fractional equipment comparison gave a slightly different effective threshold. New runtime integer comparisons are tested directly. These are gate intersections, not item counts; multi-item budgets can yield more equipment than successful gates.

Actual live regressions used 500 ordinary deaths per engine: full suite yielded 79 eligible deaths, seven equipment items and 47 potion units; stock yielded 87 eligible deaths, nine equipment items and 49 potion units. Both also passed 1,500 controlled promotion outcomes (500 low-pressure, 500 high-pressure, 500 capped dense-floor) through the production encounter handler. Each dense sample included three Unique outcomes. Evidence: tests/rng-live-*-results.json and corresponding pass logs. These samples verify wiring and bounded behaviour, not final balance targets.

The updated conditional baseline contains 50 cohorts of 10,000 reward plans (500,000 total), in tests/rng-kernel-results.json. Cold-reserve ordinary equipment units per kill were 0.1210 for world-early, 0.0240 for dense delve-early, 0.0429 for dense delve-late, 0.2662 for the level-16/gear-34 legacy personal profile and 0.0464 for its dense equivalent. Warm-reserve rows and promoted/boss tiers remain in the JSON. High-tier multi-item promoted rewards still need tasks 07–08; this repair does not reduce their budgets.

The old-version upgrade fixture passed unchanged IDs, counts, metadata, inhabitants, promotion outcomes and budget (tests/rng-compat-pass.txt). The actual installed full suite also passed population/placement, actor-bound clearance and rendered-visibility checks across all five palettes at depths 1/4/7/10/30, plus a first-floor reinforcement wave and real dungeon HUD (tests/rng-native-installed-pass.txt). Scripted stationary timing averaged 17.0 ms, p95 16.7 ms and max 200 ms in that concurrent test session; this is not an isolated performance benchmark or human playtest. Known unrelated suite animation and music-initialization warnings persist.

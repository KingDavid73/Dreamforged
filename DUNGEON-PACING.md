# Dense dungeon encounters — design and reference notes

## References consulted 2026-10-30

- [DevilutionX monster population implementation](https://github.com/diasurgical/devilutionX/blob/master/Source/monster.cpp), `InitMonsters`/population code and `PlaceGroup`: the maintained Diablo port derives scattered population from nonsolid area, bounds the total, and mixes individuals with small groups. Its code uses different group sizes on early and later floors. This is evidence about the port's implementation, not a claim that every original Diablo release uses identical numbers. It supports spreading ordinary encounters across traversable space, rather than treating each room as one encounter.
- [Blizzard's Arreat Summit: monster basics](https://classic.battle.net/diablo2exp/monsters/basics.shtml) and [monster bonuses](https://classic.battle.net/diablo2exp/monsters/bonus.shtml): ordinary crowds, minions, champions, and uniques have different roles; champion packs contain 2–4. The tactical advice discusses separating crowds and prioritizing dangerous support enemies. These sources do not establish a universal D2 monsters-per-floor figure. D2's area/difficulty variation makes such a single target inappropriate here.
- [Michael Booth, Valve: The AI Systems of Left 4 Dead](https://www.readkong.com/page/the-ai-systems-of-left-4-dead-michael-booth-valve-9664541), presentation transcript, pacing slides: damage and nearby kills contribute to estimated intensity; population alternates through build, sustained peak, fade, and relaxation. Fade allows ongoing combat to resolve before quiet time counts down. Existing enemies remain dangerous during relaxation; bosses serve a separate pacing role. [Original Valve PDF](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf) was identified but its download timed out; the author's presentation was read through the linked transcript.

No Diablo assets/code or Valve implementation was imported. The following numbers are Dreamforged proposals, tested against its broad 512-unit tiles, Morrowind creature sizes, existing progression, and full-suite runtime. They are not historical D1/D2 drop or population statistics. Detailed drop-rate research remains task 06.

## Proposed implementation targets

| Layer | Rule |
| --- | --- |
| Ambient population | 24 at depth 1; +2 each six depths, capped at 32. Broad pockets spread across connected interior tiles; entry and guardian exit clearance reserved. |
| Generation | Up to four candidates checked per update, hidden from the actual rendered view, level ground, physical clearance, no overlap, and reachable route. Bounded three-pass readiness retries; never force visible/unsafe placement to meet a count. |
| Build | Up to two reinforcements per successful group; next check 11 seconds after success. Admission ceiling eight nearby plus incoming threats. |
| Peak | Up to two per group, seven seconds after success; admission ceiling twelve. Peak lasts eight seconds. |
| Fade | No new ordinary reinforcements; allow existing combat to finish. |
| Recovery | Starts when nearby threats are at most two and no reinforcements are approaching; 25 seconds of quiet. Health below 35% or substantial recent damage extends protection. Existing ambient enemies remain in the world. |
| Separate limits | Six living reinforcement actors across the floor, 48 living owned actors, and 96 lifetime generated actors per floor. Distant ambient actors do not spend the nearby reinforcement allowance. |
| Guardians | Guaranteed each third depth. Ordinary reinforcement admission stops near the guardian; four cumulative adds remain bounded and withheld from depleted players. Victory grants 35 seconds of recovery. |
| Density safeguards | At most two ordinary promotions per floor; at most 8% per ordinary promotion roll. Unpromoted generated-reward eligibility is sampled at `4 / ambientTarget`, then existing reward rules apply. Promoted enemies/guardians retain their existing reward rules. |

Nearby ceilings govern **new admission**, not forced despawning or pacification. Pulling several ambient pockets together can exceed them; the director then adds nothing. Incoming actors are counted before they reach the player. A dead/disabled/removed actor frees live capacity; corpses do not. The lifetime budget bounds stationary farming and retained references without deleting unclaimed rewards. Descending supplies a new budget.

## Signals, persistence, and scope

The scheduler samples actual health fraction and recent health loss, nearby owned/other aggressive actors, incoming reinforcement actors, actor Combat-package reports, and nearby deaths. Damage is a conservative health-loss proxy, including nonenemy hazards; healing between samples may hide damage. Proximity and kills supplement incomplete combat reports. Intensity is a pacing estimate, not a player difficulty rating; it changes scheduling, not enemy stats or species bands.

The HUD exposes dungeon phase, intensity, nearby allowance, incoming count, floor population, wave count, guardian/add budget, and recovery timer. The wilderness controller remains separate. Placement uses the repaired rendered-camera projection and validated navigation path from 0.11.3. Selection/depth stat multipliers stay unchanged.

New floors receive dense populations. Existing saved floors retain their existing inhabitants and gain adaptive reinforcement rules, without filling visible gaps on load. Save/load preserves populations, promotion counts and pacing; pending requests are discarded and health sampling restarts. Portal returns preserve the floor and grant arrival grace. No personal save or run reset is needed.

The promotion/reward safeguards keep additional ordinary enemies from multiplying the existing loot shower. They are local protections for density, not completion of tasks 05–08. Broader promotion tiers, drop categories/rarity, ordinary-world balance, and high-level tuning remain queued. Patron narration, minimap and native isometric controls remain separate tasks.

## Measured acceptance sample

See tests/density-full-pass.txt, density-stock-pass.txt and density-installed-pass.txt. Full-suite and stock protected-player traversal runs passed through depth 30, all palettes, ~3,500 units of physical movement, low-health suppression, actual threat-clearance recovery, portal/save/load and four guardian adds. Stationary nearby peaks were 9 and 11; ordinary promotions stayed at two. These are automated controlled probes, not human combat-balance verdicts.

A separate sequential full-suite Isowind sample compared configured 0.11.4 with configured 0.11.5: six versus 25 living owned actors, one wave each during the observation; mean frame 16.77 versus 16.81 ms, both p95 16.67 ms at the 60 FPS cap. Single-frame maxima were 174 versus 107 ms. These short, capped, cache-influenced samples do not establish a universal speedup or a bound on prolonged combat. Initial batch validation remained around half a millisecond; the installed theme/depth checks had zero measured actor-clearance obstructions, with sampled maximum half-widths about 29–84 and half-heights 41–113 units.

# Encounter contexts — 0.11.4

`encounter_context.lua` identifies exteriors, the exact refuge cell, and the twelve authored generated-floor cells. Similar names alone do not make another mod's interior a generated floor. Ordinary interiors retain the existing name/service heuristic for hostile versus safe locations, with offices included among safe names. This is a heuristic, not an authoritative classification of every third-party interior.

| Context | Actor progression | Automatic encounters | Bosses / resets | Debug HUD |
| --- | --- | --- | --- | --- |
| Wilderness | Existing eligibility and settlement rules | Existing outdoor pressure controller, groups and dens | Existing world-boss cycle and wilderness reset | Pressure, boss cycle, phase, placement status |
| Hostile ordinary interior | Existing eligibility | Existing actor-triggered packs and interior budget | Existing interior boss, eligible promotions, interior reruns | Tracked interior additions and rule mode |
| Safe ordinary interior | Existing eligible actors may still progress | No automatic packs or dens | No random world bosses, automatic interior bosses or reruns | Safe-interior policy |
| Generated dungeon | Dungeon depth preparation | Dedicated validated floor scheduler; no legacy packs/dens | Scheduled third-depth guardians and bounded adds; dedicated floor recycling | Actual depth, living owned enemies/cap, ordinary waves, guardian state, adds used/cap, next check and placement status |
| Refuge | Automatic progression/promotions disabled | None | No automatic bosses or reruns | Safe refuge |
| Unknown | None | None | None | Waiting for location |

The refuge policy does not pacify actors added by other mods. Normal world eligibility protections remain in force. This release does not change density targets, promotion rates, drops, depth scaling, or camera controls.

Only wilderness deaths feed wilderness pressure/victory feedback. Interior and generated-dungeon combat cannot advance that controller. Pending ordinary placement/replacement replies recheck their original cell and current policy; legacy interior spawns also require the player to remain there.

The player HUD receives one context-specific payload from progression, with dungeon counters supplied by the actual floor scheduler. Payloads from other cells are rejected; teleport/load clears old display state. Countdown means the next scheduler check, not a promise that a spawn will succeed. Placement and population limits still apply. No dungeon pressure/peak/recovery metric is invented: adaptive dungeon pacing is the next backlog task, 04c.

Existing runs and actor records persist; no save migration or dungeon reset is required. Enable **Director debug view** in Dreamforged settings to see the panel. Test profiles and their health/fatigue protection are development-only.

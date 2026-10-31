# 0.11.5 update

DUNGEON-PACING.md supersedes the population caps and ordinary wave timers in the 0.11.3 notes below. New floors have 24–32 ambient actors, distinct nearby/incoming reinforcement allowances, a 48-live floor bound, and adaptive build/peak/fade/recovery scheduling. The rendered-view, navigation, token, pursuit and physical placement protections remain. Historical 0.11.3 tests target its four/eight-actor baseline; density-test.omwscripts covers the new controller.

# Dungeon reinforcement repair — 0.11.3

Ordinary waves and guardian adds now search for hidden, reachable formation
positions instead of repeatedly testing one point. Reinforcements receive a
saved pursuit flag and join combat; initial inhabitants remain local encounters.

## Placement and lifetime

- Capture camera position/orientation and actual vertical FOV in the request
  event. Physical checks run on the following frame using that coherent snapshot.
  Viewport rays supply orientation, never the script-overridden projection.
- Use an expanded rendered frustum plus a body-sized safety volume. Check every
  accepted member's ground, height, clearance, occupancy, range, and route.
- Search anchor neighborhoods within 1800–4000 units to keep incoming groups
  within the tested actor-processing range. Rotate candidates, try alternatives
  immediately after rejection, and bound each batch's attempts and lifetime.
- Prefer registered scene-agent navigation meshes. Tests found that the player
  mesh could be absent while kwama and rat meshes were valid. If every relevant
  mesh is absent, use the generated floor's exact 512-unit tile graph and check
  its route segments against physical obstacles. A present-but-rejected navmesh
  path is not overridden by that fallback. Missing or blocked routes defer spawns.
- Validate exact formation points; never blindly offset a second enemy after
  checking only the first. Recheck occupancy, capacity, player movement, request
  age, floor, and guardian context before committing.
- Cancel obsolete batches on portal travel, descent, context changes, disabled
  encounters, and load. Tokens distinguish attempts; duplicate/late replies
  cannot consume a new request. Resume/load grace applies to ordinary waves and
  new guardian adds. Existing enemies remain active encounters.
- Removed objects can retain valid references with count zero. They neither
  consume live capacity nor cause repeated-removal failures during cleanup.

The baseline remains four initial inhabitants, at most eight living dungeon-owned
actors, ordinary groups of up to two, and a cumulative four-add guardian budget.
Initial placement keeps the guardian's exit free of an ordinary starting actor.
Successful ordinary waves retain their normal intervals and periodic recovery;
guardian adds retain their successful-add interval. The dense ambient population
and adaptive pressure/peak/recovery redesign is backlog task 04c.

## Existing saves

No reset or new game is required. Existing inhabitants and rewards persist.
Obsolete placement requests are discarded on load. New groups use the repaired
placement and pursuit behavior. Earlier fallback-guar repair remains available.

## Verification

The focused tests cover natural waves, actual pursuit/movement, independent
rendered-view checks, first/third/isometric views, isometric zoom, portal grace,
save/load cancellation, stale/duplicate replies, alternate candidates, clearing
floors, disabled settings, navigation fallback, and guardian caps. Tests use
isolated userdata, health/fatigue protection, and selected accelerated due times
for capacity checks. They are automated in-engine checks, not visual QA or
density/balance acceptance. See VALIDATION.md and the recorded test evidence.

Engine API references: [actor navigation bounds](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwlua/types/actor.cpp)
and [world navigation-bound selection](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwworld/worldimp.cpp).
The diagnosis and fixes were verified against the installed engines at runtime;
those upstream sources provide API context rather than proof of fork behavior.

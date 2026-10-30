# Task 03: dungeon reinforcement diagnosis

Confirmed 2026-10-30 against 0.11.2 plus read-only diagnostic instrumentation.
Gameplay placement and pacing policies were not changed. Installed release
remains 0.11.2; this is preparation for task 04.

## Findings

| Experiment | Observation |
| --- | --- |
| Full-suite Isowind, first floor, 45 seconds of natural scheduling after probes | Eight requests; eight visible-point rejections; zero waves; four initial actors |
| Six manual first-floor anchor probes in Isowind | All have ground; legacy helper says visible for all six; independent rendered-FOV projection says offscreen |
| Same engine and suite without Isowind scripts | One two-enemy wave eventually placed indoors; six total actors; both reinforcements entered combat |
| Near third-floor guardian in Isowind | Two add requests; both rejected as occupied; no adds; ordinary waves paused |

The primary blocker is the camera visibility check, not an indoor prohibition.
The dungeon owns its own scheduler. Ordinary indoor suppression in progression
code intentionally excludes these floors from the older encounter path, but
does not prevent the dedicated dungeon scheduler from requesting actors.

### Rendered view and validation disagree

Isowind's `mod/scripts/isowind/topdown.lua` explicitly sets a 30-degree vertical
FOV and constructs its own projection because the viewport ray helper ignores
script overrides. The dungeon instead uses `camera.viewportToWorldVector` to
construct a frustum. The result admits distant ground into its apparent view
and rejects it for spawning even though the player cannot see it.

The focused runtime probe measured:

- Request/event-time FOV: approximately 30 degrees.
- Later validation-frame FOV: approximately 80 degrees, matching base FOV.
- Viewport top-edge ray half-angle: approximately 40 degrees.
- Independent later-camera reference FOV: approximately 30 degrees.

This establishes both the base-projection mismatch and a frame-order issue.
Simply reading `getFieldOfView()` inside the existing validation `onFrame`
callback would still read 80 degrees. Task 04 should use a coherent snapshot
of the rendered view at the appropriate phase, its actual vertical FOV/aspect,
and a conservative hidden margin. Check normal first/third person and Isowind,
including camera movement, zoom, and view switches.

The independent reference derives camera axes from normalized viewport rays
but projects using the FOV observed after Isowind applies its override. It uses
the same vertical-FOV/aspect convention as Isowind's own projection. These are
numerical runtime checks, not screenshot/visual QA.

### Rejection handling and boss adds

Each ordinary request chooses one candidate, then waits five seconds after a
failed response. It does not try other eligible points within that request.
The wave selector uses the first draw of adjacent short seeds. For the fixture
`1:1:wave:4:0` through `1:1:wave:4:11`, all first draws choose index 2 of a
two-entry list. This favors repeated failed points rather than useful coverage.
The control run had six visible-point rejections before its successful wave;
do not reinterpret those as six navigation failures.

Boss adds always request anchor 2. An initial creature occupies that anchor,
so both tested requests failed as occupied. Nearby guardians suppress ordinary
waves, leaving no alternative reinforcement path during that fight.

An early manual offscreen probe in the control returned navigation status 2;
the later successful wave returned status 0. These different probes do not
isolate readiness versus endpoint coverage as the early failure's cause.
Keep explicit retry/status handling; no permanent indoor prohibition or
lost/expired production response was observed in these runs.

### Debug HUD and density are separate issues

The existing HUD reads `state.director.outdoor` and reports `Interior` for these
cells. Its pressure and boss-cycle numbers do not drive dungeon waves. Task 04a
must show the actual encounter context and dungeon scheduling state.

Current source policy starts with four enemies, adds a guardian every third
floor, requests at most two ordinary reinforcements, caps living floor actors
at eight, waits about 30 seconds between successful ordinary requests, and
uses a fixed extra lull after every third wave. There is no dungeon-specific
adaptive pressure/peak/recovery controller here. Fixing visibility alone cannot
deliver the requested density and pacing.

Task 04c will establish dense ambient populations plus directed encounter
waves, with nearby active-threat limits distinct from total floor population.
Research Diablo/Diablo 2 density and primary Left 4 Dead director references
before setting numeric targets. Density should add common enemies without
multiplying promotions and high-tier rewards; coordinate tasks 07–08.

## Evidence and reproduction

- `tests/director-iso-diagnosis.txt`: initial isometric run and boss test.
- `tests/director-control-diagnosis.txt`: same suite/engine without Isowind scripts.
- `tests/director-camera-diagnosis.txt`: focused camera phase/projection probe.
- `tests/scripts/ashenloot_test/director_probe.lua`: experiment driver.
- `tests/scripts/ashenloot_test/director_probe_player.lua`: independent projection
  reference and test-only health protection.
- `tests/director-probe.omwscripts`: test scripts; optional empty
  `director-quick.omwscripts` marker stops after camera probes.

Profiles use isolated userdata and normal full-suite content, with the source
and tests directories added. The control omits `isowind.omwscripts`; the camera
probe adds the quick marker. Start in `Seyda Neen, Shrine of the Unending Dream`
with `--skip-menu --no-sound`. The driver pauses wave scheduling only while
probing individual points, then observes the original scheduler naturally.
Player HP protection permits observing the boss; no saves or personal settings
are changed. Actors can move and push the stationary test player.

Instrumentation records per-slot gate counters, a bounded 32-entry transition
history, candidate distances/occupancy/range, and response camera/ground/path
details. It changes no gates, spawn counts, timers, or combat rules.

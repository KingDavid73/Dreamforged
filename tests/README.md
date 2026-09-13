# Re-running the isolated tests on this PC

Use the installed engine with this additional config:

```powershell
& 'D:\SteamLibrary\steamapps\common\Morrowind\openmw.exe' --config 'C:\Users\super\Documents\OpenMW-AshenLoot\tests'
```

Run from the installed engine directory. This config replaces the normal data/content/groundcover lists and supplies its own user-data directory. The final test includes the installed Fresh Loot 3.4.5 data path. It starts a temporary character, runs assertions, creates a save in `tests/userdata`, reloads it and exits. Each run may create another temporary character directory.

Expected log lines contain `[AshenLoot TEST] PASS`. Any `[AshenLoot TEST] FAIL`, Lua `onFrame/onUpdate failed`, or `[AshenLoot] ERROR` needs investigation. Tests rely on local absolute paths; edit them when moving the source to another machine.

`extract-save-preview.ps1` reads the engine's embedded SCRN image; that image excludes the HUD and therefore cannot validate the loot browser's visual layout.

For the combined Fresh Loot / World Randomizer / Tamriel Data / Tamriel Rebuilt test, use `--config 'C:\Users\super\Documents\OpenMW-AshenLoot\tests\compat-profile'` instead. That profile has its own logs and user data. It enables World Randomizer only within the test, disables combat AI to protect fixtures, generates real replacement creatures, exercises stat and inventory randomization, then saves/reloads and exits. Expected lines contain `[AshenLoot COMPAT] PASS`. It normally takes about 40 simulation seconds after loading.

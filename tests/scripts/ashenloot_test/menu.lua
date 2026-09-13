local menu = require('openmw.menu')
local core = require('openmw.core')
local pending, elapsed = false, 0
return {eventHandlers = {AshenLoot_TestSave = function()
    menu.saveGame('Ashen Loot automated test only', 'ashenloot-smoke.omwsave')
    pending, elapsed = true, 0
end}, engineHandlers = {onFrame = function(dt)
    if not pending then return end
    elapsed = elapsed + dt
    if elapsed < 1 then return end
    pending = false
    local directory = menu.getCurrentSaveDir()
    print('[AshenLoot TEST] Reloading isolated test save in ' .. directory)
    for slot, info in pairs(menu.getSaves(directory)) do
        if info.description == 'Ashen Loot automated test only' then menu.loadGame(directory, slot); return end
    end
    error('Automated test save was not created')
end}}

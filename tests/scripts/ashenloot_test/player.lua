local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local types = require('openmw.types')
local self = require('openmw.self')
return {eventHandlers = {AshenLoot_TestWorldPosition=function()
    local nearby=require('openmw.nearby')
    local best,distance=nil,0
    for n=1,80 do
        local pos=nearby.findRandomPointAroundCircle(self.position,2200,{includeFlags=nearby.NAVIGATOR_FLAGS.Walk})
        if pos and (pos-self.position):length()>distance then best,distance=pos,(pos-self.position):length() end
    end
    core.sendGlobalEvent('AshenLoot_TestWorldPosition',{position=best,distance=distance})
end,AshenLoot_TestLevel=function(level) types.Actor.stats.level(self).current=level end,
AshenLoot_TestEquip=function(event)
    local eq=types.Actor.getEquipment(self)
    if event.weapon then eq[types.Actor.EQUIPMENT_SLOT.CarriedRight]=event.weapon end
    if event.armor then eq[types.Actor.EQUIPMENT_SLOT.Cuirass]=event.armor end
    types.Actor.setEquipment(self,eq)
end,
AshenLoot_TestFreezeAI = function()
    local debug = require('openmw.debug')
    if debug.isAIEnabled() then debug.toggleAI() end
    if not debug.isGodMode() then debug.toggleGodMode() end
end, AshenLoot_TestUI = function()
    local ok, err = pcall(function()
        I.AshenLootUI.openInventory()
        assert(I.AshenLootUI.version == 1)
        local freshFound = false
        for _, item in ipairs(types.Actor.inventory(self):getAll()) do
            local meta = I.AshenLootUI.getMetadata(item)
            if meta and meta.source == 'Fresh Loot' then freshFound = true end
        end
        if core.contentFiles.has('fresh-loot.omwscripts') then assert(freshFound, 'Fresh Loot metadata was not bridged') end
        if freshFound then print('[AshenLoot TEST] PASS: real Fresh Loot item recognized by rarity UI') end
    end)
    core.sendGlobalEvent('AshenLoot_TestUIResult', {ok = ok, error = tostring(err)})
end}}

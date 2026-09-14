local core,world,types=require('openmw.core'),require('openmw.world'),require('openmw.types')
local I,util=require('openmw.interfaces'),require('openmw.util')
local Config=require('scripts.ashenloot.config')
local function set(key,value) require('openmw.storage').globalSection(Config.groupKey(key)):set(key,value) end
local t,stage,nextMove=0,0,4
return {engineHandlers={onUpdate=function(dt)
    t=t+dt
    local ok,err=pcall(function()
        local p=world.players[1]
        if not p then return end
        if stage==0 and t>1 then
            stage=1
            p:sendEvent('AshenLoot_TestFreezeAI')
            set('creatureVariety',0);set('creaturePoolMode','Random');set('encounterDensity',3)
            set('exteriorBudget',16);set('outdoorDirectorInterval',3);set('outdoorDirectorChance',100)
            set('outdoorPressureGain',15);set('exteriorGroupMin',3);set('exteriorGroupMax',5)
            set('creatureDenChance',100);set('creatureDenWaveInterval',5)
            set('creatureDenMinCycles',2);set('creatureDenMaxCycles',2)
            set('exteriorSpawnMin',300);set('exteriorSpread',1200)
            set('settlementSuppression',false);set('unsafeContent',false)
            p:teleport(world.getExteriorCell(0,0),util.vector3(4096,4096,1000))
        elseif stage==1 and t>=nextMove then
            -- Teleporting in measured steps simulates sustained travel without
            -- depending on test-profile input or AI.
            p:teleport(p.cell,p.position+util.vector3(220,0,0))
            nextMove=t+2
            if t>22 then stage=2 end
        elseif stage==2 and t>30 then
            stage=3
            local count,variety,seen=0,0,{}
            for id in pairs(I.AshenLoot.getState().director.generated) do
                count=count+1
                for _,actor in ipairs(world.activeActors) do
                    if actor.id==id and not seen[actor.recordId] then seen[actor.recordId]=true;variety=variety+1 end
                end
            end
            assert(count>=2,'Forced den plus waves produced only '..count..' additions')
            assert(count<=48,'Living director cap was exceeded: '..count)
            assert(variety>=2,'Forced den waves produced only '..variety..' creature records')
            local dens=0
            for _ in pairs(I.AshenLoot.getState().director.dens or {}) do dens=dens+1 end
            assert(dens>=1,'Forced den encounter did not create a tracked Kwama Queen den')
            print('[Dreamforged EXTERIOR] PASS: moving-player director placed '..count..' bounded additions across '..variety..' records')
            core.quit();stage=4
        end
    end)
    if not ok then print('[AshenLoot SPREAD] FAIL: '..tostring(err));core.quit();stage=4 end
end}}

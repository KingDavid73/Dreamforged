local core,world,types=require('openmw.core'),require('openmw.world'),require('openmw.types')
local I,util=require('openmw.interfaces'),require('openmw.util')
local Config=require('scripts.ashenloot.config')
local function set(key,value) require('openmw.storage').globalSection(Config.groupKey(key)):set(key,value) end
local t,stage=0,0
return {engineHandlers={onUpdate=function(dt)
    t=t+dt
    local ok,err=pcall(function()
        local p=world.players[1]
        if not p then return end
        if stage==0 and t>1 then
            stage=1
            p:sendEvent('AshenLoot_TestFreezeAI')
            set('creatureVariety',0);set('creaturePoolMode','Random');set('encounterDensity',3)
            set('exteriorBudget',16);set('exteriorTriggerMin',100);set('exteriorTriggerRange',8000)
            set('exteriorAnchorChance',100);set('exteriorGroupMin',3);set('exteriorGroupMax',5)
            set('exteriorSpawnMin',300);set('exteriorSpread',1200)
            set('settlementSuppression',false);set('unsafeContent',false)
            p:teleport(world.getExteriorCell(0,0),util.vector3(4096,4096,1000))
        elseif stage==1 and t>12 then
            stage=2
            for n=1,8 do
                local angle=n*0.785398
                local anchor=world.createObject('rat',1)
                anchor:teleport(p.cell,p.position+util.vector3(math.cos(angle)*900,math.sin(angle)*900,0))
            end
        elseif stage==2 and t>24 then
            stage=3
            local count,variety,seen=0,0,{}
            for id in pairs(I.AshenLoot.getState().director.generated) do
                count=count+1
                for _,actor in ipairs(world.activeActors) do
                    if actor.id==id and not seen[actor.recordId] then seen[actor.recordId]=true;variety=variety+1 end
                end
            end
            assert(count>=24,'Maximum exterior settings produced '..count..' additions')
            for cellId,cellState in pairs(I.AshenLoot.getState().director.cells) do
                if cellState.isExterior then
                    assert((cellState.additionalCount or 0)<=48,'Additional-spawn budget exceeded in '..cellId)
                end
            end
            assert(variety>=6,'Maximum Random exterior settings produced only '..variety..' creature records')
            print('[Dreamforged EXTERIOR] PASS: active same/adjacent-cell anchors placed '..count..' bounded additions across '..variety..' records')
            core.quit();stage=4
        end
    end)
    if not ok then print('[AshenLoot SPREAD] FAIL: '..tostring(err));core.quit();stage=4 end
end}}

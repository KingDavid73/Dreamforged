local core,types,world=require('openmw.core'),require('openmw.types'),require('openmw.world')
local I,util=require('openmw.interfaces'),require('openmw.util')
local settings=require('openmw.storage').globalSection('SettingsAshenLoot')
settings:set('randomizeContainers',false)
local stage,time,rat,npc,item,owned,origin,generated,loaded=0,0,nil,nil,nil,nil,nil,0,false
local spawnPos,replaced,downscaled,downscaledHealth,cache,cacheBefore
local function check(c,s) assert(c,s) end
local function pass(s) print('[AshenLoot WORLD4] PASS: '..s) end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
return {engineHandlers={onUpdate=function(dt)
    time=time+dt
    local ok,err=pcall(function()
        local p=world.players[1]
        if not p then return end
        local progress=I.AshenLoot.progression
        local d=I.AshenLoot.getState().director
        if stage==0 and time>2 then
            stage=1;p:sendEvent('AshenLoot_TestFreezeAI')
            settings:set('creatureVariety',0);settings:set('extraEncounters',true)
            settings:set('exteriorBudget',6);settings:set('interiorBudget',3)
            settings:set('dungeonBosses',true)
            settings:set('containerLootPercent',100)
            p:sendEvent('AshenLoot_TestLevel',30)
            origin=p.position
            p:sendEvent('AshenLoot_TestWorldPosition')
            rat=world.createObject('rat',1)
            rat:teleport(p.cell,origin+util.vector3(1400,0,0))
            for _,rec in pairs(types.NPC.records) do
                local service=false
                for _,v in pairs(rec.servicesOffered or {}) do if v then service=true end end
                if rec.id~='player' and not rec.mwscript and not rec.isEssential and not service then
                    npc=world.createObject(rec.id,1)
                    if not types.Actor.isDead(npc) then npc:teleport(p.cell,origin+util.vector3(200,0,0));break
                    else npc:remove();npc=nil end
                end
            end
            item=world.createObject('daedric longsword',1)
            item:teleport(p.cell,origin+util.vector3(230,0,0))
            owned=world.createObject('daedric longsword',1)
            owned.owner.recordId='player'
            owned:teleport(p.cell,origin+util.vector3(240,0,0))
            downscaled=world.createObject('golden saint',1)
            downscaledHealth=types.Actor.stats.dynamic.health(downscaled).base
            downscaled:teleport(p.cell,origin+util.vector3(300,0,0))
            d.actors[downscaled.id]={level=1}
            downscaled:sendEvent('AshenLoot_Scale',{level=1,nativeLevel=50,allowDownscale=true,
                progression=true,health=1,damage=1})
            for _,rec in pairs(types.Container.records) do
                if not rec.mwscript and not rec.isOrganic and (rec.weight or 0)>=10 then
                    cache=world.createObject(rec.id,1);break
                end
            end
            check(cache,'No safe container fixture record')
            cache:teleport(p.cell,origin+util.vector3(350,0,0))
            types.Lockable.lock(cache,80)
            world.createObject('ingred_bonemeal_01',1):moveInto(types.Container.content(cache))
            cacheBefore=#types.Container.content(cache):getAll()
        elseif stage==1 and time>5 then
            stage=2
            check(spawnPos,'No navmesh fixture location')
            settings:set('randomizeContainers',true)
            progress.containerLoot(p.cell,rat,30)
            check(d.looseCells[p.cell.id], 'Eligible ruin did not complete its one-time loose-item pass')
            check(types.Actor.stats.level(downscaled).current==1,'High-native creature level did not downscale')
            check(types.Actor.stats.dynamic.health(downscaled).base<downscaledHealth,'High-native creature health did not downscale')
            pass('high-native creature level and health downscale for a low-level target')
            rat:teleport(p.cell,spawnPos)
        elseif stage==2 and time>7 then
            stage=21
            progress.prepare(rat)
            progress.scavenge({actor=npc,item=owned})
            check(not owned.parentContainer,'Owned item stolen')
            progress.scavenge({actor=npc,item=item})
        elseif stage==21 and time>12 then
            stage=3
            check(item.parentContainer==npc,'Scavenging transfer')
            check(d.randomizedContainers[cache.id]==true,'Dungeon container was not selected')
            check(#types.Container.content(cache):getAll()>=cacheBefore+1,'Selected cache did not gain a prize')
            local generatedPrize=false
            for _,container in ipairs(p.cell:getAll(types.Container)) do
                for _,found in ipairs(types.Container.content(container):getAll()) do
                    if I.AshenLoot.getState().records[found.recordId] then generatedPrize=true;break end
                end
                if generatedPrize then break end
            end
            check(generatedPrize,'Selected dungeon containers did not produce their logged generated prize')
            pass('container loot gradient, level-80 lock weighting, and uncapped cell prizes')
            local eq=types.Actor.getEquipment(npc)
            check(eq[types.Actor.EQUIPMENT_SLOT.CarriedRight] and eq[types.Actor.EQUIPMENT_SLOT.CarriedRight].recordId==item.recordId,'Scavenged weapon not wielded')
            check(d.actors[rat.id].level>=15,'Player-level encounter progression')
            check(types.Actor.stats.dynamic.health(rat).base>20,'Scaled creature health')
            check(d.cells[p.cell.id].count>0,'Spawn budget not reserved')
            local leader=I.AshenLoot.getState().elites[d.cells[p.cell.id].boss]
            check(leader and leader.rank>=2,'Dungeon minimum elite')
            generated=count(d.generated)
            check(generated>0,'No navigation-validated extra encounters')
            local before=d.cells[p.cell.id].count
            progress.prepare(rat)
            check(d.cells[p.cell.id].count==before and count(d.generated)==generated,'Repeated spawn')
            pass('level-30 actor scaling, real navmesh spawns, cell budget and repeat protection')
            pass('unowned item transferred and wielded; owned equipment protected')
            settings:set('creatureVariety',100)
            replaced=world.createObject('rat',1)
            replaced:teleport(p.cell,spawnPos)
            stage=22
        elseif stage==22 and time>14 then
            settings:set('creatureVariety',100)
            progress.prepare(replaced)
            stage=23
        elseif stage==23 and time>17 then
            local replacement=d.actors[replaced.id].replacement
            check(replacement and replacement:isValid() and not replaced.enabled,'Creature replacement')
            check(replacement.recordId~='rat','Actual monster tier unchanged')
            check(progress.test.safeRecord(types.Creature.record(replacement.recordId)),'One-off creature selected for replacement')
            pass('guaranteed dungeon elite; distant rat replaced by tiered creature '..replacement.recordId)
            local cellState=d.cells[p.cell.id]
            cellState.spawnPoints={fixture={key='fixture',x=spawnPos.x,y=spawnPos.y,z=spawnPos.z}}
            local before=count(d.generated)
            local made=progress.test.rerunDungeon(p.cell,cellState,true)
            check(made>=3 and count(d.generated)==before+made,'Dungeon rerun wave generation')
            check(cellState.rerunGeneration==1 and not cellState.clearedAt,'Dungeon rerun state')
            pass('cleared-dungeon rerun creates a persistent level-scaled wave at prior safe positions')
            generated=count(d.generated)
            stage=3
            types.Player.sendMenuEvent(p,'AshenLoot_TestSave')
        elseif stage==3 and loaded and time>13 then
            stage=4
            check(count(d.generated)>=generated,'Spawn persistence')
            check(item.parentContainer==npc,'Scavenged item persistence')
            pass('save/reload preserves spawned encounters and scavenged equipment')
            core.quit()
        elseif time>35 then error('World test timed out') end
    end)
    if not ok then print('[AshenLoot WORLD4] FAIL: '..tostring(err));core.quit() end
end,onSave=function() return {stage=stage,time=time,rat=rat,npc=npc,item=item,owned=owned,origin=origin,generated=generated} end,
onLoad=function(d) stage,time,rat,npc,item,owned,origin,generated=d.stage,d.time,d.rat,d.npc,d.item,d.owned,d.origin,d.generated;loaded=true end},
eventHandlers={AshenLoot_TestWorldPosition=function(d) spawnPos=d.position;print('[AshenLoot WORLD4] nav fixture distance '..d.distance) end}}

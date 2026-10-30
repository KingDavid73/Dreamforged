local core,world,types,I=require('openmw.core'),require('openmw.world'),require('openmw.types'),require('openmw.interfaces')
local R,util=require('scripts.ashenloot.rules'),require('openmw.util')
local stage,t,wait,chosen,report,loaded=0,0,0,nil,nil,false
local function check(v,s)assert(v,s);print('[ENEMY DEEP] PASS '..s)end
local function update(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local D=A.delve;local d=D.test.data()
 if stage==0 and t>3 then
  d.depth=12;D.test.descend(p);stage=1;wait=t+4
 elseif stage==1 and t>wait then
  local slot=d.slots[1];check(d.depth==13 and #slot.objects==4,'second cave cycle generates normally')
  for _,o in ipairs(slot.objects)do local e=D.test.selection.describe(o.recordId);check(e and e.theme==1 and e.level>=5.5,'depth13 replaces opening rats with stronger archetypes '..o.recordId)end
  -- Reproduce the production seed path to select a real optional actor, without
  -- overriding the selector or depending on a particular creature mod ID.
  for serial=slot.serial+1,slot.serial+2000 do
   local rng=R.rng(d.serial..':'..slot.depth..':'..serial);rng(997);rng(7919)
   local id,e=D.test.selectEnemy(1,false,rng,13)
   if e.optional then
    slot.serial=serial-1;local anchor=require('scripts.ashenloot.delve_layouts')[1].anchors[2]
    chosen=D.test.spawn(slot,1,anchor,false)
    check(d.actors[chosen.id].archetypeSource==id and d.actors[chosen.id].optionalArchetype,'real spawn uses eligible optional archetype '..id)
    check(not types.Creature.record(chosen).isRespawning and not types.Creature.record(chosen).mwscript,'optional dungeon snapshot is nonrespawning and script-free');check(D.test.selection.recordId(e)==chosen.recordId,'optional snapshot record reused');chosen:addScript('scripts/ashenloot_test/enemy_actor.lua')

    break
   end
  end
  check(chosen,'full suite supplies an eligible optional cave creature at depth13')
  stage=2;wait=t+5
 elseif stage==2 and t>wait then
  check(A.getState().director.actors[chosen.id].level==math.floor(d.baseline+15),'optional spawn uses existing scaling target once')
  check(not A.progression.test.safeRecord(types.Creature.record(chosen)),'generated optional snapshot excluded from world random pool');p:teleport(chosen.cell,chosen.position+util.vector3(150,0,0),{onGround=true});stage=21;wait=t+5
 elseif stage==21 and t>wait then
  chosen:sendEvent('EnemyTest_Inspect');stage=3;wait=t+3
 elseif stage==3 and report then
  print('[ENEMY DEEP] combat='..tostring(report.combat)..' fight='..tostring(report.fight)..' flee='..tostring(report.flee));check(report.combat and report.fight==100 and report.flee==0,'optional creature enters combat with dungeon hostility')
  types.Player.sendMenuEvent(p,'AshenLoot_TestSave');stage=4
 elseif stage==4 and loaded and t>wait then
  check(chosen:isValid() and d.actors[chosen.id].optionalArchetype and d.depth==13,'optional enemy and depth survive save/load')
  check(D.test.selection.describe(chosen.recordId).optional,'optional snapshot identity restored after load');check(D.test.selection.recordId(D.test.selection.describe(chosen.recordId))==chosen.recordId,'cached optional record survives save/load');print('[ENEMY DEEP] ALL PASS');core.quit();stage=99
 end
 if t>40 and stage~=99 then error('timeout stage '..stage)end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(update,dt);if not ok then print('[ENEMY DEEP] FAIL '..tostring(e));core.quit()end end,
 onSave=function()return {stage=stage,t=t,chosen=chosen}end,
 onLoad=function(s)stage,t,chosen=s.stage,s.t,s.chosen;loaded=true;wait=t+4 end},
 eventHandlers={EnemyTest_Report=function(e)report=e end}}

-- Saved-state fixture for pre-density slots: four inhabitants, no population/pacing fields.
local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local stage,t,at,loaded,ids=0,0,0,false,{}
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local D=I.AshenLoot.delve;local d=D.test.data();local s=d.slots[1]
  if stage==0 and t>3 then D.test.descend(p);stage=1
  elseif stage==1 and s and D.test.aliveCount(s)>=4 then
   local kept=0
   for _,actor in ipairs(s.objects)do if actor:isValid()and actor.count>0 then
    if kept<4 then kept=kept+1;ids[actor.id]=actor.recordId;D.context(actor).density=nil
    else actor:remove()end
   end end
   s.population=nil;s.populationPending=nil;s.pendingInitial=nil;s.pacing=nil;s.nextWave=core.getSimulationTime()+100
   stage=2;at=t+2
  elseif stage==2 and t>at then stage=3;types.Player.sendMenuEvent(p,'AshenLoot_TestSave')
  elseif stage==3 and loaded and t>at then
   assert(D.test.aliveCount(s)==4 and not s.population and not s.populationPending,'legacy slot was repopulated')
   local found=0;for _,actor in ipairs(s.objects)do if actor:isValid()and actor.count>0 then
    assert(ids[actor.id]==actor.recordId,'legacy inhabitant identity changed');found=found+1
    assert(D.rewardEligible(actor),'legacy reward rules changed')
   end end
   assert(found==4 and s.pacing and s.pacing.phase,'legacy floor failed to acquire adaptive scheduler')
   local serial=s.serial;local now=core.getSimulationTime()
   s.populationPending={token='expired-fixture',expires=now-1,points={{5000,5000,8}}}
   D.population{player=p,token='expired-fixture',depth=s.depth,cell=s.cell,origin=p.position,checkedAt=now,positions={{5000,5000,8}}}
   assert(s.serial==serial and not s.populationPending,'expired population reply accepted')
   s.populationPending={token='portal-fixture',expires=now+5,points={{5000,5000,8}}}
   D.test.retreat(p);assert(not s.populationPending,'portal did not cancel population request')
   D.population{player=p,token='portal-fixture',depth=s.depth,cell=s.cell,origin=p.position,checkedAt=now,positions={{5000,5000,8}}}
   assert(s.serial==serial,'late portal reply added actors');stage=4;at=t+3
  elseif stage==4 and t>at then
   D.test.resume(p);stage=5;at=t+3
  elseif stage==5 and t>at then
   assert(D.test.aliveCount(s)==4 and not s.population,'legacy portal resume refilled floor')
   print('[DENSITY LEGACY] ALL PASS old-format saved floor keeps four identities/rewards, gains pacing without top-up, and rejects expired/travel replies');core.quit();stage=99
  end
  if t>45 and stage~=99 then error('legacy fixture timeout')end
 end)
 if not ok then print('[DENSITY LEGACY] FAIL '..tostring(e));core.quit()end
end,onSave=function()return{stage=stage,t=t,ids=ids}end,
onLoad=function(e)if e then stage=e.stage;t=e.t;ids=e.ids;loaded=true;at=t+5 end end}}

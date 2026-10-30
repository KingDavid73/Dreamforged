local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local storage,C=require('openmw.storage'),require('scripts.ashenloot.config')
local stage,t,at,report=0,0,0,nil
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local A=I.AshenLoot
  if stage==0 and t>3 then
   storage.globalSection(C.groupKey('directorDebugView')):set('directorDebugView',true)
   assert(A.progression.test.context(p.cell).id=='refuge','installed refuge policy missing')
   A.delve.test.descend(p);stage=1;at=t+5
  elseif stage==1 and t>at then p:sendEvent('ContextTest_Report',{});stage=2;at=t+1
  elseif stage==2 and t>at then
   local d=A.progression.debugState(p);local slot=A.delve.test.data().slots[1]
   assert(d.context=='delve' and d.depth==1 and d.alive==A.delve.test.aliveCount(slot),'installed dungeon metrics mismatch')
   assert(report and report.visible and report.state.context=='delve','installed dungeon HUD absent')
   assert(not table.concat(report.lines,' '):find('Pressure',1,true),'installed HUD still uses wilderness pressure')
   A.delve.test.retreat(p);report=nil;stage=3;at=t+5
  elseif stage==3 and t>at then p:sendEvent('ContextTest_Report',{});stage=4;at=t+1
  elseif stage==4 and t>at then
   assert(report and report.visible and report.state.context=='refuge','installed portal HUD failed')
   print('[CONTEXT INSTALLED] ALL PASS configured 0.11.4 dungeon metrics and refuge HUD');stage=99;core.quit()
  end
  if t>40 and stage~=99 then error('installed context timeout')end
 end)
 if not ok then print('[CONTEXT INSTALLED] FAIL '..tostring(e));core.quit()end
end},eventHandlers={ContextTest_Report=function(e)report=e end}}

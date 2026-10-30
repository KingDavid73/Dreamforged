local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local t,stage,at,checked=0,0,0,0
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local D=I.AshenLoot.delve
  assert(D.test.beginPlacement and #require('scripts.ashenloot.delve_layouts')[1].tiles>0,'installed placement update missing')
  if stage==0 and t>3 then D.test.descend(p);stage=1
  elseif stage==1 and t>8 then D.test.data().slots[1].nextWave=core.getSimulationTime();stage=2
  elseif stage==2 and (D.test.data().slots[1].waves or 0)>0 then stage=3;at=t+1
  elseif stage==3 and t>at then
   local slot=D.test.data().slots[1];assert(D.test.aliveCount(slot)>4 and D.test.aliveCount(slot)<=8,'installed wave did not create bounded living actors')
   assert(checked>0,'installed formation not independently checked')
   assert(math.abs(slot.diagnostics.lastResponse.camera.fov-math.rad(30))<.001,'installed isometric projection mismatch')
   assert(slot.diagnostics.lastResponse.navMethod,'installed navigation update missing')
   print('[INSTALLED REINFORCEMENT] ALL PASS configured 0.11.3 actually places a hidden reachable group');core.quit();stage=99
  end
  if t>45 and stage~=99 then error('installed wave timeout')end
 end)
 if not ok then print('[INSTALLED REINFORCEMENT] FAIL '..tostring(e));core.quit()end
end},eventHandlers={ReinforcementTest_Checked=function(n)checked=checked+n end,
 Dreamforged_DelveAnchor=function(e)if e.clear and e.positions then e.player:sendEvent('ReinforcementTest_Check',{token=e.token,positions=e.positions,fov=e.camera.fov})end end}}

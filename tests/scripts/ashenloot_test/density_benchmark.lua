local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local t,stage,at=0,0,0
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 if stage==0 and t>3 then I.AshenLoot.delve.test.descend(p);stage=1;at=t+45
 elseif stage==1 and t>at then
  local s=I.AshenLoot.delve.test.data().slots[1]
  print('[DENSITY BENCH] owned='..I.AshenLoot.delve.test.aliveCount(s)..' waves='..(s.waves or 0))
  p:sendEvent('Density_Frames',{});stage=2
 end
end},eventHandlers={Density_Frames=function(e)
 print('[DENSITY BENCH] frames='..e.count..' meanMs='..e.mean..' p95Ms='..e.p95..' maxMs='..e.max)
 print('[DENSITY BENCH] ALL PASS');core.quit()
end}}

local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local t,stage=0,0
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local D=I.AshenLoot.delve;local d=D.test.data()
 local ok,err=pcall(function()
 if stage==0 and t>2 then D.test.descend(p);stage=1
 elseif stage==1 and t>5 then D.test.descend(p);stage=2
 elseif stage==2 and t>55 then
  local slot=d.slots[2]
  assert((slot.waves or 0)>0 and #slot.objects>4,'Director never reinforced a floor: '..tostring(slot.lastPlacementFailure)..' request '..tostring(slot.request))
  local alive=0;for _,o in ipairs(slot.objects)do if o:isValid() and not require('openmw.types').Actor.isDead(o) then alive=alive+1 end end
  assert(alive<=8,'Population cap exceeded')
  print('[DELVE WAVES] ALL PASS safe reinforcement placement and cap');core.quit()
 end
 end)
 if not ok then print('[DELVE WAVES] FAIL '..tostring(err));core.quit() end
end}}

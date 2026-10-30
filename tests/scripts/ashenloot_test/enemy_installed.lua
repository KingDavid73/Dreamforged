local core,world,I=require('openmw.core'),require('openmw.world'),require('openmw.interfaces')
local t,entered=0,false
return {engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local D=I.AshenLoot.delve
  assert(D.test.selection and #D.test.selection.catalog()[1].ordinary==11,'installed depth-aware roster missing')
  assert(D.test.selection.target(13,false)==10,'installed depth curve missing')
  if not entered and t>3 then D.test.descend(p);entered=true
  elseif entered and t>7 then
   local slot=D.test.data().slots[1];assert(slot and #slot.objects==4,'installed first floor not populated')
   for _,o in ipairs(slot.objects) do assert(o.recordId:find('df_delve_enemy_',1,true)==1,'installed stale selector '..o.recordId) end
   print('[ENEMY INSTALLED] ALL PASS configured installation selects dungeon combat records');core.quit()
  end
 end)
 if not ok then print('[ENEMY INSTALLED] FAIL '..tostring(e));core.quit() end
end}}
